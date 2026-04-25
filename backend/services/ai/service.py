from __future__ import annotations

import re
from typing import Any

from fastapi import HTTPException

from backend.core.config import get_settings
from backend.services.ai.exceptions import (
    AIConfigurationError,
    AIProviderUnavailableError,
    AIResponseError,
)
from backend.services.ai.providers import (
    AIProvider,
    AIProviderStatus,
    BuiltinProvider,
    OllamaProvider,
)

settings = get_settings()


def _select_provider() -> AIProvider:
    if settings.ai_provider == "ollama":
        return OllamaProvider(settings)
    return BuiltinProvider()


def _is_builtin_mode() -> bool:
    return settings.ai_provider == "builtin"


def _status_to_dict(status: AIProviderStatus) -> dict[str, Any]:
    return {
        "provider": status.provider,
        "provider_label": status.provider_label,
        "ready": status.ready,
        "model": status.model,
        "endpoint": status.endpoint,
        "detail": status.detail,
        "mode": "builtin" if status.provider == "builtin" else "external",
    }


def _normalize_draft(
    parsed: dict[str, Any],
    *,
    provider: str,
    fallback_difficulty: int | None,
    fallback_time: int | None,
) -> dict[str, Any]:
    title = str(parsed.get("title", "")).strip()
    description = str(parsed.get("description", "")).strip()
    if not title or not description:
        raise AIResponseError(provider, "AI returned an incomplete task draft")

    try:
        difficulty = int(parsed.get("difficulty_level"))
    except (TypeError, ValueError):
        difficulty = fallback_difficulty or 2
    difficulty = max(1, min(5, difficulty))

    try:
        estimated_time = int(parsed.get("estimated_time_minutes"))
    except (TypeError, ValueError):
        estimated_time = fallback_time or 15

    return {
        "title": title[:255],
        "description": description[:4000],
        "requires_submission": bool(parsed.get("requires_submission", False)),
        "difficulty_level": difficulty,
        "estimated_time_minutes": max(1, estimated_time),
        "anti_fatigue_enabled": bool(parsed.get("anti_fatigue_enabled", False)),
    }


def _normalize_review(parsed: dict[str, Any], *, provider: str) -> dict[str, Any]:
    try:
        grade = int(parsed.get("grade"))
    except (TypeError, ValueError) as exc:
        raise AIResponseError(provider, "AI returned an invalid grade") from exc

    feedback = str(parsed.get("feedback", "")).strip()
    if grade < 1 or grade > 5 or not feedback:
        raise AIResponseError(provider, "AI returned an incomplete review")

    try:
        score_percent = int(parsed.get("score_percent"))
    except (TypeError, ValueError):
        score_percent = grade * 20
    score_percent = max(0, min(100, score_percent))

    try:
        confidence = int(parsed.get("confidence"))
    except (TypeError, ValueError):
        confidence = 70
    confidence = max(0, min(100, confidence))

    rating_label = str(parsed.get("rating_label", "")).strip() or _rating_label_for_grade(grade)

    strengths = _normalize_string_list(parsed.get("strengths"), limit=3)
    improvements = _normalize_string_list(parsed.get("improvements"), limit=3)
    risk_flags = _normalize_string_list(parsed.get("risk_flags"), limit=4)
    rubric = _normalize_rubric(parsed.get("rubric"), provider=provider)
    next_task = _normalize_next_task(parsed.get("next_task"), provider=provider)

    return {
        "grade": grade,
        "feedback": feedback[:4000],
        "score_percent": score_percent,
        "confidence": confidence,
        "rating_label": rating_label[:80],
        "strengths": strengths,
        "improvements": improvements,
        "risk_flags": risk_flags,
        "rubric": rubric,
        "next_task": next_task,
    }


def _normalize_string_list(value: Any, *, limit: int) -> list[str]:
    if not isinstance(value, list):
        return []

    cleaned: list[str] = []
    for item in value:
        text = str(item).strip()
        if text:
            cleaned.append(text[:240])
        if len(cleaned) >= limit:
            break
    return cleaned


