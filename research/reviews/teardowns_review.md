# Review: research/teardowns/partial/

Reviewer: review-agent (opus), 2026-10-03. Adversarial review of INDEX.md, 6 source-derived teardowns and 27 closed-source stubs. Each citation was checked against the shallow clones in the session scratchpad (`scratchpad/teardowns/`). I confirmed that each clone's HEAD matches the cited sha: actor-scraper `7918b1f`, actor-rag-web-browser `b2dd455`, store-crawler-google-places `7fa8405`, actor-youtube-scraper `cbf2dba`.

## Verdict: PASS WITH FIXES

The code citations are reliable. 40 of the 44 citations checked were exact, and the other 4 were off by one line or one count. I fixed all 4. INDEX observation 8 overstated its point, and I corrected it. The weak area is sourcing: most UNVERIFIED figures are labeled but have **no source URL**. I added URLs only where I could trace them. Everything else is flagged below as a residual risk.

## Citation spot-check (44 checked)

AS = `apify/actor-scraper@7918b1f:packages/`, RAG = `apify/actor-rag-web-browser@b2dd455:`, GM = `josiahakinloye/store-crawler-google-places@7fa8405:`, YT = `bernardro/actor-youtube-scraper@cbf2dba:`

| # | File | Citation | Claim | Result |
|---|---|---|---|---|
| 1 | web-scraper | AS actor-scraper/web-scraper/package.json:33 | author "Apify Technologies" | PASS |
| 2 | web-scraper | package.json:10-11 | `@crawlee/puppeteer ^3.18.0`, `apify ^3.7.2` | PASS |
| 3 | web-scraper | crawler_setup.ts:327 | `new PuppeteerCrawler` | PASS |
| 4 | web-scraper | crawler_setup.ts:269-270 | dev-shm flag, `--disable-web-security` if ignoreCorsAndCsp | PASS |
| 5 | web-scraper | crawler_setup.ts:284-286 | `Actor.createProxyConfiguration(input...)`, no group | PASS |
| 6 | web-scraper | crawler_setup.ts:304-313, 320-322 | session pool off in dev runs; UNTIL_FAILURE sets pool size 1 | PASS |
| 7 | web-scraper | AS scraper-tools/src/consts.ts:57-61 | 1000 / 1 / undefined usage counts | PASS |
| 8 | web-scraper | crawler_setup.ts:30, 493-497 | idcac-playwright cookie modal script | PASS |
| 9 | web-scraper | crawler_setup.ts:161-179, 349-353 | resource blocking | PASS |
| 10 | web-scraper | AS scraper-tools/src/tools.ts:118-145 | `#error`/`#debug` appended to each item | PASS |
| 11 | web-scraper | crawler_setup.ts:630-632 | payload pushed | PASS |
| 12 | web-scraper | README.md:28-30 | "$0.04 per CU" on free plan | PASS |
| 13 | web-scraper | INPUT_SCHEMA.json lines 7…269 (21 field lines) and defaults | line numbers and defaults | PASS |
| 14 | web-scraper | INPUT_SCHEMA.json "40 fields" | field count | **FAIL → fixed (39)** |
| 15 | web-scraper | .actor/actor.json:10-14 | empty fields/views | PASS |
| 16 | cheerio | crawler_setup.ts:230 | `new CheerioCrawler` | PASS |
| 17 | cheerio | crawler_setup.ts:202-210, 218-220, 96 | session pool always on, rotation mapping | PASS |
| 18 | cheerio | crawler_setup.ts:195-199 | event-loop overload ratio comment | PASS |
| 19 | cheerio | INPUT_SCHEMA.json L84/114/122/128/134/156/187/194 + defaults | line numbers and defaults | PASS |
| 20 | cheerio | INPUT_SCHEMA.json "29 fields" | field count | **FAIL → fixed (30)** |
| 21 | cheerio | README.md:11-13 | "Cost of usage", "Simple HTML pages" | PASS |
| 22 | pptr/pw/camoufox | puppeteer crawler_setup.ts:253, playwright :258, camoufox :228 | crawler classes | PASS |
| 23 | pptr/pw/camoufox | playwright INPUT_SCHEMA.json:113-123 | launcher enum, default chromium | PASS |
| 24 | pptr/pw/camoufox | camoufox package.json:13 | `camoufox-js 0.11.2` | PASS |
| 25 | pptr/pw/camoufox | camoufox INPUT_SCHEMA L267…319 | 9 anti-detection inputs; geoip title warning | PASS |
| 26 | pptr/pw/camoufox | camoufox README.md:3, 8-10 | "stealthy fork of Firefox", resource warning | PASS |
| 27 | pptr/pw/camoufox | LOC 514 / 508 / 480 | wc -l | PASS |
| 28 | rag | RAG src/input.ts:129-130 | only GOOGLE_SERP or SHADER allowed | PASS |
| 29 | rag | RAG src/input.ts:170-176 | SERP proxy group, desiredConcurrency 1 | PASS |
| 30 | rag | RAG src/crawlers.ts:104, 266, 288 | Cheerio SERP; Playwright/Cheerio content | PASS |
| 31 | rag | RAG src/crawlers.ts:118-125 | search charged once, only if results > 0 | PASS |
| 32 | rag | RAG src/utils.ts:150-161 | totalPages = ceil(maxResults/10)+1; http when GOOGLE_SERP | PASS |
| 33 | rag | RAG src/mini-actors.ts:14-15, 56-62, 72-77 | actor-start left to platform; event names | PASS |
| 34 | rag | RAG src/charging.ts:8, 15-19, 50-73, 91-111 | 5 s timeout, idempotency key, Standby charge endpoint, charge errors not thrown | PASS |
| 35 | rag | actor input_schema.json L7…139 + defaults; required `query` | line numbers and defaults | PASS |
| 36 | rag | src/types.ts:144-173; request-handler.ts:145-159; actor.json views; LOC 3,097 | output shape; FAILED items pushed | PASS |
| 37 | maps | GM package.json:13,20,25,28 | drobnikj upstream; `apify ^2.3.2` | PASS |
| 38 | maps | GM README.md:72 | drobnikj cost-tab link | **FAIL → fixed (:71)** |
| 39 | maps | GM src/utils/input-validation.js:100-108, 115-121 | GOOGLE_SERP rejected; concurrency 20 | PASS |
| 40 | maps | GM src/main.js:37, 206-221, 215, 216, 230 | fingerprints, session pool, retries 6, 30-minute timeout, `--lang` | PASS |
| 41 | maps | GM src/places_crawler.js:47-49, 93-96, 111, 128, 156-157 | captcha → throw; session retired; consent; blocking | PASS |
| 42 | maps | GM INPUT_SCHEMA.json (29 line refs, 35 fields, required proxyConfig, scrapeReviewerName false) | lines and defaults | PASS |
| 43 | maps | consts.js:4; enqueue_places.js:39-47, 263-265; polygon.js:48-50, 96-106, 120-125, 157-200 | 120 cap, XHR interception, Nominatim, zoom grid | PASS |
| 44 | maps | enqueue_places.js:339-421 | jittered 2-3 s wait | **minor FAIL → fixed (339-422; the wait is at L422)** |
| 45 | youtube | YT main.js:103-108, 111-131, 152-162; utility.js:488,520; crawler_utils.js:214-230; README.md:5,9; schema L6…104; LOC 1,526 | all claims | PASS |

