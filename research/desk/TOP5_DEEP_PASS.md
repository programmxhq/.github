# Top-5 deep pass: synthesis

Author: top5:synthesis (fable), 2026-10-03 (UTC). Inputs: the five deep passes in `research/desk/top5/`, plus `CANDIDATES.md`, `reviews/desk_review.md`, `probes/PROBE_PLAN.md`, `DECISIONS.md` (shared rates: Decodo $4/GB PAYG, $2.75/GB at 100 GB; Apify 80% share minus compute; $0.20/CU Starter).

**Everything here is UNVERIFIED.** Every figure comes from WebSearch summaries obtained 2026-10-03 and copied from the five files; no page was fetched live and nothing was re-searched (the session's search budget was exhausted). Where a cell says "not searched", the agent hit the 200-search cap before reaching it; that is different from "searched, none found".

## 1. Bottom line

None of the five is worth building as a Store product on today's evidence. Two are dead (Currys/Screwfix, GCC/PK jobs): the niche is crowded, the monitor shape is already sold, and each has a ToS or geo gate. Three are "TEST" only because the build is cheap and the probe is cheaper, not because demand showed up: UK mortgage (the whole mortgage-rate niche on Apify, US included, earns about $0-30/month), GCC grocery (about 16 MAU across 9 actors, Carrefour monitor already taken, both retailers' ToS forbid commercial use) and PK/SA tenders (6 Etimad actors with 0-6 users each, two of them monitors). The pattern is consistent: where Apify demand exists, 10-23 actors already serve it; where the niche is thin, nobody is buying. Margin was never the problem (net $0.35-6.28 per 1k rows in every case); volume is.

Next step: run the three cheap probes (tenders, mortgage, grocery; about 23 MB) as calibration for the harness and as geo tests, not as build decisions. Then change the selection method for the live session: start from `census.csv` demand signals and look for unhealthy incumbents, instead of inventing niches and searching for competitors.

## 2. Comparison table

| | UK mortgage rates | GCC grocery (Lulu + Carrefour) | UK retail (Currys + Screwfix) | Tenders (PK + Etimad) | Jobs (Bayt + Naukrigulf + Rozee) |
|---|---|---|---|---|---|
| **Verdict** | TEST (low ceiling; KILL as Store product unless demand shows) | TEST (leaning KILL on market size) | **KILL** | TEST (narrow, PK-first; weakest economically) | **KILL** |
| Incumbents found | 0 UK-specific; 5+ adjacent (US Bankrate/LendingTree, MSM) | 9 (6 Carrefour, 2 Lulu, 1 Talabat Mart) | 12 (Currys 6 / 5 publishers; Screwfix 6 / 5 publishers) | 8 (Etimad 6; PK 2) | ~50 (Bayt ~23, Naukrigulf ~14, Rozee 6, GulfTalent 7+) |
| Monitor shape taken? | No (niche is empty) | **Yes** on Carrefour (blackfalcondata, incremental + notifications, 7 MAU); no on Lulu | **Yes** (sync-network/currys-price-tracker) | **Yes** on KSA (gulfdata, 2 monitors, 0 MAU); no on PK | **Yes** (blackfalcondata Bayt + NG; memo23 GT); cross-site dedupe also taken (get_anything) |
| Best incumbent MAU | 1 | 7 | 6 | ≤6 (snippet garbled) | 127 (NG); 775 for memo23 Naukri incl. India |
| Proposed price / 1k | $3.00 row; $10 changed; $0.02/lender-check | $0.50 checked; $3.00 price-change | $1.50 checked; $1.00 store-stock | $8.00 new; $4.00 changed | $1.50 new/changed; $0.005 per poll |
| Net / 1k | $2.34 | $0.35 checked (HTTP) / $0.24 (browser); $2.40 change | $1.14 (HTML); $0.65 if Currys browser | $6.10-6.28 | $1.16 listing / $0.95-1.02 with detail |
| Monthly net cons / base / opt | $12 / $70 / $936 | $28 / $170 / $1,060 | $17 / $102 / $909 | $4.5 / $36 / $305 | $9 / $80 / $600 |
| Months to $100 | ~9 / ~2 / <1 | ~4 / ~1 / <1 (after first payer) | ~6 / 2-3 / 1-2 | ~24 / ~5 / 1-2 (incl. 3-mo ramp) | 12+ / 4-5 / 2-3 |
| MVP hours → weeks | 35-45 h → 3-4 wk | 25-35 h → 2-3.5 wk | 25-35 h → 2-3 wk (Screwfix only) | 25-35 h → 2-3 wk | 35-45 h → 3-4.5 wk |
| Browser needed | Yes for 2-3 of 8 lenders; MVP avoids them | Lulu no; Carrefour unknown (swing factor) | Screwfix no; Currys probably | No | No (Bayt needs TLS impersonation) |
| Hardest site + grade | Lloyds/Halifax HARD; MSM HARD | Carrefour MEDIUM-HARD; Talabat HARD | Currys HARD | Etimad MEDIUM; Punjab MEDIUM | Bayt MEDIUM-HARD |
| Legal / ToS blocker | HSBC terms: personal use only; Moneyfacts sells the data; UK database right | Lulu: personal non-commercial only, robots blocks `/api/`; Carrefour: **explicitly bans robots** | **Screwfix forbids "crawl" and commercial exploitation**; Currys ToS not found | Lowest; public notices; Etimad terms not read | Not found for any board; job T&Cs usually forbid republishing |
| Geo risk (no country targeting) | UK banks suspicious of non-UK IPs; not measured | Store-picker redirect from non-GCC IPs; not measured | **Currys UK-only, VPN-hostile, Cloudflare ASN bans** | Etimad blocks datacenter IPs; non-Saudi residential unknown; PK portals 5xx/406 to cloud | None reported |

