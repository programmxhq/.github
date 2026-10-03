"""Offline test servers: a fixture origin (HTTP + HTTPS) and a stub forward proxy.

The stub proxy speaks the same protocol the Decodo gateway does for our client (HTTP proxy,
Basic Proxy-Authorization, CONNECT for https, absolute-form for http) and counts every byte
it reads from / writes to the client, so tests can assert our wire accounting is exact.
"""
from __future__ import annotations

import base64
import datetime
import gzip
import ipaddress
import json
import os
import select
import socket
import ssl
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

# ------------------------------------------------------------------ fixtures

CF_CHALLENGE = b"""<!DOCTYPE html><html lang="en-US"><head><title>Just a moment...</title>
<meta http-equiv="refresh" content="390"></head><body><div class="main-wrapper">
<noscript>Enable JavaScript and cookies to continue</noscript>
<script>(function(){window._cf_chl_opt={cvId: '3',cZone: 'example.com',cType: 'managed'};
var a = document.createElement('script');a.src = '/cdn-cgi/challenge-platform/h/b/orchestrate/chl_page/v1?ray=8f00';
document.getElementsByTagName('head')[0].appendChild(a);}());</script></div></body></html>"""

DATADOME_403 = b"""<html><head><title>example.com</title></head><body style="margin:0">
<p id="cmsg">Please enable JS and disable any ad blocker</p>
<script data-cfasync="false">var dd={'rt':'c','cid':'AHrlqAAAAAMA','hsh':'ABC','t':'fe','s':41,'host':'geo.captcha-delivery.com'}</script>
<script data-cfasync="false" src="https://ct.captcha-delivery.com/c.js"></script></body></html>"""

AKAMAI_DENIED = b"""<HTML><HEAD><TITLE>Access Denied</TITLE></HEAD><BODY><H1>Access Denied</H1>
You don't have permission to access "http&#58;&#47;&#47;www&#46;example&#46;com&#47;" on this server.<P>
Reference&#32;&#35;18&#46;5c2a1302&#46;1700000000&#46;1a2b3c<P>https&#58;&#47;&#47;errors&#46;edgesuite&#46;net&#47;18&#46;5c2a1302
</BODY></HTML>"""

PX_403 = b"""<html><head><title>Access to this page has been denied</title></head><body>
<div id="px-captcha"></div><script>window._pxAppId = 'PXabc123';</script>
<script src="//client.perimeterx.net/PXabc123/main.min.js"></script><p>Press &amp; Hold to confirm you are a human</p></body></html>"""

INCAP_200 = b"""<html><head><META NAME="robots" CONTENT="noindex,nofollow">
<script src="/_Incapsula_Resource?SWJIYLWA=5074a744e2e3d891814e9a2dace20bd4,719d34d31c8e3a6e6fffd425f7e032f3"></script>
</head><body></body></html>"""

AWS_WAF_202 = b"""<!DOCTYPE html><html><head><script>window.gokuProps = {"key":"AQIDAHj"};</script>
<script src="https://abc.edge.sdk.awswaf.com/abc/def/challenge.js"></script></head><body></body></html>"""

NORMAL_HTML = b"""<!doctype html><html><head><title>Products</title>
<script src="/cdn-cgi/challenge-platform/scripts/jsd/main.js"></script></head><body>
<form><div class="g-recaptcha" data-sitekey="x"></div></form>
<div class="item"><h2>Alpha</h2><span class="price">1</span></div>
<div class="item"><h2>Beta</h2><span class="price">2</span></div>
<div class="item"><h2>Gamma</h2><span class="price">3</span></div>
<div class="item"><h2>Delta</h2><span class="price">4</span></div>
<div class="item"><h2>Epsilon</h2><span class="price">5</span></div>
</body></html>"""


CF_522 = b"""<!DOCTYPE html><html><head><title>example.com | 522: Connection timed out</title></head>
<body><div id="cf-wrapper"><div id="cf-error-details" class="cf-error-details-wrapper">
<h1>Connection timed out</h1><span>Error code 522</span></div></div></body></html>"""

CF_JSD_NORMAL = b"""<html><body><div class="item"><h2>Alpha</h2></div>
<script>(function(){var a=document.createElement('script');
a.src='/cdn-cgi/challenge-platform/h/g/scripts/jsd/e4025c85ea63/main.js';document.body.appendChild(a)})();</script>
</body></html>"""


def items_json(page: int, n: int = 10) -> bytes:
    items = [{"id": page * 100 + i, "title": f"Item {page}-{i}", "price": 9.99 + i,
              "description": "lorem ipsum dolor sit amet " * 8} for i in range(n)]
    return json.dumps({"data": {"items": items, "page": page}}).encode()


class FixtureHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = "fixture/1.0"

    def log_message(self, *a):  # quiet
        pass

    def _send(self, status, body=b"", headers=(), ctype="text/html; charset=utf-8", allow_gzip=True):
        ae = self.headers.get("Accept-Encoding", "")
        enc = None
        if allow_gzip and body and "gzip" in ae:
            body = gzip.compress(body, mtime=0)
            enc = "gzip"
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        if enc:
            self.send_header("Content-Encoding", enc)
        for k, v in headers:
            self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def do_HEAD(self):
        self.do_GET()

    def do_POST(self):
        n = int(self.headers.get("Content-Length") or 0)
        self.rfile.read(n)
        self.do_GET()

    def do_GET(self):
        parts = urlsplit(self.path)  # absolute-form when forwarded by the stub proxy
        path, q = parts.path, parse_qs(parts.query)
        page = int((q.get("page") or ["1"])[0])
        J = "application/json"
        if path == "/api/items":
            return self._send(200, items_json(page), [("Server", "cloudflare"), ("CF-RAY", "8f00-LHR")], J)
        if path == "/api/empty":
            return self._send(200, json.dumps({"data": {"items": []}}).encode(), ctype=J)
        if path == "/api/fat":  # one row padded with incompressible bytes -> expensive per row
            pad = base64.b64encode(os.urandom(300_000)).decode()
            return self._send(200, json.dumps({"data": {"items": [{"id": 1, "blob": pad}]}}).encode(), ctype=J)
        if path == "/big":
            blob = base64.b64encode(os.urandom(int((q.get("kb") or ["60"])[0]) * 768)).decode()
            return self._send(200, json.dumps({"data": {"items": [{"blob": blob}]}}).encode(), ctype=J)
        if path == "/html/list":
            return self._send(200, NORMAL_HTML, [("Server", "cloudflare"), ("CF-RAY", "8f01-LHR"),
                                                 ("Set-Cookie", "__cf_bm=abc; path=/; HttpOnly")])
        if path == "/cf-challenge":
            return self._send(403, CF_CHALLENGE, [("Server", "cloudflare"), ("CF-RAY", "8f02-LHR"),
                                                  ("cf-mitigated", "challenge")])
        if path == "/datadome":
            return self._send(403, DATADOME_403, [("X-DataDome", "protected"), ("X-DD-B", "1"),
                                                  ("Set-Cookie", "datadome=AbC~123; Max-Age=31536000; Path=/")])
        if path == "/akamai":
            return self._send(403, AKAMAI_DENIED, [("Server", "AkamaiGHost"), ("Set-Cookie", "_abck=xyz~-1~; path=/"),
                                                   ("Set-Cookie", "bm_sz=123; path=/")])
        if path == "/px":
            return self._send(403, PX_403, [("Set-Cookie", "_pxhd=abc:def; path=/"), ("Set-Cookie", "_px3=zzz; path=/")])
        if path == "/incap":
            return self._send(200, INCAP_200, [("X-Iinfo", "13-1234-0 0NNN RT(1700000000 0)"), ("X-CDN", "Imperva"),
                                               ("Set-Cookie", "visid_incap_123=abc; path=/"),
                                               ("Set-Cookie", "incap_ses_1_123=def; path=/")])
        if path == "/kasada":
            return self._send(429, b"", [("x-kpsdk-ct", "0abc"), ("x-kpsdk-r", "1-B")])
        if path == "/awswaf":
            return self._send(202, AWS_WAF_202, [("x-amzn-waf-action", "challenge")])
        if path == "/redirect":
            return self._send(302, b"", [("Location", f"/api/items?page={page}")])
        if path == "/redirect-bad":  # hostile Location: port out of range
            return self._send(302, b"", [("Location", "http://127.0.0.1:99999/x")])
        if path == "/cf-origin-down":  # Cloudflare 522 edge error page: origin outage, not a block
            return self._send(522, CF_522, [("Server", "cloudflare"), ("CF-RAY", "8f03-LHR")])
        if path == "/slow":
            time.sleep(3)
            return self._send(200, items_json(1), ctype=J)
        if path == "/json-ip":
            return self._send(200, json.dumps({"proxy": {"ip": "203.0.113.7"}, "country": {"code": "US"}}).encode(), ctype=J)
        return self._send(404, b"<h1>Not found</h1>")


def make_cert(tmpdir) -> tuple[str, str]:
    from cryptography import x509
    from cryptography.hazmat.primitives import hashes, serialization
    from cryptography.hazmat.primitives.asymmetric import ec
    from cryptography.x509.oid import NameOID

    key = ec.generate_private_key(ec.SECP256R1())
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "localhost")])
    now = datetime.datetime.now(datetime.timezone.utc)
    cert = (x509.CertificateBuilder().subject_name(name).issuer_name(name).public_key(key.public_key())
            .serial_number(x509.random_serial_number()).not_valid_before(now - datetime.timedelta(days=1))
            .not_valid_after(now + datetime.timedelta(days=2))
            .add_extension(x509.SubjectAlternativeName([x509.DNSName("localhost"),
                                                        x509.IPAddress(ipaddress.ip_address("127.0.0.1"))]), False)
            .add_extension(x509.BasicConstraints(ca=True, path_length=None), True)
            .sign(key, hashes.SHA256()))
    cp, kp = os.path.join(tmpdir, "cert.pem"), os.path.join(tmpdir, "key.pem")
    with open(cp, "wb") as f:
        f.write(cert.public_bytes(serialization.Encoding.PEM))
    with open(kp, "wb") as f:
        f.write(key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                  serialization.NoEncryption()))
    return cp, kp


