# Partial teardowns — index

Teardown agent (opus), 2026-10-03. Offline-prep mode: apify.com and api.apify.com are blocked, so nothing here is live-verified.

- **Source-derived** = read from a cloned repo; every claim in the per-actor file cites `repo@sha:path:line`.
- **UNVERIFIED** = WebSearch summaries of third-party pages (mainly use-apify.com, tryapify.com, gtm-api.com) and of apify.com pages. These summaries sometimes conflict with each other. Search summaries do not give the date a figure was read, unless the page itself stated one.
- Clones (shallow) are in the session scratchpad under `teardowns/`. They are not committed.

## Candidate list: about 30 most-used Store actors (UNVERIFIED)
The main anchor is use-apify.com "Top 25 Most Popular Apify Actors (2026)", which says its figures were read from the Store API on 2026-09-09. Only its top 5 appeared in the summaries; the remaining rows come from per-actor searches. Treat the order as rough.

| # | Actor | Claimed total users (UNVERIFIED) | Owner class (UNVERIFIED) | Public source? | File |
|---|---|---|---|---|---|
| 1 | compass/crawler-google-places | 596K | disputed | 2022 fork only | compass__crawler-google-places.md |
| 2 | apify/instagram-scraper | 388K (or 415K) | house | no | apify__instagram-scraper.md |
| 3 | clockworks/tiktok-scraper | 275K (or 217K) | disputed | no | clockworks__tiktok-scraper.md |
| 4 | apify/instagram-profile-scraper | 214K (216K / 93K) | house | no | apify__instagram-profile-scraper.md |
| 5 | apify/rag-web-browser | 184K | house | **yes (current)** | apify__rag-web-browser.md |
| 6 | apify/google-search-scraper | 179K | house | no | apify__google-search-scraper.md |
| 7 | curious_coder/linkedin-jobs-scraper | 148K–166K | independent | no | curious_coder__linkedin-jobs-scraper.md |
| 8 | apify/website-content-crawler | 161K (or 106K) | house | no | apify__website-content-crawler.md |
| 9 | apify/instagram-reel-scraper | 156K | house | no | apify__instagram-reel-scraper.md |
| 10 | apify/instagram-post-scraper | 132K | house | no | apify__instagram-post-scraper.md |
| 11 | streamers/youtube-scraper | 131K (or 113K+) | disputed | no (see bernardo) | streamers__youtube-scraper.md |
| 12 | apify/web-scraper | 125K | house | **yes (current)** | apify__web-scraper.md |
| 13 | apify/facebook-posts-scraper | 117K | house | no | apify__facebook-posts-scraper.md |
| 14 | apidojo/tweet-scraper | 104K | independent | no | apidojo__tweet-scraper.md |
| 15 | compass/google-maps-extractor | 103K | disputed | no | compass__google-maps-extractor.md |
| 16 | harvestapi LinkedIn Profile Scraper (slug unverified) | 69K | independent | no | harvestapi__linkedin-profile-scraper.md |
| 17 | dev_fusion/Linkedin-Profile-Scraper | 63K | independent | no | dev_fusion__Linkedin-Profile-Scraper.md |
| 18 | vdrmota/contact-info-scraper | 61K | independent? | no | vdrmota__contact-info-scraper.md |
| 19 | compass/google-maps-reviews-scraper | 59K | disputed | no | compass__google-maps-reviews-scraper.md |
| 20 | clockworks/free-tiktok-scraper | 58K | disputed | no | clockworks__free-tiktok-scraper.md |
| 21 | apify/instagram-comment-scraper | 57K | house | no | apify__instagram-comment-scraper.md |
| 22 | apify/facebook-comments-scraper | 45K | house | no | apify__facebook-comments-scraper.md |
| 23 | code_crafter/leads-finder | 44K–47K | independent | no | code_crafter__leads-finder.md |
| 24 | apify/facebook-ads-scraper | 40K | house | no | apify__facebook-ads-scraper.md |
| 25 | junglee/amazon-crawler | 23K | independent | no | junglee__amazon-crawler.md |
| 26 | maxcopell/tripadvisor | 15K | independent | no (Store /source-code tab exists, host blocked) | maxcopell__tripadvisor.md |
| 27 | apify/cheerio-scraper | 13K | house | **yes (current)** | apify__cheerio-scraper.md |
| 28 | voyager/booking-scraper | 9.2K | independent | no | voyager__booking-scraper.md |
| 29 | apify/facebook-pages-scraper | – | house | no | apify__facebook-pages-scraper.md |
| 30 | apify/instagram-hashtag-scraper | – | house | no | apify__instagram-hashtag-scraper.md |
| 31 | lukaskrivka/google-maps-with-contact-details | – | independent | no | lukaskrivka__google-maps-with-contact-details.md |
| + | apify/puppeteer-, playwright-, camoufox-scraper | – | house | **yes (current)** | apify__puppeteer-playwright-camoufox-scrapers.md |
| + | bernardo/youtube-scraper | – | independent | yes (2022) | bernardo__youtube-scraper.md |