def _normalize_rubric(value: Any, *, provider: str) -> list[dict[str, Any]]:
    if not isinstance(value, list):
        return []

    rubric: list[dict[str, Any]] = []
    for item in value[:4]:
        if not isinstance(item, dict):
            continue

        criterion = str(item.get("criterion", "")).strip()
        if not criterion:
            continue

        try:
            score = int(item.get("score"))
        except (TypeError, ValueError) as exc:
            raise AIResponseError(provider, "AI returned an invalid rubric score") from exc

        try:
            max_score = int(item.get("max_score", 5))
        except (TypeError, ValueError) as exc:
            raise AIResponseError(provider, "AI returned an invalid rubric max score") from exc

        if max_score < 1:
            max_score = 5

        rubric.append(
            {
                "criterion": criterion[:120],
                "score": max(0, min(max_score, score)),
                "max_score": max(1, min(5, max_score)),
                "comment": str(item.get("comment", "")).strip()[:240] or None,
            }
        )

    return rubric


def _rating_label_for_grade(grade: int) -> str:
    return {
        5: "Excellent",
        4: "Strong",
        3: "Developing",
        2: "Needs support",
        1: "Incomplete",
    }.get(grade, "Developing")


def _extract_tokens(value: str) -> list[str]:
    return re.findall(r"[A-Za-zА-Яа-я0-9]+", value.lower())


def _local_risk_flags(
    *,
    task_title: str,
    task_description: str | None,
    evaluation_criteria: str | None,
    submission_text: str,
) -> list[str]:
    text = submission_text.strip()
    tokens = _extract_tokens(text)
    if not tokens:
        return []

    flags: list[str] = []
    unique_ratio = len(set(tokens)) / max(1, len(tokens))
    if len(tokens) >= 20 and unique_ratio < 0.45:
        flags.append("The answer is repetitive, so originality may be low.")

    reference_tokens = set(
        _extract_tokens(" ".join(part for part in [task_title, task_description or "", evaluation_criteria or ""] if part))
    )
    submission_token_set = set(tokens)
    if reference_tokens:
        overlap = len(reference_tokens & submission_token_set) / max(1, len(submission_token_set))
        if len(tokens) >= 12 and overlap > 0.72:
            flags.append("The answer is very close to the task wording, so check for copied prompt language.")

    if len(tokens) < 8:
        flags.append("The answer is very short, so the grade may be less reliable.")

    return flags[:4]


def _normalize_next_task(value: Any, *, provider: str) -> dict[str, Any] | None:
    if not isinstance(value, dict):
        return None

    title = str(value.get("title", "")).strip()
    prompt = str(value.get("prompt", "")).strip()
    if not title or not prompt:
        return None

    try:
        difficulty_level = int(value.get("difficulty_level", 2))
    except (TypeError, ValueError) as exc:
        raise AIResponseError(provider, "AI returned an invalid next-task difficulty") from exc

    estimated_time_raw = value.get("estimated_time_minutes")
    estimated_time: int | None = None
    if estimated_time_raw is not None:
        try:
            estimated_time = int(estimated_time_raw)
        except (TypeError, ValueError) as exc:
            raise AIResponseError(provider, "AI returned an invalid next-task time") from exc

    return {
        "title": title[:255],
        "prompt": prompt[:500],
        "focus_reason": str(value.get("focus_reason", "")).strip()[:240] or None,
        "difficulty_level": max(1, min(5, difficulty_level)),
        "estimated_time_minutes": None if estimated_time is None else max(1, min(480, estimated_time)),
    }


