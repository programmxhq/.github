"""CLI: run from research/tools with `python -m probe <command>`.

  health    [--count N] [--sticky]                 exit IP + latency through Decodo
  plan      DEF...  [-n N]                          byte projection vs remaining budget (no network)
  validate  DEF...                                  check definition files (no network)
  run       DEF...  [-n N] [--session rotating|sticky] [--baseline] [--dry-run]
  ledger                                            show Decodo traffic used / remaining
  report                                            regenerate research/probes/PROBES.md
Common: --config PATH, --upstream host:port|env (chain through an HTTP proxy first)
"""
from __future__ import annotations

import argparse
import json
import sys

from .creds import REDACTOR, load_credentials
from .definition import DefinitionError, load_definition
from .ledger import BudgetRefused, Ledger
from .runner import (ProbeAbort, cfg_path, health_check, load_config, plan, run_probe,
                     upstream_from_arg, write_probes_md)


def _creds_or_die():
    creds = load_credentials()
    if creds is None:
        print("error: Decodo credentials missing. Set DECODO_USER, DECODO_PASS, DECODO_HOST "
              "(host may include :port) in env or repo-root .env", file=sys.stderr)
        sys.exit(2)
    print(f"[creds] loaded from {creds.source}; gateway {creds.host}:{creds.port}")
    return creds


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="python -m probe", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config", default=None)
    ap.add_argument("--upstream", default=None, help="chain via HTTP proxy host:port, or 'env' for $HTTPS_PROXY")
    ap.add_argument("--ca-file", default=None, help=argparse.SUPPRESS)  # tests / custom CA only
    sub = ap.add_subparsers(dest="cmd", required=True)
    h = sub.add_parser("health")
    h.add_argument("--count", type=int, default=1)
    h.add_argument("--sticky", action="store_true")
    for name in ("plan", "validate", "run"):
        sp = sub.add_parser(name)
        sp.add_argument("definitions", nargs="+")
        if name in ("plan", "run"):
            sp.add_argument("-n", type=int, default=None, help="requests (clamped to 20..50)")
        if name == "run":
            sp.add_argument("--session", choices=["rotating", "sticky"], default=None)
            sp.add_argument("--baseline", action="store_true", help="also 3 direct (no-proxy) requests")
            sp.add_argument("--dry-run", action="store_true")
    sub.add_parser("ledger")
    sub.add_parser("report")
    a = ap.parse_args(argv)
    cfg = load_config(a.config)
    try:
        if a.cmd == "health":
            creds = _creds_or_die()
            res = health_check(cfg, creds, count=a.count, sticky=a.sticky,
                               upstream=upstream_from_arg(a.upstream, cfg), ca_file=a.ca_file)
            return 0 if any(r and r["exit_ip"] for r in res) else 1
        if a.cmd == "ledger":
            snap = Ledger(cfg_path(cfg, "ledger"), cfg["budget"]["cap_bytes"]).snapshot()
            snap["remaining_bytes"] = max(0, snap["cap_bytes"] - snap["proxy_bytes_total"])
            snap["runs"] = snap["runs"][-10:]
            print(json.dumps(snap, indent=2))
            return 0
        if a.cmd == "report":
            print(write_probes_md(cfg))
            return 0
        defs = []
        for d in a.definitions:
            try:
                defs.append(load_definition(d))
            except (DefinitionError, OSError, ValueError) as e:
                print(f"error: {d}: {e}", file=sys.stderr)
                return 2
        if a.cmd == "validate":
            for d in defs:
                print(f"ok  {d.name}: {len(d.urls)} URLs, extract={d.extract.get('type')}"
                      + "".join(f"\n    warn: {w}" for w in d.warnings))
            return 0
        if a.cmd == "plan":
            total = 0
            for d in defs:
                p = plan(d, cfg, a.n)
                total += p["projected_bytes"]
                print(f"{d.name}: n={p['n']} est={p['est_bytes_per_request']:,} B/req ({p['estimate_basis']}) "
                      f"projected={p['projected_bytes']:,} B fits={p['fits']}")
            snap = Ledger(cfg_path(cfg, "ledger"), cfg["budget"]["cap_bytes"]).snapshot()
            rem = snap["cap_bytes"] - snap["proxy_bytes_total"]
            print(f"TOTAL projected {total:,} B; remaining budget {rem:,} B -> {'OK' if total <= rem else 'OVER BUDGET'}")
            return 0
        if a.cmd == "run":
            creds = None if a.dry_run else _creds_or_die()
            rc = 0
            for d in defs:
                try:
                    s = run_probe(d, cfg, creds, n=a.n, session=a.session, baseline=a.baseline,
                                  dry_run=a.dry_run, upstream=upstream_from_arg(a.upstream, cfg), ca_file=a.ca_file)
                except BudgetRefused as e:
                    print(f"REFUSED {d.name}: {e}", file=sys.stderr)
                    rc = 3
                    continue
                if s.get("dry_run"):
                    print(json.dumps(s, indent=2))
                    continue
                print(f"== {d.name}: {s['verdict']} block={s['block_rate']} ok={s['ok']}/{s['requests_sent']} "
                      f"bytes/row={s['bytes_per_row']} $/1k={s['cost_per_1k_rows_usd'].get(s['price_primary'])} "
                      f"reasons={s['verdict_reasons']}")
                if s.get("stopped_reason") == "cap":
                    print("Decodo cap reached; stopping all probes.", file=sys.stderr)
                    return 4
            return rc
    except (ProbeAbort, BudgetRefused) as e:
        print(f"error: {REDACTOR.redact(e)}", file=sys.stderr)
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
