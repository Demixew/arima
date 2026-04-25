
from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.core.db import get_db_session
from backend.api.auth import get_current_user
from backend.models.task import Task, TaskReviewMode
from backend.models.user import User, UserRole
from backend.models.metrics import AIReviewStatus, TaskSubmission, TeacherStudentLink, UserMetrics
from backend.schemas.teacher import (
    AITaskDraftRequest,
    AITaskDraftResponse,
    AIStatusResponse,
    GradeSubmissionRequest,
    LinkedStudentResponse,
    TaskSubmissionResponse,
    TaskSubmissionUpsert,
    TeacherMetricsResponse,
)
from backend.schemas.task import TaskResponse
from backend.services import metrics_service
from backend.services import insights_service
from backend.services.ai_service import (
    evaluate_submission_with_ai,
    generate_personalized_task_draft,
    get_ai_status,
)

router = APIRouter(prefix="/teacher", tags=["teacher"])

def _now() -> datetime:
    return datetime.now(timezone.utc)


def _serialize_submission(submission: TaskSubmission) -> TaskSubmissionResponse:
    payload = TaskSubmissionResponse.model_validate(submission).model_dump()
    payload["task_title"] = submission.task.title if submission.task else None
    payload["task_description"] = submission.task.description if submission.task else None
    payload["review_mode"] = submission.task.review_mode if submission.task else None
    payload["evaluation_criteria"] = (
        submission.task.evaluation_criteria if submission.task else None
    )
    payload["student_name"] = (
        submission.student_user.full_name if submission.student_user else None
    )
    payload["ai_strengths"] = _decode_json_list(submission.ai_strengths_json)
    payload["ai_improvements"] = _decode_json_list(submission.ai_improvements_json)
    payload["ai_rubric"] = _decode_json_list(submission.ai_rubric_json)
    payload["ai_risk_flags"] = _decode_json_list(submission.ai_risk_flags_json)
    payload["ai_next_task"] = _decode_json_object(submission.ai_next_task_json)
    return TaskSubmissionResponse(**payload)


def _decode_json_list(raw: str | None) -> list[Any]:
    if not raw:
        return []

    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError:
        return []

    return parsed if isinstance(parsed, list) else []


def _decode_json_object(raw: str | None) -> dict[str, Any] | None:
    if not raw:
        return None

    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError:
        return None

    return parsed if isinstance(parsed, dict) else None


def _build_ai_trend_summary(tasks: list[Task]) -> dict[str, Any] | None:
    rubric_scores: dict[str, list[int]] = {}
    risk_flag_count = 0
    reviewed_count = 0

    for task in tasks:
        submission = task.submission
        if not submission or submission.ai_review_status != AIReviewStatus.ready:
            continue

        reviewed_count += 1
        risk_flag_count += len(_decode_json_list(submission.ai_risk_flags_json))

        for item in _decode_json_list(submission.ai_rubric_json):
            if not isinstance(item, dict):
                continue
            criterion = str(item.get("criterion", "")).strip()
            score = item.get("score")
            if not criterion or not isinstance(score, int):
                continue
            rubric_scores.setdefault(criterion, []).append(score)

    if reviewed_count == 0:
        return None

    weakest_area = None
    weakest_avg = None
    for criterion, scores in rubric_scores.items():
        avg = sum(scores) / len(scores)
        if weakest_avg is None or avg < weakest_avg:
            weakest_avg = avg
            weakest_area = criterion

    if weakest_area and weakest_avg is not None:
        if weakest_avg >= 4.2:
            trend_summary = f"AI sees stable strong results. Best to stretch the student while maintaining {weakest_area.lower()}."
        elif weakest_avg >= 3:
            trend_summary = f"AI sees developing performance. The main area to strengthen is {weakest_area.lower()}."
        else:
            trend_summary = f"AI sees a repeated struggle in {weakest_area.lower()}. More guided follow-up tasks would help."
    else:
        trend_summary = "AI reviews are available, but there is not enough rubric data for a trend yet."

    return {
        "weakest_area": weakest_area,
        "trend_summary": trend_summary,
        "risk_flag_count": risk_flag_count,
        "reviewed_count": reviewed_count,
    }


