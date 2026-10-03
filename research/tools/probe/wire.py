"""HTTP/1.1 client with on-the-wire byte accounting.

Why stdlib instead of requests/httpx: Decodo bills residential traffic by bytes through the
gateway. For an https:// target the gateway only sees an opaque CONNECT tunnel, so the
billable volume is: CONNECT request/response + TLS handshake + encrypted TLS records (which
carry the *compressed* body). requests/httpx hand TLS to the ssl module inside the socket,
so encrypted byte counts are invisible to Python code. Here we run TLS over ssl.MemoryBIO on
top of a counting TCP socket, so every byte written to / read from the proxy socket is
counted exactly. TCP/IP header overhead is not counted (providers bill payload traffic).

One fresh TCP connection per request (Connection: close). That is conservative: production
scrapers with keep-alive amortise the TLS handshake (~4-7 KB), so real cost per row is at
or below what we measure.

Early aborts (byte allowance hit, body truncated): the gateway has usually already sent bytes
we never read. We (1) shrink SO_RCVBUF on proxied sockets to bound data in flight, (2) count
whatever is already sitting in the kernel receive buffer as billed (`unread_drained_bytes`),
(3) close with RST so the transfer stops. Bytes still in flight or in the gateway's own
send buffer cannot be seen from here; the runner keeps `abort_margin_bytes` of headroom
under the cap to absorb them.
"""
from __future__ import annotations

import base64
import gzip
import http.client
import io
import socket
import ssl
import struct
import time
import zlib
from dataclasses import dataclass, field
from urllib.parse import urlsplit

try:
    import brotli  # type: ignore
except ImportError:  # pragma: no cover
    brotli = None

MAX_DECODED = 50_000_000


class ByteLimitExceeded(Exception):
    """Raised before a send/recv would push this request past its byte allowance."""


class ProxyConnectError(Exception):
    def __init__(self, status: int, reason: str):
        super().__init__(f"proxy CONNECT failed: {status} {reason}")
        self.status = status
        self.reason = reason


@dataclass
class ProxySpec:
    host: str
    port: int
    username: str | None = None
    password: str | None = None

    def auth_header(self) -> str | None:
        if self.username is None:
            return None
        tok = base64.b64encode(f"{self.username}:{self.password or ''}".encode()).decode()
        return f"Basic {tok}"

    def __repr__(self) -> str:
        return f"ProxySpec(host={self.host!r}, port={self.port}, auth={'yes' if self.username else 'no'})"


@dataclass
class Counter:
    wire_sent: int = 0
    wire_recv: int = 0
    app_sent: int = 0  # plaintext HTTP bytes handed to TLS (or to the socket for http://)
    app_recv: int = 0
    limit: int | None = None
    deadline: float | None = None

    @property
    def wire_total(self) -> int:
        return self.wire_sent + self.wire_recv

    def room(self) -> int | None:
        return None if self.limit is None else self.limit - self.wire_total


class _RawAdapter(io.RawIOBase):
    def __init__(self, stream):
        self._s = stream

    def readable(self) -> bool:
        return True

    def readinto(self, b) -> int:
        data = self._s.recv(len(b))
        n = len(data)
        b[:n] = data
        return n


class _StreamBase:
    def makefile(self, mode="rb", *args, **kwargs):
        return io.BufferedReader(_RawAdapter(self), buffer_size=65536)


class CountingSocket(_StreamBase):
    def __init__(self, sock: socket.socket, counter: Counter, count_app: bool = False):
        self.sock = sock
        self.c = counter
        self.count_app = count_app  # True for plain http (no TLS layer above us)

    def _check_deadline(self):
        if self.c.deadline is not None and time.monotonic() > self.c.deadline:
            raise TimeoutError("request deadline exceeded")

    def sendall(self, data) -> None:
        self._check_deadline()
        room = self.c.room()
        if room is not None and len(data) > room:
            raise ByteLimitExceeded(f"send of {len(data)} B would exceed byte allowance")
        self.sock.sendall(data)
        self.c.wire_sent += len(data)
        if self.count_app:
            self.c.app_sent += len(data)

    def recv(self, n: int) -> bytes:
        self._check_deadline()
        room = self.c.room()
        if room is not None:
            if room <= 0:
                raise ByteLimitExceeded("byte allowance exhausted while receiving")
            n = min(n, room)
        data = self.sock.recv(n)
        self.c.wire_recv += len(data)
        if self.count_app:
            self.c.app_recv += len(data)
        return data

    def settimeout(self, t):
        self.sock.settimeout(t)

    def close(self):
        try:
            self.sock.close()
        except OSError:
            pass


