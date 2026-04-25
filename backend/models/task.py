
from __future__ import annotations

import enum
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String, Text, func
from sqlalchemy import Integer, SmallInteger
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core.db import Base

if TYPE_CHECKING:
    from backend.models.metrics import TaskSubmission
    from backend.models.user import User
    from backend.models.reminder import TaskReminder

class TaskStatus(str, enum.Enum):
    pending = "pending"
    in_progress = "in_progress"
    completed = "completed"
    overdue = "overdue"


class TaskReviewMode(str, enum.Enum):
    teacher_only = "teacher_only"
    teacher_and_ai = "teacher_and_ai"
    ai_only = "ai_only"

class Task(Base):
    __tablename__ = "tasks"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[TaskStatus] = mapped_column(
        Enum(TaskStatus, native_enum=False),
        nullable=False,
        default=TaskStatus.pending,
    )
    due_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    owner_id: Mapped[int] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    assigned_by_teacher_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    requires_submission: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    difficulty_level: Mapped[int] = mapped_column(
        SmallInteger,
        default=2,
        nullable=False,
    )
    estimated_time_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    anti_fatigue_enabled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_challenge: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    challenge_title: Mapped[str | None] = mapped_column(String(255), nullable=True)
    challenge_category: Mapped[str | None] = mapped_column(String(80), nullable=True)
    challenge_bonus_xp: Mapped[int] = mapped_column(SmallInteger, default=0, nullable=False)
    review_mode: Mapped[TaskReviewMode] = mapped_column(
        Enum(TaskReviewMode, native_enum=False),
        nullable=False,
        default=TaskReviewMode.teacher_only,
    )
    evaluation_criteria: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    reminder: Mapped["TaskReminder | None"] = relationship(
        back_populates="task",
        cascade="all, delete-orphan",
        uselist=False,
    )
    submission: Mapped["TaskSubmission | None"] = relationship(
        back_populates="task",
        cascade="all, delete-orphan",
        uselist=False,
    )

    owner: Mapped["User"] = relationship(
        back_populates="tasks",
        foreign_keys=[owner_id],
    )
