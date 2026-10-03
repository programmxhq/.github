#!/usr/bin/env python3
"""Apify Store census (Phase 1).

Pages the public Apify Store list (GET /v2/store), optionally enriches each
Actor with GET /v2/actors/{username}~{name}, and writes research/census.csv.

Field paths come from the official OpenAPI spec (apify/apify-docs). They are
spec-verified, NOT live-verified. See research/API_SPEC_NOTES.md.

Safety:
  * Only GET requests. No Actor runs, no writes.
  * Hard request cap (--max-requests) checked before every HTTP attempt.
  * Optional spend guard: reads data.current.monthlyUsageUsd from
    GET /v2/users/me/limits before, during and after; stops if it grew by more
    than --spend-cap-usd.
  * Credentials are read from the environment or a .env file and are never
    printed. Every message that leaves this module goes through redact().

Stdlib + requests only.
"""
from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import os
import re
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any, Iterable

import requests

HERE = Path(__file__).resolve().parent
RESEARCH_DIR = HERE.parents[1]          # research/
REPO_ROOT = HERE.parents[2]             # repo root
DEFAULT_CONFIG = HERE / "config.json"

CRED_KEYS = ("APIFY_TOKEN", "DECODO_USER", "DECODO_PASS", "DECODO_HOST")
USER_AGENT = "store-census/0.1 (+research; GET-only)"

CSV_COLUMNS = [
    "actor_id", "owner", "name", "title", "url", "url_source", "description",
    "categories", "notice", "badge", "is_apify_owned", "is_critical",
    "total_users", "users_90d", "users_30d", "users_7d", "total_runs",
    "runs_per_user", "rating", "review_count", "bookmark_count",
    "success_rate_30d", "runs_30d", "runs_30d_succeeded", "runs_30d_failed",
    "runs_30d_aborted", "runs_30d_timed_out", "last_run_started_at",
    "pricing_model", "pricing_source", "pricing_events", "event_count",
    "primary_event", "primary_event_price_usd", "price_flat_or_per_result",
    "price_unit", "price_per_result_tiers", "trial_minutes", "apify_margin",
    "pricing_started_at", "pending_price_change", "pricing_history_count",
    "last_modified", "created_at", "deprecated", "actor_permission_level",
    "is_white_listed_for_agentic_payments", "issues_response_time", "enriched",
]

# Why a column may be empty. Written to census_summary.json and README.
COLUMN_NOTES = {
    "url": "StoreListActor.url; if null, derived as https://apify.com/{username}/{name} (url_source=derived; pattern UNVERIFIED).",
    "is_apify_owned": "owner in config.json house_owners. The list itself needs live confirmation.",
    "is_critical": "Actor.isCritical ('maintained by Apify'); detail only, empty without --enrich.",
    "rating": "StoreListActor.actorReviewRating, fallback stats.actorReviewRating. Spec-verified, not live-verified.",
    "success_rate_30d": "stats.publicActorRunStats30Days SUCCEEDED/TOTAL; excludes owner's runs per spec. Empty when absent or TOTAL=0. This is NOT necessarily the number shown on the Store web page (UNVERIFIED).",
    "runs_30d": "stats.publicActorRunStats30Days.TOTAL (excludes owner's runs).",
    "pricing_events": "JSON {eventName: {tier|'FLAT': priceUsd}} from pricingPerEvent.actorChargeEvents. Store-list shape of pricingPerEvent is untyped in spec (UNVERIFIED); detail shape is typed.",
    "price_flat_or_per_result": "FLAT_PRICE_PER_MONTH: pricePerUnitUsd per month. PRICE_PER_DATASET_ITEM: pricePerUnitUsd per unit (per item vs per 1000 UNVERIFIED), else FREE-tier tieredPricePerUnitUsd. FREE: 0.",
    "last_modified": "Actor.modifiedAt; NOT in StoreListActor, detail only (needs --enrich).",
    "created_at": "Actor.createdAt; detail only (needs --enrich).",
    "deprecated": "Actor.isDeprecated; detail only (needs --enrich).",
    "pricing_history_count": "len(Actor.pricingInfos); detail only.",
    "issues_response_time": "Not in the API spec. Only visible on the Store web page; always empty.",
}


# --------------------------------------------------------------------------
# Credentials and redaction
# --------------------------------------------------------------------------

