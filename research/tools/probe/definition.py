"""Probe definition loading + validation.

A definition is a YAML (or JSON) file; see definitions/_TEMPLATE.yaml for every field.
Hard rules enforced here (Phase 5 spec: public pages only, no logins):
  * public_only must be true
  * no Authorization / Cookie / Proxy-Authorization headers
  * no user:pass@ in URLs
  * http(s) only
"""
from __future__ import annotations

import json
import re
import string
from dataclasses import dataclass, field
from pathlib import Path

import yaml

NAME_RE = re.compile(r"^[a-z0-9][a-z0-9._-]{1,63}$")
FORBIDDEN_HEADERS = {"authorization", "cookie", "proxy-authorization"}
LOGINISH = re.compile(r"/(login|signin|sign-in|account|my-account|auth|checkout)(/|\?|$)", re.I)
EXTRACT_TYPES = {"json", "json_in_html", "css", "regex"}

DEFAULT_HEADERS = {
    # A plain, current desktop Chrome header set. TLS/HTTP2 fingerprint is still Python's,
    # see README "Limitations".
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
}


class DefinitionError(ValueError):
    pass


@dataclass
class ProbeDefinition:
    name: str
    path: Path | None
    urls: list[str]
    method: str = "GET"
    headers: dict[str, str] = field(default_factory=dict)
    body: str | None = None
    extract: dict = field(default_factory=lambda: {"type": "json", "path": "$"})
    rows_per_page_expected: int | None = None
    success: dict = field(default_factory=lambda: {"status": [200], "min_rows": 1})
    expected_bytes_per_request: int | None = None
    requests: int | None = None
    session: str | None = None  # rotating | sticky
    sticky_duration_min: int | None = None
    jitter_s: list[float] | None = None
    timeout_s: float | None = None
    max_response_bytes: int | None = None
    follow_redirects: bool = True
    candidate_ref: str = ""
    notes: str = ""
    warnings: list[str] = field(default_factory=list)

    def url_for(self, i: int) -> str:
        return self.urls[i % len(self.urls)]


def _expand_template(tmpl: str, ids: list) -> list[str]:
    fields = [f for _, f, _, _ in string.Formatter().parse(tmpl) if f]
    out = []
    for item in ids:
        if isinstance(item, dict):
            out.append(tmpl.format(**item))
        elif len(fields) == 1:
            out.append(tmpl.format(**{fields[0]: item}))
        else:
            out.append(tmpl.format(id=item))
    return out


def parse_definition(data: dict, path: Path | None = None) -> ProbeDefinition:
    if not isinstance(data, dict):
        raise DefinitionError("definition must be a mapping")
    name = str(data.get("name", "")).strip()
    if not NAME_RE.match(name):
        raise DefinitionError(f"name {name!r} must match {NAME_RE.pattern}")
    if data.get("public_only") is not True:
        raise DefinitionError("public_only: true is required (public pages only, no logins)")
    urls = list(data.get("urls") or [])
    if data.get("url_template"):
        ids = data.get("sample_ids") or []
        if not ids:
            raise DefinitionError("url_template needs sample_ids")
        urls += _expand_template(data["url_template"], ids)
    if not urls:
        raise DefinitionError("give urls or url_template + sample_ids")
    warnings = []
    for u in urls:
        if not re.match(r"^https?://", u, re.I):
            raise DefinitionError(f"only http(s) URLs allowed: {u}")
        if re.match(r"^https?://[^/]*@", u, re.I):
            raise DefinitionError(f"credentials in URL are not allowed: {u.split('@')[-1]}")
        if LOGINISH.search(u):
            warnings.append(f"URL looks like a login/account page: {u}")
    headers = dict(DEFAULT_HEADERS)
    for k, v in (data.get("headers") or {}).items():
        if k.lower() in FORBIDDEN_HEADERS:
            raise DefinitionError(f"header {k} is not allowed (no logins / sessions)")
        headers[k] = str(v)
    method = str(data.get("method", "GET")).upper()
    if method not in {"GET", "POST", "HEAD"}:
        raise DefinitionError(f"method {method} not allowed")
    extract = data.get("extract") or {"type": "json", "path": "$"}
    if extract.get("type") not in EXTRACT_TYPES:
        raise DefinitionError(f"extract.type must be one of {sorted(EXTRACT_TYPES)}")
    if extract["type"] in ("css", "json_in_html") and not extract.get("selector"):
        raise DefinitionError("extract.selector required for css/json_in_html")
    if extract["type"] == "regex" and not extract.get("pattern"):
        raise DefinitionError("extract.pattern required for regex")
    success = {"status": [200], "min_rows": 1}
    success.update(data.get("success") or {})
    session = data.get("session")
    if session not in (None, "rotating", "sticky"):
        raise DefinitionError("session must be rotating or sticky")
    body = data.get("body")
    if isinstance(body, (dict, list)):
        body = json.dumps(body)
        headers.setdefault("Content-Type", "application/json")
    return ProbeDefinition(
        name=name,
        path=path,
        urls=urls,
        method=method,
        headers=headers,
        body=body,
        extract=extract,
        rows_per_page_expected=data.get("rows_per_page_expected"),
        success=success,
        expected_bytes_per_request=data.get("expected_bytes_per_request"),
        requests=data.get("requests"),
        session=session,
        sticky_duration_min=data.get("sticky_duration_min"),
        jitter_s=data.get("jitter_s"),
        timeout_s=data.get("timeout_s"),
        max_response_bytes=data.get("max_response_bytes"),
        follow_redirects=bool(data.get("follow_redirects", True)),
        candidate_ref=str(data.get("candidate_ref", "")),
        notes=str(data.get("notes", "")),
        warnings=warnings,
    )


def load_definition(path: str | Path) -> ProbeDefinition:
    p = Path(path)
    text = p.read_text(encoding="utf-8")
    data = json.loads(text) if p.suffix == ".json" else yaml.safe_load(text)
    return parse_definition(data, p)
