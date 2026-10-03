# Apify API spec notes (census fields)

**Status of everything below: spec-verified, NOT live-verified.** Nothing here has been checked against a live API response, because egress to api.apify.com was blocked in this session. Items marked **UNVERIFIED** are not in the spec, or the spec is ambiguous about them.

## Sources

| Source | Commit | Notes |
|---|---|---|
| github.com/apify/apify-docs, `apify-api/openapi/` | `7b30f19` (2026-10-02) | The official OpenAPI spec. Line numbers below refer to this commit. |
| github.com/apify/apify-docs, `sources/platform/actors/` | `7b30f19` | Platform docs, used for rating, quality score and discount tiers. |
| github.com/apify/apify-client-js | `6f4eb0e` (2026-10-02) | `src/resource_clients/store_collection.ts`, `src/models.ts` |
| github.com/apify/apify-client-python | `ac60559` (2026-10-02) | `src/apify_client/_models.py` is generated from the same spec. |

Abbreviations: `S/` = `apify-api/openapi/components/schemas/`, `P/` = `apify-api/openapi/paths/`, `O` = `apify-api/openapi/openapi.yaml`.

## 1. Endpoints

| Endpoint | Spec location | Notes |
|---|---|---|
| `GET /v2/store` (operationId `store_get`) | `O`:775-776, `P/store/store.yaml`:1-129 | Lists public Store Actors. The description says "It will not return more than 1,000 records" (store.yaml:12-13). **UNVERIFIED:** whether that is a per-page limit or a cap on the whole result window. The tool warns if the server stops returning items before `total`. |
| `GET /v2/actors/{actorId}` (operationId `actor_get`) | `O`:533-534, `P/actors/acts@{actorId}.yaml`:1-76 | The canonical path is `/v2/actors/`. `/v2/acts/` still works but is deprecated legacy (`O`:134-140). `actorId` is either the Actor ID or `username~name` (`components/parameters/runAndBuildParameters.yaml`:1-9). |
| `GET /v2/actors/{actorId}/builds/default` (`actor_build_default_get`) | `P/actors/acts@{actorId}@builds@default.yaml`:1-25 | `security: []` (line 14), so no token is needed. This is where the input schema and README live: `Build.actorDefinition.input` / `.readme` (`S/actor-builds/Build.yaml`:97, `S/actors/ActorDefinition.yaml`:30,33). The `Build.inputSchema` and `Build.readme` fields are deprecated (Build.yaml:56-62). The census does not call this endpoint. |
| `GET /v2/users/me/limits` (`users_me_limits_get`) | `O`:785-786, `P/users/users@me@limits.yaml` | Used only by the spend guard: `data.current.monthlyUsageUsd` (`S/users/LimitsResponse.yaml`:6-7, `S/users/AccountLimits.yaml`:12, `S/users/Current.yaml`:15). **UNVERIFIED:** how often the value refreshes. |

**Auth.** Global security is `httpBearer` or `apiKey` (`O`:799-801). The security scheme text says a token is optional for public resources. The tool sends `Authorization: Bearer` only, never `?token=`. **UNVERIFIED:** whether `/v2/store` works without a token. The tool supports `--no-auth`.

**Rate limits** (`O`:415-500). The global limit is 250,000 req/min. The per-resource limit is 60 req/s. A 429 response has body `error.type = rate-limit-exceeded`. The spec recommends exponential backoff starting at 500 ms and doubling. The tool defaults to 2 req/s with that backoff.

**Cost.** The spec has no per-request pricing for GET calls. **UNVERIFIED:** whether they are free. The tool caps the request count and reads account usage to guard against spend.

## 2. `GET /v2/store` query parameters (`P/store/store.yaml`)

| Param | Line | Type / values | Census use |
|---|---|---|---|
| `limit` | 16 to `components/parameters/paginationParameters.yaml`:13-23 | number. "Default value as well as the maximum is `1000`" | 1000 |
| `offset` | 17 to `paginationParameters.yaml`:1-11 | number, default 0 | paging |
| `search` | 18-27 | string. Searches title, name, description, username and readme. | optional |
| `sortBy` | 28-37 | `relevance` (default), `popularity`, `newest`, `lastUpdate`. The spec example has stray quotes (`"'popularity'"`), so send the value without quotes. | `popularity` |
| `category` | 38-45 | string | for slicing |
| `username` | 46-53 | string | optional |
| `pricingModel` | 54-67 | `FREE`, `FLAT_PRICE_PER_MONTH`, `PRICE_PER_DATASET_ITEM`, `PAY_PER_EVENT` | for slicing |
| `allowsAgenticUsers` | 68-77 | boolean | not used |
| `responseFormat` | 78-94 | `full` (default) or `agent`. `agent` drops most fields. | must stay `full` |
| `includeUnrunnableActors` | 95-107 | boolean, default **false**. The default hides Actors from non-KYC developers and some full-permission Actors. | `true` for a full census |

