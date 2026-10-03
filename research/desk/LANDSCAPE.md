# Apify Store landscape (desk research)

Status: **ALL FIGURES UNVERIFIED.** Every number below comes from a WebSearch result summary obtained on 2026-10-03 (UTC). None was read from the live Store or API. Source dates are the dates the source itself states, or "undated" when the summary did not show one. Phase 3 (census) must re-derive anything used for scoring.

Egress to apify.com / api.apify.com was blocked for this run, so Apify's own pages were seen only through search-result snippets. Third-party sites (use-apify.com, apifystats.com, imisofts.com, godberrystudios.com, apifyforge.com) are SEO-content sites with an interest in Apify traffic; treat their numbers as weaker than Apify docs/blog.

## 1. Size of the Store

| Claim | Value | Source | Source date | Status |
|---|---|---|---|---|
| Actors in Store | "70,000+" | https://use-apify.com/docs/best-apify-actors | states "checked 2026-09-09" | UNVERIFIED |
| Actors in Store (public Store API count) | 57,363 | https://apify.com/khadinakbar/apify-store-scraper (actor README via snippet) | undated | UNVERIFIED |
| Actors / publishers (independent daily census) | 42,715 actors, 2,148 publishers | https://apifystats.com/stats.html | undated snapshot ("daily") | UNVERIFIED |
| Actors in Store, early 2026 | "21,000+" | https://use-apify.com/docs/what-is-apify/apify-actors | "early 2026" | UNVERIFIED |
| Share of actors under 1 year old | 93.5%; 36,256 created in 2026 so far | https://apifystats.com/stats.html | undated | UNVERIFIED. REVIEW 2026-10-03: a re-search summary of the same page gave "39,950 of 42,715 created in 2026; 36,256 through August" and monthly new-actor counts Jan 1,841 / Feb 1,729 / Mar 3,707 / Apr 3,699 / May 5,968 / Jun 7,496 / Jul 10,622 / Aug (partial) 1,194. The two figures are different cut-offs of a daily snapshot, not a contradiction. |
| Actors used in last 30 days | 33,439 (78.3% of census), 96.8% run success, 190.6M runs | https://apifystats.com/stats.html | undated | UNVERIFIED |
| Publishers with >=3 actors | 1,136 | https://apifystats.com/publishers/ | undated | UNVERIFIED |
| Actors on x402 protocol | "more than 20,000" | https://use-apify.com/blog/apify-ai-agents-collections-2026 | 2026 | UNVERIFIED |

Reading: the four actor counts disagree by 3x. The most likely explanation is date (21k early 2026 -> 42k-57k mid-year -> 70k Sept) plus different inclusion rules (apifystats excludes some actors). Whatever the true number, the Store roughly tripled in 2026 and >90% of inventory is less than a year old. This matters more than the absolute count: **the Store is in a land-grab phase and almost every site-level niche already has 3-10 actors** (see CANDIDATES.md, where ~45 niches were checked and only 2-3 came back empty).

## 2. Top actors by users

| Actor | Users | Rating | Source | Source date | Status |
|---|---|---|---|---|---|
| Google Maps Scraper (compass/crawler-google-places) | 596K | 4.70 | https://use-apify.com/docs/best-apify-actors/most-popular-actors | "read from Store API 2026-09-09" | UNVERIFIED |
| Instagram Scraper (apify/instagram-scraper) | 388K | 4.70 | same | 2026-09-09 | UNVERIFIED |
| TikTok Scraper (clockworks) | 275K | 4.76 | same | 2026-09-09 | UNVERIFIED |
| Instagram Profile Scraper | 214K | 4.75 | same | 2026-09-09 | UNVERIFIED |
| Google Search Results Scraper | 179K | 4.65 | same | 2026-09-09 | UNVERIFIED |
| Top-20 range (older snapshot) | 45K-324K users; Google Maps 297K, Instagram 191K, TikTok 146K | https://dev.to/agenthustler/the-apify-actor-survival-guide-why-99-of-scrapers-get-zero-users-and-how-to-fix-it-5eoh | undated (figures imply ~2025) | UNVERIFIED |
| Typical published actor | "0 to 5 users" | same dev.to article | undated | UNVERIFIED |

