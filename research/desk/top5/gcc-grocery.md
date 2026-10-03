# Top-5 deep pass: Lulu + Carrefour GCC grocery price monitor

Agent: top5:gcc-grocery (opus), 2026-10-03. All figures come from WebSearch summaries run on 2026-10-03 and are **UNVERIFIED**. "src date n/s" means the search result did not show a publication date. The session hit its 200-search cap after 31 queries in this pass, so Spinneys, Union Coop, Noon Minutes and Kibsons were not searched. Those rows say "not found (not searched)".

**Headline correction to desk_review.md.** The review said no incumbent "advertises a diff/monitor shape." That is wrong for Carrefour. `blackfalcondata/carrefour-maf-scraper` advertises "incremental tracking, and notifications", a "New Products Monitor" example and a basket monitor across 7 MAF markets at $2/1k. It has 24 total users and 7 MAU ([actor](https://apify.com/blackfalcondata/carrefour-maf-scraper), [monitor example](https://apify.com/blackfalcondata/carrefour-maf-scraper/examples/carrefour-maf-new-results-monitor), [users](https://apify.com/blackfalcondata/carrefour-maf-scraper/api/cli); src date n/s). No Lulu actor with a monitor shape was found.

## A. Scraping sources

| Site | URL pattern(s) | Page type | JSON endpoint evidence | Anti-bot (public) | Login | Store/location | robots / ToS | Paid API alt. | Geo |
|---|---|---|---|---|---|---|---|---|---|
| **Lulu UAE** | `gcc.luluhypermarket.com/en-ae/{category}/`, `/p/{id}/` | Unknown. Incumbent output (`sku`, `baseCode`, `stockCount`, `discountRatio`) implies structured JSON somewhere ([boring_internet_explorer README](https://apify.com/boring_internet_explorer/lulu-scraper/api)) | Indirect only. robots.txt **disallows `/api/`**, plus `/search/`, `/promo/` and sort/filter/price URL parameters ([robots.txt](https://gcc.luluhypermarket.com/robots.txt)). The JSON route is therefore robots-disallowed. | not found | n | Delivery details appear in incumbent output, so per-area pricing is possible but unverified | T&Cs allow "personal, non-commercial use" only ([T&C](https://gcc.luluhypermarket.com/en-ae/termsAndConditions)). robots.txt lists per-country sitemaps (en/ar × ae/qa/sa/om/kw/bh). | realdataapi / Actowiz: quote only ([realdataapi](https://www.realdataapi.com/lulu-hypermarket-api.php)) | not found |
| **Lulu other GCC** (SA, QA, OM, KW, BH) | same host, `/en-sa/`, `/en-qa/`, `/en-om/`, `/en-kw/`, `/en-bh/` | same platform | same | not found | n | as above | robots.txt blocks Bytespider, CCBot, AhrefsBot and others outright | as above | not found |
| **Carrefour UAE** (MAF) | `www.carrefouruae.com/mafuae/en/c/{F-code}`, `/p/{id}`, `/search?keyword=` | Unknown. StackShare lists Java, Apache and GTM ([stackshare](https://stackshare.io/carrefour-uae/carrefouruae-com)). No Next.js or Algolia evidence turned up. | none found (searched for api/v7, v8, algolia, mafrservices) | Vendor not found. rigelbytes README: "**Apify Residential is required for reliable access**", with each product request on a rotated residential proxy ([rigelbytes](https://apify.com/rigelbytes/carrefour-scraper)). This points to IP-reputation bot management. | n | MAF prices vary by store/area (cookie), unverified | robots.txt not found. **ToS explicitly prohibits** "browsers, spiders, robots…" other than the site's own search, and any use "other than for personal, non-commercial use" ([T&C](https://www.carrefouruae.com/mafuae/en/helpcenter/topics/216-terms-and-conditions?articleId=4222)) | Actowiz quote only | not found |
| **Carrefour KSA / other MAF** (SA, QA, EG, PK, LB, KE) | same pattern, other hosts | same MAF platform: one actor covers 7 markets | as above | as above | n | as above | assume same ToS | as above | not found |
| **Talabat Mart** (add-on) | app/web, Dubai dark stores | not found | `autofacts/talabat-mart-grocery-scraper` scrapes "by delivery zone" with EAN, from $3.50/1k ([autofacts](https://apify.com/autofacts/talabat-mart-grocery-scraper)) | not found | n | **yes, delivery zone** | not found | n/a | not found |
| **UAE MOET Essential Goods Prices Platform** (add-on and substitute) | moet.gov.ae platform | not found | Retailers feed it by direct integration and it updates daily. It covers 8,343 products at 525 outlets of 13 retailers, Carrefour and Lulu included ([National 2026-04-19](https://www.thenationalnews.com/news/uae/2026/04/19/uae-launches-digital-platform-to-monitor-prices-of-essential-goods/), [dubaistandard](https://www.dubaistandard.com/uae-shoppers-can-compare-prices-of-8343-essential-goods-across-525-outlets/)) | not found | n | per outlet | government data, lowest ToS risk | free | not found |
| Noon Minutes, Spinneys, Union Coop, Kibsons | not found (not searched) | | | | | | | | |
| *Muwazin (KSA consumer app)* | n/a | n/a | Compares 118k+ products across Panda, Carrefour, Tamimi, Danube, LuLu, BinDawood and HungerStation, "refreshed every night from the retailers' official websites" ([muwazin.me](https://muwazin.me/en/)). This shows KSA scraping is feasible at scale. | | | | | | |

**Difficulty grades and bytes (provisional until the probe runs)**

| Site | Grade | KB/request | Rows/request | Reasoning |
|---|---|---|---|---|
| Lulu UAE / GCC | **MEDIUM** | ~350 (probe def guess; range 150–400) | ~30 (grid guess, 24–60) | No anti-bot reported. The clean JSON route (`/api/`) is robots-disallowed, so we parse category HTML or embedded state. Pagination may hit the disallowed sort/filter parameters. |
| Carrefour UAE / MAF | **MEDIUM–HARD** | HTTP ~350; browser ~500–1,000 with assets blocked | ~30 (guess) | The "residential required" signal plus the selenium tutorial ([Datahut](https://www.blog.datahut.co/post/web-scraping-carrefour-data-using-python-and-selenium)) suggest bot management. No incumbent says a browser is required. |
| Talabat Mart | **HARD** | not found | not found | delivery zone required; app-first |
| MOET platform | EASY? | not found | not found | government portal, unprobed |

Bytes/row: HTTP path ~12 KB/row (350/30). Browser path ~33 KB/row (1,000/30).

## B. Build difficulty

- **Browser:** no for Lulu if category HTML carries the tiles. For Carrefour, likely not, but this is unknown and is the swing factor.
- **Core logic:** ~600–900 LOC. Two site adapters (~200 each), the diff/state store keyed by `market:productId` (~150), normalisation with EAN, promo and unit price (~150), PPE charging (~50).
- **Maintenance:** medium. Two retailer front-ends and 13 storefronts, with Carrefour bot rules that may tighten. Lulu's site is new (LuLu 2.0 digital push; [luluretail](https://www.luluretail.com/media/news/lulu-group-unveils-its-next-phase-of-growth-evolution-lulu-20-driven-by-technology-ai-innovation-and-omnichannel-retail/)), so expect layout churn.
- **Hours:** MVP (Lulu UAE + Carrefour UAE categories, diff output, PPE) **25–35 h**. v1 (all 6 Lulu + 7 MAF markets, EAN detail enrichment, sitemap discovery, Arabic, tests, README) **+35–40 h, 60–75 h total**. A Carrefour browser fallback adds 15–25 h.
- **Calendar at 10–15 h/week:** MVP takes **2–3.5 weeks** and v1 **5–7.5 weeks** (7–9 weeks with the browser fallback).

## C. Competitors (Apify Store, UNVERIFIED, src date n/s)

| Actor | Coverage | Model / price | Users |
|---|---|---|---|
| blackfalcondata/carrefour-maf-scraper | 7 MAF markets; **incremental + notifications + basket monitor** | PPE $2.00/1k items | 24 total, **7 MAU** |
| 123webdata/carrefour-scraper | country not stated in snippet | PPR $5.00/1k | 5 MAU (a second listing shows 2 MAU, rating 5.0) |
| boring_internet_explorer/carrefour-scraper | 7 MAF markets | from $0.50/1k | 2 MAU |
| rigelbytes/carrefour-scraper | AE/SA/QA/PK/GE, EAN | from $1.70/1k | 1 MAU |
| solidcode/carrefour-scraper | AE/SA/QA/PK/GE | from $4.00/1k | 0 MAU |
| price_matters/carrefour-uae-scrapper | Carrefour UAE | from $10.00/1k | 0 MAU |
| boring_internet_explorer/lulu-scraper | Lulu, 6 GCC | from $0.50/1k | **1 total user** |
| price_matters/lulu-uae-scrapper | Lulu UAE | from $5.00/1k | not found |
| autofacts/talabat-mart-grocery-scraper | Talabat Mart Dubai | from $3.50/1k | not found |
| (non-GCC) blackfalcondata/carrefour-scraper | carrefour.fr | $2.00/1k | 3 MAU |

Sources: [MAU summary](https://apify.com/solidcode/carrefour-scraper/api), [price_matters](https://apify.com/price_matters/carrefour-uae-scrapper/api/cli), [lulu users](https://apify.com/boring_internet_explorer/lulu-scraper), [lulu-uae-scrapper](https://apify.com/price_matters/lulu-uae-scrapper).

**Revenue estimates (rough).** Assumed usage per MAU is 5k–20k rows a month.
- blackfalcondata MAF: 7 × 5k–20k × $2/1k = **$70–280/mo** gross.
- 123webdata: 5 × 5k–20k × $5 = $125–500 if all five are GCC users. Unknown, so discount heavily.
- boring_internet_explorer (Carrefour + Lulu): 3 × 5k–20k × $0.50 = **$8–30/mo**.
- The other four together: **under $40/mo**.

The whole GCC-grocery niche on Apify has **~16 MAU** and plausibly **$150–600/mo gross across all actors**.

## D. Buyer's budget

- **Who buys:** FMCG brands and distributors tracking shelf price and promos, retail-analytics firms, price-comparison apps (Muwazin KSA; Sallety and Basket UAE per [Gulf News](https://gulfnews.com/uae/rate-of-change-the-difference-is-in-the-price-1.702729) / [uaeexperthub](https://www.uaeexperthub.com/best-grocery-delivery-apps-dubai/)), and regulators. Vendors pitch this exact use case: Actowiz "[Quick Commerce Price Tracking for Dubai FMCG Brands](https://www.actowizsolutions.com/quick-commerce-price-tracking-dubai-fmcg-brands.php)", RetailGators "[UAE Supermarket Price Monitoring Guide](https://www.retailgators.com/uae-supermarket-price-monitoring-guide/)", FoodDataScrape "[Noon vs Carrefour vs Lulu dataset](https://www.fooddatascrape.com/noon-carrefour-lulu-price-comparison-dataset-retail-intelligence.php)" and WebFusionData.
- **Current prices:**
  - 42signals: lowest paid plan **$500/mo** ([xpay.sh](https://www.xpay.sh/saas-pricing/42signals/), 2026).
  - DataWeave: enterprise, no public price ([selecthub](https://www.selecthub.com/p/ecommerce-analytics-software-tools/dataweave/)).
  - Bright Data datasets: **$2.50/1k records** base ($250/100k), with refresh discounts up to 80% ([brightdata](https://brightdata.com/pricing/datasets)). No Lulu dataset was listed.
  - realdataapi and Actowiz: quote only.
  - Profitero, Pricesearcher, NielsenIQ and Circana GCC pricing: not found.
- **Willingness-to-pay signals:**
  - Positive: SaaS starts at $500/mo, and at least 5 data vendors market UAE grocery feeds.
  - Negative: the free MOET platform now covers 8,343 essentials at 13 retailers and had 1,450 visits/day ([National 2026-08-05](https://www.thenationalnews.com/news/uae/2026/08/05/uae-food-price-tracking-platform-to-expand-after-receiving-1450-daily-visits/)), which eats the "basket of essentials" use case. Apify-side demand is ~16 MAU.

## E. Our earning potential

**Proposed PPE events** (benchmarks: floor $0.50/1k at boring_internet_explorer; $2/1k at blackfalcondata, the monitor incumbent):
- `product-checked` **$0.50/1k**: every product scanned. This covers cost and matches the floor.
- `price-change` **$3.00/1k**: emitted only for new, changed-price, promo-start/end or stock-flip rows. This is the value event and sits above blackfalcondata's flat $2 because snapshot users pay only $0.50.

**Unit economics per 1,000 checked rows**

| | HTTP path (12 KB/row) | Browser path (33 KB/row) |
|---|---|---|
| Data | 11.7 MB | 32 MB |
| Decodo @ $4.00/GB | $0.047 | $0.129 |
| Decodo @ $2.75/GB | $0.032 | $0.088 |
| Compute | 256 MB × ~2 min ≈ 0.009 CU → **$0.002** @ $0.20 | 2 GB × ~5 min ≈ 0.16 CU → **$0.031** |
| 80% of $0.50 | $0.40 | $0.40 |
| **Net per 1k checked @ PAYG** | **$0.35** | **$0.24** |
| Net per 1k `price-change` rows (80% × $3) | $2.40 | $2.40 |

**Scenarios.** Each scenario assumes a change rate of 5% of checks per month. Costs use PAYG on the HTTP path; the browser-path figure follows in brackets.

| | Users | Checks/user/mo | Changes/user/mo | Gross/mo | Net/mo | Months to first $100 (after first payer) |
|---|---|---|---|---|---|---|
| Conservative | 2 | 30k (1k SKUs daily) | 1.5k | $39 | **$28** ($22) | ~4 |
| Base | 6 | 60k | 3k | $234 | **$170** ($130) | ~1 |
| Optimistic | 15 | 150k (5k SKUs daily) | 7.5k | $1,463 | **$1,060** ($810) | <1 |

Example, base scenario: 360k checks × $0.50 = $180, plus 18k changes × $3 = $54, gives $234. Then 0.8 × 234 = $187, minus $17.6 Decodo and $0.7 compute, gives about $170.

REVIEW (review-agent:top5, 2026-10-03): Decodo in this example is about $16.9 (360 x $0.047/1k; $17.3 at decimal 12 MB x $4/GB), not $17.6. Net is $169-170, so $170 stands. Other rows recompute within $3: conservative $28.2 ($21.4 browser), optimistic $1,058-1,060 ($801-810). The 80% is applied to gross and Decodo/compute are subtracted after it, as they should be.

The optimistic scenario is roughly the entire current niche (~16 MAU), so treat it as a ceiling. Add 3–8 weeks of build before the first payer.

REVIEW (review-agent:top5, 2026-10-03): only by user count. Section C sizes the niche at 5k-20k rows per MAU and $150-600/month gross; these scenarios assume 30k-150k checks per user. Base gross ($234) is already 39-156% of the whole niche and optimistic gross ($1,463) is 2.4-10x it. Read base as a stretch and optimistic as above the ceiling.

## F. Verdict: **TEST** (leaning KILL on market size)

**Three strongest reasons:**
1. **Unit economics are fine if plain HTTP works.** At ~12 KB/row the cost is ~$0.05 per 1k, well under the $0.50 KILL gate, leaving ~$0.35 net per 1k checks.
2. **Lulu has no monitor-shaped incumbent.** The only GCC-wide Lulu actor has 1 total user, and no actor matches Lulu and Carrefour on EAN across the 6 shared GCC markets.
3. **There is a real B2B budget.** Digital-shelf SaaS starts at $500/mo, at least 5 vendors sell UAE grocery feeds, and ProgrammX can reach UAE buyers directly.

**Biggest risk:** demand and differentiation, more than tech.
- Apify demand is ~16 MAU across 9 actors.
- The Carrefour monitor shape is already taken (blackfalcondata, $2/1k, 7 MAU).
- The free MOET platform covers essentials.
- Both retailers' ToS limit use to personal, non-commercial purposes, and Carrefour explicitly bans robots.

REVIEW (review-agent:top5, 2026-10-03): by the standard the retail file and desk_review applied (Screwfix crawl ban, Oddschecker commercial-use ban treated as gates), Carrefour's explicit robots/spiders ban and Lulu's personal, non-commercial clause are gates too. TEST holds only as an information probe; a build needs a licence or written consent first.

**The live probe must confirm:**
1. Both hosts return product tiles to plain HTTP from **non-GCC** residential IPs, with no geo-redirect to a store picker (check `final_url`).
2. Block rate on Carrefour without a browser is ≤20%.
3. Real KB/request and rows/page, and whether embedded state (`__NEXT_DATA__` or similar) carries EAN, promo and stock.
4. Lulu pagination works without the robots-disallowed sort/filter/price parameters.
5. Whether price differs by delivery area (cookie), which would change the row key.

Build only if items 1–2 pass on both hosts. Ship Lulu-first plus cross-retailer EAN diff as the differentiator. If Carrefour needs a browser, ship Lulu alone and re-score.
