"""Anti-bot vendor fingerprinting and per-response block classification.

Marker sources (all gathered via WebSearch on 2026-10-03; summaries, not first-hand reads,
so treat individual markers as UNVERIFIED until seen in live probe data):
  [S1] Cloudflare docs, "Detect a Challenge Page response" (cf-mitigated: challenge):
       https://developers.cloudflare.com/cloudflare-challenges/challenge-types/challenge-pages/detect-response/
  [S2] DEV Community, "Cloudflare managed vs JS vs interactive challenge: how to tell from the response"
       (_cf_chl_opt, /cdn-cgi/challenge-platform/h/.../orchestrate/chl_page, "Just a moment..."):
       https://dev.to/bshahin/managed-vs-interactive-cloudflare-challenge-how-to-tell-and-why-it-changes-your-fix-3in0
  [S3] Scrappey, "Anti-Bot Vendor Detection Cheatsheet" (Akamai _abck/bm_sz/sbsd/sec_cpt/bm_sc/bm_s;
       PerimeterX _px2/_px3/_pxhd/_pxde; DataDome datadome/_dd_s; Imperva incap_ses_/visid_incap_/reese84;
       Kasada x-kpsdk-ct/x-kpsdk-cd/KP_UIDz):
       https://scrappey.com/qa/anti-bot/anti-bot-vendor-detection-cheatsheet
  [S4] microlinkhq/is-antibot (30+ providers; cf-ray, x-datadome, x-iinfo, _abck, _pxhd, visid_incap):
       https://github.com/microlinkhq/is-antibot
  [S5] Scrapfly, "How to Bypass AWS WAF" (x-amzn-waf-action: challenge, HTTP 202/405, aws-waf-token, awswaf.com):
       https://scrapfly.io/blog/posts/how-to-bypass-aws-waf-when-web-scraping
  [S6] Scrapfly, "How to Bypass F5 Bot Defense" (TS01* / TSPD_101* cookies, BIGipServer*):
       https://scrapfly.io/blog/posts/how-to-bypass-f5-when-web-scraping
  [S7] Medium (dimakynal), "Hidden Fingerprints of Bot Protection" (Fastly x-served-by, x-timer,
       x-fastly-request-id; Shape x-sh-pointer):
       https://medium.com/@dimakynal/the-hidden-fingerprints-of-bot-protection-how-every-major-vendor-leaves-traces-in-your-browser-ae951e355606
  [S8] Cloudflare Turnstile / hCaptcha / reCAPTCHA embed URLs (public widget docs; well known script hosts).

Kinds:
  cdn       - CDN / load balancer presence only. NOT evidence of bot management.
  antibot   - bot-management product present (cookie / header / sensor script).
  challenge - this response IS an interstitial / JS challenge.
  captcha   - this response embeds a captcha widget.
  block     - this response is a vendor block page (hard deny).
A captcha/antibot marker on a page that still yields the expected rows is recorded but the
response is classified "ok" (e.g. a product page with a reCAPTCHA newsletter form).
"""
from __future__ import annotations

import html
import re
from dataclasses import dataclass
from http.cookies import SimpleCookie

BODY_SCAN_LIMIT = 400_000

