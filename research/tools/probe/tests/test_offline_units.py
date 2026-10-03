"""Pure unit tests: classifier, extractor, definitions, credentials (no sockets)."""
import base64
import json

import pytest

from probe import classify as C
from probe.creds import Redactor, load_credentials, parse_host, proxy_username, read_dotenv
from probe.definition import DefinitionError, parse_definition
from probe.extract import check_success, extract
from probe.wire import decode_body

from . import servers as S


def fp(status, headers, body):
    return C.fingerprint(status, headers, body)


@pytest.mark.parametrize("status,headers,body,vendor,outcome", [
    (403, [("Server", "cloudflare"), ("CF-RAY", "x"), ("cf-mitigated", "challenge")], S.CF_CHALLENGE, "cloudflare", "challenge"),
    (403, [("X-DataDome", "protected"), ("Set-Cookie", "datadome=a; Path=/")], S.DATADOME_403, "datadome", "captcha"),
    (403, [("Server", "AkamaiGHost"), ("Set-Cookie", "_abck=x; path=/")], S.AKAMAI_DENIED, "akamai", "block_page"),
    (403, [("Set-Cookie", "_px3=a; path=/")], S.PX_403, "perimeterx", "captcha"),
    (200, [("X-Iinfo", "1"), ("Set-Cookie", "visid_incap_1=a; path=/")], S.INCAP_200, "imperva", "challenge"),
    (429, [("x-kpsdk-ct", "a")], b"", "kasada", "challenge"),
    (202, [("x-amzn-waf-action", "challenge")], S.AWS_WAF_202, "aws_waf", "challenge"),
    (403, [("Set-Cookie", "TS01abcdef=1; path=/")], b"The requested URL was rejected. Please consult with your administrator.", "f5_shape", "block_page"),
])
def test_vendor_and_outcome(status, headers, body, vendor, outcome):
    f = fp(status, headers, body)
    assert vendor in f.vendors({"antibot", "challenge", "block", "captcha"})
    assert C.classify(error_kind=None, status=status, fp=f, rows=0, success=False) == outcome
    assert outcome in C.BLOCK_OUTCOMES


def test_normal_page_with_bm_script_and_recaptcha_is_ok():
    f = fp(200, [("Server", "cloudflare"), ("CF-RAY", "x"), ("Set-Cookie", "__cf_bm=a; path=/")], S.NORMAL_HTML)
    j = f.to_json()
    assert j["challenge"] is False and "cloudflare" in j["antibot"] and "cloudflare" in j["cdn"]
    assert "recaptcha" in j["captcha"]
    assert C.classify(error_kind=None, status=200, fp=f, rows=5, success=True) == "ok"


def test_cdn_only_is_not_antibot():
    f = fp(200, [("X-Served-By", "cache-lhr123"), ("X-Fastly-Request-ID", "a")], b"{}")
    assert f.vendors({"cdn"}) == ["fastly"] and f.vendors({"antibot", "challenge", "block"}) == []


def test_other_outcomes():
    nofp = fp(200, [], b"")
    assert C.classify(error_kind="timeout", status=None, fp=nofp, rows=0, success=False) == "error"
    assert C.classify(error_kind=None, status=404, fp=nofp, rows=0, success=False) == "not_found"
    assert C.classify(error_kind=None, status=503, fp=nofp, rows=0, success=False) == "server_error"
    assert C.classify(error_kind=None, status=403, fp=nofp, rows=0, success=False) == "blocked_status"
    assert C.classify(error_kind=None, status=200, fp=nofp, rows=0, success=False) == "empty"


