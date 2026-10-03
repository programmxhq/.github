# Apify Store census tool

One command builds `research/census.csv`, one row per public Store Actor. The tool only sends GET requests. It never runs an Actor. Field mapping is spec-verified but has not been checked against the live API. See `research/API_SPEC_NOTES.md`.

## Setup (future session with network)

```bash
cd research/tools/census
pip install -r requirements.txt          # requests (+ pytest for tests)
python -m pytest                         # offline, about 5 s, must pass first
```

The tool reads credentials from environment variables. If they are missing, it reads `.env` at the repo root, then `research/.env`. Only `APIFY_TOKEN` is used. The `DECODO_*` keys are detected but the census never uses them. The tool never prints values. Every message goes through a redactor, and the token is sent only in the `Authorization` header, never in a URL.

## Run order (stay well under the $5 cap)

```bash
# 0. Smoke test: 1 page, no token, so no account can be billed
python census.py --no-auth --page-size 50 --max-pages 1 --fresh
#    Check research/census_summary.json and spot-check rows against the Store website.

# 1. Full Store list. About 20-30 requests for roughly 20k Actors at 1000/page.
python census.py --fresh            # or --no-auth if step 0 showed the Store works without a token
#    If interrupted, run:  python census.py --resume

# 2. Enrichment (detail-only fields: created_at, last_modified, deprecated, pricing history,
#    per-tier per-result prices, is_critical). This is 1 request per Actor, about 3 h at 2 req/s for 20k.
#    Run a small batch first:
python census.py --resume --enrich --enrich-limit 50
python census.py --resume --enrich                  # resumes; cached detail files are skipped
#    Cheaper subset:  --enrich-min-users 10

# Rebuild the CSV from raw files without network access
python census.py --build-only
```

If `census_summary.json` contains `store.warnings` about a result-window cap, the server stopped returning items before reaching `total`. In that case, partition the census into slices and merge them:

```bash
for c in AI AUTOMATION DEVELOPER_TOOLS ECOMMERCE LEAD_GENERATION SOCIAL_MEDIA; do   # category list UNVERIFIED
  python census.py --slice "cat_$c" --category "$c" --fresh
done
python census.py --slice newest --sort-by newest --fresh
python census.py --build-only      # merges every slice, deduped by Actor id
```

## Options

| Flag | Default | Meaning |
|---|---|---|
| `--enrich` | off | Calls `GET /v2/actors/{username}~{name}` for each Actor. Falls back to the Actor id on 404. Saves to `research/raw/actors/{id}.json`. |
| `--max-pages N` | none | Stops after N Store pages in this run. Resumable. |
| `--resume` / `--fresh` | | Continue from, or delete, the Store checkpoint (`raw/store/_checkpoint.json`). The tool refuses to run when a checkpoint exists and neither flag is given. |
| `--build-only` | | No network. Rebuilds the CSV and summary from raw files. |
| `--no-auth` | | Sends no token. |
| `--max-requests` | 25000 | Hard cap on HTTP attempts, retries included. When it is hit, the tool stops with exit code 3. |
| `--spend-cap-usd` | 0.50 | Reads `GET /v2/users/me/limits` → `current.monthlyUsageUsd` at start, every `--spend-check-every` (500) requests, and at the end. Stops with exit code 3 if usage grows by more than the cap. Only works with a token. |
| `--rps` / `--concurrency` | 2 / 2 | Global rate limit and number of enrichment threads. |
| `--page-size` | 1000 | Spec maximum is 1000. |
| `--sort-by` | popularity | `relevance`, `popularity`, `newest` or `lastUpdate` |
| `--category`, `--search`, `--username`, `--pricing-model` | | Store filters |
| `--include-unrunnable` / `--exclude-unrunnable` | include | `includeUnrunnableActors`. The API default (false) hides some Actors. |
| `--actor-path-prefix` | `/v2/actors` | `/v2/acts` is the deprecated legacy alias. |
| `--base-url` | `https://api.apify.com` | Also read from the `APIFY_API_BASE_URL` env var. Tests point it at the mock server. |

Defaults live in `config.json`. That file also holds `house_owners`, the owner list behind `is_apify_owned`. The list `apify, compass, clockworks` is unconfirmed. After `--enrich`, check `csv.house_owner_check` and `csv.non_house_owners_with_isCritical` in the summary. `isCritical` means "maintained by Apify".

