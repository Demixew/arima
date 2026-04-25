from __future__ import annotations

import asyncio
from datetime import datetime, timezone

import httpx
from fastapi.testclient import TestClient

from backend.api import teacher as teacher_api
from backend.services import ai_service
from backend.services.ai.providers import OllamaProvider
from backend.services.ai_service import (
    evaluate_submission_with_ai,
    generate_personalized_task_draft,
)


def _register_user(
    client: TestClient,
    *,
    email: str,
    full_name: str,
    role: str,
) -> dict[str, str]:
    response = client.post(
        "/auth/register",
        json={
            "email": email,
            "full_name": full_name,
            "password": "strongpass123",
            "role": role,
        },
    )
    assert response.status_code == 201
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _create_teacher_task(
    client: TestClient,
    *,
    teacher_headers: dict[str, str],
    student_email: str,
    review_mode: str,
) -> int:
    link_response = client.post(
        "/teacher/students/link",
        params={"student_email": student_email},
        headers=teacher_headers,
    )
    assert link_response.status_code == 200

    students_response = client.get("/teacher/students", headers=teacher_headers)
    assert students_response.status_code == 200
    student_id = students_response.json()[0]["student_id"]

    task_response = client.post(
        "/teacher/tasks",
        params={
            "student_id": student_id,
            "title": "Essay",
            "description": "Write a short essay about space.",
            "requires_submission": True,
            "review_mode": review_mode,
            "evaluation_criteria": "Clarity, structure, creativity",
        },
        headers=teacher_headers,
    )
    assert task_response.status_code == 200
    return task_response.json()["id"]


def test_builtin_provider_returns_deterministic_task_draft(monkeypatch) -> None:
    monkeypatch.setattr(ai_service.settings, "ai_provider", "builtin", raising=False)

    draft = asyncio.run(
        generate_personalized_task_draft(
            teacher_name="Teacher One",
            student_name="Student One",
            prompt="Create a short math practice task about fractions",
            completion_rate=42,
            current_streak=3,
            total_completed=8,
            total_created=12,
        )
    )

    assert draft["provider"] == "builtin"
    assert draft["model"] == "builtin-smart"
    assert draft["title"]
    assert draft["description"]
    assert draft["requires_submission"] is True


def test_ollama_provider_uses_ai_model_override(monkeypatch) -> None:
    monkeypatch.setattr(ai_service.settings, "ai_provider", "ollama", raising=False)
    monkeypatch.setattr(ai_service.settings, "ai_model", "custom-model", raising=False)
    provider = OllamaProvider(ai_service.settings)

    assert provider.model == "custom-model"


def test_ollama_ai_review_uses_generate_without_thinking(monkeypatch) -> None:
    captured: dict[str, object] = {}

    async def fake_post(self, url, headers=None, json=None):  # type: ignore[no-untyped-def]
        captured["url"] = url
        captured["payload"] = json
        request = httpx.Request("POST", str(url))
        return httpx.Response(
            200,
            json={
                "response": '{"grade": 4, "score_percent": 82, "confidence": 76, "rating_label": "Strong", "strengths": ["Clear main idea"], "improvements": ["Add one more example"], "risk_flags": ["Could use more evidence"], "rubric": [{"criterion": "Clarity", "score": 4, "max_score": 5, "comment": "Mostly clear"}], "next_task": {"title": "Practice evidence", "prompt": "Create a short follow-up task about adding evidence.", "focus_reason": "Evidence was weakest.", "difficulty_level": 3, "estimated_time_minutes": 15}, "feedback": "Clear answer with room for one more example."}'
            },
            request=request,
        )

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post, raising=False)
    monkeypatch.setattr(ai_service.settings, "ai_provider", "ollama", raising=False)
    monkeypatch.setattr(ai_service.settings, "ai_model", "qwen3.5:4b", raising=False)

    review = asyncio.run(
        evaluate_submission_with_ai(
            student_name="Student One",
            task_title="Essay",
            task_description="Write a short essay about space.",
            evaluation_criteria="Clarity, structure, creativity",
            submission_text="Space is interesting because planets move around the sun.",
        )
    )

    assert captured["url"] == "http://127.0.0.1:11434/api/generate"
    payload = captured["payload"]
    assert isinstance(payload, dict)
    assert payload["think"] is False
    assert payload["format"] == "json"
    assert payload["stream"] is False
    assert "Do not show your thinking." in payload["prompt"]
    assert payload["options"]["num_predict"] == 200
    assert review["grade"] == 4
    assert review["score_percent"] == 82
    assert review["confidence"] == 76
    assert review["rating_label"] == "Strong"
    assert review["strengths"] == ["Clear main idea"]
    assert review["risk_flags"] == ["Could use more evidence"]
    assert review["next_task"]["title"] == "Practice evidence"
    assert review["provider"] == "ollama"


