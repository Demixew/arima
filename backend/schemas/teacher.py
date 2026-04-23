
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from backend.schemas.metrics import UserMetricsResponse

class TaskSubmissionUpsert(BaseModel):

    submission_text: str | None = None
    image_url: str | None = None

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
    submitted_at: datetime
    graded_at: datetime | None

class GradeSubmissionRequest(BaseModel):

    grade: int = Field(ge=1, le=5, description="School grade from 1 to 5")
    feedback: str | None = None

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

class TeacherMetricsResponse(BaseModel):

    model_config = ConfigDict(from_attributes=True)

    total_students: int = 0
    total_assigned_tasks: int = 0
    total_submissions: int = 0
    pending_grading: int = 0
    avg_grade: float = 0.0

LinkedStudentResponse.model_rebuild()
