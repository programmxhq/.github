# Review: research/desk/ (LANDSCAPE, PROGRAMMX_LIVE, PATTERN_HYPOTHESES, CANDIDATES)

Reviewer: review-agent:desk (fable), 2026-10-03T11:56Z–12:05Z (UTC). Method: 28 WebSearch calls re-running the desk's most consequential claims; scripted recomputation of all 44 weighted totals; rubric-consistency pass on the top 12; ToS/legal and login pass. apify.com was not reachable, so every "result" below is itself a search-summary value and stays UNVERIFIED. Nothing committed.

## Verdict: PASS WITH FIXES (documents) — the top-8 shortlist does not survive

The four files are honest about provenance: every section is headed UNVERIFIED, most figures carry a URL, the cost model is explicit, and 41 of 44 totals are arithmetically right. That earns a PASS for the write-up. But the *content* of the shortlist fails its own gates once the missed incumbents and the actual ToS wording are added: 4 of the top 8 are OUT (PSX, Vinted, generic back-in-stock, Oddschecker) and a fifth (Marktplaats/Wallapop) drops a band. The systematic error is one kind: the desk under-counted **monitor-shaped incumbents** in every classifieds/e-commerce niche. I fixed the arithmetic, annotated every refuted or weakened claim in place as `REVIEW: ...`, and give an adjusted top 5 below.

## 1. Re-run of the 8 consequential claims