class TLSStream(_StreamBase):
    """TLS over MemoryBIO so the underlying CountingSocket sees the encrypted bytes."""

    def __init__(self, raw: CountingSocket, ctx: ssl.SSLContext, server_hostname: str):
        self.raw = raw
        self.c = raw.c
        self.inc = ssl.MemoryBIO()
        self.out = ssl.MemoryBIO()
        self.obj = ctx.wrap_bio(self.inc, self.out, server_hostname=server_hostname)
        self._eof = False
        self._handshake()

    def _flush(self):
        data = self.out.read()
        if data:
            self.raw.sendall(data)

    def _fill(self):
        data = self.raw.recv(65536)
        if not data:
            self.inc.write_eof()
            self._eof = True
        else:
            self.inc.write(data)

    def _handshake(self):
        while True:
            try:
                self.obj.do_handshake()
                self._flush()
                return
            except ssl.SSLWantReadError:
                self._flush()
                if self._eof:
                    raise ConnectionError("EOF during TLS handshake")
                self._fill()

    def sendall(self, data) -> None:
        view = memoryview(bytes(data))
        while view:
            try:
                n = self.obj.write(view)
            except ssl.SSLWantReadError:
                self._flush()
                self._fill()
                continue
            self.c.app_sent += n
            view = view[n:]
            self._flush()

    def recv(self, n: int) -> bytes:
        while True:
            try:
                data = self.obj.read(n)
                self.c.app_recv += len(data)
                return data
            except ssl.SSLWantReadError:
                self._flush()
                if self._eof:
                    return b""
                self._fill()
            except (ssl.SSLZeroReturnError, ssl.SSLEOFError):
                return b""

    def settimeout(self, t):
        self.raw.settimeout(t)

    def close(self):
        self.raw.close()


DEFAULT_PROXY_RCVBUF = 131072


def _open_socket(host: str, port: int, timeout: float, rcvbuf: int | None) -> socket.socket:
    """Like socket.create_connection, but sets SO_RCVBUF *before* connect (window scaling)."""
    err: Exception | None = None
    for af, st, proto, _, sa in socket.getaddrinfo(host, port, 0, socket.SOCK_STREAM):
        sock = socket.socket(af, st, proto)
        try:
            if rcvbuf:
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, rcvbuf)
            sock.settimeout(timeout)
            sock.connect(sa)
            return sock
        except socket.timeout as e:
            sock.close()
            err = TimeoutError(f"connect timeout to {host}:{port}")
        except OSError as e:
            sock.close()
            err = e
    raise err or OSError(f"getaddrinfo returned nothing for {host}")


def _drain_buffered(sock: socket.socket, cap: int = 8_000_000) -> int:
    """Count (and discard) bytes already received by the kernel but not read by us."""
    n = 0
    try:
        while n < cap:
            d = sock.recv(65536, socket.MSG_DONTWAIT)
            if not d:
                break
            n += len(d)
    except (BlockingIOError, InterruptedError, OSError):
        pass
    return n


@dataclass
class FetchResult:
    url: str
    status: int | None = None
    reason: str = ""
    headers: list[tuple[str, str]] = field(default_factory=list)
    body: bytes = b""
    body_compressed_bytes: int = 0
    body_decoded_bytes: int = 0
    resp_header_bytes: int = 0
    content_encoding: str = ""
    decode_error: str | None = None
    truncated: bool = False
    wire_sent: int = 0
    wire_recv: int = 0
    app_sent: int = 0
    app_recv: int = 0
    elapsed_ms: float = 0.0
    ttfb_ms: float | None = None
    error: str | None = None
    error_kind: str | None = None  # connect|timeout|proxy_auth|proxy_error|tls|byte_limit|protocol|other
    proxy_status: int | None = None
    unread_drained_bytes: int = 0  # billed bytes counted from the kernel buffer after an early abort

    @property
    def wire_total(self) -> int:
        return self.wire_sent + self.wire_recv

    def header(self, name: str) -> str | None:
        name = name.lower()
        for k, v in self.headers:
            if k.lower() == name:
                return v
        return None

    def header_all(self, name: str) -> list[str]:
        name = name.lower()
        return [v for k, v in self.headers if k.lower() == name]