def test_extract_variants():
    body = S.items_json(1)
    assert extract(body, {"type": "json", "path": "data.items"})[0] == 10
    assert extract(body, {"type": "json", "path": "data.items[*].id"})[0] == 10
    assert extract(body, {"type": "json", "path": "data.items[0]"})[0] == 1
    assert extract(body, {"type": "json", "path": "data.missing"})[0] == 0
    n, sample, err = extract(S.NORMAL_HTML, {"type": "css", "selector": "div.item", "fields": {"t": "h2"}})
    assert n == 5 and sample[0] == {"t": "Alpha"} and err is None
    nd = b'<html><script id="__NEXT_DATA__">' + json.dumps({"props": {"items": [1, 2, 3]}}).encode() + b"</script></html>"
    assert extract(nd, {"type": "json_in_html", "selector": "script#__NEXT_DATA__", "path": "props.items"})[0] == 3
    assert extract(body, {"type": "regex", "pattern": r'"id": \d+'})[0] == 10
    assert extract(b"not json", {"type": "json", "path": "a"})[2] is not None
    assert check_success(200, body, 10, {"status": [200], "min_rows": 1, "body_contains": ["items"]})
    assert not check_success(200, body, 0, {"status": [200], "min_rows": 1})
    assert not check_success(403, body, 10, {"status": [200], "min_rows": 1})


def test_decode_body():
    import gzip, zlib
    raw = b"hello" * 100
    assert decode_body(gzip.compress(raw), "gzip") == (raw, None)
    assert decode_body(zlib.compress(raw), "deflate") == (raw, None)
    try:
        import brotli
        assert decode_body(brotli.compress(raw), "br") == (raw, None)
    except ImportError:
        pass
    assert decode_body(b"xx", "zstd")[1].startswith("unsupported")


BASE = {"name": "t-probe", "public_only": True, "urls": ["https://example.com/a"], "extract": {"type": "json", "path": "x"}}


def test_definition_rules():
    d = parse_definition(dict(BASE))
    assert d.urls == ["https://example.com/a"] and "User-Agent" in d.headers
    for bad in (
        {"public_only": False},
        {"name": "Bad Name"},
        {"urls": ["https://u:p@example.com/"]},
        {"urls": ["ftp://example.com/"]},
        {"headers": {"Authorization": "Bearer x"}},
        {"headers": {"Cookie": "a=b"}},
        {"extract": {"type": "css"}},
        {"session": "weird"},
    ):
        with pytest.raises(DefinitionError):
            parse_definition({**BASE, **bad})
    t = parse_definition({**BASE, "urls": [], "url_template": "https://e.com/p/{id}?page={page}",
                          "sample_ids": [{"id": 1, "page": 2}, {"id": 3, "page": 4}]})
    assert t.urls == ["https://e.com/p/1?page=2", "https://e.com/p/3?page=4"] and t.url_for(3) == t.urls[1]
    s = parse_definition({**BASE, "urls": [], "url_template": "https://e.com/x/{slug}", "sample_ids": ["a", "b"]})
    assert s.urls[1] == "https://e.com/x/b"
    w = parse_definition({**BASE, "urls": ["https://e.com/login?x=1"]})
    assert w.warnings


def test_parse_host():
    assert parse_host("gate.decodo.com") == ("gate.decodo.com", 7000)
    assert parse_host("gate.decodo.com:10001") == ("gate.decodo.com", 10001)
    assert parse_host("http://gate.decodo.com:7000/") == ("gate.decodo.com", 7000)
    assert parse_host("[::1]:8080") == ("::1", 8080)


def test_credentials_env_dotenv_and_repr(tmp_path):
    env_file = tmp_path / ".env"
    env_file.write_text('# c\nexport DECODO_USER="dotUser"\nDECODO_PASS=\'dotPass99\'\nDECODO_HOST=gate.decodo.com:7000\n')
    assert read_dotenv(env_file)["DECODO_USER"] == "dotUser"
    c = load_credentials(env={}, dotenv_path=env_file)
    assert (c.user, c.password, c.host, c.port, c.source) == ("dotUser", "dotPass99", "gate.decodo.com", 7000, ".env")
    assert "dotPass99" not in repr(c) and "dotUser" not in str(c)
    c2 = load_credentials(env={"DECODO_USER": "envU", "DECODO_PASS": "envPass1", "DECODO_HOST": "h:1"}, dotenv_path=env_file)
    assert c2.user == "envU" and c2.port == 1
    assert load_credentials(env={}, dotenv_path=tmp_path / "missing") is None


