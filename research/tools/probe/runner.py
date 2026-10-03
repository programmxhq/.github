"""Probe runner, summaries, PROBES.md and the proxy health check."""
from __future__ import annotations

import json
import os
import random
import statistics
import time
import uuid
from collections import Counter
from pathlib import Path
from urllib.parse import urljoin, urlsplit

import yaml

from . import classify as C
from .creds import REDACTOR, REPO_ROOT, Credentials, new_session_id, proxy_username
from .definition import ProbeDefinition
from .extract import check_success, extract
from .ledger import BudgetRefused, Ledger
from .wire import FetchResult, ProxySpec, fetch

CONFIG_PATH = Path(__file__).resolve().parent / "config.yaml"
REDIRECTS = {301, 302, 303, 307, 308}


class ProbeAbort(Exception):
    pass


# ---------------------------------------------------------------- config / paths

def load_config(path: str | Path | None = None) -> dict:
    with open(path or CONFIG_PATH, encoding="utf-8") as f:
        return yaml.safe_load(f)


def cfg_path(cfg: dict, key: str, repo_root: Path = REPO_ROOT) -> Path:
    p = Path(cfg["paths"][key])
    return p if p.is_absolute() else repo_root / p


def utc_now(fmt: str = "%Y-%m-%dT%H:%M:%SZ") -> str:
    return time.strftime(fmt, time.gmtime())


def log_event(cfg: dict, event: str, repo_root: Path = REPO_ROOT) -> None:
    path = cfg_path(cfg, "log", repo_root)
    path.parent.mkdir(parents=True, exist_ok=True)
    new = not path.exists()
    with open(path, "a", encoding="utf-8") as f:
        if new:
            f.write("# probe-agent log\n\nAll times UTC.\n\n| Time | Agent | Event |\n|---|---|---|\n")
        f.write(f"| {utc_now('%Y-%m-%d %H:%M')} | probe-runner | {REDACTOR.redact(event).replace('|', '/')} |\n")


def upstream_from_arg(arg: str | None, cfg: dict) -> ProxySpec | None:
    val = arg if arg is not None else (cfg.get("proxy", {}).get("upstream") or "")
    if val == "env":
        val = os.environ.get("HTTPS_PROXY") or os.environ.get("https_proxy") or ""
    if not val:
        return None
    parts = urlsplit(val if "://" in val else f"http://{val}")
    return ProxySpec(parts.hostname or "", parts.port or 80, parts.username, parts.password)


def proxy_for(creds: Credentials, session_id: str | None, duration: int | None) -> ProxySpec:
    return ProxySpec(creds.host, creds.port, proxy_username(creds.user, session_id, duration), creds.password)


# ---------------------------------------------------------------- one request (+redirects)

def fetch_follow(url: str, *, defn: ProbeDefinition, proxy, upstream, timeout, max_body, byte_limit,
                 max_redirects: int, ca_file: str | None) -> tuple[FetchResult, dict]:
    method, body = defn.method, defn.body.encode() if defn.body else None
    acc = {"wire_sent": 0, "wire_recv": 0, "app_sent": 0, "app_recv": 0, "redirects": 0, "elapsed_ms": 0.0}
    cur = url
    while True:
        limit = None if byte_limit is None else byte_limit - acc["wire_sent"] - acc["wire_recv"]
        r = fetch(cur, method=method, headers=defn.headers, body=body, proxy=proxy, upstream=upstream,
                  timeout=timeout, max_body_bytes=max_body, byte_limit=limit, ca_file=ca_file)
        for k in ("wire_sent", "wire_recv", "app_sent", "app_recv"):
            acc[k] += getattr(r, k)
        acc["elapsed_ms"] += r.elapsed_ms
        loc = r.header("location")
        if (defn.follow_redirects and not r.error and r.status in REDIRECTS and loc
                and acc["redirects"] < max_redirects):
            acc["redirects"] += 1
            cur = urljoin(cur, loc)
            if r.status in (301, 302, 303) and method == "POST":
                method, body = "GET", None
            continue
        acc["final_url"] = cur
        return r, acc


