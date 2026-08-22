"""
Task Management API - sample app for the DevOps capstone.
Deliberately simple business logic; the point of the capstone is the
pipeline/infra/ops work around this app, not the app itself.
"""
from datetime import datetime, timezone
from typing import Optional
from uuid import uuid4

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response
import time

app = FastAPI(
    title="Task Management API",
    description="Sample app for AWS/GCP Enterprise DevOps Capstone",
    version="1.0.0",
)

# ---- in-memory "database" ----
tasks: dict[str, dict] = {}

# ---- Prometheus metrics (scraped by Cloud Monitoring's managed Prometheus,
#      or by a Prometheus/Grafana stack if you deploy one) ----
REQUEST_COUNT = Counter(
    "http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"]
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds", "Request latency", ["endpoint"]
)


@app.middleware("http")
async def metrics_middleware(request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    REQUEST_LATENCY.labels(endpoint=request.url.path).observe(duration)
    REQUEST_COUNT.labels(
        method=request.method, endpoint=request.url.path, status=response.status_code
    ).inc()
    return response


class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    completed: Optional[bool] = None


class Task(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    completed: bool = False
    created_at: str


# ---- health endpoints: used by K8s readiness/liveness probes ----
@app.get("/health/live", tags=["health"])
def liveness():
    """Liveness probe: is the process up at all."""
    return {"status": "alive"}


@app.get("/health/ready", tags=["health"])
def readiness():
    """Readiness probe: is the app ready to serve traffic."""
    return {"status": "ready", "tasks_in_memory": len(tasks)}


# ---- Prometheus scrape endpoint ----
@app.get("/metrics", tags=["observability"])
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


# ---- CRUD endpoints ----
@app.post("/tasks", response_model=Task, status_code=201, tags=["tasks"])
def create_task(payload: TaskCreate):
    task_id = str(uuid4())
    task = {
        "id": task_id,
        "title": payload.title,
        "description": payload.description,
        "completed": False,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    tasks[task_id] = task
    return task


@app.get("/tasks", response_model=list[Task], tags=["tasks"])
def list_tasks():
    return list(tasks.values())


@app.get("/tasks/{task_id}", response_model=Task, tags=["tasks"])
def get_task(task_id: str):
    task = tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.put("/tasks/{task_id}", response_model=Task, tags=["tasks"])
def update_task(task_id: str, payload: TaskUpdate):
    task = tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    update_data = payload.model_dump(exclude_unset=True)
    task.update(update_data)
    return task


@app.delete("/tasks/{task_id}", status_code=204, tags=["tasks"])
def delete_task(task_id: str):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    del tasks[task_id]
    return None


@app.get("/", tags=["root"])
def root():
    return {
        "service": "task-management-api",
        "docs": "/docs",
        "health": "/health/live",
        "metrics": "/metrics",
    }