def test_ollama_ai_review_accepts_json_like_python_dict(monkeypatch) -> None:
    async def fake_post(self, url, headers=None, json=None):  # type: ignore[no-untyped-def]
        request = httpx.Request("POST", str(url))
        return httpx.Response(
            200,
            json={
                "response": """```json
{'grade': 4, 'score_percent': 80, 'confidence': 71, 'rating_label': 'Strong', 'strengths': ['Correct answers'], 'improvements': ['Show one step of reasoning'], 'risk_flags': ['The answer is short, so confidence is lower'], 'rubric': [{'criterion': 'Accuracy', 'score': 4, 'max_score': 5, 'comment': 'Mostly correct',}], 'next_task': {'title': 'More arithmetic', 'prompt': 'Solve 3 more examples and show the steps.', 'focus_reason': 'Reasoning needs practice', 'difficulty_level': 2, 'estimated_time_minutes': 10,}, 'feedback': 'Good work. Add one more step so the teacher can follow your reasoning.'}
```"""
            },
            request=request,
        )

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post, raising=False)
    monkeypatch.setattr(ai_service.settings, "ai_provider", "ollama", raising=False)
    monkeypatch.setattr(ai_service.settings, "ai_model", "qwen3.5:4b", raising=False)

    review = asyncio.run(
        evaluate_submission_with_ai(
            student_name="Student One",
            task_title="Arithmetic",
            task_description="Solve the examples.",
            evaluation_criteria="Accuracy, clarity",
            submission_text="1) 19 2) 3 3) 8",
        )
    )

    assert review["grade"] == 4
    assert review["score_percent"] == 80
    assert review["strengths"] == ["Correct answers"]
    assert review["rubric"][0]["criterion"] == "Accuracy"
    assert review["next_task"]["estimated_time_minutes"] == 10


def test_ai_status_reports_builtin_mode(client: TestClient, monkeypatch) -> None:
    teacher_headers = _register_user(
        client,
        email="teacher@example.com",
        full_name="Teacher One",
        role="teacher",
    )
    monkeypatch.setattr(ai_service.settings, "ai_provider", "builtin", raising=False)

    response = client.get("/teacher/ai/status", headers=teacher_headers)

    assert response.status_code == 200
    body = response.json()
    assert body["provider"] == "builtin"
    assert body["mode"] == "builtin"
    assert body["ready"] is True


def test_teacher_ai_task_draft_returns_explicit_failure_when_ollama_is_down(
    client: TestClient,
    monkeypatch,
) -> None:
    async def fake_post(self, *args, **kwargs):  # type: ignore[no-untyped-def]
        request = httpx.Request("POST", "http://localhost:11434/api/chat")
        raise httpx.ConnectError("Connection refused", request=request)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post, raising=False)
    monkeypatch.setattr(ai_service.settings, "ai_provider", "ollama", raising=False)

    teacher_headers = _register_user(
        client,
        email="teacher@example.com",
        full_name="Teacher One",
        role="teacher",
    )
    _register_user(
        client,
        email="student@example.com",
        full_name="Student One",
        role="student",
    )

    _create_teacher_task(
        client,
        teacher_headers=teacher_headers,
        student_email="student@example.com",
        review_mode="teacher_only",
    )

    students_response = client.get("/teacher/students", headers=teacher_headers)
    student_id = students_response.json()[0]["student_id"]

    response = client.post(
        "/teacher/ai/task-draft",
        json={
            "student_id": student_id,
            "prompt": "Create a short math practice task about fractions",
            "difficulty_level": 2,
            "estimated_time_minutes": 15,
        },
        headers=teacher_headers,
    )

    assert response.status_code == 503
    assert "ollama serve" in response.json()["detail"]


def test_student_submission_auto_grades_with_builtin_ai_only_mode(
    client: TestClient,
    monkeypatch,
) -> None:
    monkeypatch.setattr(ai_service.settings, "ai_provider", "builtin", raising=False)

    teacher_headers = _register_user(
        client,
        email="teacher@example.com",
        full_name="Teacher One",
        role="teacher",
    )
    student_headers = _register_user(
        client,
        email="student@example.com",
        full_name="Student One",
        role="student",
    )

    task_id = _create_teacher_task(
        client,
        teacher_headers=teacher_headers,
        student_email="student@example.com",
        review_mode="ai_only",
    )

    submit_response = client.post(
        f"/teacher/tasks/{task_id}/submit",
        json={"submission_text": "My essay text"},
        headers=student_headers,
    )
    assert submit_response.status_code == 200
    body = submit_response.json()
    assert body["is_graded"] is True
    assert body["grade"] is not None
    assert body["ai_grade"] is not None
    assert body["ai_review_status"] == "ready"
    assert body["review_mode"] == "ai_only"


