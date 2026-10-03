# Top-5 deep pass: Bayt / Naukrigulf / Rozee.pk new-job-postings monitor

Agent: top5:jobs (opus). Date: 2026-10-03. Inputs: `desk/CANDIDATES.md` row 11, `reviews/desk_review.md` §4, `reviews/probe_defs_review.md` §5, `probes/PROBE_PLAN.md` §5, `tools/probe/definitions/jobs-bayt-naukrigulf-rozee.yaml`.

All figures come from WebSearch result summaries run on 2026-10-03. They are **UNVERIFIED**: apify.com and the boards could not be fetched directly. Apify Store pages show no date, so "accessed 2026-10-03" is the only date for them. Store counts are "total users / monthly active users (MAU)".

**Headline.** The gap this candidate was built on is gone. The desk counted 3-4 incumbents per site. The real count is about 23 on Bayt, about 14 on Naukrigulf, 6 on Rozee and 7+ on GulfTalent. The three differentiators we planned are already on sale:

- **Charge only for new postings, plus alerts:** blackfalcondata (Bayt and Naukrigulf) and memo23 (GulfTalent).
- **Cross-site dedupe:** get_anything sells Bayt + GulfTalent + NaukriGulf merged into one record and billed once.
- **Price:** the market floor is about $0.80-1.00 per 1k rows.

---

## A. Scraping sources