## 3. Scraping sources and difficulty

Grades are the agents' own: EASY = plain HTTP, clean HTML/JSON; MEDIUM = header/session tricks or partial JS; HARD = browser, strong anti-bot, login or geo-lock.

### UK mortgage rates

| Site | Page type / JSON route | Anti-bot | Login | ToS / robots | Grade |
|---|---|---|---|---|---|
| HSBC public rate pages | HTML tables; a public repo says Playwright needed | not found | n | Site terms: personal use only | MEDIUM |
| HSBC intermediary rate-sheet PDF | Dated PDF URL, 100+ rows | not found | n | as above | EASY fetch / MEDIUM parse |
| NatWest | Rate page; Playwright per mortgage-tracker | not found | n | not found | MEDIUM-HARD |
| Lloyds / Halifax | Calculator; Halifax closed to new customers 2026-07-01, brand moving to Lloyds | not found | n | not found | HARD |
| Barclays | Historic JSON XHR (`costcalculator/productservice`, book-era, likely stale) | not found | n | not found | MEDIUM |
| Santander | Comparison calculator, rows in snippets (SSR or XHR) | not found | n | not found | MEDIUM |
| Nationwide (intermediary PDF) | 672 KB PDF, ~300-590 products | not found | n (marked "intermediaries only") | not found | MEDIUM |
| Coventry BS | Static marketing page | not found | n | not found | EASY (unverified) |
| Moneyfacts Compare | Best-buy tables | not found | n | Vendor sells this exact data: HIGH legal | EASY-MEDIUM tech / HIGH legal |
| MoneySuperMarket | Dynamic app; incumbent uses headless browser | not found | n | not found | HARD |
| Bank of England IADB | CSV, free | none | n | free | n/a (averages only) |

Per-lender anti-bot vendor checks: **not searched** (budget hit). Rate limits: not found for any.

### GCC grocery

| Site | Page type / JSON route | Anti-bot | Login | ToS / robots | Grade |
|---|---|---|---|---|---|
| Lulu UAE + 5 GCC | Unknown; incumbent output implies JSON somewhere; robots **disallows `/api/`, `/search/`, `/promo/`** and sort/filter/price params | not found | n | T&Cs: personal, non-commercial only | MEDIUM |
| Carrefour UAE / MAF (7 markets) | Unknown; no api/v7/v8/Algolia evidence; rigelbytes: "Apify Residential required" | IP-reputation signal; vendor not found | n | ToS **prohibits spiders/robots** and non-personal use; robots.txt not found | MEDIUM-HARD |
| Talabat Mart | App-first, by delivery zone | not found | n | not found | HARD |
| UAE MOET essentials platform | Government, 8,343 products, 525 outlets, free | not found | n | lowest | EASY? (unprobed) |
| Noon Minutes, Spinneys, Union Coop, Kibsons | **not searched** | | | | |