def evaluate(r: FetchResult, defn: ProbeDefinition) -> dict:
    rows, sample, xerr = (0, [], None)
    if r.status is not None and not r.error:
        rows, sample, xerr = extract(r.body, defn.extract, r.header("content-type") or "")
    ok = (not r.error) and check_success(r.status, r.body, rows, defn.success)
    fp = C.fingerprint(r.status, r.headers, r.body)
    outcome = C.classify(error_kind=r.error_kind, status=r.status, fp=fp, rows=rows, success=ok)
    return {"rows": rows if ok else 0, "rows_seen": rows, "sample": sample if ok else [], "extract_error": xerr,
            "success": ok, "fp": fp.to_json(), "outcome": outcome}


def record_for(run_id, i, mode, session, session_id, url, r: FetchResult, acc: dict, ev: dict) -> dict:
    wire_total = acc["wire_sent"] + acc["wire_recv"]
    return {
        "run_id": run_id, "i": i, "ts": utc_now(), "mode": mode, "session": session,
        "session_id": session_id, "url": url, "final_url": acc.get("final_url", url),
        "redirects": acc["redirects"], "status": r.status, "outcome": ev["outcome"],
        "success": ev["success"], "rows": ev["rows"], "rows_seen": ev["rows_seen"],
        "antibot": ev["fp"]["antibot"], "cdn": ev["fp"]["cdn"], "captcha": ev["fp"]["captcha"],
        "challenge": ev["fp"]["challenge"], "signals": ev["fp"]["signals"],
        "bytes_wire_total": wire_total, "bytes_wire_sent": acc["wire_sent"], "bytes_wire_recv": acc["wire_recv"],
        "bytes_http_sent": acc["app_sent"], "bytes_http_recv": acc["app_recv"],
        "resp_header_bytes": r.resp_header_bytes, "body_compressed_bytes": r.body_compressed_bytes,
        "body_decoded_bytes": r.body_decoded_bytes, "content_encoding": r.content_encoding,
        "truncated": r.truncated, "decode_error": r.decode_error,
        "elapsed_ms": round(acc["elapsed_ms"], 1), "ttfb_ms": round(r.ttfb_ms, 1) if r.ttfb_ms else None,
        "error_kind": r.error_kind, "error": REDACTOR.redact(r.error) if r.error else None,
        "extract_error": ev["extract_error"], "sample": ev["sample"],
    }


# ---------------------------------------------------------------- summary / verdict

def _median(xs):
    return statistics.median(xs) if xs else None


def _pct(xs, q):
    if not xs:
        return None
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(round(q * (len(xs) - 1))))]


