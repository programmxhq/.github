"""Offline end-to-end tests. Run: python -m pytest tests/  or  python tests/test_census.py"""
from __future__ import annotations

import contextlib
import csv
import io
import json
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
sys.path.insert(0, str(HERE))

import census  # noqa: E402
from mock_apify import MockServer, MockState  # noqa: E402

TOKEN = "apify_api_TESTSECRETdoNotLeak0123456789"


def run(server: MockServer, tmp: Path, *extra: str, token: str | None = TOKEN) -> tuple[int, str, dict | None]:
    env_file = tmp / "test.env"
    env_file.write_text(f"APIFY_TOKEN={token}\nDECODO_PASS='hunter2secret'\n" if token else "")
    argv = ["--base-url", server.url, "--raw-dir", str(tmp / "raw"), "--out", str(tmp / "census.csv"),
            "--env-file", str(env_file), "--rps", "0", "--backoff-base", "0.01", "--page-size", "2", *extra]
    err = io.StringIO()
    old = dict(census.os.environ)
    for k in census.CRED_KEYS:
        census.os.environ.pop(k, None)
    try:
        with contextlib.redirect_stderr(err), contextlib.redirect_stdout(err):
            try:
                code = census.main(argv)
            except SystemExit as e:
                code = e.code if isinstance(e.code, int) else 99
                print(e)
    finally:
        census.os.environ.clear()
        census.os.environ.update(old)
    summary_path = tmp / "census_summary.json"
    summary = json.loads(summary_path.read_text()) if summary_path.exists() else None
    return code, err.getvalue(), summary