### UK retail

| Site | Page type / JSON route | Anti-bot | Login | ToS / robots | Grade |
|---|---|---|---|---|---|
| Currys listing / product | SFCC server HTML; no `Search-UpdateGrid` found | **Cloudflare**, error 1005 ASN bans; UK-only; VPN-hostile | n | ToS not found; robots blocks search/cart/`prefn=` | HARD |
| Currys store stock | not found | as above | n | | HARD / unknown |
| Screwfix category / product | Next.js `__NEXT_DATA__` page 1; BFF JSON for later pages; Bazaarvoice reviews | none reported | n | **T&Cs forbid crawl, deep-link, commercial exploitation**; robots.txt not found | MEDIUM |
| Screwfix Click & Collect stock | JSON (implied by dromb README) | not found | n | as above | MEDIUM |
| Toolstation / Wickes / B&Q / AO (add-ons) | not captured | not found | n | | crowded, skip |

Free alternative: both retailers publish Awin feeds (Currys "multiple feeds throughout the day", Screwfix twice daily) to approved publishers.

### Tenders

| Site | Page type / JSON route | Anti-bot | Login | ToS / robots | Grade |
|---|---|---|---|---|---|
| Etimad (KSA) | Public JSON `Tender/AllSupplierTendersForVisitorAsync?PageSize=&PageNumber=&PublishDateId=`; ~85,900 tenders in 2024 | Blocks datacenter IPs; 429 on bursts; 5xx on deep pages (incumbent READMEs); vendor **not searched** | List public; booklets need SAR 1,500/yr account | not surfaced | MEDIUM |
| EPADS federal | Server-paginated HTML `open-procurements?page=N`; mandatory since 2026-09-28 | 5xx/406 to cloud traffic (incumbent) | List public | not surfaced | EASY (provisional) |
| PPRA EPMS (legacy) | Static HTML tables, `?page=` | none reported | public | not surfaced | EASY |
| Punjab e-PAD | ASP.NET WebForms, `__VIEWSTATE` postback | not found | list public | not surfaced | MEDIUM |
| SPPRA (Sindh) | HTML table, GET pagination, archive ~2,216 pages | not found | public | not surfaced | EASY |
| KPPRA | HTML list, sequential IDs (~320/month) | not found | public | not surfaced | EASY |
| BPPRA | PHP search form; notices likely PDF scans | not found | public | not surfaced | MEDIUM |

Not searched: robots.txt for all hosts, EPADS/Punjab/SPPRA volumes, blessed_jouster user counts. Demand risk: PPRA plans OCDS adoption Dec 2026 (free federal feed would hit the PK leg).

### Jobs

| Site | Page type / JSON route | Anti-bot | Login | ToS / robots | Grade |
|---|---|---|---|---|---|
| Bayt listing / detail | Server HTML; JSON-LD not confirmed | **Cloudflare** (incumbent README); residential + TLS impersonation | listings no; some contacts gated | not found | MEDIUM-HARD |
| Naukrigulf listing / detail | Internal search JSON API behind SPA | no vendor named; residential used | no | not found | MEDIUM |
| Rozee listing / detail | Mobile-app JSON `mobapp.rozee.pk`, no auth; ~110 new postings/day | web may have Cloudflare; app API unprotected | no | not found | EASY |
| Sitemaps / RSS | not found for any board | | | | unknown |
| GulfTalent (add-on) | not found; 7+ actors | not found | | | MEDIUM (assumed) |
| Indeed / LinkedIn (add-ons) | **not searched** this session | | | | saturated, skip |

## 4. Revenue: three lenses per candidate

Assumptions shared by all five: revenue = MAU × rows/month × list price; our share = 80% minus Decodo and compute at the DECISIONS.md rates; competitor MAU and prices are single search snippets with no date. "Niche gross" is the agents' estimate of what every actor on that source earns together, which is the realistic ceiling for a new entrant.

