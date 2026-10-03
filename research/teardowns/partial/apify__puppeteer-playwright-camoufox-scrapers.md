# apify/puppeteer-scraper, apify/playwright-scraper, apify/camoufox-scraper — partial teardown (source-derived)

Grouped because they share one codebase pattern with Web Scraper. Users claimed for these: none found in WebSearch (**needs live data**).

- **Source:** github.com/apify/actor-scraper @ `7918b1f` (2026-09-21). Prefix `AS` = `apify/actor-scraper@7918b1f:packages/actor-scraper/`.
- **Owner class:** house.

| | puppeteer-scraper | playwright-scraper | camoufox-scraper |
|---|---|---|---|
| Crawler class | `PuppeteerCrawler` (`AS puppeteer-scraper/src/internals/crawler_setup.ts:253`) | `PlaywrightCrawler` (`AS playwright-scraper/src/internals/crawler_setup.ts:258`) | `PlaywrightCrawler` with Camoufox Firefox launcher (`AS camoufox-scraper/src/internals/crawler_setup.ts:198-201, 228`) |
| Browser choice | Chrome/Chromium (`useChrome`, schema L119) | `launcher` enum chromium/firefox, default chromium (`AS playwright-scraper/INPUT_SCHEMA.json:113-123`) | `camoufox-js 0.11.2` (`AS camoufox-scraper/package.json:13`) |
| Session pool | on (`crawler_setup.ts:233`) | on (`crawler_setup.ts:238`) | on, cookies per session (`crawler_setup.ts:208-215`) |
| Proxy | user-supplied via `Actor.createProxyConfiguration` | same | same (`crawler_setup.ts:194-196`) |
| LOC (`src/`) | 514 | 508 | 480 |
| Charging code | none (grep) | none | none |

## Camoufox-specific anti-detection inputs (`AS camoufox-scraper/INPUT_SCHEMA.json`)
`os` (L267, linux/windows/macos), `block_images` (L279), `block_webrtc` (L285), `block_webgl` (L291), `disable_coop` (L296), `geoip` (L301, titled "might not fully work with Apify Proxy"), `humanize` cursor speed (L307), `locale` (L313), `fonts` (L319). All spread into `camoufox-js` `launchOptions` (`crawler_setup.ts:199-202`).
- README states Camoufox is "a stealthy fork of Firefox" and warns it is more resource-heavy; use it "only when you need to scrape websites that are able to detect and block Playwright-controlled Chromium / Firefox" (`AS camoufox-scraper/README.md:3,8-10`).

## Shared behaviour
Input schemas mirror Web Scraper (startUrls, globs, pageFunction, proxyRotation, sessionPoolName, maxRequestRetries, maxConcurrency, closeCookieModals, maxScrollHeightPixels; required `startUrls`, `pageFunction`, `proxyConfiguration`). Output = page-function result + `#error`/`#debug` via shared `scraper-tools` (`apify/actor-scraper@7918b1f:packages/scraper-tools/src/tools.ts:118-145`). READMEs have no H1; first H2 "Cost of usage" (`README.md:11` puppeteer/playwright, `:18` camoufox).

## Needs live data
Users, runs, pricing, rating; whether Camoufox Scraper is listed publicly on Store.
