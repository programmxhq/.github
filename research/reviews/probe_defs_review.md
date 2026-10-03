# Review: Phase 5 probe definitions (5 candidates) and PROBE_PLAN.md

Reviewer: review-agent:probe-defs (opus), 2026-10-03 (UTC). Offline only: no `probe run` and no `probe health`,
no request was sent to any target or to Decodo. robots.txt and incumbent evidence come from WebSearch summaries
(UNVERIFIED wording). Nothing committed.

Scope: `research/tools/probe/definitions/{uk-mortgage-lender-rates, gcc-grocery-lulu-carrefour,
uk-retail-currys-screwfix, tenders-pk-epads-sa-etimad, jobs-bayt-naukrigulf-rozee}.yaml` and
`research/probes/PROBE_PLAN.md`.

## Verdict: PASS WITH FIXES

The definitions follow the user's rules. All URLs are public pages. None is a login, account, cart or checkout
endpoint, and none is a search-engine page. Each candidate makes 30 requests, inside the 20-50 range. The total
projection is 40.1 MB, inside the 500 MB cap. Three of the five row markers were wrong on plausible markup and
are now fixed:

- **Currys:** 0 rows on dotted product slugs.
- **Mortgage:** 0 rows on split-span rates.
- **Bayt:** 0 rows on percent-encoded slugs.

Several header and plan statements were also inaccurate and are now corrected. A per-host breakdown is now in
the harness.

## Checks

### 1. URL policy, robots.txt, ToS headers

| Check | Result |
|---|---|
| Login / account / cart / checkout | None. `probe validate` raises no LOGINISH warning. Coventry `/member/...remortgage.html` is a public marketing page (search shows rates on it). Barclays `existing-customer-centre/moving-home/rates/` is a public rates page. The Etimad probe covers list data only; detail pages, which may need a login, are excluded. |
| Search-engine pages | None. **Site-search** pages are present: 4 Rozee `/job/jsearch/` URLs and 1 Etimad `AllTendersForVisitor?...IsSearch=true` URL. They are public, but they are the URL family most often disallowed. |
| robots.txt (search-visible) | **Lulu:** the file that surfaced belongs to `www.luluhypermarket.com` and disallows `*/search*`, cart, checkout and my-account. Every probe URL is on `gcc.luluhypermarket.com`, which has its own robots.txt (unseen). The header claimed the probe followed Lulu's robots.txt; that claim was inaccurate and is corrected. **Currys:** disallows search, cart, account registration, wishlist, checkout and `prefn=`/`pmin=`/`pmax=`. No probe URL uses any of these; `?start=&sz=` was not seen either way. **Screwfix:** the only file that surfaced is `shop.screwfix.eu`, a different site (it disallows `/search` and `/policies/`). The robots.txt files for `screwfix.com`, Carrefour, the banks, Bayt, Naukrigulf, Rozee, Etimad and the PK portals did not surface. |
| Disallowed URL found? | None confirmed. No probe URL matches a disallow seen in search. Unknown: the 6 Screwfix faceted URLs, the 4 Rozee jsearch URLs and Lulu `?page=2`. |
| ToS notes in headers | Accurate in substance: every header says the T&Cs are unread and calls for a legal check. The Lulu robots.txt host claim is corrected. |

### 2. Row-count markers

New file: `research/tools/probe/tests/test_definition_markers.py`. It contains realistic snippets for each site.
In each snippet, one id appears in an href, a second href (with `?`, `#` or `/`), a data attribute and JSON-LD
or `__NEXT_DATA__`. The test asserts that the id counts once and that plausible markup does not count zero.
The URL shapes for Currys, Screwfix, Naukrigulf `-jid-` and Rozee `-lahore-jobs-<n>` were confirmed in search.

| Candidate | Before | Bug | Fix |
|---|---|---|---|
| Mortgage | 6 of 7 | `<span>5.04</span><span>%</span>` gave 0. `\b` let `1.4.69%` yield `4.69`. | Allow up to 3 tags or spaces before `%`; use the lookbehind `(?<![\d.])`. |
| Grocery | correct (4) | none | none |
| Retail | 3 of 6 | Currys slugs contain dots (`...-15.6-laptop-...-10284802.html`), so every such tile counted 0. The dedupe `\1` had no boundary, so `/p/x/3738` was swallowed by a later `/p/x/37381`. Single-quoted hrefs were not delimited. | Slug class `[A-Za-z0-9.%-]`; boundary `(?![0-9a-z])` in the lookahead; `'`, `<` and whitespace added as delimiters. |
| Tenders | correct (24 JSON, 6 HTML) | none. `tenderIdString` and nested `tenderId` repeats are handled. | none |
| Jobs | 5 of 6 | A percent-encoded (Arabic) Bayt slug gave 0. | Slug class `[A-Za-z0-9%-]`. |

