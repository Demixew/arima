from __future__ import annotations

import os
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class BotConfig(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(Path(__file__).with_name(".env")),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    bot_token: str
    backend_url: str = "http://127.0.0.1:8000"

    @property
    def api_url(self) -> str:
        return self.backend_url.rstrip("/")


_cfg: BotConfig | None = None


def get_config() -> BotConfig:
    global _cfg
    if _cfg is None:
        _cfg = BotConfig()
    return _cfg

