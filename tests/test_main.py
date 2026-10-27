import pytest

from app.main import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


def test_hello(client):
    resp = client.get("/")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["message"] == "Hello, World from Flask on Kubernetes!"
    assert "version" in body
    assert "pod" in body


def test_healthz(client):
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}
