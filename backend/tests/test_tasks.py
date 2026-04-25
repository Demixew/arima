
from __future__ import annotations

from fastapi.testclient import TestClient

def test_task_crud_flow(client: TestClient, auth_headers: dict[str, str]) -> None:
    create_payload = {
        "title": "Finish homework",
        "description": "Math pages 10-12",
        "status": "pending",
        "due_at": "2026-04-23T18:00:00Z",
    }

    create_response = client.post("/tasks", json=create_payload, headers=auth_headers)
    assert create_response.status_code == 201
    created_task = create_response.json()
    task_id = created_task["id"]

    assert created_task["title"] == create_payload["title"]
    assert created_task["status"] == create_payload["status"]

    get_response = client.get(f"/tasks/{task_id}", headers=auth_headers)
    assert get_response.status_code == 200
    assert get_response.json()["id"] == task_id

    update_response = client.put(
        f"/tasks/{task_id}",
        json={"status": "completed", "title": "Finish homework now"},
        headers=auth_headers,
    )
    assert update_response.status_code == 200
    updated_task = update_response.json()
    assert updated_task["status"] == "completed"
    assert updated_task["title"] == "Finish homework now"

    list_response = client.get("/tasks", headers=auth_headers)
    assert list_response.status_code == 200
    tasks = list_response.json()
    assert len(tasks) == 1
    assert tasks[0]["id"] == task_id

    delete_response = client.delete(f"/tasks/{task_id}", headers=auth_headers)
    assert delete_response.status_code == 204

    list_after_delete_response = client.get("/tasks", headers=auth_headers)
    assert list_after_delete_response.status_code == 200
    assert list_after_delete_response.json() == []

def test_tasks_require_authentication(client: TestClient) -> None:
    response = client.get("/tasks")

    assert response.status_code == 401

def test_user_cannot_access_another_users_task(client: TestClient) -> None:
    first_user = {
        "email": "first@example.com",
        "full_name": "First User",
        "password": "strongpass123",
        "role": "student",
    }
    second_user = {
        "email": "second@example.com",
        "full_name": "Second User",
        "password": "strongpass123",
        "role": "student",
    }

    first_register = client.post("/auth/register", json=first_user)
    second_register = client.post("/auth/register", json=second_user)

    first_headers = {"Authorization": f"Bearer {first_register.json()['access_token']}"}
    second_headers = {"Authorization": f"Bearer {second_register.json()['access_token']}"}

    task_response = client.post(
        "/tasks",
        json={"title": "Private task", "description": "Visible only to owner"},
        headers=first_headers,
    )
    task_id = task_response.json()["id"]

    forbidden_read = client.get(f"/tasks/{task_id}", headers=second_headers)
    forbidden_update = client.put(
        f"/tasks/{task_id}",
        json={"title": "Hijacked"},
        headers=second_headers,
    )
    forbidden_delete = client.delete(f"/tasks/{task_id}", headers=second_headers)

    assert forbidden_read.status_code == 404
    assert forbidden_update.status_code == 404
    assert forbidden_delete.status_code == 404


def test_metrics_endpoint_returns_gamification_summary(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    create_response = client.post(
        "/tasks",
        json={"title": "Level up task", "description": "Earn progress"},
        headers=auth_headers,
    )
    task_id = create_response.json()["id"]

    update_response = client.put(
        f"/tasks/{task_id}",
        json={"title": "Level up task", "status": "completed"},
        headers=auth_headers,
    )
    assert update_response.status_code == 200

    metrics_response = client.get("/metrics/me", headers=auth_headers)

    assert metrics_response.status_code == 200
    body = metrics_response.json()
    assert body["gamification"]["total_xp"] > 0
    assert body["gamification"]["level"] >= 1
    assert body["gamification"]["rank_title"]
    assert len(body["gamification"]["daily_challenges"]) == 3
    badge_ids = {badge["id"] for badge in body["gamification"]["unlocked_badges"]}
    assert "first_task" in badge_ids
    assert "first_finish" in badge_ids
    assert body["total_focus_time_minutes"] >= 15


def test_study_plan_endpoint_returns_structured_plan(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    create_response = client.post(
        "/tasks",
        json={
            "title": "Write summary",
            "description": "Summarize chapter 2",
            "status": "pending",
            "due_at": "2026-04-26T18:00:00Z",
            "difficulty_level": 3,
            "estimated_time_minutes": 25,
        },
        headers=auth_headers,
    )
    assert create_response.status_code == 201

    plan_response = client.get("/tasks/study-plan", headers=auth_headers)

    assert plan_response.status_code == 200
    body = plan_response.json()
    assert "focus_message" in body
    assert "do_now" in body
    assert "do_next" in body
    assert "estimated_total_minutes" in body
    assert "weekly_narrative" in body


def test_challenge_task_grants_bonus_xp(
    client: TestClient,
    auth_headers: dict[str, str],
) -> None:
    create_response = client.post(
        "/tasks",
        json={
            "title": "Weekly challenge",
            "description": "Finish two revision tasks",
            "is_challenge": True,
            "challenge_title": "Weekly challenge",
            "challenge_category": "weekly_goal",
            "challenge_bonus_xp": 80,
        },
        headers=auth_headers,
    )
    assert create_response.status_code == 201
    task_id = create_response.json()["id"]

    update_response = client.put(
        f"/tasks/{task_id}",
        json={"title": "Weekly challenge", "status": "completed"},
        headers=auth_headers,
    )
    assert update_response.status_code == 200
    body = update_response.json()
    assert body["is_challenge"] is True
    assert body["challenge_bonus_xp"] == 80

    metrics_response = client.get("/metrics/me", headers=auth_headers)
    assert metrics_response.status_code == 200
    assert metrics_response.json()["gamification"]["total_xp"] >= 215
