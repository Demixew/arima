
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from backend.models.task import TaskStatus
from backend.schemas.reminder import TaskReminderResponse, TaskReminderUpsert

class TaskCreateRequest(BaseModel):

    title: str = Field(min_length=1, max_length=255)
    description: str | None = Field(default=None, max_length=4000)
    status: TaskStatus = TaskStatus.pending
    due_at: datetime | None = None
    reminder: TaskReminderUpsert | None = None

    assigned_to_student_id: int | None = None
    requires_submission: bool = False

class TaskUpdateRequest(BaseModel):

    title: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = Field(default=None, max_length=4000)
    status: TaskStatus | None = None
    due_at: datetime | None = None
    reminder: TaskReminderUpsert | None = None
    requires_submission: bool | None = None

class TaskResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str | None
    status: TaskStatus
    due_at: datetime | None
    owner_id: int
    assigned_by_teacher_id: int | None
    requires_submission: bool
    reminder: TaskReminderResponse | None
    submission: "TaskSubmissionResponse | None" = None
    created_at: datetime
    updated_at: datetime

from backend.schemas.teacher import TaskSubmissionResponse
TaskResponse.model_rebuild()