def _read_head(stream: CountingSocket, max_bytes: int = 65536) -> bytes:
    buf = bytearray()
    while not buf.endswith(b"\r\n\r\n"):
        ch = stream.recv(1)
        if not ch:
            raise ConnectionError("proxy closed connection during CONNECT")
        buf += ch
        if len(buf) > max_bytes:
            raise ConnectionError("oversized proxy response head")
    return bytes(buf)


def _connect_via(stream: CountingSocket, host: str, port: int, proxy: ProxySpec) -> None:
    lines = [f"CONNECT {host}:{port} HTTP/1.1", f"Host: {host}:{port}"]
    auth = proxy.auth_header()
    if auth:
        lines.append(f"Proxy-Authorization: {auth}")
    stream.sendall(("\r\n".join(lines) + "\r\n\r\n").encode("latin-1"))
    head = _read_head(stream).decode("latin-1")
    first = head.split("\r\n", 1)[0]
    parts = first.split(" ", 2)
    status = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 0
    if status != 200:
        raise ProxyConnectError(status, parts[2] if len(parts) > 2 else "")


def decode_body(raw: bytes, encoding: str) -> tuple[bytes, str | None]:
    enc = (encoding or "").strip().lower()
    if not enc or enc == "identity" or not raw:
        return raw, None
    try:
        out = raw
        for e in [x.strip() for x in enc.split(",")][::-1]:
            if e in ("gzip", "x-gzip"):
                d = zlib.decompressobj(16 + zlib.MAX_WBITS)
                out = d.decompress(out, MAX_DECODED)
            elif e == "deflate":
                try:
                    out = zlib.decompressobj().decompress(out, MAX_DECODED)
                except zlib.error:
                    out = zlib.decompressobj(-zlib.MAX_WBITS).decompress(out, MAX_DECODED)
            elif e == "br":
                if brotli is None:
                    return raw, "brotli not installed"
                out = brotli.decompress(out)
            elif e == "identity":
                continue
            else:
                return raw, f"unsupported content-encoding {e}"
        return out, None
    except Exception as exc:  # truncated or corrupt
        try:
            if enc in ("gzip", "x-gzip"):
                return gzip.decompress(raw), None
        except Exception:
            pass
        return raw, f"decode failed: {type(exc).__name__}"


def default_accept_encoding() -> str:
    return "gzip, deflate, br" if brotli is not None else "gzip, deflate"