def summarize(defn: ProbeDefinition, cfg: dict, records: list[dict], meta: dict) -> dict:
    prox = [r for r in records if r["mode"] == "proxy"]
    base = [r for r in records if r["mode"] == "direct"]
    sent = len(prox)
    outcomes = Counter(r["outcome"] for r in prox)
    errors = outcomes.get("error", 0)
    responded = sent - errors
    blocks = sum(outcomes.get(o, 0) for o in C.BLOCK_OUTCOMES)
    hard = sum(outcomes.get(o, 0) for o in C.HARD_BLOCK_OUTCOMES)
    ok = outcomes.get("ok", 0)
    total_bytes = sum(r["bytes_wire_total"] for r in prox)
    rows_total = sum(r["rows"] for r in prox)
    okb = [r["bytes_wire_total"] for r in prox if r["success"]]
    allb = [r["bytes_wire_total"] for r in prox]
    bytes_per_row = (total_bytes / rows_total) if rows_total else None
    prices = cfg["pricing"]["usd_per_gb"]
    primary = cfg["pricing"]["primary"]
    cost = {k: (round(bytes_per_row * 1000 / 1e9 * v, 5) if bytes_per_row else None) for k, v in prices.items()}
    vend = Counter(v for r in prox for v in r["antibot"])
    cdn = Counter(v for r in prox for v in r["cdn"])
    cap = Counter(v for r in prox for v in r["captcha"])
    v = cfg["verdict"]
    block_rate = (blocks / responded) if responded else None
    error_rate = (errors / sent) if sent else None
    kill = []
    if sent and rows_total == 0:
        kill.append("no rows extracted")
    if block_rate is not None and block_rate > v["max_block_rate"]:
        kill.append(f"block rate {block_rate:.0%} > {v['max_block_rate']:.0%}")
    if cost.get(primary) is not None and cost[primary] > v["max_cost_per_1k_rows_usd"]:
        kill.append(f"cost/1k rows ${cost[primary]:.3f} > ${v['max_cost_per_1k_rows_usd']:.2f}")
    if error_rate is not None and error_rate > v["max_error_rate"]:
        kill.append(f"error rate {error_rate:.0%} > {v['max_error_rate']:.0%}")
    if kill:
        verdict = "KILL"
    elif sent < v["min_requests_for_verdict"]:
        verdict = "INCOMPLETE"
        kill.append(f"only {sent} requests completed (stopped: {meta.get('stopped_reason')})")
    else:
        verdict = "PASS"
    notes = []
    med_ok_rows = _median([r["rows"] for r in prox if r["success"]])
    if defn.rows_per_page_expected and med_ok_rows is not None and med_ok_rows < 0.5 * defn.rows_per_page_expected:
        notes.append(f"median rows/ok page {med_ok_rows} < 50% of expected {defn.rows_per_page_expected}: check extractor")
    if not cfg["pricing"].get("verified"):
        notes.append("cost uses UNVERIFIED price")
    return {
        "name": defn.name, "candidate_ref": defn.candidate_ref, "definition": str(defn.path or ""),
        **meta,
        "requests_sent": sent, "ok": ok, "outcomes": dict(outcomes),
        "block_rate": round(block_rate, 4) if block_rate is not None else None,
        "hard_block_rate": round(hard / responded, 4) if responded else None,
        "error_rate": round(error_rate, 4) if error_rate is not None else None,
        "success_rate": round(ok / sent, 4) if sent else None,
        "antibot_vendors": dict(vend), "cdn_vendors": dict(cdn), "captcha_vendors": dict(cap),
        "total_proxy_bytes": total_bytes,
        "median_bytes_per_request": _median(allb), "p90_bytes_per_request": _pct(allb, 0.9),
        "median_bytes_per_ok_request": _median(okb),
        "rows_total": rows_total, "rows_per_request": round(rows_total / sent, 3) if sent else None,
        "median_rows_per_ok_request": med_ok_rows, "rows_per_page_expected": defn.rows_per_page_expected,
        "bytes_per_row": round(bytes_per_row, 1) if bytes_per_row else None,
        "bytes_per_row_basis": "all proxied bytes (incl. blocked/failed requests) / rows from ok responses",
        "cost_per_1k_rows_usd": cost, "price_primary": primary,
        "price_usd_per_gb": prices[primary], "price_verified": bool(cfg["pricing"].get("verified")),
        "median_latency_ms": _median([r["elapsed_ms"] for r in prox if not r["error_kind"]]),
        "verdict": verdict, "verdict_reasons": kill, "thresholds": v, "notes": notes + defn.warnings,
        "baseline": {
            "requests": len(base), "outcomes": dict(Counter(r["outcome"] for r in base)),
            "statuses": [r["status"] for r in base],
            "median_bytes_per_request": _median([r["bytes_wire_total"] for r in base]),
            "antibot_vendors": sorted({x for r in base for x in r["antibot"]}),
        } if base else None,
    }


def _fmt_bytes(n) -> str:
    if n is None:
        return "-"
    n = float(n)
    for unit in ("B", "KB", "MB", "GB"):
        if n < 1000 or unit == "GB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1000
    return str(n)