| # | Site / page type | URL pattern | Page type | Evidence (UNVERIFIED) | Anti-bot (public) | Login wall | Grade |
|---|---|---|---|---|---|---|---|
| 1 | Bayt listing / search | `bayt.com/en/<country>/jobs/<q>-jobs/`, `?page=N` (paging unverified) | Server HTML. JSON-LD not confirmed. | jungle_synthesizer README: "Bayt.com is protected by Cloudflare… uses residential proxies to bypass the challenge" ([link](https://apify.com/jungle_synthesizer/bayt-jobs-scraper)). blackfalcondata runs a "SERP-prefilter" on listing cards ([link](https://apify.com/blackfalcondata/bayt-scraper)). | **Cloudflare** | No for listings | **MEDIUM-HARD** |
| 2 | Bayt job detail | `/en/<country>/jobs/<slug>-<7 digits>/` (confirmed) | Server HTML | blackfalcondata says it extracts "contact" data, and its prefilter skips detail fetches to save bandwidth, which suggests detail pages are heavy. | Cloudflare | Contact details sometimes. Not confirmed. | MEDIUM-HARD |
| 3 | Naukrigulf listing | `naukrigulf.com/jobs-in-<city>`, `<q>-jobs-in-<city>` | JSON/XHR API behind the SPA | memo23: "uses Naukri's and Naukrigulf's own internal search APIs via Apify Residential proxy" ([link](https://apify.com/memo23/naukri-scraper)) | No vendor named in search. Residential proxies used. | No | **MEDIUM** |
| 4 | Naukrigulf detail | `…-jid-<12 digits>` (confirmed) | JSON via the same API, or HTML | blackfalcondata lists recruiter contacts "where published" ([link](https://apify.com/blackfalcondata/naukrigulf-scraper)) | not found | Partial | MEDIUM |
| 5 | Rozee listing | `rozee.pk/jobs-in-<city>`, `/job/jsearch/q/<q>?fpn=N` | Mobile-app JSON API (`mobapp.rozee.pk`) | memo23: "reads Rozee's own mobile-app JSON API… pure HTTP, no browser" ([link](https://apify.com/memo23/rozee-scraper)). parsebird: "no login or API key". | The web frontend may have Cloudflare (a search summary inferred this; not sourced). The app API is reported as unprotected. | No | **EASY** |
| 6 | Rozee detail | `…-<city>-jobs-<7 digits>` (confirmed) | The same app API returns detail fields: salary, skills, dates. | memo23 README (above) | as above | No | EASY |
| 7 | Sitemaps / RSS | `/sitemap*.xml` on each site | XML | **Not found** for any of the three. robots.txt did not surface in search (same result as the probe review). | – | – | unknown |
| 8 | GulfTalent (add-on) | gulftalent.com search and detail | not found | 7+ actors: crawlerbros $3.00/1k, memo23 $0.89/1k with incremental runs and alerts, corvuslab, unfenced-group, solidcode, fetch_cat, blackfalcondata ([link](https://apify.com/memo23/gulftalent-scraper/api/cli)) | not found | not found | MEDIUM (assumed) |
| 9 | Indeed AE / PK (add-on) | ae.indeed.com, pk.indeed.com | – | Head-on with valig ($0.07/1k), mikolabs ($0.05/1k), misceres ($3/1k) ([link](https://apify.com/valig/indeed-jobs-scraper)) | not searched this session | No | HARD and saturated. Skip. |
| 10 | LinkedIn Jobs (add-on) | linkedin.com/jobs guest API | – | valig $0.28-0.40/1k; curious_coder; themineworks $3/1k ([link](https://apify.com/valig/linkedin-jobs-scraper)) | – | Guest pages are partial | HARD and saturated. Skip. |

**Official feeds.** We found no public Bayt, Naukrigulf or Rozee data API or partner XML read-feed. Bayt appears as a *posting* destination for Workable ([link](https://partners.workable.com/bayt)). That integration feeds jobs in, not out, so it does not reduce demand.

**Geo.** None of the sources reports geo-blocking. Incumbents use generic Apify residential proxies. Rozee is PK-hosted, and no PK-only restriction was found.

**Rate limits, robots.txt and ToS.** Not found for any of the three sites. A legal and robots.txt check by hand is still required before launch.

**Bytes and rows per request.** These are reasoned estimates, not measured.

| Request | KB / request | Rows / request | KB / row | Reasoning |
|---|---|---|---|---|
| Bayt listing HTML | ~150 (probe guess) | ~20 | ~7.5 | Server HTML with about 20 cards. Cloudflare adds some challenge overhead. |
| Bayt detail HTML | ~100-150 | 1 | 100-150 | Full page for a single job |
| Naukrigulf JSON search | ~40-80 | ~20-50 | ~1.5-2 | Compact JSON |
| Rozee app JSON | ~30-60 | ~20 | ~1.5-3 | Compact JSON |

**Blended estimate for a "new posting" row:** about **8 KB** listing-only, or about **60 KB** when Bayt detail pages are fetched for new ids.

**Posting volume (UNVERIFIED):**

| Site | Figure | Source |
|---|---|---|
| Rozee | "110+ new job postings each day" | [jobboardfinder/pakwired summary](https://www.jobboardfinder.com/jobboard-rozeepk-pakistan), undated |
| Naukrigulf | "90K+ jobs… every day" (live inventory, not new per day) | [Play Store listing](https://play.google.com/store/apps/details?id=com.naukriGulf.app&hl=en_US), accessed 2026-10-03 |
| Bayt | 2.4M+ jobs posted all-time, 60,000 hiring employers. Daily new postings not found. | [bayt.com/en/about](https://www.bayt.com/en/about/) |

Rozee is small: about 3,300 new postings a month across the whole site.

## B. Build difficulty

- **Browser needed:** no. Bayt works over HTTP with residential IPs and TLS-impersonating headers (got-scraping or curl-impersonate), according to incumbents. Naukrigulf and Rozee are JSON.
- **Core logic:** about 1,000-1,400 lines of code. That covers 3 site adapters (about 250 each), a key-value store with id+hash diffing, PPE charging, salary normalisation (PKR/AED/SAR to USD) and webhook output.
- **Maintenance: medium-high.** Bayt's Cloudflare settings change, and the Naukrigulf and Rozee internal APIs are undocumented and can change without notice.
- **Hours:** MVP (Rozee + Naukrigulf JSON, Bayt listing HTML, diff, PPE) about 35-45 h, which is **3-4.5 calendar weeks** at 10-15 h/week. v1 (add GulfTalent, cross-site dedupe, salary normalisation, Slack/Telegram alerts) about 80-100 h, which is **6-10 weeks**.
- **What could set us apart, checked against what already exists:**

| Differentiator | Already shipped by |
|---|---|
| Cross-site dedupe | get_anything/gcc-jobs-aggregator ($1.50/1k, "billed once, never per duplicate") ([link](https://apify.com/get_anything/gcc-jobs-aggregator)). automation-lab/gcc-job-listings-aggregator and fetchfinch/gcc-jobs-intelligence also exist. |
| Monitor / diff / charge only new | blackfalcondata Bayt and Naukrigulf ("emit and charge only for the diff… saves 80-95%"), memo23 GulfTalent |
| Alerts | blackfalcondata: Telegram, Slack, Discord, WhatsApp, webhook |
| Salary normalisation | blackfalcondata ("native + USD salaries"), memo23 GulfTalent ("exact USD conversion") |
| GCC + PK in one feed | **not found.** This is the only unclaimed gap, and Rozee adds only about 110 postings a day. |

## C. Competitors' revenue

Prices and users are from WebSearch summaries of Apify Store pages, accessed 2026-10-03, UNVERIFIED.

| Actor | Site | Price / 1k | Total users / MAU |
|---|---|---|---|
| blackfalcondata/naukrigulf-scraper | NG | $1.00, incremental | 537 / 127 |
| epicscrapers/naukrigulf-jobs-scraper | NG | $0.80 | 224 / 62 |
| shahidirfan/nukrigulf-job-scraper | NG | not found | 67 / 10 |
| memo23/naukri-scraper (India + Gulf) | NG + Naukri | $1.00 | 4.7K / 775 |
| memo23/naukrigulf-jobs-scraper | NG | not found | 20 / – |
| automation-lab, fayoussef ($0.96), corvuslab, scrapesage, easyapi ($2.99), alexist ($1.00), hgservices, bovi, entrogix_works, unfenced-group | NG | $0.48-2.99 | 1-4 each where shown |
| shahidirfan/bayt-jobs-scraper | Bayt | $1.00 | 310 / 74 |
| blackfalcondata/bayt-scraper | Bayt | $1.00, incremental, rated 5.0 | 71 / 32 |
| easyapi/bayt-jobs-scraper | Bayt | $2.99 | 261 / 24 |
| abotapi/bayt-com-jobs-scraper | Bayt | not found | 115 / 8 |
| agentx/bayt-jobs-scraper | Bayt | not found | 25 / 7 |
| codingfrontend/bayt-jobs-scraper | Bayt | $4.99 | 3 / 2 |
| parsebird ($0.99), jobscrawler, lentic_clockss, vero-api, hipersoft, scrapeai, solidcode, corvuslab, unfenced-group, makework36, jungle_synthesizer, piotrv1001, parseforge, khadinakbar, scrapyx, haketa, data_api | Bayt | about $1 | 0-2 each where shown |
| shahidirfan/rozeepk-jobs-scraper | Rozee | not found | 284 / 16 |
| memo23/rozee-scraper | Rozee | $1.00 | 147 / 23 |
| parsebird/rozeepk-jobs-scraper | Rozee | $1.00 | 100 / 3 |
| maximedupre ($0.90), jungle_synthesizer ($1.60), delectable_incubator (per start), soft_alexist | Rozee | $0.90-1.60 | 1-16 |
| get_anything/gcc-jobs-aggregator | Bayt + GT + NG | $1.50 | 50 / – |
| memo23/gulftalent-scraper | GT | $0.89, incremental and alerts | 59 / 26 |

**Revenue estimate (rough).** We assume one MAU pulls 2k-20k rows a month at about $1 per 1k, which is $2-20 gross per MAU per month:

| Actor | Estimated gross / month |
|---|---|
| blackfalcondata NG (127 MAU) | $250-2,500 |
| shahidirfan Bayt (74 MAU) | $150-1,500 |
| epicscrapers NG (62 MAU, $0.80) | $100-1,000 |
| All Rozee actors combined (about 45 MAU) | about $90-900 |
| Long tail (most actors, ≤ 8 MAU) | under $50 each |

These figures are **rough**. Rows per MAU is the main unknown.

**Price-ceiling benchmark.**

| Board | Price range per 1k | Sources |
|---|---|---|
| Indeed | $0.05 (mikolabs), $0.07 (valig), $0.30 (igolaizola), $3.00 (misceres, lentic_clockss) | [link](https://apify.com/valig/indeed-jobs-scraper), [link](https://apify.com/misceres/indeed-scraper) |
| LinkedIn | $0.28-0.40 (valig), $3.00 (themineworks) | [link](https://apify.com/valig/linkedin-jobs-scraper) |

Niche GCC boards cluster at $0.80-1.00 per 1k. The premium tier ($2.99-4.99) has very few MAU, so the realistic ceiling is about $1.50 per 1k.

## D. Buyer's budget

**Who buys:** GCC and PK recruitment and staffing agencies (they sell to employers that are hiring), HR-tech and job aggregators, salary-benchmarking firms, labour-market analysts and government bodies, and B2B lead-gen teams that use hiring signals.

**What they use now (UNVERIFIED):**

| Provider | Published price |
|---|---|
| TheirStack | 1 credit per job. $49/mo for 1.5k jobs, up to $1,500/mo for 1M jobs. That is about $0.0015-0.033 per job. ([pricing](https://theirstack.com/en/pricing)) |
| Coresignal | $49-5,000/mo, 1 credit per job posting ([link](https://coresignal.com/pricing/)) |
| PredictLeads | $40/mo minimum, $0.04 down to $0.002 per credit. Datasets $24k-150k a year. ([link](https://coresignal.com/coresignal-versus-predictleads/)) |
| JobsPikr | $79 / $240 / $480 per month, Enterprise custom ([link](https://www.softwareadvice.com/hr/jobspikr-profile/)) |
| Lightcast | Not published. A 2022 regional quote was $5k-12k a year ([link](https://edcconline.org/wp-content/uploads/2022/11/EDCC-Pricing-Updated-Lightcast.pdf)). GCC coverage not found. |
| LinkUp | Not published |
| Revelio | not searched |

**Willingness to pay.** Small agencies pay $1-5 per 1k rows on Apify, or $50-500 a month on SaaS. Whether TheirStack or JobsPikr cover Bayt, Naukrigulf or Rozee was **not found**. That is the one opening, because Lightcast's GCC coverage was also not found. But Apify actors already serve the long tail at about $1 per 1k.

## E. Our earning potential

**Proposed PPE (pay-per-event):**

| Event | Price |
|---|---|
| `run-start` (per poll, covers listing polls that find no new jobs) | $0.005 |
| `new-or-changed-posting` (includes detail page and USD salary) | $1.50 per 1k |

$1.50 matches get_anything and sits above the $1.00 floor. That gap is hard to justify against blackfalcondata, which offers the same diff behaviour at $1.00.

**Unit economics per 1k new rows at $1.50:**

| Item | Listing-only (8 KB/row) | With Bayt detail (60 KB/row) |
|---|---|---|
| Revenue × 80% | $1.20 | $1.20 |
| Decodo at $4.00/GB | −$0.03 | −$0.24 |
| Decodo at $2.75/GB | −$0.02 | −$0.17 |
| Compute (0.05 CU at $0.20) | −$0.01 | −$0.01 |
| **Net per 1k** | **≈ $1.16-1.17** | **≈ $0.95-1.02** |

**Hidden cost: polling bandwidth.** Hourly polling of 10 Bayt queries × 3 pages × 150 KB is about 3.2 GB a month, or about $13 per user per month at $4/GB. That is why the `run-start` charge is needed. Daily polling costs about $0.54 per user per month.

**Scenarios.** All use a blended net of about $1.00 per 1k, after a ramp of about 3 months to reach the stated users.

| Scenario | Users (steady MAU) | Rows / user / month | Rows / month | Net / month | Months to first $100 (incl. ramp) |
|---|---|---|---|---|---|
| Conservative | 3 | 3k | 9k | ≈ $9 | about 12+ |
| Base | 10 | 8k | 80k | ≈ $80 | about 4-5 |
| Optimistic | 30 | 20k | 600k | ≈ $600 | about 2-3 |

Assumptions behind the scenarios:

- **Base** puts us about level with the 2nd-ranked Bayt actor's MAU (blackfalcondata, 32). That would need 6+ months against 20+ incumbents.
- **Optimistic** means overtaking blackfalcondata. That is unlikely.
- **Conservative** is what most of the long tail shows: 0-8 MAU.

## F. Verdict: **KILL** (as scoped)

1. **Saturation.** Bayt has about 23 actors and Naukrigulf about 14. The scoring rule gives H = 1 on both GCC legs.
2. **The monitor angle is taken.** blackfalcondata already sells incremental "charge only for the diff" with Slack, Telegram and webhook alerts on Bayt and Naukrigulf at $1/1k, and it is the top-rated actor on both. get_anything already sells cross-site dedupe at $1.50/1k.
3. **The PK leg is too small to carry a product.** Rozee posts about 110 jobs a day, and its 6 actors have about 45 MAU combined. Even with charge-only-new, the volume per user is tiny.

**Biggest risk if built anyway.** Bayt's Cloudflare raises proxy bytes and maintenance, at a $1/1k price where competitors already undercut.

**What a live probe would need to confirm before reopening:**

- Bayt blocks less than 20% of requests through Decodo residential.
- Listing pages expose a newest-first sort.
- Rozee `mobapp.rozee.pk` responds with no auth.

Only a narrower re-scope would justify reopening: a "PK + GCC for Pakistani job seekers and agencies" feed (Rozee + Naukrigulf, Urdu/English, PKR salaries). No search result showed demand for it. If the probe runs anyway, treat a PASS as information, not as a reason to build.
