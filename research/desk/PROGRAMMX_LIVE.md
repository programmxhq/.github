# ProgrammX presence on Apify Store and GitHub (desk research)

Status: **UNVERIFIED.** Found via WebSearch on 2026-10-03; apify.com was not reachable from this container, so nothing below was read from the live Store. Phase 3 census must confirm against `GET /v2/store?username=programmx` (or the equivalent spec-verified endpoint) and the live profile page.

## Store profile

| Field | Value (as summarised by search) | Source |
|---|---|---|
| Profile URL | https://apify.com/programmx | search result title "Yasir Azeem (programmx) · Apify" |
| Display name | Yasir Azeem | same |
| Joined | November 2023 | search snippet of profile page |
| Public actors | 4 | same |
| Total users / monthly users | 9 total, 5 monthly | same (snippet; no date shown, likely the crawl date of the search index) |
| Run success | ">99% runs succeeded" | same |
| Positioning line | "builds focused data actors — B2B contact and marketplace data from public EU/UK sources"; "public data only, no logins, no account data, no private-seller data; fields the source doesn't publish come back null" | same |

## Actors found (exclude these from the candidate list)

| # | Actor (slug) | What it is, per snippet | URLs seen |
|---|---|---|---|
| 1 | `programmx/ebay-business-leads` | eBay Business Seller Leads: verified business-seller records from eBay EU/UK marketplaces (company name, email, phone, VAT number, company registration number, registered address), deduplicated per seller | https://apify.com/programmx/ebay-business-leads/api ; .../api/mcp |
| 2 | `programmx/immoscout24-agent-leads` | German Estate Agent Leads: Immobilienmakler contact DB from ImmobilienScout24 (company, business email with live deliverability status, phone, registered address, agency rating, ImmoScout membership tier) | https://apify.com/programmx/immoscout24-agent-leads ; .../api/mcp |
| 3 | `programmx/instantly-lead-pusher` | Instantly Lead Pusher: push any Apify dataset into Instantly campaigns (integration actor, not a scraper) | https://apify.com/programmx/instantly-lead-pusher/api/mcp ; .../api/cli |
| 4 | `programmx/propertyfinder-deal-scraper` | Property Finder Scraper: UAE listings with "AI Deal Score & Complete Coverage" | https://apify.com/programmx/propertyfinder-deal-scraper/api/mcp ; .../api/cli |

Observations (desk-level):

- Two of the four are **fixed-population lead lists** (eBay business sellers, ImmoScout agents). Under the user's own criteria ("fixed populations are OUT") these are the kind of actor the new selection should avoid, which is consistent with the low user counts.
- Property Finder is a crowded niche: at least 6 other PropertyFinder/Bayut/Dubizzle actors surfaced in search (see CANDIDATES.md group entry G1). A PropertyFinder *agents* scraper also exists from `solidcode`, and a Bayut agents scraper from `happyendpoint` and `skyline_scrapers`.
- An adjacent-publisher collision to note: `ryanclinton/pipedrive-lead-pusher` appeared next to `programmx/instantly-lead-pusher` in results, so the "lead pusher" integration pattern is also being copied.

## Possible duplicates / overlaps with candidates in CANDIDATES.md

- Any UAE property idea (Bayut/Dubizzle listings or agents) overlaps actor #4 and must be treated as an extension of it, not a new actor.
- Any ImmoScout24 *listings* monitor would share source and anti-bot surface with actor #2; worth considering as a sibling only if #2's run data shows the source is stable.

## GitHub presence

- This repo's remote is `https://github.com/programmxhq/.github` (org: **programmxhq**). The org profile README (profile/README.md) positions ProgrammX as an AI & blockchain product studio and says "some of that work is open in this org", but does not mention Apify.
- WebSearch for "github programmx Yasir Azeem apify actor repository" returned only the Apify profile and generic Apify SDK repos. **No public GitHub repository for the four actors was found.** If the actors are built from private repos or from Apify's web IDE, nothing is lost; if they are meant to be discoverable for credibility, a public `apify-actors` repo under programmxhq is a cheap fix.

## Must be checked live (Phase 3)

1. Confirm the four slugs, their pricing model (rental actors were auto-migrated on 2026-10-01; if any of these were rental, they are now pay-per-usage), current users, and `stats.lastRunStartedAt`.
2. Confirm whether any have been flagged "under maintenance" or deprecated.
3. Pull their Issues tab response-time metric; it is one of the public quality signals (PATTERN_HYPOTHESES.md H7) and will apply to anything new published under the same account.
4. Check whether a `programmxhq` or `programmx` GitHub org/user has public actor repos; the search index may simply not have them.
