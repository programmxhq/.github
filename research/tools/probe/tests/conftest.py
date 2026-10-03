import copy
import sys
from pathlib import Path

import pytest

TOOLS = Path(__file__).resolve().parents[2]  # research/tools
if str(TOOLS) not in sys.path:
    sys.path.insert(0, str(TOOLS))

from probe.creds import Credentials, REDACTOR  # noqa: E402
from probe.runner import load_config  # noqa: E402

from .servers import FixtureServer, StubProxy, make_cert  # noqa: E402

TEST_USER = "spTestUser42"
TEST_PASS = "s3cr3t-PaSS-xyz"


@pytest.fixture(scope="session")
def cert(tmp_path_factory):
    pytest.importorskip("cryptography")
    return make_cert(str(tmp_path_factory.mktemp("tls")))


@pytest.fixture(scope="session")
def origin(cert):
    s = FixtureServer(cert)
    yield s
    s.close()


@pytest.fixture(scope="session")
def origin_http():
    s = FixtureServer(None)
    yield s
    s.close()


@pytest.fixture
def proxy():
    p = StubProxy(TEST_USER, TEST_PASS)
    yield p
    p.close()


@pytest.fixture
def creds(proxy):
    REDACTOR.add(TEST_USER, TEST_PASS)
    return Credentials(user=TEST_USER, password=TEST_PASS, host="127.0.0.1", port=proxy.port, source="test")


@pytest.fixture
def cfg(tmp_path):
    c = copy.deepcopy(load_config())
    c["paths"] = {
        "probes_dir": str(tmp_path / "probes"),
        "ledger": str(tmp_path / "probes" / "traffic_ledger.json"),
        "probes_md": str(tmp_path / "probes" / "PROBES.md"),
        "log": str(tmp_path / "logs" / "probe-agent.md"),
    }
    c["requests"]["jitter_s"] = [0, 0]
    c["requests"]["timeout_s"] = 5
    return c