**House vs independent.** The `apify/*` namespace counts as house. The sources disagree about **compass, clockworks and streamers**:
- Summaries of apify.com and tryapify.com pages say "developed by Compass/Clockworks and maintained by Apify".
- use-apify.com calls them "community maintainers" that "out-rank apify-official Actors".
- One summary calls Compass and Clockworks independent developers.

This needs live data: the owner's `username` and profile in the Store API. Source-derived hint: in 2022 the Google Maps README linked `apify.com/drobnikj/crawler-google-places` (`josiahakinloye/store-crawler-google-places@7fa8405:README.md:72`). So the actor was published under a different username before `compass`.

## Teardown matrix (actors with source)

| Actor | Snapshot | Crawler (Crawlee class) | Anti-bot technique | Proxy | Charging in code | Core LOC |
|---|---|---|---|---|---|---|
| apify/rag-web-browser | 2026-10-02 | Cheerio (SERP) + Playwright-Firefox or Cheerio (pages) | Firefox-only fingerprint generator, media blocking, low retries (1/2) | `GOOGLE_SERP` group hard-coded default for SERP; user proxy for pages | **PPE**: `search`, `fetch`; idempotent; Standby charge endpoint | 3,097 |
| apify/web-scraper | 2026-09-21 | PuppeteerCrawler | session pool + cookie persistence, rotation modes, resource blocking, cookie-modal dismissal (idcac) | user-chosen (Apify Proxy default on) | none (README: platform usage) | 1,182 + 707 shared |
| apify/cheerio-scraper | 2026-09-21 | CheerioCrawler | session pool, rotation modes | user-chosen | none | 450 + 707 |
| apify/puppeteer- / playwright-scraper | 2026-09-21 | Puppeteer / PlaywrightCrawler | session pool, rotation modes | user-chosen | none | ~510 each |
| apify/camoufox-scraper | 2026-09-21 | PlaywrightCrawler + Camoufox (stealth Firefox) | OS/locale/font spoofing, WebRTC/WebGL block, humanized cursor, geoip | user-chosen | none | 480 |
| compass/crawler-google-places | **2022 fork** | PuppeteerCrawler (SDK v2) | `useFingerprints`, session pool, captcha → retire session + retry, consent handling, jittered scroll | user-chosen; **GOOGLE_SERP forbidden** | none (then) | 4,144 |
| bernardo/youtube-scraper | 2022 | PuppeteerCrawler (SDK v2) | session pool, reCAPTCHA → retire + retry, telemetry and media blocking | user-chosen | none | 1,526 |

Other repos cloned but outside the top-30 list (crawler class only, from grep): `apify/actor-screenshot-url` PuppeteerCrawler (`src/main.ts:64`); `apify/actor-beautifulsoup-scraper` BeautifulSoupCrawler, Python (`actor_beautifulsoup_scraper/main.py:13`); `apify/actor-llmstxt-generator` BeautifulSoupCrawler subclass, Python (`src/crawler.py:74`); `dtrungtin/actor-airbnb-scraper` BasicCrawler calling Airbnb's internal JSON API (`src/index.js:80`, `src/api.js:32,88`; 2022); `emastra/actor-google-trends-scraper` PuppeteerCrawler (`src/main.js:70`; 2022). None of these contain charge code (grep).