# (vendor, kind, location, matcher, label, source)
# location: "header" (name present), "header_value" (name, regex on value),
#           "cookie" (regex on cookie name), "body" (case-insensitive substring)
RULES: list[tuple] = [
    # --- Cloudflare [S1][S2][S4]
    ("cloudflare", "cdn", "header", "cf-ray", "cf-ray header", "S4"),
    ("cloudflare", "cdn", "header_value", ("server", r"cloudflare"), "server: cloudflare", "S4"),
    ("cloudflare", "challenge", "header_value", ("cf-mitigated", r"challenge"), "cf-mitigated: challenge", "S1"),
    ("cloudflare", "antibot", "cookie", r"^__cf_bm$", "__cf_bm cookie (Bot Management)", "S4"),
    ("cloudflare", "antibot", "cookie", r"^cf_clearance$", "cf_clearance cookie", "S2"),
    ("cloudflare", "challenge", "body", "<title>just a moment", "'Just a moment...' interstitial", "S2"),
    ("cloudflare", "challenge", "body", "_cf_chl_opt", "_cf_chl_opt challenge namespace", "S2"),
    ("cloudflare", "challenge", "body", "/cdn-cgi/challenge-platform/h/", "challenge-platform orchestrate", "S2"),
    # main.js "jsd" detections are injected into NORMAL pages on BM zones -> antibot, not challenge
    ("cloudflare", "antibot", "body", "/cdn-cgi/challenge-platform/scripts/jsd", "challenge-platform JSD script", "S2"),
    ("cloudflare", "block", "body", "attention required! | cloudflare", "Cloudflare 'Attention Required' block", "S4"),
    ("cloudflare", "block", "body", "cf-error-details", "Cloudflare error page", "S4"),
    ("cloudflare", "captcha", "body", "challenges.cloudflare.com/turnstile", "Turnstile widget", "S8"),
    ("cloudflare", "captcha", "body", "cf-turnstile", "Turnstile container", "S8"),
    # --- Akamai Bot Manager [S3][S4]
    ("akamai", "antibot", "cookie", r"^(_abck|bm_sz|ak_bmsc|bm_sv|bm_mi|bm_sc|bm_s|sbsd)$", "Akamai BM cookie", "S3"),
    ("akamai", "challenge", "cookie", r"^sec_cpt$", "sec_cpt (Akamai crypto challenge)", "S3"),
    ("akamai", "challenge", "body", "/_sec/cp_challenge", "Akamai sec-cpt challenge page", "S3"),
    ("akamai", "cdn", "header", "akamai-grn", "akamai-grn header", "S4"),
    ("akamai", "cdn", "header", "x-akamai-transformed", "x-akamai-transformed", "S4"),
    ("akamai", "cdn", "header", "akamai-cache-status", "akamai-cache-status", "S4"),
    ("akamai", "cdn", "header_value", ("server", r"akamai"), "server: AkamaiGHost/NetStorage", "S4"),
    ("akamai", "block", "body", "errors.edgesuite.net", "Akamai 'Access Denied' reference", "S4"),
    # --- DataDome [S3][S4]
    ("datadome", "antibot", "cookie", r"^datadome$", "datadome cookie", "S3"),
    ("datadome", "antibot", "header", "x-datadome", "x-datadome header", "S4"),
    ("datadome", "antibot", "header", "x-datadome-cid", "x-datadome-cid header", "S4"),
    ("datadome", "antibot", "header", "x-dd-b", "x-dd-b header", "S4"),
    ("datadome", "captcha", "body", "captcha-delivery.com", "captcha-delivery.com challenge", "S4"),
    ("datadome", "antibot", "body", "js.datadome.co", "DataDome JS tag", "S3"),
    # --- PerimeterX / HUMAN [S3]
    ("perimeterx", "antibot", "cookie", r"^(_px|_px2|_px3|_pxhd|_pxvid|pxcts|_pxde|_pxff_.*)$", "PerimeterX _px* cookie", "S3"),
    ("perimeterx", "captcha", "body", "px-captcha", "px-captcha (Press & Hold)", "S3"),
    ("perimeterx", "antibot", "body", "_pxappid", "_pxAppId sensor", "S3"),
    ("perimeterx", "antibot", "body", "client.perimeterx.net", "PerimeterX client script", "S3"),
    ("perimeterx", "antibot", "body", "px-cloud.net", "px-cloud.net sensor", "S3"),
    # --- Imperva / Incapsula [S3][S4]
    ("imperva", "antibot", "cookie", r"^(incap_ses_.*|visid_incap_.*|nlbi_.*|reese84)$", "Incapsula cookie", "S3"),
    ("imperva", "antibot", "header", "x-iinfo", "x-iinfo header", "S4"),
    ("imperva", "cdn", "header_value", ("x-cdn", r"incapsula|imperva"), "x-cdn: Imperva", "S4"),
    ("imperva", "challenge", "body", "_incapsula_resource", "_Incapsula_Resource challenge", "S4"),
    ("imperva", "block", "body", "incapsula incident id", "Incapsula incident block page", "S4"),
    # --- Kasada [S3]
    ("kasada", "antibot", "header", "x-kpsdk-ct", "x-kpsdk-ct header", "S3"),
    ("kasada", "antibot", "header", "x-kpsdk-cd", "x-kpsdk-cd header", "S3"),
    ("kasada", "antibot", "header", "x-kpsdk-c", "x-kpsdk-c header", "S3"),
    ("kasada", "antibot", "header", "x-kpsdk-r", "x-kpsdk-r header", "S3"),
    ("kasada", "antibot", "cookie", r"^KP_UIDz.*$", "KP_UIDz cookie", "S3"),
    ("kasada", "antibot", "body", "kpsdk", "KPSDK script reference", "S3"),
    # --- AWS WAF [S5]
    ("aws_waf", "antibot", "cookie", r"^aws-waf-token$", "aws-waf-token cookie", "S5"),
    ("aws_waf", "challenge", "header", "x-amzn-waf-action", "x-amzn-waf-action header", "S5"),
    ("aws_waf", "challenge", "body", "awswaf.com", "awswaf.com challenge script", "S5"),
    ("aws_waf", "challenge", "body", "awswafintegration", "AwsWafIntegration", "S5"),
    # --- F5 / Shape [S6][S7]
    ("f5_shape", "antibot", "cookie", r"^TS[0-9a-fA-F]{6,}$", "TS01* cookie (BIG-IP ASM)", "S6"),
    ("f5_shape", "antibot", "cookie", r"^TSPD_101.*$", "TSPD_101 cookie (Bot Defense)", "S6"),
    ("f5_shape", "cdn", "cookie", r"^BIGipServer.*$", "BIGipServer LB cookie", "S6"),
    ("f5_shape", "antibot", "header", "x-sh-pointer", "x-sh-pointer (Shape)", "S7"),
    ("f5_shape", "challenge", "body", "/tspd/", "TSPD JS challenge", "S6"),
    ("f5_shape", "block", "body", "the requested url was rejected", "F5 ASM rejection page", "S6"),
    # --- Fastly (CDN only) [S7]
    ("fastly", "cdn", "header", "x-fastly-request-id", "x-fastly-request-id", "S7"),
    ("fastly", "cdn", "header_value", ("x-served-by", r"cache-"), "x-served-by: cache-*", "S7"),
    ("fastly", "cdn", "header", "fastly-debug-digest", "fastly-debug-digest", "S7"),
    # --- Generic captcha widgets [S8]
    ("recaptcha", "captcha", "body", "google.com/recaptcha", "reCAPTCHA script", "S8"),
    ("recaptcha", "captcha", "body", "g-recaptcha", "g-recaptcha widget", "S8"),
    ("hcaptcha", "captcha", "body", "hcaptcha.com/1/api.js", "hCaptcha script", "S8"),
    ("hcaptcha", "captcha", "body", "h-captcha", "h-captcha widget", "S8"),
    ("arkose", "captcha", "body", "arkoselabs.com", "Arkose/FunCaptcha", "S8"),
    ("geetest", "captcha", "body", "geetest", "GeeTest", "S8"),
]

