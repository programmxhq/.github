# Review: top-5 deep pass

Reviewer: review-agent:top5 (opus), 2026-10-03 (UTC). Scope: `research/desk/TOP5_DEEP_PASS.md` (synthesis) against `research/desk/top5/{uk-mortgage-rates,gcc-grocery,uk-retail-currys-screwfix,tenders-pk-sa,jobs-gcc-pk}.md`, with `DECISIONS.md` #7 rates (Decodo $4/GB PAYG, $2.75/GB at 100 GB; developer gets 80% of revenue minus compute; $0.20/CU; payout minimum $100 bank / $20 PayPal). Repo files only: no web, no new searches, nothing committed. Every figure in the reviewed files is UNVERIFIED search-summary evidence; this review checks traceability and arithmetic, not truth.

## Verdict: PASS WITH FIXES

The synthesis is faithful to its sources: nearly every number traces exactly, and the overall conclusion (nothing build-worthy; run three cheap probes as calibration; switch to census-first selection) follows from the evidence. One real arithmetic error turned up (jobs polling cost vs the `run-start` fee). It strengthens the jobs KILL rather than changing any verdict. There are also several overstatements and copied inconsistencies. All are annotated `REVIEW:` in place.

## 1. Mismatch table (synthesis vs sources)

Everything not listed here was checked and matches: the comparison table, the section-3 site tables, the section-4 revenue lenses, the section-6 probe sizes (3.38 + 6.75 + 13.13 = 23.3 MB; all five = 40.1 MB), the FX-converted buyer prices, and the niche ceilings (sum of four thin niches: about $187-1,750).

| # | Synthesis says | Source says | Severity | Fix |
|---|---|---|---|---|
| 1 | §1: "net $0.35-6.28 per 1k rows in every case" | Grocery browser path nets $0.24 (gcc-grocery §E); the synthesis's own table shows $0.24 | Low | REVIEW in §1 |
| 2 | §1: "Margin was never the problem" | Jobs `run-start` $0.005 doesn't cover polling: hourly polling loses about $10/user/month (see §2 below) | Medium | REVIEW in §1, §2 table, jobs §E |
| 3 | §4 jobs: "base = matching the #2 Bayt actor's 32 MAU" | The base scenario is **10 users**. The source text says "about level with … 32", which contradicts its own table. Copied inconsistency | Medium | REVIEW in synthesis §4 and jobs §E |
| 4 | §4 grocery: "optimistic ≈ the whole current niche" | True for MAU (15 vs ~16). By revenue, optimistic gross $1,463 is 2.4-10x the file's $150-600 niche gross, and base gross $234 is 39-156% of it | Medium | REVIEW in synthesis §4, §2 and grocery §E |
| 5 | Header + §5: "All five agents ran out of search budget mid-pass" | Jobs file never mentions the cap. `logs/top5-agents.md`: jobs did 22 searches and finished without reporting it. Its "not searched" cells (Indeed, Revelio) are scope choices | Low-Medium | REVIEW under header and in §5 |
| 6 | §5: "missed the monitor shape in 4 of 5" | Mortgage has no monitor to miss. CANDIDATES row 7 already listed sian.agency's Currys price-drop/target-price tracking. The probe-defs review already noted memo23's daily scheduled runs. Clean misses: grocery, tenders, plus sync-network on Currys | Low | REVIEW in §5 |
| 7 | §5 / §7: counts rose "2-6x in 4 of 5" | Holds only against the original desk counts. Against the probe-defs re-count for jobs (11 / 9 / 4 → 23 / 14 / 6) it is 1.5-2.1x. Grocery publishers went 5 → 7 (1.4x; actors 9) | Low | REVIEW in §5; CANDIDATES uncertainty #1 annotated as "1.4-6x" |
| 8 | §2 tenders: "8 (Etimad 6; PK 2)" | 6 counts Etimad *actors*; 2 counts PK *publishers* (blessed_jouster has 3 Epad actors). GulfPulse (GCC, "partly" monitor) is omitted | Low | REVIEW after §2 table |
| 9 | §7: PageSize "typically 100" vs "the def's 50" | The def sends `PageSize=24`. 50 is PROBE_PLAN's UNVERIFIED maximum | Low | REVIEW in §7 |
| 10 | §5: "ProgrammX's own four actors show 5 MAU" | Not in the five deep passes. Traces to `PROGRAMMX_LIVE.md` (single snippet, UNVERIFIED) | Info | REVIEW in §5 |

No invented figures were found. Every price, user count, date and URL-derived claim in the synthesis appears in a source file, in PROBE_PLAN.md, or in PROGRAMMX_LIVE.md.

## 2. Arithmetic table

