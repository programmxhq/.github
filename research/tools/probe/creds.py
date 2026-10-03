"""Credential loading and redaction.

Credentials come from env DECODO_USER / DECODO_PASS / DECODO_HOST, falling back to the
repo-root .env file. They are never printed, logged or written to results. Every string
that leaves this package through an error path goes through REDACTOR.redact().

Decodo username/endpoint format (UNVERIFIED, from WebSearch summaries of help.decodo.com,
2026-10-03 -- confirm live with `python -m probe health`):
  * Residential gateway: gate.decodo.com:7000 (rotating by default).
    https://help.decodo.com/docs/residential-proxy-quick-start
  * Sticky session: add parameters to the username with a "user-" prefix:
    user-<username>-session-<id>-sessionduration-<1..1440 minutes>  (default 10 min)
    https://help.decodo.com/docs/residential-proxy-custom-sticky-sessions
    https://help.decodo.com/docs/residential-proxy-advanced-parameters
  * Our plan has NO country targeting, so we never add -country-/-cc- parameters.
"""
from __future__ import annotations

import base64
import os
import re
import secrets
import urllib.parse
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_PORT = 7000  # UNVERIFIED: documented residential gateway port, see module docstring.


class Redactor:
    """Replaces every registered secret (and common encodings of it) with ***."""

    def __init__(self) -> None:
        self._secrets: set[str] = set()

    def add(self, *values: str | None) -> None:
        for v in values:
            if v and len(v) >= 3:
                self._secrets.add(v)
                self._secrets.add(urllib.parse.quote(v, safe=""))
        # basic-auth token for any user:pass combination we know about
        vals = [v for v in values if v]
        if len(vals) >= 2:
            tok = base64.b64encode(f"{vals[0]}:{vals[1]}".encode()).decode()
            self._secrets.add(tok)

    def add_basic(self, user: str, password: str) -> None:
        self._secrets.add(base64.b64encode(f"{user}:{password}".encode()).decode())

    def redact(self, text: object) -> str:
        s = str(text)
        for sec in sorted(self._secrets, key=len, reverse=True):
            if sec in s:
                s = s.replace(sec, "***")
        # Belt and braces: never let a Proxy-Authorization value through.
        s = re.sub(r"(?i)(proxy-authorization:\s*basic\s+)\S+", r"\1***", s)
        s = re.sub(r"(?i)(//)[^/@\s:]+:[^/@\s]+@", r"\1***:***@", s)
        return s


REDACTOR = Redactor()


@dataclass(repr=False)
class Credentials:
    user: str
    password: str
    host: str
    port: int = DEFAULT_PORT
    source: str = field(default="env")

    def __repr__(self) -> str:  # never show secrets, even in tracebacks / pytest output
        return f"Credentials(user=***, password=***, host={self.host!r}, port={self.port}, source={self.source!r})"

    __str__ = __repr__


def parse_host(value: str, default_port: int = DEFAULT_PORT) -> tuple[str, int]:
    """Accepts 'gate.decodo.com', 'gate.decodo.com:7000', 'http://gate.decodo.com:7000/'."""
    v = value.strip()
    if "://" in v:
        parts = urllib.parse.urlsplit(v)
        host = parts.hostname or ""
        port = parts.port or default_port
        return host, port
    v = v.rstrip("/")
    if v.startswith("[") and "]" in v:  # [ipv6]:port
        host, _, rest = v[1:].partition("]")
        port = int(rest[1:]) if rest.startswith(":") else default_port
        return host, port
    if v.count(":") == 1:
        host, port_s = v.split(":")
        return host, int(port_s)
    return v, default_port


def read_dotenv(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return out
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        if line.startswith("export "):
            line = line[len("export "):]
        k, _, v = line.partition("=")
        v = v.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in "'\"":
            v = v[1:-1]
        out[k.strip()] = v
    return out


def load_credentials(env: dict[str, str] | None = None, dotenv_path: Path | None = None) -> Credentials | None:
    env = dict(os.environ) if env is None else env
    dotenv_path = dotenv_path or (REPO_ROOT / ".env")
    names = ("DECODO_USER", "DECODO_PASS", "DECODO_HOST")
    vals = {k: env.get(k) for k in names}
    source = "env"
    if not all(vals.values()):
        dot = read_dotenv(dotenv_path)
        for k in names:
            if not vals[k] and dot.get(k):
                vals[k] = dot[k]
                source = "env+.env" if source == "env" and any(env.get(n) for n in names) else ".env"
    if not all(vals.values()):
        return None
    host, port = parse_host(vals["DECODO_HOST"])  # type: ignore[arg-type]
    creds = Credentials(user=vals["DECODO_USER"], password=vals["DECODO_PASS"], host=host, port=port, source=source)  # type: ignore[arg-type]
    REDACTOR.add(creds.user, creds.password)
    REDACTOR.add(creds.host)  # DECODO_HOST is treated as secret too (it lands in connect errors)
    return creds


def new_session_id() -> str:
    return secrets.token_hex(6)


def proxy_username(user: str, session_id: str | None = None, duration_min: int | None = None) -> str:
    """Rotating: the plain username. Sticky: user-<user>-session-<id>[-sessionduration-<m>].

    UNVERIFIED format (see module docstring). If DECODO_USER already starts with 'user-' we do
    not add a second prefix.
    """
    if not session_id:
        return user
    base = user if user.startswith("user-") else f"user-{user}"
    name = f"{base}-session-{session_id}"
    if duration_min:
        if not 1 <= int(duration_min) <= 1440:
            raise ValueError("sessionduration must be 1..1440 minutes")
        name += f"-sessionduration-{int(duration_min)}"
    REDACTOR.add(name)
    return name
