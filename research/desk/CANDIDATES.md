# Candidate actors (desk research)

Status: **UNVERIFIED throughout.** Competitor names, prices and API-status claims come from WebSearch snippets obtained 2026-10-03; nothing was read live. Competitor counts are "actors surfaced in one search" and are a floor, not a census. Phase 3 replaces every number here.

Exclusions already applied: ProgrammX's own four actors (PROGRAMMX_LIVE.md); Apify-owned heads (Instagram, Google Search, Booking, TripAdvisor, Airbnb, Pinterest, Facebook); dominant third-party heads (Google Maps/compass, TikTok/clockworks, LinkedIn, Amazon, Zillow, Indeed, Twitter/X, YouTube); sources with a free official API that covers the use case (Companies House, Ticketmaster Discovery, Hacker News, Product Hunt, Reddit-via-API is paid but Store is saturated, CoinGecko/DexScreener, Bluesky, Greenhouse/Lever boards, UK Contracts Finder/TED/SAM.gov, Land Registry, DVLA/MOT, FCA register, Apple iTunes Search/RSS, arXiv/PubMed/Semantic Scholar, SEC EDGAR, Steam store API (undocumented but free), The Gazette data feed).

## Scoring method

Each criterion 1-5. Gates: `L` (login) = 1 or `A` (free official API exists) <= 2 -> candidate marked OUT regardless of total. Fixed-population sources (directories that change slowly) get `P` <= 2 and are OUT per the user's rule.

| Code | Criterion | Weight | How scored (desk) |
|---|---|---|---|
| P | Data perishability | 2.0 | 5 = changes hourly/daily (listings, prices, odds); 3 = weekly; 1 = static directory |
| R | Repeat usage shape | 2.0 | 5 = natural schedule/monitor or per-record lookup; 3 = periodic batch; 1 = one-off list pull |
| D | Source demand / search volume | 1.5 | Proxy signals only: number of competing actors and their visible user counts, "most scraped" lists, dev.to/blog chatter. 5 = global head-adjacent; 3 = national mainstream; 1 = micro-niche. No keyword-tool data was available; UNVERIFIED |
| L | Reachable without login | 1.0 | 5 = fully public; 3 = partial (some fields gated); 1 = login wall (gate) |
| A | No free official API | 1.5 | 5 = none at all; 4 = partner/approval-gated or paid; 3 = free aggregator covers part; <= 2 = free official API (gate) |
| C | Proxy cost < $0.50/1k rows | 1.0 | See cost model below. 5 = JSON endpoint, many rows/request; 3 = HTML list pages; 1 = browser render, 1 row/page |
| H | Not head-on vs Apify-owned/dominant | 1.5 | 5 = 0-1 competitors found; 4 = 2-3; 3 = 4-6; 2 = 7-10; 1 = Apify-owned or > 10 |
| E | Easy build (no browser, clean JSON/HTML, < ~300 lines core) | 1.0 | 5 = JSON endpoint; 3 = HTML with embedded state; 1 = browser + anti-bot |

Weighted total = 2P + 2R + 1.5D + 1L + 1.5A + 1C + 1.5H + 1E. Max 57.5.

### Proxy cost model (UNVERIFIED inputs)

