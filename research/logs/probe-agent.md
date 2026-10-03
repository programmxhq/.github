# probe-agent log

All times UTC.

| Time | Agent | Event |
|---|---|---|
| 2026-10-03 11:39 | probe-agent (opus) | Started Phase 5 probe tooling build in research/tools/probe/. |
| 2026-10-03 11:56 | probe-agent (opus) | WebSearch: Decodo prices (PAYG $4/GB; plans $3.75-$2.75/GB; enterprise $2.50-$2/GB), gateway gate.decodo.com:7000, sticky user-<u>-session-<id>-sessionduration-<m>, ip.decodo.com/json; anti-bot markers for CF/Akamai/DataDome/PX/Imperva/Kasada/AWS WAF/F5/Fastly. All UNVERIFIED, cited in config.yaml and classify.py. |
| 2026-10-03 11:56 | probe-agent (opus) | Built research/tools/probe: stdlib http.client over ssl.MemoryBIO counting socket (exact CONNECT+TLS wire bytes), classifier, extractor (json/json_in_html/css/regex), ledger with 500 MB hard cap + 1 MB abort margin, runner, health check, CLI, PROBES.md generator. |
| 2026-10-03 11:56 | probe-agent (opus) | Finding: aborting a read early leaves gateway-sent bytes unread (billed but invisible). Mitigated: SO_RCVBUF 128 KB on proxy sockets, count kernel-buffered bytes, RST close, cap headroom (abort_margin_bytes). |
| 2026-10-03 11:56 | probe-agent (opus) | Tests: 45 passed offline (pytest probe/tests, ~5 s, 3 consecutive green runs). Local HTTPS fixture origin + stub forward proxy; client byte counts equal proxy-observed bytes exactly. |
| 2026-10-03 11:56 | probe-agent (opus) | Initialised research/probes/traffic_ledger.json (0 B used) and PROBES.md (empty table). Added .pytest_cache/ and research/probes/*.lock to .gitignore. No commits made. |
| 2026-10-03 11:56 | probe-agent (opus) | Open question: whether container egress permits CONNECT to gate.decodo.com:7000 (non-443); --upstream env chaining built but only stub-tested. |
