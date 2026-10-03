# Runbook for the live session

This session (2026-10-03) could not reach Apify or Decodo, so it built and reviewed the tooling offline. This file is the checklist for the next session, which runs the full 7-phase brief with network access.

## 0. Before starting the session (user, about 2 minutes)

1. Cloud environment settings → Network access: **Full**. Alternatively, choose Custom and allow `api.apify.com`, `apify.com`, `docs.apify.com`, the Decodo gateway host, and every target site the probes hit. With Full, probes only need the Decodo host.
2. Same screen → environment variables: `APIFY_TOKEN`, `DECODO_USER`, `DECODO_PASS`, `DECODO_HOST`. The tools read these directly, so no `.env` file is needed.
3. Start a **new** session on branch `claude/apify-store-research-pkfr2p` (environment changes don't reach running sessions) and paste the original brief, adding: "Start from research/NEXT_SESSION.md."

## 1. Smoke checks (about 5 minutes; stop if any fail)

```bash
cd research/tools/census && pip install -r requirements.txt && python -m pytest -q   # 16 tests
python census.py --no-auth --page-size 50 --max-pages 1 --fresh                      # free, 1 request
cd ../ && pip install -r probe/requirements.txt && python -m pytest probe/tests -q     # 71 tests
python -m probe health                     # exit IP via Decodo. If CONNECT is refused: python -m probe --upstream env health
python -m probe health --sticky --count 3
cd ../../builds/_template && npm ci && npm test                                       # 17 tests
```

Answer the UNVERIFIED items on the first live calls, then update `API_SPEC_NOTES.md` and `probe/config.yaml`:
- Is the Store list paged in 1,000-item pages, or capped at 1,000 results in total? (`store.warnings` in `census_summary.json`)
- What are the real tier names, and what shape does pay-per-event pricing have in the Store list? Are rating and success rate in the Store list or only on detail?
- What are Decodo's live $/GB for your plan (config default: $4.00/GB pay-as-you-go, UNVERIFIED)? Check the `ip.decodo.com` response format.
- Which owners are Apify-owned? (`compass`, `clockworks`, `streamers` are disputed; check `isCritical` / "maintained by Apify" on detail pages.)
- Is ProgrammX's live actor list the 4 actors desk research found (only 3 re-confirmed)? Run `python census.py --build-only` and filter `owner == programmx`.

## 2. Phase map: what exists and what's left

| Phase | Ready now | Left for the live session |
|---|---|---|
| 1 Census | `tools/census/` (reviewed, fail-closed $ guard, request cap) | Run steps 1–2 of the census README. Enrich actors with `--enrich-min-users 10` first. |
| 2 Top 20 | `teardowns/partial/` (6 from code, 27 stubs + field checklist) | Rank by `users_30d`. Fill stubs from actor pages, issues tabs and READMEs, one subagent per actor. |
| 3 Patterns | `desk/PATTERN_HYPOTHESES.md` (14 hypotheses, each with census columns and kill thresholds) | Test the hypotheses against `census.csv` (H10, H2, H8 first) and verify all prices live. |
| 4 Candidates | `desk/CANDIDATES.md` (43 scored) + `reviews/desk_review.md` (adjusted top 5, legal gate) | Re-score with census counts of competitors per niche. Add the legal/ToS gate (`T`) column. REVIEW 2026-10-03 (top-5 deep pass): replace "re-score with census counts" with the census-first peer-set selection in desk/TOP5_DEEP_PASS.md §5 (demand floor, unhealthy incumbent, shape gap, price floor), including the `T` gate column. |
| 5 Probes | `tools/probe/` (reviewed, 500 MB hard cap) + `probes/PROBE_PLAN.md` + definitions for the top 5 | `validate` → `plan` → `run --baseline`, then fix selectors after the first response. REVIEW 2026-10-03 (top-5 deep pass): "definitions for the top 5" becomes 3 probes (tenders, mortgage, grocery; ~23 MB) plus an optional Currys geo control. |
| 6 Report | — | Write `FINAL_REPORT.md` from the census, teardowns and probe numbers (Fable). |
| 7 Build | `builds/_template/` (reviewed: pay-per-event, Decodo + health check, retries, monitoring, 17 tests) | Copy it to `builds/<name>` for 2–3 easy survivors (edit `src/routes.js`), then a tester agent runs 3 clean live runs. REVIEW 2026-10-03 (top-5 deep pass): "2-3 easy survivors" is optimistic; expect 0-1 from this shortlist, with candidates coming from the census pass instead. |

## 3. Budget guardrails already in code

- **Apify:** the census only sends GET requests. It stops when account usage rises by $0.50 (configurable, kept under the $5 total) and refuses to run if it can't read usage. Request cap: 25,000.
- **Decodo:** `research/probes/traffic_ledger.json` counts on-the-wire bytes across all runs. There is a hard 500 MB cap in code, a run is refused when its projected bytes exceed the remaining budget, and only one run can use the proxy at a time. Don't delete the ledger: deleting it resets the budget. Compare its total against the Decodo dashboard after the first run.
- **Actors:** charging stops at the first limit signal, so an item is never charged after the budget is used up. Decodo credentials must be set as **Secret** env vars in Console.

## 4. Known weak spots to fix first

- Most UNVERIFIED figures in `teardowns/partial/` and the "Official API status" column in `desk/CANDIDATES.md` lack source URLs. The live census supersedes the user counts.
- Desk research under-counted incumbent actors that already monitor new listings in classifieds and e-commerce niches. Re-count from `census.csv` before trusting any "thin niche" claim.
- The probe client sends plain Python HTTP/1.1 traffic, not a browser fingerprint, so it may under-report reachability on strict Akamai, Kasada or DataDome sites. Record that as a limitation rather than retrying with a browser.
- REVIEW 2026-10-03 (top-5 deep pass): ToS/robots gates (Screwfix, Carrefour, Lulu, HSBC) and geo-locks (Currys, Etimad) were found in the deep pass; check both before any probe.
