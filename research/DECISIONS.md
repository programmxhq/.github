# Decisions

| # | Decision | Why |
|---|---|---|
| 1 | Run in offline-prep mode (no live census, probes, or prices). | Egress policy blocks Apify and Decodo; credentials absent. User approved prep scope. |
| 2 | API field names are taken from the official OpenAPI spec in github.com/apify/apify-docs, not memory. Marked "spec-verified, not live-verified" until a live call confirms. | Closest available evidence to "verify endpoints yourself". |
| 3 | Everything from WebSearch is marked UNVERIFIED and kept in research/desk/, separate from evidence files. | Rule: evidence over opinion; search results are third-party summaries. |
| 4 | Model routing: claude-fable-5-1 for desk-research synthesis and candidate generation; claude-opus-5-5 for tooling, template, teardowns, reviews. | Per brief. |
| census-1 | `is_apify_owned` = owner in `research/tools/census/config.json` `house_owners` = [apify, compass, clockworks]. Only `apify` is certain; compass and clockworks NEED LIVE CONFIRMATION. After `--enrich`, check `census_summary.json` -> `csv.house_owner_check` / `non_house_owners_with_isCritical` (Actor.isCritical = "maintained by Apify") and edit the list. | Orchestrator's suggested list; spec offers isCritical as an evidence field. |
| census-2 | Census uses canonical `/v2/actors/{username}~{name}` (falls back to id on 404), not legacy `/v2/acts/`. | Spec openapi.yaml:134-140 marks `/v2/acts/` deprecated alias. |
| census-3 | Census sends `includeUnrunnableActors=true`, `sortBy=popularity`, `limit=1000`, `responseFormat` left at `full`. | API default hides unrunnable Actors; `agent` format drops fields; 1000 is spec max. |
| census-4 | Spend defence: GET-only, hard request cap (25k default), and a usage guard reading `/v2/users/me/limits` `current.monthlyUsageUsd` (stop at +$0.50). First live run must be a 1-page `--no-auth` smoke test. | $5 project cap; whether Store GETs are free is not stated in the spec. |
| 5 | Census spend guard fails closed: refuses an authenticated run if account usage can't be read at start, and stops after 3 consecutive failed usage reads. Override only with `--allow-unguarded`. | Census review found it failed open; the $5 cap is a hard limit. |
| 6 | Census sends APIFY_TOKEN only to api.apify.com or localhost unless `--allow-custom-base-url`. | Census review: any `--base-url` would receive the token. |
| 7 | Top-5 deep pass uses one shared set of rates (Decodo $4/GB PAYG and $2.75/GB at 100 GB; Apify 80% share minus compute; $0.20/CU Starter) so the five revenue models are comparable. | Avoid each agent finding different third-party figures. All UNVERIFIED until checked live. |
