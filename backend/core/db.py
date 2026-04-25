from __future__ import annotations

from collections.abc import AsyncGenerator
from pathlib import Path

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from backend.core.config import get_settings

class Base(DeclarativeBase):
    pass

settings = get_settings()

engine: AsyncEngine = create_async_engine(
    settings.resolved_database_url,
    echo=False,
    future=True,
)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)

async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session

async def init_db() -> None:
    from backend.models import user, task, reminder, metrics

    async with engine.begin() as connection:
        await connection.run_sync(Base.metadata.create_all)
        await connection.run_sync(_ensure_schema_updates)


def _ensure_schema_updates(connection) -> None:
    inspector = connection.dialect.get_columns

    task_columns = {
        column["name"]
        for column in inspector(connection, "tasks")
    }
    if "review_mode" not in task_columns:
        connection.exec_driver_sql(
            "ALTER TABLE tasks ADD COLUMN review_mode VARCHAR(50) NOT NULL DEFAULT 'teacher_only'"
        )
    if "evaluation_criteria" not in task_columns:
        connection.exec_driver_sql(
            "ALTER TABLE tasks ADD COLUMN evaluation_criteria TEXT"
        )
    if "difficulty_level" not in task_columns:
        connection.exec_driver_sql(
            "ALTER TABLE tasks ADD COLUMN difficulty_level SMALLINT NOT NULL DEFAULT 2"
        )
    if "estimated_time_minutes" not in task_columns:
        connection.exec_driver_sql(
            "ALTER TABLE tasks ADD COLUMN estimated_time_minutes INTEGER"
        )
    if "anti_fatigue_enabled" not in task_columns:
        connection.exec_driver_sql(
            "ALTER TABLE tasks ADD COLUMN anti_fatigue_enabled INTEGER NOT NULL DEFAULT 0"
        )
    if "is_challenge" not in task_columns:
        connection.exec_driver_sql(
            "ALTER TABLE tasks ADD COLUMN is_challenge INTEGER NOT NULL DEFAULT 0"
        )
    if "challenge_title" not in task_columns:
        connection.exec_driver_sql(
            "ALTER TABLE tasks ADD COLUMN challenge_title VARCHAR(255)"
        )
    if "challenge_category" not in task_columns:
        connection.exec_driver_sql(
            "ALTER TABLE tasks ADD COLUMN challenge_category VARCHAR(80)"
        )
    if "challenge_bonus_xp" not in task_columns:
        connection.exec_driver_sql(
            "ALTER TABLE tasks ADD COLUMN challenge_bonus_xp SMALLINT NOT NULL DEFAULT 0"
        )

    submission_columns = {
        column["name"]
        for column in inspector(connection, "task_submissions")
    }
    metric_columns = {
        column["name"]
        for column in inspector(connection, "user_metrics")
    }
    if "bonus_xp" not in metric_columns:
        connection.exec_driver_sql(
            "ALTER TABLE user_metrics ADD COLUMN bonus_xp INTEGER NOT NULL DEFAULT 0"
        )

    if "ai_grade" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_grade SMALLINT"
        )
    if "ai_score_percent" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_score_percent SMALLINT"
        )
    if "ai_confidence" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_confidence SMALLINT"
        )
    if "ai_rating_label" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_rating_label VARCHAR(80)"
        )
    if "ai_feedback" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_feedback TEXT"
        )
    if "ai_strengths_json" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_strengths_json TEXT"
        )
    if "ai_improvements_json" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_improvements_json TEXT"
        )
    if "ai_rubric_json" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_rubric_json TEXT"
        )
    if "ai_risk_flags_json" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_risk_flags_json TEXT"
        )
    if "ai_next_task_json" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_next_task_json TEXT"
        )
    if "ai_checked_at" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_checked_at DATETIME"
        )
    if "ai_model" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_model VARCHAR(120)"
        )
    if "ai_provider" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_provider VARCHAR(50)"
        )
    if "ai_review_status" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_review_status VARCHAR(50) NOT NULL DEFAULT 'not_requested'"
        )
    if "ai_review_error" not in submission_columns:
        connection.exec_driver_sql(
            "ALTER TABLE task_submissions ADD COLUMN ai_review_error TEXT"
        )
