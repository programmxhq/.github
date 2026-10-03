# Currys + Screwfix UK price & stock monitor: deep second pass

Agent: top5:uk-retail (opus), 2026-10-03 (UTC). Method: about 45 WebSearch calls. After that the session's shared search budget (200) ran out, so some user counts were not retrieved and are marked "not found". apify.com and the general web were not reachable directly. **Every figure below comes from a search-result summary from this session and is UNVERIFIED.** Search summaries rarely show a page date, so "src date" means "retrieved 2026-10-03, page date not shown" unless stated otherwise. Shared rates (Decodo, Apify payout and compute) come from the brief.

## Headline

The desk premise fails on three counts:

1. **The niche is not thin.** Desk: Currys 1 incumbent, Screwfix 2. Re-search: Currys has 6 actors from 5 publishers, and Screwfix has 6 actors from 5 publishers.
2. **The monitor shape is already on Currys.** `sync-network/currys-price-tracker` tracks price history across runs (sales, price drops, target prices).
3. **Two gates are hit.** Currys is behind Cloudflare and is UK-geo-blocked and VPN-hostile; we have no country targeting. Screwfix's own T&Cs forbid anyone to "crawl" the site or use its content "for any commercial exploitation".

## A. Scraping sources

| # | Site / page type | URL pattern | Rendering | JSON evidence | Anti-bot (public) | Login | Geo | Grade |
|---|---|---|---|---|---|---|---|---|
| 1 | Currys category listing | `currys.co.uk/{dept}/{cat}/{sub}` (confirmed in the probe def); paging `?start=&sz=` UNVERIFIED | SFCC server HTML. HTML sitemap title is "Sites-curryspcworlduk-Site" (from the probe def) | None public. SFCC `Search-UpdateGrid`-style endpoints did not surface (search 2026-10-03) | **Cloudflare**: users report Cloudflare error 1005 "currys.co.uk has banned the ASN your IP address is in" [1][2]. One summary claims "no Cloudflare / Playwright-stealth" (source not identifiable), which contradicts [1][2] | n | **UK-only; "hostile to VPNs"** [3][4] | **HARD** for us |
| 2 | Currys product page | `currys.co.uk/products/{slug-with-dots}-{8 digits}.html` (confirmed) | SFCC HTML; incumbents extract EAN, SKU, specs and stock [5][6] | not found | as #1 | n | as #1 | HARD |
| 3 | Currys stock / store stock | not found. One third-party vendor claims "per-store stock across 300+ Currys stores" (search summary; URL ambiguous) | not found | not found | as #1 | n | as #1 | HARD / unknown |
| 4 | Screwfix category | `screwfix.com/c/{path}/cat{digits}` (confirmed) | **Next.js**. Page 1 is in `__NEXT_DATA__`; later pages come from a REST call [7] | **"Listing uses BFF API; product detail uses Next.js JSON"** (datasaurus README) [7] | none reported (not found) | n | T&Cs: content is "deliverable to the UK" [8]. Hard geo-block not confirmed; one forum thread reports "not accessible" [9] | **MEDIUM** |
| 5 | Screwfix product | `screwfix.com/p/{slug}/{code}` (confirmed) | Next.js JSON [7]; Bazaarvoice for reviews and Q&A [7] | yes [7] | not found | n | as #4 | MEDIUM |
| 6 | Screwfix stock / Click & Collect | endpoint path not public | JSON (implied) | dromb README: "per-store Click & Collect quantities, delivery status, opening hours" [10]; sian.agency "stock check" [11] | not found | n | as #4 | MEDIUM |
| 7 | Sitemaps (both) | not found in search | n/a | n/a | n/a | n | n/a | n/a |
| 8 | Toolstation (add-on) | not captured | not found | 3 incumbents: crawlerbros $3.00/1k, studio-amba $2.00/1k, maximedupre $2.70/1k (incl. EAN) [12] | not found | n | UK | n/a: crowded |
| 9 | Wickes / B&Q diy.com (add-on) | not captured | not found | Wickes: studio-amba $2.00/1k, dromb/wickes-uk-wave3. B&Q: a DIY.com scraper exists [13] | not found | n | UK | n/a: crowded |
| 10 | AO.com (add-on) | not captured | listing returns "60 products per page request" [14] | studio-amba/ao-scraper [14] | not found | n | UK | n/a: taken |

**Grades.** EASY = plain HTTP returning clean HTML or JSON with no strong anti-bot. MEDIUM = header or session tricks, or partial JS. HARD = needs a browser, faces strong anti-bot, a login or a geo-lock.