def test_student_submission_auto_runs_ai_review_for_teacher_and_ai_mode(
    client: TestClient,
    monkeypatch,
) -> None:
    async def fake_review(**kwargs):  # type: ignore[no-untyped-def]
        return {
            "grade": 4,
            "score_percent": 82,
            "confidence": 76,
            "rating_label": "Strong",
            "feedback": "Clear answer with one idea to expand.",
            "strengths": ["Clear structure"],
            "improvements": ["Add one more supporting detail"],
            "risk_flags": ["The answer could use more evidence."],
            "rubric": [
                {"criterion": "Clarity", "score": 4, "max_score": 5, "comment": "Easy to follow"},
            ],
            "next_task": {
                "title": "Evidence follow-up",
                "prompt": "Create a short task that practices adding evidence.",
                "focus_reason": "Evidence was the weakest area.",
                "difficulty_level": 3,
                "estimated_time_minutes": 15,
            },
            "model": "qwen3.5:4b",
            "provider": "ollama",
            "checked_at": datetime.now(timezone.utc),
        }

    monkeypatch.setattr(teacher_api, "evaluate_submission_with_ai", fake_review)
    monkeypatch.setattr(ai_service.settings, "ai_provider", "ollama", raising=False)

    teacher_headers = _register_user(
        client,
        email="teacher@example.com",
        full_name="Teacher One",
        role="teacher",
    )
    student_headers = _register_user(
        client,
        email="student@example.com",
        full_name="Student One",
        role="student",
    )

    task_id = _create_teacher_task(
        client,
        teacher_headers=teacher_headers,
        student_email="student@example.com",
        review_mode="teacher_and_ai",
    )

    submit_response = client.post(
        f"/teacher/tasks/{task_id}/submit",
        json={"submission_text": "My essay text"},
        headers=student_headers,
    )

    assert submit_response.status_code == 200
    body = submit_response.json()
    assert body["is_graded"] is False
    assert body["ai_review_status"] == "ready"
    assert body["ai_grade"] == 4
    assert body["ai_score_percent"] == 82
    assert body["ai_confidence"] == 76
    assert body["ai_rating_label"] == "Strong"
    assert body["ai_strengths"] == ["Clear structure"]
    assert body["ai_risk_flags"] == ["The answer could use more evidence."]
    assert body["ai_next_task"]["title"] == "Evidence follow-up"
    assert body["ai_feedback"] == "Clear answer with one idea to expand."
    assert body["ai_provider"] == "ollama"


def test_student_submission_auto_runs_ai_review_and_grades_for_ai_only_mode(
    client: TestClient,
    monkeypatch,
) -> None:
    async def fake_review(**kwargs):  # type: ignore[no-untyped-def]
        return {
            "grade": 5,
            "score_percent": 94,
            "confidence": 88,
            "rating_label": "Excellent",
            "feedback": "Excellent work with clear structure.",
            "strengths": ["Strong structure"],
            "improvements": ["Keep this level of detail"],
            "risk_flags": [],
            "rubric": [
                {"criterion": "Structure", "score": 5, "max_score": 5, "comment": "Very clear"},
            ],
            "next_task": {
                "title": "Stretch task",
                "prompt": "Create a slightly harder extension task.",
                "focus_reason": "The student is ready for a stretch task.",
                "difficulty_level": 4,
                "estimated_time_minutes": 20,
            },
            "model": "qwen3.5:4b",
            "provider": "ollama",
            "checked_at": datetime.now(timezone.utc),
        }

    monkeypatch.setattr(teacher_api, "evaluate_submission_with_ai", fake_review)
    monkeypatch.setattr(ai_service.settings, "ai_provider", "ollama", raising=False)

    teacher_headers = _register_user(
        client,
        email="teacher2@example.com",
        full_name="Teacher Two",
        role="teacher",
    )
    student_headers = _register_user(
        client,
        email="student2@example.com",
        full_name="Student Two",
        role="student",
    )

    task_id = _create_teacher_task(
        client,
        teacher_headers=teacher_headers,
        student_email="student2@example.com",
        review_mode="ai_only",
    )

    submit_response = client.post(
        f"/teacher/tasks/{task_id}/submit",
        json={"submission_text": "My essay text"},
        headers=student_headers,
    )

    assert submit_response.status_code == 200
    body = submit_response.json()
    assert body["is_graded"] is True
    assert body["grade"] == 5
    assert body["feedback"] == "Excellent work with clear structure."
    assert body["ai_review_status"] == "ready"
    assert body["ai_score_percent"] == 94
    assert body["ai_next_task"]["difficulty_level"] == 4


