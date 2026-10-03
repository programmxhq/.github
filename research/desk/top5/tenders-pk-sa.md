# Top-5 deep pass: Pakistan + Saudi new-tender monitor

Agent: top5:tenders (opus). Date: 2026-10-03. Inputs: CANDIDATES.md row 26, desk_review.md rank 4,
probe_defs_review.md, PROBE_PLAN.md §4, `tenders-pk-epads-sa-etimad.yaml`.

**Everything below is UNVERIFIED.** It comes from WebSearch summaries run on 2026-10-03; no page was opened.
"Src date" means the date the source itself shows. Where the summary shows none, it says "n/d" and only the
search date (2026-10-03) applies. The session's shared search budget (200 calls) ran out partway through this
pass. Gaps that would have needed more searches say "not found (budget)".

## A. Scraping sources

| Site | URL pattern(s) (seen in search) | Page type | Login wall | Anti-bot / limits / geo | Volume | Grade |
|---|---|---|---|---|---|---|
| **Etimad (KSA)** | `tenders.etimad.sa/Tender/AllSupplierTendersForVisitorAsync?PageSize=&PageNumber=&PublishDateId=`; HTML `.../Tender/AllTendersForVisitor` | **JSON API** (the portal's own front-end endpoint): public, no key. Params: PageSize (one source says "typically 100"), PublishDateId (default 5), pageNumber. Fields: tenderId, referenceNumber, tenderName, tenderNumber, agencyName, branchName, tenderActivityName, submitionDate, remainingDays [S1] | List: public. Booklets need a supplier login, an **SAR 1,500/yr company fee** and a per-tender booklet purchase [S2] | Competitor READMEs say Etimad "blocks datacenter IPs" (they default to residential), returns **HTTP 429 on bursts** and **5xx on deep pagination** [S3]. Vendor: not found. Geo-block on non-Saudi IPs: no evidence either way. robots/ToS: not surfaced. | **~85,900 tenders launched in 2024** (LCGPA via Argaam [S4]), about 7,150/month or 235/day | **MEDIUM** (JSON is easy, but it needs residential IPs plus backoff) |
| **EPADS federal** | `epads.gov.pk/` ("Open Opportunities (Procurements)"); `epads.gov.pk/open-procurements?page=16`; `epads.gov.pk/disposals`; notice `pa.epads.gov.pk/procurement/goods/<id>/sbd` | **Server-paginated HTML list** (a `?page=N` URL is indexed in search, so the list is likely not SPA-only). Home lists buyer, tender no., publish date, countdown [S5] | List: public. Bidding needs vendor registration at vendors.epads.gov.pk [S5] | Vendor: not found. Incumbent: PK portals "5xx/406 to cloud traffic". robots: not surfaced. | Mandatory for federal agencies since **28 Sep 2026** (PP Rules 2026 [S6]). "~7,000 procurements completed on EPADS 2.0 since Feb 2026" [S7], about 900/month, so expect a rise. | **EASY** (provisional) |
| **PPRA EPMS (federal legacy)** | `epms.ppra.gov.pk/public/tenders/active-tenders`, `/tenders-history`, `/public/contracts?page=`, `/public/evaluations`; `old.ppra.org.pk/dad_tenders.asp` | Static HTML tables: tender no., org, status, advertised/closing dates; contracts carry PKR value [S8] | Public | none reported | not found. Likely shrinking as EPADS becomes mandatory | **EASY** |
| **Punjab PPRA / e-PAD** | `eproc.punjab.gov.pk/ActiveTenders.aspx`; e-PADS Punjab `punjab.eprocure.gov.pk` | **ASP.NET WebForms** (`.aspx`): paging is likely a `__VIEWSTATE` postback | List public; "bidding documents available for registered bidders" [S9] | not found | not found. Trap: searches for "Punjab tenders" return **Indian** Punjab counts (e.g. "663 live", tatanexarc) | **MEDIUM** |
| **SPPRA (Sindh)** | `e.pprasindh.gov.pk/tenderlst?tender_list[page]=N&tender_list[sort][sppra_id]=DESC`; e-PADS login `portalsindh.eprocure.gov.pk` | Server-rendered HTML table, GET pagination: SPPRA ID, dept, advert/closing dates, city, notice, BER/CER, corrigendum [S10] | List public | not found | Archive reaches page ~2,216; monthly volume not found | **EASY** |
| **KPPRA** | `kppra.gov.pk/kppra/activetenders` (plain http) | HTML list with sequential numeric IDs | List public; documents from the procuring entity's office [S11] | not found | **Derived:** tender ID 32030 (advertised 2026-06-09) to 33175 (2026-09-24) is 1,145 IDs in 107 days, **≈ 320/month** [S11] | **EASY** |
| **BPPRA (Balochistan)** | `bppra.gob.pk/searchnewTender.php` | PHP search form; notices are likely PDF scans (not confirmed) | Public | not found | "219+ active" (pakistantender.com [S12]) | **MEDIUM** |

**Official API / open data (demand killers).** Etimad has no official public API in results. Third parties already
resell it: docs.tendersalerts.com "Etimad Tenders API", and parse.bot "managed Etimad API" [S1]. **Pakistan: PPRA
plans OCDS adoption in Dec 2026** under its 2026–2031 roadmap (PPRA highlights PDF, ppra.gov.pk [S13]). If PPRA
ships a free federal OCDS feed in 2027, demand for the federal leg falls. The provincial legs survive. No RSS feed
was found for any portal.

**Bytes and rows per request (estimates, to be replaced by the probe):**

| Source | KB/request | Rows/request | KB/row | Reasoning |
|---|---|---|---|---|
| Etimad JSON | 40–200 | 24–100 | ~2 | About 15 short fields plus Arabic UTF-8 (2 B/char); PROBE_PLAN PASS bar is < 50 KB per 24 rows |
| PK HTML lists | 50–200 | 10–50 | 4–10 | Gov HTML templates with inline CSS/JS; EPMS and SPPRA tables carry 8–12 columns |
| Detail pages (optional) | 30–80 | 1 | 30–80 | Needed only for value, fees and document links not in the list |

For monitor mode, repeat polls return rows we have already seen. I budget ×3 overhead: **about 15 KB per new row
list-only, about 75 KB per new row with details.**

## B. Build difficulty

- **Browser:** no. Etimad is JSON; the PK lists are server-rendered. Punjab needs a viewstate POST, not a browser.
- **Core LOC:** about 900. Etimad 120, EPADS 100, EPMS 80, SPPRA 80, KPPRA 70, Punjab (viewstate) 150,
  BPPRA 100, plus 200 for the shared schema, KV-store dedupe/diff, corrigendum detection and per-portal failure
  isolation.
- **MVP:** Etimad + EPADS + EPMS + SPPRA + KPPRA, new-only output. **25–35 h, about 2–3 calendar weeks** at
  10–15 h/week.
- **v1:** adds Punjab, BPPRA, "changed" events (deadline extensions, corrigenda), EN translation, tests and README.
  **+30–40 h, 55–75 h in total, about 4–7 weeks.**
- **Maintenance:** high for a solo dev. Seven government portals, PK outages and 5xx responses, the EPADS 2.0
  migration still under way, and possibly provinces moving onto e-PADS. Expect **2–4 h/month.**
- **Value-add:**
  - **Arabic→English** title and agency for Etimad. Etimad is Arabic-first; dottti only normalises Arabic and does
    not translate.
  - Hijri→ISO deadlines.
  - PKR/SAR→USD.
  - One schema across PK and SA.
  - "changed" detection.
  - Urdu matters little; PK notices are mostly English.

## C. Competitors on Apify and their revenue

| Actor | Owner | Model / price | Users (as shown) | Monitor shape? |
|---|---|---|---|---|
| Etimad Saudi Govt Tenders Scraper | jungle_synthesizer | PPE from **$0.80/1k** [S14] | 6 total | no |
| Etimad Tender Scraper – Deadlines | publicmoney | PPE **$2.00 → $0.70/1k** across 6 tiers ("from $1/1k") [S15] | "0 total / 6 monthly" (snippet garbled) | no |
| Etimad Tender Radar (Arabic-safe) | dottti | **$5/1k** [S16] | 1 total, 0 monthly | no |
| Etimad Pre-Planning Radar | dottti | $10/1k [S17] | n/f | no |
| **Etimad Saudi Tenders Monitor** | gulfdata | **$5/1k**, daily new-only [S18] | **2 total, 0 monthly** | **yes** |
| **Global Tenders Radar** (Etimad + WB + UN) | gulfdata | **$7/1k**, monitor mode [S18] | **1 total, 0 monthly** | **yes** |
| GulfPulse GCC Tender Intelligence | complex_intricate_networks | $10/1k and $50/1k listings [S19] | n/f | partly |
| Epad / Epad 1 / Epad 2 (PK, federal + 4 provinces + GB/AJK) | blessed_jouster(-owner) | Epad 1: $0.00001/result; Epad 2: **$0.10001/result** ($100/1k, looks like a placeholder) [S20] | not found | no |
| PPRA EPMS tenders/contracts/evaluations | owner not found | n/f [S8] | n/f | no |

**Correction to CANDIDATES.md row 26:**
- The Saudi leg now has **6 Store actors, including 2 monitor-shaped ones** (gulfdata). The row lists 3.
- The PK leg is still thin: blessed_jouster plus one EPMS actor.

**Revenue estimate (rough).** Assumptions:

- Visible users across the Etimad actors are 1–6 each.
- About 10 monthly paying users in the whole Etimad niche, each taking 2,000 rows/month at a $1–5/1k blended price.
- That gives **$20–100/month gross for all Etimad actors combined.**
- PK: assume fewer than 5 paying users at near-zero prices, so **under $20/month.**

**The niche has proven supply but not proven Apify demand.**

## D. Buyer's budget

**Buyers:**
- PK: contractors, general-order suppliers, consultants, bid-management firms.
- KSA: local and foreign suppliers, who must pay Etimad SAR 1,500/yr anyway [S2].
- Global: exporters and development-sector consultants.

**What they pay today (FX: 1 USD = 276.79 PKR, 2026-10-02 [S21]; SAR/USD 3.75, implied by GlobalTenders' "SAR
600 bn (USD 160 bn)" [S22]):**

| Service | Market | Price | ≈ USD/month |
|---|---|---|---|
| TenderAlert.pk | PK | PKR 3,000/mo; 15,000/6 mo; 25,000/yr [S23] | $10.8 / $9.0 / $7.5 |
| TenderService.pk | PK | Rs 3,000/mo; Rs 20,000/yr [S24] | $10.8 / $6.0 |
| PakistanTender.com | PK | Sole PKR 3,000/mo; Corporate 29,000/6 mo or 49,000/yr (5 logins) [S24] | $10.8 / $17.5 / $14.8 |
| TendersAlerts.com (Etimad + AI) | KSA | SAR 290/mo … SAR 115/mo (2-yr) [S25] | $77 → $31 |
| GlobalTenders.com | Global | $137 / $249 / $334 per month, billed annually [S22] | $137–334 |
| BidDetail | Global | Single country $249/yr … Corporate $2,495/yr [S26] | $21–208 |
| TendersOnTime | Global | One country $249/yr … Global Premium $1,495/yr [S27] | $21–125 |
| tenderinfo.org (may not be TendersInfo.com) | Global | Economy $429/yr; **API $499/mo or $3,990/yr** [S28] | $36; API $333–499 |
| DevelopmentAid | Dev sector | €229–429/yr individual; All-in-One €829/yr [S29] | ≈ €19–69 |

**Willingness to pay:**
- PK buyers pay about **$8–18/month for all-Pakistan alerts by WhatsApp or email.** A per-row Apify feed must
  undercut that, which caps PK pricing at a few $/1k.
- KSA and global buyers pay **$20–330/month**, and **$333–499/month for API access**. That is the ceiling a
  developer or integrator compares us against.

## E. Our earning potential

**Proposed PPE events:**
- `tender-new` at **$8 per 1,000** ($0.008 each).
- `tender-changed` at $4/1k (deadline extension or corrigendum).
- No per-start fee beyond the platform default.

**Rationale:**
- Above the $0.80–2/1k Etimad batch scrapers.
- Near the $5–7/1k monitors.
- Far below the cost per tender of a $249/yr country subscription. One user filtering to 300 tenders/month pays
  $2.40/month.
- A user taking the whole PK+SA firehose (about 10k/month) pays $80/month, close to TendersAlerts monthly pricing.

**Unit economics per 1,000 new rows:**

| Item | List-only (15 KB/row) | With details (75 KB/row) |
|---|---|---|
| Decodo @ $4.00/GB PAYG | $0.06 | $0.30 |
| Decodo @ $2.75/GB (100 GB plan) | $0.04 | $0.21 |
| Compute (assumption below) | $0.08–0.25 | $0.10–0.30 |
| Revenue @ $8/1k; 80% share | $6.40 | $6.40 |
| **Net per 1k** | **≈ $6.10–6.28** | **≈ $5.80–6.09** |

Compute assumption:
- 256 MB HTTP crawler, daily runs of 3–10 min (slow PK portals, 45 s timeouts).
- That is 0.0125–0.042 CU per run, or 0.4–1.25 CU/month per scheduled user, about $0.08–0.25 at $0.20/CU.
- The figure is per user-month (assuming about 1k rows/user), not per row. Cost scales with schedules, not rows.

**Scenarios (steady state, reached after a 3-month ramp):**

| Scenario | Paying users | Rows/user/mo | Rows/mo | Net/mo | Months to first $100 payout (incl. 3-mo ramp) |
|---|---|---|---|---|---|
| Conservative (in line with incumbents' 0–6 users) | 2 | 400 | 800 | ≈ $4.5 | about 24 (the $20 PayPal minimum is reached in about 6) |
| Base | 6 | 1,000 | 6,000 | ≈ $36 | about 5 |
| Optimistic (we win the Etimad + PK niche, EN translation lands) | 20 | 2,500 | 50,000 | ≈ $305 | about 1–2 |

Net = rows × $6.40/1k − compute ($0.25 × users) − Decodo ($0.20/1k, mid case).

REVIEW (review-agent:top5, 2026-10-03): recomputed $4.46 / $35.70 / $305.00 per month; net/1k $6.09-6.28 list-only and $5.80-6.09 with details. The 80% share is applied to revenue and costs are subtracted after it. The ramp shape is not stated: with a linear 1/3, 2/3, full ramp, base reaches $100 in month 4 (file: about 5), conservative in about 24 and PayPal $20 in month 6 (both match). Compute is per user-month, so a 400-row conservative user nets an effective $5.58/1k, not $6.10.

## F. Verdict: **TEST**, with a narrow scope. This is the weakest of the top-5 economically.

**3 strongest reasons:**
1. **Easy, cheap build.** No browser; Etimad is a public JSON endpoint; at least 4 of 7 PK portals are GET-paginated
   HTML. MVP is 25–35 h. Cost is about $0.10–0.30 per 1k rows, so the margin is about 75% of gross.
2. **Lowest legal/ToS risk in the shortlist, and a PK leg that is still thin.** EPADS became mandatory for federal
   procurement on 28 Sep 2026, which concentrates the federal flow onto one portal. The PK incumbent is a
   single-publisher actor with odd pricing.

REVIEW (review-agent:top5, 2026-10-03): this rests on the nature of government notices, not on a read: Etimad terms and every host's robots.txt were not searched (budget; see the not-found list at the end). Treat "lowest legal risk" as a prior until a human reads them.

3. **Real off-platform willingness to pay.** Buyers pay $8–18/month in PK, $31–334/month in KSA and $333–499/month
   for tender APIs. An EN-translated, PK+SA monitor has a story that ProgrammX can sell directly as well.

**Biggest risk: demand on Apify.**
- Six Etimad actors, two of them monitor-shaped at $5–7/1k, show **0–6 users each.** The monitor shape is already
  taken in KSA and has not attracted users.
- Revenue likely sits in the conservative-to-base band ($5–36/month).
- Second risk: PPRA's planned OCDS feed (Dec 2026) could commoditise the federal leg.

**Recommended scope for the TEST:**
- Lead with PK (EPADS + EPMS + SPPRA + KPPRA), plus Etimad as a cheap add-on with EN translation.
- Kill threshold: **fewer than 3 paying users or under $10/month net 60 days after listing.**

**The live probe must confirm:**
1. The Etimad JSON returns 200 with rows through a **non-Saudi Decodo residential** IP, which tests the
   geo-block risk. A no-proxy baseline should confirm the datacenter block. Also check the wrapper key, max
   PageSize, PublishDateId semantics, and the 429 threshold.
2. `epads.gov.pk/open-procurements?page=N` is server-rendered, with rows in the HTML.
3. `?page=` works on EPMS active tenders.
4. PK portals respond from non-PK residential IPs at p90 under 45 s, with no 406.
5. Measured KB/row against the 2 KB (JSON) and 4–10 KB (HTML) estimates.
6. Punjab viewstate paging works over plain HTTP.

## Sources (WebSearch, 2026-10-03; all UNVERIFIED)

- S1: <https://parse.bot/marketplace/cdd27019-78e5-4cd9-b912-26eaf721ab67/tenders-etimad-sa-api>,
  <https://docs.tendersalerts.com/>, <https://github.com/AhadFaiz/SEEK> (src date n/d)
- S2: <https://tendersalerts.com/en/articles/etimad-fees>,
  <https://portal.etimad.sa/en-us/services/servicedetails?ServiceGuid=a3605276-839a-4d75-8ca0-88f771d0c732> (n/d)
- S3: <https://apify.com/gulfdata/global-tenders-radar>, <https://apify.com/dottti/etimad-tender-radar>,
  <https://apify.com/publicmoney/etimad-tender-scraper> (README snippets; the actor carrying each quote is not
  pinned)
- S4: <https://www.argaam.com/en/article/articledetail/id/1827106> (LCGPA 2024 report)
- S5: <https://epads.gov.pk/>, <https://epads.gov.pk/open-procurements?page=16>,
  <https://pakera.pk/bid-federal-government-tender-epads/>
- S6: <https://quwa.org/pakistan/market-intelligence/pakistans-public-procurement-rules-2026-what-has-changed-what-remains-and-where-dipra-fits/>,
  <https://www.dawn.com/news/2033401>
- S7: <https://epads.com.pk/epads-2-0-complete-guide/> (summary of a PPRA-related result; exact page uncertain)
- S8: <https://epms.ppra.gov.pk/public/tenders/active-tenders>, <https://epms.ppra.gov.pk/public/contracts>,
  <https://epms.ppra.gov.pk/public/evaluations>
- S9: <https://eproc.punjab.gov.pk/ActiveTenders.aspx>, PLRA notice PDF (punjab-zameen.gov.pk)
- S10: <https://e.pprasindh.gov.pk/tenderlst>
- S11: <http://www.kppra.gov.pk/kppra/activetenders>
- S12: <https://pakistantender.com/bppra-tenders>, <http://bppra.gob.pk/searchnewTender.php>
- S13: ppra.gov.pk highlights PDF (`ppra.gov.pk/media?file=...`),
  <https://www.pakistantoday.com.pk/2026/01/20/epads-a-platform-for-transparency-accountability>
- S14: <https://apify.com/jungle_synthesizer/etimad-saudi-government-tenders-scraper>
- S15: <https://apify.com/publicmoney/etimad-tender-scraper>
- S16: <https://apify.com/dottti/etimad-tender-radar>
- S17: <https://apify.com/dottti/etimad-preplanning-radar>
- S18: <https://apify.com/gulfdata/etimad-tenders-monitor>, <https://apify.com/gulfdata/global-tenders-radar>
- S19: <https://apify.com/complex_intricate_networks/gulfpulse-gcc-tender-scraper>
- S20: <https://apify.com/blessed_jouster/epad>, <https://apify.com/blessed_jouster-owner/epad-1>,
  <https://apify.com/blessed_jouster-owner/epad-2>
- S21: <https://pluang.com/en/tools/currency-converter/usd-pkr> (2026-10-02)
- S22: <https://www.globaltenders.com/global-tenders-yearly-packages>,
  <https://www.globaltenders.com/saudi-arabia-tenders>
- S23: <https://tenderalert.pk/>
- S24: <https://tenderservice.pk/permits/login.php>, <https://pakistantender.com/>
- S25: <https://tendersalerts.com/en/plans>
- S26: <https://www.biddetail.com/membership-plan>
- S27: <https://www.tendersontime.com/subscribe/>
- S28: <https://www.tenderinfo.org/pricing> (may not be TendersInfo.com)
- S29: <https://www.developmentaid.org/experts/membership>,
  <https://www.developmentaid.org/news-stream/post/208987/all-in-one-membership-at-developmentaid>

Not found (search budget exhausted): Etimad anti-bot vendor, robots.txt for all hosts, EPADS/Punjab/SPPRA
monthly volumes, blessed_jouster user counts, owner of the EPMS actor, AJK/GB volumes.