| # | Claim | Desk value | Re-search result (2026-10-03) | Verdict | Sources |
|---|---|---|---|---|---|
| a | Rental pricing retired 2026-10-01 | Rentals frozen 2026-04-01, retired 2026-10-01, un-migrated -> pay-per-usage | Confirmed: "retires monthly rental pricing on 30 Sept 2026; on 1 Oct rental Actors fully retired; remaining Actors migrated to pay-per-usage" | CONFIRMED | https://blog.apify.com/standardizing-actor-pricing/ ; https://imisofts.com/blog/apify-rental-actors-retired/ ; https://godberrystudios.com/posts/apify-pay-per-event-migration-playbook-2026/ |
| b | Store size / growth | 70k+ (use-apify, 2026-09-09); 57,363 (Store API via actor README); 42,715 / 2,148 publishers (apifystats); 36,256 created in 2026 | Same three figures re-surfaced with the same attributions; apifystats adds 39,950 of 42,715 created in 2026 and monthly counts (Jul 2026 peak 10,622). 36,256 = "through August". Not a contradiction, a cut-off difference. | CONFIRMED (annotated) | https://apifystats.com/stats.html ; https://use-apify.com/docs/best-apify-actors ; https://apify.com/extractmaster01/apify-store-scraper |
| c | ProgrammX 4 live actors | ebay-business-leads, immoscout24-agent-leads, instantly-lead-pusher, propertyfinder-deal-scraper; 9 users / 5 monthly | 3 of 4 re-surfaced with prices (ImmoScout $30/1k emails; PropertyFinder $150/1k deal scores). `instantly-lead-pusher` did not re-surface in 2 searches. User counts did not re-surface. | PARTLY CONFIRMED | https://apify.com/programmx ; https://apify.com/programmx/ebay-business-leads ; https://apify.com/programmx/immoscout24-agent-leads/api ; https://apify.com/programmx/propertyfinder-deal-scraper/api |
| d | PSX: no free official API; zero PSX actors on Store | A = 5 ("none at all"); "aggressively enforces IP" noted as a risk | No free API confirmed (licence via marketdatarequest@psx.com.pk; Deutsche Börse is exclusive international licensor). Zero PSX-specific actors re-confirmed (only generic gentle_cloud/stock-exchange-scraper). **But** PSX terms: commercial use of site content "strictly prohibited" without approval; dissemination of market data without licence "strictly prohibited"; PSX "reserves its right to ... initiate civil and criminal legal proceedings". | CONFIRMED on facts; **risk understated** -> legal gate | https://www.psx.com.pk/psx/terms-of-use ; https://www.psx.com.pk/psx/product-and-services/data-services-vending ; https://dps.psx.com.pk/ |
| e | Vinted monitor competitors | 7 batch incumbents; "incumbents are batch scrapers"; internal `/api/v2/catalog/items` | **Refuted.** 4 monitor-shaped incumbents missed: trovevault/vinted-scraper-monitor (26 countries, only-new), neverempty/vinted-new-listings-monitor ($2.45/1k), mojocakes/vinted-search-monitor, accountable_eel/vinted-listing-lookup ("New Listing and Price Drop Alerts"); plus studio-amba, lulzasaur, crawlerbros. >= 11 -> H = 1. Also `/api/v2/catalog/items` reportedly 404 since Sept 2026; replaced by `svc-catalogue/items` + `access_token_web` bearer, DataDome. | REFUTED | https://apify.com/trovevault/vinted-scraper-monitor ; https://apify.com/neverempty/vinted-new-listings-monitor/api ; https://apify.com/mojocakes/vinted-search-monitor/api ; https://apify.com/accountable_eel/vinted-listing-lookup ; https://dev.to/datakaz/how-to-scrape-vinted-in-2026-without-getting-blocked-2a59 ; https://github.com/HelpCode-ai/anythingmcp/pull/710 |
| f | Decodo residential $4/GB | $4/GB PAYG; $3.75 -> $2.00/GB plans | Confirmed ($4 PAYG; $3.75-$2.75 on 3-100 GB; $2.50-$2.00 enterprise). **Gap:** Apify's own residential proxy is $8/GB Free/Starter, $7.50 Scale, $7 Business — 2x the model's input. | CONFIRMED; model input incomplete | https://decodo.com/proxies/residential-proxies/pricing ; https://proxidize.com/blog/decodo-pricing/ ; https://scrapegraphai.com/blog/apify-pricing ; https://automationatlas.io/answers/apify-pricing-explained-2026/ |
| g | Payout / revenue share | 80/20; $100 bank / $20 PayPal minimum; monthly | Confirmed verbatim. "$1.4M monthly / ~3,000 devs" did not re-surface (reinventing.ai only; no primary). | CONFIRMED (aggregate figure weak) | https://help.apify.com/en/articles/8684010-make-money-publishing-your-actors-on-apify-store ; https://use-apify.com/docs/apify-for-developers/monetize-actors ; https://docs.apify.com/academy/actor-marketing-playbook/store-basics/how-actor-monetization-works |
| h | Any top-8 head-on vs Apify-owned actor | None flagged | **One is.** S4 (generic back-in-stock / price-change monitor) is head-on with `apify/e-commerce-scraping-tool` (Apify-owned, advertises monitoring "price details over time"). No `apify/` actor found for Vinted, Oddschecker, Argos, Marktplaats, Wallapop, mortgage, Lulu/Carrefour, PSX. | 1 of 8 REFUTED | https://apify.com/apify/e-commerce-scraping-tool |

Additional refutations found while re-searching (all annotated in CANDIDATES.md):

| Candidate | Desk | Re-search |
|---|---|---|
| #6 Oddschecker | "none Oddschecker-specific" | consummate_mandala/oddschecker-comparison-scraper exists; ToS forbids reproduction "for any commercial enterprise" and blocks "automated or robotic activity" (US T&C page; UK page not surfaced). https://apify.com/consummate_mandala/oddschecker-comparison-scraper/api ; https://www.oddschecker.com/us/terms-and-conditions |
| #5 Marktplaats/Wallapop | 3 + 5 batch | +bostomate/marktplaats-monitor ($7/1k new listings), lowlanddata/marktplaats-new-listing-alerts, accountable_eel, haketa, panjan; Wallapop +blackfalcondata (monitor), igolaizola, parseforge. 8+ each, monitor shape taken. |
| #7 Argos | 7 incumbents, H = 3 | 8 (+jupri); Argos behind Akamai per dromb README (TLS impersonation then real Chrome). H = 2, C/E lower for the Argos leg. https://apify.com/dromb/argos-uk-product-search-catalog-unofficial |
| #9 Kleinanzeigen | 9 | 11+, 3 monitor-shaped (bostomate, tagadanar, crawloop). |
| #12 SpareRoom/OpenRent | 5 | 10+ incl. automation-lab monitor mode, parseforge x2, logiover, benthepythondev. |
| #13 Idealo/Geizhals | 5 | 10 incl. ahmed_jasarevic EAN lookup (claims "most-used"). Lookup shape taken. |
| #17 Tadawul/DFM/ADX | sibling of PSX | Same legal gate: DFM "strictly prohibited and may result in criminal penalties"; Tadawul legal notice forbids storing data in any other retrieval system. Tadawul monitor shape taken (generous_heavens). https://apify.com/getascraper/dfm-announcements-scraper ; https://origin.tadawulgroup.sa/wps/portal/saudiexchange/hidden/legal_notice?locale=en |
| #19 Stepstone | "none surfaced" | easyapi, s-r, scrapesage, wyle, jupri; Akamai Bot Manager per READMEs. |
| G1 PakWheels | "1 incumbent, thin" | 5 (shahidirfan, voyn, ecomscrape x2, entrepreneurial_lens_ehi). Refuted. |
| #21 Uswitch energy | 1 | crawlerbros/uswitch-scraper exists; its README confirms energy is postcode/usage-gated. |