def test_sticky_username_and_redaction():
    assert proxy_username("bob") == "bob"
    assert proxy_username("bob", "abc", 30) == "user-bob-session-abc-sessionduration-30"
    assert proxy_username("user-bob", "abc") == "user-bob-session-abc"
    with pytest.raises(ValueError):
        proxy_username("bob", "abc", 5000)
    r = Redactor()
    r.add("bobUser", "hunter2pass")
    tok = base64.b64encode(b"bobUser:hunter2pass").decode()
    out = r.redact(f"failed for bobUser with hunter2pass Proxy-Authorization: Basic {tok} http://a:b@h/")
    assert "bobUser" not in out and "hunter2pass" not in out and tok not in out and "a:b@" not in out


# ---------------------------------------------------------------- review regressions (review-agent:probe)

def test_cloudflare_jsd_on_normal_page_is_antibot_not_challenge():
    f = fp(200, [("Server", "cloudflare"), ("CF-RAY", "x")], S.CF_JSD_NORMAL)
    assert not f.has("challenge") and "cloudflare" in f.vendors({"antibot"})
    # a 200 page that fails the predicate is "empty" (soft block / drift), not a hard "challenge"
    assert C.classify(error_kind=None, status=200, fp=f, rows=0, success=False) == "empty"
    real = fp(403, [], b"<script src='/cdn-cgi/challenge-platform/h/b/orchestrate/chl_page/v1?ray=1'></script>")
    assert real.has("challenge")


def test_cloudflare_5xx_edge_error_is_server_error_not_block():
    f = fp(522, [("Server", "cloudflare"), ("CF-RAY", "x")], S.CF_522)
    assert not f.has("block") and f.vendors({"antibot", "challenge", "block"}) == []
    assert C.classify(error_kind=None, status=522, fp=f, rows=0, success=False) == "server_error"
    deny = fp(403, [("Server", "cloudflare")], b"<div id='cf-error-details'>Error 1020 Access denied</div>")
    assert C.classify(error_kind=None, status=403, fp=deny, rows=0, success=False) == "block_page"


def test_fetch_never_raises_on_bad_url():
    from probe.wire import fetch
    for u in ("http://127.0.0.1:99999/x", "ftp://example.com/", "http:///nohost"):
        r = fetch(u, timeout=1)
        assert r.error_kind == "invalid" and r.wire_total == 0, (u, r.error)


def test_sticky_basic_token_is_redacted(creds):
    from probe.creds import REDACTOR
    from probe.runner import proxy_for
    ps = proxy_for(creds, "abc123", 30)
    tok = ps.auth_header().split()[1]
    assert tok not in REDACTOR.redact(f"echo {tok}")


def test_host_is_redacted(tmp_path):
    from probe.creds import REDACTOR
    load_credentials(env={"DECODO_USER": "hU", "DECODO_PASS": "hPass77", "DECODO_HOST": "gw.example-proxy.test:7000"},
                     dotenv_path=tmp_path / "none")
    assert "gw.example-proxy.test" not in REDACTOR.redact("connect timeout to gw.example-proxy.test:7000")


def test_per_host_folds_www_and_excludes_errors():
    from probe.runner import per_host

    def rec(url, outcome, nbytes, rows, antibot=()):
        return {"url": url, "outcome": outcome, "bytes_wire_total": nbytes, "rows": rows, "antibot": list(antibot)}
    prox = [rec("https://www.a.com/1", "ok", 1000, 10), rec("https://a.com/2", "error", 500, 0),
            rec("https://www.a.com/3", "challenge", 1500, 0, ["cloudflare"]),
            rec("https://b.org/x", "ok", 2000, 4)]
    ph = per_host(prox, 4.0)
    assert set(ph) == {"a.com", "b.org"}
    a = ph["a.com"]
    assert a["requests"] == 3 and a["ok"] == 1 and a["block_rate"] == 0.5  # 1 block / 2 responded
    assert a["bytes"] == 3000 and a["rows"] == 10 and a["bytes_per_row"] == 300.0
    assert a["cost_per_1k_rows_usd"] == round(300 * 1000 / 1e9 * 4.0, 5) and a["antibot_vendors"] == ["cloudflare"]
    assert ph["b.org"]["block_rate"] == 0 and ph["b.org"]["bytes_per_row"] == 500.0
