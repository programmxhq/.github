# TEMPLATE NOTES: provenance and gotchas

These notes say where each config field and behavior in this template comes from. Paths are relative
to the scratchpad clones made on 2026-10-03:

- `apify-docs/` is github.com/apify/apify-docs (master, 2026-10).
- `sdk/` is github.com/apify/apify-sdk-js at **tag v3.7.2**. That is the version npm `apify@latest` installs. The SDK's master branch is already on the crawlee-v4 line and differs.
- `crawlee/` is github.com/apify/crawlee at **tag v3.18.2**. That is the version npm `@crawlee/cheerio@latest` installs. crawlee's master branch is v4.
- `templates/` is github.com/apify/actor-templates (master), `templates/js-crawlee-cheerio`.

The installed `node_modules/apify/dist/*.js` was checked against `sdk/src/*.ts` and matches. One example is the local $1 price line in `charging.js`.

## File-by-file provenance

| File / field | Source |
|---|---|
| `.actor/actor.json`: `actorSpecification: 1`, `name`, `version` "X.Y", `buildTag`, `input`, `storages.dataset`, `dockerfile`, `min/max/defaultMemoryMbytes`, `meta.templateId` | `apify-docs/sources/platform/actors/development/actor_definition/actor_json.md` (reference table). `"$schema"` and `"dockerfile": "../Dockerfile"` follow `templates/js-crawlee-cheerio/.actor/actor.json`. |
| `maxMemoryMbytes: 1024` | `apify-docs/.../monetizing/pay_per_event.mdx` § "Set memory limits": cap memory so PPE runs stay profitable. `apify-actor-start` is charged once per GB. |
| `.actor/input_schema.json`: `schemaVersion`, `sectionCaption`, `editor` values (`requestListSources`, `stringList`, `select`+`enum`+`enumTitles`, `datepicker`+`dateType`, `proxy`), `unit`, `minimum`/`maximum` | `apify-docs/.../actor_definition/input_schema/specification.md` |
| `isSecret: true` on `decodoUsername`/`decodoPassword` (textfield only) | `apify-docs/.../input_schema/secret_input.md`. `Actor.getInput()` decrypts the values (SDK ≥ 3.1.0). |
| proxy editor object shape `{useApifyProxy, apifyProxyGroups, proxyUrls}` | `specification.md` § proxy. `{useApifyProxy:false}` returns undefined, per `sdk/src/actor.ts:1383` |
| `.actor/dataset_schema.json`: `actorSpecification`, `fields` (JSON Schema), `views.overview.transformation.fields`, `display.component: table`, `format` values | `apify-docs/sources/platform/storage/dataset/dataset_schema.md` |
| `.actor/pay_per_event.json` | **Documentation only.** It is a convention from official templates (`templates/ts-mcp-empty/.actor/pay_per_event.json` + README: "establish the PPE pricing schema in the Actor's Monetization settings ... An example schema can be found in pay_per_event.json"). It is not in the actor.json spec. apify-cli 1.10.0 has no reference to it (grepped the npm tarball). Prices are placeholders (0) and are NOT LIVE. |
| `Dockerfile` | `templates/js-crawlee-cheerio/Dockerfile` pattern, with `apify/actor-node:22` per the brief. Base images are listed in `apify-docs/.../actor_definition/docker.md`. |
| Synthetic events `apify-actor-start`, `apify-default-dataset-item` | `apify-docs/.../monetizing/pay_per_event.mdx` § Synthetic events |
| `ACTOR_MAX_TOTAL_CHARGE_USD` | `apify-docs/.../programming_interface/environment_variables.md`. Read by `sdk/src/configuration.ts` (`maxTotalChargeUsd`). |
| `aborting` / `migrating` / `persistState` events | `apify-docs/.../programming_interface/system_events.md`, `.../builds_and_runs/state_persistence.md` |

## Verified in SDK / crawlee source, and exercised by `npm test`