## 2. Scoring audit (CANDIDATES.md)

**Arithmetic.** Formula `2P + 2R + 1.5D + 1L + 1.5A + 1C + 1.5H + 1E`, max 57.5 (correct). Recomputed all 44 rows: 41 match. Three errors, all fixed in place:

| Row | Stated | Correct |
|---|---|---|
| #42 Checkatrade/Yell | 34.0 | 36.5 |
| #43 WhatClinic/Doctify | 32.5 | 35.0 |
| G1 home-market group | 45.5 | 45.0 |

None affects the top 12.

**Rubric consistency, top 12** (score the file's own rubric would give, using the file's own evidence plus the re-search). I annotated rows rather than silently changing scores, since Phase 3 replaces them.

| # | Candidate | Desk total | Issue | Adjusted (rubric) | Gate |
|---|---|---|---|---|---|
| 1 | PSX | 52.0 | A = 5 "none at all" but a paid licence exists -> A = 4. Legal risk is a gate, not a note. | 50.5 | **OUT (legal)** |
| 2 | Vinted | 50.5 | 7 listed -> H = 2 was right for the desk's count; true count >= 11 -> H = 1. E/C stale (API moved, DataDome). | 49.0 | **OUT (H)** |
| 3 | UK mortgage | 50.0 | A = 5 but Moneyfacts sells a mortgage API/datafeed -> A = 4. "No UK-specific" holds (crawlerbros Moneyfacts actor is savings only). | 48.5 | in |
| 4 | Generic back-in-stock | 50.0 | Apify-owned e-commerce tool + 6 Shopify monitors -> H = 1. | 47.0 | **OUT (Apify-owned)** |
| 5 | Marktplaats/Wallapop/Subito | 49.5 | 8+ per site incl. monitors -> H = 2. | 48.0 | in, weak |
| 6 | Oddschecker | 49.5 | "none specific" refuted -> H = 3; A = 4 defensible (Odds API third-party). ToS explicit. | 48.0 | **OUT (ToS)** |
| 7 | Argos/Currys/Screwfix | 49.5 | Argos leg: 8 incumbents (H = 2) + Akamai (C/E = 2-3). Currys (1) / Screwfix (2) legs fine. | ~47 as bundled; ~49.5 without Argos | in (drop Argos) |
| 8 | Lulu/Carrefour | 49.5 | 5 publishers -> H = 3 stands. No monitor shape seen. | 49.5 | in |
| 9 | Kleinanzeigen | 48.5 | 11+ -> H = 1 | 47.0 | OUT (H) |
| 10 | Trustpilot | 48.5 | already H = 1 | 48.5 | OUT (H), as desk said |
| 11 | Bayt/Naukrigulf/Rozee | 48.5 | 3-4 per site -> H = 3 stands | 48.5 | in |
| 12 | SpareRoom/OpenRent | 48.5 | 10+ incl. monitor -> H = 2 | 47.0 | in, weak |