Method: Decodo per 1k = KB/row × 1000 / 1e6 GB × $/GB. Net per 1k = 0.8 × price − Decodo − compute. Monthly net = users × rows × net/1k. Every file applies the 80% to revenue first and subtracts costs afterwards (not 80% of net), and every file charges Decodo to the developer. Both are correct for a developer-run proxy under pay-per-event. Small differences come from the files using binary MB (12 KB/row → 0.0117 GB) where the brief's decimal formula gives 0.012 GB. That changes nothing by more than $0.001/1k.

| Candidate | Stated net/1k | Recomputed net/1k (PAYG) | Stated base monthly | Recomputed base monthly | Scenarios cons / base / opt (recomputed) | Months to $100 | Status |
|---|---|---|---|---|---|---|---|
| UK mortgage ($3/1k, 12 KB/row, 0.07 CU) | $2.34 | $2.338 | $70 | $70.14 | $11.69 / $70.14 / $935 | ~9 / ~2 / <1: OK | OK. Caveat: 0.07 CU/1k equals the HTTP rate, not the "Playwright worst case" it is labelled as; a browser at 5-10x would make net $2.20-2.27 |
| GCC grocery ($0.50 check + $3 change, 12 KB/row HTTP; 33 KB browser) | $0.35 / $0.24 | $0.350 / $0.236 | $170 | $169.2-169.6 | $28.2 / $169 / $1,058 (browser $21.4 / $128 / $801) | ~4 / ~1 / <1: OK | Minor: worked example's Decodo $17.6 should be $16.9 ($17.3 decimal). Base and optimistic exceed the file's own niche gross |
| UK retail ($1.50/1k, 15 KB/row, 0.02 CU) | $1.136 | $1.136 (BFF $1.186; browser $0.65) | $102 | $102.2 | $17.0 / $102.2 / $909 | ~6 / 2-3 / 1-2: OK | OK, no fix |
| Tenders ($8/1k new, 15 KB/row, $0.08-0.25 compute per user-month) | $6.10-6.28 | $6.09-6.28 (details $5.80-6.09) | $36 | $35.70 | $4.46 / $35.70 / $305.00 | ~24 / ~5 / 1-2: linear ramp gives 24 / **4** / 1; PayPal $20 in month 6 matches | OK. Ramp shape unstated. Conservative users at 400 rows net an effective $5.58/1k because compute is per user |
| Jobs ($1.50/1k, 8 KB/row listing; 60 KB with detail; 0.05 CU) | $1.16 / $0.95-1.02 | $1.158 / $0.950 (plan $1.168 / $1.025) | $80 | **$76 daily polling; −$21 hourly polling** | stated $9 / $80 / $600; with daily polling $7.7 / $75.8 / $587; with hourly polling −$21.2 / −$20.8 / +$298 | stated 12+ / 4-5 / 2-3; hourly polling never reaches $100 in cons/base | **Error.** One poll = 4.5 MB = $0.018 at $4/GB, but `run-start` nets $0.004. The file says the fee exists to cover polling; it covers about 22%. Break-even fee is about $0.0225 |

Other spot checks that passed: mortgage diff-mode ($2.16 Decodo + $0.60 compute; `lender-checked` $3.84 net). Grocery compute (0.0083 CU HTTP, 0.167 CU browser). Tenders FX table (all 15 conversions within $0.1). Tenders KPPRA rate (1,145 IDs / 107 days ≈ 321/month). Etimad 85,900/yr ≈ 7,158/month. Jobs polling $12.96 hourly / $0.54 daily. Jobs niche-leader sum $590-5,900.

## 3. Verdict consistency and "not searched" vs "not found"

| Candidate | Verdict | Follows from evidence? | Search-gap labelling |
|---|---|---|---|
| UK mortgage | TEST (KILL as Store product) | Yes: niche about $0-30/month. HSBC's personal-use clause is a gate by the standard desk_review used for Oddschecker (annotated) | Header says some "not found" cells are budget gaps but does not mark which. The log confirms per-lender anti-bot checks were budget-cut, which supports the synthesis's "not searched" |
| GCC grocery | TEST leaning KILL | Only as an information probe. By the retail file's own gate standard, Carrefour's robots ban and Lulu's personal non-commercial clause are gates (annotated). Base scenario already exceeds the estimated niche | Good: "not found (not searched)" used for Spinneys, Union Coop, Noon Minutes, Kibsons |
| UK retail | KILL | Yes: 12 actors, monitor taken, Screwfix ToS gate, Currys geo-lock | Ambiguous: "some user counts not retrieved and marked 'not found'" without per-cell marks |
| Tenders | TEST, PK-first | Yes, given the explicit kill threshold. But "lowest legal risk" rests on the nature of the data, not on a read: Etimad terms and all robots.txt were **not searched** (annotated) | Best of the five: "not found (budget)" convention plus a closing not-found list |
| Jobs | KILL | Yes, and the polling error strengthens it | No cap statement. "not searched" for Indeed/Revelio is scope, not budget; the synthesis conflated them (annotated) |

