
from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict

class UserMetricsResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    total_tasks_completed: int
    total_tasks_created: int
    current_streak: int
    longest_streak: int
    avg_completion_time_hours: float
    total_focus_time_minutes: int
    completion_rate: int
    last_completed_at: datetime | None
    last_activity_at: datetime | None
    created_at: datetime
    updated_at: datetime

class DailyStatsResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    date: datetime
    tasks_created: int
    tasks_completed: int
    focus_time_minutes: int
    created_at: datetime
    updated_at: datetime

class ParentChildLinkResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    parent_id: int
    child_id: int
    status: str
    created_at: datetime
    updated_at: datetime

class LinkedChildResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    child_id: int
    child_name: str
    child_email: str
    link_status: str
    metrics: UserMetricsResponse | None = None
    recent_tasks: list[dict[str, Any]] = []

class ChildStatsSummary(BaseModel):

    total_tasks: int = 0
    completed_tasks: int = 0
    overdue_tasks: int = 0
    current_streak: int = 0
    completion_rate: int = 0
    last_activity: datetime | None = None

class LinkChildRequest(BaseModel):

    child_email: str
