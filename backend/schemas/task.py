
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from backend.models.task import TaskReviewMode, TaskStatus
from backend.schemas.insights import WeeklyNarrativeResponse
from backend.schemas.reminder import TaskReminderResponse, TaskReminderUpsert


class TaskRescuePlanResponse(BaseModel):
    mini_steps: list[str] = []
    recommended_new_time_block: str | None = None
    difficulty_tone: str | None = None


class StudyPlanTaskRefResponse(BaseModel):
    id: int
    title: str
    status: str
    due_at: datetime | None = None
    difficulty_level: int = 2
    estimated_time_minutes: int | None = None


class StudyPlanResponse(BaseModel):
    focus_message: str
    do_now: list[StudyPlanTaskRefResponse] = []
    do_next: list[StudyPlanTaskRefResponse] = []
    stretch_goal: str | None = None
    estimated_total_minutes: int = 0
    main_skill_to_improve: str | None = None
    weekly_narrative: WeeklyNarrativeResponse | None = None

class TaskCreateRequest(BaseModel):

    title: str = Field(min_length=1, max_length=255)
    description: str | None = Field(default=None, max_length=4000)
    status: TaskStatus = TaskStatus.pending
    due_at: datetime | None = None
    reminder: TaskReminderUpsert | None = None

    assigned_to_student_id: int | None = None
    requires_submission: bool = False
    difficulty_level: int = Field(default=2, ge=1, le=5)
    estimated_time_minutes: int | None = Field(default=None, ge=1, le=480)
    anti_fatigue_enabled: bool = False
    is_challenge: bool = False
    challenge_title: str | None = Field(default=None, max_length=255)
    challenge_category: str | None = Field(default=None, max_length=80)
    challenge_bonus_xp: int = Field(default=0, ge=0, le=500)
    review_mode: TaskReviewMode = TaskReviewMode.teacher_only
    evaluation_criteria: str | None = Field(default=None, max_length=4000)

class TaskUpdateRequest(BaseModel):

    title: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = Field(default=None, max_length=4000)
    status: TaskStatus | None = None
    due_at: datetime | None = None
    reminder: TaskReminderUpsert | None = None
    requires_submission: bool | None = None
    difficulty_level: int | None = Field(default=None, ge=1, le=5)
    estimated_time_minutes: int | None = Field(default=None, ge=1, le=480)
    anti_fatigue_enabled: bool | None = None
    is_challenge: bool | None = None
    challenge_title: str | None = Field(default=None, max_length=255)
    challenge_category: str | None = Field(default=None, max_length=80)
    challenge_bonus_xp: int | None = Field(default=None, ge=0, le=500)
    review_mode: TaskReviewMode | None = None
    evaluation_criteria: str | None = Field(default=None, max_length=4000)

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
    difficulty_level: int
    estimated_time_minutes: int | None
    anti_fatigue_enabled: bool
    is_challenge: bool
    challenge_title: str | None
    challenge_category: str | None
    challenge_bonus_xp: int
    review_mode: TaskReviewMode
    evaluation_criteria: str | None
    rescue_plan: TaskRescuePlanResponse | None = None
    reminder: TaskReminderResponse | None
    submission: "TaskSubmissionResponse | None" = None
    created_at: datetime
    updated_at: datetime

from backend.schemas.teacher import TaskSubmissionResponse
TaskResponse.model_rebuild()
