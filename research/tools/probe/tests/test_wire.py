"""Byte accounting through a local stub proxy: our counts must equal what the proxy saw."""
from probe.wire import ProxySpec, fetch

from .conftest import TEST_PASS, TEST_USER
from .servers import StubProxy


def spec(proxy, user=TEST_USER, pw=TEST_PASS):
    return ProxySpec("127.0.0.1", proxy.port, user, pw)


def test_direct_http_gzip(origin_http):
    r = fetch(origin_http.url("/api/items?page=2"), timeout=5)
    assert r.status == 200 and r.error is None and r.content_encoding == "gzip"
    assert r.body_compressed_bytes < r.body_decoded_bytes
    assert b'"page": 2' in r.body
    # plain HTTP: app bytes == wire bytes, and recv = status/headers + compressed body
    assert r.wire_recv == r.app_recv == r.resp_header_bytes + r.body_compressed_bytes


def test_http_via_proxy_exact_bytes(origin_http, proxy):
    r = fetch(origin_http.url("/api/items"), proxy=spec(proxy), timeout=5)
    assert r.status == 200 and r.error is None
    assert proxy.total() == r.wire_total
    assert proxy.conns[0]["method"] == "GET" and proxy.conns[0]["username"] == TEST_USER


def test_https_connect_exact_bytes(origin, proxy, cert):
    r = fetch(origin.url("/api/items"), proxy=spec(proxy), timeout=5, ca_file=cert[0])
    assert r.status == 200 and r.error is None, r.error
    assert proxy.conns[0]["method"] == "CONNECT"
    assert proxy.total() == r.wire_total
    # TLS + CONNECT overhead is billed on top of the HTTP bytes
    assert r.wire_total > r.app_sent + r.app_recv
    assert r.app_recv == r.resp_header_bytes + r.body_compressed_bytes


def test_bad_password_is_proxy_auth_and_redacted(origin, proxy, cert):
    from probe.creds import REDACTOR
    REDACTOR.add(TEST_USER, "wrong-password-123")
    r = fetch(origin.url("/api/items"), proxy=spec(proxy, pw="wrong-password-123"), timeout=5, ca_file=cert[0])
    assert r.error_kind == "proxy_auth" and r.proxy_status == 407
    assert "wrong-password-123" not in REDACTOR.redact(r.error)
    assert proxy.total() == r.wire_total  # failed requests are still billed traffic


def test_http_407(origin_http, proxy):
    r = fetch(origin_http.url("/api/items"), proxy=spec(proxy, pw="nope-nope"), timeout=5)
    assert r.error_kind == "proxy_auth"


def test_byte_limit_never_exceeded(origin, proxy, cert):
    r = fetch(origin.url("/big?kb=200"), proxy=spec(proxy), timeout=5, ca_file=cert[0], byte_limit=20_000)
    assert r.error_kind == "byte_limit"
    assert r.wire_total <= 20_000
    assert proxy.total() <= 20_000  # the proxy never received/sent more than we allowed ourselves


def test_timeout(origin_http):
    r = fetch(origin_http.url("/slow"), timeout=1)
    assert r.error_kind == "timeout"


def test_truncation(origin_http):
    r = fetch(origin_http.url("/big?kb=100"), timeout=5, max_body_bytes=10_000)
    assert r.truncated and r.body_compressed_bytes >= 10_000


def test_upstream_chain(origin, proxy, cert):
    up = StubProxy()  # no auth, plays the container egress proxy
    try:
        r = fetch(origin.url("/api/items"), proxy=spec(proxy), upstream=ProxySpec("127.0.0.1", up.port),
                  timeout=5, ca_file=cert[0])
        assert r.status == 200 and r.error is None, r.error
        assert up.conns[0]["target"] == f"127.0.0.1:{proxy.port}"
        assert up.total() == r.wire_total
    finally:
        up.close()