def write_probes_md(cfg: dict, repo_root: Path = REPO_ROOT) -> Path:
    probes_dir = cfg_path(cfg, "probes_dir", repo_root)
    out = cfg_path(cfg, "probes_md", repo_root)
    ledger = Ledger(cfg_path(cfg, "ledger", repo_root), cfg["budget"]["cap_bytes"])
    snap = ledger.snapshot()
    rows = []
    for sp in sorted(probes_dir.glob("*/summary.json")):
        s = json.loads(sp.read_text(encoding="utf-8"))
        pk = s.get("price_primary")
        c = (s.get("cost_per_1k_rows_usd") or {}).get(pk)
        vend = ", ".join(sorted(s.get("antibot_vendors") or {})) or "none"
        cdn = ", ".join(sorted(s.get("cdn_vendors") or {}))
        if cdn:
            vend += f" (cdn: {cdn})"
        br = s.get("block_rate")
        rows.append(
            f"| {s['name']} | {s.get('ended', '')[:16]} | {s.get('session', '')} | {s['requests_sent']} | {s['ok']} | "
            f"{'-' if br is None else f'{br:.0%}'} | {vend} | {_fmt_bytes(s.get('median_bytes_per_request'))} | "
            f"{s.get('rows_per_request') if s.get('rows_per_request') is not None else '-'} | "
            f"{_fmt_bytes(s.get('bytes_per_row'))} | {'-' if c is None else f'${c:.4f}'} | **{s['verdict']}** | "
            f"{'; '.join(s.get('verdict_reasons') or []) or '-'} |")
    price = cfg["pricing"]["usd_per_gb"][cfg["pricing"]["primary"]]
    text = [
        "# Phase 5 reachability probes (Decodo residential)",
        "",
        f"Generated {utc_now('%Y-%m-%d %H:%M')} UTC by research/tools/probe. One row per candidate (latest run).",
        f"Decodo traffic used: {_fmt_bytes(snap['proxy_bytes_total'])} of {_fmt_bytes(snap['cap_bytes'])} cap "
        f"({snap['proxy_requests_total']} proxied requests).",
        f"Cost column uses `{cfg['pricing']['primary']}` = ${price:.2f}/GB"
        f"{'' if cfg['pricing'].get('verified') else ' (UNVERIFIED price)'}. "
        "Bytes are on-the-wire (CONNECT + TLS + compressed HTTP), one connection per request.",
        f"Verdict: KILL if block rate > {cfg['verdict']['max_block_rate']:.0%}, cost/1k rows > "
        f"${cfg['verdict']['max_cost_per_1k_rows_usd']:.2f}, error rate > {cfg['verdict']['max_error_rate']:.0%}, or no rows.",
        "",
        "| Candidate | Run (UTC) | Session | Req | OK | Block rate | Anti-bot vendor(s) | Median B/req | Rows/req | B/row | $/1k rows | Verdict | Reasons |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|",
        *rows,
        "",
    ]
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(text), encoding="utf-8")
    return out


# ---------------------------------------------------------------- run

def plan(defn: ProbeDefinition, cfg: dict, n: int | None = None, repo_root: Path = REPO_ROOT) -> dict:
    rq, b = cfg["requests"], cfg["budget"]
    n = int(n or defn.requests or rq["default"])
    n = max(rq["min"], min(rq["max"], n))
    est, basis = defn.expected_bytes_per_request, "definition"
    prior = cfg_path(cfg, "probes_dir", repo_root) / defn.name / "summary.json"
    if not est and prior.exists():
        try:
            est = json.loads(prior.read_text())["p90_bytes_per_request"]
            basis = "previous run p90"
        except Exception:
            est = None
    if not est:
        est, basis = b["default_expected_bytes_per_request"], "config default"
    projected = int(n * est * b["projection_safety_factor"])
    ledger = Ledger(cfg_path(cfg, "ledger", repo_root), b["cap_bytes"])
    used = ledger.used()
    return {"n": n, "est_bytes_per_request": int(est), "estimate_basis": basis, "projected_bytes": projected,
            "per_probe_max_bytes": b["per_probe_max_bytes"], "ledger_used": used, "cap": ledger.cap,
            "remaining": max(0, ledger.cap - used),
            "fits": projected <= b["per_probe_max_bytes"] and used + projected + int(b.get("abort_margin_bytes", 0)) <= ledger.cap}


