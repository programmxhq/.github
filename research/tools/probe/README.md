# Phase 5 probe harness (Decodo residential)

Sends 20 to 50 real requests per candidate through Decodo and records block rate, anti-bot
vendor, bytes per row and cost per 1,000 rows. Verdict is PASS or KILL. All Decodo bytes are
counted on the wire and added to a persistent ledger that enforces the **500 MB project cap**.

Built offline on 2026-10-03, when egress blocked Decodo. **Nothing here has touched the real
gateway yet.** Every Decodo-specific fact below is UNVERIFIED until the health check passes.

## One-time setup (live session)

```bash
cd /home/user/.github            # repo root
pip install -r research/tools/probe/requirements.txt
# Credentials: env vars, or KEY=VALUE lines in the repo-root .env (gitignored). Never commit them.
export DECODO_USER='...'  DECODO_PASS='...'  DECODO_HOST='gate.decodo.com:7000'
cd research/tools                # every command below runs from here
python -m pytest probe/tests -q  # 56 offline tests, ~6 s
```

## Run order

```bash
# 1. Proxy health: exit IP, country, latency, bytes. Checks creds, host:port and CONNECT egress.
python -m probe health
python -m probe health --sticky --count 3      # should report "kept the same IP"
#    If direct egress to the gateway is blocked but an HTTP egress proxy exists, chain it:
python -m probe --upstream env health          # uses $HTTPS_PROXY as the first hop

# 2. Harness smoke test on a public scraping sandbox (~2 MB total). Confirms the maths.
python -m probe plan probe/definitions/books-toscrape-smoke.yaml probe/definitions/quotes-toscrape-api-smoke.yaml  # no network
python -m probe run probe/definitions/books-toscrape-smoke.yaml probe/definitions/quotes-toscrape-api-smoke.yaml

# 3. Candidates: write one definition each (copy probe/definitions/_TEMPLATE.yaml), then
python -m probe validate probe/definitions/*.yaml        # no network
python -m probe plan probe/definitions/<cand>*.yaml      # projected bytes vs remaining budget
python -m probe run probe/definitions/<cand>.yaml --baseline   # 30 requests + 3 direct baseline
python -m probe run probe/definitions/<cand>.yaml -n 50 --session sticky

python -m probe ledger      # Decodo bytes used / remaining, last 10 runs
python -m probe report      # rebuild research/probes/PROBES.md from every summary.json
```

Exit codes: 0 ok, 2 bad definition or missing creds, 3 refused by budget, 4 cap hit mid-run
(all later probes in that command are skipped).

## Outputs

| Path | Contents |
|---|---|
| `research/probes/<name>/results.jsonl` | One line per request, appended per run (`run_id`): status, outcome, rows, vendors and signals, wire/HTTP/body bytes, latency, redacted error. No credentials; the sticky `session_id` is random. |
| `research/probes/<name>/summary.json` | Latest run: block/error/success rates, vendors, median and p90 bytes/request, rows/request, bytes/row, cost per 1k rows for every price tier, verdict and reasons, baseline. |
| `research/probes/PROBES.md` | One row per candidate (latest run), regenerated on every run. |
| `research/probes/traffic_ledger.json` | Cumulative Decodo bytes, per probe and per run. Commit it. Never hand-edit it to free budget. |
| `research/logs/probe-agent.md` | `probe-runner` start/end rows per run. |

## How it measures

- **Bytes** = every byte written to or read from the TCP socket to the gateway: the CONNECT
  exchange (with Proxy-Authorization), the TLS handshake and the encrypted records, which carry
  the *compressed* body. TLS runs over `ssl.MemoryBIO`, so the counts are exact. The offline
  tests check they match, byte for byte, what a local proxy saw. TCP/IP headers are not
  counted. Each request uses a fresh connection (`Connection: close`), so the handshake cost is
  paid every time. Keep-alive scrapers spend less, so read the cost figure as an upper bound.
- **Why not requests/httpx**: they hide TLS inside the socket, so the encrypted bytes Decodo
  bills cannot be seen from Python. The client is stdlib `http.client` on a counting socket.
- **Outcomes** per response: `ok` (the success predicate passed; markers are recorded but
  ignored), `challenge`, `captcha`, `block_page`, `blocked_status` (401/403/429/451, or 503 with
  vendor evidence), `empty` (2xx but no rows: soft block, login wall or layout drift),
  `not_found`, `server_error`, `error` (network/proxy/TLS/timeout).
- **Block rate** = (challenge + captcha + block_page + blocked_status + empty) / responses.
  Network errors are excluded and reported as `error_rate`. `hard_block_rate` excludes `empty`.
- **Bytes/row** = all proxied bytes in the run, including blocked and failed requests, divided
  by rows from `ok` responses. **Cost per 1k rows** = `bytes_per_row * 1000 / 1e9 * price_per_GB`.