**Rate limits.** Not found for either site.

**robots.txt.**
- Currys disallows search, cart, wishlist, checkout and `prefn=`/`pmin=`/`pmax=` (from probe_defs_review).
- Screwfix.com's robots.txt was not found.

**ToS.**
- **Screwfix** (from the [8] summary): without prior written consent you may not "reproduce, crawl, frame, link to or deep-link into the Website ... or use the content for any commercial exploitation". Use is allowed only for "personal use or internal business purposes". That is explicit enough to gate, by the same standard the desk review applied to Oddschecker.
- **Currys**: the T&Cs text was not found. Vendors say Currys "employs CAPTCHAs and IP blocking" [15].

**Official / affiliate alternatives (free to approved publishers).**
- **Currys on Awin.** "Market leading data feed... multiple feeds throughout the day". Currys Business provides a daily datafeed, with an intraday feed on request [16].
- **Screwfix on Awin.** The GB programme is open, and feeds are "updated twice daily" [17].
- Price for both: free to publishers who are approved.
- **Effect on demand:** this removes the deal-site and price-comparison buyer, who can join Awin. Brands and competitors that cannot be affiliates are not covered.

**KB and rows per request (estimates, not measured).**

| Source | Rows per request | KB per request | KB per row | Reasoning |
|---|---|---|---|---|
| Screwfix listing HTML with `__NEXT_DATA__` | ~20 | ~300 | ~15 | Probe-def guess |
| Screwfix BFF JSON | ~20 | ~50 | ~2.5 | JSON without markup, typically 5-10x smaller |
| Currys listing HTML | ~20 | ~300 | ~15 | — |
| Currys behind a challenge | ~20 | 1-2 MB (browser) | ~100 | Needs a browser |

## B. Build difficulty

- **Browser.** Screwfix: no, it uses `__NEXT_DATA__` plus BFF JSON. Currys: probably needed against Cloudflare, but the binding problem is the UK geo-lock, not the browser.
- **Core logic.** About 450-650 lines:
  - 2 adapters at about 150-200 lines each
  - diff and state in a KV store, about 100 lines
  - PPE and output, about 80 lines
  - store-stock fan-out, about 60 lines
- **Maintenance.** Medium-high:
  - Next.js `buildId` and BFF shape changes on Screwfix
  - Cloudflare rule changes on Currys
  - the ToS letter risk on Screwfix
- **Effort and time** at 10-15 h/week:

| Release | Scope | Hours | Calendar weeks |
|---|---|---|---|
| MVP | Screwfix only: listings, diff, change events | 25-35 | 2-3 |
| v1 | + Currys (needs a UK-targeted proxy we do not have) + store stock | 70-100 | 5-9 |

## C. Competitors' revenue (Apify Store, UNVERIFIED)

| Actor | Pricing | Users | Notes |
|---|---|---|---|
| sian.agency/currys-product-scraper | from $1.43/1k overview products [5] | **12 total / 6 monthly**, rating 0 [18] | Marketing pages for "price tracker", "stock checker" and "deals" |
| **sync-network/currys-price-tracker** | from $2.00/1k [19] | not found | **Monitor-shaped:** 4 modes, price history across runs in KV store `currys-price-history`, price drops, target prices |
| soft_alexist/currys-product-search-scraper (+ details actor) | from $4.99/1k [20] | not found | 13+ fields incl. care plans |
| powerai/currys-products-search-scraper | from $4.99/1k [21] | not found | — |
| voyn/currys-co-uk-scraper | $20/month + usage [22] (stale rental label; rentals retired 2026-10-01) | not found | EAN, stock, delivery |
| sian.agency/screwfix-product-scraper | from $4.75/1k [23] | not found | inc/ex VAT, stock |
| studio-amba/screwfix-scraper | from $2.00/1k [24] | **2 total / 0 monthly** [24] | — |
| crawlerbros/screwfix-trade-supply-catalog-scraper | from $3.00/1k [25] | not found | — |
| **dromb/screwfix-uk-wave3** | **from $0.40/1k** [10] | not found | Per-store C&C quantities, stores, coordinates |
| datasaurus/screwfix(-event) | from $2.00/1k, PPE: listings, pages, reviews, Q&A [7] | not found | BFF API |

**Off-Apify alternatives.**
- Bright Data has Currys price-tracker repos (luminati-io, bright-kr) [26]. Its Web Scraper API costs $1.50/1k records PAYG and $1.30/1k on the Scale plan ($499/mo) [27].
- ShoppingScraper takes `site=currys.co.uk` plus an EAN; extra requests cost €0.003-0.005 [28].
- At least 6 data-service shops sell Currys or Screwfix feeds (Actowiz, RetailGators, X-Byte, ProductDataScrape, WebFusion, MobileAppScraping) [15][29].

