import { Type } from "typebox";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import  { Text } from "@earendil-works/pi-tui";
import { complete, TextContent } from "@earendil-works/pi-ai/compat";

export default function (pi: ExtensionAPI) {
  setupTools(pi);
}

function setupTools(pi: ExtensionAPI) {
  //const fetchWiki = fetch;
  const fetchWiki = createCookieFetch();
  pi.registerTool({
    name: "wikipedia",
    label: "Wikipedia",
    description: "Search for information on wikipedia. Returns information",
    promptSnippet: "Search for information on wikipedia",
    promptGuidelines: [
      "Use wikipedia for looking up simple facts (toxcicity of hydrazine, lifespan of ladybug, battles in world war 2, ex-partners of brad pitt) or information that is likely to be found on wikipedia.org.",
      "Prefer wikipedia over web_search if possible."
    ],
    parameters: Type.Object({
      searchTerm: Type.String({
        description: "Short term to search for on wikipedia. Either name of the article or a simple query",
        examples: ["windows 11", "golden gate bridge", "tour de france 2009"],
        minLength: 2,
        maxLength: 80,
      }),
      description: Type.String({
        description: "Detailed description what you want to know from wikipedia.",
        minLength: 8,
      }),
    }),
    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const searchUrl = `https://en.wikipedia.org/w/api.php?action=query&list=search&format=json&srsearch=${encodeURIComponent(params.searchTerm)}&srnamespace=0&srlimit=5&srprop=`;
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
      let pageIds = searchBody.query.search.map((o:{ pageid: number }) => o.pageid);
      ctx.ui.notify(`Searching '${params.searchTerm}'`);

      const titles = [];

      for (const pageId of pageIds) {
        const parseUrl = `https://en.wikipedia.org/w/api.php?action=parse&format=json&pageid=${pageId}&prop=wikitext`;
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
        const model = ctx.model;
        if (model == null) {
          throw new Error("No model found to summarize wikipedia");
        }
        const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
        if (!auth.ok || !auth.apiKey) {
          throw new Error(auth.ok ? `No API key for ${model.provider}` : auth.error);
        }
        const MYSTIC = "B8lgoTPOba";
        const wikitext = parseBody.parse.wikitext["*"] as string;
        let minifiedText = wikitext
          .replaceAll(/{{.*?}}/g, "")
          .replaceAll(/<ref.*?<\/ref>/g, "")
          .replaceAll(/\[\[File:.*?\]\]/g, "")
          .trim();

        let answer = await complete(model, {
          messages: [
            {
              role: "user",
              content: `Question: ${params.description}\nExtract a detailed answer from the following text. If no good answer found, return '${MYSTIC}.'\n\n${minifiedText}`,
              timestamp: Date.now()
            },
          ]
        }, { apiKey: auth.apiKey, headers: auth.headers, env: auth.env, signal: signal });
        if (answer.stopReason == "stop" && answer.content.length > 0) {
          let content = answer.content.filter($ => $.type === "text").filter($ => !$.text.includes(MYSTIC)).map($ => $.text).join("\n");
          if (content.length > 2) {
            ctx.ui.notify("");
            return {
              content: [{ type: "text", text: content }],
              details: {},
            };
          }
        }
      }
      ctx.ui.notify("");
      return {
        content: [{ type: "text", text: `No results found. Examined pages: ${titles.join(", ")}` }],
        details: {},
      };
    },
    renderResult(result, options, theme, context) {
      const text=(result.content[0] as TextContent).text;
      let formattedText=options.expanded?text.slice(0,500):text.slice(0,150);
      if (formattedText.length!=text.length){
        formattedText+="...";
      }
      
      return new Text(theme.fg("toolOutput",formattedText), 0,0);
    }
  });
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