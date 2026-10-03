"""Row extraction: count the rows a response yields (and keep a tiny sample for sanity).

Extract spec (in a probe definition, key `extract`):
  {type: json,          path: "data.items"}            # dotted path, ints index lists, "*" maps
  {type: json_in_html,  selector: "script#__NEXT_DATA__", path: "props.pageProps.items"}
  {type: css,           selector: "article.product_pod", fields: {title: "h3 a"}}
  {type: regex,         pattern: "\"sku\":\"[^\"]+\""}
Path semantics: the value at the path; a list -> len(list) rows, a dict/scalar -> 1 row,
missing/null -> 0 rows. "$" or "" means the document root.
"""
from __future__ import annotations

import json
import re
from typing import Any

try:
    from selectolax.parser import HTMLParser  # type: ignore
except ImportError:  # pragma: no cover
    HTMLParser = None

SAMPLE_ROWS = 2
SAMPLE_CHARS = 80


class ExtractError(Exception):
    pass


def _walk(doc: Any, path: str) -> Any:
    if path in ("", "$", None):
        return doc
    p = path[2:] if path.startswith("$.") else path
    cur: list[Any] = [doc]
    fanned = False
    for seg in re.split(r"\.(?![^\[]*\])", p):
        # allow a[0] / a[*] sugar
        m = re.fullmatch(r"([^\[]*)((?:\[[^\]]+\])*)", seg)
        keys = [m.group(1)] if m and m.group(1) else []
        if m:
            keys += re.findall(r"\[([^\]]+)\]", m.group(2))
        for key in keys:
            nxt: list[Any] = []
            for node in cur:
                if key == "*":
                    if isinstance(node, list):
                        nxt.extend(node)
                    elif isinstance(node, dict):
                        nxt.extend(node.values())
                    fanned = True
                elif isinstance(node, list) and re.fullmatch(r"-?\d+", key):
                    i = int(key)
                    if -len(node) <= i < len(node):
                        nxt.append(node[i])
                elif isinstance(node, dict) and key in node:
                    nxt.append(node[key])
            cur = nxt
    if fanned:
        return cur
    return cur[0] if cur else None


def _count(value: Any) -> int:
    if value is None:
        return 0
    if isinstance(value, list):
        return len(value)
    return 1


def _short(v: Any) -> str:
    s = v if isinstance(v, str) else json.dumps(v, ensure_ascii=False, default=str)
    return s[:SAMPLE_CHARS]


def extract(body: bytes, spec: dict, content_type: str = "") -> tuple[int, list, str | None]:
    """Returns (rows, sample, error). Never raises."""
    kind = (spec or {}).get("type", "json")
    try:
        if kind == "json":
            doc = json.loads(body.decode("utf-8", "replace"))
            val = _walk(doc, spec.get("path", "$"))
            sample = [_short(x) for x in (val[:SAMPLE_ROWS] if isinstance(val, list) else [val])] if val is not None else []
            return _count(val), sample, None
        if kind == "json_in_html":
            if HTMLParser is None:
                raise ExtractError("selectolax not installed")
            node = HTMLParser(body.decode("utf-8", "replace")).css_first(spec["selector"])
            if node is None:
                return 0, [], None
            doc = json.loads(node.text(deep=True))
            val = _walk(doc, spec.get("path", "$"))
            sample = [_short(x) for x in (val[:SAMPLE_ROWS] if isinstance(val, list) else [val])] if val is not None else []
            return _count(val), sample, None
        if kind == "css":
            if HTMLParser is None:
                raise ExtractError("selectolax not installed")
            nodes = HTMLParser(body.decode("utf-8", "replace")).css(spec["selector"])
            fields = spec.get("fields") or {}
            sample = []
            for n in nodes[:SAMPLE_ROWS]:
                if fields:
                    row = {}
                    for fname, sel in fields.items():
                        sub = n.css_first(sel)
                        row[fname] = _short(sub.text(strip=True)) if sub is not None else None
                    sample.append(row)
                else:
                    sample.append(_short(n.text(strip=True)))
            return len(nodes), sample, None
        if kind == "regex":
            found = re.findall(spec["pattern"], body.decode("utf-8", "replace"))
            return len(found), [_short(x) for x in found[:SAMPLE_ROWS]], None
        raise ExtractError(f"unknown extract type {kind!r}")
    except ExtractError as e:
        return 0, [], str(e)
    except (ValueError, KeyError, TypeError) as e:
        return 0, [], f"{type(e).__name__}: {str(e)[:120]}"


def check_success(status: int | None, body: bytes, rows: int, spec: dict) -> bool:
    spec = spec or {}
    statuses = spec.get("status", [200])
    if status not in statuses:
        return False
    if rows < int(spec.get("min_rows", 1)):
        return False
    text = body.decode("utf-8", "replace") if (spec.get("body_contains") or spec.get("body_not_contains")) else ""
    for s in spec.get("body_contains", []) or []:
        if s not in text:
            return False
    for s in spec.get("body_not_contains", []) or []:
        if s in text:
            return False
    return True