**Revenue estimate (rough).**
- sian.agency Currys: 6 MAU × 2k-30k rows × $1.43/1k ≈ **$17-$257/mo gross**.
- studio-amba Screwfix: 0 MAU ≈ **$0**.
- Others: user counts not found. Assuming 0-5 MAU each at similar usage gives ≈ $0-$750/mo gross for the other ~8 actors combined.
- **Total Apify market for these two sites:** probably **under $1,000/mo gross, split 10 ways**.

## D. Buyer's budget

| Buyer | What they use now | Public price | Signal |
|---|---|---|---|
| Arbitrage / reseller Discords | Mercury Dynamics (50+ UK retailers incl. Currys, 100+ communities, 250k+ members) [30]; Mastermind Arbitrage [31]; Reseller Paradise, House of Resell [31] | £34.99/mo [30]; £30/mo [31]; £24.99 and £34.99/mo [31] | Real willingness to pay, but they need **sub-minute** alerts; scheduled Apify runs cannot compete |
| Deal hunters | BuySignal [31]; free trackers: PriceSpy, pricedrops.co.uk, Whisprice, pricehistory.co.uk [32] | £5 per alert; free | The consumer layer is free |
| Deal / comparison sites | Awin feeds [16][17] | free to approved publishers | Kills demand for this buyer |
| SMB retailers / brands | Prisync [33]; Price2Spy [34] | Prisync $59-$399/mo (+20% for API); Price2Spy $39.95-$947.95/mo | Turnkey SaaS with matching and dashboards |
| Enterprise brands / analysts | Skuuudle, Competera, PriceSpider [35]; UK agencies such as ukdataservices [35] | Skuuudle $10k-$1M/yr; Competera €98+/mo to $500-10k/mo; PriceSpider not public; ukdataservices from £299/mo | Buys managed service, not Apify actors |

The willingness to pay sits in SaaS (alerts and dashboards). Raw Apify rows for two UK retailers have a ceiling set by the $0.40-$2.00/1k incumbents.

## E. Our earning potential

**Proposed PPE events.**

| Event | Price |
|---|---|
| `product-checked` | $1.50/1k (between sian $1.43 and sync-network $2.00; above dromb $0.40) |
| `change-detected` | $0 extra, as differentiation |
| `store-stock-row` | $1.00/1k |

**Unit economics per 1,000 checked rows** (Screwfix HTML at 15 KB/row; compute 0.02 CU per 1k rows for an HTTP crawler, about 50 requests at 1 GB):

| Item | PAYG $4/GB | Plan $2.75/GB |
|---|---|---|
| Revenue at $1.50 × 80% | $1.200 | $1.200 |
| Decodo, 15 MB | −$0.060 | −$0.041 |
| Compute, 0.02 CU × $0.20 | −$0.004 | −$0.004 |
| **Net per 1k rows (HTML)** | **$1.136** | **$1.155** |
| Net per 1k rows if BFF JSON (2.5 KB/row) | $1.186 | $1.189 |
| Net per 1k rows if Currys needs a browser (100 KB/row, ~0.75 CU) | $0.65 | $0.78 |

Margin is not the problem. Volume is, and so is the price war with dromb at $0.40.

**Scenarios** (net $1.136/1k rows; months counted from launch):

| Scenario | Users × rows/user/mo | Rows/mo | Net/mo | Months to first $100 |
|---|---|---|---|---|
| Conservative | 1 × 15k | 15k | $17 | ~6 (and the payout min is only reached if retained) |
| Base | 3 × 30k | 90k | $102 | ~2-3, allowing a ramp |
| Optimistic | 8 × 100k | 800k | $909 | 1-2 |

Base assumes we match the category leader's 6 MAU at half share. The optimistic case needs 8 MAU, more than any Currys or Screwfix actor shows today.

## F. Verdict: **KILL**

**Three strongest reasons:**

1. **The niche is crowded, and the monitor shape is taken.** There are 10+ actors from 9 publishers. `sync-network/currys-price-tracker` already does price history and price-drop tracking. `dromb` sells Screwfix with per-store stock at $0.40/1k. The desk's H = 4-5 becomes H = 1-2.
2. **Gates on both legs.**
   - Screwfix T&Cs explicitly forbid crawling and commercial exploitation [8].
   - Currys is behind Cloudflare with ASN bans, UK geo-blocked and VPN-hostile [1][3][4]; with no Decodo country targeting most exits will be blocked.
