# compass/crawler-google-places (Google Maps Scraper) — partial teardown from a 2022 public fork

**Read this first.** The current Store actor is not public on GitHub (probe of apify/ and owner repo names failed; see INDEX). What exists publicly is a set of forks of an older open-source repo `drobnikj/crawler-google-places`. This teardown uses the newest fork found:

- **Source:** github.com/josiahakinloye/store-crawler-google-places @ `7fa8405` (last commit 2022-11-11). Prefix `GM` = that repo@`7fa8405`:.
- Upstream identity: `package.json` repository/homepage = `github.com/drobnikj/crawler-google-places`, author "Jakub Drobnik" (`GM package.json:13,20,25`). README links its cost tab at `apify.com/drobnikj/crawler-google-places` (`GM README.md:71`). So the Store actor appears to have been published under `drobnikj` before `compass` — **source-derived for 2022; current ownership UNVERIFIED**.
- Last CHANGELOG entry 2022-11-10 (`GM CHANGELOG.md:1-3`). Everything below describes the **2022 code**, not today's build. Fork may contain fork-owner changes: **UNVERIFIED**.
- **Owner class:** disputed. WebSearch summaries say "developed by Compass and maintained by Apify" (tryapify.com / apify.com pages, UNVERIFIED) while use-apify.com calls compass a "community maintainer" (UNVERIFIED).
- **Claimed users (UNVERIFIED):** 596K users, 4.70★ (use-apify.com "Top 25 Most Popular Apify Actors", https://use-apify.com/docs/best-apify-actors/most-popular-actors, stated as read from Store API 2026-09-09); another summary says "over 237,000 users" (undated).

## Input schema (2022) — `GM INPUT_SCHEMA.json`
Required: `proxyConfig` only. 35 fields, including:
- Search: `searchStringsArray` (L7, prefill ["restaurant"]), `startUrls` (L872), `allPlacesNoSearchAction` (L892).
- Geography: `countryCode` (L22), `city` (L513), `state` (L820), `county` (L828), `postalCode` (L834), `lat`/`lng` (L840/846), `zoom` (L852), `maxAutomaticZoomOut` (L859), `customGeolocation` (L866).
- Limits: `maxCrawledPlacesPerSearch` (L520, prefill 10), `maxImages` (L720), `maxReviews` (L727).
- Enrichment toggles (all default false): `includeHistogram` (L696), `includeOpeningHours` (L702), `includePeopleAlsoSearch` (L708), `additionalInfo` (L714), `exportPlaceUrls` (L688).
- Reviews: `oneReviewPerRow` (L736), `reviewsStartDate` (L742), `reviewsSort` (L748, newest), `reviewsTranslation` (L767). Personal-data toggles: `scrapeReviewerName` default **false** (L784), `scrapeReviewerId`/`Url`/`ReviewId`/`ReviewUrl`/`ResponseFromOwnerText` default true (L790-814).
- `language` (L527, default en).

## Output (2022)
Place object built at `GM src/detail_page_handle.js:221-271`: page data (title, address parts, website, phone, categories, etc. from `GM src/place-extractors/general.js`) plus `permanentlyClosed, totalScore, isAdvertisement, rank, placeId, categories, cid, url, searchPageUrl, searchString, location, scrapedAt, popularTimes (opt), openingHours, peopleAlsoSearch, additionalInfo, reviewsCount, reviewsDistribution, imagesCount, imageUrls, reviews, orderBy, gasPrices`. Pushed per place or unwound per review (`detail_page_handle.js:285-287`). Dataset overview view fields: title, totalScore, reviewsCount, street, city, state, countryCode, website, phone, categoryName, url (`GM .actor/actor.json`).

## Crawler type
Browser: `Apify.PuppeteerCrawler` (SDK v2, `GM src/places_crawler.js:111`; `apify ^2.3.2`, `GM package.json:28`).

## Anti-bot (2022)
- Proxy mandatory on platform; **GOOGLE_SERP group explicitly rejected** for Maps (`GM src/utils/input-validation.js:100-108`). No group hard-coded; user picks.
- Session pool + per-session cookies + `useFingerprints: true` (`GM src/main.js:206-221`).
- Captcha: detected (`form#captcha-form`) and thrown to trigger retry; any handler error retires the session (`GM src/places_crawler.js:47-49, 93-96`). No solving.
- Consent screen auto-handling (`places_crawler.js:156-157`); request blocking for speed (`places_crawler.js:128`).
- Browser forced to search language via `--lang` (`main.js:230`); retries `maxPageRetries` default 6 (`main.js:37,216`); 30-min handler timeout for long scrolls (`main.js:215`); max 10 pages per browser (`main.js:37`).
- Concurrency forced to 20 in map-interaction mode (`GM src/utils/input-validation.js:115-121`).

## Enumeration (2022)
- Search page → intercept Google's internal XHR responses (`/search`, `/maps/preview/place`) and parse JSON rather than DOM (`GM src/enqueue_places.js:39-47, 263-265`).
- Scroll the results panel with mouse wheel, 2–3 s jittered waits "to simulate real scrolling" (`enqueue_places.js:339-422`); cap 120 places per search page (`GM src/consts.js:4`).
- Geographic splitting: geocode area via OpenStreetMap Nominatim (polygon GeoJSON) (`GM src/utils/polygon.js:96-106`), then build a point grid over the polygon bounding box sized by zoom-level metres-per-pixel (`polygon.js:120-125, 157-200`) and run one search per grid point. Places outside the polygon filtered (`polygon.js:48-50`).

## Charging
None in 2022 code (grep). README then priced by platform usage: "$5 free usage credits ... up to 2,000 reviews" (`GM README.md:65-69`). Current pricing reported as pay-per-event / "$4 per 1,000 businesses" by tryapify.com (UNVERIFIED).

## README (2022)
No H1; first H2 "What is Google Maps Scraper what does it do?" (`GM README.md:1`); H2s include cost, "advantages over the Google Maps API", "Is it legal to scrape Google Maps?" (`README.md:65,75,82`). actor.json title "Google Maps Scraper".

## LOC
`src/` JavaScript 4,144 lines (general.js 510, misc-utils 472, enqueue_places 427, reviews 342).

## Needs live data
Current input schema (diff vs 2022), current output fields, pricing events and prices, crawler type today (HTTP vs browser), proxy group in use, users/runs/rating, maintainer.
