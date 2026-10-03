# Pattern hypotheses: what separates winners from the bottom of the same category

Purpose: each hypothesis is phrased so Phase 3 can confirm or kill it with census.csv columns. "Winner" = top quartile by `users_30d` within a category (or within a same-source peer set); "bottom" = bottom quartile with age >= 90 days (so brand-new actors do not pollute the bottom). All priors below are desk-level and UNVERIFIED; sources in LANDSCAPE.md.

## Census columns assumed

Column names are proposals for census-agent; rename to match the spec-verified fields. Columns marked (derived) are computed from raw fields.

`actor_id, slug, username, title, seo_title, seo_description, category[], created_at, modified_at, is_deprecated, under_maintenance, pricing_model, ppe_events[] (name, desc, price_free, price_bronze, price_silver, price_gold), entry_price_per_1k (derived), gold_price_per_1k (derived), has_start_fee, monitor_mode_claimed (derived from README/title regex), users_total, users_30d, runs_30d, run_success_30d, rating, rating_count, issues_open, issues_closed, issue_response_time_avg, readme_len, readme_has_sample_json, readme_first_para_len, input_fields_count, input_has_url_list, input_has_schedule_hint, output_schema_present, versions_count, last_build_at, builds_90d (derived), bookmarks, is_apify_maintained, publisher_actor_count, publisher_users_total, source_domain (derived from title/README), peers_same_source (derived count), quality_score (if exposed)`

Peer set construction: group by `source_domain` (e.g. vinted.*, autotrader.co.uk). The hypotheses are mostly *within-peer-set* comparisons, because cross-category comparisons are dominated by source demand.

---

## H1. Title/SEO: winners' `seo_title`/title matches the literal search query ("<Site> Scraper"), bottom actors use branded/clever names or repo-style slugs.

Prior: dev.to survival guide and Apify's SEO help article both say the name is the heaviest-weighted field; the 98-actors blog describes "<Site> Scraper — <3 nouns>" as the pattern.
Test: within each peer set, compute `title_matches_pattern` = regex `^(?i)[\w .'-]+ (scraper|api|monitor|alerts?|tracker)\b` AND source name present in first 40 chars. Compare winner vs bottom rate. Also test `seo_title` non-null and length 40-70.
Confirm if: winners' match rate >= bottom + 25 points across >= 10 peer sets. Kill if: difference < 10 points.
Counter-hypothesis to test at the same time (dododata dev.to post): `users_total` explains rank more than title. Test: Spearman(users_total, Store search position for the peer keyword) if census records search position; otherwise Spearman(users_total, users_30d) vs Spearman(title_match, users_30d).

## H2. Age/flywheel: winners are simply older. Within a peer set, the oldest actor with success rate > 95% is in the top quartile most of the time.

Prior: apifystats says 93.5% of actors are < 1 year old; dododata claims cumulative users is what ranks.
Test: Spearman(`created_at` age, `users_30d`) within peer sets; also fraction of peer sets where the oldest healthy actor is #1 by `users_30d`.
Confirm if: oldest-healthy is #1 in > 60% of peer sets. Kill if: < 35%.
Why it matters: if confirmed, entering an existing peer set head-on is a losing move regardless of quality; the selection should prefer peer sets where the incumbents are < 6 months old or unhealthy (H8), or sources with no peer set.

## H3. Pricing model: within a peer set, PPE actors out-rank free and pay-per-usage actors in `users_30d`; rental-migrated (pay-per-usage as of 2026-10-01) actors lose users over the next 30-60 days.

Prior: 75% of top-20 are PPE; Apify says 73% of customers prefer PPE; rental retired 2026-10-01.
Test: `pricing_model` vs `users_30d` rank within peer set (Kruskal-Wallis or simple quartile shares). For the migration effect, census must be re-run at +30 days; compare `users_30d` delta for `pricing_model == PAY_PER_USAGE AND created_at < 2026-04-01` (likely ex-rental) vs PPE peers.
Confirm if: PPE share in top quartile >= 1.5x PPE share in bottom quartile. Kill if: no difference, or FREE dominates (would suggest free loss-leaders win users).

## H4. Price level: within a peer set, the top actor is NOT the cheapest; price-per-1k has weak correlation with users once the actor is above the "hobby" floor. But extreme prices (> 5x peer median) sit in the bottom quartile.

