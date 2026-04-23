
from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parent.parent
PROJECT_ROOT = BACKEND_DIR.parent

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=PROJECT_ROOT / ".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = "Arima"
    app_env: Literal["dev", "prod", "test"] = "dev"
    app_host: str = "0.0.0.0"
    app_port: int = 8000

    database_url: str | None = Field(default=None, alias="DATABASE_URL")
    sqlite_db_path: str = Field(default="./wata_smart_tracker.db", alias="SQLITE_DB_PATH")

    postgres_host: str = Field(default="localhost", alias="POSTGRES_HOST")
    postgres_port: int = Field(default=5432, alias="POSTGRES_PORT")
    postgres_db: str = Field(default="wata", alias="POSTGRES_DB")
    postgres_user: str = Field(default="wata", alias="POSTGRES_USER")
    postgres_password: str = Field(default="wata", alias="POSTGRES_PASSWORD")

    jwt_secret: str = Field(default="change-me-for-production", alias="JWT_SECRET")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    jwt_access_token_expire_minutes: int = Field(
        default=60 * 24,
        alias="JWT_ACCESS_TOKEN_EXPIRE_MINUTES",
    )

    ollama_url: str = Field(default="http://localhost:11434", alias="OLLAMA_URL")
    cors_origins: list[str] = Field(
        default_factory=lambda: [
            "http://localhost:3000",
            "http://localhost:8080",
            "http://localhost:5000",
            "http://localhost:61000",
            "http://127.0.0.1:8000",
        ],
        alias="CORS_ORIGINS",
    )
    cors_origin_regex: str | None = Field(default=None, alias="CORS_ORIGIN_REGEX")

    @property
    def resolved_database_url(self) -> str:
        if self.database_url:
            return self.database_url

        if self.app_env == "prod":
            return (
                "postgresql+asyncpg://"
                f"{self.postgres_user}:{self.postgres_password}"
                f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
            )

        sqlite_path = Path(self.sqlite_db_path)
        if not sqlite_path.is_absolute():
            sqlite_path = PROJECT_ROOT / sqlite_path

        sqlite_path.parent.mkdir(parents=True, exist_ok=True)
        normalized_path: str = sqlite_path.resolve().as_posix()
        return f"sqlite+aiosqlite:///{normalized_path}"

    @property
    def resolved_cors_origins(self) -> list[str]:
        return list(dict.fromkeys(self.cors_origins))

    @property
    def resolved_cors_origin_regex(self) -> str | None:
        if self.cors_origin_regex:
            return self.cors_origin_regex

        if self.app_env in {"dev", "test"}:
            return r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"

        return None

@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