The 5 extra repos listed in INDEX (screenshot-url `main.ts:64`, beautifulsoup `main.py:13`, llmstxt `crawler.py:74`, airbnb `index.js:80` / `api.js:32,88`, trends `main.js:70`) all PASS. A grep for charge code in them returns 0 hits.

## Issues found

1. **Field counts off by one** in web-scraper (40 → 39) and cheerio-scraper (29 → 30) (`len(properties)`). Fixed.
2. **Line drift**: `GM README.md:72` should be `:71`, in both compass__crawler-google-places.md and INDEX.md. `enqueue_places.js:339-421` should be `:339-422`. Fixed.
3. **INDEX obs. 8 overstated**: it said "every scraper input schema requires proxyConfiguration". RAG Web Browser requires only `query` (proxyConfiguration is optional there, with the same default). Fixed.
4. **INDEX "7 codebases, 5 house current" is inconsistent**: the matrix covers 8 actors (6 current house actors from 2 repos, plus 2 from 2022). Fixed wording.
5. **INDEX obs. 5 incomplete**: the RESIDENTIAL hint string also appears in the identical helper in `emastra/actor-google-trends-scraper` (`src/utils.js:236,265`). Fixed. (The Airbnb `RESIDENTIAL` constant is a location type, not a proxy group.)
6. **Missing source URLs (main finding)**: almost every UNVERIFIED figure says "(summary)" or names a site but gives no URL. This applies to the 27 stubs, the web-scraper 125K, the cheerio 13K / 5.0★, the use-apify "community maintainer" quotes, the tryapify "$4 per 1,000 businesses", the YouTube PPE date and prices, and the INDEX "177.8M / 112.4M" 30-day runs (177.8M appears in no per-actor file). Everything is labeled UNVERIFIED, so nothing reads as a claim of fact, but the sources cannot be traced. I added URLs only where I could trace them; see Fixes.
7. **Mixed-source ranking**: INDEX row 5 (RAG, 184K, from an apify.com page summary) sits above row 6 (Google Search, 179K), which use-apify.com ranks #5 in its own top 5. The two figures come from different sources and dates, so the order implies a comparison the data does not support. I added a note.
8. **Suspicious figure**: cheerio-scraper "13K users, 5.0 stars" has no source. A perfect rating on a 13K-user actor should be confirmed live before anyone uses it.