Prior: 10x spreads inside niches (Google Play reviews $0.05-$7/1k; Noon $0.55-$7.50) with the cheapest not obviously the most used (Trustpilot: automation-lab at $0.575 FREE-tier had 2.4K users vs webdata_labs at $0.20 with no user count shown).
Test: within peer set, rank of `entry_price_per_1k` vs rank of `users_30d`; share of actors with price > 5x peer median in each quartile.
Confirm if: |Spearman| < 0.3 for the middle 80% of prices AND > 60% of > 5x-median actors are in the bottom half. Kill if: Spearman < -0.5 (cheapest wins).
Decision use: tells us whether to price at the peer median (H4 true) or undercut (H4 false).

## H5. Tiering: winners more often have tiered PPE (FREE > BRONZE > SILVER > GOLD spread) than bottom actors, who use a single price.

Prior: docs say tiering is optional; Apify blog suggests 10%/20% discounts; worked example shows 2.7x spread FREE -> GOLD.
Test: `tier_spread` = price_free / price_gold (1.0 = flat). Compare mean and share > 1.0 by quartile.
Confirm if: top-quartile share with spread > 1.0 exceeds bottom by >= 20 points. Kill if: no difference. (If killed, skip tiering effort at launch.)

## H6. Maintenance cadence: winners are rebuilt more often. `builds_90d` >= 3 for winners; bottom actors have 0-1 builds in 90 days and higher `under_maintenance` incidence.

Prior: Apify tests actors daily; 3 failing days -> "under maintenance"; 98-actor dev reports ~2 h/week maintenance across the catalogue.
Test: `builds_90d` and `modified_at` recency by quartile; `under_maintenance` rate by quartile; `run_success_30d` by quartile.
Confirm if: median builds_90d winners >= 2x bottom AND run_success_30d winners - bottom >= 5 points. Kill if: build cadence is flat across quartiles (then reliability is about source choice, not effort).

## H7. Issue responsiveness: winners have a public `issue_response_time_avg` under 24 h and a high closed/open ratio; bottom actors have unanswered issues.

Prior: Apify shows average response time publicly in Actor metrics and tells publishers to respond promptly.
Test: `issue_response_time_avg`, `issues_open / (issues_open + issues_closed)` by quartile. Control for volume (winners get more issues).
Confirm if: median response time winners < 24 h and bottom > 72 h (or null because never answered). Kill if: no separation.
Operational implication for ProgrammX: if confirmed, a 24 h issue SLA is a cheap, measurable advantage for a team of 15 vs solo publishers.

## H8. Incumbent health gap: peer sets where the #1 actor has `run_success_30d` < 90%, `under_maintenance` true, or `modified_at` > 120 days old show faster share shifts to #2/#3 (users_30d growth), i.e. unhealthy incumbents are displaceable.

Prior: anecdotal (deprecated WTTJ actors visible in search; rental migration churn).
Test: needs two census snapshots >= 30 days apart. For each peer set compute `top1_health` and the change in `users_30d` share of non-#1 actors.
Confirm if: unhealthy-incumbent peer sets show >= 2x the share shift of healthy ones. Kill if: no difference.
Decision use: this is the main filter for picking peer sets to enter. Even without two snapshots, Phase 3 should list every peer set from CANDIDATES.md with incumbent `run_success_30d`, `modified_at` and `under_maintenance`.

## H9. Scope breadth: within a peer set, actors covering multiple country sites or multiple sources (e.g. "26 Vinted markets", "Rightmove + Zoopla + OnTheMarket", "Copart + IAAI") out-rank single-site actors; but "scrape anything" generic actors under-rank specific ones.

Prior: many top-of-snippet actors advertise multi-market coverage; generic "Food Delivery Scraper (6 platforms)" exists but specific Talabat/Deliveroo actors appear more often.
Test: `scope_breadth` = count of distinct domains/markets claimed in title+README (regex on country lists, "+", "&", "all councils"). Compare by quartile; separately flag `is_generic` (no source domain in title).
Confirm if: multi-market share in top quartile >= bottom + 20 points AND generic actors are over-represented in the bottom. Kill if: single-site specific actors dominate the top (then build narrow and clone per market).

## H10. Monitoring/scheduling fit: actors whose title or README promises "new since last run", "alerts", "monitor", "price drop", "only charges for new items" have higher `runs_30d / users_30d` (runs per user) than batch scrapers, and higher retention (users_30d / users_total).

