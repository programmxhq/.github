# apify/web-scraper — partial teardown (source-derived)

- **Source:** github.com/apify/actor-scraper @ `7918b1f` (commit date 2026-09-21), monorepo package `packages/actor-scraper/web-scraper`. Shallow clone.
- **Citation prefix:** `AS` = `apify/actor-scraper@7918b1f:packages/`
- **Owner class:** house (`apify` namespace; package.json author "Apify Technologies", `AS actor-scraper/web-scraper/package.json:33`).
- **Store link between this repo and the live Store actor:** README links to `apify.com/apify/web-scraper` from sibling READMEs (e.g. `AS actor-scraper/puppeteer-scraper/README.md:3`). Whether the live build = this commit: **needs live data**.
- **Claimed users (UNVERIFIED, WebSearch summary, 2026-10-03):** 125K total users.

## Input schema (`AS actor-scraper/web-scraper/INPUT_SCHEMA.json`)
Required: `startUrls`, `pageFunction`, `proxyConfiguration`. 39 fields. Key ones:

| Field | Line | Type | Default | Prefill |
|---|---|---|---|---|
| runMode | 7 | select | PRODUCTION | DEVELOPMENT |
| startUrls | 17 | requestListSources | – | crawlee.dev/js |
| respectRobotsTxtFile | 31 | bool | false | true |
| linkSelector | 38 | string | – | `a[href]` |
| globs / pseudoUrls / excludes | 45 / 57 / 65 | array | [] | – |
| pageFunction | 77 | javascript | – | sample fn |
| injectJQuery | 84 | bool | true | – |
| proxyConfiguration | 90 | proxy | `{useApifyProxy:true}` | same |
| proxyRotation | 99 | enum RECOMMENDED / PER_REQUEST / UNTIL_FAILURE | RECOMMENDED | – |
| sessionPoolName | 112 | string | – | – |
| initialCookies | 121 | json | – | [] |
| useChrome / headless | 129 / 136 | bool | false / true | – |
| downloadMedia / downloadCss | 155 / 163 | bool | true / true | – |
| maxRequestRetries | 169 | int | 3 | – |
| maxPagesPerCrawl / maxResultsPerCrawl / maxCrawlingDepth | 176 / 183 / 190 | int | 0 (no limit) | – |
| maxConcurrency | 197 | int | 50 | – |
| pageLoadTimeoutSecs / pageFunctionTimeoutSecs | 204 / 212 | int | 60 / 60 | – |
| waitUntil | 220 | json | `["networkidle2"]` | – |
| closeCookieModals | 263 | bool | false | – |
| maxScrollHeightPixels | 269 | int | 5000 | – |

## Output
- Dataset items = whatever `pageFunction` returns, with `#error` and `#debug` appended to every item (`AS scraper-tools/src/tools.ts:118-145`; pushed at `AS actor-scraper/web-scraper/src/internals/crawler_setup.ts:630-632`).
- Output schema only links to the default dataset (`AS actor-scraper/web-scraper/.actor/output_schema.json`). `actor.json` dataset `fields`/`views` are empty (`.actor/actor.json:10-14`).

## Crawler type
- Browser: Crawlee `PuppeteerCrawler` (`crawler_setup.ts:327`), deps `@crawlee/puppeteer ^3.18.0`, `apify ^3.7.2` (`package.json:10-11`).
- Chrome flag `--disable-dev-shm-usage`; `--disable-web-security` if `ignoreCorsAndCsp` (`crawler_setup.ts:269-270`).

## Anti-bot / reliability
- Proxy: `Actor.createProxyConfiguration(input.proxyConfiguration)` — no hard-coded proxy group (`crawler_setup.ts:284-286`). Proxy group choice is left to the user.
- Session pool on for production runs, cookies persisted per session (`crawler_setup.ts:304-313`). Session reuse count by rotation mode: UNTIL_FAILURE = 1000, PER_REQUEST = 1, RECOMMENDED = Crawlee default (`AS scraper-tools/src/consts.ts:57-61`); UNTIL_FAILURE also caps pool at 1 session (`crawler_setup.ts:320-322`).
- Resource blocking (images/fonts/CSS) when `downloadMedia`/`downloadCss` off (`crawler_setup.ts:161-179`, applied 349-353).
- Cookie-consent dismissal via `idcac-playwright` injectable script (`crawler_setup.ts:30`, `493-497`).
- No fingerprint, header-generator, stealth or captcha code set in this package (grep, none found). Crawlee library defaults may apply; **needs verification**.
- Retries: `maxRequestRetries` default 3 (schema L169) passed at `crawler_setup.ts:282`.

## Enumeration
- Generic link following: `enqueueLinks` with `linkSelector` + globs/pseudoUrls/excludes, depth tracked in `userData` (`crawler_setup.ts:592-620`).
- Optional infinite scroll to `maxScrollHeightPixels` (`crawler_setup.ts:499-503`).

## Charging
- No `Actor.charge` / PPE code anywhere in `packages/` (grep). README: "free to use, but you do pay for Apify platform usage ... $0.04 per CU" on free plan (`AS actor-scraper/web-scraper/README.md:28-30`). Pricing model on Store: **needs live data**.

## README
- H1 `# Web Scraper` (`README.md:1`); H2s include "What is Web Scraper?", "How much does the Web Scraper cost?", "Web Scraper and MCP Server" (`README.md:3,28,55`). No `seoTitle`/keywords in actor.json.

## LOC
- web-scraper `src/` TypeScript: 1,182 lines (crawler_setup.ts 746, bundle.browser.ts 304). Shared `scraper-tools/src`: 707 lines.

## Needs live data
Store title/description/categories, pricing model and price, run counts, 30-day users, rating, build version deployed, issue response, actual default proxy group used by most runs.
