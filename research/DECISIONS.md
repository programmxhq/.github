# Decisions

| # | Decision | Why |
|---|---|---|
| 1 | Run in offline-prep mode (no live census, probes, or prices). | Egress policy blocks Apify and Decodo; credentials absent. User approved prep scope. |
| 2 | API field names are taken from the official OpenAPI spec in github.com/apify/apify-docs, not memory. Marked "spec-verified, not live-verified" until a live call confirms. | Closest available evidence to "verify endpoints yourself". |
| 3 | Everything from WebSearch is marked UNVERIFIED and kept in research/desk/, separate from evidence files. | Rule: evidence over opinion; search results are third-party summaries. |
| 4 | Model routing: claude-fable-5-1 for desk-research synthesis and candidate generation; claude-opus-5-5 for tooling, template, teardowns, reviews. | Per brief. |