def test_manual_ai_review_marks_failure_explicitly_when_provider_is_down(
    client: TestClient,
    monkeypatch,
) -> None:
    async def fake_post(self, *args, **kwargs):  # type: ignore[no-untyped-def]
        request = httpx.Request("POST", "http://localhost:11434/api/chat")
        raise httpx.ConnectError("Connection refused", request=request)

    monkeypatch.setattr(httpx.AsyncClient, "post", fake_post, raising=False)
    monkeypatch.setattr(ai_service.settings, "ai_provider", "ollama", raising=False)

    teacher_headers = _register_user(
        client,
        email="teacher@example.com",
        full_name="Teacher One",
        role="teacher",
    )
    student_headers = _register_user(
        client,
        email="student@example.com",
        full_name="Student One",
        role="student",
    )

    task_id = _create_teacher_task(
        client,
        teacher_headers=teacher_headers,
        student_email="student@example.com",
        review_mode="teacher_and_ai",
    )

    submit_response = client.post(
        f"/teacher/tasks/{task_id}/submit",
        json={"submission_text": "My essay text"},
        headers=student_headers,
    )
    submission_id = submit_response.json()["id"]

    review_response = client.post(
        f"/teacher/submissions/{submission_id}/ai-review",
        headers=teacher_headers,
    )

    assert review_response.status_code == 503

    submissions_response = client.get("/teacher/submissions", headers=teacher_headers)
    submission = submissions_response.json()[0]
    assert submission["ai_review_status"] == "failed"
    assert submission["ai_review_error"]


def test_assign_ai_next_task_creates_follow_up_task(
    client: TestClient,
    monkeypatch,
) -> None:
    async def fake_review(**kwargs):  # type: ignore[no-untyped-def]
        return {
            "grade": 4,
            "score_percent": 80,
            "confidence": 70,
            "rating_label": "Solid",
            "feedback": "Good work.",
            "strengths": ["Clear answer"],
            "improvements": ["Add more evidence"],
            "risk_flags": [],
            "rubric": [],
            "next_task": {
                "title": "Evidence booster",
                "prompt": "Write one more paragraph with stronger evidence.",
                "focus_reason": "Evidence needs more work.",
                "difficulty_level": 3,
                "estimated_time_minutes": 15,
            },
            "model": "qwen2.5:3b",
            "provider": "ollama",
            "checked_at": datetime.now(timezone.utc),
        }

    monkeypatch.setattr(teacher_api, "evaluate_submission_with_ai", fake_review)

    teacher_headers = _register_user(
        client,
        email="teacher3@example.com",
        full_name="Teacher Three",
        role="teacher",
    )
    student_headers = _register_user(
        client,
        email="student3@example.com",
        full_name="Student Three",
        role="student",
    )

    task_id = _create_teacher_task(
        client,
        teacher_headers=teacher_headers,
        student_email="student3@example.com",
        review_mode="teacher_and_ai",
    )

    submit_response = client.post(
        f"/teacher/tasks/{task_id}/submit",
        json={"submission_text": "My essay text"},
        headers=student_headers,
    )
    submission_id = submit_response.json()["id"]

    assign_response = client.post(
        f"/teacher/submissions/{submission_id}/assign-ai-next-task",
        headers=teacher_headers,
    )

    assert assign_response.status_code == 200
    body = assign_response.json()
    assert body["title"] == "Evidence booster"
    assert body["review_mode"] == "teacher_and_ai"


def test_teacher_students_include_risk_summary_and_narrative(
    client: TestClient,
    monkeypatch,
) -> None:
    monkeypatch.setattr(ai_service.settings, "ai_provider", "builtin", raising=False)
    teacher_headers = _register_user(
        client,
        email="teacher4@example.com",
        full_name="Teacher Four",
        role="teacher",
    )
    _register_user(
        client,
        email="student4@example.com",
        full_name="Student Four",
        role="student",
    )

    _create_teacher_task(
        client,
        teacher_headers=teacher_headers,
        student_email="student4@example.com",
        review_mode="teacher_only",
    )

    response = client.get("/teacher/students", headers=teacher_headers)

    assert response.status_code == 200
    body = response.json()[0]
    assert "risk_score" in body
    assert body["risk_level"] in {"stable", "watch", "high"}
    assert "risk_reason" in body
    assert body["weekly_narrative"]["headline"]


def test_teacher_can_extend_deadline(
    client: TestClient,
) -> None:
    teacher_headers = _register_user(
        client,
        email="teacher5@example.com",
        full_name="Teacher Five",
        role="teacher",
    )
    _register_user(
        client,
        email="student5@example.com",
        full_name="Student Five",
        role="student",
    )

    task_id = _create_teacher_task(
        client,
        teacher_headers=teacher_headers,
        student_email="student5@example.com",
        review_mode="teacher_only",
    )

    response = client.post(
        f"/teacher/tasks/{task_id}/extend-deadline",
        params={"due_at": "2026-05-01T18:00:00Z"},
        headers=teacher_headers,
    )

    assert response.status_code == 200
    assert response.json()["due_at"] == "2026-05-01T18:00:00"