## 3. Pagination shape

The response body is `data` = `ListOfStoreActors` (`S/store/ListOfActorsInStoreResponse.yaml`:6-7, `S/store/ListOfStoreActors.yaml`:1-11). It is `PaginationResponse` (`S/common/PaginationResponse.yaml`) plus `items[]`.

| JSON path | Type | Line |
|---|---|---|
| `data.total` | integer | 11 |
| `data.offset` | integer | 16 |
| `data.limit` | integer | 21 |
| `data.desc` | boolean | 26 |
| `data.count` | integer | 30 |
| `data.items[]` | StoreListActor[] | ListOfStoreActors.yaml:8-11 |

The same values are also sent as headers: `X-Apify-Pagination-Offset/Limit/Count/Total/Desc` (`components/headers/ApifyPaginationHeaders.yaml`:1-35).

## 4. `StoreListActor` (`S/store/StoreListActor.yaml`). Required: id, title, name, username, stats

| JSON path (in `data.items[]`) | Type | Line |
|---|---|---|
| `id` | string | 10 |
| `title` | string | 13 |
| `name` | string | 16 |
| `username` | string | 19 |
| `userFullName` | string\|null | 22 |
| `description` | string\|null | 25 |
| `categories` | string[] (e.g. `MARKETING`, `LEAD_GENERATION`) | 28-34 |
| `notice` | `NONE`\|`RESIDENTIAL_PROXY_REQUIRED`\|`UNDER_MAINTENANCE`\|null (`S/actors/ActorNotice.yaml`:5-9) | 35-36 |
| `pictureUrl`, `userPictureUrl` | string\|null | 37-43 |
| `url` | string\|null (uri) | 44-47 |
| `stats` | ActorStats (section 5) | 48-49 |
| `currentPricingInfo` | CurrentPricingInfo (section 6) | 50-51 |
| `isWhiteListedForAgenticPayments` | boolean\|null | 52-54 |
| `actorReviewCount` | integer | 55-57 |
| `actorReviewRating` | number (e.g. 4.7) | 58-60 |
| `bookmarkCount` | integer | 61-63 |
| `badge` | string\|null | 64-66 |
| `readmeSummary` | string (LLM-generated) | 67-69 |

**Not in StoreListActor:** `modifiedAt`, `createdAt`, `isDeprecated`, `pricingInfos` (history), `isCritical`, `actorPermissionLevel`. They are on Actor detail only (section 7). `lastRunStartedAt` is in `stats`.

**UNVERIFIED:** `actorReviewCount`, `actorReviewRating` and `bookmarkCount` are defined twice, at the item top level and inside `stats` (section 5). Which one the live API fills is unknown, so the tool reads the top-level value and falls back to `stats`.

## 5. `ActorStats` (`S/actors/ActorStats.yaml`). Shared by Store list `stats` and Actor detail `stats`

| JSON path | Type | Line | Census column |
|---|---|---|---|
| `stats.totalBuilds` | integer | 5 | (not used) |
| `stats.totalRuns` | integer | 9 | total_runs |
| `stats.totalUsers` | integer (includes the owner) | 13 | total_users |
| `stats.totalUsers7Days` | integer | 17 | users_7d |
| `stats.totalUsers30Days` | integer | 21 | users_30d |
| `stats.totalUsers90Days` | integer | 25 | users_90d |
| `stats.totalMetamorphs` | integer | 29 | (not used) |
| `stats.lastRunStartedAt` | date-time | 35 | last_run_started_at |
| `stats.actorReviewCount` | integer | 40 | review_count (fallback) |
| `stats.actorReviewRating` | number | 44 | rating (fallback) |
| `stats.bookmarkCount` | integer | 48 | bookmark_count (fallback) |
| `stats.publicActorRunStats30Days` | object. "Only for public Actors. Excludes runs started by the Actor's owner." | 52-56 | |
| `...publicActorRunStats30Days.ABORTED` | integer | 58 | runs_30d_aborted |
| `...FAILED` | integer | 62 | runs_30d_failed |
| `...SUCCEEDED` | integer | 66 | runs_30d_succeeded |
| `...TIMED-OUT` | integer (key has a hyphen) | 70 | runs_30d_timed_out |
| `...TOTAL` | integer | 74 | runs_30d |