| Candidate | Our earning potential (net/month, cons / base / opt) | Competitors' revenue estimate (gross/month) | **Sum-of-niche ceiling (gross/month)** | Buyer's current budget |
|---|---|---|---|---|
| UK mortgage | $12 / $70 / $936 at $3/1k, net $2.34/1k; conservative = 1 user × 5k rows | parseforge Bankrate ~$6; studio-amba MSM ≤$20; crawlerbros, ahmed_jasarevic ~$0 | **~$0-30, US included** | Brokers £21-44/user/mo (Mortgage Brain £31.50+VAT, Twenty7tec £21+VAT) for whole-of-market sourcing; PropertyData £28-1,300/mo (averages); Moneyfacts feeds not public; journalists and hobbyists free |
| GCC grocery | $28 / $170 / $1,060 (HTTP path); optimistic ≈ the whole current niche | blackfalcondata MAF $70-280; 123webdata $125-500 if GCC; boring_internet_explorer $8-30; other four <$40 | **~$150-600 across 9 actors, ~16 MAU** | 42signals from $500/mo; Bright Data datasets $2.50/1k records; DataWeave enterprise (no price); Actowiz/realdataapi quote only; MOET government platform free |
| UK retail | $17 / $102 / $909 at $1.50/1k, net $1.14/1k; base assumes half the leader's 6 MAU | sian.agency Currys $17-257; studio-amba Screwfix $0; ~8 others $0-750 combined | **under ~$1,000, split 10 ways** | Arbitrage Discords £25-35/mo (need sub-minute alerts); Prisync $59-399/mo; Price2Spy $40-948/mo; Skuuudle $10k-1M/yr; Awin feeds free to publishers |
| Tenders | $4.5 / $36 / $305 at $8/1k, net ~$6.1-6.3/1k; conservative = 2 users × 400 rows | All Etimad actors $20-100 combined; PK <$20 | **~$20-120** | PK aggregators $8-18/mo (PKR 3,000/mo); TendersAlerts KSA $31-77/mo; GlobalTenders $137-334/mo; BidDetail/TendersOnTime $21-208/mo; tender API $333-499/mo |
| Jobs | $9 / $80 / $600 at blended net $1.00/1k; base = matching the #2 Bayt actor's 32 MAU | blackfalcondata NG $250-2,500; shahidirfan Bayt $150-1,500; epicscrapers NG $100-1,000; Rozee actors $90-900 combined; long tail <$50 each | **~$0.6k-6k across the named leaders** (sum of the file's ranges; rows/MAU is the unknown) | TheirStack $49-1,500/mo; Coresignal $49-5,000/mo; JobsPikr $79-480/mo; PredictLeads from $40/mo; Lightcast ~$5-12k/yr (2022 quote, GCC coverage not found) |

What the three lenses say together: the only niche with a real Apify market (jobs) is the one with 50 incumbents; the four thin niches have a combined ceiling of roughly $200-1,700/month gross for every actor in them. Off-platform buyers do pay (brokers, FMCG brands, bid consultants), but they pay for whole-of-market coverage, dashboards or alerts, not raw rows, and reaching them is direct sales, which the Store does not do for us.

## 5. Cross-cutting findings

**Desk research under-counted incumbents in 4 of 5 niches, and missed the monitor shape in 4 of 5.** Grocery went from "5 publishers, none monitor-shaped" to 9 actors with a 7-MAU incremental monitor on Carrefour. UK retail went from "1 + 2" to 6 + 6 with a price-history tracker. Tenders went from 3 Etimad actors to 6 with two monitors. Jobs went from 3-4 per site to 23 / 14 / 6, with incremental billing, alerts and cross-site dedupe all already on sale. Only mortgage held, and it held because the niche is empty. The desk review had already made this same correction once (Vinted, Marktplaats, Kleinanzeigen) and the second pass still found more. A search floor is not a count.

**ToS and robots gate three of the five.** Screwfix forbids crawling and commercial exploitation; Carrefour bans robots outright; Lulu limits use to personal non-commercial and disallows its `/api/` route; HSBC limits use to personal information. Only government tender notices are clean. The scoring table still has no legal column.