Exit codes: 0 means OK. 2 means an API error (4xx other than 404/429, or retries exhausted). 3 means a hard stop on the request cap or spend cap. The CSV and summary are written on every exit.

## Outputs

- `research/raw/store/page_0001.json` and following: raw `/v2/store` responses, plus a `_census` block with the request params. This directory is gitignored.
- `research/raw/actors/{id}.json`: raw Actor detail. A 404 is saved as a `_census.status: 404` marker.
- `research/census.csv`: one row per unique Actor, sorted by total_users descending.
- `research/census_summary.json`: request counts by kind and status, spend-guard readings, Store total vs unique items, enrichment stats, house-owner check, and notes on each column.

## Columns

| Column | Source (JSON path) | Needs `--enrich` |
|---|---|---|
| actor_id, owner, name, title, description, categories (`;`-joined), notice, badge | `items[].id/username/name/title/description/categories/notice/badge` | |
| url, url_source | `items[].url`. If null, built as `https://apify.com/{owner}/{name}` (url_source=`derived`; the URL pattern is UNVERIFIED). | |
| is_apify_owned | owner in `config.json` house_owners | |
| is_critical | `data.isCritical` | yes |
| total_users, users_90d, users_30d, users_7d, total_runs | `stats.totalUsers/totalUsers90Days/totalUsers30Days/totalUsers7Days/totalRuns` | |
| runs_per_user | total_runs / total_users. Empty when total_users = 0. | |
| rating, review_count, bookmark_count | `items[].actorReviewRating/actorReviewCount/bookmarkCount`, falling back to `stats.*` | |
| success_rate_30d | `stats.publicActorRunStats30Days.SUCCEEDED / TOTAL`. Empty if absent or TOTAL = 0. Excludes the owner's runs. | |
| runs_30d, runs_30d_succeeded, _failed, _aborted, _timed_out | `publicActorRunStats30Days.TOTAL/SUCCEEDED/FAILED/ABORTED/TIMED-OUT` | |
| last_run_started_at | `stats.lastRunStartedAt` | |
| pricing_model, pricing_source | With enrichment: the latest `data.pricingInfos[]` entry whose `startedAt` is not in the future. Otherwise `items[].currentPricingInfo`. | |
| pricing_events | JSON `{event: {TIER or "FLAT": usd}}` from `pricingPerEvent.actorChargeEvents` | Store copy UNVERIFIED |
| event_count, primary_event, primary_event_price_usd | Event map. The primary event is the one with `isPrimaryEvent`. Its price is the FLAT price, else the FREE tier price, else the highest tier price. | |
| price_flat_or_per_result, price_unit, price_per_result_tiers, trial_minutes | `pricePerUnitUsd`, `unitName`, `tieredPricing.{TIER}.tieredPricePerUnitUsd`, `trialMinutes`. FREE is 0. FLAT_PRICE_PER_MONTH is USD per month. | Tiers: yes |
| apify_margin, pricing_started_at | `apifyMarginPercentage`, `startedAt` | |
| pending_price_change, pricing_history_count | A future-dated `pricingInfos` entry exists; `len(pricingInfos)` | yes |
| last_modified, created_at, deprecated, actor_permission_level | `data.modifiedAt/createdAt/isDeprecated/actorPermissionLevel` | yes |
| is_white_listed_for_agentic_payments | `items[].isWhiteListedForAgenticPayments` | |
| issues_response_time | **Always empty.** Not in the API. Only on the Store web page. | n/a |
| enriched | Whether a detail record was merged | |

## Tests

`python -m pytest` (or `python tests/test_census.py`) starts `tests/mock_apify.py`, a local `http.server` that serves `/v2/store`, `/v2/actors/{id}` and `/v2/users/me/limits` with fixtures copied from the spec examples. It then runs the full pipeline offline. The tests cover:

- the CSV contents
- 429 retry
- resume without refetching
- the request-cap hard stop
- the spend-cap hard stop
- the result-window-cap warning
- slice merging
- `--build-only`
- token redaction, including that the token appears in no URL, output or file
- fixture keys being a subset of the spec's properties
