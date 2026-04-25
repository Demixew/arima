
from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field

from backend.schemas.insights import WeeklyNarrativeResponse
from backend.schemas.metrics import UserMetricsResponse
from backend.models.metrics import AIReviewStatus
from backend.models.task import TaskReviewMode

class TaskSubmissionUpsert(BaseModel):

    submission_text: str | None = None
    image_url: str | None = None

class AIRubricItemResponse(BaseModel):
    criterion: str
    score: int = Field(ge=0, le=5)
    max_score: int = Field(ge=1, le=5, default=5)
    comment: str | None = None


class AINextTaskSuggestionResponse(BaseModel):
    title: str
    prompt: str
    focus_reason: str | None = None
    difficulty_level: int = Field(ge=1, le=5, default=2)
    estimated_time_minutes: int | None = Field(default=None, ge=1, le=480)


class AITrendSummaryResponse(BaseModel):
    weakest_area: str | None = None
    trend_summary: str | None = None
    risk_flag_count: int = 0
    reviewed_count: int = 0


class TaskSubmissionResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    task_id: int
    student_id: int
    submission_text: str | None
    image_url: str | None
    is_graded: bool
    grade: int | None
    feedback: str | None
    ai_grade: int | None
    ai_score_percent: int | None = None
    ai_confidence: int | None = None
    ai_rating_label: str | None = None
    ai_feedback: str | None
    ai_strengths: list[str] = []
    ai_improvements: list[str] = []
    ai_rubric: list[AIRubricItemResponse] = []
    ai_risk_flags: list[str] = []
    ai_next_task: AINextTaskSuggestionResponse | None = None
    ai_checked_at: datetime | None
    ai_model: str | None
    ai_provider: str | None
    ai_review_status: AIReviewStatus = AIReviewStatus.not_requested
    ai_review_error: str | None
    submitted_at: datetime
    graded_at: datetime | None
    task_title: str | None = None
    task_description: str | None = None
    review_mode: TaskReviewMode | None = None
    evaluation_criteria: str | None = None
    student_name: str | None = None

class GradeSubmissionRequest(BaseModel):

    grade: int = Field(ge=1, le=5, description="School grade from 1 to 5")
    feedback: str | None = None


class AITaskDraftRequest(BaseModel):
    student_id: int
    prompt: str = Field(min_length=3, max_length=1000)
    difficulty_level: int | None = Field(default=None, ge=1, le=5)
    estimated_time_minutes: int | None = Field(default=None, ge=1, le=480)


class AITaskDraftResponse(BaseModel):
    title: str
    description: str
    requires_submission: bool = False
    difficulty_level: int = 2
    estimated_time_minutes: int | None = None
    anti_fatigue_enabled: bool = False
    model: str
    provider: str | None = None


class AIStatusResponse(BaseModel):
    provider: str
    provider_label: str
    ready: bool
    model: str = ""
    endpoint: str = ""
    detail: str = ""
    mode: Literal["builtin", "external"]

class TeacherStudentLinkResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    teacher_id: int
    student_id: int
    status: str
    created_at: datetime
    updated_at: datetime

class LinkedStudentResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    id: int
    student_id: int
    student_name: str
    student_email: str
    link_status: str
    metrics: "UserMetricsResponse | None" = None
    assigned_tasks_count: int = 0
    submitted_count: int = 0
    graded_count: int = 0
    risk_score: int = 0
    risk_level: Literal["stable", "watch", "high"] = "stable"
    risk_reason: str = ""
    ai_trend: AITrendSummaryResponse | None = None
    weekly_narrative: WeeklyNarrativeResponse | None = None

class TeacherMetricsResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    total_students: int = 0
    total_assigned_tasks: int = 0
    total_submissions: int = 0
    pending_grading: int = 0
    avg_grade: float = 0.0

LinkedStudentResponse.model_rebuild()