1. **Local runs do not charge.** In `sdk/src/charging.ts:281`, `charge()` returns `chargedCount: 0` with a one-time warning when the run is not PPE. `Actor.pushData(items, event)` on a non-PPE run pushes every item and never calls `charge()`, so no warning is printed (test: "plain local run").
2. **Local PPE simulation** works with `ACTOR_TEST_PAY_PER_EVENT=true` (`sdk/src/configuration.ts:179`). Locally every event is priced at **$1** (`sdk/src/charging.ts:428`). `ACTOR_USE_CHARGING_LOG_DATASET=true` writes every charge to the local `charging_log` dataset (`charging.ts:86`). The tests count charges from that dataset.
3. **Synthetic dataset-item event locally.** It was not charged in local runs: only `result` rows appear in `charging_log`. Local memory storage does not take the platform's patched-client path (`sdk/src/patched_apify_client.ts:99`), and the explicit path sees `isDefaultDataset=false` because the local default dataset gets a UUID id, not `defaultDatasetId` "default" (`node_modules/apify/dist/actor.js:1657`; checked by review). The test with `ACTOR_MAX_TOTAL_CHARGE_USD=3` saves exactly 3 items, so local cost is $1/item.
4. **Overcharge-by-one.** When the budget cannot cover the next item, the SDK still pushes and charges ONE item so the platform kills the run (`charging.ts:305, 478`). `ResultSink` stops at the first `eventChargeLimitReached` and (review fix 2026-10-03) also checks `calculateMaxEventChargeCountWithinLimit()` before every push, because a budget already exhausted before the first item (e.g. `ACTOR_MAX_TOTAL_CHARGE_USD=0.5` at $1/item) used to push + charge 1 item anyway (tests: saved == charged == 3; budget 0.5 -> 0 items, 0 charges).
5. **`chargedCount` from `Actor.pushData` is not an item count.** `mergeChargeResults` sums the custom and synthetic events (`charging.ts:69-72`). The sink counts saved items with `getChargedEventCount(event)` deltas under a serialized flush chain.
6. **`Actor.pushData(items, 'apify-…')` throws** (`sdk/src/actor.ts:1065`). Never charge synthetic events manually.
7. **Blocking.** 401/403/429 retire the session and are retried (`crawlee/packages/core/src/session_pool/consts.ts:1`, and `_throwOnBlockedRequest`). `SessionError extends RetryRequestError` (`crawlee/packages/core/src/errors.ts:59`), so retries from `detectBlock` are bounded by `maxSessionRotations` instead of `maxRequestRetries` (`basic-crawler.ts:2001`). The template sets both to `maxRequestRetries`. `errorHandler` runs before every retry (`basic-crawler.ts:1898`), and that is where the exponential backoff sleeps (test: 403 page and captcha page each hit twice).
8. **`Actor.useState(name, default, options)`** is the real signature (`sdk/src/actor.ts:1521`). The docs example `Actor.useState({…})` in `state_persistence.md` passes the default as the *name*, which is wrong.
9. **Schemas** pass `apify validate-schema` (apify-cli 1.10.0). **`apify run`** (CLI 1.10.0) runs the Actor end to end against the mock server.

## UNVERIFIED (needs the platform or the live provider)

- Charging on the platform: real `run.charge()` calls, `pricingInfo` from the run, Console event config.
- Whether `apify-default-dataset-item` and a custom `result` would double-bill. Source reading says yes (`calculatePushDataLimits` adds both prices). The SDK must also have `apify-default-dataset-item` in `perEventPrices` to intercept.
- Decodo gateway host/port, the sticky-session username syntax, and the default IP-echo URL. Only a local authenticating stub proxy was tested.
- Apify Proxy fallback (needs a token or `APIFY_PROXY_PASSWORD`).
- `migrating` / `aborting` handlers (wired but not triggered). The Docker build was not run because there is no Docker daemon in this environment.
- Platform input defaults: the platform fills `default` from the input schema, but local runs do not. `src/input.js` duplicates every default.

## Builder gotchas

- **Pick ONE per-item event in Console.** Use either custom `result` (and delete `apify-default-dataset-item`) or the synthetic event only (set `CHARGE_EVENT = null` in `src/charge.js`). With both, users pay twice. The sink logs a warning on the platform when both are priced.
- **Never call `Actor.charge` for `apify-actor-start`.** The platform charges it.
- **Push only through `sink.add()`.** On the platform, crawlee's `context.pushData()` / `Dataset.pushData()` still triggers the synthetic event, but it bypasses the custom-event charge, the monitoring commit and the `maxItems` count.
- **Monitoring state lives in a named KV store `<SOURCE_NAME>-monitor`.** Named stores are account-wide and never expire, so give every Actor a distinct `SOURCE_NAME`. The record ID must be stable across runs, and any field that changes on every run belongs in `VOLATILE_FIELDS`.
- **Charge-then-commit.** Items are marked "seen" only after they are saved and charged. If the budget cuts a run short, the unsaved items show up as `new` next time, which is correct.
- **Decodo credentials go in Console as *Secret* env vars** (`environment_variables.md:135-141`: non-secret env vars are shown publicly on the Actor page once published). Never put them in `actor.json` `environmentVariables`. Proxy URLs typed into the `proxyConfiguration` editor are not encrypted.
- **The owner pays Decodo bandwidth** on every user's run when the owner's credentials are baked in. Price `result` to cover it.
- **Single `@crawlee/core` copy.** `npm ls @crawlee/core` must show one version, deduped between `apify` and `@crawlee/cheerio`. If you upgrade one of them, upgrade both.
- **The crawlee v4 / SDK master migration is coming.** Source on GitHub master no longer matches npm. Read the tagged source that matches `package-lock.json`.
- **Default monitoring key** hashes start URLs, IDs and any input field not in `NON_KEY_FIELDS` (`src/monitor.js`), so a builder-added `query`/`country` field separates memories automatically. Add new run-setting fields (that do not change the result set) to `NON_KEY_FIELDS`.
- **Flush failures fail the run.** `pushData` pushes before it charges; if saving/charging throws, the sink stops the crawl, drops later items and `main.js` fails the run after writing `RUN_SUMMARY`.
- `crawler.stop()` lets in-flight requests finish, so a few extra requests can happen after `maxItems`. The sink drops their items, and `RUN_SUMMARY.dropped` counts them.
