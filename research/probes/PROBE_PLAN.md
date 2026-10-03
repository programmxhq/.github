# Phase 5 probe plan: adjusted top 5

Author: probe-def-agent (opus), 2026-10-03 (UTC). Built offline: no request has been sent to any
target or to Decodo. Every URL pattern and selector comes from WebSearch result summaries. URLs
and selectors that no result confirmed are marked `# UNVERIFIED` in the definitions.
Source shortlist: `research/reviews/desk_review.md` section 4.

Definitions are in `research/tools/probe/definitions/`. All five pass `python -m probe validate`,
and `python -m probe plan` accepts them (projected total 40.1 MB of the 500 MB cap, 0 B used).

| # | Candidate | Definition | URLs / requests | Est. B/req | Projected (x1.25) |
|---|---|---|---|---|---|
| 1 | UK lender mortgage rates | `uk-mortgage-lender-rates.yaml` | 30 / 30 | 180 KB | 6.75 MB |
| 2 | Lulu + Carrefour GCC grocery | `gcc-grocery-lulu-carrefour.yaml` | 30 / 30 | 350 KB | 13.13 MB |
| 3 | Currys + Screwfix | `uk-retail-currys-screwfix.yaml` | 30 / 30 | 300 KB | 11.25 MB |
| 4 | EPADS/PPRA + Etimad tenders | `tenders-pk-epads-sa-etimad.yaml` | 30 / 30 | 90 KB | 3.38 MB |
| 5 | Bayt + Naukrigulf + Rozee jobs | `jobs-bayt-naukrigulf-rozee.yaml` | 30 / 30 | 150 KB | 5.63 MB |
| | **Total, one pass each** | | 150 requests | | **40.1 MB** |

The B/req estimates are guesses. Two safeguards limit the cost if they are wrong. The harness
stops any single run at `per_probe_max_bytes` (25 MB). Each response is also capped at
`max_response_bytes` (2-3 MB). The worst case for one full pass of all five is therefore
5 x 25 = 125 MB. A realistic budget is 40 MB for the first pass, about 40 MB for one re-run
after adjusting the extractors, and 15 MB for the smoke tests. That totals about 95 MB and
leaves roughly 400 MB of headroom.

## Harness facts every candidate shares

- **Rows come from a robust marker, not a precise selector.** The harness reads one `extract`
  spec, and it does not save response bodies (only a 2-row sample on `ok`). So `extract` in each
  definition is a regex that counts *distinct* ids or values. It uses a negative lookahead, so a
  product that appears three times (card, link and embedded JSON) counts once. That makes rows a
  lower bound, so cost/1k rows errs high, which is the safe direction. Each file also has an
  `extract_precise` block, which the harness ignores. It holds the CSS/JSON selector to switch to
  once the markup has been seen. Unit check: each regex was run on synthetic bodies and gave the
  intended counts. The worst-case speed is about 4 s for a 1.5 MB page.
- **Mixed hosts, one verdict.** Each candidate bundles 2-8 hosts in one definition, so the
  harness verdict is a blend of all of them. Before reading PASS or KILL, group
  `results.jsonl` by host (the `url` field) and compute the block rate and bytes/row per host.
  A candidate can survive with one host dropped, as Argos was.
- **`empty` is ambiguous.** It counts towards the block rate, but it can mean any of four things:
  a soft block, a JS-only page, a marker that does not match, or a geo redirect. Check
  `final_url`, the status, and the `signals`/vendor fields before calling it a block.
- **No geo-targeting.** The Decodo plan has no country parameter (`creds.py`). GCC and PK sites
  may geo-redirect, which shows up as `empty`. UK sites are usually fine from any exit IP.
- **Plain Python TLS fingerprint.** If a vendor that fingerprints TLS hard-blocks a host (Akamai,
  Kasada, DataDome), record it as "needs a browser-TLS client" rather than as "unreachable"
  (README "Fingerprint gap").
- **Run order.** Do the health check and the smoke tests first. Then run the cheapest and most
  likely PASS first: tenders (3.4 MB), then jobs, mortgage, retail and grocery. Use
  `--baseline` on the first run of each candidate so the 3 direct requests show what an
  unproxied client sees.
