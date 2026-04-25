
from __future__ import annotations

import os
import sys
from collections.abc import Generator
from pathlib import Path

project_root = Path(__file__).parent.parent.parent.resolve()
sys.path.insert(0, str(project_root))

import pytest
from fastapi.testclient import TestClient

TEST_DB_PATH = Path(__file__).resolve().parent / "test_wata.db"
os.environ["APP_ENV"] = "test"
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{TEST_DB_PATH.resolve().as_posix()}"
os.environ["JWT_SECRET"] = "test-secret-key-for-jwt-minimum-32-chars-long"

from backend.core.db import Base, engine
from backend.main import app

@pytest.fixture(autouse=True)
def reset_database() -> Generator[None, None, None]:
    import asyncio

    async def _reset() -> None:
        async with engine.begin() as connection:
            await connection.run_sync(Base.metadata.drop_all)
            await connection.run_sync(Base.metadata.create_all)

    asyncio.run(_reset())
    yield

@pytest.fixture()
def client() -> Generator[TestClient, None, None]:
    with TestClient(app) as test_client:
        yield test_client

@pytest.fixture()
def auth_headers(client: TestClient) -> dict[str, str]:
    register_payload = {
        "email": "student@example.com",
        "full_name": "Student Tester",
        "password": "strongpass123",
        "role": "student",
    }
    register_response = client.post("/auth/register", json=register_payload)
    assert register_response.status_code == 201

    token = register_response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