The comment in the mortgage header called the marker a "LOWER bound". That was wrong: an APRC with two decimal
places counts as an extra row. The comment now calls the marker approximate.

### 3. validate / plan

`python -m probe validate` passes all 5 with no warnings, both before and after the fixes. `python -m probe plan`:

| Candidate | Projected (x1.25) | Under 25 MB per-run limit? |
|---|---|---|
| Mortgage | 6,750,000 B | yes |
| Grocery | 13,125,000 B | yes |
| Retail | 11,250,000 B | yes |
| Tenders | 3,375,000 B | yes |
| Jobs | 5,625,000 B | yes |
| **Total** | **40,125,000 B** of 500,000,000 B | OK |

### 4. Per-host breakdown (implemented)

- `runner.py` gains `per_host()`, about 20 lines, plus about 15 lines in `write_probes_md`. Nothing in byte
  accounting, the ledger or the cap code was touched.
- `summary.json` has a new `per_host` object keyed by requested host, with `www.` folded. Each entry gives
  requests, ok, outcomes, block_rate (errors excluded, as in the run total), rows, bytes, bytes_per_row,
  cost_per_1k_rows_usd at the primary price, and antibot_vendors.
- PROBES.md prints a "Per-host breakdown" table for definitions with more than one host.
- Tests:
  - A unit test checks `www.` folding, block rate with errors excluded, and bytes/row.
  - An end-to-end test through the stub proxy uses two hostnames (localhost and 127.0.0.1, both on the fixture
    cert), one healthy and one empty. The blended verdict is KILL at a 50% block rate, while the clean host shows
    0%. Per-host bytes and rows sum to the run totals.
- Full suite: **70 passed** (was 56; +12 marker tests, +2 per-host tests).
- PROBE_PLAN.md and the harness README are updated. The plan also gives a `jq` one-liner for splitting by host
  across runs.

### 5. Candidate 5 incumbents

The probe-def-agent's finding holds. Search found 8 Bayt and 7 Naukrigulf actors. My re-search adds 3 more on
Bayt (jobscrawler, blackfalcondata, piotrv1001), for **11 → H = 1** on that leg (gate), and 2 more on Naukrigulf
(bovi, blackfalcondata), for **9 → H = 2**. Rozee has 4 (H = 3). memo23 advertises daily scheduled runs.

- `REVIEW:` lines were added to `desk/CANDIDATES.md` row 11 and `reviews/desk_review.md` §4: bundle H 3 → 2,
  total 48.5 → 47.0, following the per-leg convention of #5 and #7. The recommendation is to drop Bayt from v1
  or treat the candidate as weak.
- The probe stays in the plan because it is cheap (5.6 MB). A PASS should not promote it.

## Other fixes

- **Mortgage notes:** these said "25 URLs, 5 repeated". The actual count is 23 distinct with 7 repeated. Fixed
  in the YAML and in PROBE_PLAN.
- **Grocery notes:** these said "22 UAE". The actual count is 26. One URL on the bare host `carrefouruae.com`
  was changed to `www.`; without that, every request would cost a redirect hop and the URL would split into its
  own host in the breakdown.
- **PROBE_PLAN:** the regex speed claim was replaced with measured numbers (below), and the "after a live run"
  step now points at the per-host table.

## Residual risks

1. **The markers are still guesses about live markup.** Only the URL shapes are confirmed. If Lulu, Carrefour,
   Rozee or Currys render tiles client-side, those hosts will show `empty`, and the blended block rate will read
   as anti-bot. Read the per-host table, `final_url` and the signals first.
2. **The dedupe regexes are quadratic.** With 100-800 ids near the top of a 1.2 MB page, extraction takes
   3-10 s; a 3 MB body could take 25-60 s. This costs CPU time, not bytes. If it hurts, a small `distinct: true`
   option in `extract.py` (`len(set(findall))`) would make extraction linear; it was not added, to keep the
   harness unchanged.
3. **robots.txt was not seen for 11 of 13 hosts.** The live operator must fetch each one first. The likeliest
   drops are the Screwfix facets, Rozee jsearch and Lulu `?page=`.
4. **Bytes per request are guesses.** If SPA pages run to about 1 MB, grocery reaches the 25 MB per-run limit
   at about 20 requests and may come back INCOMPLETE.
5. **The mortgage marker may over-count up to about 2x** where APRCs have two decimal places. Switch to the row
   selector after the first response.
6. **Per-host figures cover the latest run only.** A host split across runs needs the `jq` line in PROBE_PLAN.
7. **The incumbent counts are search summaries.** The Phase 3 census must replace them.