- **robots.txt.** Lulu's robots.txt is the only one that surfaced in search (it disallows search,
  cart, checkout and my-account). Fetch the others by hand in the live session before running,
  and delete any URL family they disallow.

## Global PASS / KILL (config.yaml `verdict`)

- **KILL** if block rate > 20%, cost > $0.50 per 1k rows at the primary price ($4/GB PAYG,
  UNVERIFIED), error rate > 30%, or zero rows.
- **PASS** otherwise.
- **INCOMPLETE** if fewer than 20 requests completed.
- **Second cut at Apify Proxy prices.** Apply this by hand at $8/GB (Apify residential, per
  desk_review), which is a budget of 62.5 KB/row. A candidate that passes at $4 but fails at $8
  can only ship with the "+ usage" pricing toggle.

---

## 1. UK lender mortgage-rate monitor (`uk-mortgage-lender-rates`)

**What is tested.** Whether direct-lender rate tables can be fetched with a plain HTTP client
through residential IPs, and whether they are server-rendered. The probe covers 8 lenders:
HSBC, NatWest, Halifax, Lloyds, Barclays, Santander, Coventry BS and Nationwide. It requests
25 distinct URLs, 5 of them twice to mimic a repeat poll. It also measures what one rate row
costs in bytes.

**Row marker.** Distinct rate strings (`4.69%`) per page, with `min_rows: 3`. A page that only
mentions the SVR or base rate gives 1-2 and fails.

**PASS means** at least 4 lenders return tables without blocks, at under $0.50 per 1k rows. This
should be easy: one 150 KB page holds 10-30 rates, about 5-15 KB/row. The real question is
coverage, not cost.

**KILL means** at least one of the following:

- Most lender pages are JS-rendered (rows = 0 with no vendor signal), so a headless browser
  would be needed per lender.
- A bot manager blocks more than 20% of requests.

Note: KILL on cost is very unlikely here.

**Known weak spots.**

