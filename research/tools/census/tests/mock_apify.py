"""Tiny offline stand-in for the three Apify API endpoints the census uses.

Response shapes follow the OpenAPI spec (see fixtures/*). Behaviour knobs let
tests inject 429s, a result-window cap and growing account usage.
"""
from __future__ import annotations

import json
import re
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

FIXTURES = Path(__file__).resolve().parent / "fixtures"


class MockState:
    def __init__(self, fail_first_n_with_429: int = 0, window_cap: int | None = None,
                 usage_step_usd: float = 0.0, expected_token: str | None = None,
                 ignore_offset: bool = False):
        store = json.loads((FIXTURES / "store_items.json").read_text())
        self.items = store["items"]
        self.details = {p.stem: json.loads(p.read_text()) for p in (FIXTURES / "actors").glob("*.json")}
        self.fail_429 = fail_first_n_with_429
        self.window_cap = window_cap
        self.usage = 1.0
        self.usage_step = usage_step_usd
        self.expected_token = expected_token
        self.ignore_offset = ignore_offset   # misbehaving server: always serves the first page
        self.log: list[dict] = []
        self.lock = threading.Lock()


def make_handler(state: MockState):
    class H(BaseHTTPRequestHandler):
        def log_message(self, *a):  # silence
            pass

        def _send(self, code: int, body: dict, headers: dict | None = None):
            raw = json.dumps(body).encode()
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(raw)))
            for k, v in (headers or {}).items():
                self.send_header(k, v)
            self.end_headers()
            self.wfile.write(raw)

        def do_GET(self):
            u = urlparse(self.path)
            q = {k: v[0] for k, v in parse_qs(u.query).items()}
            with state.lock:
                state.log.append({"path": u.path, "query": q, "raw_path": self.path,
                                  "auth": self.headers.get("Authorization")})
                if state.fail_429 > 0:
                    state.fail_429 -= 1
                    return self._send(429, {"error": {"type": "rate-limit-exceeded",
                                                      "message": "You have exceeded the rate limit."}},
                                      {"Retry-After": "0"})
            if state.expected_token and self.headers.get("Authorization") != f"Bearer {state.expected_token}":
                return self._send(401, {"error": {"type": "token-not-valid", "message": "Authentication token is not valid."}})

            if u.path == "/v2/store":
                limit = int(float(q.get("limit", 1000)))
                offset = 0 if state.ignore_offset else int(float(q.get("offset", 0)))
                limit = min(limit, 1000)
                items = state.items
                window = items if state.window_cap is None else items[: state.window_cap]
                page = window[offset: offset + limit]
                headers = {"X-Apify-Pagination-Offset": str(offset), "X-Apify-Pagination-Limit": str(limit),
                           "X-Apify-Pagination-Count": str(len(page)), "X-Apify-Pagination-Total": str(len(items)),
                           "X-Apify-Pagination-Desc": "false"}
                return self._send(200, {"data": {"total": len(items), "offset": offset, "limit": limit,
                                                 "desc": False, "count": len(page), "items": page}}, headers)

            m = re.fullmatch(r"/v2/(?:actors|acts)/([^/]+)", u.path)
            if m:
                ref = m.group(1)
                hit = state.details.get(ref)
                if hit is None:
                    for d in state.details.values():
                        if f"{d['data']['username']}~{d['data']['name']}" == ref:
                            hit = d
                if hit is None:
                    return self._send(404, {"error": {"type": "record-not-found", "message": "Actor was not found"}})
                body = {k: v for k, v in hit.items() if not k.startswith("_")}
                return self._send(200, body)

            if u.path == "/v2/users/me/limits":
                with state.lock:
                    cur = state.usage
                    state.usage += state.usage_step
                return self._send(200, {"data": {"monthlyUsageCycle": {"startAt": "2026-10-01T00:00:00.000Z",
                                                                        "endAt": "2026-10-31T23:59:59.999Z"},
                                                 "limits": {"maxMonthlyUsageUsd": 5},
                                                 "current": {"monthlyUsageUsd": cur}}})
            return self._send(404, {"error": {"type": "page-not-found", "message": "not found"}})

    return H


class MockServer:
    def __init__(self, state: MockState):
        self.state = state
        self.httpd = ThreadingHTTPServer(("127.0.0.1", 0), make_handler(state))
        self.thread = threading.Thread(target=self.httpd.serve_forever, daemon=True)

    @property
    def url(self) -> str:
        return f"http://127.0.0.1:{self.httpd.server_address[1]}"

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *exc):
        self.httpd.shutdown()
        self.httpd.server_close()