def read_csv(tmp: Path) -> dict[str, dict]:
    with (tmp / "census.csv").open(newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    return {r["actor_id"]: r for r in rows}


def all_text(tmp: Path) -> str:
    return "\n".join(p.read_text(errors="ignore") for p in tmp.rglob("*") if p.is_file() and p.name != "test.env")


def test_full_pipeline_with_enrichment():
    with tempfile.TemporaryDirectory() as d, MockServer(MockState(fail_first_n_with_429=2,
                                                                  expected_token=TOKEN)) as srv:
        tmp = Path(d)
        code, out, summary = run(srv, tmp, "--enrich")
        assert code == 0, out
        rows = read_csv(tmp)
        assert len(rows) == 5
        with (tmp / "census.csv").open() as f:
            assert next(csv.reader(f)) == census.CSV_COLUMNS

        jane = rows["zdc3Pyhyz3m8vjDeM"]
        assert jane["owner"] == "jane35" and jane["is_apify_owned"] == "false"
        assert jane["categories"] == "MARKETING;LEAD_GENERATION"
        assert jane["total_users"] == "6" and jane["users_30d"] == "6" and jane["users_7d"] == "2"
        assert jane["runs_per_user"] == str(round(16 / 6, 3))
        assert jane["rating"] == "4.7" and jane["review_count"] == "69" and jane["bookmark_count"] == "1269"
        assert jane["success_rate_30d"] == str(round(732805 / 749137, 4))
        assert jane["runs_30d"] == "749137" and jane["runs_30d_timed_out"] == "12556"
        assert jane["pricing_model"] == "PAY_PER_EVENT" and jane["pricing_source"] == "detail.pricingInfos"
        ev = json.loads(jane["pricing_events"])
        assert ev["actor-start"] == {"FLAT": 0.005}
        assert ev["result"]["DIAMOND"] == 0.0015 and ev["result"]["FREE"] == 0.004 and len(ev["result"]) == 6
        assert jane["primary_event"] == "result" and jane["primary_event_price_usd"] == "0.004"
        assert jane["pending_price_change"] == "true"          # 2099 entry is future-dated
        assert jane["pricing_history_count"] == "3"
        assert jane["created_at"] == "2019-07-08T11:27:57.401Z" and jane["last_modified"] == "2019-07-08T14:01:05.546Z"
        assert jane["deprecated"] == "false" and jane["enriched"] == "true"
        assert jane["issues_response_time"] == ""

        web = rows["aPifyWebScraper01"]
        assert web["is_apify_owned"] == "true" and web["is_critical"] == "true"
        assert web["pricing_model"] == "FREE" and web["price_flat_or_per_result"] == "0"
        assert web["success_rate_30d"] == "" and web["runs_30d"] == ""

        maps = rows["compassMaps000001"]
        assert maps["url_source"] == "derived" and maps["url"] == "https://apify.com/compass/google-maps-extractor"
        assert maps["success_rate_30d"] == "0.9"
        assert maps["price_unit"] == "place" and maps["price_flat_or_per_result"] == "0.004"
        assert json.loads(maps["price_per_result_tiers"])["GOLD"] == 0.0025

        flat = rows["flatMonthly000001"]
        assert flat["deprecated"] == "true" and flat["price_flat_or_per_result"] == "25"
        assert flat["price_unit"] == "month" and flat["trial_minutes"] == "4320"
        assert flat["runs_per_user"] == ""                      # totalUsers = 0

        gone = rows["goneActor00000001"]
        assert gone["enriched"] == "false" and gone["pricing_model"] == "FREE"

        # 3 store pages (2+2+1); 5 tilde lookups + 1 id fallback; the 2 injected 429s land on the
        # first (spend-check) request and are retried. Every attempt is counted.
        assert summary["requests_by_kind"]["store_list"] == 3
        assert summary["requests_by_kind"]["spend_check"] == 2 + 2
        assert summary["requests_total"] == sum(summary["requests_by_kind"].values()) == len(srv.state.log)
        assert summary["requests_by_kind"]["actor_detail"] == 6
        assert summary["responses_by_status"]["429"] == 2
        assert summary["store"]["complete"] is True and summary["store"]["items_unique"] == 5
        assert summary["enrichment"]["not_found"] == 1 and summary["csv"]["enriched"] == 4
        assert summary["spend_guard"]["available"] is True and summary["spend_guard"]["delta_usd"] == 0
        assert summary["csv"]["house_owner_check"]["apify"]["is_critical_true"] == 1
        assert (tmp / "raw/store/page_0001.json").exists() and (tmp / "raw/store/page_0003.json").exists()

        # token only ever in the Authorization header, never in a URL, output, or file
        assert all(TOKEN not in e["raw_path"] for e in srv.state.log)
        assert TOKEN not in out and "hunter2secret" not in out
        assert TOKEN not in all_text(tmp)


def test_resume_after_max_pages():
    with tempfile.TemporaryDirectory() as d, MockServer(MockState()) as srv:
        tmp = Path(d)
        code, out, s1 = run(srv, tmp, "--max-pages", "1")
        assert code == 0, out
        assert s1["store"]["pages"] == 1 and s1["store"]["complete"] is False
        assert len(read_csv(tmp)) == 2                         # partial CSV is still written

        code, out, _ = run(srv, tmp)                            # no --resume -> refuse
        assert code == 99 and "--resume" in out

        n_before = len(srv.state.log)
        code, out, s2 = run(srv, tmp, "--resume")
        assert code == 0, out
        offsets = [e["query"]["offset"] for e in srv.state.log[n_before:] if e["path"] == "/v2/store"]
        assert offsets == ["2", "4"]                            # did not refetch page 1
        assert s2["store"]["complete"] is True and len(read_csv(tmp)) == 5


def test_request_cap_hard_stop():
    with tempfile.TemporaryDirectory() as d, MockServer(MockState()) as srv:
        tmp = Path(d)
        code, out, s = run(srv, tmp, "--max-requests", "2", "--no-auth")
        assert code == 3, out
        assert "request cap 2 reached" in s["hard_stop"]
        assert len(srv.state.log) == 2 and s["requests_total"] == 2
        assert all(e["auth"] is None for e in srv.state.log)   # --no-auth sends no token


def test_spend_guard_stops():
    with tempfile.TemporaryDirectory() as d, MockServer(MockState(usage_step_usd=1.0)) as srv:
        tmp = Path(d)
        code, out, s = run(srv, tmp, "--enrich", "--spend-check-every", "1", "--spend-cap-usd", "0.5")
        assert code == 3, out
        assert "account usage grew" in s["hard_stop"]


def test_spend_guard_unavailable_at_start_refuses_authenticated_run():
    with tempfile.TemporaryDirectory() as d, MockServer(MockState(limits_ok_calls=0)) as srv:
        tmp = Path(d)
        code, out, s = run(srv, tmp)
        assert code == 3, out
        assert "spend guard unavailable" in s["hard_stop"]
        assert not any(e["path"].startswith("/v2/store") for e in srv.state.log)


def test_spend_guard_fails_closed_when_usage_reads_stop():
    with tempfile.TemporaryDirectory() as d, MockServer(MockState(limits_ok_calls=1)) as srv:
        tmp = Path(d)
        code, out, s = run(srv, tmp, "--enrich", "--spend-check-every", "1")
        assert code == 3, out
        assert "fail closed" in s["hard_stop"]


def test_token_not_sent_to_untrusted_base_url():
    with tempfile.TemporaryDirectory() as d, MockServer(MockState()) as srv:
        tmp = Path(d)
        url = srv.url.replace("127.0.0.1", "127.0.0.1.nip.io")
        code, out, _ = run(srv, tmp, "--base-url", url)
        assert code == 2, out
        assert "refusing to send APIFY_TOKEN" in out and TOKEN not in out
        assert srv.state.log == []


def test_result_window_cap_warning():
    with tempfile.TemporaryDirectory() as d, MockServer(MockState(window_cap=4)) as srv:
        tmp = Path(d)
        code, out, s = run(srv, tmp)
        assert code == 0, out
        assert s["store"]["items_unique"] == 4 and s["store"]["reported_total"] == 5
        assert any("result-window cap" in w for w in s["store"]["warnings"])


def test_slices_merge_and_build_only():
    with tempfile.TemporaryDirectory() as d, MockServer(MockState()) as srv:
        tmp = Path(d)
        assert run(srv, tmp, "--slice", "a", "--sort-by", "newest")[0] == 0
        assert run(srv, tmp, "--slice", "b", "--category", "LEAD_GENERATION")[0] == 0
        n = len(srv.state.log)
        code, out, s = run(srv, tmp, "--build-only")
        assert code == 0 and len(srv.state.log) == n            # no network
        assert s["store"]["items_raw"] == 10 and s["store"]["items_unique"] == 5


def test_redactor_and_env_parsing():
    r = census.Redactor([TOKEN])
    msg = f"GET https://api.apify.com/v2/store?token={TOKEN}&x=1 Authorization: Bearer {TOKEN}"
    out = r(msg)
    assert TOKEN not in out and "token=***" in out
    assert "apify_api_" not in census.Redactor()("leaked apify_api_abcDEF123 here").replace("apify_api_***", "")
    with tempfile.TemporaryDirectory() as d:
        p = Path(d) / ".env"
        p.write_text("# c\nexport APIFY_TOKEN=\"abc12345\"\nDECODO_USER='u1'\nBAD LINE\n")
        assert census.parse_env_file(p) == {"APIFY_TOKEN": "abc12345", "DECODO_USER": "u1"}


def test_pricing_parsers_on_spec_shapes():
    assert census.parse_charge_events(None) == {}
    bare = {"ev": {"eventTitle": "t", "eventDescription": "d", "eventPriceUsd": 1.0}}
    assert census.parse_charge_events(bare) == bare             # defensive: untyped store shape
    cols = census.pricing_columns({"pricingModel": "PRICE_PER_DATASET_ITEM", "unitName": "result",
                                   "pricePerUnitUsd": 0.002})
    assert cols["price_flat_or_per_result"] == 0.002 and cols["price_unit"] == "result"


# ---- Added by review-agent:census (2026-10-03) for bugs found in review ----

def test_stalled_paging_stops_before_request_cap():
    # Server ignores offset and has no usable end: must stop on the 2nd identical page,
    # not loop until --max-requests (each page is also written to disk).
    with tempfile.TemporaryDirectory() as d, MockServer(MockState(ignore_offset=True)) as srv:
        tmp = Path(d)
        code, out, s = run(srv, tmp, "--no-auth", "--max-requests", "50")
        assert code == 0, out
        assert s["requests_by_kind"]["store_list"] == 2
        assert any("already-seen" in w for w in s["store"]["warnings"])


def test_null_top_level_review_fields_fall_back_to_stats():
    now = census.dt.datetime.now(census.dt.timezone.utc)
    item = {"id": "x", "username": "u", "name": "n", "actorReviewRating": None, "actorReviewCount": None,
            "stats": {"actorReviewRating": 4.5, "actorReviewCount": 3, "bookmarkCount": 7}}
    row = census.build_row(item, None, set(), now)
    assert row["rating"] == 4.5 and row["review_count"] == 3 and row["bookmark_count"] == 7
    item["actorReviewRating"] = 0          # a real 0 must not be replaced
    assert census.build_row(item, None, set(), now)["rating"] == 0


def test_pick_current_pricing_tolerates_naive_timestamps():
    now = census.dt.datetime(2026, 10, 3, tzinfo=census.dt.timezone.utc)
    infos = [{"pricingModel": "FREE", "startedAt": "2023-01-01T00:00:00"},
             {"pricingModel": "PAY_PER_EVENT", "startedAt": "2099-01-01T00:00:00.000Z"}]
    pi, pending = census.pick_current_pricing(infos, now)
    assert pi["pricingModel"] == "FREE" and pending is True


def test_env_fallback_reads_research_env_when_root_env_lacks_token():
    saved = (census.REPO_ROOT, census.RESEARCH_DIR, dict(census.os.environ))
    with tempfile.TemporaryDirectory() as d:
        root, research = Path(d), Path(d) / "research"
        research.mkdir()
        (root / ".env").write_text("DECODO_USER=user1\n")
        (research / ".env").write_text("APIFY_TOKEN=tok_from_research\nDECODO_USER=other\n")
        try:
            census.REPO_ROOT, census.RESEARCH_DIR = root, research
            for k in census.CRED_KEYS:
                census.os.environ.pop(k, None)
            creds = census.load_credentials(None)
        finally:
            census.REPO_ROOT, census.RESEARCH_DIR = saved[0], saved[1]
            census.os.environ.clear()
            census.os.environ.update(saved[2])
        assert creds["APIFY_TOKEN"] == "tok_from_research" and creds["DECODO_USER"] == "user1"


# Property names copied from apify-docs@7b30f19 apify-api/openapi (spec-verified, not live-verified).
SPEC_STORE_LIST_ACTOR = {  # components/schemas/store/StoreListActor.yaml
    "id", "title", "name", "username", "userFullName", "description", "categories", "notice", "pictureUrl",
    "userPictureUrl", "url", "stats", "currentPricingInfo", "isWhiteListedForAgenticPayments",
    "actorReviewCount", "actorReviewRating", "bookmarkCount", "badge", "readmeSummary"}
SPEC_ACTOR_STATS = {  # components/schemas/actors/ActorStats.yaml
    "totalBuilds", "totalRuns", "totalUsers", "totalUsers7Days", "totalUsers30Days", "totalUsers90Days",
    "totalMetamorphs", "lastRunStartedAt", "actorReviewCount", "actorReviewRating", "bookmarkCount",
    "publicActorRunStats30Days"}
SPEC_RUN_STATS_30D = {"ABORTED", "FAILED", "SUCCEEDED", "TIMED-OUT", "TOTAL"}
SPEC_CURRENT_PRICING_INFO = {  # components/schemas/store/CurrentPricingInfo.yaml
    "pricingModel", "apifyMarginPercentage", "createdAt", "startedAt", "notifiedAboutChangeAt",
    "notifiedAboutFutureChangeAt", "isPriceChangeNotificationSuppressed", "forceContainsSignificantPriceChange",
    "isPPEPlatformUsagePaidByUser", "reasonForChange", "trialMinutes", "unitName", "pricePerUnitUsd",
    "minimalMaxTotalChargeUsd", "pricingPerEvent"}
SPEC_ACTOR = {  # components/schemas/actors/Actor.yaml
    "id", "userId", "name", "username", "description", "restartOnError", "isPublic", "actorPermissionLevel",
    "createdAt", "modifiedAt", "stats", "versions", "pricingInfos", "defaultRunOptions", "exampleRunInput",
    "isDeprecated", "deploymentKey", "title", "taggedBuilds", "actorStandby", "readmeSummary", "seoTitle",
    "seoDescription", "pictureUrl", "standbyUrl", "notice", "categories", "isCritical", "isGeneric",
    "isSourceCodeHidden", "hasNoDataset"}
SPEC_PRICING_INFO = {  # actor-pricing-info/CommonActorPricingInfo.yaml + the four variants
    "apifyMarginPercentage", "createdAt", "startedAt", "notifiedAboutFutureChangeAt", "notifiedAboutChangeAt",
    "reasonForChange", "isPriceChangeNotificationSuppressed", "forceContainsSignificantPriceChange",
    "pricingModel", "pricePerUnitUsd", "trialMinutes", "unitName", "tieredPricing", "pricingPerEvent",
    "minimalMaxTotalChargeUsd"}
SPEC_CHARGE_EVENT = {"eventTitle", "eventDescription", "eventPriceUsd", "eventTieredPricingUsd",
                     "isPrimaryEvent", "isOneTimeEvent"}  # actor-pricing-info/ActorChargeEvent.yaml


def test_fixtures_use_only_spec_fields():
    fx = HERE / "fixtures"
    items = json.loads((fx / "store_items.json").read_text())["items"]
    for it in items:
        assert {"id", "title", "name", "username", "stats"} <= set(it)      # required
        assert set(it) <= SPEC_STORE_LIST_ACTOR, set(it) - SPEC_STORE_LIST_ACTOR
        assert set(it["stats"]) <= SPEC_ACTOR_STATS
        assert set(it["stats"].get("publicActorRunStats30Days", {})) <= SPEC_RUN_STATS_30D
        assert set(it.get("currentPricingInfo", {})) <= SPEC_CURRENT_PRICING_INFO
    for p in (fx / "actors").glob("*.json"):
        d = json.loads(p.read_text())["data"]
        assert set(d) <= SPEC_ACTOR, set(d) - SPEC_ACTOR
        assert {"id", "userId", "name", "username", "isPublic", "createdAt", "modifiedAt", "stats",
                "versions", "defaultRunOptions"} <= set(d)
        for pi in d["pricingInfos"]:
            assert set(pi) <= SPEC_PRICING_INFO
            assert pi["pricingModel"] in {"FREE", "FLAT_PRICE_PER_MONTH", "PRICE_PER_DATASET_ITEM", "PAY_PER_EVENT"}
            for ev in (pi.get("pricingPerEvent") or {}).get("actorChargeEvents", {}).values():
                assert set(ev) <= SPEC_CHARGE_EVENT
                assert ("eventPriceUsd" in ev) != ("eventTieredPricingUsd" in ev)   # mutually exclusive


if __name__ == "__main__":
    failed = 0
    for name, fn in list(globals().items()):
        if name.startswith("test_") and callable(fn):
            try:
                fn()
                print(f"PASS {name}")
            except Exception as e:  # noqa: BLE001
                failed += 1
                print(f"FAIL {name}: {type(e).__name__}: {e}")
    sys.exit(1 if failed else 0)
