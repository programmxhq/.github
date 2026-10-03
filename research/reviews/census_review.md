# Review: census tool and API spec notes

- **Reviewer:** review-agent:census (opus)
- **Date:** 2026-10-03
- **Scope:** `research/API_SPEC_NOTES.md` and `research/tools/census/` (census.py, config.json, tests, README)
- **Spec source:** my own shallow clone of github.com/apify/apify-docs, HEAD `7b30f19` (2026-10-02). This is the same commit the author used. Nothing was called live, because api.apify.com is blocked.

## Verdict: PASS WITH FIXES

The field mapping matches the OpenAPI spec. I spot-checked 24 items: 22 pass and 2 had wrong line numbers, now fixed. The pagination, resume, retry, request cap, spend guard and redaction logic all work. Four real bugs were found and fixed, each with a regression test that fails on the original code and passes now. Tests went from 9 to 13, and all pass under both `python -m pytest` and `python tests/test_census.py`. The CSV covers every column in the brief. "Last update" needs `--enrich`.

## 1. Spec spot-check

Paths are relative to `apify-api/openapi/` unless they start with `sources/`.

| # | Claim in API_SPEC_NOTES.md | Checked at | Result |
|---|---|---|---|
| 1 | `/v2/store` "will not return more than 1,000 records" | `paths/store/store.yaml`:12-13 | PASS |
| 2 | `limit`: default and max 1000 | `components/parameters/paginationParameters.yaml`:13-23 | PASS |
| 3 | `sortBy` values; stray-quote example `"'popularity'"` | `store.yaml`:28-37 | PASS |
| 4 | `includeUnrunnableActors` defaults to false and hides non-KYC Actors | `store.yaml`:95-107 | PASS |
| 5 | `responseFormat` is `full` or `agent`; `agent` drops fields | `store.yaml`:78-94 | PASS |
| 6 | `data.total/offset/limit/desc/count` at lines 11/16/21/26/30 | `components/schemas/common/PaginationResponse.yaml` | PASS |
| 7 | `data` → `ListOfStoreActors`, `items[]` at 8-11 | `store/ListOfActorsInStoreResponse.yaml`:6-7, `store/ListOfStoreActors.yaml`:8-11 | PASS |
| 8 | StoreListActor requires id, title, name, username and stats | `store/StoreListActor.yaml`:2-7 | PASS |
| 9 | `actorReviewCount` 55-57, `actorReviewRating` 58-60, `bookmarkCount` 61-63, `url` 44-47 (nullable) | `StoreListActor.yaml` | PASS |
| 10 | `stats.totalRuns` 9, `totalUsers` 13 ("including its owner"), `totalUsers30Days` 21 | `actors/ActorStats.yaml` | PASS |
| 11 | `publicActorRunStats30Days` 52-56 excludes the owner's runs; `TIMED-OUT` 70, `TOTAL` 74 | `ActorStats.yaml` | PASS |
| 12 | `currentPricingInfo.pricingModel` 6 (required); `pricingPerEvent` 55-58 is untyped; no `tieredPricing` | `store/CurrentPricingInfo.yaml` | PASS |
| 13 | Actor `createdAt` 45, `modifiedAt` 50, `pricingInfos` 63, `isDeprecated` 73, `isCritical` 124 | `actors/Actor.yaml` | PASS |
| 14 | `notice` enum NONE / RESIDENTIAL_PROXY_REQUIRED / UNDER_MAINTENANCE / null | `actors/ActorNotice.yaml`:5-9 | PASS |
| 15 | PRICE_PER_DATASET_ITEM: `unitName` 12, `pricePerUnitUsd` 15, `tieredPricing` 20; the two price fields are mutually exclusive | `actor-pricing-info/PricePerDatasetItemActorPricingInfo.yaml` | PASS |
| 16 | PAY_PER_EVENT: `pricingPerEvent.actorChargeEvents` 12-18, `minimalMaxTotalChargeUsd` 19 | `PayPerEventActorPricingInfo.yaml` | PASS |
| 17 | ActorChargeEvent: `eventPriceUsd` 16 and `eventTieredPricingUsd` 20 are mutually exclusive; `isPrimaryEvent` 22 | `ActorChargeEvent.yaml`:4,16-24 | PASS |
| 18 | `tieredEventPriceUsd` 7; example tier keys are FREE through DIAMOND | `TieredPricingPerEventEntry.yaml`:7, `TieredPricingPerEvent.yaml`:3-4 | PASS |
| 19 | FLAT_PRICE_PER_MONTH: `trialMinutes` 13, `pricePerUnitUsd` 16 | `FlatPricePerMonthActorPricingInfo.yaml` | PASS |
| 20 | `actorId` is an ID or `username~name` | `components/parameters/runAndBuildParameters.yaml`:1-9 | PASS |
| 21 | `/v2/acts/` is deprecated (O:134-140); paths at O:533, 775, 785; security at O:799-801 | `openapi.yaml` | PASS |
| 22 | Rate limits: 250k/min global, 60 req/s per resource, backoff from DELAY=500 | `openapi.yaml`:425, 432, 499-503 | PASS. The spec also randomises the wait between DELAY and 2×DELAY; the tool does not. Minor. |
| 23 | Build default `security: []` at line 14; `actorDefinition` at 97; `inputSchema` and `readme` deprecated at 56-62 | `paths/actors/acts@{actorId}@builds@default.yaml`:14, `actor-builds/Build.yaml` | PASS |
| 24 | `monthlyUsageUsd`: "AccountLimits.yaml:19, Current.yaml:14" | `users/AccountLimits.yaml`:12 (`current`), `users/Current.yaml`:15 | **FAIL (line numbers only).** The JSON path `data.current.monthlyUsageUsd` is correct. Fixed in the notes. |

