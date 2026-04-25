
from __future__ import annotations

from datetime import datetime, timezone
from http import HTTPStatus

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import Select, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.api.auth import get_current_user
from backend.core.db import get_db_session
from backend.models.task import Task, TaskStatus
from backend.models.user import UserRole
from backend.models.user import User
from backend.schemas.task import (
    StudyPlanResponse,
    TaskCreateRequest,
    TaskResponse,
    TaskUpdateRequest,
)
from backend.services import metrics_service
from backend.services import insights_service
from backend.services.reminder_service import sync_reminder_with_task, upsert_task_reminder

router = APIRouter(prefix="/tasks", tags=["tasks"])

async def _get_owned_task(
    task_id: int,
    current_user: User,
    session: AsyncSession,
) -> Task:
    statement: Select[tuple[Task]] = select(Task).where(
        Task.id == task_id,
        Task.owner_id == current_user.id,
    ).options(selectinload(Task.reminder), selectinload(Task.submission))
    task = (await session.execute(statement)).scalar_one_or_none()
    if task is None:
        raise HTTPException(
            status_code=HTTPStatus.NOT_FOUND,
            detail="Task not found",
        )
    return task

async def _serialize_owned_task(
    *,
    task_id: int,
    current_user: User,
    session: AsyncSession,
) -> TaskResponse:
    task = await _get_owned_task(task_id=task_id, current_user=current_user, session=session)
    payload = TaskResponse.model_validate(task).model_dump()
    payload["rescue_plan"] = insights_service.build_rescue_plan(task)
    return TaskResponse(**payload)

@router.get(
    "",
    response_model=list[TaskResponse],
    status_code=HTTPStatus.OK,
)
async def list_tasks(
    session: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> list[TaskResponse]:
    statement: Select[tuple[Task]] = (
        select(Task)
        .options(selectinload(Task.reminder), selectinload(Task.submission))
        .where(Task.owner_id == current_user.id)
        .order_by(Task.created_at.desc())
    )
    tasks = (await session.execute(statement)).scalars().all()
    responses: list[TaskResponse] = []
    for task in tasks:
        payload = TaskResponse.model_validate(task).model_dump()
        payload["rescue_plan"] = insights_service.build_rescue_plan(task)
        responses.append(TaskResponse(**payload))
    return responses


@router.get(
    "/study-plan",
    response_model=StudyPlanResponse,
    status_code=HTTPStatus.OK,
)
async def get_study_plan(
    session: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> StudyPlanResponse:
    if current_user.role != UserRole.student:
        raise HTTPException(status_code=403, detail="Only students can view study plans")

    statement: Select[tuple[Task]] = (
        select(Task)
        .options(selectinload(Task.reminder), selectinload(Task.submission))
        .where(Task.owner_id == current_user.id)
        .order_by(Task.created_at.desc())
    )
    tasks = list((await session.execute(statement)).scalars().all())
    metrics = await metrics_service.get_user_metrics(session, current_user.id)
    payload = insights_service.build_study_plan(tasks=tasks, metrics=metrics)
    payload["weekly_narrative"] = insights_service.build_weekly_narrative(
        role="student",
        person_name=current_user.full_name,
        tasks=tasks,
        metrics=metrics,
    )
    return StudyPlanResponse(**payload)

@router.post(
    "",
    response_model=TaskResponse,
    status_code=HTTPStatus.CREATED,
)
async def create_task(
    payload: TaskCreateRequest,
    session: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> TaskResponse:
    task = Task(
        title=payload.title,
        description=payload.description,
        status=payload.status,
        due_at=payload.due_at,
        owner_id=current_user.id,
        assigned_by_teacher_id=payload.assigned_to_student_id,
        requires_submission=payload.requires_submission,
        difficulty_level=payload.difficulty_level,
        estimated_time_minutes=payload.estimated_time_minutes,
        anti_fatigue_enabled=payload.anti_fatigue_enabled,
        is_challenge=payload.is_challenge,
        challenge_title=payload.challenge_title,
        challenge_category=payload.challenge_category,
        challenge_bonus_xp=payload.challenge_bonus_xp,
        review_mode=payload.review_mode,
        evaluation_criteria=payload.evaluation_criteria,
    )
    session.add(task)
    await session.flush()

    await metrics_service.update_on_task_created(session, current_user.id)

    if payload.reminder is not None:
        await upsert_task_reminder(
            session=session,
            task=task,
            reminder_payload=payload.reminder,
        )

    await session.commit()
    await session.refresh(task)

    return await _serialize_owned_task(task_id=task.id, current_user=current_user, session=session)

@router.get(
    "/{task_id}",
    response_model=TaskResponse,
    status_code=HTTPStatus.OK,
)
async def get_task(
    task_id: int,
    session: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> TaskResponse:
    return await _serialize_owned_task(task_id=task_id, current_user=current_user, session=session)

@router.put(
    "/{task_id}",
    response_model=TaskResponse,
    status_code=HTTPStatus.OK,
)
async def update_task(
    task_id: int,
    payload: TaskUpdateRequest,
    session: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> TaskResponse:
    task = await _get_owned_task(task_id=task_id, current_user=current_user, session=session)

    was_completed = task.status == TaskStatus.completed

    update_data = payload.model_dump(exclude_unset=True, exclude={"reminder"})
    for field_name, value in update_data.items():
        setattr(task, field_name, value)

    if payload.reminder is not None:
        await upsert_task_reminder(
            session=session,
            task=task,
            reminder_payload=payload.reminder,
        )
    elif task.reminder is not None:
        sync_reminder_with_task(task, task.reminder)
        await session.flush()

    if not was_completed and task.status == TaskStatus.completed:
        await metrics_service.update_on_task_completed(
            session,
            current_user.id,
            datetime.now(timezone.utc),
            focus_time_minutes=task.estimated_time_minutes or 15,
            bonus_xp=task.challenge_bonus_xp if task.is_challenge else 0,
        )

    await session.commit()
    await session.refresh(task)
    return await _serialize_owned_task(task_id=task.id, current_user=current_user, session=session)

@router.delete(
    "/{task_id}",
    status_code=HTTPStatus.NO_CONTENT,
)
async def delete_task(
    task_id: int,
    session: AsyncSession = Depends(get_db_session),
    current_user: User = Depends(get_current_user),
) -> Response:
    task = await _get_owned_task(task_id=task_id, current_user=current_user, session=session)

    await metrics_service.update_on_task_deleted(session, current_user.id)

    await session.delete(task)
    await session.commit()
    return Response(status_code=HTTPStatus.NO_CONTENT)