GitHub probes that failed, meaning the repo is private or does not exist (`git ls-remote`):
- `apify/website-content-crawler`, `apify/actor-website-content-crawler`, `apify/google-search-scraper`, `apify/actor-google-search-scraper`, `apify/instagram-scraper`, `apify/actor-instagram-scraper`
- `apify/instagram-profile-scraper`, `apify/instagram-post-scraper`, `apify/facebook-posts-scraper`, `apify/facebook-ads-scraper`
- `apify/crawler-google-places`, `drobnikj/crawler-google-places`, `compass/crawler-google-places`
- `clockworks/tiktok-scraper`, `streamers/youtube-scraper`, `apidojo/tweet-scraper`, `junglee/amazon-crawler`, `voyager/booking-scraper`, `maxcopell/tripadvisor`
- `vdrmota/contact-info-scraper`, `lukaskrivka/google-maps-with-contact-details`, `harvestapi/linkedin-profile-scraper`, `curious_coder/linkedin-jobs-scraper`
- about 60 other `apify/actor-*` name guesses

## Cross-cutting observations

**Source-derived.** These are limited to 7 codebases. 5 are Apify house and current; 2 are 2022 snapshots.
1. **Every top actor whose source we found is either an Apify house actor or a 2022 snapshot.** No public source was found for any current independent top-30 actor. The commercial leaders in maps, social and LinkedIn are closed.
2. **Browser vs HTTP.** In the current house code, the generic scrapers offer both. The newest product, RAG Web Browser, defaults to **raw HTTP** (`scrapingTool` default `raw-http`) and uses Playwright only on request. The two 2022 vertical scrapers (Maps, YouTube) were browser-only (Puppeteer).
3. **API interception beats DOM.** The 2022 Maps code parsed Google's internal XHR JSON while scrolling. The 2022 Airbnb code called Airbnb's JSON API directly through BasicCrawler. Both read structured responses instead of scraping HTML.
4. **Anti-bot is mostly Crawlee primitives**: session pool, cookie persistence, retiring a session on captcha or bad status, resource blocking and fingerprints. None of the code we found solves captchas; on a captcha it retires the session and retries. The only stealth-browser code is the Camoufox scraper.
5. **Proxy choice is pushed to the user.** Only RAG Web Browser hard-codes a group (`GOOGLE_SERP`, which accepts only GOOGLE_SERP or SHADER). The Maps code explicitly *forbids* GOOGLE_SERP. No code hard-codes RESIDENTIAL; it shows up only as a hint string in the YouTube proxy helper.
6. **Enumeration by geography.** The Maps actor got around Google's cap of about 120 results per search by geocoding the area (Nominatim polygon) and running one search per grid point, with grid spacing derived from the zoom level.
7. **Charging granularity (one data point).** RAG Web Browser charges PPE per *unit of value*: one event per successful query and one per fetched page. Its design rules:
   - charge only after results exist;
   - use an idempotency key so retries do not double-charge;
   - never fail a request because the charge failed;
   - leave `apify-actor-start` to the platform.

   Its sibling `url-to-markdown` prices browser and HTTP fetches differently. The generic scrapers and the 2022 actors have no charge code (usage-based).
8. **Input conventions.** Every scraper input schema requires `proxyConfiguration`/`proxyConfig` with default `{useApifyProxy: true}`. Limits default to 0 (no limit) in the generic scrapers. The Maps code defaults to the more privacy-preserving option for reviewer names (`scrapeReviewerName` false).

**UNVERIFIED (from search summaries).**
- Lead categories by claimed users: Google Maps, Instagram (6 of the candidate rows are apify/instagram-* actors), TikTok, LinkedIn and Facebook.
- Several top actors are reported to have moved to pay-per-event pricing (Maps Reviews; YouTube since 2025-11-07).
- Compass and Clockworks are reported to lead 30-day runs (177.8M and 112.4M).

## Needs live data (all actors)
For every actor:
- Store metadata, user, run and rating figures, and the pricing model and prices
- Current input and output schemas
- Crawler type in production, default memory, and proxy group

Also needed: owner usernames, which settle the house vs independent question. For actors with public source, the build version deployed to Store also needs checking.
