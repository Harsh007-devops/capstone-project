"""
Unit tests - this is what Jenkins CI runs in the 'Run unit tests' stage.
"""
from fastapi.testclient import TestClient
from main import app, tasks

client = TestClient(app)


def setup_function():
    """Reset in-memory store before each test."""
    tasks.clear()


def test_root():
    resp = client.get("/")
    assert resp.status_code == 200
    assert resp.json()["service"] == "task-management-api"


def test_liveness():
    resp = client.get("/health/live")
    assert resp.status_code == 200
    assert resp.json()["status"] == "alive"


def test_readiness():
    resp = client.get("/health/ready")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ready"


def test_metrics_endpoint():
    resp = client.get("/metrics")
    assert resp.status_code == 200


def test_create_task():
    resp = client.post("/tasks", json={"title": "Write Terraform", "description": "VPC + GKE"})
    assert resp.status_code == 201
    body = resp.json()
    assert body["title"] == "Write Terraform"
    assert body["completed"] is False
    assert "id" in body


def test_list_tasks():
    client.post("/tasks", json={"title": "Task 1"})
    client.post("/tasks", json={"title": "Task 2"})
    resp = client.get("/tasks")
    assert resp.status_code == 200
    assert len(resp.json()) == 2


def test_get_task():
    created = client.post("/tasks", json={"title": "Task 1"}).json()
    resp = client.get(f"/tasks/{created['id']}")
    assert resp.status_code == 200
    assert resp.json()["id"] == created["id"]


def test_get_task_not_found():
    resp = client.get("/tasks/does-not-exist")
    assert resp.status_code == 404


def test_update_task():
    created = client.post("/tasks", json={"title": "Task 1"}).json()
    resp = client.put(f"/tasks/{created['id']}", json={"completed": True})
    assert resp.status_code == 200
    assert resp.json()["completed"] is True


def test_delete_task():
    created = client.post("/tasks", json={"title": "Task 1"}).json()
    resp = client.delete(f"/tasks/{created['id']}")
    assert resp.status_code == 204
    resp2 = client.get(f"/tasks/{created['id']}")
    assert resp2.status_code == 404