def run_probe(
    defn: ProbeDefinition,
    cfg: dict,
    creds: Credentials | None,
    *,
    n: int | None = None,
    session: str | None = None,
    baseline: bool = False,
    dry_run: bool = False,
    upstream: ProxySpec | None = None,
    ca_file: str | None = None,
    repo_root: Path = REPO_ROOT,
    sleep=time.sleep,
    log=print,
) -> dict:
    rq, b = cfg["requests"], cfg["budget"]
    p = plan(defn, cfg, n, repo_root)
    n = p["n"]
    log(f"[plan] {defn.name}: n={n}, est {p['est_bytes_per_request']:,} B/req ({p['estimate_basis']}), "
        f"projected {p['projected_bytes']:,} B; ledger {p['ledger_used']:,}/{p['cap']:,} B used")
    for w in defn.warnings:
        log(f"[warn] {w}")
    if p["projected_bytes"] > b["per_probe_max_bytes"]:
        raise BudgetRefused(f"projected {p['projected_bytes']:,} B exceeds per-probe max {b['per_probe_max_bytes']:,} B")
    ledger = Ledger(cfg_path(cfg, "ledger", repo_root), b["cap_bytes"])
    ledger.check_projection(p["projected_bytes"] + int(b.get("abort_margin_bytes", 0)))
    if dry_run:
        return {"dry_run": True, **p}
    if creds is None:
        raise ProbeAbort("Decodo credentials missing: set DECODO_USER, DECODO_PASS, DECODO_HOST (env or repo-root .env)")

    session = session or defn.session or rq["session"]
    duration = defn.sticky_duration_min or rq["sticky_duration_min"]
    session_id = new_session_id() if session == "sticky" else None
    jitter = defn.jitter_s or rq["jitter_s"]
    timeout = float(defn.timeout_s or rq["timeout_s"])
    max_body = int(defn.max_response_bytes or rq["max_response_bytes"])
    run_id = f"{utc_now('%Y%m%dT%H%M%SZ')}-{uuid.uuid4().hex[:6]}"
    out_dir = cfg_path(cfg, "probes_dir", repo_root) / defn.name
    out_dir.mkdir(parents=True, exist_ok=True)
    results_path = out_dir / "results.jsonl"
    started = utc_now()
    ledger.start_run(run_id, defn.name, {"planned": n, "session": session})
    log_event(cfg, f"run start {defn.name} run={run_id} n={n} session={session}", repo_root)
    records: list[dict] = []
    stopped = None
    common = dict(defn=defn, upstream=upstream, timeout=timeout, max_body=max_body,
                  max_redirects=rq["max_redirects"], ca_file=ca_file)
    try:
        with open(results_path, "a", encoding="utf-8") as fout:
            def emit(rec):
                records.append(rec)
                fout.write(json.dumps(rec, ensure_ascii=False) + "\n")
                fout.flush()

            if baseline:
                for i in range(int(rq["baseline_requests"])):
                    url = defn.url_for(i)
                    r, acc = fetch_follow(url, proxy=None, byte_limit=None, **common)
                    ledger.record(run_id, defn.name, acc["wire_sent"] + acc["wire_recv"], proxied=False)
                    rec = record_for(run_id, i, "direct", "none", None, url, r, acc, evaluate(r, defn))
                    emit(rec)
                    log(f"[base {i + 1}] {rec['status']} {rec['outcome']} rows={rec['rows']} {rec['bytes_wire_total']:,} B")

            proxy = proxy_for(creds, session_id, duration if session_id else None)
            run_bytes = 0
            for i in range(n):
                margin = int(b.get("abort_margin_bytes", 0))
                remaining = ledger.cap - ledger.used() - margin
                room = min(remaining, b["per_probe_max_bytes"] - run_bytes - margin)
                if room < b["min_reserve_bytes"]:
                    stopped = "cap" if remaining < b["min_reserve_bytes"] else "per_probe_budget"
                    log(f"[stop] {stopped}: only {room:,} B left")
                    break
                url = defn.url_for(i)
                r, acc = fetch_follow(url, proxy=proxy, byte_limit=room, **common)
                nbytes = acc["wire_sent"] + acc["wire_recv"]
                run_bytes += nbytes
                ledger.record(run_id, defn.name, nbytes, proxied=True)
                rec = record_for(run_id, i, "proxy", session, session_id, url, r, acc, evaluate(r, defn))
                emit(rec)
                vend = ",".join(rec["antibot"]) or "-"
                log(f"[{i + 1}/{n}] {rec['status']} {rec['outcome']} rows={rec['rows']} {nbytes:,} B vendors={vend}"
                    + (f" err={rec['error']}" if rec["error"] else ""))
                if r.error_kind == "byte_limit":
                    stopped = "cap" if ledger.remaining() - margin < b["min_reserve_bytes"] else "per_probe_budget"
                    log(f"[stop] byte allowance hit mid-request ({stopped})")
                    break
                if r.error_kind == "proxy_auth":
                    stopped = "proxy_auth"
                    log("[stop] proxy authentication failed (407); check DECODO_USER/DECODO_PASS")
                    break
                if i < n - 1 and jitter and jitter[1] > 0:
                    sleep(random.uniform(float(jitter[0]), float(jitter[1])))
    finally:
        ledger.end_run(run_id, stopped or "completed")
    meta = {"run_id": run_id, "started": started, "ended": utc_now(), "session": session,
            "requests_planned": n, "stopped_reason": stopped,
            "projected_bytes": p["projected_bytes"], "ledger_after_bytes": ledger.used()}
    summary = summarize(defn, cfg, records, meta)
    (out_dir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    write_probes_md(cfg, repo_root)
    log_event(cfg, f"run end {defn.name} run={run_id} sent={summary['requests_sent']} ok={summary['ok']} "
                   f"block={summary['block_rate']} bytes={summary['total_proxy_bytes']} verdict={summary['verdict']}",
              repo_root)
    return summary


# ---------------------------------------------------------------- health check

def _find_key(obj, key):
    if isinstance(obj, dict):
        if key in obj and isinstance(obj[key], (str, int)):
            return obj[key]
        for v in obj.values():
            got = _find_key(v, key)
            if got is not None:
                return got
    elif isinstance(obj, list):
        for v in obj:
            got = _find_key(v, key)
            if got is not None:
                return got
    return None


def health_check(cfg: dict, creds: Credentials, *, count: int = 1, sticky: bool = False,
                 upstream: ProxySpec | None = None, ca_file: str | None = None, urls: list[str] | None = None,
                 repo_root: Path = REPO_ROOT, log=print) -> list[dict]:
    urls = urls or cfg["health"]["ip_echo_urls"]
    ledger = Ledger(cfg_path(cfg, "ledger", repo_root), cfg["budget"]["cap_bytes"])
    hmargin = int(cfg["budget"].get("abort_margin_bytes", 0))
    if ledger.remaining() - hmargin < cfg["budget"]["min_reserve_bytes"]:
        raise BudgetRefused("Decodo traffic cap reached; health check refused")
    sid = new_session_id() if sticky else None
    proxy = proxy_for(creds, sid, cfg["requests"]["sticky_duration_min"] if sid else None)
    run_id = f"health-{utc_now('%Y%m%dT%H%M%SZ')}-{uuid.uuid4().hex[:4]}"
    ledger.start_run(run_id, "_health", {"planned": count, "session": "sticky" if sticky else "rotating"})
    out = []
    try:
        for i in range(max(1, min(int(count), 10))):
            res = None
            for u in urls:
                r = fetch(u, headers={"Accept": "application/json"}, proxy=proxy, upstream=upstream,
                          timeout=float(cfg["requests"]["timeout_s"]), max_body_bytes=200_000,
                          byte_limit=max(0, ledger.remaining() - hmargin), ca_file=ca_file)
                ledger.record(run_id, "_health", r.wire_total, proxied=True)
                info = {"i": i, "endpoint": u, "status": r.status, "latency_ms": round(r.elapsed_ms, 1),
                        "ttfb_ms": round(r.ttfb_ms, 1) if r.ttfb_ms else None, "bytes": r.wire_total,
                        "exit_ip": None, "country": None, "error": REDACTOR.redact(r.error) if r.error else None}
                if r.status == 200 and not r.error:
                    try:
                        doc = json.loads(r.body.decode("utf-8", "replace"))
                        info["exit_ip"] = _find_key(doc, "ip") or _find_key(doc, "query")
                        ctry = doc.get("country") if isinstance(doc, dict) else None
                        info["country"] = (ctry.get("code") or ctry.get("name")) if isinstance(ctry, dict) else ctry
                    except ValueError:
                        info["error"] = "endpoint did not return JSON"
                res = info
                if info["exit_ip"] or r.error_kind == "proxy_auth":
                    break
            out.append(res)
            log(f"[health {i + 1}] exit_ip={res['exit_ip']} country={res['country']} status={res['status']} "
                f"latency={res['latency_ms']} ms bytes={res['bytes']:,} via={res['endpoint']}"
                + (f" error={res['error']}" if res["error"] else ""))
    finally:
        ledger.end_run(run_id, "completed")
    if sticky and len(out) > 1:
        ips = {o["exit_ip"] for o in out if o["exit_ip"]}
        log(f"[health] sticky session kept {'the same IP' if len(ips) == 1 else f'{len(ips)} different IPs'}")
    return out