def fetch(
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    body: bytes | None = None,
    proxy: ProxySpec | None = None,
    upstream: ProxySpec | None = None,
    timeout: float = 30.0,
    max_body_bytes: int = 5_000_000,
    byte_limit: int | None = None,
    ca_file: str | None = None,
    rcvbuf: int | None = DEFAULT_PROXY_RCVBUF,
) -> FetchResult:
    """One request on one fresh connection. Never raises; errors land in FetchResult.error."""
    parts = urlsplit(url)
    scheme = parts.scheme.lower()
    host = parts.hostname or ""
    port = parts.port or (443 if scheme == "https" else 80)
    path = parts.path or "/"
    if parts.query:
        path += "?" + parts.query
    res = FetchResult(url=url)
    c = Counter(limit=byte_limit, deadline=time.monotonic() + timeout)
    t0 = time.monotonic()
    raw: CountingSocket | None = None
    try:
        hop_host, hop_port = (upstream.host, upstream.port) if upstream else (
            (proxy.host, proxy.port) if proxy else (host, port))
        sock = _open_socket(hop_host, hop_port, timeout, rcvbuf if (proxy or upstream) else None)
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        plain_via_proxy = proxy is not None and scheme == "http"
        raw = CountingSocket(sock, c, count_app=(scheme == "http"))
        if upstream and proxy:
            _connect_via(raw, proxy.host, proxy.port, upstream)  # chain: upstream -> decodo
        if proxy and scheme == "https":
            try:
                _connect_via(raw, host, port, proxy)
            except ProxyConnectError as e:
                res.proxy_status = e.status
                raise
            # CONNECT bytes are billed but are not HTTP payload
            c.app_sent = c.app_recv = 0
        stream: _StreamBase
        if scheme == "https":
            ctx = ssl.create_default_context(cafile=ca_file) if ca_file else ssl.create_default_context()
            ctx.set_alpn_protocols(["http/1.1"])
            stream = TLSStream(raw, ctx, host)
        else:
            stream = raw
        conn = http.client.HTTPConnection(host, port, timeout=timeout)
        conn.sock = stream  # type: ignore[assignment]
        hdrs = dict(headers or {})
        lower = {k.lower() for k in hdrs}
        if "accept-encoding" not in lower:
            hdrs["Accept-Encoding"] = default_accept_encoding()
        hdrs.setdefault("Connection", "close")
        if plain_via_proxy:
            auth = proxy.auth_header() if proxy else None
            if auth:
                hdrs["Proxy-Authorization"] = auth
            target = url  # absolute-form for an HTTP proxy
        else:
            target = path
        conn.request(method, target, body=body, headers=hdrs)
        resp = conn.getresponse()
        res.ttfb_ms = (time.monotonic() - t0) * 1000
        res.status = resp.status
        res.reason = resp.reason
        res.headers = list(resp.getheaders())
        res.resp_header_bytes = len(f"HTTP/1.1 {resp.status} {resp.reason}\r\n") + sum(
            len(k) + len(v) + 4 for k, v in res.headers) + 2
        if plain_via_proxy and resp.status == 407:
            res.proxy_status = 407
        chunks = []
        got = 0
        while True:
            chunk = resp.read(65536)
            if not chunk:
                break
            chunks.append(chunk)
            got += len(chunk)
            if got >= max_body_bytes:
                res.truncated = True
                break
        raw_body = b"".join(chunks)
        res.body_compressed_bytes = len(raw_body)
        res.content_encoding = res.header("content-encoding") or ""
        res.body, res.decode_error = decode_body(raw_body, res.content_encoding)
        res.body_decoded_bytes = len(res.body)
        if res.proxy_status == 407:
            res.error, res.error_kind = "proxy authentication failed (407)", "proxy_auth"
    except ByteLimitExceeded as e:
        res.error, res.error_kind = str(e), "byte_limit"
    except ProxyConnectError as e:
        res.error = str(e)
        res.error_kind = "proxy_auth" if e.status == 407 else "proxy_error"
    except (TimeoutError, socket.timeout) as e:
        res.error, res.error_kind = f"timeout: {e}", "timeout"
    except ssl.SSLError as e:
        res.error, res.error_kind = f"tls: {e}", "tls"
    except (http.client.HTTPException,) as e:
        res.error, res.error_kind = f"protocol: {type(e).__name__}: {e}", "protocol"
    except (ConnectionError, OSError) as e:
        res.error, res.error_kind = f"connect: {type(e).__name__}: {e}", "connect"
    except Exception as e:  # pragma: no cover - last resort, keep the run alive
        res.error, res.error_kind = f"{type(e).__name__}: {e}", "other"
    finally:
        if raw is not None:
            early = res.truncated or res.error_kind in ("byte_limit", "timeout", "protocol", "tls", "other")
            # Always count stragglers already in the kernel buffer (they were transmitted and billed).
            drained = _drain_buffered(raw.sock)
            c.wire_recv += drained
            res.unread_drained_bytes = drained
            if early:
                try:  # RST instead of FIN: tell the gateway to stop sending now
                    raw.sock.setsockopt(socket.SOL_SOCKET, socket.SO_LINGER, struct.pack("ii", 1, 0))
                except OSError:
                    pass
            raw.close()
        res.wire_sent, res.wire_recv = c.wire_sent, c.wire_recv
        res.app_sent, res.app_recv = c.app_sent, c.app_recv
        res.elapsed_ms = (time.monotonic() - t0) * 1000
    return res
