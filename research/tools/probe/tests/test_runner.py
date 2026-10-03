"""End-to-end runs through the stub proxy: summaries, verdicts, ledger, cap enforcement, outputs."""
import json
import re
import subprocess
import sys
from pathlib import Path

import pytest
import yaml

from probe.definition import parse_definition
from probe.ledger import BudgetRefused, HARD_CAP_BYTES, Ledger
from probe.runner import health_check, run_probe

from .conftest import TEST_PASS, TEST_USER, TOOLS


def defn(origin, path, **kw):
    d = {"name": kw.pop("name", "t-" + re.sub(r"[^a-z0-9]+", "-", path.lower()).strip("-")[:40]),
         "public_only": True, "urls": [origin.url(path)],
         "extract": {"type": "json", "path": "data.items"}, "expected_bytes_per_request": 10_000}
    d.update(kw)
    return parse_definition(d)


def run(d, cfg, creds, cert, **kw):
    kw.setdefault("log", lambda *_: None)
    return run_probe(d, cfg, creds, ca_file=cert[0], sleep=lambda *_: None, **kw)


def no_secrets(*paths):
    for p in paths:
        txt = Path(p).read_text()
        assert TEST_PASS not in txt and TEST_USER not in txt, p


def test_pass_end_to_end(origin, proxy, creds, cfg, cert):
    d = defn(origin, "/api/items?page=1", name="ok-json", rows_per_page_expected=10)
    s = run(d, cfg, creds, cert, n=5, session="sticky", baseline=True)  # n clamps to 20
    assert s["requests_sent"] == 20 and s["ok"] == 20 and s["verdict"] == "PASS", s["verdict_reasons"]
    assert s["block_rate"] == 0 and s["rows_total"] == 200 and s["rows_per_request"] == 10
    assert s["cost_per_1k_rows_usd"]["payg"] < 0.5 and s["bytes_per_row"] > 0
    assert s["cdn_vendors"] == {"cloudflare": 20} and s["antibot_vendors"] == {}
    assert s["baseline"]["requests"] == 3 and s["baseline"]["outcomes"] == {"ok": 3}
    probes = Path(cfg["paths"]["probes_dir"])
    lines = [json.loads(x) for x in (probes / "ok-json" / "results.jsonl").read_text().splitlines()]
    assert len(lines) == 23 and {x["mode"] for x in lines} == {"proxy", "direct"}
    prox = [x for x in lines if x["mode"] == "proxy"]
    # ledger == sum of per-request bytes == what the proxy actually carried
    led = Ledger(cfg["paths"]["ledger"]).snapshot()
    assert led["proxy_bytes_total"] == sum(x["bytes_wire_total"] for x in prox) == proxy.total()
    assert led["direct_bytes_total"] == sum(x["bytes_wire_total"] for x in lines if x["mode"] == "direct")
    assert led["runs"][-1]["status"] == "completed" and led["by_probe"]["ok-json"]["proxy_requests"] == 20
    # sticky: one session username for the whole run, Decodo format
    names = {c["username"] for c in proxy.conns}
    assert len(names) == 1 and re.fullmatch(rf"user-{TEST_USER}-session-[0-9a-f]+-sessionduration-30", names.pop())
    md = Path(cfg["paths"]["probes_md"]).read_text()
    assert "| ok-json |" in md and "**PASS**" in md
    no_secrets(probes / "ok-json" / "results.jsonl", probes / "ok-json" / "summary.json",
               cfg["paths"]["probes_md"], cfg["paths"]["ledger"], cfg["paths"]["log"])


@pytest.mark.parametrize("path,vendor,outcome", [
    ("/cf-challenge", "cloudflare", "challenge"),
    ("/datadome", "datadome", "captcha"),
    ("/akamai", "akamai", "block_page"),
    ("/px", "perimeterx", "captcha"),
    ("/incap", "imperva", "challenge"),
    ("/kasada", "kasada", "challenge"),
    ("/awswaf", "aws_waf", "challenge"),
    ("/api/empty", None, "empty"),
])
def test_blocked_targets_are_killed(origin, proxy, creds, cfg, cert, path, vendor, outcome):
    s = run(defn(origin, path), cfg, creds, cert, n=20)
    assert s["verdict"] == "KILL" and s["outcomes"] == {outcome: 20} and s["block_rate"] == 1.0
    if vendor:
        assert s["antibot_vendors"].get(vendor) == 20
    assert any("block rate" in r for r in s["verdict_reasons"])


def test_cost_kill(origin, proxy, creds, cfg, cert):
    s = run(defn(origin, "/api/fat", expected_bytes_per_request=450_000), cfg, creds, cert)
    assert s["block_rate"] == 0 and s["verdict"] == "KILL"
    assert s["cost_per_1k_rows_usd"]["payg"] > 0.5
    assert any("cost/1k rows" in r for r in s["verdict_reasons"])


def test_redirect_followed_and_bytes_summed(origin, proxy, creds, cfg, cert):
    s = run(defn(origin, "/redirect?page=3"), cfg, creds, cert)
    assert s["ok"] == 30  # default n
    lines = [json.loads(x) for x in (Path(cfg["paths"]["probes_dir"]) / s["name"] / "results.jsonl").read_text().splitlines()]
    assert all(x["redirects"] == 1 and x["final_url"].endswith("/api/items?page=3") for x in lines)
    assert len(proxy.conns) == 60  # each hop is its own billed connection
    assert Ledger(cfg["paths"]["ledger"]).used() == proxy.total()