**Geo risk is now concrete.** Currys is UK-only and VPN-hostile; Etimad blocks datacenter IPs and nobody knows what it does to non-Saudi residential; both GCC retailers may redirect to a store picker. With no Decodo country targeting, a geo-locked source is a plan-level KILL, not a technical one.

**Apify demand in regional niches is tiny.** Best-incumbent MAU in the four thin niches: 1, 7, 6, ≤6. ProgrammX's own four actors show 5 MAU. The user's thesis ("monitor shape on perishable sources with ≤3 incumbents") selects for empty rooms.

**The method also hit its own cap.** All five agents ran out of search budget mid-pass, so each file carries "not found" cells that mean "not searched". That ambiguity is now labelled, but it cost precision on exactly the anti-bot and robots questions that matter.

**Recommended selection approach for the live session: census first, niche second.** Build peer sets from `census.csv` (group by target site using title/name/description keywords), then filter:

1. **Demand floor:** peer-set `sum(users_30d) >= 50`, or top actor `users_30d >= 30`. Every thin niche in this pass sat below that and produced a <$100/month ceiling.
2. **Displaceable incumbent (H8):** at least one of the top 3 actors in the set has `success_rate_30d < 0.90`, or `runs_30d_failed / runs_30d > 0.10`, or `last_modified` older than 120 days (needs `--enrich`), or `deprecated` true, or a `notice`/`badge` indicating maintenance, or `rating < 4.0` with `review_count >= 3`.
3. **Not head-on:** `is_apify_owned` false (and `is_critical` false after enrichment) for every actor in the set; set size ≤ 8 actors.
4. **Shape gap:** no actor in the set whose title or description matches `monitor|alert|new listing|price drop|since last run|incremental|track`, or the ones that do fail filter 2.
5. **Price floor:** median `primary_event_price_usd` or `price_flat_or_per_result` ≥ $1 per 1k; sets where the floor is $0.05-0.50 (Indeed, dromb Screwfix) are price wars.
6. **Repeat-usage signal (H10):** prefer sets with high `runs_per_user` and `users_30d / total_users`.

Rank the surviving sets by `sum(users_30d) × (number of unhealthy top-3 actors)`, take the top 20, and only then do the ToS/robots and geo desk check by hand, add the `T` gate column, and write probe definitions for the 3-5 that pass. This inverts the current order (invent niche → search competitors → probe) and uses measured demand instead of search floors.

## 6. Probe recommendation

Total projected for all five was 40.1 MB. Keeping three costs about 23 MB.

| Probe | Run? | Why | Must show |
|---|---|---|---|
| `tenders-pk-epads-sa-etimad` (3.4 MB) | **Yes, first** | Cheapest, lowest legal risk, PK leg still thin, tests PK-portal reliability for any future PK actor | Etimad JSON 200 with rows via non-Saudi Decodo residential, and a no-proxy baseline confirming the datacenter block; wrapper key, max PageSize, PublishDateId meaning, 429 threshold; `epads.gov.pk/open-procurements?page=N` server-rendered; EPMS `?page=` works; PK p90 < 45 s with no 406; KB/row vs 2 KB JSON / 4-10 KB HTML; Punjab viewstate over plain HTTP |
| `uk-mortgage-lender-rates` (6.75 MB) | **Yes, as information** | Cheap; tells us how UK banks treat untargeted residential IPs, which matters for any UK candidate | HSBC, Barclays, Santander, Nationwide, Coventry return rate rows over plain HTTP from non-UK IPs; whether Halifax URLs redirect to Lloyds (drop them if so); Barclays/Santander JSON XHR; KB/row vs 12 KB guess; any `_abck`/`cf-ray`/`incap_ses` signature. The probe cannot test demand; a PASS does not authorise a build without 3 pre-commitments from fintech/proptech contacts |
| `gcc-grocery-lulu-carrefour` (13.1 MB) | **Yes, Lulu-weighted** | Lulu has no monitor incumbent and the GCC buyer is reachable; Carrefour result is information only given its ToS | Tiles returned to plain HTTP from non-GCC IPs with no store-picker redirect (`final_url`); Carrefour block rate ≤ 20% without a browser; real KB/request and rows/page; embedded state carrying EAN, promo, stock; Lulu pagination without the robots-disallowed sort/filter/price params; whether price varies by delivery-area cookie |
| `uk-retail-currys-screwfix` (11.25 MB) | **Drop** | Screwfix ToS gate and Currys geo-lock stand regardless of outcome | Optional: 3-5 Currys requests as a negative control to see what a hard geo-block looks like in our harness (`empty` vs vendor signal) |
| `jobs-bayt-naukrigulf-rozee` (5.6 MB) | **Drop** | The jobs file says a PASS is information, not a reason to build; 50 incumbents | Nothing that would change the verdict |

