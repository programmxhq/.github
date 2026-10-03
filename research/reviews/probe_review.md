# Review: Phase 5 probe harness (Decodo residential)

- **Reviewer:** review-agent:probe (opus)
- **Date:** 2026-10-03
- **Scope:** `research/tools/probe/` (README, config.yaml, wire.py, classify.py, runner.py, ledger.py, creds.py, extract.py, definition.py, `__main__.py`, definitions/, tests/), `research/probes/traffic_ledger.json`, `research/probes/PROBES.md`
- **Method:** I read all of the code. I ran the suite twice before making changes and twice after. I added a regression test for each fix and checked that each new test fails on the original code (HEAD copy in the scratchpad: 11 failed, 44 passed) and passes after the fix. No network was used, Decodo was not contacted, and nothing was committed.

## Verdict: PASS WITH FIXES

The core design holds up. The client counts bytes on the wire (CONNECT + TLS over MemoryBIO + compressed body), TLS is verified with SNI, credentials are redacted, the cost maths is correct, and vendor detection is kept separate from block classification. I found 9 real defects. Four of them could let traffic go unrecorded or let the cap be overrun (one hostile redirect, Ctrl-C, concurrent runs, config edits). The others are a misclassification and some smaller leaks. All are fixed. Tests went from 45 to 56, and all 56 pass on both runs (about 6 s each).

## Checks

| # | Check | Result | Notes |
|---|---|---|---|
| 1 | Tests run x2 (from `research/tools`: `python -m pytest probe/tests -q`) | PASS | Before: 45/45 twice. After: 56/56 twice. The author's claim of "45 passing" is confirmed. |
| 2a | Bytes recorded on every path: errors, 407, timeouts, TLS failures, truncation, byte limit | PASS | `fetch()` counts in `finally` and drains bytes the kernel has buffered. The runner records before it classifies. |
| 2b | Redirects | **FIXED** | A `Location` with a bad port or IPv6 made `urlsplit`/`urljoin` raise *outside* the try. The run crashed and the earlier hops' billed bytes never reached the ledger. |
| 2c | Ctrl-C mid-request | **FIXED** | The in-flight request's bytes (up to about 5 MB) were lost. Now it records first, then re-raises. The run status is `interrupted`. |
| 2d | Health check billed | PASS | Recorded under `_health`, once per endpoint attempt. |
| 2e | Direct baseline not charged to Decodo | PASS | It goes to `direct_bytes_total`, appears in results.jsonl as `mode: direct`, and is excluded from the cap and from verdict stats. |
| 2f | Ledger write atomic / locked | PASS (hardened) | Each write uses flock + mkstemp + `os.replace`. I added `fsync` before the replace. |
| 2g | Concurrent runs | **FIXED** | Each request may use `cap - used - margin`. Two concurrent runs could both spend that same headroom and overrun the cap. A non-blocking run lock now refuses a second concurrent run or health check. |
| 2h | Cap unbypassable via config/CLI | **FIXED** | `HARD_CAP_BYTES` was already clamped. But (a) a negative or zero `abort_margin_bytes` turned the hard cap into a soft one, and (b) `--config` with a different `paths.ledger` started again from 0 bytes. Now there is a 1 MB margin floor in code, and the CLI refuses any ledger other than `research/probes/traffic_ledger.json` unless `PROBE_ALLOW_ALT_LEDGER=1` is set (tests only). |
| 3 | TLS correctness | PASS | `ssl.create_default_context()` gives CERT_REQUIRED and check_hostname, with no verify=False path (`--ca-file` replaces the trust store but still verifies). `wrap_bio(server_hostname=host)` sets SNI and checks the hostname. ALPN is http/1.1. http.client handles chunked. The client decodes gzip, deflate (zlib and raw) and br. Truncated gzip yields a partial decode. |
| 4 | Credential safety | **FIXED** | User, pass and Basic token were redacted everywhere (errors, log, results, summary) and `Proxy-Authorization` is never stored. Gaps: the CLI printed `DECODO_HOST`, connect errors carried the gateway host into results.jsonl, and the sticky-username Basic token was not registered. All three are fixed. |
| 5 | Classifier | **FIXED** | Vendor (`antibot`/`cdn`) and outcome are separate. `cf-ray` or `__cf_bm` on a 200 page that passes the predicate gives `ok`. A bare word "captcha" is never matched. Bugs: (a) Cloudflare now injects JSD on normal pages under `/cdn-cgi/challenge-platform/h/<x>/scripts/jsd/...`, which matched the `/challenge-platform/h/` challenge marker, so ordinary pages were flagged `challenge: true`; (b) Cloudflare 52x and Akamai 5xx edge error pages matched the block-page markers, so origin outages counted as blocks. |
| 6 | Cost formula | PASS | `bytes_per_row * 1000 / 1e9 * usd_per_GB`. Decimal GB is used everywhere (cap 500e6, price per 1e9). If Decodo bills GiB, these figures overstate cost by 7%, which is the conservative side. With rows = 0, cost is None and the verdict is KILL ("no rows extracted"). The thresholds match the README and config: block > 20%, $/1k > 0.50, errors > 30%, fewer than 20 requests gives INCOMPLETE. |
| 6b | Verdict precedence | **FIXED** | A 407 on request 1 (or a cap stop after a few samples) gave KILL from 1–3 requests. INCOMPLETE now takes precedence when fewer than `min_requests_for_verdict` requests ran, and the reasons are listed as "would KILL: ...". |
| 7 | README first-run order | PASS (tweaked) | The order is health, then sticky health, then smoke run, then validate, plan and run. I added a no-network `plan` before the smoke run. `--dry-run` and `plan` are documented. |
| 8 | Ledger / PROBES.md state | PASS | Ledger is at 0 bytes with no runs, cap 500,000,000. PROBES.md has an empty table and labels the price UNVERIFIED. `*.lock` is gitignored, and so is the new `.run.lock`. |

