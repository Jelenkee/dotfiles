import { resolve, join } from "path";
import { homedir } from "os";
import { mkdir, readdir, readFile, stat, unlink, writeFile } from "fs/promises";

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