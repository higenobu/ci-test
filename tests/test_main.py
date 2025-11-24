from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_read_root():
    r = client.get("/")
    assert r.status_code == 200
    assert "message" in r.json()

def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}

def test_compute_max():
    r = client.post("/max", json={"numbers": [1, 5, 3]})
    assert r.status_code == 200
    assert r.json()["max"] == 5

def test_compute_max_empty():
    r = client.post("/max", json={"numbers": []})
    assert r.status_code == 400