## Fixes (each with a regression test)

| Fix | Files | Test |
|---|---|---|
| URL parse and scheme check moved inside `fetch()`'s try, giving a new `invalid` error kind. `urljoin` failure stops redirect-following but keeps the bytes. | wire.py, runner.py | `test_fetch_never_raises_on_bad_url`, `test_bad_redirect_location_is_recorded_not_lost` |
| Ctrl-C is caught in `fetch()` (`interrupted`), recorded by the runner and health check, then re-raised | wire.py, runner.py | `test_ctrl_c_mid_request_still_records_bytes` |
| `Ledger.exclusive_run()` non-blocking run lock, raising `LedgerBusy` (a `BudgetRefused`, exit 3) | ledger.py, runner.py | `test_concurrent_run_is_refused` |
| `abort_margin()` floor of 1 MB (or cap/10 for tiny test caps), used by plan, run and health | runner.py, ledger.py | `test_abort_margin_cannot_be_configured_away` |
| CLI refuses a non-canonical ledger path unless `PROBE_ALLOW_ALT_LEDGER=1` | `__main__.py` | `test_cli_refuses_alternate_ledger_without_opt_in` (the existing CLI test now opts in) |
| INCOMPLETE takes precedence over KILL when fewer than 20 requests ran | runner.py | `test_proxy_auth_failure_is_incomplete_not_kill` |
| Cloudflare JSD at `/h/<x>/scripts/jsd/` is now antibot, and only `.../orchestrate/` counts as a challenge (new `body_re` rule type) | classify.py | `test_cloudflare_jsd_on_normal_page_is_antibot_not_challenge` |
| `cf-error-details` / `errors.edgesuite.net` on 5xx count as CDN presence, not a block | classify.py | `test_cloudflare_5xx_edge_error_is_server_error_not_block` |
| `DECODO_HOST` is redacted and no longer printed. The sticky username's Basic token is registered with the redactor. | creds.py, `__main__.py`, runner.py | `test_host_is_redacted`, `test_sticky_basic_token_is_redacted`, CLI test asserts no host in output |
| Ledger `fsync` before `os.replace`. The config comment now says the block rate is over responses, not sent. README updated (56 tests, budget rules 5–7, verdict precedence, plan step). | ledger.py, config.yaml, README.md | (covered by the existing ledger tests) |

## Residual risks (not fixed)

1. **Unverified live behaviour.** Prices, gateway host and port, sticky username format and IP-echo shape all come from search summaries. Nothing has touched Decodo. The first `health` run is the real test.
2. **Bytes the client never sees.** After an early abort (RST), in-flight data and data in the gateway's send buffer are invisible. The 1 MB margin is a guess. Compare the ledger with the Decodo dashboard after the smoke run, and treat a difference above 5% as a blocker.
3. **Ledger deletion.** If `traffic_ledger.json` is deleted or reverted, the budget resets to 0. Git history is the only defence: commit the ledger after every live session. Code edits can bypass any in-code cap.
4. **`per_probe_max_bytes` is per run, not cumulative per candidate.** Re-running one candidate many times can spend more than 25 MB on it. The project cap still holds.
5. **`--upstream env` sends the Decodo Proxy-Authorization in plaintext through the upstream egress proxy**, which is inherent to HTTP-proxy chaining. Only chain through a trusted proxy.
6. **Error-dominated runs are still KILL.** A gateway outage across all 30 requests gives KILL via "error rate" or "no rows", per spec. Re-check any KILL whose only reasons are errors.
7. **Fingerprint gap.** The client uses Python TLS over HTTP/1.1. A KILL on Akamai, Kasada or DataDome means "not reachable with a plain client", as the README says.
8. **Brotli has no decompressed-size cap** (gzip and deflate cap at 50 MB). This is low risk with the 5 MB compressed limit.
9. **SIGTERM / SIGKILL** mid-request still loses that one request's bytes (at most about 5 MB, within the margin plus reserve).