- Decodo residential: $4/GB pay-as-you-go, $3.75/GB (3 GB plan) down to $2.00/GB at 1 TB (https://decodo.com/proxies/residential-proxies ; https://proxygraphy.com/smartproxy-pricing-plans/ , 2026). Apify's own residential proxy is priced per GB on top of plan; not captured this run.
- Budget of $0.50 per 1,000 rows at $4/GB = **125 MB per 1,000 rows = 125 KB per row** all-in.
- JSON list endpoint returning 20-50 rows in a 50-200 KB response: 1-10 KB/row -> $0.004-$0.04 per 1k rows. Passes with 10x headroom.
- HTML list page (200-600 KB compressed, 20-30 rows): 10-30 KB/row -> $0.04-$0.12 per 1k. Passes.
- HTML detail page per row (300 KB-1 MB): $1.20-$4.00 per 1k. **Fails** unless detail enrichment is an optional, separately-charged event.
- Browser render per row (1-3 MB incl. assets, even with asset blocking ~500 KB): $2-$12 per 1k. **Fails.**
- Datacenter proxies (~10-20x cheaper per GB) pass almost anything, but most targets here block them; the Phase 4 probe must test datacenter first, then residential.

Rule used for `C`: 5 if JSON list endpoint is believed to exist; 4 if HTML list pages suffice; 3 if detail pages needed for core fields or anti-bot likely forces residential; 2 if browser needed for some paths; 1 if browser needed for every row.

## Scored candidates

Competitors column: usernames surfaced by WebSearch (floor). Official API column: what search said about an official API.

| # | Candidate (shape) | P | R | D | L | A | C | H | E | Total | Competitors surfaced (UNVERIFIED) | Official API status (UNVERIFIED) | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **PSX (Pakistan Stock Exchange) data-portal feed**: daily quotes, company announcements, indices from dps.psx.com.pk; per-symbol lookup + end-of-day feed | 5 | 5 | 2 | 5 | 5 | 5 | 5 | 4 | **52.0** | none found on Store; GitHub unofficial clients umairsandhu/psx-dps, alihamza098/psx-stock-screener; parse.bot listing | "PSX does not publish a public developer API"; paid licence via marketdatarequest@psx.com.pk | Risks: PSX "aggressively enforces IP rights" (legal review needed); portal nodes intermittently 404 on data routes (reliability). Small market. |
| 2 | **Vinted new-listing & price-drop monitor**, multi-market (UK/DE/FR/…): saved-search URL in, only-new items out | 5 | 5 | 4 | 5 | 5 | 5 | 2 | 4 | **50.5** | louisdeconinck, 123webdata, scraping_empire, kazkn (x2), automation-lab, vonsensey | No public API; Vinted Pro API gated (EUR 30/mo seller account + allowlist) | Incumbents are batch scrapers; one claims to beat the 960-item cap. Internal /api/v2/catalog endpoints exist per dev.to; verify. |
| 3 | **UK mortgage rate monitor**: lender best-buy tables + Moneyfacts/MoneySuperMarket, daily diff | 5 | 5 | 3 | 5 | 5 | 4 | 4 | 3 | **50.0** | none UK-specific found; US analogues parseforge (Bankrate), ahmed_jasarevic (LendingTree), crawlerbros; studio-amba MoneySuperMarket scraper covers mortgages generically | No official API for lender tables; Bank of England has free stats but not product rates | Audience: UK brokers, fintechs, journalists. Build cost: one parser per lender (fragmented). |
| 4 | **Generic back-in-stock / price-change monitor** for product URLs (Shopify + major UK/EU retailers) | 5 | 5 | 4 | 5 | 5 | 4 | 3 | 3 | **50.0** | that_red_bird (restock-monitor), s_actors (Walmart), pepeschuster (Shopify), scrapebench (Shopify change tracker), yugenox (IKEA) | None | Differentiator would be retailer adapters + charge-only-on-change. Generic = weak SEO (H9). |
| 5 | **Marktplaats / Wallapop / Subito classifieds monitor** (NL/ES/IT) | 5 | 5 | 3 | 5 | 5 | 4 | 3 | 4 | **49.5** | Marktplaats: solidcode, crawloop, 123webdata; Wallapop: ivanvs, seretalabs, rastriq, tagadanar, datacut (deprecated); Subito: 1 | None | Wallapop incumbent says internal API, no browser. |
| 6 | **Oddschecker UK odds comparison** (per-event lookup + pre-match line movement) | 5 | 5 | 5 | 5 | 4 | 3 | 4 | 2 | **49.5** | none Oddschecker-specific; generic odds: sian.agency, scrapesage, lulzasaur (SBR), abotapi, parseforge, harvest, thatmike1 (BetExplorer) | The Odds API is paid with a small free tier (third party, not official) | Cloudflare likely; legal/ToS review; strong demand. |
| 7 | **Argos / Currys / Screwfix price & stock monitor** (UK retail) | 5 | 5 | 3 | 5 | 5 | 4 | 3 | 4 | **49.5** | Argos: 123webdata, powerai, sync-network, dromb, mynewhome, muhammetakkurtt (stock checker), wibuild.in (reviews); Currys: sian.agency; Screwfix: sian.agency | None | Argos crowded; Currys/Screwfix thin. |
| 8 | **Lulu / Carrefour UAE grocery price monitor** (GCC) | 5 | 5 | 3 | 5 | 5 | 4 | 3 | 4 | **49.5** | price_matters (lulu, carrefour), boring_internet_explorer (Lulu, 6 GCC markets), blackfalcondata (Carrefour GTINs) | None | Incumbents look low-effort (slug "scrapper"); GCC pricing teams are a real buyer. |
| 9 | Kleinanzeigen.de saved-search monitor | 5 | 5 | 4 | 5 | 5 | 4 | 2 | 3 | 48.5 | beatanalytics, 0nixion, velvety_bedbug, crawloop, shahidirfan, santamaria-automations, automation-lab, epicscrapers, lowlanddata | None ("no official Kleinanzeigen API") | 9+ incumbents. |
| 10 | Trustpilot new-review monitor | 4 | 5 | 5 | 5 | 5 | 5 | 1 | 4 | 48.5 | webdata_labs, zen-studio, parsebird, automation-lab (2.4K users), bovi, intelscrape, scrapeunblocker, unfenced-group, diopside, automation_craft, johnvc | Official API enterprise-only, waitlist | > 10 incumbents; H1 gate (dominant) -> treat as OUT unless H8 shows unhealthy incumbents. |
| 11 | Bayt / Naukrigulf / Rozee.pk job feeds (Gulf + PK) | 5 | 5 | 3 | 5 | 5 | 4 | 3 | 3 | 48.5 | Rozee: memo23, delectable_incubator, jungle_synthesizer, maximedupre; Bayt: easyapi, parsebird, shahidirfan; Naukrigulf: easyapi | None | Monitor shape ("new postings for query") not seen in snippets. |
| 12 | SpareRoom / OpenRent / Gumtree UK rentals monitor | 5 | 5 | 3 | 5 | 5 | 4 | 3 | 3 | 48.5 | vivid-softwares (x2), rover-omniscraper, lexis-solutions, sync-network | None | Rent-to-rent sourcing audience. |
| 13 | Idealo / Geizhals price-history lookup (EAN -> offers) | 5 | 5 | 4 | 5 | 4 | 4 | 3 | 3 | 48.5 | studio-amba (x3), scrapifier, scrapyx | Idealo has partner/affiliate API (gated) | Per-record lookup shape fits MCP. |
| 14 | OLX Pakistan / Foodpanda PK | 5 | 5 | 3 | 5 | 5 | 4 | 3 | 3 | 48.5 | OLX PK: accountable_eel (already monitor + WhatsApp/n8n); Foodpanda: crawlerbros, goat255, shahidirfan, dmitrii_shifo, lentic_clockss, scrapesage | Foodpanda uses PerimeterX | OLX PK incumbent already has the monitor shape. |
| 15 | Otto.de / MediaMarkt / Saturn price monitor (DE) | 5 | 5 | 3 | 5 | 5 | 4 | 2 | 4 | 48.0 | Otto: ecomscrape, lexis-solutions, studio-amba, muhammetakkurtt, solidcode, abotapi; MM/Saturn: unfenced-group, studio-amba (x2), truenorth | None | Embedded product state parseable without browser (per incumbent). |
| 16 | Copart / IAAI salvage lot feed (export buyers PK/Gulf) | 5 | 5 | 4 | 5 | 5 | 3 | 2 | 3 | 47.5 | spry_frame, automation_studio, parseforge (x2), haketa, crawloop (x2), memo23 | None | 8 incumbents; IAAI anti-bot. |
| 17 | Tadawul / DFM / ADX announcements monitor (Gulf exchanges) | 5 | 5 | 2 | 5 | 4 | 5 | 3 | 4 | 47.5 | generous_heavens (Tadawul), nexgendata (Tadawul screener), getascraper (DFM); ADX none found | Tadawul has internal JSON; paid official feeds | Sibling of #1; ADX empty. |
| 18 | Shopify App Store review monitor | 4 | 5 | 3 | 5 | 5 | 5 | 2 | 4 | 47.0 | appmarketscraper, fabrikit ($1/1k), fetch_cat (x2, one is "& Monitor"), automation-lab, scrapesignal_labs, scrapesage | None | Monitor already offered by fetch_cat. |
| 19 | Welcome to the Jungle / Stepstone job feeds (FR/DE) | 5 | 5 | 3 | 5 | 5 | 4 | 2 | 3 | 47.0 | WTTJ: fearless_sharpener (deprecated), fetch_cat, orgupdate, bebity, saswave, runtime (deprecated), jobsapi; Stepstone: none surfaced | None | Deprecated incumbents = H8 opportunity; Stepstone unchecked. |
| 20 | Google Play new-review monitor | 4 | 5 | 4 | 5 | 5 | 5 | 1 | 4 | 47.0 | nexgendata, neatrat, webdatalabs, peerless_columbine, digitalstamp (monitor), workmatic, dev-hoss (monitor), herus13, haketa, curious_coder | No public API for other developers' apps | > 10 incumbents incl. monitors -> OUT by H gate. |
| 21 | UK energy / broadband tariff monitor (MoneySuperMarket, Uswitch) | 5 | 5 | 3 | 4 | 5 | 3 | 4 | 2 | 47.0 | studio-amba (MoneySuperMarket) | None | Quote flows need postcode input; legal review of comparison-site ToS. |
| 22 | AutoTrader UK listing/price-change monitor | 5 | 4 | 4 | 5 | 5 | 4 | 2 | 3 | 46.5 | parsebird ($0.80/1k), moving_beacon-owner1, shahidirfan, rastriq, calm_builder, epctex, alexist, haketa | Partner-only API | 8 incumbents, none monitor-shaped in snippets. |
| 23 | Rightmove / Zoopla new-listing alerts | 5 | 5 | 5 | 5 | 5 | 3 | 1 | 2 | 46.5 | cynix_dev, femstar, aurumworks, illehius, jungle_synthesizer, automation-lab, igolaizola, lowlanddata (alerts), neverempty, conceivable_extension (deal alerts), signal_lab | None | OUT: > 10 incl. alert actors; incumbents use Playwright + residential. |
| 24 | Eventbrite / Luma / Meetup events feed | 5 | 4 | 4 | 5 | 5 | 4 | 2 | 3 | 46.5 | alexdyn.com, luis.pinto, that_red_bird, webdatalabs, memo23, crawlerbros, avinashchby | Eventbrite public search API removed Feb 2020; Meetup API needs Pro subscription | Crowded; Luma-only monitor not seen. |
| 25 | Carwow / Cinch / Motors.co.uk used cars (UK) | 5 | 4 | 3 | 5 | 5 | 4 | 3 | 3 | 46.5 | Carwow: lexis-solutions, parseforge (x2), miladamirzadeh; Cinch: getascraper; Motors: 1 | None | |
| 26 | Etimad / GCC / PPRA tenders feed | 5 | 5 | 3 | 4 | 4 | 4 | 3 | 3 | 46.0 | Etimad: jungle_synthesizer, publicmoney, dottti; PPRA/EPADS: blessed_jouster (x2); GCC: complex_intricate_networks; global: paduchak | Some portals partly login-gated | |
| 27 | mobile.de / AutoScout24 monitor (DE/EU cars) | 5 | 4 | 4 | 5 | 5 | 3 | 2 | 3 | 45.5 | 3x1t, s-r, dev00, ivanvs, crawloop, memo23, webdata_labs; mobile.de: 1 | Dealer-only API | AutoScout anti-bot. |
| 28 | AI tool directories (TAAFT / Futurepedia / FutureTools) new-launch feed | 4 | 4 | 3 | 5 | 5 | 4 | 3 | 4 | 45.5 | crawlerbros ($3/1k), benthepythondev (x2), scrapesage, automation-lab | None | |
| 29 | UK property auctions catalogue (Savills/Allsop/EIG) | 5 | 4 | 2 | 5 | 5 | 4 | 3 | 3 | 45.0 | Savills: nocodeventure, shahidirfan, rigelbytes, stealth_mode; auction houses: none | None | |
| 30 | Chrome Web Store extension stats tracker | 3 | 4 | 3 | 5 | 5 | 5 | 3 | 4 | 44.5 | datamule, haktelaren, parseforge, scrapers_lat, dariomory | Official API retired | Weekly cadence only. |
| 31 | The Gazette insolvency monitor | 5 | 5 | 3 | 5 | 2 | 5 | 2 | 4 | 44.5 | scrapers_lat, moving_beacon-owner1, nexgenwatch, minimal_ricegrass | **Free official data feed exists** -> OUT (A gate) | |
| 32 | MachineryTrader / Mascus / TruckScout24 | 5 | 4 | 2 | 5 | 5 | 3 | 3 | 3 | 44.0 | parseforge (x2), rastriq, scrapers_lat, crawloop, serp.cheap.ofc | None | |
| 33 | BizBuySell / BusinessesForSale new-listing feed | 5 | 4 | 3 | 5 | 5 | 3 | 2 | 3 | 44.0 | khadinakbar, parsebird, rigelbytes, automation-lab, scrapers_lat, crawloop, abotapi, jungle_synthesizer | None | Akamai. |
| 34 | Gumroad / TPT new-product & price monitor | 4 | 4 | 3 | 5 | 5 | 4 | 2 | 4 | 44.0 | Gumroad: muhammetakkurtt, ahmed_jasarevic, scrapesage, memo23, crawlerbros, tactful_anvil, s7_studio; TPT: crawlerbros | None | Monitor already offered. |
| 35 | G2 / Capterra review monitor | 4 | 5 | 4 | 5 | 5 | 2 | 2 | 2 | 43.5 | sovereigntaylor, novashieldai, samstorm, zen-studio (x2), zhorex, automation-lab, focused_vanguard | None | Aggressive blocking -> cost fails. |
| 36 | UK planning applications (direct Idox portals, monitor) | 5 | 5 | 3 | 5 | 3 | 4 | 2 | 2 | 43.0 | memo23, interactapps (monitor, 24 portals), scrapersdelight, spookyweb, automation-lab, inexhaustible_glass | PlanIt free aggregator covers most councils | |
| 37 | UK court daily listings / tribunal decisions monitor | 5 | 4 | 2 | 5 | 3 | 4 | 3 | 3 | 42.0 | spookyweb (x3 incl. court listings), parseforge, nomad-agent | Find Case Law has free API; CourtServe none | |
| 38 | Website tech-stack lookup (per-domain) | 3 | 4 | 4 | 5 | 4 | 5 | 1 | 4 | 41.5 | automation-lab, clearfetch, footage, webdata_labs, conserving_celerytop, fullspeedtram, nexgensignal, ponderable_hydrometer | Wappalyzer/BuiltWith paid; open fingerprints free | > 10 -> OUT. |
| 39 | Idealista (ES/IT/PT) listings | 5 | 4 | 4 | 5 | 4 | 2 | 2 | 1 | 41.0 | crawloop, sian.agency, rigelbytes, dltik, makework36, lukass, nice_dev | Official API approval-gated with small free quota | Heavy anti-bot -> cost fails. |
| 40 | Clutch.co agencies | 2 | 2 | 3 | 5 | 5 | 4 | 2 | 4 | 36.0 | crawlerbros, parseforge, sian.agency, curious_coder, samstorm, great_pistachio, rigelbytes, crawloop, accountable_eel | None | OUT: fixed population. |
| 41 | Europages / Kompass B2B directories | 2 | 2 | 3 | 5 | 5 | 4 | 2 | 3 | 35.0 | santamaria-automations, ahmed_jasarevic, bovi, rastriq, logiover, crawloop, automation-lab, memo23 | None | OUT: fixed population. |
| 42 | Checkatrade / Yell / Gelbe Seiten / PagesJaunes | 2 | 2 | 3 | 5 | 5 | 4 | 3 | 3 | 34.0 | vulnv, hipersoft, memo23, fatihtahta, saswave, hackteur (GitHub) | None | OUT: fixed population. |
| 43 | WhatClinic / Doctify / wedding vendors (The Knot etc.) | 2 | 2 | 2 | 5 | 5 | 4 | 3 | 3 | 32.5 | haketa, scraptivo, rigelbytes, automation-lab (Practo), parseforge (Doximity, TheKnot), apage, jungle_synthesizer, fortuitous_pirate | None | OUT: fixed population. |
| G1 | Group: Noon / Daraz / Talabat / Deliveroo / Zameen / PakWheels / Bayut / Dubizzle / PropertyFinder (ProgrammX home markets) | 5 | 4 | 3 | 5 | 5 | 4 | 2 | 3 | 45.5 | Noon 6+, Daraz 8+, Talabat 5+, Deliveroo 3+, Zameen 4+, PakWheels 1, Bayut/Dubizzle 6+ (+ programmx PropertyFinder) | None | Documented to show the home-market advantage is already arbitraged away; only PakWheels (1 incumbent at $5/1k) is thin. Re-check live. |

## Shortlist: top 8 by weighted total

Caveat before the list: #1 (PSX) ranks first mainly on the absence of competitors and low proxy cost, with the weakest demand score of the eight; #6 (Oddschecker) ranks on demand with the hardest anti-bot. The census will likely reorder these. The common thread across the eight is **monitor / per-record-lookup shape on perishable, public, JSON-friendly sources with <= 3 healthy incumbents**.

### S1. PSX data-portal feed (52.0)
- Public URL patterns to probe (hypothesised from search snippets; confirm live): `https://dps.psx.com.pk/` (landing), `https://dps.psx.com.pk/downloads` (closing-price files), per-company pages under `https://dps.psx.com.pk/company/{SYMBOL}`, index and market-summary pages linked from the landing page. The GitHub client umairsandhu/psx-dps documents the actual routes; clone it first (github.com is reachable).
- Verify live: (a) which routes return JSON vs HTML; (b) node flakiness ("some nodes 404 on data routes" per search) and whether a retry-on-404 policy fixes it; (c) PSX terms of use and the data-licence wording; (d) Store search for "PSX", "Pakistan stock" returns nothing.
- Probe definition: 3 request classes x 20 requests each: market-summary page, 20 per-symbol pages (symbols from the downloads list), 1 downloads file. Record bytes, status, latency on datacenter and residential. Expected rows/request: market summary ~500+ symbols in one response (so cost per 1k rows is near zero); per-symbol page = 1 row (only used for lookup event).

### S2. Vinted new-listing & price-drop monitor (50.5)
- URL patterns: public catalog search `https://www.vinted.co.uk/catalog?search_text={q}&order=newest_first&price_to=...` and the equivalent on `.de/.fr/.es/.it/.nl/.pl`; internal JSON reportedly at `https://www.vinted.{tld}/api/v2/catalog/items?search_text=...&per_page=96&order=newest_first` (from dev.to guide; needs a session cookie from the HTML page first). Treat as hypothesis.
- Verify live: cookie bootstrap requirement; per_page cap; 960-item cap behaviour; datacenter vs residential block rate; rate limits per IP; whether `item_id` is monotonic (cheap "new since last run" cursor).
- Probe definition: 5 saved-search URLs x 3 markets, 10 pages each = 150 requests, on datacenter then residential; measure bytes/row (expect 96 rows per ~150-300 KB response -> ~2-3 KB/row).

### S3. UK mortgage rate monitor (50.0)
- URL patterns: lender rate pages, e.g. `https://www.halifax.co.uk/mortgages/mortgage-rates.html`, `https://www.nationwide.co.uk/mortgages/...rates`, `https://www.barclays.co.uk/mortgages/mortgage-rates/`, `https://www.hsbc.co.uk/mortgages/our-rates/` (patterns hypothesised; confirm each); aggregator `https://moneyfacts.co.uk/mortgages/...` and `https://www.moneysupermarket.com/mortgages/`.
- Verify live: whether rate tables are server-rendered HTML or JSON; how many of the top-10 lenders publish best-buy tables without a quote form; comparison-site ToS on scraping; whether Bank of England / FCA publish product-level rates for free (would hurt `A`).
- Probe definition: 10 lender pages + 2 aggregator pages, fetched 3x each at 8 h intervals to measure change frequency; expect 20-200 rows per page.

### S4. Generic back-in-stock / price-change monitor with retailer adapters (50.0)
- URL patterns: Shopify `https://{store}/products/{handle}.json` and `/products.json?limit=250&page=n` (public JSON on most Shopify stores); retailer adapters for Argos/Currys/Screwfix product URLs (see S7); fallback generic HTML price/availability extraction.
- Verify live: Shopify JSON availability rate across 50 random stores; price/stock fields; whether `products.json` is disabled on larger merchants; how the five incumbents charge (per check vs per change).
- Probe definition: 50 Shopify product JSON URLs + 20 retailer URLs, 2 passes 6 h apart; expect 1 row per product URL but ~5-15 KB per JSON response, so still ~$0.02-0.06 per 1k checks.

### S5. Marktplaats / Wallapop / Subito classifieds monitor (49.5)
- URL patterns: `https://www.marktplaats.nl/q/{q}/#sortBy:SORT_INDEX|sortOrder:DECREASING`; Wallapop `https://es.wallapop.com/app/search?keywords={q}&order_by=newest` with internal `https://api.wallapop.com/api/v3/general/search?keywords=...` (hypothesis from incumbent's "internal API, no browser" claim); Subito `https://www.subito.it/annunci-italia/vendita/usato/?q={q}&o=...`.
- Verify live: JSON endpoints and required headers; geo-blocking (NL/ES/IT residential may be required); per-page row counts; dedupe keys.
- Probe definition: 5 queries x 3 sites x 5 pages = 75 requests, datacenter then country-specific residential.

### S6. Oddschecker UK odds comparison (49.5)
- URL patterns: `https://www.oddschecker.com/football/english/premier-league` (fixture list), `https://www.oddschecker.com/football/english/premier-league/{fixture}/winner` (per-market table); horse racing `https://www.oddschecker.com/horse-racing`.
- Verify live: Cloudflare challenge rate on datacenter vs residential; whether an embedded JSON state exists; legal/ToS position; whether the demand is for pre-match snapshots (fine) or live in-play (not feasible on Apify cadence).
- Probe definition: 10 fixture pages x 3 markets, 2 passes 1 h apart, residential UK; expect 20-40 bookmaker rows per market page (~300-600 KB HTML -> ~15 KB/row, passes). If Cloudflare forces browser, cost fails -> drop.

### S7. Argos / Currys / Screwfix price & stock monitor (49.5)
- URL patterns: Argos `https://www.argos.co.uk/search/{q}/` and `https://www.argos.co.uk/product/{id}`; Currys `https://www.currys.co.uk/search?q={q}`, `.../products/{slug}-{id}.html`; Screwfix `https://www.screwfix.com/search?search={q}`, `.../p/{slug}/{code}`.
- Verify live: embedded JSON state (`__NEXT_DATA__`/`window.__PRELOADED_STATE__`-style) on list and product pages; Akamai/Cloudflare behaviour; store-stock endpoints (Argos stock checker incumbent implies one exists).
- Probe definition: 10 search pages + 30 product pages per retailer, datacenter then UK residential; expect 30-60 rows per search page.

### S8. Lulu / Carrefour UAE grocery price monitor (49.5)
- URL patterns: Lulu `https://www.luluhypermarket.com/en-ae/{category}` and `.../en-ae/search?q={q}`; Carrefour UAE `https://www.carrefouruae.com/mafuae/en/c/{category}` and `.../search?keyword={q}`; both have sibling GCC storefronts (en-sa, en-qa, en-om, en-kw, en-bh).
- Verify live: XHR/JSON product-list endpoints (Carrefour UAE is a MAF/Algolia-style SPA per typical patterns; confirm), per-page sizes, GCC geo-blocking, EAN/GTIN availability (blackfalcondata incumbent exposes GTINs; strong for per-record lookups).
- Probe definition: 10 category pages x 2 retailers x 2 markets (AE, SA), 3 pages deep = 120 requests; expect 24-48 rows/page.

## Next-tier (if any shortlist item fails probes)
#9 Kleinanzeigen monitor, #11 Bayt/Naukrigulf/Rozee feeds, #12 SpareRoom/OpenRent, #13 Idealo/Geizhals EAN lookup, #15 Otto/MediaMarkt, #17 Tadawul/DFM/ADX (natural sibling of S1), #19 WTTJ/Stepstone (deprecated incumbents = H8 opportunity).

## Biggest uncertainties
1. Competitor counts are search-floor numbers; the live census may show 2-3x more actors per niche and will change `H` scores.
2. Demand (`D`) has no keyword-volume data behind it; the only proxies were incumbent user counts, which were visible for a handful of actors.
3. Proxy cost assumptions hinge on JSON endpoints that were asserted by third-party guides or incumbents' READMEs, not observed.
4. Legal/ToS: PSX, Oddschecker and comparison sites need a review before building, regardless of score.
5. The 2026-10-01 rental retirement may have changed incumbents' pricing models and health in every peer set above; census must capture `pricing_model` and `under_maintenance`.