## 7. Changes needed elsewhere (list only; files not edited)

**`research/desk/CANDIDATES.md`**
- Row 3 (UK mortgage): add D downgrade (niche earns $0-30/month on Apify), HSBC site-terms gate, and the Halifax brand closure (2026-07-01) that affects the S3 URL list.
- Row 7 (Argos/Currys/Screwfix): "Currys/Screwfix remain thin (1 and 2)" is stale; now 6 + 6, monitor shape taken (sync-network), Screwfix ToS gate, Currys Cloudflare + UK geo-lock. Mark OUT.
- Row 8 (Lulu/Carrefour): "none advertises a diff/monitor shape" is wrong (blackfalcondata MAF, 7 MAU); 9 actors not 5 publishers; add Lulu robots `/api/` disallow, Carrefour robot ban, MOET free platform (A should drop).
- Row 11 (jobs): counts 11 / 9 / 4 are now ~23 / ~14 / 6; incremental billing, alerts, salary normalisation and cross-site dedupe all taken. Mark OUT.
- Row 26 (tenders): "Etimad: 3" is now 6 including 2 monitor-shaped (gulfdata); "No monitor shape advertised" is wrong for the KSA leg; add PPRA OCDS plan (Dec 2026) and EPADS mandatory date (2026-09-28).
- Shortlist blocks S3, S7, S8: URL hypotheses stale (Halifax; `www.luluhypermarket.com` vs `gcc.luluhypermarket.com`; "Carrefour is Algolia-style" unsupported).
- "Biggest uncertainties" #1: strengthen; the second pass raised counts 2-6x in 4 of 5 niches. #4: add Screwfix, Carrefour, Lulu, HSBC to the gate list.

**`research/reviews/desk_review.md` §4 (adjusted top 5)**
- Rank 2 reason "none advertising a diff/monitor shape" stale. Rank 3 "Currys has 1 incumbent, Screwfix 2" and "charge-only-on-change is not offered" stale. Rank 4 "3 Etimad" stale. Rank 5 already annotated; now KILL.
- Residual risk 6 ("distribution risk higher for mortgage, tenders") is confirmed by the revenue lens.

**`research/probes/PROBE_PLAN.md`**
- Summary table and "Run order": drop jobs and retail (or keep Currys as a 3-5 request geo control); total becomes ~23 MB.
- §1 mortgage: the 5 Halifax URLs may redirect; add "Halifax redirect" to the adjust list; consider Nationwide intermediary PDF as a counted source.
- §2 grocery: `gcc.luluhypermarket.com` robots.txt has now been seen (disallows `/api/`, `/search/`, `/promo/`, sort/filter/price params); check probe pagination params against it; add Carrefour ToS to the legal paragraph; remove "Carrefour likely uses a MAF API" as unsupported.
- §3 retail and §5 jobs: mark KILL pre-probe. §5: Rozee id pattern `…-<city>-jobs-<7 digits>` and Bayt Cloudflare are now confirmed by incumbents.
- §4 tenders: add no-proxy baseline for the datacenter block; PageSize "typically 100" vs the def's 50; PublishDateId default 5.

**`research/NEXT_SESSION.md`**
- Phase 4 row: replace "re-score with census counts" with the census-first peer-set selection in §5 above, including the `T` gate column.
- Phase 5 row: "definitions for the top 5" → 3 probes (plus optional Currys control).
- Phase 7 row: "2-3 easy survivors" is optimistic; expect 0-1 from this shortlist, with candidates coming from the census pass instead.
- §4 weak spots: add "ToS/robots gates (Screwfix, Carrefour, Lulu, HSBC) and geo-locks (Currys, Etimad) found in the deep pass; check both before any probe".
