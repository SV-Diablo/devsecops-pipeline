import pytest

from app import create_app


@pytest.fixture()
def client(tmp_path):
    app = create_app(str(tmp_path / "test.db"))
    return app.test_client()


def test_health(client):
    assert client.get("/health").get_json() == {"status": "ok"}


def test_filter_by_owner(client):
    data = client.get("/assets?owner=platform").get_json()
    assert {a["hostname"] for a in data} == {"web-01", "db-01"}


def test_sql_injection_payload_returns_nothing(client):
    # A classic tautology must be treated as a literal owner name, not as SQL.
    data = client.get("/assets?owner=' OR '1'='1").get_json()
    assert data == []


def test_criticality_allow_list(client):
    assert client.get("/assets/by-criticality/critical").status_code == 200
    assert client.get("/assets/by-criticality/critical' --").status_code == 400
