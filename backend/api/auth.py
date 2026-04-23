
from __future__ import annotations

import hashlib
import hmac
import os
from datetime import datetime, timedelta, timezone
from http import HTTPStatus
from typing import Any

import jwt
from fastapi import APIRouter, Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import Select, select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.config import get_settings
from backend.core.db import get_db_session
from backend.models.user import User
from backend.schemas.auth import (
    AuthResponse,
    TokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
)

router = APIRouter(prefix="/auth", tags=["auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")
settings = get_settings()

def hash_password(password: str, salt: str | None = None) -> str:
    password_salt: str = salt or os.urandom(16).hex()
    password_hash: bytes = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        password_salt.encode("utf-8"),
        100_000,
    )
    return f"{password_salt}${password_hash.hex()}"

def verify_password(password: str, hashed_password: str) -> bool:
    try:
        salt, expected_hash = hashed_password.split("$", maxsplit=1)
    except ValueError:
        return False

    candidate_hash: str = hash_password(password, salt).split("$", maxsplit=1)[1]
    return hmac.compare_digest(candidate_hash, expected_hash)

def create_access_token(subject: str) -> str:
    expires_at: datetime = datetime.now(timezone.utc) + timedelta(
        minutes=settings.jwt_access_token_expire_minutes
    )
    payload: dict[str, Any] = {
        "sub": subject,
        "exp": expires_at,
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)

async def get_current_user(
    session: AsyncSession = Depends(get_db_session),
    token: str = Depends(oauth2_scheme),
) -> User:
    unauthorized_error = HTTPException(
        status_code=HTTPStatus.UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload: dict[str, Any] = jwt.decode(
            token,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
    except jwt.InvalidTokenError as exc:
        raise unauthorized_error from exc

    subject: str | None = payload.get("sub")
    if subject is None:
        raise unauthorized_error

    statement: Select[tuple[User]] = select(User).where(User.email == subject)
    result = await session.execute(statement)
    user: User | None = result.scalar_one_or_none()
    if user is None:
        raise unauthorized_error
    return user

@router.post(
    "/register",
    response_model=AuthResponse,
    status_code=HTTPStatus.CREATED,
)
async def register_user(
    payload: UserRegisterRequest,
    session: AsyncSession = Depends(get_db_session),
) -> AuthResponse:
    statement: Select[tuple[User]] = select(User).where(User.email == payload.email)
    existing_user = (await session.execute(statement)).scalar_one_or_none()
    if existing_user is not None:
        raise HTTPException(
            status_code=HTTPStatus.CONFLICT,
            detail="User with this email already exists",
        )

    user = User(
        email=payload.email,
        full_name=payload.full_name,
        hashed_password=hash_password(payload.password),
        role=payload.role,
    )
    session.add(user)
    await session.commit()
    await session.refresh(user)

    token: str = create_access_token(subject=user.email)
    return AuthResponse(access_token=token, user=UserResponse.model_validate(user))

@router.post(
    "/login",
    response_model=TokenResponse,
    status_code=HTTPStatus.OK,
)
async def login_user(
    payload: UserLoginRequest,
    session: AsyncSession = Depends(get_db_session),
) -> TokenResponse:
    statement: Select[tuple[User]] = select(User).where(User.email == payload.email)
    user = (await session.execute(statement)).scalar_one_or_none()
    if user is None or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=HTTPStatus.UNAUTHORIZED,
            detail="Invalid email or password",
        )

    token: str = create_access_token(subject=user.email)
    return TokenResponse(access_token=token)

@router.get(
    "/me",
    response_model=UserResponse,
    status_code=HTTPStatus.OK,
)
async def read_current_user(current_user: User = Depends(get_current_user)) -> UserResponse:
    return UserResponse.model_validate(current_user)
