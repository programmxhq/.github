"""Persistent Decodo traffic ledger (research/probes/traffic_ledger.json).

Every proxied byte (probe requests, health checks, failed requests) is added after each
request, under an exclusive file lock, with an atomic replace. Direct (no-proxy) baseline
bytes are tracked separately and do not count toward the Decodo cap.
"""
from __future__ import annotations

import contextlib
import fcntl
import json
import os
import tempfile
import time
from pathlib import Path

HARD_CAP_BYTES = 500_000_000  # project-wide hard cap; config can only lower it
MIN_ABORT_MARGIN_BYTES = 1_000_000  # floor for budget.abort_margin_bytes (runner.abort_margin)
CANONICAL_LEDGER = "research/probes/traffic_ledger.json"  # repo-relative; the CLI refuses any other


class BudgetRefused(Exception):
    pass


class LedgerBusy(BudgetRefused):
    """Another proxied run or health check holds the run lock on this ledger."""


def _now() -> str:
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


class Ledger:
    def __init__(self, path: str | Path, cap_bytes: int = HARD_CAP_BYTES):
        self.path = Path(path)
        self.cap = min(int(cap_bytes), HARD_CAP_BYTES)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._lockpath = self.path.with_suffix(self.path.suffix + ".lock")
        self._runlockpath = self.path.with_suffix(self.path.suffix + ".run.lock")

    @contextlib.contextmanager
    def exclusive_run(self):
        """Held for a whole proxied run. Per-request headroom (cap - used - margin) is only safe
        if no other process spends from the same ledger at the same time, so a second concurrent
        run or health check is refused instead of sharing that headroom."""
        with open(self._runlockpath, "a+") as lf:
            try:
                fcntl.flock(lf, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise LedgerBusy(f"another probe run or health check is using {self.path.name}; "
                                 "run probes one at a time") from None
            try:
                yield
            finally:
                fcntl.flock(lf, fcntl.LOCK_UN)

    @contextlib.contextmanager
    def _locked(self):
        with open(self._lockpath, "a+") as lf:
            fcntl.flock(lf, fcntl.LOCK_EX)
            try:
                yield
            finally:
                fcntl.flock(lf, fcntl.LOCK_UN)

    def _empty(self) -> dict:
        return {
            "cap_bytes": self.cap,
            "proxy_bytes_total": 0,
            "direct_bytes_total": 0,
            "proxy_requests_total": 0,
            "by_probe": {},
            "runs": [],
            "updated": _now(),
            "note": "Bytes on the wire to/from the Decodo gateway (CONNECT + TLS + HTTP). Never edit by hand to free budget.",
        }

    def _read(self) -> dict:
        try:
            data = json.loads(self.path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            return self._empty()
        data["cap_bytes"] = self.cap
        return data

    def _write(self, data: dict) -> None:
        data["updated"] = _now()
        fd, tmp = tempfile.mkstemp(dir=self.path.parent, prefix=".ledger.", suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, sort_keys=False)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())  # never let a crash replace the ledger with an empty file
        os.replace(tmp, self.path)

    def init(self) -> None:
        """Create the ledger file (zero usage) if it does not exist yet."""
        with self._locked():
            if not self.path.exists():
                self._write(self._empty())

    def snapshot(self) -> dict:
        with self._locked():
            return self._read()

    def used(self) -> int:
        return int(self.snapshot()["proxy_bytes_total"])

    def remaining(self) -> int:
        return max(0, self.cap - self.used())

    def check_projection(self, projected_bytes: int) -> None:
        used = self.used()
        if used + projected_bytes > self.cap:
            raise BudgetRefused(
                f"projected {projected_bytes:,} B + used {used:,} B exceeds cap {self.cap:,} B "
                f"(remaining {max(0, self.cap - used):,} B). Lower -n or the per-request estimate.")

    def start_run(self, run_id: str, probe: str, meta: dict) -> None:
        with self._locked():
            d = self._read()
            d["runs"].append({"run_id": run_id, "probe": probe, "started": _now(), "ended": None,
                              "proxy_bytes": 0, "direct_bytes": 0, "proxy_requests": 0,
                              "status": "running", **meta})
            self._write(d)

    def record(self, run_id: str, probe: str, nbytes: int, *, proxied: bool = True) -> int:
        """Adds bytes; returns the new proxy total."""
        with self._locked():
            d = self._read()
            bp = d["by_probe"].setdefault(probe, {"proxy_bytes": 0, "direct_bytes": 0, "proxy_requests": 0})
            run = next((r for r in reversed(d["runs"]) if r["run_id"] == run_id), None)
            if proxied:
                d["proxy_bytes_total"] += nbytes
                d["proxy_requests_total"] += 1
                bp["proxy_bytes"] += nbytes
                bp["proxy_requests"] += 1
                if run:
                    run["proxy_bytes"] += nbytes
                    run["proxy_requests"] += 1
            else:
                d["direct_bytes_total"] += nbytes
                bp["direct_bytes"] += nbytes
                if run:
                    run["direct_bytes"] += nbytes
            self._write(d)
            return int(d["proxy_bytes_total"])

    def end_run(self, run_id: str, status: str) -> None:
        with self._locked():
            d = self._read()
            for r in reversed(d["runs"]):
                if r["run_id"] == run_id:
                    r["ended"] = _now()
                    r["status"] = status
                    break
            self._write(d)
