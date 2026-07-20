import { Type } from "typebox";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Api, completeSimple, Model, TextContent } from "@earendil-works/pi-ai/compat";
import { resolve, join } from "path";
import { Cache } from "./util"
import { createHash } from "crypto";

export default function (pi: ExtensionAPI) {
  setupTools(pi);
  setupEvents(pi);
  setupCommands(pi);
}

function setupTools(pi: ExtensionAPI) {
  //const fetchWiki = fetch;
  const exaAPIKeys = (process.env["GOJO_EXA_API_KEYS"] ?? "").split(",")
    .map($ => $.trim())
    .filter(Boolean);
  const fetchWiki = createCookieFetch();
  pi.registerTool({
    name: "wikipedia",
    label: "Wikipedia",
    description: "Search Wikipedia and extract information relevant to a specific intent. Given article titles (can be multiple) and a detailed intent describing what information is needed, this tool finds the best-matching Wikipedia article and returns the extracted content relevant to that intent.",
    promptSnippet: "Search for information on wikipedia",
    promptGuidelines: [
      "Use wikipedia tool for looking up simple facts (use case of hydrazine, lifespan of ladybug, battles in world war 2, movies of brad pitt) or information that is likely to be found on wikipedia.org.",
      exaAPIKeys.length > 0 ? "Prefer wikipedia tool over web_search for factual, encyclopedic, or biographical questions about topics likely to have a dedicated Wikipedia article — people, places, species, historical events, concepts, organizations, etc." : "",
      exaAPIKeys.length > 0 ? "Use web_search tool instead of wikipedia tool when the information is time-sensitive, current, or unlikely to be covered by an encyclopedia article (e.g. current events, recent news, real-time data, or topics that change frequently)." : "",
    ],
    parameters: Type.Object({
      articleTitles: Type.Array(Type.String, {
        minItems: 1,
        maxItems: 3,
        uniqueItems: true,
        description: "List of wikipedia articles which may contain the requested information."
      }),
      intent: Type.String({
        description: "A detailed description of what information is being sought from the article. Used to locate and extract the relevant section(s) of the page rather than returning the whole article.",
        minLength: 6,
      }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      ctx.ui.notify(`Searching '${params.articleTitles}'`);
      let pageIds: number[] = [];
      for (const articleTitle of params.articleTitles) {
        const searchUrl = `https://en.wikipedia.org/w/api.php?action=query&list=search&format=json&srsearch=${encodeURIComponent(articleTitle as string)}&srnamespace=0&srlimit=2&srprop=`;
        const response = await fetchWiki(searchUrl, {
          signal,
          headers: {
            "user-agent": "pi.dev/extension (baumeister@posteo.de)",
          },
        });
        if (!response.ok) {
          throw new Error("Error when searching wikipedia: " + response.status);
        }
        const searchBody = await response.json();
        for (const pageId of searchBody.query.search.map((o: { pageid: number }) => o.pageid)) {
          if (!pageIds.includes(pageId)) {
            pageIds.push(pageId)
          }
        }
      }

      const titles: string[] = [];

      let models = (process.env["GOJO_SUMMARIZE_MODELS"] ?? "")
        .split(",")
        .map($ => $.trim())
        .filter(Boolean);
      if (ctx.model) {
        models.push(ctx.model.id);
      }
      const model = models.flatMap(id => ctx.modelRegistry.getAvailable().filter(mod => mod.id === id)).at(0);
      if (model == null) {
        throw new Error("No model found to summarize wikipedia");
      }

      const texts: string[] = [];
      for (const pageId of pageIds) {
        const parseUrl = `https://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=${pageId}&prop=text`;
        const response = await fetchWiki(parseUrl, {
          signal,
          headers: {
            "user-agent": "pi.dev/extension (baumeister@posteo.de)",
          },
        });
        if (!response.ok) {
          throw new Error("Error when parsing wikipedia: " + response.status);
        }
        const parseBody = await response.json();
        const pageTitle = parseBody.parse.title;
        ctx.ui.notify(`Fetched '${pageTitle}'`);
        titles.push(pageTitle);
        const wikitext = parseBody.parse.text["*"] as string;
        const minifiedText = wikitext
          .slice(0, wikitext.indexOf('id="References"'))
          .replaceAll(/<style.*?<\/style>/gs, "")
          .replaceAll(/<\/[^>]*>/gs, "<>")
          .replaceAll(/<[^>]*>/gs, "</>")
          .replaceAll("&#160;", " ")
          .trim()
        texts.push(minifiedText);

      }
      const MYSTIC = "B8lgoTPOba";
      ctx.ui.notify(`Summarizing '${titles.join(", ")}'`);
      let answer = await callLLM(model, [`Question: ${params.intent}?\nExtract a detailed answer from the following text. If no good answer found, return '${MYSTIC}.'\n\n${texts.map($ => `<article>${$}</article`).join("\n\n")}`], "you are an information-extracting assistant", ctx.signal, ctx);
      if (answer && answer.includes(MYSTIC)) {
        answer = undefined;
      }
      const text = answer ? answer : `No results found. Examined pages: ${titles.join(", ")}`;
      ctx.ui.notify("");
      return {
        content: [{ type: "text", text }],
        details: { titles, intent: params.intent },
      };
    },
    renderResult(result, options, theme, context) {
      //@ts-ignore
      const titles = result.details.titles as string[];
      //@ts-ignore
      const intent = result.details.intent as string;
      let text = (result.content[0] as TextContent).text;
      text = `Pages: ${titles.join(", ")}\nIntent: ${intent}\n\n${text}`
      let formattedText = options.expanded ? text.slice(0, 1000) : text.slice(0, 250);
      if (formattedText.length != text.length) {
        formattedText += "...";
      }

      return new Text(theme.fg("toolOutput", formattedText), 0, 0);
    }
  });


  if (exaAPIKeys.length > 0) {
    type ExaResponse = {
      results: ({
        title: string,
        url: string,
        highlights: string
      })[]
    };
    pi.registerTool({
      name: "web_search",
      label: "Web Search",
      description: "Searches the web and returns a list of relevant results (title, URL, and snippet) for a given query. Use this to find current information, facts, or sources you don't already know.",
      promptSnippet: "Search up-to-date information from the internet",
      promptGuidelines: [
        "Before calling web_search tool, you MUST first check whether the data is available via a free, public, unauthenticated API. If so, use `bash` + `curl` to call it directly instead of web_search.",
        "Do NOT use web_search tool for data that has a well-known public REST API (e.g. GitHub, npm, PyPI, crates.io, Wikipedia REST API, wttr.in, musicbrainz, PokéAPI, HackerNews API, exchange rate APIs). Query the API directly with bash/curl. web_search tool can be used to fetch API documentation",
        "Do NOT use web_search tool for well-known historical facts, basic definitions, or anything you can confidently answer from your own knowledge.",
      ],
      parameters: Type.Object({
        query: Type.String({
          description: "The search query string. Keep it concise and keyword-focused, e.g. 'current Bitcoin price USD' rather than 'what is the price of Bitcoin right now please'.",
          minLength: 2
        }),
        deep: Type.Boolean({
          description: "When true, execute multi-step searches with synthesized results. Use for complex queries requiring cross-referencing multiple sources or iterative search refinement.",
        }),
      }),
      async execute(toolCallId, params, signal, onUpdate, ctx) {
        ctx.ui.notify(`Searching '${params.query}'`);
        const exaUrl = "https://api.exa.ai/search";
        const response = await fetch(exaUrl, {
          signal,
          method: "POST",
          headers: {
            "x-api-key": exaAPIKeys.sample(),
            "content-type": "application/json",
          },
          body: JSON.stringify({
            query: params.query,
            numResults: 5,
            contents: {
              highlights: true
            },
            type: params.deep ? "deep" : "fast"
          })
        });
        if (!response.ok) {
          throw new Error("Error when searching exa: " + response.status);
        }
        const payload = await response.json() as ExaResponse;

        ctx.ui.notify("");
        return {
          content: [{ type: "text", text: JSON.stringify(payload.results) }],
          details: { payload, query: params.query, deep: params.deep },
        };
      },
      renderResult(result, options, theme, context) {
        //@ts-ignore
        const details = result.details.payload as ExaResponse;
        //@ts-ignore
        const query = result.details.query as string;
        //@ts-ignore
        const deep = result.details.deep as boolean;
        let text = details.results.map($ => $.highlights).join("\n\n");
        text = `Query: ${query}\nDeep: ${deep}\n\n${text}`
        let formattedText = options.expanded ? text.slice(0, 1000) : text.slice(0, 300);
        if (formattedText.length != text.length) {
          formattedText += "...";
        }

        return new Text(theme.fg("toolOutput", formattedText), 0, 0);
      }
    });
  }

  pi.on("session_start", async (event, ctx) => {
    pi.registerTool({
      name: "noop",
      label: "Noop",
      description: "Does nothing",
      promptSnippet: "Does nothing",
      promptGuidelines: [
        `Do not create/edit files outside of ${ctx.cwd} (including sub directories) or /tmp (unless explicitly instructed to do so)`,
      ],
      parameters: Type.Enum(["_"]),
      async execute(toolCallId, params, signal, onUpdate, ctx) {
        return {
          content: [{ type: "text", text: "error!!" }],
          details: {},
        };
      }
    });
  })
}

function setupEvents(pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (["write", "edit"].includes(event.toolName)) {
      let path = null;
      if (event.toolName === "write") {
        path = event.input.path as string
      } else if (event.toolName === "edit") {
        path = event.input.path as string
      }
      if (!path) {
        return { block: false }
      }
      const absolutePath = resolve(ctx.cwd, path);
      if (!absolutePath.startsWith("/tmp") && !absolutePath.startsWith(ctx.cwd)) {
        if (!ctx.hasUI || !(await ctx.ui.confirm(`Tool: ${event.toolName}`, `Allow modification of ${absolutePath}`, { signal: ctx.signal }))) {
          return { block: true, reason: `Tool only allowed in /tmp and cwd (${ctx.cwd})` }
        }
      }
    }
  });
}

function setupCommands(pi: ExtensionAPI) {
  pi.registerCommand("gojo:dummy", {
    async handler(args, ctx) {
      ctx.ui.notify("waiting")
    }
  })
}

const llmCache = new Cache("llm", 30 * 24 * 60 * 60 * 1000);

async function callLLM(model: Model<Api> | string, messages: string[], systemPrompt: string | undefined, signal: AbortSignal | undefined, ctx: ExtensionContext): Promise<string | undefined> {
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

function createCookieFetch() {
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

Array.prototype.sample = function () {
  return this[Math.floor(Math.random() * this.length)];
}

declare global {
  interface Array<T> {
    sample(): T;
  }
}