# Review: builds/_template/ (Node 22, apify 3.7.2 + crawlee 3.18.2 Actor template)

Reviewer: review-agent:template (opus), 2026-10-03. This was an adversarial review. Source claims were checked against the installed `builds/_template/node_modules` (apify 3.7.2, @crawlee/* 3.18.2, with one deduped `@crawlee/core`). The TS line references were checked against the tagged clones in the scratchpad (`apify-sdk-3.7.2` at v3.7.2, `crawlee-3.18.2` at v3.18.2). Nothing was committed, pushed or published.

## Verdict: PASS WITH FIXES

The template is well built. The tests are real end-to-end runs: a child process, a mock site and an authenticating proxy stub. The SDK claims are accurate to within ±2 lines. Two of the author's headline claims were false at the edges, though:

- **"stops at first charge-limit signal to avoid overcharge-by-one"** was false when the budget was already used up before the first item.
- **"Decodo creds redacted everywhere"** was false for a malformed host or proxy URL. The password reached the log and the run status message.

I fixed both, plus four more bugs. Each fix has a regression test, and each of those tests fails on the original code and passes after the fix.

## 1. Test runs

| Run | Before fixes (author's suite) | After fixes (suite + 6 new tests) |
|---|---|---|
| 1 | 11/11 pass, 5.6 s | 17/17 pass, 8.1 s |
| 2 | 11/11 pass, 5.6 s | 17/17 pass, 8.3 s |
| 3 | 11/11 pass, 5.7 s | 17/17 pass, 8.3 s |
| New tests on the original `src/` | — | 6 fail, 11 pass, as expected |

No `storage/` or `storage-test/` directories remain in the tree. `cleanStorage()` runs on load and in `after`, and both paths are gitignored. `apify validate-schema` (apify-cli 1.10.0) still reports both schemas valid after the `pattern` I added.

## 2. TEMPLATE_NOTES source claims (19 checked)

Paths are relative to `builds/_template/node_modules/`.

| # | Claim | Evidence (installed dist file:line) | Result |
|---|---|---|---|
| 1 | Non-PPE `charge()` returns `chargedCount 0` and warns once | apify/dist/charging.js:244-254 (TS charging.ts:281 ✓) | PASS |
| 2 | Non-PPE `pushData(items, event)` pushes everything and never calls `charge()` | charging.js:383-388 (empty `eventsToCharge`), 439 | PASS |
| 3 | `ACTOR_TEST_PAY_PER_EVENT` makes the run PPE locally | configuration.js:171; charging.js:155-164 (TS configuration.ts:179 ✓) | PASS |
| 4 | Every event costs $1 locally | charging.js:280, 365 (TS charging.ts:428 ✓) | PASS |
| 5 | `ACTOR_USE_CHARGING_LOG_DATASET` writes to the local `charging_log` | configuration.js:172; charging.js:35, 193-199 | PASS |
| 6 | Synthetic `apify-default-dataset-item` is not charged locally | Correct in practice, but the stated reason was incomplete. The real reason is actor.js:1657, where `isDefaultDataset` is false locally because the default dataset id is a UUID, not `"default"` (checked by running it). | PARTIAL, note corrected |
| 7 | The SDK overcharges by one when the budget is short | charging.js:264-269, 396-403 (TS 305/478 ✓) | PASS |
| 7b | "this never triggers" in ResultSink | Reproduced with `ACTOR_MAX_TOTAL_CHARGE_USD=0.5` and `=1`: one item was pushed and charged $1 | **FAIL → fixed (B1)** |
| 8 | `mergeChargeResults` sums `chargedCount` | charging.js:10-13 (TS charging.ts:69 ✓) | PASS |
| 9 | `Actor.pushData(items, 'apify-…')` throws | actor.js:667-669 (TS actor.ts:1065 ✓) | PASS |
| 10 | 401/403/429 retire the session and retry | @crawlee/core/session_pool/consts.js:4; basic/internals/basic-crawler.js:951-955 | PASS |
| 11 | `SessionError extends RetryRequestError` | @crawlee/core/errors.js:70 (TS errors.ts:59 ✓) | PASS |
| 12 | Retries from `detectBlock` are bounded by `maxSessionRotations`, not `maxRequestRetries` | basic-crawler.js:1380 and 1384 (TS basic-crawler.ts:2001 ✓) | PASS |
| 13 | `errorHandler` runs before every retry | basic-crawler.js:1303 (TS 1898 ✓) | PASS |
| 14 | The signature is `useState(name, default, options)` | actor.js:1052, 1068 (TS actor.ts:1521 ✓) | PASS |
| 15 | `createProxyConfiguration({useApifyProxy:false})` returns undefined | actor.js:929-933 (TS actor.ts:1383 ✓) | PASS |
| 16 | On `aborting`, the SDK itself calls `Actor.exit()` | actor.js:259-266. `reboot()` also awaits the `persistState` and `migrating` listeners (actor.js:538-549). | PASS |
| 17 | `ACTOR_MAX_TOTAL_CHARGE_USD` is read, and empty or 0 means unlimited | configuration.js:170; charging.js:109 | PASS |
| 18 | There is one `@crawlee/core` copy | `npm ls @crawlee/core` shows 3.18.2, deduped | PASS |
| 19 | Schemas pass `apify validate-schema` | Re-ran with CLI 1.10.0: input and dataset both valid | PASS |

## 3. Charging correctness

| Check | Finding |
|---|---|
| Pushed without a charge, or charged without a push | Every route path goes through `sink.add`, then `Actor.pushData(batch, 'result')`. The SDK pushes `limitedItems` and then charges the same count (charging.js:429-450). Saved items are counted as the `getChargedEventCount` delta under a serialized chain, and the monitoring commit uses `slice(0, saved)`. I found no charged-without-push path. |
| `Actor.charge` throws (platform API error) | The SDK has **already pushed** the batch, and it bumps the local `chargingState` before the API call (charging.js:283-296). The original sink swallowed the error with `log.exception`, kept crawling and ended SUCCEEDED, so items could be in the dataset unbilled and `RUN_SUMMARY.saved` under-reported. **Fixed (B4):** the sink now stops, drops the rest of the buffer, and `main.js` fails the run after writing `RUN_SUMMARY`. Unconfirmed items are not marked seen. |
| `ACTOR_MAX_TOTAL_CHARGE_USD` respected | Yes when the budget runs out mid-run (the existing test: 3 saved, 3 charged). No when the budget was exhausted before the first push, because the SDK charged one item over. **Fixed (B1)** with a `calculateMaxEventChargeCountWithinLimit()` pre-check (a public API, charging.d.ts:113). Budget 0.5 now gives 0 items and 0 charges. |
| Pay-per-event charging required by the brief | Yes. It uses a custom `result` event per saved item, `apify-actor-start` is left to the platform, and `pay_per_event.json` is clearly marked NOT LIVE with $0 placeholder prices. |
| Monitoring skips are not charged | Yes. Tests run 2 and run 3 cover this. |

## 4. Credential safety

| Path | Result |
|---|---|
| main.js `Proxy: ${label}` | Redacted, for example `http://de***:***@host` ✓ |
| main.js `errorHandler`, `failedRequestHandler`, top-level catch → `Actor.fail` | `scrubSecrets` ✓. **However,** `secrets` was assigned only after `createProxy` returned (B2). |
| `Actor.createProxyConfiguration` validation error | **LEAK, reproduced:** with `DECODO_HOST='gate example:7000'`, the output contained ``got `http://leakuser:LeakPa55!x@gate example:7000` ``, both in the log and in the `[Status message]`. **Fixed (B2):** `collectSecrets()` now runs before `createProxy`, a `configureProxy()` wrapper rethrows with redacted URLs, and `DECODO_HOST` must be `host:port`. |
| Health check OK and failure paths | Uses the label plus `scrubSecrets` ✓. The test with a wrong password stays clean. |
| Persisted storage | After a Decodo run I grepped every KV, request-queue and dataset file, including `SDK_SESSION_POOL_STATE`. No password found ✓ |
| Dockerfile / .dockerignore / .gitignore | `.env` and `.env.*` are excluded in all three. `test`, `storage*` and `node_modules` are excluded from the image ✓ |
| README / BUILD_NOTES deploy steps | The token comes from the environment or from `apify login` (stored in `~/.apify`), never from a repo file. Decodo credentials are set as Console secret env vars ✓ |
| Repo grep for real credentials | None found. Only test fakes appear. |

## 5. Proxy health check

- **Fails fast:** yes. It sends one request through `proxyConfiguration.newUrl()` with a 20 s timeout and 1 got retry, so the worst case is about 40 s. A 407 or bad credentials fail before any crawl request (tested).
- **Skippable:** yes. `skipProxyHealthCheck` covers it, and it is skipped automatically when there is no proxy.
- **Decodo-style URLs:** `http://user:pass@host:port` works, with user and password URL-encoded and tested through the authenticating stub, HTTP only. The CONNECT/https echo URL (the `api.ipify.org` default) is not exercised by the tests.
- **Retries:** 401/403/429 throw a plain Error, which retires the session and counts against `maxRequestRetries`. `detectBlock` throws `SessionError`, which counts against `maxSessionRotations` (also set to `maxRequestRetries`). Backoff doubles with jitter and is capped at 30 s. These settings are sane.

## 6. Monitoring dedupe

- **Stable keys:** state is stored as id → 16-hex sha1 fingerprint, the volatile fields are excluded, and keys are sorted. Entries are committed only after a confirmed charge.
- **Bug B3, fixed:** a user `monitoringKey` containing an invalid character (space or `/`) passed `getValue` (crawlee only checks that it is non-empty) but threw in `setValue` at the end of the run, after charging. The seen-set never persisted, so every scheduled run re-charged everything. Reproduced: run 1 charged 7 items and failed, and run 2 charged 7 again. Now it is validated at input time (`src/input.js` with the `@apify/consts` regex, plus an input-schema `pattern`).
- **Bug B6, fixed:** the default key hashed only `startUrls` and `ids`, so a builder-added `query` or `country` input made different searches share one seen-set and wrongly skip items. The key now covers every input not listed in `NON_KEY_FIELDS`. Keys for template-only inputs are unchanged (tested).
- **Bug B5, fixed:** a record with no `id` became the string `"undefined"`, and every later record was dropped as a duplicate. It now throws loudly.
- **Size:** capped at 200,000 entries with oldest-first eviction. The cap is on entries, not bytes. See residual risks.

## 7. Schemas

`input_schema.json` and `dataset_schema.json` are valid under apify-cli 1.10.0 `validate-schema`. They also match `specification.md`: `datepicker` with `absoluteOrRelative`, and the "N unit" format that `parseSince` handles. `isSecret` is only used on textfields. The `actor.json` fields match the `actor_json.md` table, and `meta.generatedBy` matches the official templates. Note that the placeholder `"name": "TODO-actor-name"` contains uppercase letters. The builder has to replace it before `apify push`.

## 8. Core logic size

There are 689 lines in `src/`. Of those, 86 are in `routes.js`, which is source-specific. The other ~600 lines are infrastructure. For a list-and-detail source, a builder only edits `routes.js`, the two schemas, `README.md` and `BUILD_NOTES.md`. Adding a new input field also means touching `src/input.js`, because defaults are duplicated there and the code requires `startUrls` or `ids`. After the B6 fix the builder does not need to touch `monitor.js`. The claim that builders only edit `routes.js` holds for the logic, but not for new inputs.

## Issues and fixes

| ID | Severity | Issue | Fix | Test |
|---|---|---|---|---|
| B1 | High | Budget exhausted before the first push still pushed and charged 1 item (overcharge-by-one) | Pre-push `calculateMaxEventChargeCountWithinLimit` check (`src/charge.js`) | `budget below one item price: nothing pushed, nothing charged` |
| B2 | High | Proxy password printed by crawlee's URL validation error for a malformed `DECODO_HOST` or custom URL, in the log and the status message | `collectSecrets` runs first, `configureProxy` redacts, `DECODO_HOST` format is validated (`src/proxy.js`, `src/main.js`) | `malformed Decodo host or custom proxy URL never prints the password` |
| B3 | High | Invalid `monitoringKey` failed after charging and never saved state, so every run re-charged everything | Input validation plus schema `pattern` (`src/input.js`, `.actor/input_schema.json`) | `invalid monitoringKey fails before crawling or charging` |
| B4 | Medium | Flush or charge failure was swallowed, so the run ended SUCCEEDED with possibly unbilled items | Sink records `flushError`, stops and drops the rest; `main.js` fails the run (`src/charge.js`, `src/main.js`) | `test/sink.test.js`: failed save test |
| B5 | Medium | Missing `id` silently collapsed all records into `"undefined"` | Throw in `sink.add` (`src/charge.js`) | `test/sink.test.js`: no-id test |
| B6 | Medium | Default monitoring key ignored builder-added inputs | Hash every input not in `NON_KEY_FIELDS` (`src/monitor.js`) | `default monitoring key covers builder-added inputs…` |

I also updated `TEMPLATE_NOTES.md` (claim 4, the claim 3 mechanism, and two new builder gotchas) and the expected test-count line in `BUILD_NOTES.md`.

## Residual risks (not fixed)

1. **Platform charging is unverified.** That covers real `run.charge`, Console event config, and what happens if `charge` fails after a push. Items from a failed batch stay in the dataset, possibly unbilled, and reappear as `new` next run.
2. **Double pricing.** If both `result` and `apify-default-dataset-item` are priced, the B1 pre-check uses only the `result` price while the SDK uses the combined price, so overcharge-by-one is still possible in that misconfiguration. It is warned about in the log and in the notes.
3. **Monitoring state is bounded by count, not bytes.** 200k long ids (for example URLs) could produce a record of ~25 MB. The KV record size limit was not found in the docs clone, so this is UNVERIFIED. In `new` mode, items that are still listed never refresh their age, so after 200k newer ids they are evicted and re-saved and charged as `new`.
4. **Crawlee's own logs are not scrubbed.** That includes "Reclaiming failed request…" and "Error analysis". The 407 path is clean in tests, but other upstream proxy errors are unverified.
5. **Retry and proxy behaviour.** The backoff sleeps inside a concurrency slot, for up to 30 s. With one Decodo URL, "fresh session per retry" only changes the IP if the gateway rotates per connection, and keep-alive may reuse a tunnel. Not verified against the real gateway.
6. **`proxyProvider: 'apify'` locally without a token.** The SDK warns and runs without a proxy, but the label still says "Apify Proxy". On the platform it throws instead.
7. **Top-level failure skips the monitor save.** If `crawler.run()` throws after items were charged, the catch path does not save monitoring state (`persistState` runs every 60 s, which limits the loss). The next run may re-charge those items.
8. **Not run here:** the Docker build, the migration and abort handlers, the https health-check URL through CONNECT, and the real Decodo host and sticky-session syntax.