def _clear_ai_review(submission: TaskSubmission) -> None:
    submission.ai_grade = None
    submission.ai_score_percent = None
    submission.ai_confidence = None
    submission.ai_rating_label = None
    submission.ai_feedback = None
    submission.ai_strengths_json = None
    submission.ai_improvements_json = None
    submission.ai_rubric_json = None
    submission.ai_risk_flags_json = None
    submission.ai_next_task_json = None
    submission.ai_checked_at = None
    submission.ai_model = None
    submission.ai_provider = None
    submission.ai_review_error = None
    submission.ai_review_status = AIReviewStatus.not_requested


async def _run_submission_ai_review(
    *,
    submission: TaskSubmission,
    session: AsyncSession,
) -> None:
    if submission.task is None or submission.student_user is None:
        raise HTTPException(status_code=404, detail="Submission context is incomplete")

    submission.ai_review_status = AIReviewStatus.pending
    submission.ai_review_error = None
    await session.commit()

    try:
        review = await evaluate_submission_with_ai(
            student_name=submission.student_user.full_name,
            task_title=submission.task.title,
            task_description=submission.task.description,
            evaluation_criteria=submission.task.evaluation_criteria,
            submission_text=submission.submission_text,
        )
    except HTTPException as exc:
        submission.ai_review_status = AIReviewStatus.failed
        submission.ai_review_error = exc.detail
        submission.ai_grade = None
        submission.ai_score_percent = None
        submission.ai_confidence = None
        submission.ai_rating_label = None
        submission.ai_feedback = None
        submission.ai_strengths_json = None
        submission.ai_improvements_json = None
        submission.ai_rubric_json = None
        submission.ai_risk_flags_json = None
        submission.ai_next_task_json = None
        submission.ai_checked_at = None
        submission.ai_model = None
        submission.ai_provider = None
        await session.commit()
        raise

    submission.ai_review_status = AIReviewStatus.ready
    submission.ai_review_error = None
    submission.ai_grade = review["grade"]
    submission.ai_score_percent = review.get("score_percent")
    submission.ai_confidence = review.get("confidence")
    submission.ai_rating_label = review.get("rating_label")
    submission.ai_feedback = review["feedback"]
    submission.ai_strengths_json = json.dumps(review.get("strengths", []))
    submission.ai_improvements_json = json.dumps(review.get("improvements", []))
    submission.ai_rubric_json = json.dumps(review.get("rubric", []))
    submission.ai_risk_flags_json = json.dumps(review.get("risk_flags", []))
    submission.ai_next_task_json = json.dumps(review.get("next_task"))
    submission.ai_checked_at = review["checked_at"]
    submission.ai_model = review["model"]
    submission.ai_provider = review.get("provider")

    if submission.task.review_mode == TaskReviewMode.ai_only:
        submission.grade = review["grade"]
        submission.feedback = review["feedback"]
        submission.is_graded = True
        submission.graded_at = review["checked_at"]

    await session.commit()

async def _get_teacher_user(
    current_user: User = Depends(get_current_user),
) -> User:
    if current_user.role != UserRole.teacher:
        raise HTTPException(status_code=403, detail="Only teachers can access this endpoint")
    return current_user

async def _get_student_user(
    current_user: User = Depends(get_current_user),
) -> User:
    if current_user.role != UserRole.student:
        raise HTTPException(status_code=403, detail="Only students can access this endpoint")
    return current_user

