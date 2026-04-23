
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

class TaskReminderUpsert(BaseModel):

    is_enabled: bool = True
    remind_after_hours: int = Field(default=6, gt=0, le=72)
    max_missed_count: int = Field(default=3, gt=0, le=20)

class TaskReminderResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    is_enabled: bool
    remind_after_hours: int
    max_missed_count: int
    last_reminded_at: datetime | None
    missed_count: int
    escalated_to_parent: bool
    parent_alert_message: str | None
    created_at: datetime
    updated_at: datetime