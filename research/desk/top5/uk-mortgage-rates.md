# UK mortgage-rate monitor: deep second pass

Candidate: CANDIDATES.md row 3 / S3; desk_review.md adjusted top 5, rank 1. Probe def: `research/tools/probe/definitions/uk-mortgage-lender-rates.yaml`.
Agent: top5:uk-mortgage (opus), 2026-10-03. Every figure is from a WebSearch summary obtained 2026-10-03 and is **UNVERIFIED**. No page was fetched directly. Apify Store listings carry no page date, so "seen 2026-10-03" is the only date. The shared session search budget ran out partway through this pass (200/200), so some cells say "not found" because they could not be searched, not because a search came back empty.

## A. Scraping sources

| # | Site | URL pattern(s) | Page type | JSON / embedded-data evidence | Anti-bot (public) | Login | Paid / official alternative |
|---|---|---|---|---|---|---|---|
| 1 | HSBC UK | `hsbc.co.uk/mortgages/our-rates/`, `/first-time-buyers/rates/`, `/buy-to-let/rates/`, `/move-your-mortgage/rates/`, `/existing-customers/switch/rates/`; intermediary `intermediaries.hsbc.co.uk/ratesheet/YYYYMMDD-Rate-Sheet.pdf` | Rate tables (rate, period, APRC, booking fee, overpayment, max loan, cashback all appear in search snippets). Dated PDF rate sheet. | The ha-mortgage-rates HA plugin reads HSBC's switch-rates page directly. dirwin15/mortgage-tracker lists HSBC as "expected to fail… needs a Playwright-based scraper" | not found | n | Moneyfacts feed |
| 2 | NatWest | `natwest.com/mortgages/mortgage-rates.html`; intermediary `intermediary.natwest.com/products.html` | Rate page with LTV/fee rows (snippets quote 5.15% at 60% LTV, £995 fee). The intermediary page is said to list all products. | mortgage-tracker: needs Playwright | not found | n | Moneyfacts |
| 3 | Lloyds (and Halifax) | `lloydsbank.com/mortgages/mortgage-rates.html`, `halifax.co.uk/mortgages/...` | Calculator ("get a personalised rate", per probe-def notes) | mortgage-tracker: both need Playwright. **Halifax closed to new customers on 1 Jul 2026; its app closes on 31 Oct 2026; the brand moves to Lloyds** (mortgagefinancegazette.com, 2026-07-01). The 5 Halifax URLs in the probe def may now redirect. | not found | n | Moneyfacts |
| 4 | Barclays | `barclays.co.uk/mortgages/first-time-buyers/rates/`, `/existing-customer-centre/moving-home/rates/` | Rate pages backed by an XHR | Historic JSON endpoint `barclays.co.uk/dss/service/co.uk/mortgages/costcalculator/productservice` in Apress *Practical Web Scraping* `barclays.py` (book era, likely stale). mortgage-tracker does not list Barclays among the Playwright failures. | not found | n | Moneyfacts |
| 5 | Santander | `santander.co.uk/personal/mortgages/mortgage-calculators/mortgage-product-comparison-calculator`, `/new-customers/remortgaging-to-us` | "Compare our mortgage rates" calculator. Snippets show tracker rows (4.34-4.87%, SVR 6.50%). | mortgage-tracker: not in the Playwright list | not found | n | Moneyfacts |
| 6 | Nationwide BS | No consumer rate-table URL surfaced. Intermediary: `nationwide-intermediary.co.uk/forms-and-guides` (product guide PDF, 672 KB), `/products`, `/products/old-rates` (dated archive PDFs) | PDF rate sheet; HTML product list | One archived PDF header reads "593 product(s) match your criteria" (Dec 2023). mortgage-tracker: not in the Playwright list. | not found | n (pages are marked "for professional intermediaries only") | Moneyfacts |
| 7 | Coventry BS | `coventrybuildingsociety.co.uk/member/mortgages/.../remortgage.html` | Public marketing page with rates (per probe-def review) | none | not found | n | Moneyfacts |
| 8 | Moneyfacts Compare (aggregator) | `moneyfactscompare.co.uk/mortgages/`, `/2-year-fixed-rate/`, `/remortgage/`, `/buy-to-let/` | Best-buy tables, "updated throughout the working day" | stosgale/ha-mortgage-rates scrapes it daily | not found | n | **Moneyfacts API + daily XML/CSV datafeeds** (moneyfactsgroup.co.uk/data-provision); price not public |
| 9 | MoneySuperMarket | `moneysupermarket.com/mortgages/{lender}/` | "Dynamic web application"; the studio-amba actor uses a headless browser | none | not found | n | n/a |
| 10 | Bank of England IADB | `bankofengland.co.uk/boeapps/database/...` (e.g. series BTL275, FR2Y75) | CSV export | Free; parseforge/bank-of-england-iadb-scraper already wraps it | none | n | Free, but only monthly averages by LTV, not product-level data |