BLOCK_STATUSES = {401, 403, 405, 406, 418, 429, 451, 503}  # 503 counted only with vendor evidence
BLOCK_OUTCOMES = {"challenge", "captcha", "blocked_status", "block_page", "empty"}
HARD_BLOCK_OUTCOMES = BLOCK_OUTCOMES - {"empty"}


def cookie_names(set_cookie_values: list[str]) -> list[str]:
    names = []
    for v in set_cookie_values:
        first = v.split(";", 1)[0]
        if "=" in first:
            names.append(first.split("=", 1)[0].strip())
        else:
            try:
                sc = SimpleCookie()
                sc.load(v)
                names.extend(sc.keys())
            except Exception:
                pass
    return names


@dataclass
class Fingerprint:
    signals: list[dict]

    def vendors(self, kinds: set[str] | None = None) -> list[str]:
        out = []
        for s in self.signals:
            if (kinds is None or s["kind"] in kinds) and s["vendor"] not in out:
                out.append(s["vendor"])
        return out

    def has(self, kind: str) -> bool:
        return any(s["kind"] == kind for s in self.signals)

    def to_json(self) -> dict:
        return {
            "antibot": self.vendors({"antibot", "challenge", "block"}),
            "cdn": self.vendors({"cdn"}),
            "captcha": self.vendors({"captcha"}),
            "challenge": self.has("challenge"),
            "block_page": self.has("block"),
            "signals": [f"{s['vendor']}:{s['kind']}:{s['label']}" for s in self.signals],
        }