Reading: a textbook power law. Comparing the two snapshots, the top actor roughly doubled its user count in about a year, so the head is still growing, not just the tail.

## 3. Top categories and what is growing

| Claim | Source | Source date | Status |
|---|---|---|---|
| Five highest-traffic categories 2026: Google Maps, Instagram, TikTok, LinkedIn, lead generation | https://use-apify.com/docs/best-apify-actors | 2026 | UNVERIFIED |
| Store categories seen in snippets: E-commerce, Lead generation, Social media, AI agents, Automation, MCP_TOOLS (new category "added early 2026") | https://apifyforge.com/blog/mcp-servers-next-big-thing-apify ; https://use-apify.com/docs/apify-use-cases | 2026 | UNVERIFIED |
| MCP servers described as fastest-growing actor type; one publisher claims 93 MCP servers shipped | https://apifyforge.com/blog/mcp-servers-next-big-thing-apify | 2026 | UNVERIFIED (self-promotional source) |
| "In 2026 the typical customer is an AI agent that needs real-time data" | https://www.usecarly.com/blog/apify-mcp/ | 2026 | UNVERIFIED (opinion) |
| Most-scraped sites 2026 (proxy-provider telemetry): TikTok #1; new entrants ChatGPT, Perplexity, Naver, Make.com, Target, GitHub, Stack Overflow; e-commerce still the largest category by volume | https://decodo.com/blog/most-scraped-websites-2026 | 2026 | UNVERIFIED |
| Most-scraped e-commerce: Amazon, eBay, Etsy, Walmart; also Indeed, Glassdoor, TripAdvisor, Booking, Airbnb, Zillow, Google | https://www.octoparse.com/blog/top-10-most-scraped-websites | 2026 | UNVERIFIED (listicle) |

Reading: the head categories are owned by Apify (Instagram, Google Search, Booking, TripAdvisor) or by entrenched publishers (compass, clockworks). The growth vector that is open to a small shop is not a new site but a new *shape*: every actor is now also exposed as an MCP tool and via x402, so per-record lookups and monitor-style actors that an agent can call repeatedly fit the platform's direction.

## 4. Pricing model mix

| Claim | Source | Source date | Status |
|---|---|---|---|
| 75% of top-20 actors use PAY_PER_EVENT, typically $0.002-$0.005 per result | https://dev.to/agenthustler/the-apify-actor-survival-guide-why-99-of-scrapers-get-zero-users-and-how-to-fix-it-5eoh | undated | UNVERIFIED |
| Rental model: no new rental actors or price changes from 2026-04-01; fully retired 2026-10-01; un-migrated rentals auto-moved to pay-per-usage | https://blog.apify.com/standardizing-actor-pricing/ ; https://imisofts.com/blog/apify-rental-actors-retired/ ; https://godberrystudios.com/posts/apify-pay-per-event-migration-playbook-2026/ | 2026 | UNVERIFIED (Apify blog is the primary; the rest echo it) |
| Apify's stated reason: 73% of surveyed customers preferred PPE over rentals | https://use-apify.com/docs/apify-for-developers/monetize-actors (quoting Apify) | 2026 | UNVERIFIED |
| Developers report 40-70% revenue drops when auto-migrated rental -> pay-per-usage without a PPE plan | https://godberrystudios.com/posts/apify-pay-per-event-migration-playbook-2026/ | 2026 | UNVERIFIED (anecdotal) |
| apifystats normalises all models to $/1k results and records every PPE event with description and price | https://apifystats.com/ | undated | UNVERIFIED |

