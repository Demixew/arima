from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.api.auth import router as auth_router
from backend.api.tasks import router as tasks_router
from backend.api.metrics import router as metrics_router
from backend.api.teacher import router as teacher_router
from backend.core.config import get_settings
from backend.core.db import init_db
from backend.core.scheduler import build_scheduler

settings = get_settings()
scheduler = build_scheduler()

@asynccontextmanager
async def lifespan(_: FastAPI):
    await init_db()
    if not scheduler.running:
        scheduler.start()
    yield
    if scheduler.running:
        scheduler.shutdown(wait=False)

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.resolved_cors_origins,
    allow_origin_regex=settings.resolved_cors_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", tags=["system"])
async def healthcheck() -> dict[str, str]:
    return {"status": "ok"}

app.include_router(auth_router)
app.include_router(tasks_router)
app.include_router(metrics_router)
app.include_router(teacher_router)