The spec's Store-list example (`ListOfActorsInStoreResponse.yaml`:25-33) does not include `publicActorRunStats30Days`. **UNVERIFIED:** whether the Store list actually returns it. The tool falls back to detail `stats` when it is missing.

## 6. `currentPricingInfo` in the Store list (`S/store/CurrentPricingInfo.yaml`). Required: pricingModel

| JSON path | Type | Line |
|---|---|---|
| `currentPricingInfo.pricingModel` | string (FREE / FLAT_PRICE_PER_MONTH / PRICE_PER_DATASET_ITEM / PAY_PER_EVENT) | 6 |
| `.apifyMarginPercentage` | number, 0 to 1 | 9 |
| `.createdAt`, `.startedAt` | date-time | 15, 19 |
| `.notifiedAboutChangeAt`, `.notifiedAboutFutureChangeAt` | date-time\|null | 23, 27 |
| `.isPriceChangeNotificationSuppressed`, `.forceContainsSignificantPriceChange` | boolean | 31, 34 |
| `.isPPEPlatformUsagePaidByUser` | boolean | 37 |
| `.reasonForChange` | string\|null | 40 |
| `.trialMinutes` | integer\|null | 43 |
| `.unitName` | string\|null | 46 |
| `.pricePerUnitUsd` | number\|null | 49 |
| `.minimalMaxTotalChargeUsd` | number\|null | 52 |
| `.pricingPerEvent` | object\|null, `additionalProperties: true`, **untyped** | 55-58 |

**Pay-per-event in the Store list is UNVERIFIED.** `pricingPerEvent` exists here but its inner shape is not specified. The tool assumes it matches the detail shape (`actorChargeEvents` → event map) and also accepts a bare event map.

**Tiered per-result pricing in the Store list.** `CurrentPricingInfo` has no `tieredPricing` property, so per-tier PRICE_PER_DATASET_ITEM prices are **detail-only per the spec**. **UNVERIFIED:** whether the live API includes them anyway.

## 7. Actor detail `GET /v2/actors/{actorId}` → `data` (`S/actors/Actor.yaml`)

| JSON path | Type | Line | Census column |
|---|---|---|---|
| `data.id`, `.userId`, `.name`, `.username` | string | 15-30 | |
| `data.title` | string\|null | 81 | |
| `data.description` | string\|null | 31 | |
| `data.isPublic` | boolean | 39 | |
| `data.actorPermissionLevel` | `LIMITED_PERMISSIONS` or `FULL_PERMISSIONS` (`ActorPermissionLevel.yaml`) | 43 | actor_permission_level |
| `data.createdAt` | date-time | 45 | created_at |
| `data.modifiedAt` | date-time | 50 | last_modified |
| `data.stats` | ActorStats | 55 | fills gaps |
| `data.versions[]` | Version[] | 57-62 | (not used) |
| `data.pricingInfos[]` | ActorRunPricingInfo[], the full history including future-dated entries | 63-66 | pricing_*, pricing_history_count, pending_price_change |
| `data.isDeprecated` | boolean\|null | 73 | deprecated |
| `data.taggedBuilds` | object\|null | 85 | |
| `data.readmeSummary` | string | 93 | |
| `data.seoTitle`, `.seoDescription` | string\|null | 97, 102 | |
| `data.notice` | ActorNotice | 116 | |
| `data.categories` | string[] | 118 | |
| `data.isCritical` | boolean, "maintained by Apify" | 124-127 | is_critical (cross-checks the house list) |
| `data.isGeneric` | boolean, "intended for developers" | 128 | |
| `data.isSourceCodeHidden`, `.hasNoDataset` | boolean | 132, 137 | |
| `data.standbyUrl` | string\|null | 110 | |

The spec has no full README or input schema on Actor detail. Those come from the build (section 1).

### `pricingInfos[]` variants (`S/actor-pricing-info/`)

- Discriminator `pricingModel` (`ActorRunPricingInfo.yaml`:1-13).
- Common fields (`CommonActorPricingInfo.yaml`):
  - `apifyMarginPercentage` (8)
  - `createdAt` (14)
  - `startedAt` (19), "since when this record is effective"
  - the notification and reason fields are `x-internal` (22-38)
