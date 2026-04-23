
from __future__ import annotations

import enum
from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, Enum, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.core.db import Base

if TYPE_CHECKING:
    from backend.models.task import Task
    from backend.models.metrics import (
        DailyStats,
        ParentChildLink,
        TaskSubmission,
        TeacherStudentLink,
        UserMetrics,
    )

class UserRole(str, enum.Enum):
    student = "student"
    teacher = "teacher"
    parent = "parent"

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, native_enum=False),
        nullable=False,
        default=UserRole.student,
    )
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

    tasks: Mapped[list["Task"]] = relationship(
        back_populates="owner",
        foreign_keys="Task.owner_id",
        cascade="all, delete-orphan",
    )

    metrics: Mapped["UserMetrics"] = relationship(
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
    )

    linked_children: Mapped[list["ParentChildLink"]] = relationship(
        back_populates="parent",
        foreign_keys="ParentChildLink.parent_id",
        cascade="all, delete-orphan",
    )

    linked_parent: Mapped["ParentChildLink"] = relationship(
        back_populates="child",
        foreign_keys="ParentChildLink.child_id",
        uselist=False,
        cascade="all, delete-orphan",
    )

    daily_stats: Mapped[list["DailyStats"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )

    linked_students: Mapped[list["TeacherStudentLink"]] = relationship(
        back_populates="teacher",
        foreign_keys="TeacherStudentLink.teacher_id",
        cascade="all, delete-orphan",
    )

    linked_teacher: Mapped["TeacherStudentLink"] = relationship(
        back_populates="student",
        foreign_keys="TeacherStudentLink.student_id",
        uselist=False,
        cascade="all, delete-orphan",
    )

    submissions: Mapped[list["TaskSubmission"]] = relationship(
        back_populates="student_user",
        cascade="all, delete-orphan",
    )