def parse_env_file(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    try:
        text = path.read_text(encoding="utf-8")
    except (FileNotFoundError, PermissionError, IsADirectoryError):
        return out
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[len("export "):]
        key, _, val = line.partition("=")
        key, val = key.strip(), val.strip()
        if len(val) >= 2 and val[0] == val[-1] and val[0] in "\"'":
            val = val[1:-1]
        out[key] = val
    return out


def load_credentials(env_file: Path | None) -> dict[str, str]:
    """Env vars win over the .env file. Values are never printed."""
    file_vals: dict[str, str] = {}
    candidates = [env_file] if env_file else [REPO_ROOT / ".env", RESEARCH_DIR / ".env"]
    for c in candidates:
        if c and c.is_file():
            file_vals = parse_env_file(c)
            break
    creds = {}
    for k in CRED_KEYS:
        v = os.environ.get(k) or file_vals.get(k)
        if v:
            creds[k] = v
    return creds


class Redactor:
    PATTERNS = [
        (re.compile(r"(token=)[^&\s'\"]+", re.I), r"\1***"),
        (re.compile(r"(Bearer\s+)[A-Za-z0-9_\-\.]+", re.I), r"\1***"),
        (re.compile(r"apify_api_[A-Za-z0-9]+"), "apify_api_***"),
    ]

    def __init__(self, secrets: Iterable[str] = ()):
        self.secrets = sorted({s for s in secrets if s and len(s) >= 4}, key=len, reverse=True)

    def __call__(self, text: Any) -> str:
        s = str(text)
        for sec in self.secrets:
            s = s.replace(sec, "***REDACTED***")
        for pat, rep in self.PATTERNS:
            s = pat.sub(rep, s)
        return s


redact = Redactor()


def log(msg: str) -> None:
    ts = dt.datetime.now(dt.timezone.utc).strftime("%H:%M:%S")
    print(f"[{ts}] {redact(msg)}", file=sys.stderr, flush=True)


# --------------------------------------------------------------------------
# Budget, rate limit, HTTP
# --------------------------------------------------------------------------

class BudgetExceeded(RuntimeError):
    pass


class SpendCapExceeded(RuntimeError):
    pass


class ApiError(RuntimeError):
    pass


class RequestBudget:
    """Counts every HTTP attempt (retries included). Hard stop at max_requests."""

    def __init__(self, max_requests: int):
        self.max_requests = max_requests
        self.count = 0
        self.by_kind: dict[str, int] = {}
        self.by_status: dict[str, int] = {}
        self.lock = threading.Lock()

    def acquire(self, kind: str) -> None:
        with self.lock:
            if self.count >= self.max_requests:
                raise BudgetExceeded(f"request cap {self.max_requests} reached")
            self.count += 1
            self.by_kind[kind] = self.by_kind.get(kind, 0) + 1

    def record_status(self, status: Any) -> None:
        with self.lock:
            k = str(status)
            self.by_status[k] = self.by_status.get(k, 0) + 1


class RateLimiter:
    """Global minimum interval between request starts, shared by all threads."""

    def __init__(self, rps: float):
        self.interval = 1.0 / rps if rps > 0 else 0.0
        self.next_at = 0.0
        self.lock = threading.Lock()

    def wait(self) -> None:
        if not self.interval:
            return
        with self.lock:
            now = time.monotonic()
            start = max(now, self.next_at)
            self.next_at = start + self.interval
        delay = start - time.monotonic()
        if delay > 0:
            time.sleep(delay)


class ApiClient:
    RETRY_STATUSES = {429, 500, 502, 503, 504}

    def __init__(self, base_url: str, token: str | None, budget: RequestBudget,
                 limiter: RateLimiter, max_retries: int = 6, backoff_base: float = 0.5,
                 backoff_cap: float = 60.0, timeout: float = 60.0):
        self.base_url = base_url.rstrip("/")
        self.budget = budget
        self.limiter = limiter
        self.max_retries = max_retries
        self.backoff_base = backoff_base
        self.backoff_cap = backoff_cap
        self.timeout = timeout
        self.session = requests.Session()
        self.session.headers["User-Agent"] = USER_AGENT
        self.session.headers["Accept"] = "application/json"
        if token:
            # Header auth only, so the token never appears in a URL.
            self.session.headers["Authorization"] = f"Bearer {token}"
        self.authenticated = bool(token)

    def get(self, path: str, params: dict | None = None, kind: str = "other",
            allow_404: bool = False) -> tuple[int, Any]:
        url = f"{self.base_url}{path}"
        attempt = 0
        while True:
            self.budget.acquire(kind)
            self.limiter.wait()
            try:
                resp = self.session.get(url, params=params, timeout=self.timeout)
                status = resp.status_code
            except requests.RequestException as e:
                self.budget.record_status("conn_error")
                if attempt >= self.max_retries:
                    raise ApiError(redact(f"GET {path} failed after {attempt + 1} attempts: {type(e).__name__}: {e}")) from None
                self._sleep_backoff(attempt, None)
                attempt += 1
                continue
            self.budget.record_status(status)
            if status == 200:
                try:
                    return status, resp.json()
                except ValueError:
                    raise ApiError(redact(f"GET {path}: non-JSON 200 body")) from None
            if status == 404 and allow_404:
                return status, None
            if status in self.RETRY_STATUSES and attempt < self.max_retries:
                self._sleep_backoff(attempt, resp.headers.get("Retry-After"))
                attempt += 1
                continue
            body = resp.text[:300] if resp.text else ""
            raise ApiError(redact(f"GET {path} -> HTTP {status}: {body}"))

    def _sleep_backoff(self, attempt: int, retry_after: str | None) -> None:
        # Spec: start at 500 ms and double on each retry.
        delay = min(self.backoff_cap, self.backoff_base * (2 ** attempt))
        if retry_after:
            try:
                delay = max(delay, min(self.backoff_cap, float(retry_after)))
            except ValueError:
                pass
        time.sleep(delay)


class SpendGuard:
    """Watches account usage via GET /v2/users/me/limits -> data.current.monthlyUsageUsd."""

    def __init__(self, client: ApiClient, cap_usd: float, check_every: int):
        self.client = client
        self.cap_usd = cap_usd
        self.check_every = check_every
        self.baseline: float | None = None
        self.latest: float | None = None
        self.available = False
        self.last_checked_at_count = 0
        self.lock = threading.Lock()

    def _read(self) -> float | None:
        try:
            _, body = self.client.get("/v2/users/me/limits", kind="spend_check")
            return float(body["data"]["current"]["monthlyUsageUsd"])
        except (ApiError, KeyError, TypeError, ValueError) as e:
            log(f"spend guard: could not read usage ({str(e)[:120]})")
            return None

    def start(self) -> None:
        if not self.client.authenticated:
            log("spend guard: no token, requests are unauthenticated and cannot bill an account")
            return
        self.baseline = self._read()
        self.latest = self.baseline
        self.available = self.baseline is not None
        if self.available:
            log(f"spend guard: baseline monthlyUsageUsd={self.baseline:.4f}, cap +{self.cap_usd:.2f}")

    def delta(self) -> float | None:
        if self.baseline is None or self.latest is None:
            return None
        return self.latest - self.baseline

    def maybe_check(self, force: bool = False) -> None:
        if not self.available:
            return
        with self.lock:
            count = self.client.budget.count
            if not force and count - self.last_checked_at_count < self.check_every:
                return
            self.last_checked_at_count = count
        val = self._read()
        if val is None:
            return
        self.latest = val
        d = self.delta() or 0.0
        if d > self.cap_usd:
            raise SpendCapExceeded(f"account usage grew by ${d:.4f} > cap ${self.cap_usd:.2f}")


# --------------------------------------------------------------------------
# File helpers
# --------------------------------------------------------------------------

def write_json_atomic(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
    os.replace(tmp, path)


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# --------------------------------------------------------------------------
# Phase A: Store list
# --------------------------------------------------------------------------

def store_query_params(args) -> dict[str, Any]:
    q: dict[str, Any] = {}
    if args.sort_by:
        q["sortBy"] = args.sort_by
    for k in ("category", "search", "username", "pricing_model"):
        v = getattr(args, k)
        if v:
            q[{"pricing_model": "pricingModel"}.get(k, k)] = v
    if args.include_unrunnable:
        q["includeUnrunnableActors"] = "true"
    return q


def fetch_store(client: ApiClient, guard: SpendGuard, store_dir: Path, args) -> dict:
    ckpt_path = store_dir / "_checkpoint.json"
    query = store_query_params(args)
    if ckpt_path.exists():
        if not args.resume:
            raise SystemExit(f"checkpoint exists at {ckpt_path}; pass --resume to continue or --fresh to start over")
        ckpt = read_json(ckpt_path)
        if ckpt.get("query") != query or ckpt.get("page_size") != args.page_size:
            raise SystemExit("checkpoint was made with different query params/page size; use --fresh")
        log(f"resuming store paging at offset {ckpt['next_offset']} (pages done: {ckpt['pages_done']})")
    else:
        ckpt = {"query": query, "page_size": args.page_size, "next_offset": 0,
                "pages_done": 0, "total": None, "complete": False,
                "started_at": now_iso(), "warnings": []}
        write_json_atomic(ckpt_path, ckpt)

    pages_this_run = 0
    while not ckpt["complete"]:
        if args.max_pages is not None and pages_this_run >= args.max_pages:
            log(f"--max-pages {args.max_pages} reached; stopping store paging (resumable)")
            break
        guard.maybe_check()
        offset = ckpt["next_offset"]
        params = dict(query, limit=args.page_size, offset=offset)
        _, body = client.get("/v2/store", params=params, kind="store_list")
        data = (body or {}).get("data") or {}
        items = data.get("items") or []
        count = len(items)
        total = data.get("total")
        page_no = ckpt["pages_done"] + 1
        write_json_atomic(store_dir / f"page_{page_no:04d}.json",
                          {"_census": {"fetched_at": now_iso(), "params": params}, **(body or {})})
        ckpt["pages_done"] = page_no
        ckpt["next_offset"] = offset + count
        if isinstance(total, int):
            ckpt["total"] = total
        pages_this_run += 1
        log(f"store page {page_no}: offset={offset} count={count} total={total}")
        if count == 0:
            ckpt["complete"] = True
            if isinstance(ckpt["total"], int) and ckpt["next_offset"] < ckpt["total"]:
                w = (f"server returned 0 items at offset {offset} but total={ckpt['total']}: "
                     "probable result-window cap (spec: 'will not return more than 1,000 records'). "
                     "Partition with --category/--sort-by and merge.")
                ckpt["warnings"].append(w)
                log("WARNING: " + w)
        elif isinstance(ckpt["total"], int) and ckpt["next_offset"] >= ckpt["total"]:
            ckpt["complete"] = True
        if ckpt["complete"]:
            ckpt["completed_at"] = now_iso()
        write_json_atomic(ckpt_path, ckpt)
    return ckpt


def load_store_items(store_dir: Path) -> tuple[list[dict], int]:
    """All items from saved pages, deduped by id (first occurrence wins)."""
    seen: dict[str, dict] = {}
    raw_count = 0
    for p in sorted(store_dir.rglob("page_*.json")):
        body = read_json(p)
        for it in ((body.get("data") or {}).get("items") or []):
            raw_count += 1
            aid = it.get("id") or f"{it.get('username')}~{it.get('name')}"
            seen.setdefault(aid, it)
    return list(seen.values()), raw_count


# --------------------------------------------------------------------------
# Phase B: enrichment
# --------------------------------------------------------------------------

def detail_path(actors_dir: Path, item: dict) -> Path:
    key = item.get("id") or f"{item.get('username')}~{item.get('name')}"
    return actors_dir / f"{re.sub(r'[^A-Za-z0-9_~.-]', '_', key)}.json"


def enrich(client: ApiClient, guard: SpendGuard, items: list[dict], actors_dir: Path, args) -> dict:
    actors_dir.mkdir(parents=True, exist_ok=True)
    todo = []
    for it in items:
        users = ((it.get("stats") or {}).get("totalUsers") or 0)
        if users < args.enrich_min_users:
            continue
        if detail_path(actors_dir, it).exists():
            continue
        todo.append(it)
    if args.enrich_limit is not None:
        todo = todo[: args.enrich_limit]
    log(f"enrichment: {len(todo)} actors to fetch ({len(items)} in store, cached files skipped)")
    stats = {"fetched": 0, "not_found": 0, "errors": 0, "skipped_cached_or_filtered": len(items) - len(todo)}
    stop = threading.Event()

    def one(it: dict) -> str:
        if stop.is_set():
            return "stopped"
        guard.maybe_check()
        ref = f"{it['username']}~{it['name']}"
        status, body = client.get(f"{args.actor_path_prefix}/{ref}", kind="actor_detail", allow_404=True)
        if status == 404 and it.get("id"):
            status, body = client.get(f"{args.actor_path_prefix}/{it['id']}", kind="actor_detail", allow_404=True)
        out = detail_path(actors_dir, it)
        if status == 404:
            write_json_atomic(out, {"_census": {"status": 404, "fetched_at": now_iso(), "ref": ref}})
            return "not_found"
        write_json_atomic(out, {"_census": {"status": 200, "fetched_at": now_iso(), "ref": ref}, **body})
        return "fetched"

    fatal: BaseException | None = None
    with ThreadPoolExecutor(max_workers=max(1, args.concurrency)) as ex:
        futs = [ex.submit(one, it) for it in todo]
        for i, f in enumerate(as_completed(futs), 1):
            try:
                r = f.result()
                if r in stats:
                    stats[r] += 1
            except (BudgetExceeded, SpendCapExceeded) as e:
                stop.set()
                fatal = fatal or e
            except ApiError as e:
                stats["errors"] += 1
                log(f"enrichment error: {e}")
            if i % 100 == 0:
                log(f"enrichment progress: {i}/{len(todo)}")
    if fatal:
        raise fatal
    return stats


# --------------------------------------------------------------------------
# Row building
# --------------------------------------------------------------------------

def _num(v: Any) -> Any:
    return "" if v is None else v


def parse_charge_events(ppe: Any) -> dict[str, dict]:
    """pricingPerEvent -> {eventName: ActorChargeEvent}. Accepts the typed detail
    shape {actorChargeEvents: {...}} and, defensively, a bare map of events."""
    if not isinstance(ppe, dict):
        return {}
    events = ppe.get("actorChargeEvents")
    if isinstance(events, dict):
        return {k: v for k, v in events.items() if isinstance(v, dict)}
    if ppe and all(isinstance(v, dict) and ("eventPriceUsd" in v or "eventTieredPricingUsd" in v) for v in ppe.values()):
        return dict(ppe)
    return {}


def event_prices(ev: dict) -> dict[str, float]:
    tiers = ev.get("eventTieredPricingUsd")
    if isinstance(tiers, dict) and tiers:
        return {t: e.get("tieredEventPriceUsd") for t, e in tiers.items() if isinstance(e, dict)}
    if ev.get("eventPriceUsd") is not None:
        return {"FLAT": ev["eventPriceUsd"]}
    return {}


def base_price(prices: dict[str, float]) -> Any:
    for k in ("FLAT", "FREE"):
        if prices.get(k) is not None:
            return prices[k]
    vals = [v for v in prices.values() if isinstance(v, (int, float))]
    return max(vals) if vals else ""


def pick_current_pricing(pricing_infos: Any, now: dt.datetime) -> tuple[dict | None, bool]:
    """Latest pricingInfos entry whose startedAt <= now; flag future-dated entries."""
    if not isinstance(pricing_infos, list) or not pricing_infos:
        return None, False
    def ts(p):
        s = p.get("startedAt") or p.get("createdAt") or ""
        try:
            return dt.datetime.fromisoformat(s.replace("Z", "+00:00"))
        except ValueError:
            return None
    dated = [(ts(p), p) for p in pricing_infos if isinstance(p, dict)]
    past = [(t, p) for t, p in dated if t is not None and t <= now]
    future = any(t is not None and t > now for t, _ in dated)
    if past:
        return max(past, key=lambda x: x[0])[1], future
    return dated[-1][1] if dated else None, future


def pricing_columns(pi: dict | None) -> dict[str, Any]:
    cols = {k: "" for k in ("pricing_model", "pricing_events", "event_count", "primary_event",
                            "primary_event_price_usd", "price_flat_or_per_result", "price_unit",
                            "price_per_result_tiers", "trial_minutes", "apify_margin", "pricing_started_at")}
    if not pi:
        return cols
    model = pi.get("pricingModel") or ""
    cols["pricing_model"] = model
    cols["apify_margin"] = _num(pi.get("apifyMarginPercentage"))
    cols["pricing_started_at"] = pi.get("startedAt") or ""
    cols["trial_minutes"] = _num(pi.get("trialMinutes"))
    if model == "PAY_PER_EVENT":
        events = parse_charge_events(pi.get("pricingPerEvent"))
        priced = {name: event_prices(ev) for name, ev in events.items()}
        cols["pricing_events"] = json.dumps(priced, sort_keys=True) if events else ""
        cols["event_count"] = len(events) if events else ""
        primary = next((n for n, ev in events.items() if ev.get("isPrimaryEvent")), None)
        if primary:
            cols["primary_event"] = primary
            cols["primary_event_price_usd"] = base_price(priced[primary])
        cols["price_unit"] = "event"
    elif model == "PRICE_PER_DATASET_ITEM":
        tiers = pi.get("tieredPricing")
        tier_prices = ({t: e.get("tieredPricePerUnitUsd") for t, e in tiers.items() if isinstance(e, dict)}
                       if isinstance(tiers, dict) else {})
        if tier_prices:
            cols["price_per_result_tiers"] = json.dumps(tier_prices, sort_keys=True)
        p = pi.get("pricePerUnitUsd")
        cols["price_flat_or_per_result"] = p if p is not None else (base_price(tier_prices) if tier_prices else "")
        cols["price_unit"] = pi.get("unitName") or "result"
    elif model == "FLAT_PRICE_PER_MONTH":
        cols["price_flat_or_per_result"] = _num(pi.get("pricePerUnitUsd"))
        cols["price_unit"] = "month"
    elif model == "FREE":
        cols["price_flat_or_per_result"] = 0
    return cols


def build_row(item: dict, detail: dict | None, house_owners: set[str], now: dt.datetime) -> dict:
    stats = dict(item.get("stats") or {})
    d = (detail or {}).get("data") if detail else None
    if d and isinstance(d.get("stats"), dict):
        # Detail stats fill gaps only; the Store list is the census snapshot.
        for k, v in d["stats"].items():
            stats.setdefault(k, v)
    owner = item.get("username") or (d or {}).get("username") or ""
    name = item.get("name") or (d or {}).get("name") or ""
    url, url_source = item.get("url"), "store"
    if not url:
        url, url_source = f"https://apify.com/{owner}/{name}", "derived"

    total_users = stats.get("totalUsers")
    total_runs = stats.get("totalRuns")
    rps = ""
    if isinstance(total_users, (int, float)) and total_users > 0 and isinstance(total_runs, (int, float)):
        rps = round(total_runs / total_users, 3)

    run30 = stats.get("publicActorRunStats30Days") or {}
    tot30 = run30.get("TOTAL") if isinstance(run30, dict) else None
    succ30 = run30.get("SUCCEEDED") if isinstance(run30, dict) else None
    success_rate = ""
    if isinstance(tot30, (int, float)) and tot30 > 0 and isinstance(succ30, (int, float)):
        success_rate = round(succ30 / tot30, 4)

    rating = item.get("actorReviewRating", stats.get("actorReviewRating"))
    reviews = item.get("actorReviewCount", stats.get("actorReviewCount"))
    bookmarks = item.get("bookmarkCount", stats.get("bookmarkCount"))

    pending = False
    history_count: Any = ""
    if d is not None:
        pi, pending = pick_current_pricing(d.get("pricingInfos"), now)
        history_count = len(d.get("pricingInfos") or [])
        source = "detail.pricingInfos" if pi else "store.currentPricingInfo"
        if not pi:
            pi = item.get("currentPricingInfo")
    else:
        pi, source = item.get("currentPricingInfo"), "store.currentPricingInfo"
    pcols = pricing_columns(pi)
    # Store PPE events may be absent/untyped; fall back to the store copy if detail had none.
    if not pcols["pricing_events"] and source.startswith("detail") and item.get("currentPricingInfo"):
        alt = pricing_columns(item["currentPricingInfo"])
        if alt["pricing_model"] == pcols["pricing_model"] and alt["pricing_events"]:
            for k in ("pricing_events", "event_count", "primary_event", "primary_event_price_usd"):
                pcols[k] = alt[k]

    categories = item.get("categories") or (d or {}).get("categories") or []
    row = {
        "actor_id": item.get("id") or (d or {}).get("id") or "",
        "owner": owner,
        "name": name,
        "title": item.get("title") or (d or {}).get("title") or "",
        "url": url,
        "url_source": url_source,
        "description": (item.get("description") or "").replace("\r", " ").replace("\n", " "),
        "categories": ";".join(categories),
        "notice": item.get("notice") or "",
        "badge": item.get("badge") or "",
        "is_apify_owned": str(owner.lower() in house_owners).lower(),
        "is_critical": "" if d is None or d.get("isCritical") is None else str(d["isCritical"]).lower(),
        "total_users": _num(total_users),
        "users_90d": _num(stats.get("totalUsers90Days")),
        "users_30d": _num(stats.get("totalUsers30Days")),
        "users_7d": _num(stats.get("totalUsers7Days")),
        "total_runs": _num(total_runs),
        "runs_per_user": rps,
        "rating": _num(rating),
        "review_count": _num(reviews),
        "bookmark_count": _num(bookmarks),
        "success_rate_30d": success_rate,
        "runs_30d": _num(tot30),
        "runs_30d_succeeded": _num(succ30),
        "runs_30d_failed": _num(run30.get("FAILED") if isinstance(run30, dict) else None),
        "runs_30d_aborted": _num(run30.get("ABORTED") if isinstance(run30, dict) else None),
        "runs_30d_timed_out": _num(run30.get("TIMED-OUT") if isinstance(run30, dict) else None),
        "last_run_started_at": stats.get("lastRunStartedAt") or "",
        "pricing_source": source if pi else "",
        "pending_price_change": str(pending).lower() if d is not None else "",
        "pricing_history_count": history_count,
        "last_modified": (d or {}).get("modifiedAt") or "",
        "created_at": (d or {}).get("createdAt") or "",
        "deprecated": "" if d is None or d.get("isDeprecated") is None else str(d["isDeprecated"]).lower(),
        "actor_permission_level": (d or {}).get("actorPermissionLevel") or "",
        "is_white_listed_for_agentic_payments": "" if item.get("isWhiteListedForAgenticPayments") is None
            else str(item["isWhiteListedForAgenticPayments"]).lower(),
        "issues_response_time": "",
        "enriched": str(d is not None).lower(),
    }
    row.update(pcols)
    return {c: row.get(c, "") for c in CSV_COLUMNS}


def write_csv(items: list[dict], actors_dir: Path, out_csv: Path, house_owners: set[str]) -> dict:
    now = dt.datetime.now(dt.timezone.utc)
    rows, enriched, not_found, mismatches = [], 0, 0, 0
    for it in items:
        detail = None
        p = detail_path(actors_dir, it)
        if p.exists():
            body = read_json(p)
            if (body.get("_census") or {}).get("status") == 200 and body.get("data"):
                detail = body
                enriched += 1
            else:
                not_found += 1
        row = build_row(it, detail, house_owners, now)
        store_model = (it.get("currentPricingInfo") or {}).get("pricingModel")
        if detail and store_model and row["pricing_model"] and store_model != row["pricing_model"]:
            mismatches += 1
        rows.append(row)
    # Live cross-check of the house list: Actor.isCritical = "maintained by Apify" (detail only).
    crit: dict[str, list[int]] = {}
    for r in rows:
        if r["is_critical"] in ("true", "false"):
            c = crit.setdefault(r["owner"], [0, 0])
            c[0] += 1
            c[1] += r["is_critical"] == "true"
    house_check = {o: {"enriched": crit.get(o, [0, 0])[0], "is_critical_true": crit.get(o, [0, 0])[1],
                       "store_actors": sum(1 for r in rows if r["owner"].lower() == o)} for o in sorted(house_owners)}
    other_critical = sorted(((o, c[1]) for o, c in crit.items() if c[1] and o.lower() not in house_owners),
                            key=lambda x: -x[1])[:25]
    rows.sort(key=lambda r: (-(r["total_users"] or 0) if isinstance(r["total_users"], (int, float)) else 0, r["owner"], r["name"]))
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    tmp = out_csv.with_suffix(".csv.tmp")
    with tmp.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
        w.writeheader()
        w.writerows(rows)
    os.replace(tmp, out_csv)
    return {"rows": len(rows), "enriched": enriched, "detail_404": not_found,
            "store_vs_detail_pricing_model_mismatch": mismatches,
            "house_owner_check": house_check,
            "non_house_owners_with_isCritical": dict(other_critical)}


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def load_config(path: Path) -> dict:
    try:
        return read_json(path)
    except FileNotFoundError:
        return {}


def parse_args(argv=None):
    cfg = load_config(DEFAULT_CONFIG)
    ap = argparse.ArgumentParser(description="Apify Store census (GET-only).")
    ap.add_argument("--enrich", action="store_true", help="also GET /v2/actors/{username}~{name} per actor")
    ap.add_argument("--max-pages", type=int, default=None, help="stop store paging after N pages this run")
    ap.add_argument("--resume", action="store_true", help="continue from the store checkpoint")
    ap.add_argument("--fresh", action="store_true", help="delete store pages + checkpoint and start over")
    ap.add_argument("--build-only", action="store_true", help="no network; rebuild CSV from raw files")
    ap.add_argument("--no-auth", action="store_true", help="send no token (cannot bill any account)")
    ap.add_argument("--page-size", type=int, default=cfg.get("page_size", 1000), help="limit param (spec max 1000)")
    ap.add_argument("--sort-by", default=cfg.get("sort_by", "popularity"),
                    help="relevance|popularity|newest|lastUpdate")
    ap.add_argument("--slice", default=None,
                    help="name for a partitioned query (own checkpoint under raw/store/slices/NAME); "
                         "CSV merges all slices, deduped by actor id")
    ap.add_argument("--category", default=None)
    ap.add_argument("--search", default=None)
    ap.add_argument("--username", default=None)
    ap.add_argument("--pricing-model", default=None, choices=["FREE", "FLAT_PRICE_PER_MONTH",
                                                              "PRICE_PER_DATASET_ITEM", "PAY_PER_EVENT"])
    ap.add_argument("--include-unrunnable", action="store_true", default=cfg.get("include_unrunnable", True),
                    help="includeUnrunnableActors=true (default on, for a full census)")
    ap.add_argument("--exclude-unrunnable", dest="include_unrunnable", action="store_false")
    ap.add_argument("--enrich-min-users", type=int, default=cfg.get("enrich_min_users", 0))
    ap.add_argument("--enrich-limit", type=int, default=None)
    ap.add_argument("--concurrency", type=int, default=cfg.get("concurrency", 2))
    ap.add_argument("--rps", type=float, default=cfg.get("rps", 2.0), help="global requests/second")
    ap.add_argument("--max-requests", type=int, default=cfg.get("max_requests", 25000))
    ap.add_argument("--spend-cap-usd", type=float, default=cfg.get("spend_cap_usd", 0.50))
    ap.add_argument("--spend-check-every", type=int, default=cfg.get("spend_check_every", 500))
    ap.add_argument("--base-url", default=os.environ.get("APIFY_API_BASE_URL", cfg.get("base_url", "https://api.apify.com")))
    ap.add_argument("--actor-path-prefix", default=cfg.get("actor_path_prefix", "/v2/actors"),
                    help="/v2/actors (canonical) or /v2/acts (legacy)")
    ap.add_argument("--raw-dir", type=Path, default=RESEARCH_DIR / "raw")
    ap.add_argument("--out", type=Path, default=RESEARCH_DIR / "census.csv")
    ap.add_argument("--env-file", type=Path, default=None)
    ap.add_argument("--backoff-base", type=float, default=0.5)
    ap.add_argument("--max-retries", type=int, default=6)
    args = ap.parse_args(argv)
    args.house_owners = {o.lower() for o in cfg.get("house_owners", ["apify"])}
    if not (1 <= args.page_size <= 1000):
        ap.error("--page-size must be 1..1000 (spec max 1000)")
    return args


def main(argv=None) -> int:
    global redact
    args = parse_args(argv)
    creds = load_credentials(args.env_file)
    redact = Redactor(creds.values())
    token = None if args.no_auth else creds.get("APIFY_TOKEN")
    log(f"credentials: APIFY_TOKEN {'present' if creds.get('APIFY_TOKEN') else 'absent'}"
        f"{' (not sent: --no-auth)' if args.no_auth and creds.get('APIFY_TOKEN') else ''}; "
        f"DECODO_* {'present' if all(k in creds for k in CRED_KEYS[1:]) else 'absent'} (unused by census)")

    store_root = args.raw_dir / "store"
    store_dir = store_root / "slices" / args.slice if args.slice else store_root
    actors_dir = args.raw_dir / "actors"
    if args.fresh and store_dir.exists():
        for f in list(store_dir.glob("page_*.json")) + [store_dir / "_checkpoint.json"]:
            if f.exists():
                f.unlink()
        log(f"--fresh: removed previous pages and checkpoint in {store_dir}")
    store_dir.mkdir(parents=True, exist_ok=True)

    budget = RequestBudget(args.max_requests)
    client = ApiClient(args.base_url, token, budget, RateLimiter(args.rps),
                       max_retries=args.max_retries, backoff_base=args.backoff_base)
    guard = SpendGuard(client, args.spend_cap_usd, args.spend_check_every)
    summary: dict[str, Any] = {"started_at": now_iso(), "base_url": args.base_url,
                               "authenticated": client.authenticated, "args": {
                                   k: (str(v) if isinstance(v, Path) else sorted(v) if isinstance(v, set) else v)
                                   for k, v in vars(args).items() if k not in ("env_file",)}}
    exit_code = 0
    ckpt: dict = {}
    enrich_stats: dict | None = None
    try:
        if not args.build_only:
            guard.start()
            ckpt = fetch_store(client, guard, store_dir, args)
            if args.enrich:
                items, _ = load_store_items(store_root)
                enrich_stats = enrich(client, guard, items, actors_dir, args)
            guard.maybe_check(force=True)
    except (BudgetExceeded, SpendCapExceeded) as e:
        log(f"HARD STOP: {e}")
        summary["hard_stop"] = str(e)
        exit_code = 3
    except ApiError as e:
        log(f"API error: {e}")
        summary["api_error"] = redact(str(e))
        exit_code = 2
    finally:
        items, raw_count = load_store_items(store_root)  # merges all slices
        csv_stats = write_csv(items, actors_dir, args.out, args.house_owners) if items else {"rows": 0}
        if not ckpt and (store_dir / "_checkpoint.json").exists():
            ckpt = read_json(store_dir / "_checkpoint.json")
        summary.update({
            "finished_at": now_iso(),
            "requests_total": budget.count,
            "requests_by_kind": budget.by_kind,
            "responses_by_status": budget.by_status,
            "max_requests": budget.max_requests,
            "spend_guard": {"available": guard.available, "baseline_usd": guard.baseline,
                            "latest_usd": guard.latest, "delta_usd": guard.delta(),
                            "cap_usd": args.spend_cap_usd},
            "store": {"reported_total": ckpt.get("total"), "pages": ckpt.get("pages_done"),
                      "complete": ckpt.get("complete"), "items_raw": raw_count,
                      "items_unique": len(items), "warnings": ckpt.get("warnings", [])},
            "enrichment": enrich_stats,
            "csv": {"path": str(args.out), **csv_stats},
            "column_notes": COLUMN_NOTES,
            "status": "spec-verified, NOT live-verified field mapping",
        })
        write_json_atomic(args.out.with_name(args.out.stem + "_summary.json"), summary)
        log("SUMMARY: " + json.dumps({k: summary[k] for k in ("requests_total", "responses_by_status", "spend_guard", "store", "enrichment", "csv")}))
    return exit_code


if __name__ == "__main__":
    sys.exit(main())