def test_projection_refused_before_any_traffic(origin, proxy, creds, cfg, cert):
    cfg["budget"]["cap_bytes"] = 100_000
    with pytest.raises(BudgetRefused):
        run(defn(origin, "/api/items", expected_bytes_per_request=50_000), cfg, creds, cert)
    assert proxy.conns == [] and Ledger(cfg["paths"]["ledger"]).snapshot()["runs"] == []


def test_per_probe_max_refused(origin, proxy, creds, cfg, cert):
    cfg["budget"]["per_probe_max_bytes"] = 10_000
    with pytest.raises(BudgetRefused):
        run(defn(origin, "/api/items"), cfg, creds, cert)
    assert proxy.conns == []


def test_stops_mid_run_at_cap(origin, proxy, creds, cfg, cert):
    cap = 300_000
    cfg["budget"].update(cap_bytes=cap, min_reserve_bytes=1_000, abort_margin_bytes=100_000)
    # Underestimate on purpose so the projection passes but real traffic hits the cap.
    d = defn(origin, "/big?kb=80", expected_bytes_per_request=1_000)
    s = run(d, cfg, creds, cert)
    led = Ledger(cfg["paths"]["ledger"], cap).snapshot()
    assert s["stopped_reason"] == "cap" and s["requests_sent"] < 20
    # Hard guarantee: neither our ledger nor the bytes the gateway actually carried pass the cap.
    assert led["proxy_bytes_total"] <= proxy.total() <= cap
    assert led["proxy_bytes_total"] == sum(
        json.loads(x)["bytes_wire_total"] for x in (Path(cfg["paths"]["probes_dir"]) / d.name / "results.jsonl").read_text().splitlines())
    assert led["runs"][-1]["status"] == "cap"
    assert s["verdict"] in ("INCOMPLETE", "KILL")
    # A second run is refused outright: remaining budget can't cover any projection.
    with pytest.raises(BudgetRefused):
        run(defn(origin, "/api/items", name="second"), cfg, creds, cert)


def test_cap_cannot_be_raised_above_hard_cap(tmp_path):
    assert Ledger(tmp_path / "l.json", 10 * HARD_CAP_BYTES).cap == HARD_CAP_BYTES


def test_dry_run_needs_no_creds_or_network(origin, proxy, cfg, cert):
    s = run(defn(origin, "/api/items"), cfg, None, cert, dry_run=True, n=99)
    assert s["dry_run"] and s["n"] == 50 and s["fits"] and proxy.conns == []


def test_health_check(origin, proxy, creds, cfg, cert):
    out = []
    res = health_check(cfg, creds, count=2, sticky=True, ca_file=cert[0],
                       urls=[origin.url("/json-ip")], log=out.append)
    assert [r["exit_ip"] for r in res] == ["203.0.113.7"] * 2 and res[0]["country"] == "US"
    assert all(TEST_PASS not in line and TEST_USER not in line for line in out)
    assert Ledger(cfg["paths"]["ledger"]).snapshot()["by_probe"]["_health"]["proxy_bytes"] == proxy.total()


def test_health_check_bad_password(origin, proxy, creds, cfg, cert):
    creds.password = "definitely-wrong-pw"
    out = []
    res = health_check(cfg, creds, ca_file=cert[0], urls=[origin.url("/json-ip")], log=out.append)
    assert res[0]["exit_ip"] is None and "407" in res[0]["error"]
    assert all("definitely-wrong-pw" not in line for line in out)


def test_cli_validate_plan_and_run(origin, proxy, cfg, cert, tmp_path):
    cfg_file = tmp_path / "cfg.yaml"
    cfg_file.write_text(yaml.safe_dump(cfg))
    dfile = tmp_path / "cli-probe.yaml"
    dfile.write_text(yaml.safe_dump({"name": "cli-probe", "public_only": True, "urls": [origin.url("/api/items")],
                                     "extract": {"type": "json", "path": "data.items"},
                                     "expected_bytes_per_request": 10000}))
    defs = sorted(str(p) for p in (TOOLS / "probe" / "definitions").glob("*.yaml"))
    base = [sys.executable, "-m", "probe", "--config", str(cfg_file)]
    r = subprocess.run(base + ["validate", *defs], cwd=TOOLS, capture_output=True, text=True)
    assert r.returncode == 0, r.stderr
    r = subprocess.run(base + ["plan", *defs], cwd=TOOLS, capture_output=True, text=True)
    assert r.returncode == 0 and "TOTAL projected" in r.stdout, r.stderr
    env = {"DECODO_USER": TEST_USER, "DECODO_PASS": TEST_PASS, "DECODO_HOST": f"127.0.0.1:{proxy.port}",
           "PATH": "/usr/bin:/bin"}
    r = subprocess.run(base + ["--ca-file", cert[0], "run", str(dfile)], cwd=TOOLS, capture_output=True, text=True, env=env)
    assert r.returncode == 0, r.stderr
    assert "cli-probe: PASS" in r.stdout
    assert TEST_PASS not in r.stdout + r.stderr and TEST_USER not in r.stdout + r.stderr
    r = subprocess.run(base + ["ledger"], cwd=TOOLS, capture_output=True, text=True)
    assert json.loads(r.stdout)["proxy_bytes_total"] == proxy.total()
    r = subprocess.run(base + ["run", str(dfile)], cwd=TOOLS, capture_output=True, text=True, env={"PATH": "/usr/bin:/bin"})
    assert r.returncode == 2 and "credentials missing" in r.stderr