3. **The demand is small and served elsewhere.** The best incumbent has 6 MAU [18]. Free Awin feeds serve publishers [16][17], arbitrage communities need sub-minute monitors (£35/mo SaaS), and brands buy Prisync or Price2Spy.

**Biggest risk if pursued anyway:** a Screwfix cease-and-desist under its "no crawl" clause after launch, or Currys blocking all non-UK exits so the actor fails silently in production.

**What a live probe would have to confirm before reversal** (do not spend probe budget unless the verdict is challenged):

1. Currys returns 200 with tiles from untargeted Decodo exits (expect Cloudflare 1005 or a challenge).
2. Whether screwfix.com geo-blocks non-UK IPs.
3. The Screwfix BFF JSON is reachable with plain HTTP, at under 5 KB per row.
4. The full Screwfix T&Cs page and robots.txt, read by a human.

## Sources (all retrieved via WebSearch 2026-10-03; page dates not shown unless stated)

1. https://answers.microsoft.com/en-us/microsoftedge/forum/all/screen-has-message-from-cloudflare-1005-error/9d2b6547-2612-4f6b-84a3-4768abe2f400
2. https://community.cloudflare.com/t/blocked-on-currys-couk/816468 ; https://www.edugeek.net/forums/topic/224618-cloudflare-blocking-users/
3. https://aseannow.com/topic/1282391-currys-uk-blocked-from-thailand/
4. https://community.bitdefender.com/en/discussion/103152/currys-co-uk-website-blocked-with-british-connection-or-allowance-on-split-tunnel/p1
5. https://apify.com/sian.agency/currys-product-scraper/api
6. https://apify.com/voyn/currys-co-uk-scraper/api
7. https://apify.com/datasaurus/screwfix ; https://apify.com/datasaurus/screwfix-event
8. https://www.screwfix.com/help/websitetermsandconditions
9. https://www.ukworkshop.co.uk/threads/screwfix-website-not-accessible.139359/
10. https://apify.com/dromb/screwfix-uk-wave3/api
11. https://apify.com/sian.agency/screwfix-product-scraper/examples/screwfix-stock-check
12. https://apify.com/crawlerbros/toolstation-scraper ; https://apify.com/studio-amba/toolstation-scraper ; https://apify.com/maximedupre/toolstation-scraper
13. https://apify.com/studio-amba/wickes-scraper ; https://apify.com/dromb/wickes-uk-wave3/api/cli
14. https://apify.com/studio-amba/ao-scraper
15. https://proxyempire.io/scraping-api-for-currys/ ; https://www.actowizsolutions.com/currys-co-uk-e-commerce-product-data-scraping.php
16. https://ui.awin.com/merchant-profile/1599 ; https://www.affiliate-toolkit.com/program/currys-business/
17. https://ui.awin.com/merchant-profile/30957 ; https://affi.io/m/screwfix
18. https://apify.com/sian.agency/currys-product-scraper
19. https://apify.com/sync-network/currys-price-tracker
20. https://apify.com/soft_alexist/currys-product-search-scraper
21. https://apify.com/powerai/currys-products-search-scraper/api
22. https://apify.com/voyn/currys-co-uk-scraper
23. https://apify.com/sian.agency/screwfix-product-scraper
24. https://apify.com/studio-amba/screwfix-scraper
25. https://apify.com/crawlerbros/screwfix-trade-supply-catalog-scraper
26. https://github.com/topics/currys
27. https://casrai.org/guides/bright-data-pricing (states "as of September 2026")
28. https://shoppingscraper.com/pricing
29. https://www.retailgators.com/screwfix.php ; https://www.xbyte.io/screwfix-stock-price-scraping-click-and-collect-feed/
30. https://mercury-dynamics.co.uk/
31. https://mastermindarbitrage.com/ ; https://cookgroups.net/uk-cook-groups/ ; https://buysignal.deals/alerts
32. https://pricespy.co.uk/information/about-pricespy ; https://www.pricedrops.co.uk/shop/currys ; https://www.whisprice.com/uk/currys-uk-price-tracker
33. https://www.capterra.com/p/153451/Prisync/ ; https://www.spotsaas.com/product/prisync/pricing (tier figures differ between sources)
34. https://tekpon.com/software/price2spy/reviews/ ; https://www.pricinghunter.com/resources/price2spy-pricing
35. https://www.getapp.co.uk/software/104335/competera ; https://ukdataservices.co.uk/services/price-monitoring ; https://checkthat.ai/brands/pricespider
