import { resolve, join } from "path";
import { homedir } from "os";
import { mkdir, readdir, readFile, stat, unlink, writeFile } from "fs/promises";
import { Api, Model } from "@earendil-works/pi-ai";
import { createHash } from "crypto";
import { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { completeSimple } from "@earendil-works/pi-ai/compat";
import { spawn, SpawnOptionsWithoutStdio } from "child_process";

export class Cache {
    name: string;
    duration: number;

    constructor(name: string, duration: number) {
        this.name = this.#fixName(name);
        this.duration = duration;
    }

    async set(key: string, value: string) {
        key = this.#fixName(key);
        const folder = await this.#ensureCacheFolder();
        const file = join(folder, key);
        await writeFile(file, value);
    }

    async get(key: string): Promise<string | undefined> {
        key = this.#fixName(key);
        const folder = await this.#ensureCacheFolder();
        const file = join(folder, key);
        try {
            return await readFile(file, "utf-8");
        } catch {

        }
    }

    async #ensureCacheFolder(): Promise<string> {
        const folder = this.#getCacheFolder();
        await mkdir(folder, { recursive: true });
        const now = Date.now()
        for (const file of await readdir(folder)) {
            const path = resolve(folder, file);
            const stats = await stat(path);
            if ((now - stats.mtimeMs) > this.duration) {
                await unlink(path);
            }
        }
        return folder;
    }

    #getCacheFolder(): string {
        return join(homedir(), ".cache", "gojo", this.name)
    }

    #fixName(value: string): string {
        return value.replaceAll("/", "_").replaceAll("\0", "_");
    }
}

const llmCache = new Cache("llm", 30 * 24 * 60 * 60 * 1000);

export async function callLLM(model: Model<Api> | string, messages: string[], systemPrompt: string | undefined, signal: AbortSignal | undefined, ctx: ExtensionContext): Promise<string | undefined> {
    if (typeof model === "string") {
        model = ctx.modelRegistry.getAvailable().filter(mod => mod.id === model)[0];
    }
    const rawCacheKey = `${model.id}_${messages.join(",")}_${systemPrompt}`;
    const cacheKey = createHash("sha256").update(rawCacheKey).digest("hex");
    const cachedValue = await llmCache.get(cacheKey);
    if (cachedValue) {
        return cachedValue;
    }
    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
    if (!auth.ok || !auth.apiKey) {
        throw new Error(auth.ok ? `No API key for ${model.provider}` : auth.error);
    }
    const response = await completeSimple(model, {
        messages: messages.map(mes => ({ role: "user", content: mes, timestamp: Date.now() })),
        systemPrompt,
    }, { apiKey: auth.apiKey, headers: auth.headers, env: auth.env, signal, reasoning: "medium" })
    if ((response.stopReason === "stop" || response.stopReason === "length") && response.content.length > 0) {
        const result = response.content
            .filter($ => $.type === "text")
            .map($ => $.text.trim())
            .filter(Boolean)
            .join("\n");
        try {
            await llmCache.set(cacheKey, result);
        }
        catch (e) {
        }
        return result;
    }
}

export function createCookieFetch() {
    const cookieMap = new Map();
    async function fetch2(input: string | URL | Request, init?: RequestInit,) {
        init = Object.assign({}, init);
        init.headers = Object.fromEntries(new Headers(init.headers));
        init.headers["cookie"] = Array.from(cookieMap.entries()).map(([key, value]) => `${key}=${value}`).join("; ");
        if (!init.headers["cookie"]) {
            delete init.headers["cookie"]
        }
        let response = await fetch(input, init);
        for (const rawCookie of response.headers.getSetCookie()) {
            const parts = rawCookie.split(";").map(p => p.trim());
            const [key, value] = parts[0].split(/=(.*)/s).map(p => p.trim());
            cookieMap.set(key, value)
        }
        return response;
    }
    return fetch2 satisfies typeof fetch;
}

export async function runCommand(command: string, args: string[], options?: SpawnOptionsWithoutStdio): Promise<[string , number|null]> {
    const stdout = await new Promise<[string , number|null]>((resolve, reject) => {
        const child = spawn(command, args, options);
        let stdout = "";
        child.stdout.on("data", (data) => (stdout += data));
        child.on("close", code => {
            resolve([stdout.trim(),code])
        });
        child.on("error", error => {
            reject(error)
        })
    });
    return stdout
}