The platform docs citations also check out: BRONZE/SILVER/GOLD at `store/index.md`:110, the weighted rating at `actor-rating.mdx`:12-15, and Console > Insights at `quality_score.mdx`:23.

## 2. census.py findings

| Area | Finding |
|---|---|
| Pagination termination | Paging ends when a page has 0 items or when `next_offset >= total`. Dedupe by id works across pages and slices. **Bug 1 (fixed):** paging had no progress check. If the server ignored or clamped `offset`, or `total` was missing, the loop re-fetched the same page until `--max-requests` (default 25,000). That is about 3.5 h at 2 rps and up to ~25k page files on disk. Paging now stops with a warning when a page has no new Actor ids. |
| Resume / checkpoint | Correct. The page file is written before the checkpoint and both writes are atomic. A crash between them re-fetches the same `page_NNNN` on resume and overwrites it. The tool refuses to resume when the query or page size changed. Enrichment resumes by skipping cached detail files. |
| Retry / backoff | Retries 429, 500, 502, 503, 504 and connection errors up to 6 times, waiting 0.5 s doubling to a 60 s cap. It honours numeric `Retry-After`. Every attempt counts against the budget. There is no jitter. |
| Request cap | `acquire()` runs before every attempt. I confirmed the run stops with exit code 3 during Store paging (existing test) and during enrichment (ad hoc check: exactly 5 requests at `--max-requests 5`). |
| Spend guard | Stops with exit code 3. I confirmed it in both the Store and enrichment phases. **It fails open:** if `/v2/users/me/limits` cannot be read at start (token lacks permission) or later, the run continues without a cap. It also only checks every 500 requests. README now tells the user to check `spend_guard.available` first. |
| Credentials | The token appears only in the session `Authorization` header. Every `log()` and `ApiError` message goes through `Redactor`, which strips secret values, `token=`, `Bearer …` and `apify_api_…`. Summary `args` contains no secrets. No `logging` or `traceback` output. Test asserts the token is in no URL, no output and no file. **Bug 2 (fixed):** `.env` fallback stopped at the first file it found. If a repo-root `.env` existed without `APIFY_TOKEN`, `research/.env` was never read, which contradicts the README. Both files are now read; the earlier file wins per key. |
| CSV vs brief | Every brief column is present: owner, total users, 30-day users (`users_30d`), total runs, runs per user, rating, success rate (`success_rate_30d`), pricing model, every priced event (`pricing_events` JSON, all events and all tiers), and last update (`last_modified`). `last_modified` is detail-only, so it is empty without `--enrich`. |
| Division by zero | `runs_per_user` is computed only when `total_users > 0`. `success_rate_30d` is computed only when `TOTAL > 0`. Both are tested. |
| Missing fields | **Bug 3 (fixed):** the rating, review-count and bookmark fallback used `dict.get(k, default)`, so a top-level `null` blocked the documented fallback to `stats.*` and the column came out empty. A real `0` is still kept. **Bug 4 (fixed):** a `pricingInfos[].startedAt` without a timezone offset raised `TypeError` (naive vs aware datetime). That would crash `write_csv` and lose the whole CSV build. Such timestamps are now treated as UTC. |

