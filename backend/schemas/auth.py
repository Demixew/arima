
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from backend.models.user import UserRole

class UserRegisterRequest(BaseModel):
    email: EmailStr
    full_name: str = Field(min_length=2, max_length=255)
    password: str = Field(min_length=8, max_length=128)
    role: UserRole

class UserLoginRequest(BaseModel):

    email: EmailStr
    password: str = Field(min_length=8, max_length=128)

class UserResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    email: EmailStr
    full_name: str
    role: UserRole
    created_at: datetime
    updated_at: datetime

class TokenResponse(BaseModel):

    access_token: str
    token_type: str = "bearer"

class AuthResponse(BaseModel):

    access_token: str
    token_type: str = "bearer"
    user: UserResponse