Prior: multiple monitor-mode actors exist (Rightmove alerts, OLX PK watchlist, Gazette monitor, Gumroad price-drop, generic restock monitor) and advertise hourly schedules + webhooks. REVIEW 2026-10-03: the review re-search found 15+ more (Vinted x4, Marktplaats x3, Kleinanzeigen x3, Wallapop, SpareRoom, Argos stock, Shopify x4, Tadawul), several priced per *new listing* at $2.45-$7/1k vs $0.40-$1/1k for batch scrapers of the same source. H10 now has a large enough sample to test in Phase 3, and a price-premium sub-test (monitor $/1k vs batch $/1k within peer set) should be added.
Test: `monitor_mode_claimed` vs `runs_per_user_30d` and `retention_proxy = users_30d / users_total`. Also `input_has_schedule_hint` (README mentions schedule/webhook).
Confirm if: monitor actors' median runs_per_user >= 2x batch actors' AND retention_proxy higher. Kill if: no difference (then monitor shape is marketing, not usage).
Decision use: this is the hypothesis behind the user's "repeat usage shape" criterion and should be tested first; if it fails, re-weight CANDIDATES.md.

## H11. README structure: winners' README first paragraph is short (< 300 chars) and states the use case; includes a sample JSON block and a field table; bottom actors open with install instructions or long marketing.

Prior: 98-actors blog ("single sentence use case, three bullets, sample JSON output, filters; technical details as appendix"); Apify README guide.
Test: `readme_first_para_len`, `readme_has_sample_json`, `readme_has_field_table`, `readme_len` by quartile.
Confirm if: sample-JSON presence winners >= bottom + 25 points. Kill if: no difference.

## H12. Input schema simplicity: winners accept a pasted URL or a keyword with few required fields (<= 3); bottom actors require many fields or site-specific IDs.

Prior: Apify blog on input schema design; many top snippets say "paste a filtered URL".
Test: `input_fields_required_count`, `input_has_url_list` by quartile.
Confirm if: median required fields winners <= 2 and bottom >= 4. Kill if: equal.

## H13. Publisher effect: actors from publishers with >= 10 actors (catalogue publishers like parseforge, memo23, automation-lab, scrapesage, 123webdata, shahidirfan, sian.agency, haketa, crawloop, studio-amba, logiover) take a disproportionate share of users in long-tail peer sets, not because each actor is better but because of cross-linking and account-level trust.

Prior: these ~11 usernames appeared in roughly half of all niche searches this run.
Test: `publisher_actor_count` and `publisher_users_total` vs within-peer-set rank, controlling for H2 (age) and H6 (health).
Confirm if: catalogue publishers hold #1 in > 50% of long-tail peer sets even when not oldest. Kill if: they are #1 only when also oldest/healthiest.
Decision use: if confirmed, ProgrammX should launch a cluster of related actors (one source family, several shapes) rather than one actor, and cross-link them in READMEs.

## H14. Proxy/anti-bot burden: peer sets whose incumbents require residential proxy + browser (README says "Playwright", "residential proxy required", "Cloudflare") have fewer total actors and higher prices; this is where a JSON-endpoint approach can win on price and reliability.

Prior: Rightmove/Zoopla incumbents describe Playwright + residential proxy; Idealista and G2 described as aggressively blocking; Wallapop/Kompass incumbents brag about "no browser".
Test: `needs_browser_claimed` regex on README; compare `peers_same_source`, `entry_price_per_1k`, `run_success_30d` by this flag.
Confirm if: browser-required peer sets have median price >= 2x and success rate <= 5 points lower. Kill if: no difference.
Decision use: pairs with the Decodo probes in Phase 4; the probe must record whether a JSON endpoint exists for each shortlisted source.

---

## Which hypotheses matter most (desk opinion)

1. **H2 (age flywheel) and H8 (incumbent health)** decide *whether* to enter any crowded peer set at all. Everything else is execution detail.
2. **H10 (monitor shape -> repeat usage)** is the user's core thesis; it must be tested before committing to monitor-style builds.
3. **H3/H4/H5 (pricing)** decide the launch price; cheap to test, directly actionable.
4. **H6/H7 (maintenance, issue SLA)** are the levers a 15-person team has over solo publishers.
5. H1, H9, H11, H12, H13, H14 refine positioning and are secondary.
