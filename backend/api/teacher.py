
from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.core.db import get_db_session
from backend.api.auth import get_current_user
from backend.models.task import Task
from backend.models.user import User, UserRole
from backend.models.metrics import TaskSubmission, TeacherStudentLink, UserMetrics
from backend.schemas.teacher import (
    GradeSubmissionRequest,
    LinkedStudentResponse,
    TaskSubmissionResponse,
    TaskSubmissionUpsert,
    TeacherMetricsResponse,
)
from backend.schemas.task import TaskResponse
from backend.services import metrics_service

router = APIRouter(prefix="/teacher", tags=["teacher"])

def _now() -> datetime:
    return datetime.now(timezone.utc)

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
    else:

        submission = TaskSubmission(
            task_id=task_id,
            student_id=current_user.id,
            submission_text=payload.submission_text,
            image_url=payload.image_url,
        )
        session.add(submission)

    await session.commit()
    await session.refresh(submission)
    return TaskSubmissionResponse.model_validate(submission)

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
            "submission": TaskSubmissionResponse.model_validate(t.submission)
            if t.submission
            else None,
            "created_at": t.created_at,
        }
        for t in tasks
    ]

@router.post("/submissions/{submission_id}/grade")
async def grade_submission(
    submission_id: int,
    payload: GradeSubmissionRequest,
    current_user: User = Depends(_get_teacher_user),
    session: AsyncSession = Depends(get_db_session),
) -> TaskSubmissionResponse:
    result = await session.execute(
        select(TaskSubmission).where(TaskSubmission.id == submission_id)
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
    await session.refresh(submission)
    return TaskSubmissionResponse.model_validate(submission)

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
        .where(
            TaskSubmission.student_id.in_(student_ids),
            TaskSubmission.is_graded == False,
            Task.assigned_by_teacher_id == current_user.id,
        )
    )
    submissions = result.scalars().all()
    return [TaskSubmissionResponse.model_validate(sub) for sub in submissions]

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