- **Verdict** (`config.yaml: verdict`): INCOMPLETE if fewer than 20 requests ran (for example,
  the run stopped at the cap or on a 407); any KILL reasons are listed as "would KILL". Else KILL
  if block rate > 20%, cost/1k rows > $0.50 at the `primary` price, error rate > 30%, or zero
  rows. Otherwise PASS.
- **Vendors** (`classify.py`, sources cited inline): Cloudflare, Akamai, DataDome,
  PerimeterX/HUMAN, Imperva/Incapsula, Kasada, AWS WAF, F5/Shape, Fastly (CDN only),
  reCAPTCHA, hCaptcha, Turnstile, Arkose and GeeTest. CDN presence (`cf-ray`, `x-served-by`)
  is reported separately from bot management (`__cf_bm`, `_abck`, `datadome`...).

## Budget safety

1. **Before a run**: projected = n x estimated bytes/request x 1.25. The estimate comes from
   the definition's `expected_bytes_per_request`, else the previous run's p90, else 400 KB.
   The run is refused if projected + 1 MB abort margin + used > cap, or if projected >
   `per_probe_max_bytes` (25 MB).
2. **During a run**: each request may use at most (cap - used - margin) bytes. The client stops
   reading at that limit, counts any data already buffered in the kernel as billed, and resets
   the connection. The run stops once less than `min_reserve_bytes` remains.
3. The ledger is updated after every request under a file lock, so a crash loses at most one
   request. `ledger.HARD_CAP_BYTES = 500_000_000` (decimal MB) is enforced in code, and config
   can only lower it.
4. Health checks are billed and recorded under `_health`.
5. Only one proxied run or health check at a time: each takes a non-blocking lock
   (`traffic_ledger.json.run.lock`, gitignored) and a second one is refused, because two runs
   would otherwise both spend the same per-request headroom.
6. `abort_margin_bytes` has a 1 MB floor in code. The CLI refuses a `--config` whose ledger path is
   not `research/probes/traffic_ledger.json` (a fresh ledger would start at zero); only the
   offline tests set `PROBE_ALLOW_ALT_LEDGER=1`.
7. Ctrl-C during a request is caught long enough to record that request's bytes, then re-raised.

## UNVERIFIED (confirm in the live session)

- **Prices** (`config.yaml: pricing`, `verified: false`): PAYG $4.00/GB (primary). Plans:
  $3.75 (3 GB), $3.50 (10 GB), $3.25 (25 GB), $2.75 (100 GB). Enterprise: $2.50 (250 GB),
  $2.00 (1 TB). These come from WebSearch summaries of decodo.com and third-party reviews on
  2026-10-03. Check them at https://decodo.com/proxies/residential-proxies/pricing, then set
  the real plan as `primary`, set `verified: true` and run `python -m probe report`.
- **Gateway**: `gate.decodo.com:7000`, an HTTP proxy that is rotating by default. Sticky
  sessions use the username `user-<USER>-session-<id>-sessionduration-<min>`. If sticky
  auth fails with 407, the prefix rule is wrong; see `creds.proxy_username`. Decodo also sells
  per-port sticky endpoints (10001+), and `DECODO_HOST=host:port` accepts those as-is.
- **IP echo**: `https://ip.decodo.com/json`, with `api.ipify.org` as a fallback. The JSON
  shape is unknown, so the parser looks for any `ip` key.
- **Vendor markers**: these come from search summaries. Check them against real responses
  (the `signals` field in results.jsonl).

## Open questions and risks

- **Container egress**: can this container open a TCP connection to `gate.decodo.com:7000`
  (a non-443 port)? If outbound traffic must go through the agent egress proxy, that proxy has
  to allow `CONNECT gate.decodo.com:7000` and must not intercept TLS on it, because the inner
  hop is plaintext CONNECT. `--upstream env` chains through it, but this has only been tested
  against a local stub. `python -m probe health` answers the question in one request.
- **Fingerprint gap**: requests use Python's TLS (JA3/JA4) over HTTP/1.1 with Chrome headers,
  not a real browser. Strict Akamai, Kasada or DataDome sites may block this client but let a
  browser-TLS client (got-scraping, curl-impersonate) through. A KILL on a TLS-fingerprinting
  vendor means "not reachable with a plain HTTP client", not "unreachable".
- **Residential variance**: with no country targeting, exit IPs can come from anywhere, and
  geo-dependent sites will show that as `empty` or redirects. Check `final_url` and samples.
- **Billing granularity**: Decodo may round per request or count overheads differently. Once
  real runs exist, compare `ledger` against the dashboard and adjust if they differ by > 5%.

## Layout

`creds.py` loads credentials and redacts them. `wire.py` is the counting HTTP client.
`classify.py` does vendor fingerprints and outcomes. `extract.py` counts rows and evaluates
the success predicate. `definition.py` validates definitions (public only: no auth or cookie
headers, no `user:pass@` URLs). `ledger.py` holds the budget. `runner.py` runs probes, writes
summaries and PROBES.md, and does the health check. `__main__.py` is the CLI. `tests/` holds a
fixture origin (HTTP and HTTPS with a throwaway cert), a stub forward proxy that counts bytes,
and 56 tests.