class FixtureServer:
    def __init__(self, cert: tuple[str, str] | None = None):
        self.httpd = ThreadingHTTPServer(("127.0.0.1", 0), FixtureHandler)
        self.httpd.daemon_threads = True
        self.tls = cert is not None
        if cert:
            ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
            ctx.load_cert_chain(*cert)
            self.httpd.socket = ctx.wrap_socket(self.httpd.socket, server_side=True)
        self.port = self.httpd.server_address[1]
        self.t = threading.Thread(target=self.httpd.serve_forever, daemon=True)
        self.t.start()

    def url(self, path: str) -> str:
        return f"{'https' if self.tls else 'http'}://{'localhost' if self.tls else '127.0.0.1'}:{self.port}{path}"

    def close(self):
        self.httpd.shutdown()
        self.httpd.server_close()


# ------------------------------------------------------------------ stub forward proxy

class StubProxy:
    """HTTP forward proxy. auth=None accepts anyone (used as an 'upstream' egress proxy)."""

    def __init__(self, user: str | None = None, password: str | None = None):
        self.user, self.password = user, password
        self.sock = socket.socket()
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind(("127.0.0.1", 0))
        self.sock.listen(64)
        self.port = self.sock.getsockname()[1]
        self.conns: list[dict] = []
        self.lock = threading.Lock()
        self._stop = False
        threading.Thread(target=self._accept, daemon=True).start()

    def _accept(self):
        while not self._stop:
            try:
                c, _ = self.sock.accept()
            except OSError:
                return
            threading.Thread(target=self._handle, args=(c,), daemon=True).start()

    def _auth_ok(self, headers: dict) -> tuple[bool, str | None]:
        if self.user is None:
            return True, None
        val = headers.get("proxy-authorization", "")
        if not val.lower().startswith("basic "):
            return False, None
        u, _, p = base64.b64decode(val[6:]).decode().partition(":")
        ok = p == self.password and (u == self.user or u.startswith(f"user-{self.user}-session-"))
        return ok, u

    def _handle(self, c: socket.socket):
        st = {"client_in": 0, "client_out": 0, "username": None, "target": None, "method": None, "done": False}
        with self.lock:
            self.conns.append(st)
        t = None
        try:
            head = b""
            while b"\r\n\r\n" not in head:
                d = c.recv(4096)
                if not d:
                    return
                head += d
            st["client_in"] += len(head)
            hdr, _, rest = head.partition(b"\r\n\r\n")
            lines = hdr.decode("latin-1").split("\r\n")
            method, target, _ = lines[0].split(" ", 2)
            headers = {}
            for ln in lines[1:]:
                k, _, v = ln.partition(":")
                headers[k.strip().lower()] = v.strip()
            st["method"], st["target"] = method, target
            ok, u = self._auth_ok(headers)
            st["username"] = u
            if not ok:
                msg = b"HTTP/1.1 407 Proxy Authentication Required\r\nProxy-Authenticate: Basic realm=\"stub\"\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
                c.sendall(msg)
                st["client_out"] += len(msg)
                return
            if method == "CONNECT":
                host, port = target.rsplit(":", 1)
                t = socket.create_connection((host, int(port)), timeout=10)
                msg = b"HTTP/1.1 200 Connection established\r\n\r\n"
                c.sendall(msg)
                st["client_out"] += len(msg)
                if rest:
                    t.sendall(rest)
            else:
                p = urlsplit(target)
                t = socket.create_connection((p.hostname, p.port or 80), timeout=10)
                fwd = "\r\n".join(ln for ln in lines if not ln.lower().startswith("proxy-authorization"))
                t.sendall(fwd.encode("latin-1") + b"\r\n\r\n" + rest)
            self._relay(c, t, st)
        except Exception:
            pass
        finally:
            for s in (c, t):
                try:
                    s and s.close()
                except OSError:
                    pass
            st["done"] = True

    def _relay(self, c, t, st):
        socks = [c, t]
        while True:
            r, _, _ = select.select(socks, [], [], 10)
            if not r:
                return
            for s in r:
                try:
                    d = s.recv(65536)
                except OSError:
                    d = b""
                if not d:
                    return
                if s is c:
                    st["client_in"] += len(d)
                    t.sendall(d)
                else:
                    c.sendall(d)
                    st["client_out"] += len(d)

    def wait_idle(self, timeout: float = 5.0):
        end = time.time() + timeout
        while time.time() < end:
            with self.lock:
                if all(s["done"] for s in self.conns):
                    return
            time.sleep(0.01)

    def total(self) -> int:
        self.wait_idle()
        with self.lock:
            return sum(s["client_in"] + s["client_out"] for s in self.conns)

    def close(self):
        self._stop = True
        self.sock.close()