## 3. Fixes applied

All fixes are minimal and uncommitted.

1. `census.py` `fetch_store`: stall guard. `seen_ids` holds the ids seen this run; a page with no new id sets `complete` and adds a warning.
2. `census.py` `load_credentials`: merges the repo-root `.env` and `research/.env`, with the root file winning per key.
3. `census.py` `build_row`: `top_or_stats()` falls back to `stats.*` when the top-level value is `None`.
4. `census.py` `pick_current_pricing`: treats naive timestamps as UTC.
5. `tests/mock_apify.py`: new `ignore_offset` knob. `tests/test_census.py`: four new regression tests. All four fail on the original code and pass now. I did not use pytest fixtures, so the plain runner still works.
6. `API_SPEC_NOTES.md`: corrected the line numbers for the limits path.
7. README: added the spend-guard availability check to the run order, and listed the new tests.

## 4. README first-run sequence

The sequence is correct and safe:

1. pytest
2. a smoke test with `--no-auth`, 1 page of 50 Actors (1 request, cannot bill anything)
3. `--fresh` for the full Store list (about 20-30 requests)
4. `--resume --enrich --enrich-limit 50`
5. the full enrichment run

`--fresh` is needed after the smoke test because the page size changed, and the README includes it. The one gap was that it never said to confirm that the spend guard is active before the long enrichment run. That note is now added.

## 5. Residual risks

- **Nothing is live-verified.** Open questions:
  - the 1,000-record window
  - whether `/v2/store` works without a token
  - whether the Store list fills `publicActorRunStats30Days` and `pricingPerEvent`
  - whether `pricePerUnitUsd` is per item or per 1,000 items
  - whether `success_rate_30d` equals the Store page figure
- **`sortBy=popularity` can shift during a multi-page run.** Items can then be skipped between pages. Dedupe hides duplicates but not gaps. Compare `store.items_unique` with `reported_total`, or use `--sort-by newest` as a cross-check slice.
- **The spend guard fails open** (see above). It also cannot see a billing-cycle reset during a run, where the delta goes negative.
- **The base URL is not checked.** `--base-url` / `APIFY_API_BASE_URL` will send the bearer token to any host, including plain `http`. Only point it at api.apify.com or localhost.
- **`last_modified` is `Actor.modifiedAt`.** It may track metadata edits rather than builds, and it is empty without `--enrich`.
- **Tier fallback for `primary_event_price_usd`.** When there is no FLAT price or FREE tier, it uses the highest tier price. This is documented but is a judgement call.
- **No retry jitter.** With concurrency 2 this is fine. Raise it only with care.
- **`house_owners` beyond `apify` is a guess.** Check `house_owner_check` after enrichment.

## Orchestrator follow-up (residual risks closed)
- Spend guard now fails closed (start + 3 consecutive failed reads). Tests: `test_spend_guard_unavailable_at_start_refuses_authenticated_run`, `test_spend_guard_fails_closed_when_usage_reads_stop`.
- Token only sent to trusted hosts. Test: `test_token_not_sent_to_untrusted_base_url`.
- Suite: 16/16 pass.