REVIEW (review-agent:desk, 2026-10-03): re-search confirms the primary (https://blog.apify.com/standardizing-actor-pricing/ : rentals retired 30 Sept 2026, remaining Actors migrated to pay-per-usage on 1 Oct 2026) and the echoes (imisofts, godberrystudios, use-apify). Still UNVERIFIED (snippet only) but consistent across four sources.

Reading: as of this run (2026-10-03) the rental retirement happened **two days ago**. Expect churn in Phase 3 data: actors whose pricing model flipped to pay-per-usage on 2026-10-01, deprecated actors, and users shopping for replacements. The census should capture `pricingInfos.pricingModel` and the date it last changed if the API exposes it.

## 5. Typical PPE event structures and per-1k prices

Event structures seen in snippets (all UNVERIFIED):

- Synthetic start event `apify-actor-start`: enabled by default on new PPE actors; Apify covers the first 5 s of compute; the developer must not charge it manually. Source: https://docs.apify.com/platform/actors/publishing/monetize/pay-per-event (undated docs).
- Common shape: one `result`/`result-item` event per dataset row, plus optional add-on events (e.g. Talabat scraper bills `$0.0005 per item with choices` for menu option trees; Copart+IAAI scraper bills `$0.005 per actor start + $0.010 per vehicle`; app-review monitor bills `$0.004 per review + $0.02 per app checked`). Sources: https://apify.com/memo23/talabat-scraper ; https://apify.com/automation_studio/auto-salvage-radar ; https://apify.com/dev-hoss/app-review-intelligence (all undated).
- Monitor-mode actors advertise "charges only for new items since last run" (e.g. https://apify.com/interactapps/uk-planning-applications-scraper , https://apify.com/lowlanddata/rightmove-new-listings-alert).
- Toy example from docs: start $0.1 + per-task events $0.2-0.5 (https://apify.com/mhamas/pay-per-event-example); another example: $0.001 per row + $0.00005 start.

Per-1k price points seen (lowest advertised tier unless stated; all UNVERIFIED, undated unless noted):

| Category / actor | $ per 1,000 results | Source |
|---|---|---|
| Google Maps (compass/crawler-google-places) | from $1.50; $2.10 on Business tier; third party says "$4-7 for typical workloads" | https://use-apify.com/docs/best-apify-actors/best-google-maps-scrapers ; https://www.leadscrape.com/apify-google-maps-scraper-vs-lead-scrape.html |
| Google Maps competitors | $0.80 (labrat011), $1.00 (moyadata), $1.50 w/ emails (microworlds), $2.50 (s-r) | https://use-apify.com/blog/best-google-maps-scrapers-2026 |
| Instagram (apidojo, pay per result) | from $0.47 | https://apify.com/apidojo/instagram-scraper |
| Twitter/X | $0.18-$0.40 | https://use-apify.com/docs/best-apify-actors/best-twitter-scrapers |
| Amazon product | from $3.00 (Apify-listed), $0.99 (search results), $2.00 (listings) | https://use-apify.com/ ; https://apify.com/scrapecrafter/amazon-search-scraper |
| LinkedIn profiles | $10.00 flat | https://use-apify.com/docs/how-to-use-apify/scrape-linkedin |
| Trustpilot reviews | $0.20 (webdata_labs) to $1.99 (zen-studio); tiered $0.575 FREE -> $0.14 top tier (automation-lab) | https://apify.com/webdata_labs/trustpilot-review-scraper etc. |
| Google Play reviews | $0.05 to $7.00 (!) across 6 actors | https://apify.com/neatrat/google-play-store-reviews-scraper etc. |
| AutoTrader UK | $0.80 (parsebird) | https://apify.com/parsebird/autotrader-scraper |
| Noon (Gulf e-com) | $0.55 (scrapesage) to $7.50 (parseforge) | https://apify.com/scrapesage/noon-scraper |
| Deliveroo menus | $4.49 | https://apify.com/parseforge/deliveroo-restaurants-scraper |
| App Store apps | $1.00 | https://apify.com/scrapeunblocker/app-store-scraper |
| BizBuySell | $1.97-$2.00 | https://apify.com/khadinakbar/bizbuysell-scraper |
| MediaMarkt/Saturn | $1.20-$2.02 | https://apify.com/studio-amba/mediamarkt-de-scraper |
| AI tool directories | $2.00-$3.00 | https://apify.com/crawlerbros/theresanaiforthat-scraper |
| Tech-stack lookup | $1.20-$20 per 1k URLs | https://apify.com/automation-lab/tech-stack-detector |
| General statement | "most prices $1-10 per 1,000 results" | https://docs.apify.com/academy/actor-marketing-playbook/store-basics/how-actor-monetization-works |

Reading: head categories with heavy competition sit at $0.2-$2/1k; long-tail niches sit at $1-$5/1k; the spread inside one niche is often 10x (Google Play $0.05-$7), which says price is not yet the main sorting mechanism and the Store's ranking is. Hypothesis H4 in PATTERN_HYPOTHESES.md tests this.

## 6. Revenue share and payout terms

| Claim | Source | Source date | Status |
|---|---|---|---|
| Developer receives 80% of revenue; Apify keeps 20% | https://help.apify.com/en/articles/8684010-make-money-publishing-your-actors-on-apify-store ; https://docs.apify.com/academy/actor-marketing-playbook/store-basics/how-actor-monetization-works | undated | UNVERIFIED |
| PPE profit formula: `profit = 0.8 * revenue - platform costs` (compute, proxy, storage used by the actor's runs). Optional "Pay per event + usage" toggle passes platform costs to the user instead. | https://docs.apify.com/platform/actors/publishing/monetize/pay-per-event | undated | UNVERIFIED |
| Developer never pays Apify for other users' runs; only paying-plan users count toward profit (free-plan users' usage is not reflected) | same docs page | undated | UNVERIFIED |
| Payout monthly; minimum $100 bank transfer or $20 PayPal | https://use-apify.com/docs/apify-for-developers/monetize-actors | 2026 | UNVERIFIED |
| Aggregate payouts: "$1.4M monthly across roughly 3,000 developers, ~ $470 average, heavily skewed" | https://www.reinventing.ai/blog/apify-actor-passive-income | 2026 | UNVERIFIED (no primary source shown) |
| Top independent creators ">$10,000 MRR"; "many" >$1,000/month | https://help.apify.com/en/articles/8684010-make-money-publishing-your-actors-on-apify-store | undated | UNVERIFIED |

Implication for pricing: with PPE the developer eats proxy cost unless the "+ usage" toggle is on. At Apify residential proxy rates this is the single biggest margin risk for browser-rendered sources; see the proxy-cost model in CANDIDATES.md.

REVIEW (review-agent:desk, 2026-10-03): 80/20 split and the $100 bank / $20 PayPal payout minimums re-confirmed from https://help.apify.com/en/articles/8684010-make-money-publishing-your-actors-on-apify-store and https://use-apify.com/docs/apify-for-developers/monetize-actors (snippets, UNVERIFIED). Apify residential proxy price now captured: $8/GB Free & Starter, $7.50 Scale, $7 Business (https://scrapegraphai.com/blog/apify-pricing ; https://automationatlas.io/answers/apify-pricing-explained-2026/ , 2026, UNVERIFIED). The "$1.4M monthly across ~3,000 developers" aggregate in the table above did not re-surface and has no primary source; treat as remembered-grade until a source is found.

## 7. Plan tiers and PPE tier pricing

| Claim | Source | Source date | Status |
|---|---|---|---|
| Plans: Free $0 (incl. $5 usage, 16 GB RAM), Starter $19/mo ($17 annual; one source says $29), Scale $199 (256 GB RAM, 128 concurrent runs), Business $999 (512 GB, 256 concurrent), Enterprise custom | https://use-apify.com/docs/what-is-apify/apify-pricing ; https://scrapegraphai.com/blog/apify-pricing ; https://costbench.com/software/web-scraping/apify/ | July-Sept 2026 | UNVERIFIED (Starter price appears to have changed $29 -> $19 mid-2026) |
| Compute unit price: $0.20/CU Free & Starter, $0.16 Scale, $0.13 Business | https://scrapegraphai.com/blog/apify-pricing | 2026 | UNVERIFIED |
| PPE prices CAN vary by tier: developer sets a separate price per tier FREE, BRONZE (Starter), SILVER (Scale), GOLD (Business); API type `TieredPricingPerEvent` | https://docs.apify.com/api/client/js/reference/next/interface/TieredPricingPerEvent ; https://use-apify.com/docs/what-is-apify/apify-pay-per-event | undated / 2026 | UNVERIFIED |
| Worked example of tiering: $0.004 / $0.003 / $0.002 / $0.0015 per place (FREE/BRONZE/SILVER/GOLD) | https://use-apify.com/docs/what-is-apify/apify-pay-per-event | 2026 | UNVERIFIED |
| Suggested discounts: Silver ~10% below Bronze, Gold ~20% below Bronze; optional, set by owner | https://blog.apify.com/migrating-to-pay-per-event-pricing/ | undated | UNVERIFIED |
| Some actors advertise additional tiers ("Diamond") in tiered tables | https://apify.com/automation-lab/trustpilot | undated | UNVERIFIED |

Note for census: the Store API's pricing object appears to carry per-tier prices; capture the FREE-tier price as "entry price" (apifystats does the same) and the GOLD-tier price as "floor" so H4/H5 can test whether tier spread correlates with users.

## 8. Discovery, ranking and quality

| Claim | Source | Source date | Status |
|---|---|---|---|
| Actor quality score 0-100, recalculated several times a day, correlates strongly with search rank; dimensions named: reliability, documentation, user satisfaction, pricing strategy, maintenance, popularity | https://docs.apify.com/actors/publishing/quality-score ; https://apify.com/change-log/actor-quality-is-here | 2026 | UNVERIFIED |
| Third-party weighting claim: README 25%, pricing setup 20%, output schema 15%, run reliability 30%, popularity 10% | https://apify.com/ryanclinton/actor-quality-audit (actor README) | undated | UNVERIFIED (not from Apify) |
| Store search weights `seoTitle` and `seoDescription` heavily; name becomes URL slug and title tag | https://dev.to/agenthustler/... ; https://help.apify.com/en/articles/2644024-seo-for-actors | undated | UNVERIFIED |
| Counter-claim: "the metric that correlates most with discovery is cumulative distinct users all-time, not recent 30-day activity" | https://dev.to/dododata/i-measured-what-ranks-an-apify-actor-it-is-not-your-title-1dla | undated | UNVERIFIED |
| 3 consecutive days of failures -> "under maintenance" label; +28 days -> deprecation | https://docs.apify.com/academy/actor-marketing-playbook/store-basics/how-store-works | undated | UNVERIFIED |
| Average issue response time is computed and shown publicly in Actor metrics | https://docs.apify.com/academy/actor-marketing-playbook/interact-with-users/issues-tab | undated | UNVERIFIED |
| Apify runs automated daily tests on Store actors | https://docs.apify.com/academy/actor-marketing-playbook/store-basics/how-store-works | undated | UNVERIFIED |
| Ideas page: users submit and upvote wanted actors; top-voted = demand signal | https://docs.apify.com/academy/actor-marketing-playbook/store-basics/ideas-page ; https://apify.com/ideas/how-it-works | undated | UNVERIFIED (page content not reachable this run) |
| Solo-dev playbook (98 actors in 6 months): underserved niches, PPE pricing, README opens with one-sentence use case + 3 bullets + sample JSON; "~2 hours/week maintenance" | https://blog.apify.com/building-98-actors-on-apify-store/ | 2026 | UNVERIFIED |

## 9. What this means for ProgrammX (desk-level, to be tested)

1. Site-level blue ocean is nearly gone: of ~45 niches checked (CANDIDATES.md), only PSX data, UK-specific mortgage rates, ~~Oddschecker-specific odds~~ (REVIEW 2026-10-03: consummate_mandala/oddschecker-comparison-scraper exists), Platinumlist and a few micro-verticals returned zero Store hits via search. Even "monitor" variants exist for Rightmove, OLX Pakistan, The Gazette, Gumroad and generic back-in-stock. REVIEW: re-search adds monitor variants for Vinted (4), Marktplaats (3), Wallapop (1), Kleinanzeigen (3), SpareRoom (1), Argos stock (1), Shopify (4+), Tadawul disclosures (1). "Monitor" is no longer an open shape in any classifieds or e-commerce niche checked; it is only open where the *source* is thin.
2. The open differentiators are therefore execution variables the quality score rewards: reliability (daily tests), README/SEO fields, output schema, PPE with tiering, fast issue responses, and *shape* (monitor/diff with charge-only-for-new, per-record lookup callable from MCP).
3. The 2026-10-01 rental retirement is a timing window: incumbents auto-migrated to pay-per-usage may be mispriced or deprecated; Phase 3 should flag niches where the top incumbent flipped model or went "under maintenance".
4. Margin is decided by proxy bytes per row. Any source that forces browser rendering at one row per page is uneconomic at <$0.50/1k unless the "+ usage" toggle is on (see cost model in CANDIDATES.md).