## 4. Labelling and source URLs

- **UNVERIFIED labels:** all five files and the synthesis carry a blanket UNVERIFIED statement at the top. Section-level labels repeat it in competitor tables. No unlabelled figure was found.
- **Mortgage:** has a full source list covering every incumbent, the HSBC site-terms quote, and the broker prices (trustpms) and PropertyData prices. URLs are listed, not mapped to claims.
- **Grocery:** inline links for the key claims: the blackfalcondata monitor and users, the Lulu robots.txt and T&C, the Carrefour T&C, MOET, 42signals and Bright Data. Gaps:
  - 123webdata, boring_internet_explorer/carrefour and solidcode MAU come from one "MAU summary" URL (`solidcode/carrefour-scraper/api`), which is weak provenance for five actors.
  - 123webdata has no URL of its own.
- **Retail:** 35 numbered sources. Every count, ToS quote and price is footnoted. The strongest file.
- **Tenders:** 29 S-refs covering counts, prices and FX. The S3 anti-bot quotes are not pinned to a specific actor; the file says so itself.
- **Jobs:** the weakest provenance.
  - Of the ~50 incumbent user counts, only about 8 actors have a URL (blackfalcondata Bayt/NG, jungle_synthesizer, memo23 ×3, get_anything, valig).
  - shahidirfan Bayt (310/74), epicscrapers (224/62), easyapi, abotapi, agentx and the Rozee counts have no link.
  - There is no sources section.
  - Buyer prices are linked.

## 5. Stale-row annotations applied (synthesis §7)

Each annotation is a single `REVIEW 2026-10-03 (top-5 deep pass): ...` line, appended to the table cell for table rows or added as a line for sections. Nothing was rewritten.

- `research/desk/CANDIDATES.md`: rows 3, 7 (OUT), 8, 11 (OUT), 26; shortlist blocks S3, S7, S8; "Biggest uncertainties" #1 and #4.
- `research/reviews/desk_review.md` §4: ranks 2, 3, 4, 5; residual risk 6.
- `research/probes/PROBE_PLAN.md`: summary table / run order (~23 MB), §1 Halifax, §2 Lulu robots + Carrefour ToS + MAF-API claim (supersedes the earlier "gcc robots unseen" REVIEW), §3 KILL, §4 baseline/PageSize, §5 KILL.
- `research/NEXT_SESSION.md`: Phase 4, 5 and 7 rows; a new bullet under §4 weak spots.

## 6. Fixes applied (all annotated `REVIEW (review-agent:top5, 2026-10-03)`)

- `top5/jobs-gcc-pk.md`: polling-cost error with recomputed scenarios and the break-even `run-start` fee; base-vs-32-MAU inconsistency.
- `top5/gcc-grocery.md`: the $17.6 Decodo figure; scenarios vs niche size; ToS gate consistency.
- `top5/uk-mortgage-rates.md`: arithmetic confirmed; binary/decimal GB note; compute label; HSBC gate.
- `top5/tenders-pk-sa.md`: arithmetic confirmed; ramp note; effective net/1k for low-volume users; "lowest legal risk" rests on unsearched ToS/robots.
- `TOP5_DEEP_PASS.md`: 7 REVIEW lines covering mismatches 1-10.
- `top5/uk-retail-currys-screwfix.md`: no changes (arithmetic and sourcing are clean).

## 7. Residual risks

1. **Everything is still single-snippet search evidence.** User counts have no page date, and the five agents shared one exhausted budget. The live census replaces all of it.
2. **Scenario rows per user aren't anchored to evidence.** Competitor revenue estimates assume 1.5k-20k rows/MAU, while our scenarios assume up to 150k (grocery) and 40k (mortgage). Base cases are therefore optimistic relative to the niches they sit in.
3. **The ToS gate is applied unevenly.** Retail is KILLed on Screwfix's crawl clause; grocery and mortgage stay TEST despite comparable clauses. Until a `T` column exists, this depends on which agent wrote the file.
4. **Polling cost is missing from every monitor model except mortgage.** Grocery and tenders price per row and assume scheduled checks are covered by `product-checked` or by per-user compute. Recheck that for any future monitor candidate: polls that return no new rows still cost bandwidth.
5. **Compute figures are guesses** (0.02-0.16 CU/1k) that no measurement backs. At the $0.20/CU Starter rate none changes a verdict, but browser paths could be 5-10x higher.
6. **Recommended census filters are untested.** Every column the §5 filters name exists in `tools/census/census.py`, but none has been filled from a live run. `last_modified` and `is_critical` need `--enrich`, and the thresholds (0.90 success rate, 120 days, ≥ 50 users) are judgement calls with no calibration behind them.
