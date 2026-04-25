
from __future__ import annotations

import enum
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    SmallInteger,
    String,
    Text,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core.db import Base

if TYPE_CHECKING:
    from backend.models.task import Task
    from backend.models.user import User

class UserMetrics(Base):

    __tablename__ = "user_metrics"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False
    )

    total_tasks_completed: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_tasks_created: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    current_streak: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    longest_streak: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    avg_completion_time_hours: Mapped[float] = mapped_column(Integer, default=0, nullable=False)
    total_focus_time_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    bonus_xp: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    completion_rate: Mapped[int] = mapped_column(SmallInteger, default=0, nullable=False)

    last_completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_activity_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

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

    user: Mapped["User"] = relationship(back_populates="metrics")

class ParentChildLink(Base):

    __tablename__ = "parent_child_links"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    parent_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    child_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
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

    parent: Mapped["User"] = relationship(
        foreign_keys=[parent_id],
        back_populates="linked_children",
    )
    child: Mapped["User"] = relationship(
        foreign_keys=[child_id],
        back_populates="linked_parent",
    )

class DailyStats(Base):

    __tablename__ = "daily_stats"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    tasks_created: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    tasks_completed: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    focus_time_minutes: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
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

    user: Mapped["User"] = relationship(back_populates="daily_stats")

class TeacherStudentLink(Base):

    __tablename__ = "teacher_student_links"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    teacher_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
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

    teacher: Mapped["User"] = relationship(
        foreign_keys=[teacher_id],
        back_populates="linked_students",
    )
    student: Mapped["User"] = relationship(
        foreign_keys=[student_id],
        back_populates="linked_teacher",
    )


class AIReviewStatus(str, enum.Enum):
    not_requested = "not_requested"
    pending = "pending"
    ready = "ready"
    failed = "failed"

class TaskSubmission(Base):

    __tablename__ = "task_submissions"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    task_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("tasks.id", ondelete="CASCADE"), nullable=False
    )
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    submission_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_graded: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    grade: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    feedback: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_grade: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    ai_score_percent: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    ai_confidence: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    ai_rating_label: Mapped[str | None] = mapped_column(String(80), nullable=True)
    ai_feedback: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_strengths_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_improvements_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_rubric_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_risk_flags_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_next_task_json: Mapped[str | None] = mapped_column(Text, nullable=True)
    ai_checked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ai_model: Mapped[str | None] = mapped_column(String(120), nullable=True)
    ai_provider: Mapped[str | None] = mapped_column(String(50), nullable=True)
    ai_review_status: Mapped[AIReviewStatus] = mapped_column(
        Enum(AIReviewStatus, native_enum=False),
        default=AIReviewStatus.not_requested,
        nullable=False,
    )
    ai_review_error: Mapped[str | None] = mapped_column(Text, nullable=True)
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    graded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
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

    task: Mapped["Task"] = relationship(back_populates="submission")
    student_user: Mapped["User"] = relationship(back_populates="submissions")