def _map_error_to_http(exc: Exception) -> HTTPException:
    if isinstance(exc, AIProviderUnavailableError):
        detail = exc.detail
        if "memory layout cannot be allocated" in detail.lower():
            detail = (
                "Ollama loaded the model list, but this model cannot run on the current machine. "
                "Use a smaller model such as `qwen2.5:3b`, or free more RAM/VRAM and try again."
            )
        elif "model" in detail.lower() and "not found" in detail.lower():
            detail = (
                "The configured Ollama model is missing. Pull it with `ollama pull <model>` "
                "or update AI_MODEL / OLLAMA_MODEL in `.env`."
            )
        elif "connection refused" in detail.lower():
            detail = "Ollama is not accepting requests. Make sure `ollama serve` is running."
        elif "timeout" in detail.lower():
            detail = "Ollama took too long to respond. Try a smaller model or restart the Ollama server."
        elif "read timeout" in detail.lower():
            detail = "Ollama is running, but the model is responding too slowly. Try again after it warms up, or switch to a smaller model."
        elif "failed during model inference" in detail.lower():
            detail = (
                "Ollama is reachable, but the current model crashes during generation on this machine. "
                "Restart Ollama and switch the app to a smaller model such as `qwen2.5:3b`."
            )
        return HTTPException(status_code=503, detail=detail)
    if isinstance(exc, AIConfigurationError):
        return HTTPException(status_code=400, detail=str(exc))
    if isinstance(exc, AIResponseError):
        return HTTPException(status_code=502, detail=exc.detail)
    return HTTPException(status_code=500, detail="AI request failed")


async def get_ai_status() -> dict[str, Any]:
    provider = _select_provider()
    status = await provider.status()
    return _status_to_dict(status)


async def generate_personalized_task_draft(
    *,
    teacher_name: str,
    student_name: str,
    prompt: str,
    completion_rate: int | None,
    current_streak: int | None,
    total_completed: int | None,
    total_created: int | None,
    difficulty_level: int | None = None,
    estimated_time_minutes: int | None = None,
) -> dict[str, Any]:
    provider = _select_provider()
    try:
        draft = await provider.generate_task_draft(
            teacher_name=teacher_name,
            student_name=student_name,
            prompt=prompt,
            completion_rate=completion_rate,
            current_streak=current_streak,
            total_completed=total_completed,
            total_created=total_created,
            difficulty_level=difficulty_level,
            estimated_time_minutes=estimated_time_minutes,
        )
    except Exception as exc:  # noqa: BLE001
        raise _map_error_to_http(exc) from exc

    if _is_builtin_mode():
        return draft

    normalized = _normalize_draft(
        draft,
        provider=getattr(provider, "provider_name", "external"),
        fallback_difficulty=difficulty_level,
        fallback_time=estimated_time_minutes,
    )
    normalized["model"] = draft.get("model", "")
    normalized["provider"] = draft.get("provider", getattr(provider, "provider_name", "external"))
    return normalized


async def evaluate_submission_with_ai(
    *,
    student_name: str,
    task_title: str,
    task_description: str | None,
    evaluation_criteria: str | None,
    submission_text: str | None,
) -> dict[str, Any]:
    if not submission_text or not submission_text.strip():
        raise HTTPException(status_code=400, detail="Submission text is required for AI review")

    provider = _select_provider()
    try:
        review = await provider.evaluate_submission(
            student_name=student_name,
            task_title=task_title,
            task_description=task_description,
            evaluation_criteria=evaluation_criteria,
            submission_text=submission_text,
        )
    except Exception as exc:  # noqa: BLE001
        raise _map_error_to_http(exc) from exc

    if _is_builtin_mode():
        review["risk_flags"] = list(
            dict.fromkeys(
                [
                    *review.get("risk_flags", []),
                    *_local_risk_flags(
                        task_title=task_title,
                        task_description=task_description,
                        evaluation_criteria=evaluation_criteria,
                        submission_text=submission_text,
                    ),
                ]
            )
        )[:4]
        return review

    normalized = _normalize_review(review, provider=getattr(provider, "provider_name", "external"))
    normalized["risk_flags"] = list(
        dict.fromkeys(
            [
                *normalized.get("risk_flags", []),
                *_local_risk_flags(
                    task_title=task_title,
                    task_description=task_description,
                    evaluation_criteria=evaluation_criteria,
                    submission_text=submission_text,
                ),
            ]
        )
    )[:4]
    normalized["model"] = review.get("model", "")
    normalized["provider"] = review.get("provider", getattr(provider, "provider_name", "external"))
    normalized["checked_at"] = review.get("checked_at")
    return normalized
