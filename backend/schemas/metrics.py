
from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict

from backend.schemas.insights import WeeklyNarrativeResponse


class BadgeResponse(BaseModel):
    id: str
    title: str
    description: str
    icon: str
    accent_color: str


class DailyChallengeResponse(BaseModel):
    id: str
    title: str
    description: str
    current: int
    target: int
    reward_xp: int
    completed: bool


class GamificationProfileResponse(BaseModel):
    total_xp: int
    level: int
    rank_title: str
    current_level_xp: int
    next_level_xp: int
    progress_percent: int
    energy: int
    next_unlock_hint: str | None = None
    unlocked_badges: list[BadgeResponse] = []
    daily_challenges: list[DailyChallengeResponse] = []


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
    gamification: GamificationProfileResponse | None = None

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
    positive_signal: str | None = None
    attention_signal: str | None = None
    recommended_action: str | None = None
    support_summary: str | None = None
    needs_attention: bool = False
    weekly_narrative: WeeklyNarrativeResponse | None = None

class ChildStatsSummary(BaseModel):

    total_tasks: int = 0
    completed_tasks: int = 0
    overdue_tasks: int = 0
    current_streak: int = 0
    completion_rate: int = 0
    last_activity: datetime | None = None
    gamification: GamificationProfileResponse | None = None
    positive_signal: str | None = None
    attention_signal: str | None = None
    recommended_action: str | None = None
    support_summary: str | None = None
    weekly_narrative: WeeklyNarrativeResponse | None = None

class LinkChildRequest(BaseModel):

    child_email: str
