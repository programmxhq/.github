# apify/rag-web-browser — partial teardown (source-derived)

- **Source:** github.com/apify/actor-rag-web-browser @ `b2dd455` (commit date 2026-10-02). Prefix `RAG` = `apify/actor-rag-web-browser@b2dd455:`.
- **Owner class:** house. Repo also builds a second actor, `apify/url-to-markdown` (`RAG src/mini-actors.ts:64-78`).
- **Claimed users (UNVERIFIED, WebSearch summary 2026-10-03 of https://apify.com/apify/rag-web-browser):** 184K total users (same summary: 32K monthly, 276 bookmarks).

## Input schema (`RAG actors/apify_rag-web-browser/.actor/input_schema.json`)
Required: `query`.

| Field | Line | Default | Notes |
|---|---|---|---|
| query | 7 | – | prefill `web browser for RAG pipelines -site:reddit.com`; a URL skips search (README:308-310) |
| maxResults | 15 | 3 | |
| outputFormats | 23 | `["markdown"]` | |
| requestTimeoutSecs | 45 | 40 | hidden |
| serpProxyGroup | 55 | GOOGLE_SERP | hidden; only GOOGLE_SERP or SHADER allowed (`RAG src/input.ts:129-130`) |
| serpMaxRetries | 62 | 2 | |
| proxyConfiguration | 71 | `{useApifyProxy:true}` | for target pages |
| scrapingTool | 84 | raw-http | enum browser-playwright / raw-http (L90-93) |
| removeElementsCssSelector | 99 | nav, footer, script, ... | |
| desiredConcurrency | 115 | 5 | hidden |
| maxRequestRetries | 124 | 1 | |
| dynamicContentWaitSecs | 132 | 10 | |
| removeCookieWarnings | 139 | true | |

## Output (`RAG src/types.ts:144-173`)
`{ text, html, markdown, query, crawl{httpStatusCode, httpStatusMessage, loadedAt, requestStatus, uniqueKey, debug}, searchResult{title, description, rank, url, resultType}, metadata{title, url, redirectedUrl, canonicalUrl, description, author, keywords, languageCode, openGraph[], jsonLd[], headers} }`. Dataset views "overview" and "searchResults" (`actor.json` storages.dataset.views). Failed pages are still pushed with `requestStatus: FAILED` (`RAG src/request-handler.ts:145-159`).

## Crawler type
- Two stages: SERP via `CheerioCrawler` (`RAG src/crawlers.ts:104`) with desiredConcurrency 1 (`RAG src/input.ts:170-176`); content via `PlaywrightCrawler` (Firefox) or `CheerioCrawler` per `scrapingTool` (`RAG src/crawlers.ts:266, 288`).
- Runs in Standby mode as an HTTP server + MCP server (`actor.json` `usesStandbyMode: true`; `RAG src/mcp/server.ts`).

## Anti-bot
- SERP uses Apify Proxy group `GOOGLE_SERP` by default (`RAG src/input.ts:170`); SERP URL switches to `http://` when that group is used (`RAG src/utils.ts:157-161`).
- Playwright: Firefox launcher, fingerprint generator restricted to Firefox, media blocked, `waitUntil: domcontentloaded`, browsers retired after 60 s idle (`RAG src/input.ts:222-262`).
- Low retries: `maxRequestRetries` default 1 for content, 2 for SERP.
- No captcha solving code found (grep).

## Enumeration
Google pagination by `&start=` offset, 10 per page, totalPages = ceil(maxResults/10)+1, dedup across pages, stops when enough unique results or Google returns none (`RAG src/utils.ts:150-161`; `RAG src/crawlers.ts:118-140`).

## Charging (pay-per-event)
- `RAG src/charging.ts` (125 LOC). Events for this actor: `search` (once per query that returned organic results) and `fetch` (once per page, same price for Cheerio and Playwright "at launch") (`RAG src/mini-actors.ts:56-62`). The sibling `url-to-markdown` prices by crawler: `raw-http-result` vs `playwright-result` (`mini-actors.ts:72-77`).
- `apify-actor-start` is left to the platform (`mini-actors.ts:14-15`).
- Idempotency key = `request.uniqueKey` so handler retries do not double-charge (`charging.ts:15-19`); search charged only when results > 0 and only once per query via `isSearchChargeAttempted` flag (`crawlers.ts:118-125`).
- Standby callers charged through `POST {apiBaseUrl}v2/actor-runs/{runId}/charge` with `requestId` and `Idempotency-Key` header (`charging.ts:50-73`); 5 s timeout (`charging.ts:8`). Charge failures are logged, request still served (`charging.ts:91-111`).
- README pricing table restates the three events (`RAG README.md` section "💰 Pricing", actors README lines 298-316).

## README
Repo README H1 `# actor-rag-web-browser`; actor README H1 `# 🌐 RAG Web Browser` (`actors/apify_rag-web-browser/README.md:1`). actor.json title "RAG Web browser"; description mentions "OpenAI Assistants API and RAG pipelines, similar to a web browser in ChatGPT".

## LOC
`src/` TypeScript 3,097 lines (request-handler 416, input 376, crawlers 325, utils 289).

## Needs live data
Event prices per plan, users/runs split Standby vs batch, rating, MCP traffic share.