**ToS / robots.** HSBC site terms allow copying only "for personal information…; any other use is prohibited unless you first get written permission" (hsbc.co.uk/site-terms, via search, undated). No other lender's ToS or robots.txt surfaced. Moneyfacts sells this exact data, so scraping its compare site is the highest-risk leg. UK database right still needs a legal read. **Geo:** no geo-block was reported for any site. UK banks commonly treat non-UK IPs with suspicion, and Decodo gives us no UK targeting, so the probe must measure this. **Rate limits:** not found for any site. **Official API:** the Open Banking Open Data APIs cover PCA, BCA, SME loans and commercial credit cards only, with **no mortgages** (openbankinguk.github.io v2.4.0). PropertyData's `/mortgage-rates` gives averages only, from £28/month (propertydata.co.uk/api/pricing).

### Difficulty and payload per site

KB/request is the probe's own guess (180 KB incl. TLS overhead; PROBE_PLAN.md), not a measurement. Rows/request is inferred from the table sizes in snippets.

| Site | Grade | Why | Est. KB/req | Rows/req | KB/row |
|---|---|---|---|---|---|
| HSBC public pages | MEDIUM | Tables visible in snippets, but a public repo reports it needs Playwright | 180 | 15-30 | 6-12 |
| HSBC rate-sheet PDF | EASY fetch / MEDIUM parse | Predictable dated URL; PDF table parsing | ~300 (guess) | 100+ | ~2-3 |
| NatWest | MEDIUM-HARD | Needs Playwright per mortgage-tracker; intermediary page untested | 180 | 10-30 | 6-18 |
| Lloyds (Halifax) | HARD | Calculator plus browser needed; Halifax brand churn | 180 + XHR | 0 static | n/a |
| Barclays | MEDIUM | JSON XHR existed historically; needs header tricks (UA/Referer in the Apress code) | 20-60 (JSON) | 20-50 | ~1-2 |
| Santander | MEDIUM | Calculator page whose rows appear in snippets (likely SSR or XHR) | 180 | 10-30 | 6-18 |
| Nationwide (intermediary PDF) | MEDIUM | 672 KB PDF holding hundreds of products; PDF parsing | 672 | ~300-590 | ~1-2 |
| Coventry BS | EASY (unverified) | Static marketing page | 150 | 5-15 | 10-30 |
| Moneyfacts Compare | EASY-MEDIUM technically, HIGH legal | Public tables, hobby scraper works; vendor sells the same data | 200 | 20-50 | 4-10 |
| MoneySuperMarket | HARD | Headless browser per the incumbent | 1,000+ | 10-20 | 50+ |

## B. Build difficulty

- **Browser needed:** yes for 2-3 of the 8 big lenders (Lloyds/Halifax, NatWest, possibly HSBC), per dirwin15/mortgage-tracker. An MVP can avoid a browser by using HSBC, Barclays, Santander, Nationwide (PDF) and Coventry.
- **Core LOC:** about 60-120 per lender parser. Add a normalisation schema (lender, product code, type, term, LTV band, rate, APRC, fee, ERC, cashback, channel), a diff on product key (KV store), and PPE event code. MVP is roughly 700-900 LOC; v1 with 8 lenders, PDFs and Playwright is roughly 1,500 LOC.
- **Maintenance:** high relative to size. That means 8+ independent marketing sites. Halifax was retired mid-2026 and the HSBC rate-sheet URL is dated. Expect a parser break about every 1-2 months across the set (estimate, not sourced).
- **Hours:** MVP (5 HTTP/PDF sources, snapshot + diff, PPE) about 35-45 h, or **3-4 calendar weeks** at 10-15 h/week. v1 (8 lenders incl. Playwright, intermediary ranges, BTL, alerts) about 80-100 h, or **6-10 weeks**.

## C. Competitors' revenue

