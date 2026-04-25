from __future__ import annotations

import asyncio
import json
import logging
from typing import Any

import aiohttp

from tg_bot.config import get_config
from tg_bot.fallback import DEMO_DAILY_STATS, DEMO_METRICS, DEMO_STUDY_PLAN, DEMO_TASKS

logger = logging.getLogger(__name__)


class BackendClient:
    """Async HTTP client for FastAPI backend with fallback to demo data."""

    def __init__(self) -> None:
        self.cfg = get_config()
        self._session: aiohttp.ClientSession | None = None

    async def _get_session(self) -> aiohttp.ClientSession:
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(
                headers={"Content-Type": "application/json"},
                timeout=aiohttp.ClientTimeout(total=15),
            )
        return self._session

    async def close(self) -> None:
        if self._session and not self._session.closed:
            await self._session.close()
            self._session = None

    def _headers(self, token: str | None) -> dict[str, str]:
        h = {"Content-Type": "application/json"}
        if token:
            h["Authorization"] = f"Bearer {token}"
        return h

    async def request(
        self,
        method: str,
        path: str,
        token: str | None = None,
        json_data: dict[str, Any] | None = None,
        params: dict[str, Any] | None = None,
    ) -> tuple[bool, Any]:
        """Returns (ok, data). On failure returns fallback demo data where applicable."""
        session = await self._get_session()
        url = f"{self.cfg.api_url}{path}"
        try:
            async with session.request(
                method,
                url,
                headers=self._headers(token),
                json=json_data,
                params=params,
            ) as resp:
                text = await resp.text()
                if resp.status == 401:
                    logger.warning("Backend returned 401 for %s — token expired", path)
                    return False, {"error": "unauthorized", "detail": "Сессия истекла. Авторизуйтесь заново /start"}
                if resp.status >= 500:
                    logger.error("Backend server error %s on %s: %s", resp.status, path, text)
                    return self._fallback(path)
                if resp.status >= 400:
                    logger.warning("Backend client error %s on %s: %s", resp.status, path, text)
                    try:
                        data = json.loads(text)
                    except json.JSONDecodeError:
                        data = {"detail": text}
                    return False, data
                if resp.status == 204:
                    return True, None
                try:
                    data = json.loads(text)
                except json.JSONDecodeError:
                    data = text
                return True, data
        except aiohttp.ClientError as exc:
            logger.error("Network error on %s: %s", path, exc)
            return self._fallback(path)
        except asyncio.TimeoutError:
            logger.error("Timeout on %s", path)
            return self._fallback(path)
        except Exception as exc:
            logger.exception("Unexpected error on %s: %s", path, exc)
            return self._fallback(path)

    def _fallback(self, path: str) -> tuple[bool, Any]:
        logger.info("Serving fallback demo data for %s", path)
        if path == "/tasks":
            return True, DEMO_TASKS
        if path == "/metrics/me":
            return True, DEMO_METRICS
        if path == "/metrics/me/daily":
            return True, DEMO_DAILY_STATS
        if path == "/tasks/study-plan":
            return True, DEMO_STUDY_PLAN
        return False, {"error": "backend_unavailable", "detail": "Сервер временно недоступен. Попробуйте позже."}

    async def healthcheck(self) -> bool:
        ok, _ = await self.request("GET", "/health")
        return ok

    async def login(self, email: str, password: str) -> tuple[bool, Any]:
        return await self.request(
            "POST",
            "/auth/login",
            json_data={"email": email, "password": password},
        )

    async def me(self, token: str) -> tuple[bool, Any]:
        return await self.request("GET", "/auth/me", token=token)

    async def list_tasks(self, token: str) -> tuple[bool, Any]:
        return await self.request("GET", "/tasks", token=token)

    async def create_task(self, token: str, payload: dict[str, Any]) -> tuple[bool, Any]:
        return await self.request("POST", "/tasks", token=token, json_data=payload)

    async def update_task(self, token: str, task_id: int, payload: dict[str, Any]) -> tuple[bool, Any]:
        return await self.request("PUT", f"/tasks/{task_id}", token=token, json_data=payload)

    async def get_metrics(self, token: str) -> tuple[bool, Any]:
        return await self.request("GET", "/metrics/me", token=token)

    async def get_daily_stats(self, token: str, days: int = 7) -> tuple[bool, Any]:
        return await self.request("GET", "/metrics/me/daily", token=token, params={"days": days})

    async def get_study_plan(self, token: str) -> tuple[bool, Any]:
        return await self.request("GET", "/tasks/study-plan", token=token)


_client: BackendClient | None = None


def get_client() -> BackendClient:
    global _client
    if _client is None:
        _client = BackendClient()
    return _client