The source-derived and UNVERIFIED parts are otherwise kept separate correctly. In INDEX, source-derived observations 1–7 are each supported by the per-actor files and the code. The UNVERIFIED bullets match the stubs: 6 apify/instagram-* rows; PPE for Maps Reviews and YouTube.

**Secrets:** none. I grepped for Apify/GitHub/OpenAI/AWS token patterns, bearer strings, password/secret assignments and long opaque strings. The only "token"/"Bearer" text is quoted code in RAG charging.ts (`Bearer ${token}`), described in prose only.

## Fixes applied (all in research/teardowns/partial/)

- apify__web-scraper.md: 40 fields → 39.
- apify__cheerio-scraper.md: 29 fields → 30.
- compass__crawler-google-places.md: `README.md:72` → `:71`; `enqueue_places.js:339-421` → `:339-422`; added the use-apify.com URL to the 596K figure.
- apify__rag-web-browser.md: added the source URL (https://apify.com/apify/rag-web-browser, via a WebSearch summary run 2026-10-03, still UNVERIFIED) and the 32K monthly / 276 bookmarks that the same summary gave.
- apify__instagram-scraper.md, apify__instagram-profile-scraper.md, clockworks__tiktok-scraper.md, apify__google-search-scraper.md: added https://use-apify.com/docs/best-apify-actors/most-popular-actors to the 2026-09-09 figures. The URL comes from research/desk/LANDSCAPE.md:26-30.
- INDEX.md: anchor URL added; README line `:72` → `:71`; mixed-source ranking note; obs. 5, the obs. 8 wording and the codebase count corrected.

## Residual risks

- Most UNVERIFIED numbers in the stubs still have no URL. Before any of them is used in a decision, re-run the searches and attach URLs, or replace the numbers with live Store API data.
- Owner class (house vs independent) for compass, clockworks and streamers is unresolved and drives INDEX obs. 1.
- The Maps teardown is a third-party fork. Changes made by the fork owner were not diffed against upstream `drobnikj/crawler-google-places` (that upstream is not public).
- Nothing confirms that the public actor-scraper and rag commits are the builds deployed on Store.
- My spot-check covered about 45 of roughly 150 citations. The rest were not opened, though the pass rate (all failures off by one) suggests they are reliable.
