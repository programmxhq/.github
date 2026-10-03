# apify/cheerio-scraper — partial teardown (source-derived)

- **Source:** github.com/apify/actor-scraper @ `7918b1f` (2026-09-21), `packages/actor-scraper/cheerio-scraper`. Prefix `AS` = `apify/actor-scraper@7918b1f:packages/`.
- **Owner class:** house (author "Apify Technologies", `AS actor-scraper/cheerio-scraper/package.json:31`).
- **Claimed users (UNVERIFIED, WebSearch summary 2026-10-03):** 13K users, 5.0 stars.

## Input schema (`AS actor-scraper/cheerio-scraper/INPUT_SCHEMA.json`)
Required `startUrls`, `pageFunction`, `proxyConfiguration`. 29 fields; same crawl controls as Web Scraper minus browser options, plus HTTP-specific ones:
- `additionalMimeTypes` (L114, default []), `suggestResponseEncoding` (L122), `forceResponseEncoding` (L128, false), `ignoreSslErrors` (L134, false).
- `proxyRotation` (L84, default RECOMMENDED), `maxRequestRetries` (L156, 3), `maxConcurrency` (L187, 50), `pageLoadTimeoutSecs` (L194, 60).

## Output
Same payload helper as Web Scraper: page-function result + `#error` + `#debug` (`AS scraper-tools/src/tools.ts:118-145`; pushed `crawler_setup.ts:389`).

## Crawler type
HTTP: Crawlee `CheerioCrawler` (`AS actor-scraper/cheerio-scraper/src/internals/crawler_setup.ts:230`); `@crawlee/cheerio ^3.18.0` (`package.json:9`).

## Anti-bot / reliability
- User-supplied proxy via `Actor.createProxyConfiguration` (`crawler_setup.ts:169`); no hard-coded group.
- Session pool always on, cookies per session (`crawler_setup.ts:202-210`); rotation mode maps to session `maxUsageCount` (`crawler_setup.ts:96`; `AS scraper-tools/src/consts.ts:57-61`), UNTIL_FAILURE → pool size 1 (`crawler_setup.ts:218-220`).
- No header-generator/fingerprint/captcha code in package (grep).
- Event-loop overload ratio raised because Cheerio parsing is synchronous (`crawler_setup.ts:195-199`).

## Enumeration
`enqueueLinks` with selector/globs (`crawler_setup.ts:354-370`).

## Charging
None in code (grep). README "Cost of usage" points to platform pricing page; Cheerio = "Simple HTML pages" tier (`README.md:11-13`).

## README
No H1; first H2 "Cost of usage" (`README.md:11`).

## LOC
450 lines in `src/` + 707 shared scraper-tools.

## Needs live data
Pricing, users/runs, rating, deployed version.