No UK-mortgage-specific Store actor was found in 4 queries. Adjacent actors (seen 2026-10-03, UNVERIFIED):

| Actor | Owner | Pricing | Users | Rough revenue/month |
|---|---|---|---|---|
| Bankrate Mortgage Rates Scraper | parseforge | from $4.07/1k results | 2 total / 1 MAU | 1 MAU × ~1.5k rows (daily, 50 rows) × $4.07 ≈ **$6** |
| Bankrate Financial Rates Scraper | crawlerbros | from $3.00/1k | 3 total / 0 MAU | **~$0** |
| LendingTree Scraper (mortgage monitoring) | ahmed_jasarevic | from $2.00/1k | 1 total / 0 MAU | **~$0** |
| MoneySuperMarket Scraper (incl. mortgages) | studio-amba | from $2.00/1k | 1 total / 1 MAU | ≤10k rows × $2 ≈ **≤$20** |
| Moneyfacts Savings Rates Scraper | crawlerbros | from $3.00/1k | not found | savings only; not head-on |
| MoneySavingExpert Best-Buy Tables | crawlerbros | from $3.00/1k | 1 total | no mortgages; ~$0 |
| Bankrate Rate Scraper | moving_beacon-owner1 | not found | not found | not found |
| Bank of England IADB Scraper | parseforge | not found | not found | free macro data; substitute for "average rate" buyers |
| Apify Ideas: "Mortgage rate API", "Mortgage API" | (open ideas) | n/a | n/a | requested but unbuilt (US-flavoured: FHA/VA/jumbo) |

**Assumption:** revenue = MAU × rows/month × list price. These are rough estimates. **The whole mortgage-rate niche on Apify, including the much larger US market, earns about $0-30/month.** This is the strongest data point in the file.

## D. Buyer's budget

| Buyer | What they use now | Public price |
|---|---|---|
| Brokers (36,764 FCA-permissioned individuals, H1 2026; 1,851 firms in 2024; intermediaries do about 87-91% of mortgages) | Sourcing systems with whole-of-market coverage (about 7,418 residential deals, Moneyfacts, 28 Sep 2026) | Mortgage Brain Sourcing Brain £31.50 + VAT /user/month; bundle £44; Twenty7tec £21 + VAT /user (PMS member rate) (trustpms.com) |
| Lenders, comparison sites, regulators (BoE, FCA, HMT) | Moneyfacts API / datafeeds; Moneyfacts Group revenue about $21.6-30.9 M/yr (growjo/zoominfo estimates) | not public |
| Proptech / analysts | PropertyData API (averages) | £28-£1,300/month |
| Journalists | Moneyfacts press releases, BoE IADB | free |
| Hobbyists / homeowners | DIY GitHub scrapers (mortgage-tracker, ha-mortgage-rates) | free |

**Willingness to pay:** brokers already pay about £25-55/user/month, but for whole-of-market sourcing with criteria, which an 8-lender scrape cannot replace. Lenders and fintechs pay Moneyfacts for authoritative feeds, and our feed would be weaker on coverage and liability. The only buyers who plausibly fit are fintech/proptech builders who need a cheap "big-lender headline rates" feed. Apify usage data (section C) shows few of them.

## E. Earning potential

**Proposed PPE events.** `product-row` (full snapshot) **$3.00/1k**, the middle of the $2.00-4.07 range competitors charge. `product-changed` (new/changed/withdrawn) **$10/1k** ($0.01 each). `lender-checked` **$0.02** per lender per run, so diff-only schedules still pay for the fetch.

**Unit economics per 1,000 snapshot rows** (HTML, 180 KB/req, 15 rows/req = 12 KB/row = 0.0117 GB):

| Item | PAYG $4/GB | Plan $2.75/GB |
|---|---|---|
| Revenue | $3.00 | $3.00 |
| Our 80% | $2.40 | $2.40 |
| Decodo | $0.047 | $0.032 |
| Compute (0.07 CU/1k rows, worst case with Playwright for 2-3 lenders, at $0.20) | $0.014 | $0.014 |
| **Net / 1k rows** | **$2.34** | **$2.35** |

The PDF and JSON sources cost about 5x less in bandwidth. Cost is never the constraint.

**Diff-mode cost to check.** One daily run over about 1,500 products is about 100 requests, 18 MB and 0.1 CU. Over 30 runs that comes to $2.16 Decodo (PAYG) + $0.60 compute per subscriber per month. That is why `lender-checked` exists: 8 lenders × 30 runs × $0.02 = $4.80 gross, about $3.84 at 80%.