@router.post("/tasks/{task_id}/submit", response_model=TaskSubmissionResponse)
async def submit_task(
    task_id: int,
    payload: TaskSubmissionUpsert,
    current_user: User = Depends(_get_student_user),
    session: AsyncSession = Depends(get_db_session),
) -> TaskSubmissionResponse:

    result = await session.execute(
        select(Task)
        .options(selectinload(Task.submission))
        .where(Task.id == task_id)
    )
    task = result.scalar_one_or_none()

    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    if task.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not your task")

    if not task.requires_submission:
        raise HTTPException(status_code=400, detail="This task does not require submission")

    submission: TaskSubmission | None = None
    if task.submission:

        submission = task.submission
        submission.submission_text = payload.submission_text
        submission.image_url = payload.image_url
        submission.submitted_at = _now()
        _clear_ai_review(submission)
    else:

        submission = TaskSubmission(
            task_id=task_id,
            student_id=current_user.id,
            submission_text=payload.submission_text,
            image_url=payload.image_url,
        )
        session.add(submission)
        _clear_ai_review(submission)

    await session.commit()
    result = await session.execute(
        select(TaskSubmission)
        .where(TaskSubmission.id == submission.id)
        .options(selectinload(TaskSubmission.task), selectinload(TaskSubmission.student_user))
    )
    submission = result.scalar_one()

    if submission.task and submission.task.review_mode in (
        TaskReviewMode.teacher_and_ai,
        TaskReviewMode.ai_only,
    ):
        try:
            await _run_submission_ai_review(submission=submission, session=session)
        except HTTPException:
            pass

    result = await session.execute(
        select(TaskSubmission)
        .where(TaskSubmission.id == submission.id)
        .options(selectinload(TaskSubmission.task), selectinload(TaskSubmission.student_user))
    )
    refreshed_submission = result.scalar_one()
    return _serialize_submission(refreshed_submission)


@router.get("/ai/status", response_model=AIStatusResponse)
async def get_teacher_ai_status(
    current_user: User = Depends(_get_teacher_user),
) -> AIStatusResponse:
    return AIStatusResponse(**(await get_ai_status()))