**Demand (D) with no signal.** D is self-declared as proxy-only. The only D = 5 scores (Oddschecker, Trustpilot, Rightmove) are backed by incumbent counts, which is circular with H. D = 2 for PSX is honest. No D score contradicts the file's evidence, but none is supported by it either; the file says so.

**Legal/ToS surfaced?** Partly. PSX and Oddschecker are named in "Biggest uncertainties" #4 as "need a review", but both score A = 5 / 4 and sit at #1 and #6 with no penalty. The table has no legal column. The ToS wording found (PSX: criminal proceedings; Oddschecker: commercial use prohibited; DFM: criminal penalties; Tadawul: no storage in other systems) is explicit enough to gate. Recommended: add a `T` gate column before Phase 5.

**Login required?** None of the top 12 requires a login. Vinted needs an anonymous session cookie (not a login). Etimad (#26) is partly login-gated for details (L = 4, correctly). UK energy (#21) is postcode-form-gated (L = 4, correctly; incumbent confirms). CourtServe (#37) requires registration (not scored; irrelevant).

## 3. Unlabeled numbers, missing URLs, remembered-looking figures

- **Labeling:** every file carries a top-level UNVERIFIED banner and LANDSCAPE tables carry per-row status. Good.
- **Missing URLs (main gap):** the entire "Official API status" column in CANDIDATES.md has no URLs: Vinted Pro API "EUR 30/mo + allowlist", Eventbrite search API "removed Feb 2020", Meetup "Pro subscription", Trustpilot "enterprise-only, waitlist", Chrome Web Store "API retired", Idealo partner API, AutoTrader "partner-only", mobile.de "dealer-only", Foodpanda "PerimeterX", "Rightmove incumbents use Playwright + residential", Wallapop "internal API, no browser". These are plausible but untraceable; several (Eventbrite Feb 2020, Meetup Pro) read as remembered rather than searched.
- **Remembered-grade figure:** LANDSCAPE §6 "$1.4M monthly across ~3,000 developers, ~$470 average" has no primary source and did not re-surface. Annotated.
- **Cost model input half-missing:** Apify Proxy $/GB was "not captured"; now added ($8/GB Starter). At that price the 125 KB/row budget is 62.5 KB/row.
- PROGRAMMX_LIVE "9 total / 5 monthly users, joined Nov 2023" are single-snippet; annotated.
- PATTERN_HYPOTHESES contains no unlabeled figures of its own; its priors cite LANDSCAPE.

## 4. Adjusted top 5 for Phase 5 probing

Ordered by (thin incumbents) x (no ToS gate) x (build cost for a solo dev at 10-15 h/week). "Easy build" = no browser, server-rendered HTML or JSON, plausibly < ~300 lines core.

| Rank | Candidate | One-line reason | Easy build? |
|---|---|---|---|
| 1 | **UK lender mortgage-rate monitor** (direct lender best-buy tables: Halifax, Nationwide, Barclays, HSBC, Santander, NatWest; daily diff; skip Moneyfacts/MSM in v1) | Zero UK-mortgage-specific Store actors in two searches; no free product-level API (Moneyfacts is paid, BoE is monthly aggregate); lender marketing pages are public and low-ToS-risk; daily change cadence fits a scheduled diff. A = 4 is the only soft spot. | Likely yes: static HTML tables, no anti-bot expected; one ~40-line parser per lender, so start with 4-5 lenders. Probe: is each table server-rendered or a JSON XHR? |
| 2 | **Lulu + Carrefour GCC grocery price monitor** (AE/SA first; diff + EAN lookup) | 5 low-effort incumbents, none advertising a diff/monitor shape; GCC retail pricing teams are a paying buyer (Bright Data and realdataapi sell Lulu endpoints); ProgrammX already sells UAE data. | Depends on probe: both are SPAs that likely expose JSON list endpoints (Carrefour MAF). If JSON: easy. If not: medium. |
| 3 | **Currys + Screwfix price & stock monitor** (drop Argos) | Currys has 1 incumbent, Screwfix 2 (one at $0.40/1k with stock + store data); UK retail monitoring has demonstrated demand (Argos has 8 actors); charge-only-on-change is not offered by either incumbent. | Medium: probe for embedded JSON state and for Akamai (Argos has it; Currys/Screwfix unconfirmed). If Akamai: drop. |
| 4 | **Pakistan EPADS/PPRA + Saudi Etimad new-tender monitor** ("tenders since last run", per authority/category) | Thinnest home-market niche left: 2 PPRA actors from one publisher (slugs "epad"/"epad-1"), 3 Etimad; government procurement notices carry the lowest ToS risk in the file; perishable (deadlines) and natural daily schedule. Demand is mid (D = 3) but the buyer (bid consultants, suppliers) pays. | Likely yes for PPRA/EPADS (public HTML lists, incumbent says no login). Etimad detail pages may be login-gated; list page is public per incumbent. |
| 5 | **Bayt + Naukrigulf + Rozee.pk new-postings monitor** (query in, only-new postings out) | 3-4 batch incumbents per site at a ~$1/1k floor, none monitor-shaped; GCC + PK recruiter audience ProgrammX can reach; job boards are usually server-rendered. Margin is thin at the $1/1k floor, so price per *new posting*. | Likely yes: server-rendered list pages, 20-50 rows/page; dedupe on job id. Probe anti-bot on Bayt. |

REVIEW (review-agent:probe-defs, 2026-10-03): rank 5's "3-4 batch incumbents per site" is refuted. Search now shows 11 Bayt actors (H = 1 for that leg, gate), 9 Naukrigulf (H = 2) and 4 Rozee (H = 3); memo23 advertises daily scheduled runs. Adjusted H for the bundle = 2, total 48.5 -> 47.0 (CANDIDATES.md row 11). Rank 5 stays in the probe set only because its probe is cheap (5.6 MB projected); a PASS should not promote it unless it is re-scoped without Bayt.

Dropped from the desk top 8 and why: PSX (legal gate, home jurisdiction), Vinted (>= 11 incumbents, 4 monitor-shaped, API moved behind DataDome), generic back-in-stock (Apify-owned head), Oddschecker (ToS forbids commercial use; incumbent exists), Marktplaats/Wallapop (monitor shape taken on both, 8+ each).

## 5. Fixes applied (all in research/desk/, annotated `REVIEW:`)

- CANDIDATES.md: totals #42, #43, G1; PakWheels count; REVIEW notes on rows 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 17, 19, 21, 26; Apify Proxy $/GB added to cost model; Decodo re-confirmation; shortlist caveat block; S2 URL hypothesis marked stale; uncertainty #4 upgraded to a gate.
- LANDSCAPE.md: rental retirement re-confirmed; apifystats cut-off note; 80/20 and payout minimums re-confirmed; Apify Proxy price captured; "$1.4M" flagged; §9.1 Oddschecker struck and monitor-variant list extended.
- PROGRAMMX_LIVE.md: re-confirmation block with prices; instantly-lead-pusher weakened; user counts flagged single-snippet.
- PATTERN_HYPOTHESES.md: H10 prior extended with the new monitor sample and a price-premium sub-test.

## 6. Residual risks

1. Everything above is still search-summary evidence. Phase 3 census must replace every count; the re-search floors here will also be low.
2. The "Official API status" column has no sources; before any A score is used for a build decision, each claim needs a URL or a live check.
3. Legal review is now the binding constraint on the whole "exchange disclosures" family (PSX, Tadawul, DFM, ADX) and on odds comparison. If ProgrammX wants PSX, the path is a licence conversation with marketdatarequest@psx.com.pk, not a scraper.
4. The cost model is built on $4/GB; on Apify Proxy it is $8/GB. Any candidate that needs residential + detail pages fails at $8/GB even if it passed at $4/GB.
5. Demand (D) remains unmeasured for all five adjusted candidates; the strongest proxy is that third-party API vendors (Bright Data, realdataapi, Anakin) sell endpoints for Lulu, Argos and Oddschecker, which is also where competition is.
6. The adjusted top 5 leans on two niches (mortgage, tenders) whose buyers are not Apify's typical self-serve developer; distribution risk is higher than for e-commerce monitors.
7. Oddschecker UK T&Cs page was not surfaced; the US page was used. Wording may differ.