- Halifax, Lloyds and Santander rate pages are described as calculators ("get a personalised
  rate"), so they may be `empty` without any blocking. If so, find their XHR product endpoint.
  Lloyds Banking Group brands likely share one endpoint.
- No Nationwide rate-table URL surfaced in search; both Nationwide rate URLs are UNVERIFIED.
- Barclays `/mortgages/mortgage-rates/` is a desk guess.

**ToS / legal.**

- Public marketing pages, no login.
- Bank T&Cs typically forbid systematic extraction, and UK database right applies to a
  commercial daily feed. This needs a legal check before launch.
- Aggregators (Moneyfacts, MSM, Uswitch) are excluded on purpose, following the desk review.
- HSBC intermediary rate-sheet PDFs are public but were left out because rows cannot be counted
  in PDFs.

**Adjust after the first live response.**

1. Per lender, decide between "static table" and "JS calculator". For calculators, record the
   XHR URL from a browser and add it as a JSON URL.
2. Replace the regex with `table tbody tr` (or the real row selector) per lender. Note the
   duplication factor between distinct rates and products.
3. Replace or delete the UNVERIFIED Nationwide and Barclays URLs.
4. Bytes: if a page is over 300 KB, look for a lighter endpoint (a print view or JSON).

## 2. Lulu + Carrefour GCC grocery price monitor (`gcc-grocery-lulu-carrefour`)

**What is tested.** Whether category pages on `gcc.luluhypermarket.com/en-ae` and
`carrefouruae.com/mafuae/en` return product tiles to a plain HTTP client from non-UAE
residential IPs, and at what bytes per product. The probe covers:

- 22 UAE URLs plus 4 other GCC URLs (Lulu KSA, KW, QA and BH).
- 24 category pages and 6 product pages.

**Row marker.** Distinct `/p/<digits>` product ids. On product pages, related-product links
inflate the count; those are 6 of the 30 requests.

**PASS means** the block rate is at most 20% on both hosts and product ids are visible in the
HTML. Cost should land well under $0.50/1k: 350 KB / 30 products is about 12 KB/row, or
$0.05/1k.

**KILL means** at least one of the following:

- A bot manager on either host blocks the plain client. Carrefour/MAF is the likelier host to
  run one; this is unverified.
- Every page is `empty` because tiles render client-side and no JSON endpoint can be found.
- Geo-redirects make the data unreachable without UAE IPs. Our plan has no country targeting,
  so this would be a cost/plan KILL rather than a technical one.

**ToS / legal.**

- Lulu robots.txt disallows search, cart, checkout and account pages, so no search URLs are used.
- Carrefour robots.txt has not been seen; check it.
- Neither T&Cs has been read. A price feed sold to competitors is the usage retail T&Cs target,
  so this needs a legal check before launch.
- Sitemaps were excluded from the probe (1-5 MB each would distort rows/request). Note that
  sitemaps are the discovery route the actor would use.

**Adjust after the first live response.**

1. Check whether `__NEXT_DATA__` or another embedded state exists. If so, switch to
   `json_in_html` and find the real path (the current path is a placeholder).
2. If tiles are client-rendered, capture the category XHR (Carrefour likely uses a MAF API)
   and probe it as JSON with the correct headers.
3. Confirm the pagination params (`?page=`, `?currentPage=`); both are UNVERIFIED.
4. If `final_url` shows a store or region picker, record it as geo and decide whether a
   country-targeted plan is worth it.
5. Check whether the EAN/GTIN is on listing pages or only on detail pages. If only on detail
   pages, the per-row cost of EAN lookup equals the detail-page bytes.

## 3. Currys + Screwfix price & stock monitor (`uk-retail-currys-screwfix`)

**What is tested.** Anti-bot posture and bytes per product on listing pages. The probe uses
13 Currys listing pages and 16 Screwfix listing pages (including faceted `?brand=` and
`?powersupply=` filters), plus 1 Screwfix product page. No Currys product URL surfaced in
search, so none is probed.

**Row marker.** Distinct Screwfix `/p/<slug>/<code>` links and Currys
`/products/<slug>-<digits>.html` links. The Currys pattern is UNVERIFIED.

**PASS means** the block rate is at most 20% on each host and tiles are visible in the HTML.
Expected cost is about 300 KB / 20 tiles = 15 KB/row, or $0.06/1k.

**KILL means** Akamai or a similar vendor hard-blocks either host. Per the desk review, that
host is then dropped: Argos was dropped for exactly this reason. If both hosts are blocked, the
candidate is dead. Zero rows with no vendor signal is most likely the Currys marker; check
`rows_seen` and the samples before calling it a KILL.

**ToS / legal.** Neither robots.txt nor the T&Cs surfaced in search; check them by hand.
Faceted filter URLs are a common robots.txt disallow; drop them if listed. Price and stock facts
carry lower risk than descriptions or images.

**Adjust after the first live response.**

1. Currys: confirm the tile markup (SFCC usually has `data-pid`) and the product URL shape, then
   switch `extract`.
2. Screwfix: confirm the tile selector and whether stock or delivery status is in the listing
   HTML or a separate call. The per-store stock call would be extra bytes per row.
3. Confirm the paging params (`?start=&sz=` for Currys, `?page_start=` for Screwfix); both are
   UNVERIFIED.
4. If Screwfix exposes a JSON BFF in the network tab (not surfaced in search), probe it
   separately; it would cut bytes/row by about 10x.

## 4. EPADS/PPRA + Etimad new-tender monitor (`tenders-pk-epads-sa-etimad`)

**What is tested.**

- Etimad: the public visitor JSON endpoint `Tender/AllSupplierTendersForVisitorAsync?PageSize=&PageNumber=`
  (12 requests) and the HTML list (4). The endpoint is confirmed by a search summary as
  unauthenticated, with fields `tenderId` and `referenceNumber`.
- Pakistan: federal EPADS 2.0 (`epads.gov.pk`), PPRA EPMS active tenders and history, legacy
  PPRA, one EPADS notice, and Punjab, KP and AJK list pages (14).

This also tests reliability: the incumbent reports 5xx/406 responses from PK provinces to cloud
traffic.

**Row marker.** Distinct ids of any of four kinds: `"tenderId": n`, `STenderId=`,
`TS…E` (PPRA reference) and `/procurement/<type>/<n>` (EPADS). There is no marker for the
3 provincial pages; treat their `empty` results as an extractor gap and exclude them from the
block rate.

**PASS means** the Etimad JSON returns 24 rows per call at under 50 KB (about 2 KB/row, or
$0.01/1k), and the PPRA EPMS and EPADS list pages return rows. Tenders are low volume (a few
hundred new per day), so reliability matters more than cost.

**KILL means** either of the following:

- Etimad geo-blocks or challenges non-Saudi IPs on both JSON and HTML. The Saudi leg is then
  dead without KSA IPs; the PK leg can continue alone.
- EPADS federal (the mandatory route since 28 Sep 2026 per search) returns no rows because the
  SPA has no server-rendered list. In that case, find its XHR before killing the candidate.

**ToS / legal.** These are government notices published for bidders; this is the lowest-risk
candidate. Etimad detail pages and booklets may need a login; the probe stays on list data.
Etimad terms were not read. The PPRA invoice pages (public, billing documents) were deliberately
not probed.

**Adjust after the first live response.**

1. Find the Etimad JSON wrapper key (assumed `data`) and the maximum `PageSize` (50 is
   UNVERIFIED), and work out what `PublishDateId` means (1 and 5 seen; meaning UNVERIFIED).
2. Check whether `X-Requested-With` is needed; drop it if it is not.
3. Confirm that EPMS `?page=` works on active tenders (confirmed only on `/public/contracts`).
4. Add per-province markers or drop provinces from v1. They are the "isolate portal failures"
   part of the incumbent's README.
5. `timeout_s` is 45 s. If the PK p90 latency is near that, raise it, because timeouts count as
   `error`.

## 5. Bayt + Naukrigulf + Rozee new-postings monitor (`jobs-bayt-naukrigulf-rozee`)

**What is tested.** Anti-bot and bytes per job on listing pages for 3 boards: 10 Bayt
(SEO listing paths plus 1 detail page), 9 Naukrigulf (`/jobs-in-<city>`) and 10 Rozee
(`/jobs-in-<city>` and `/job/jsearch/q/<q>`). The monitor would poll listings and dedupe on job
id.

**Row marker.** Distinct job ids from Bayt `/jobs/<slug>-<digits>/` (confirmed), Naukrigulf
`jid-<digits>` (UNVERIFIED) and Rozee `-jobs-<digits>` (UNVERIFIED).

**PASS means** the block rate is at most 20% per board and there are at least 15 ids per listing
page. Expected cost is about 150 KB / 20 = 7.5 KB/row, or $0.03/1k.

**KILL means** Cloudflare or another vendor blocks Bayt (the desk flagged Bayt anti-bot as the
open question). Zero ids on Naukrigulf or Rozee with no vendor signal means the marker is wrong,
not that the board is blocked.

**Scoring note found while building this.** Search on 2026-10-03 surfaced **8 Bayt actors**
(easyapi, parsebird, shahidirfan, codingfrontend, scrapyx, lentic_clockss, haketa, data_api) and
**7 Naukrigulf actors** (easyapi, alexist, epicscrapers, memo23, automation-lab, corvuslab,
hgservices). memo23's README describes recruiters running *daily scheduled* runs, which is close
to the monitor shape. Under the desk rubric, H drops from 3 to about 1-2 for Bayt and
Naukrigulf. Rozee (4) is the thinnest leg. Re-score before investing build time, whatever the
probe verdict.

**ToS / legal.** robots.txt was not seen for any board. The Rozee `/job/jsearch/` URLs are
search-style and the first to drop if they are disallowed. Job-board T&Cs usually forbid
republishing listings, so the output should be new-posting facts plus a link, not full
descriptions.

**Adjust after the first live response.**

1. Confirm the Naukrigulf and Rozee detail-link id patterns and fix the regex.
2. Check for JSON-LD `JobPosting` or an embedded state blob on listing pages, which would be a
   cheaper and more stable extractor.
3. Confirm the paging patterns (`?page=2` on Bayt, `-2` on Naukrigulf, `?fpn=20` on Rozee); all
   are UNVERIFIED.
4. Check whether the listing is sorted newest-first by default. If not, find the sort param,
   because the monitor depends on it.

---

## After any live run

1. Run `python -m probe report` and read `research/probes/PROBES.md`.
2. Split each candidate's `results.jsonl` by host before accepting the blended verdict.
3. Edit only `extract` and the URL list, keeping `expected_bytes_per_request` close to the
   observed p90. Then re-run with `-n 20` to save budget.
4. Never hand-edit `traffic_ledger.json`.