def fingerprint(status: int | None, headers: list[tuple[str, str]], body: bytes) -> Fingerprint:
    hmap: dict[str, list[str]] = {}
    for k, v in headers:
        hmap.setdefault(k.lower(), []).append(v)
    cookies = cookie_names(hmap.get("set-cookie", []))
    # html.unescape: Akamai's deny page entity-encodes text ("errors&#46;edgesuite&#46;net")
    text = html.unescape(body[:BODY_SCAN_LIMIT].decode("utf-8", "replace")).lower() if body else ""
    signals: list[dict] = []
    seen = set()
    for vendor, kind, loc, matcher, label, src in RULES:
        hit = False
        if loc == "header":
            hit = matcher in hmap
        elif loc == "header_value":
            name, rx = matcher
            hit = any(re.search(rx, v, re.I) for v in hmap.get(name, []))
        elif loc == "cookie":
            hit = any(re.match(matcher, c) for c in cookies)
        elif loc == "body":
            hit = bool(text) and matcher in text
        if hit and (vendor, kind, label) not in seen:
            seen.add((vendor, kind, label))
            signals.append({"vendor": vendor, "kind": kind, "label": label, "source": src})
    # Kasada: an empty-bodied 429 alongside x-kpsdk-* is its challenge [S3]
    if status == 429 and any(k.startswith("x-kpsdk") for k in hmap) and not text.strip():
        signals.append({"vendor": "kasada", "kind": "challenge", "label": "empty 429 + x-kpsdk-*", "source": "S3"})
    # AWS WAF challenge usually comes as 202 [S5]
    if status == 202 and "x-amzn-waf-action" in hmap:
        signals.append({"vendor": "aws_waf", "kind": "challenge", "label": "202 + x-amzn-waf-action", "source": "S5"})
    # Akamai generic "Access Denied" HTML only counts when Akamai is otherwise present
    if "access denied" in text and "reference #" in text and any(s["vendor"] == "akamai" for s in signals):
        signals.append({"vendor": "akamai", "kind": "block", "label": "Akamai Access Denied page", "source": "S4"})
    return Fingerprint(signals)


def classify(
    *,
    error_kind: str | None,
    status: int | None,
    fp: Fingerprint,
    rows: int,
    success: bool,
) -> str:
    """Outcome for one response.

    ok              success predicate passed (markers ignored)
    error           network / proxy / tls / timeout / byte-limit (not a block)
    challenge       interstitial JS challenge (Cloudflare, Kasada, AWS WAF, Akamai sec-cpt...)
    captcha         captcha wall
    block_page      vendor hard-deny page
    blocked_status  401/403/429/451/... (or 503 with anti-bot evidence) without a clearer marker
    not_found       404/410: bad sample id, not counted as a block
    server_error    other 5xx
    empty           2xx but the success predicate failed (soft block / layout drift / login wall)
    other           anything else (e.g. unfollowed 3xx)
    """
    if error_kind:
        return "error"
    if success:
        return "ok"
    if fp.has("challenge"):
        return "challenge"
    if fp.has("block"):
        return "block_page"
    failed_status = status is not None and not (200 <= status < 300)
    if fp.has("captcha") and (failed_status or rows == 0):
        return "captcha"
    if status in (404, 410):
        return "not_found"
    if status in BLOCK_STATUSES:
        if status == 503 and not fp.vendors({"antibot", "challenge", "block"}):
            return "server_error"
        return "blocked_status"
    if status is not None and status >= 500:
        return "server_error"
    if status is not None and 200 <= status < 300:
        return "empty"
    return "other"