**Scenarios** (net $2.34/1k rows):

| Scenario | Users | Rows/user/month | Rows/month | Net/month | Months to $100 |
|---|---|---|---|---|---|
| Conservative (matches section C evidence) | 1 | 5,000 | 5k | $11.70 | ~9 |
| Base | 2 | 15,000 | 30k | $70 | ~2 |
| Optimistic | 10 | 40,000 | 400k | $936 | <1 |

The base case already beats every comparable mortgage actor on Apify. The $20 PayPal threshold is reached in month 2 in the conservative case.

## F. Verdict: TEST (low ceiling); KILL as a Store product unless demand shows

The cheap probe is already defined (6.75 MB), so run it. Do not build beyond the MVP without a demand signal.

**Strongest reasons**

1. **Demand on Apify is near zero.** Five rate-scraper actors, US included, have 0-1 MAU each (section C). Being first in the UK niche does not help if the niche is empty.
2. **Buyers already pay for something better.** Brokers get whole-of-market sourcing for £21-44/user/month. Institutions buy Moneyfacts feeds covering about 7,418 deals; an 8-lender scrape covers perhaps 20-30% of that.
3. **Cost and difficulty are fine.** Net is about $2.34 per 1k rows, and an HTTP/PDF MVP is about 40 h. The build is not the problem.

**Biggest risk:** distribution and legal combined. HSBC's terms forbid non-personal use without written permission. A commercial resale feed of bank content sits in a grey zone, and the realistic buyer (fintech) will ask about licensing.

**The live probe must confirm:**

- (a) Whether HSBC, Barclays, Santander, Nationwide and Coventry return rate rows over plain HTTP via non-UK residential IPs (geo).
- (b) Whether Halifax URLs now redirect to Lloyds (drop Halifax from the def if so).
- (c) Whether Barclays/Santander expose a JSON XHR.
- (d) Measured KB/row against the 12 KB guess.
- (e) Whether any bot-manager signature appears (`_abck`/akamai, `cf-ray`, `incap_ses`).

Separately, and before building, get 3 pre-commitments from fintech/proptech contacts. The probe cannot test demand.

### Sources (all via WebSearch 2026-10-03, UNVERIFIED)
apify.com/parseforge/bankrate-mortgage-rates-scraper · apify.com/crawlerbros/bankrate-scraper · apify.com/ahmed_jasarevic/lendingtree-scraper · apify.com/studio-amba/moneysupermarket-scraper · apify.com/crawlerbros/moneyfacts-scraper · apify.com/crawlerbros/moneysavingexpert-scraper · apify.com/parseforge/bank-of-england-iadb-scraper · apify.com/ideas/mortgage-rate-api-b1ca7be6 · github.com/dirwin15/mortgage-tracker · github.com/stosgale/ha-mortgage-rates · github.com/Apress/practical-web-scraping-for-data-science/blob/master/mortgage-rates/barclays.py · hsbc.co.uk/mortgages/our-rates/ · hsbc.co.uk/site-terms/ · intermediaries.hsbc.co.uk/ratesheet/20250509-Rate-Sheet.pdf · natwest.com/mortgages/mortgage-rates.html · intermediary.natwest.com/products.html · santander.co.uk/personal/mortgages/mortgage-calculators/mortgage-product-comparison-calculator · nationwide-intermediary.co.uk/forms-and-guides · nationwide-intermediary.co.uk/products/old-rates · mortgagefinancegazette.com/banks/halifax-brand-to-vanish-after-173-years-01-07-2026/ · moneyfactsgroup.co.uk/data-provision/api/ · moneyfactsgroup.co.uk/data-provision/datafeeds/ · moneyfactscompare.co.uk/news/mortgages/best-uk-residential-mortgage-rates-this-week/ (7,418 deals, 28 Sep 2026) · openbankinguk.github.io/opendata-api-docs-pub/v2.4.0/ · propertydata.co.uk/api/pricing · trustpms.com/Bolt-ons/Sourcing-Software/Mortgage-Brain · trustpms.com/Bolt-ons/Sourcing-Software/Twenty7Tec · issmarketintelligence.com (36,764 advisers H1 2026) · mortgagesolutions.co.uk (1,851 broker firms 2024) · growjo.com/company/Moneyfacts_Group_plc