- `FREE` (`FreeActorPricingInfo.yaml`): no extra fields.
- `FLAT_PRICE_PER_MONTH` (`FlatPricePerMonthActorPricingInfo.yaml`):
  - `pricePerUnitUsd` = monthly USD (16)
  - `trialMinutes` (13)
- `PRICE_PER_DATASET_ITEM` (`PricePerDatasetItemActorPricingInfo.yaml`):
  - `unitName` (12)
  - `pricePerUnitUsd` (15), **or** `tieredPricing` (20). The two are mutually exclusive.
  - `tieredPricing.{TIER}.tieredPricePerUnitUsd` (`TieredPricingPerDatasetItem.yaml`:1-7, `...Entry.yaml`:7)
  - **UNVERIFIED:** whether `pricePerUnitUsd` is per single item or per 1,000 items.
- `PAY_PER_EVENT` (`PayPerEventActorPricingInfo.yaml`):
  - `pricingPerEvent.actorChargeEvents.{eventName}` (12-18)
  - `minimalMaxTotalChargeUsd` (19)
  - Each event is an `ActorChargeEvent` (`ActorChargeEvent.yaml`) with these fields:
    - `eventTitle` (10)
    - `eventDescription` (13)
    - `eventPriceUsd`, a flat price (16), **or** `eventTieredPricingUsd.{TIER}.tieredEventPriceUsd` (20, `TieredPricingPerEvent.yaml`, `TieredPricingPerEventEntry.yaml`:7). The two are mutually exclusive.
    - `isPrimaryEvent` (22)
    - `isOneTimeEvent` (25)

**Tier names.** The spec describes tier keys as free-form (`additionalProperties`) and gives "e.g. `FREE`, `BRONZE`, `SILVER`, `GOLD`, `PLATINUM`, `DIAMOND`" (`TieredPricingPerEvent.yaml`:3-4, `TieredPricingPerDatasetItem.yaml`:3-4). The platform docs name only BRONZE, SILVER and GOLD as plan discount tiers (`sources/platform/actors/running/store/index.md`:108-120). **UNVERIFIED:** the exact tier set. The tool stores whatever keys come back.

**Where per-tier PPE prices live:**

| Location | Status |
|---|---|
| Detail `pricingInfos[].pricingPerEvent.actorChargeEvents` | Typed, spec-verified |
| Store list `currentPricingInfo.pricingPerEvent` | Untyped, UNVERIFIED |

## 8. Web-page metrics: in the API or not?

| Metric | In API spec? | Notes |
|---|---|---|
| Rating | **Yes**: `actorReviewRating`, `actorReviewCount` (sections 4 and 5) | Platform docs say it is a weighted average where recent reviews and trusted users weigh more (`sources/platform/actors/publishing/actor-rating.mdx`:10-15). |
| Success rate | **Derivable**: `publicActorRunStats30Days.SUCCEEDED / TOTAL` | Excludes the owner's runs. **UNVERIFIED:** that this equals the percentage shown on the Store page, since the page's formula is unknown. For example, it may treat ABORTED differently. |
| Issues response time / open-issue count | **No** | Not in the spec or in either client. Only on `apify.com/{user}/{actor}/issues`. **UNVERIFIED:** which JSON or internal endpoint feeds the page; it is not knowable from the docs or client code. Would need a live page fetch. |
| Quality score (0-100) | **No** | Console > Insights, owner only (`publishing/quality_score.mdx`:23). |
| "Last modified" on the page | Partly | `modifiedAt` is detail-only. **UNVERIFIED:** whether the page shows `modifiedAt` or the last build time. |
| Developer-level stats (actor count, etc.) | Not checked | Out of scope. `GET /v2/users/{userId}` exists (`O`:779). |

## 9. Client-library cross-check

- **JS client** `StoreCollectionClient.list` (`store_collection.ts`:14-23) accepts `search`, `sortBy`, `category`, `username`, `pricingModel` and `includeUnrunnableActors`. It does not take `allowsAgenticUsers` or `responseFormat`.
- **JS types** (`models.ts`:774-793) build `ActorStoreList` from the spec's `StoreListActor`. They describe `currentPricingInfo` as "a flat summary rather than one of the `ActorRunPricingInfo` variants, so … every price field is optional". This agrees with section 6.
- **Python client** `_models.py`:423 and 2332 are generated from the spec and have the same fields. Neither client exposes a success-rate or issues field.
