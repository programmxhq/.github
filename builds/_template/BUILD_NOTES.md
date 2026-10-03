# BUILD NOTES — TODO actor name

> Skeleton. The builder fills every TODO. Keep claims honest: "verified" only means a command was
> actually run and its output checked. Anything that needs the Apify platform or the live site is
> UNVERIFIED until a platform run proves it.

## Status

| Area | State | Evidence |
|---|---|---|
| Local tests (`npm test`, offline mock) | TODO pass/fail | TODO paste summary line, e.g. `# pass 17 # fail 0` x3 |
| Schemas (`apify validate-schema`) | TODO | TODO |
| Live site scrape (real target) | UNVERIFIED | Egress blocked in build env / TODO |
| Decodo proxy against real gateway | UNVERIFIED | Only the local proxy stub was tested |
| Apify Proxy fallback | UNVERIFIED | Needs platform or APIFY_PROXY_PASSWORD |
| PPE charging on platform | UNVERIFIED | Only `ACTOR_TEST_PAY_PER_EVENT` local simulation |
| Docker build | UNVERIFIED | No Docker daemon in build env / TODO |
| Migration / abort handlers | UNVERIFIED | Handlers wired; platform events not simulated |

## What works

- TODO: list features exercised by tests, with the test name.

## Untested / known gaps

- TODO: source-specific fields that could not be checked against the live site.
- TODO: selectors that are guesses.
- TODO: anti-bot behaviour of the real site (rate limits, challenge pages).

## Source-specific decisions

- Entry points: TODO
- ID used for monitoring dedupe: TODO (must be stable across runs)
- Fields excluded from change detection (`VOLATILE_FIELDS`): TODO
- Block markers added to `detectBlock`: TODO

## Pricing (NOT LIVE)

- Events: `apify-actor-start` (synthetic), `result` (custom). Prices: TODO — set in Console only.
- In Console, remove `apify-default-dataset-item` if `result` is kept (otherwise users pay twice per item).
- Suggested minimal max-cost-per-run: TODO.

## Deploy (the user's call — do NOT run without explicit approval)

Pushing creates or updates a real Actor in an Apify account. Building agents must never run these
commands; the account owner decides when (and whether) to publish.

```bash
npm i -g apify-cli          # once
# Token comes from the environment, never from a file in this repo:
#   export APIFY_TOKEN=...   (or run `apify login` interactively and paste it)
apify login                 # stores credentials in ~/.apify, outside the repo
apify validate-schema       # schemas
npm test                    # offline tests must pass
apify push                  # builds on the platform; Actor stays private until published in Console
```

After the first push: set pricing in Console (Publication > Monetization), set the Decodo
credentials as secret environment variables (DECODO_USER, DECODO_PASS, DECODO_HOST), run once on the
platform with a small `maxItems`, and check the Output tab and `RUN_SUMMARY` before publishing.