@router.get("/students", response_model=list[LinkedStudentResponse])
async def get_linked_students(
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> list[LinkedStudentResponse]:
    result = await session.execute(
        select(TeacherStudentLink)
        .where(
            TeacherStudentLink.teacher_id == current_user.id,
            TeacherStudentLink.status == "active",
        )
        .options(selectinload(TeacherStudentLink.student))
    )
    links = result.scalars().all()

    students = []
    for link in links:
        student_user = link.student

        metrics_result = await session.execute(
            select(UserMetrics).where(UserMetrics.user_id == student_user.id)
        )
        metrics = metrics_result.scalar_one_or_none()

        tasks_result = await session.execute(
            select(Task)
            .options(selectinload(Task.submission))
            .where(
                Task.owner_id == student_user.id,
                Task.assigned_by_teacher_id == current_user.id,
            )
        )
        tasks = tasks_result.scalars().all()

        submitted = sum(1 for t in tasks if t.submission is not None)
        graded = sum(1 for t in tasks if t.submission and t.submission.is_graded)
        risk_summary = insights_service.build_teacher_risk_summary(
            tasks=tasks,
            metrics=metrics,
        )

        students.append(
            LinkedStudentResponse(
                id=link.id,
                student_id=student_user.id,
                student_name=student_user.full_name,
                student_email=student_user.email,
                link_status=link.status,
                metrics=metrics,
                assigned_tasks_count=len(tasks),
                submitted_count=submitted,
                graded_count=graded,
                risk_score=risk_summary["risk_score"],
                risk_level=risk_summary["risk_level"],
                risk_reason=risk_summary["risk_reason"],
                ai_trend=_build_ai_trend_summary(tasks),
                weekly_narrative=insights_service.build_weekly_narrative(
                    role="teacher",
                    person_name=student_user.full_name,
                    tasks=tasks,
                    metrics=metrics,
                ),
            )
        )

    return students

@router.post("/students/link")
async def link_student(
    student_email: str,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, str]:

    result = await session.execute(
        select(User).where(User.email == student_email, User.role == UserRole.student)
    )
    student = result.scalar_one_or_none()

    if not student:
        raise HTTPException(status_code=404, detail="Student not found")

    existing = await session.execute(
        select(TeacherStudentLink).where(
            TeacherStudentLink.teacher_id == current_user.id,
            TeacherStudentLink.student_id == student.id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Already linked to this student")

    link = TeacherStudentLink(teacher_id=current_user.id, student_id=student.id)
    session.add(link)
    await session.commit()
    return {"status": "linked", "student_id": str(student.id)}


@router.post("/ai/task-draft", response_model=AITaskDraftResponse)
async def create_ai_task_draft(
    payload: AITaskDraftRequest,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> AITaskDraftResponse:
    link_result = await session.execute(
        select(TeacherStudentLink)
        .options(selectinload(TeacherStudentLink.student))
        .where(
            TeacherStudentLink.teacher_id == current_user.id,
            TeacherStudentLink.student_id == payload.student_id,
            TeacherStudentLink.status == "active",
        )
    )
    link = link_result.scalar_one_or_none()
    if not link or link.student is None:
        raise HTTPException(status_code=403, detail="Student not linked to you")

    metrics_result = await session.execute(
        select(UserMetrics).where(UserMetrics.user_id == payload.student_id)
    )
    metrics = metrics_result.scalar_one_or_none()

    draft = await generate_personalized_task_draft(
        teacher_name=current_user.full_name,
        student_name=link.student.full_name,
        prompt=payload.prompt,
        completion_rate=metrics.completion_rate if metrics else None,
        current_streak=metrics.current_streak if metrics else None,
        total_completed=metrics.total_tasks_completed if metrics else None,
        total_created=metrics.total_tasks_created if metrics else None,
        difficulty_level=payload.difficulty_level,
        estimated_time_minutes=payload.estimated_time_minutes,
    )
    return AITaskDraftResponse(**draft)


@router.post(
    "/submissions/{submission_id}/ai-review",
    response_model=TaskSubmissionResponse,
)
async def run_ai_review_for_submission(
    submission_id: int,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> TaskSubmissionResponse:
    result = await session.execute(
        select(TaskSubmission)
        .where(TaskSubmission.id == submission_id)
        .options(selectinload(TaskSubmission.task), selectinload(TaskSubmission.student_user))
    )
    submission = result.scalar_one_or_none()
    if not submission or submission.task is None or submission.student_user is None:
        raise HTTPException(status_code=404, detail="Submission not found")

    if submission.task.assigned_by_teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You did not assign this task")

    await _run_submission_ai_review(submission=submission, session=session)
    result = await session.execute(
        select(TaskSubmission)
        .where(TaskSubmission.id == submission.id)
        .options(selectinload(TaskSubmission.task), selectinload(TaskSubmission.student_user))
    )
    refreshed_submission = result.scalar_one()
    return _serialize_submission(refreshed_submission)

@router.delete("/students/{student_id}/unlink")
async def unlink_student(
    student_id: int,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, str]:
    result = await session.execute(
        select(TeacherStudentLink).where(
            TeacherStudentLink.teacher_id == current_user.id,
            TeacherStudentLink.student_id == student_id,
            TeacherStudentLink.status == "active",
        )
    )
    link = result.scalar_one_or_none()

    if not link:
        raise HTTPException(status_code=404, detail="Link not found")

    link.status = "inactive"
    await session.commit()
    return {"status": "unlinked"}

@router.post("/tasks", response_model=TaskResponse)
async def assign_task(
    student_id: int,
    title: str,
    description: str | None = None,
    due_at: datetime | None = None,
    requires_submission: bool = False,
    difficulty_level: int = Query(default=2, ge=1, le=5),
    estimated_time_minutes: int | None = Query(default=None, ge=1, le=480),
    anti_fatigue_enabled: bool = False,
    is_challenge: bool = False,
    challenge_title: str | None = None,
    challenge_category: str | None = None,
    challenge_bonus_xp: int = Query(default=0, ge=0, le=500),
    review_mode: TaskReviewMode = TaskReviewMode.teacher_only,
    evaluation_criteria: str | None = None,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> TaskResponse:

    link_result = await session.execute(
        select(TeacherStudentLink).where(
            TeacherStudentLink.teacher_id == current_user.id,
            TeacherStudentLink.student_id == student_id,
            TeacherStudentLink.status == "active",
        )
    )
    if not link_result.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Student not linked to you")

    task = Task(
        title=title,
        description=description,
        owner_id=student_id,
        due_at=due_at,
        assigned_by_teacher_id=current_user.id,
        requires_submission=requires_submission,
        difficulty_level=difficulty_level,
        estimated_time_minutes=estimated_time_minutes,
        anti_fatigue_enabled=anti_fatigue_enabled,
        is_challenge=is_challenge,
        challenge_title=challenge_title,
        challenge_category=challenge_category,
        challenge_bonus_xp=challenge_bonus_xp,
        review_mode=review_mode,
        evaluation_criteria=evaluation_criteria,
    )
    session.add(task)

    await metrics_service.update_on_task_created(session, student_id)

    await session.commit()
    result = await session.execute(
        select(Task)
        .options(
            selectinload(Task.reminder),
            selectinload(Task.submission),
        )
        .where(Task.id == task.id)
    )
    task = result.scalar_one()
    return TaskResponse.model_validate(task)

@router.get("/students/{student_id}/tasks", response_model=list[dict[str, Any]])
async def get_student_tasks(
    student_id: int,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> list[dict[str, Any]]:

    link_result = await session.execute(
        select(TeacherStudentLink).where(
            TeacherStudentLink.teacher_id == current_user.id,
            TeacherStudentLink.student_id == student_id,
            TeacherStudentLink.status == "active",
        )
    )
    if not link_result.scalar_one_or_none():
        raise HTTPException(status_code=403, detail="Student not linked to you")

    result = await session.execute(
        select(Task)
        .options(selectinload(Task.submission))
        .where(Task.owner_id == student_id)
        .order_by(Task.created_at.desc())
    )
    tasks = result.scalars().all()

    return [
        {
            "id": t.id,
            "title": t.title,
            "description": t.description,
            "status": t.status.value,
            "due_at": t.due_at,
            "requires_submission": t.requires_submission,
            "difficulty_level": t.difficulty_level,
            "estimated_time_minutes": t.estimated_time_minutes,
            "is_challenge": t.is_challenge,
            "challenge_title": t.challenge_title,
            "challenge_category": t.challenge_category,
            "challenge_bonus_xp": t.challenge_bonus_xp,
            "submission": TaskSubmissionResponse.model_validate(t.submission)
            if t.submission
            else None,
            "rescue_plan": insights_service.build_rescue_plan(t),
            "created_at": t.created_at,
        }
        for t in tasks
    ]


@router.post("/tasks/{task_id}/extend-deadline", response_model=TaskResponse)
async def extend_task_deadline(
    task_id: int,
    due_at: datetime,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> TaskResponse:
    result = await session.execute(
        select(Task)
        .options(selectinload(Task.reminder), selectinload(Task.submission))
        .where(Task.id == task_id, Task.assigned_by_teacher_id == current_user.id)
    )
    task = result.scalar_one_or_none()
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")

    task.due_at = due_at
    await session.commit()
    await session.refresh(task)
    return TaskResponse.model_validate(task)

@router.post("/submissions/{submission_id}/grade")
async def grade_submission(
    submission_id: int,
    payload: GradeSubmissionRequest,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> TaskSubmissionResponse:
    result = await session.execute(
        select(TaskSubmission)
        .where(TaskSubmission.id == submission_id)
        .options(selectinload(TaskSubmission.task), selectinload(TaskSubmission.student_user))
    )
    submission = result.scalar_one_or_none()

    if not submission:
        raise HTTPException(status_code=404, detail="Submission not found")

    task_result = await session.execute(
        select(Task).where(Task.id == submission.task_id)
    )
    task = task_result.scalar_one_or_none()

    if task.assigned_by_teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You did not assign this task")

    submission.grade = payload.grade
    submission.feedback = payload.feedback
    submission.is_graded = True
    submission.graded_at = _now()

    await session.commit()
    result = await session.execute(
        select(TaskSubmission)
        .where(TaskSubmission.id == submission.id)
        .options(selectinload(TaskSubmission.task), selectinload(TaskSubmission.student_user))
    )
    refreshed_submission = result.scalar_one()
    return _serialize_submission(refreshed_submission)


@router.post("/submissions/{submission_id}/assign-ai-next-task", response_model=TaskResponse)
async def assign_ai_next_task(
    submission_id: int,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> TaskResponse:
    result = await session.execute(
        select(TaskSubmission)
        .where(TaskSubmission.id == submission_id)
        .options(selectinload(TaskSubmission.task), selectinload(TaskSubmission.student_user))
    )
    submission = result.scalar_one_or_none()

    if not submission or submission.task is None or submission.student_user is None:
        raise HTTPException(status_code=404, detail="Submission not found")

    if submission.task.assigned_by_teacher_id != current_user.id:
        raise HTTPException(status_code=403, detail="You did not assign this task")

    next_task = _decode_json_object(submission.ai_next_task_json)
    if not next_task:
        raise HTTPException(status_code=400, detail="No AI next-task suggestion is available")

    task = Task(
        title=str(next_task.get("title", "")).strip()[:255],
        description=str(next_task.get("prompt", "")).strip()[:4000],
        owner_id=submission.student_id,
        assigned_by_teacher_id=current_user.id,
        requires_submission=True,
        difficulty_level=int(next_task.get("difficulty_level", 2)),
        estimated_time_minutes=next_task.get("estimated_time_minutes"),
        anti_fatigue_enabled=False,
        is_challenge=True,
        challenge_title="AI follow-up challenge",
        challenge_category="targeted_practice",
        challenge_bonus_xp=25,
        review_mode=TaskReviewMode.teacher_and_ai,
        evaluation_criteria=submission.task.evaluation_criteria,
    )
    session.add(task)

    await metrics_service.update_on_task_created(session, submission.student_id)
    await session.commit()

    result = await session.execute(
        select(Task)
        .options(selectinload(Task.reminder), selectinload(Task.submission))
        .where(Task.id == task.id)
    )
    created_task = result.scalar_one()
    return TaskResponse.model_validate(created_task)

@router.get("/submissions", response_model=list[TaskSubmissionResponse])
async def get_teacher_submissions(
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> list[TaskSubmissionResponse]:
    result = await session.execute(
        select(TeacherStudentLink)
        .where(
            TeacherStudentLink.teacher_id == current_user.id,
            TeacherStudentLink.status == "active",
        )
    )
    links = result.scalars().all()
    student_ids = [link.student_id for link in links]
    if not student_ids:
        return []
    result = await session.execute(
        select(TaskSubmission)
        .join(Task)
        .options(selectinload(TaskSubmission.task), selectinload(TaskSubmission.student_user))
        .where(
            TaskSubmission.student_id.in_(student_ids),
            Task.assigned_by_teacher_id == current_user.id,
        )
        .order_by(TaskSubmission.submitted_at.desc())
        .limit(50)
    )
    submissions = result.scalars().all()
    return [_serialize_submission(sub) for sub in submissions]

@router.get("/metrics", response_model=TeacherMetricsResponse)
async def get_teacher_metrics(
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> TeacherMetricsResponse:

    students_result = await session.execute(
        select(TeacherStudentLink).where(
            TeacherStudentLink.teacher_id == current_user.id,
            TeacherStudentLink.status == "active",
        )
    )
    students = students_result.scalars().all()
    total_students = len(students)

    tasks_result = await session.execute(
        select(Task)
        .options(selectinload(Task.submission))
        .where(Task.assigned_by_teacher_id == current_user.id)
    )
    tasks = tasks_result.scalars().all()
    total_assigned = len(tasks)

    total_submissions = 0
    pending_grading = 0
    total_grade = 0

    for task in tasks:
        if task.submission:
            total_submissions += 1
            if task.submission.is_graded:
                total_grade += task.submission.grade
            else:
                pending_grading += 1

    avg_grade = total_grade / total_submissions if total_submissions > 0 else 0.0

    return TeacherMetricsResponse(
        total_students=total_students,
        total_assigned_tasks=total_assigned,
        total_submissions=total_submissions,
        pending_grading=pending_grading,
        avg_grade=avg_grade,
    )
