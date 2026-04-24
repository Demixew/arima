from __future__ import annotations

import json
from typing import Any

import httpx
from fastapi import HTTPException

from backend.core.config import get_settings

settings = get_settings()


def _extract_json_object(content: str) -> dict[str, Any]:
    start = content.find("{")
    end = content.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError("Model response does not contain JSON")

    return json.loads(content[start : end + 1])


async def generate_personalized_task_draft(
    *,
    teacher_name: str,
    student_name: str,
    prompt: str,
    completion_rate: int | None,
    current_streak: int | None,
    total_completed: int | None,
    total_created: int | None,
) -> dict[str, Any]:
    system_prompt = (
        "You generate short, practical school task drafts for a teacher. "
        "Return only valid JSON with keys: title, description, requires_submission. "
        "The title must be concise. The description must be 2-5 sentences, age-appropriate, "
        "clear, and personalized. requires_submission must be a boolean."
    )
    user_prompt = (
        f"Teacher: {teacher_name}\n"
        f"Student: {student_name}\n"
        f"Teacher request: {prompt}\n"
        f"Student completion rate: {completion_rate if completion_rate is not None else 'unknown'}%\n"
        f"Current streak: {current_streak if current_streak is not None else 'unknown'} days\n"
        f"Completed tasks: {total_completed if total_completed is not None else 'unknown'}\n"
        f"Created tasks: {total_created if total_created is not None else 'unknown'}\n\n"
        "Adapt difficulty gently: if completion rate is low, keep the task simpler and more motivating. "
        "If completion rate is high, you may make it slightly more challenging."
    )

    payload = {
        "model": settings.ollama_model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        "stream": False,
        "options": {
            "temperature": 0.4,
        },
    }

    try:
        async with httpx.AsyncClient(timeout=45.0) as client:
            response = await client.post(
                f"{settings.ollama_url}/api/chat",
                json=payload,
            )
            response.raise_for_status()
    except httpx.TimeoutException as exc:
        raise HTTPException(status_code=504, detail="Ollama request timed out") from exc
    except httpx.HTTPError as exc:
        raise HTTPException(status_code=502, detail="Cannot reach Ollama") from exc

    data = response.json()
    content = (
        data.get("message", {}).get("content", "")
        if isinstance(data, dict)
        else ""
    )

    try:
        parsed = _extract_json_object(content)
    except (ValueError, json.JSONDecodeError) as exc:
        raise HTTPException(
            status_code=502,
            detail="Ollama returned an invalid draft format",
        ) from exc

    title = str(parsed.get("title", "")).strip()
    description = str(parsed.get("description", "")).strip()
    requires_submission = bool(parsed.get("requires_submission", False))

    if not title or not description:
        raise HTTPException(status_code=502, detail="Ollama returned an incomplete draft")

    return {
        "title": title[:255],
        "description": description[:4000],
        "requires_submission": requires_submission,
        "model": settings.ollama_model,
    }
