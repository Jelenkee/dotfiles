import { Type } from "typebox";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { TextContent } from "@earendil-works/pi-ai/compat";
import { resolve, join, relative, isAbsolute } from "path";
import { callLLM, createCookieFetch, runCommand } from "./util"
import { homedir } from "os";

export default function (pi: ExtensionAPI) {
  setupTools(pi);
  setupEvents(pi);
  setupCommands(pi);
}

function setupTools(pi: ExtensionAPI) {
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
      articleTitles: Type.Array(Type.String(), {
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
      let answer = await callLLM(model, [`Question: ${params.intent}?\nExtract a detailed answer from the following text. If no good answer found, return '${MYSTIC}.'\n\n${texts.map($ => `<article>${$}</article`).join("\n\n")}`], "you are an information-extracting assistant", ctx.signal, ctx);
      if (answer && answer.includes(MYSTIC)) {
        answer = undefined;
      }
      const text = answer ? answer : `No results found. Examined pages: ${titles.join(", ")}`;
      return {
        content: [{ type: "text", text }],
        details: { titles, intent: params.intent },
      };
    },
    renderCall(args, theme, context) {
      return new Text(theme.fg("toolTitle", "Wikipedia\n") + theme.fg("muted", "Searching: " + args.articleTitles.join(", ")), 0, 0);
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
        "Never assume a claim, product name, version number, or price mentioned by the user is incorrect or fabricated just because it is unfamiliar to you or postdates your training. Your knowledge has a cutoff; the user's information may be more recent and correct.",
        "If a user's message references a specific named entity (product, model, company policy, price, version number, event) that you cannot confidently verify from your own knowledge, you MUST call web_search (or check a public API per the rules above) BEFORE responding, even if no one explicitly asked you to search. Do this in the same turn — do not ask the user to confirm the fact first, and do not tell them they are mistaken without checking.",
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
      renderCall(args, theme, context) {
        return new Text(theme.fg("toolTitle", "Web Search"), 0, 0);
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
        "When using bash tool, always use absolute paths (e.g. /home/joe/awesome) or relative paths starting with './' (e.g ./projects/penny)",
      ],
      parameters: Type.Object({
        _: Type.Enum(["_"])
      }),
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
    if (["write", "edit", "read"].includes(event.toolName)) {
      //@ts-ignore
      let path = typeof event.input.path === "string" ? event.input.path : undefined;
      if (!path) {
        return { block: false }
      }
      const blockReason = await validPath(ctx.cwd, path, event.toolName === "read", ctx.signal);
      if (blockReason != null) {
        return { block: true, reason: blockReason }
      }
    }
  });

  async function validPath(cwd: string, path: string, read: boolean, signal: AbortSignal | undefined): Promise<string | undefined> {
    const absolutePath = resolve(cwd, path);
    if (absolutePath.startsWith(`${homedir()}/.pi/agent`)) {
      return undefined;
    }
    if (read && absolutePath.includes("/node_modules/")) {
      return undefined;
    }
    const gitIgnore = await isGitIgnore(cwd, path, signal);
    if (gitIgnore) {
      return "Not allowed to access gitignored files/folders";
    }
    if (!isInCwdOrTmp(cwd, path)) {
      return `Not allowed to access files outside of cwd (${cwd}) or /tmp`;
    }

  }

  function isInCwdOrTmp(cwd: string, path: string): boolean {
    const absolutePath = resolve(cwd, path);
    cwd = resolve(cwd);
    const relativ = relative(cwd, absolutePath);
    return absolutePath.startsWith("/tmp") || (!relativ || !relativ.startsWith("..") && !isAbsolute(relativ));
  }

  async function isGitIgnore(cwd: string, path: string, signal: AbortSignal | undefined): Promise<boolean> {
    const absolutePath = resolve(cwd, path);
    const result = await runCommand("git", ["check-ignore", absolutePath], {
      cwd,
      signal
    });
    return result[1] === 0;
  }

  pi.on("before_agent_start", async (event, ctx) => {
    const gitBranch = await runCommand("git", ["rev-parse", "--abbrev-ref", "HEAD"], {
      cwd: ctx.cwd,
      signal: ctx.signal,
      timeout: 2000
    });
    const gitText = gitBranch[1] === 0 ? `${ctx.cwd} has a git repository. Currently on branch ${gitBranch[0]}` : `${ctx.cwd} has no git repository. Do not run any git commands.`
    const dateText = `Current date: ${new Date().toISOString().slice(0, 10)}`;
    return {
      systemPrompt: `${event.systemPrompt}\n${gitText}\n${dateText}`
    }
  });

  let startTime: number | undefined = Date.now();
  pi.on("agent_start", async (event, ctx) => {
    startTime = Date.now();
  });

  pi.on("agent_settled", async (event, ctx) => {
    if (startTime != null) {
      const duration = Date.now() - startTime;
      if (duration > 30000) {
        const notifyInstalled = (await runCommand("which", ["notify-send"], { signal: ctx.signal }))[1] === 0;
        if (notifyInstalled) {
          await runCommand("notify-send", [`Pi finished after ${Math.floor(duration / 1000)} seconds`], { signal: ctx.signal });
        }
      }
    }
    startTime = undefined;
  });
}

function setupCommands(pi: ExtensionAPI) {
  pi.registerCommand("gojo:dummy", {
    async handler(args, ctx) {
      ctx.ui.notify(pi.getActiveTools() + "-" + JSON.stringify(pi.getAllTools().map($ => $.name)))
    }
  })
}

Array.prototype.sample = function () {
  return this[Math.floor(Math.random() * this.length)];
}

declare global {
  interface Array<T> {
    sample(): T;
  }
}