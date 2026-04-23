
from __future__ import annotations

from fastapi.testclient import TestClient

def test_register_login_and_get_me(client: TestClient) -> None:
    register_payload = {
        "email": "teacher@example.com",
        "full_name": "Teacher One",
        "password": "strongpass123",
        "role": "teacher",
    }

    register_response = client.post("/auth/register", json=register_payload)
    assert register_response.status_code == 201

    register_body = register_response.json()
    assert register_body["user"]["email"] == register_payload["email"]
    assert register_body["user"]["role"] == register_payload["role"]
    assert register_body["access_token"]

    login_response = client.post(
        "/auth/login",
        json={
            "email": register_payload["email"],
            "password": register_payload["password"],
        },
    )
    assert login_response.status_code == 200
    login_token = login_response.json()["access_token"]

    me_response = client.get(
        "/auth/me",
        headers={"Authorization": f"Bearer {login_token}"},
    )
    assert me_response.status_code == 200
    me_body = me_response.json()
    assert me_body["email"] == register_payload["email"]
    assert me_body["full_name"] == register_payload["full_name"]

def test_register_duplicate_email_returns_conflict(client: TestClient) -> None:
    payload = {
        "email": "parent@example.com",
        "full_name": "Parent User",
        "password": "strongpass123",
        "role": "parent",
    }

    first_response = client.post("/auth/register", json=payload)
    second_response = client.post("/auth/register", json=payload)

    assert first_response.status_code == 201
    assert second_response.status_code == 409
    assert second_response.json()["detail"] == "User with this email already exists"

def test_login_with_invalid_password_returns_unauthorized(client: TestClient) -> None:
    payload = {
        "email": "student2@example.com",
        "full_name": "Student Two",
        "password": "strongpass123",
        "role": "student",
    }
    client.post("/auth/register", json=payload)

    response = client.post(
        "/auth/login",
        json={"email": payload["email"], "password": "wrongpass123"},
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid email or password"
