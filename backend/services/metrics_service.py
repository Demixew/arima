
from __future__ import annotations

from datetime import datetime, timezone, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.models.metrics import DailyStats, ParentChildLink, UserMetrics
from backend.models.user import User, UserRole
from backend.models.task import Task, TaskStatus
from backend.schemas.metrics import LinkedChildResponse, UserMetricsResponse

def _now() -> datetime:
    return datetime.now(timezone.utc)

async def get_or_create_user_metrics(
    session: AsyncSession, user_id: int
) -> UserMetrics:
    result = await session.execute(
        select(UserMetrics).where(UserMetrics.user_id == user_id)
    )
    metrics = result.scalar_one_or_none()

    if metrics is None:
        metrics = UserMetrics(user_id=user_id)
        session.add(metrics)
        await session.flush()

    return metrics

async def update_on_task_created(
    session: AsyncSession, user_id: int
) -> None:
    metrics = await get_or_create_user_metrics(session, user_id)
    metrics.total_tasks_created += 1
    metrics.last_activity_at = _now()
    await update_completion_rate(session, metrics)

async def update_on_task_completed(
    session: AsyncSession, user_id: int, completed_at: datetime
) -> None:
    metrics = await get_or_create_user_metrics(session, user_id)

    now = _now()
    metrics.total_tasks_completed += 1
    metrics.last_completed_at = completed_at
    metrics.last_activity_at = now

    if metrics.last_completed_at:
        days_since_last = (now.date() - metrics.last_completed_at.date()).days
        if days_since_last == 1:
            metrics.current_streak += 1
        elif days_since_last > 1:
            metrics.current_streak = 1

        if metrics.current_streak > metrics.longest_streak:
            metrics.longest_streak = metrics.current_streak

    await update_completion_rate(session, metrics)
    await record_daily_stat(session, user_id, tasks_completed=1)

async def update_on_task_deleted(
    session: AsyncSession, user_id: int
) -> None:
    metrics = await get_or_create_user_metrics(session, user_id)
    if metrics.total_tasks_created > 0:
        metrics.total_tasks_created -= 1
    await update_completion_rate(session, metrics)

async def update_completion_rate(
    session: AsyncSession, metrics: UserMetrics
) -> None:
    if metrics.total_tasks_created > 0:
        metrics.completion_rate = int(
            (metrics.total_tasks_completed / metrics.total_tasks_created) * 100
        )
    await session.flush()

async def record_daily_stat(
    session: AsyncSession,
    user_id: int,
    tasks_created: int = 0,
    tasks_completed: int = 0,
    focus_time_minutes: int = 0,
) -> None:
    today = _now().replace(hour=0, minute=0, second=0, microsecond=0)

    result = await session.execute(
        select(DailyStats).where(
            DailyStats.user_id == user_id,
            DailyStats.date == today,
        )
    )
    daily = result.scalar_one_or_none()

    if daily:
        daily.tasks_created += tasks_created
        daily.tasks_completed += tasks_completed
        daily.focus_time_minutes += focus_time_minutes
    else:
        daily = DailyStats(
            user_id=user_id,
            date=today,
            tasks_created=tasks_created,
            tasks_completed=tasks_completed,
            focus_time_minutes=focus_time_minutes,
        )
        session.add(daily)

    await session.flush()

async def get_user_metrics(
    session: AsyncSession, user_id: int
) -> UserMetrics | None:
    result = await session.execute(
        select(UserMetrics).where(UserMetrics.user_id == user_id)
    )
    return result.scalar_one_or_none()

async def get_daily_stats(
    session: AsyncSession,
    user_id: int,
    days: int = 7,
) -> list[DailyStats]:
    start_date = _now() - timedelta(days=days)

    result = await session.execute(
        select(DailyStats)
        .where(
            DailyStats.user_id == user_id,
            DailyStats.date >= start_date,
        )
        .order_by(DailyStats.date.desc())
    )
    return list(result.scalars().all())

async def link_child_to_parent(
    session: AsyncSession,
    parent_id: int,
    child_email: str,
) -> ParentChildLink:

    result = await session.execute(
        select(User).where(
            User.email == child_email,
            User.role == UserRole.student,
        )
    )
    child = result.scalar_one_or_none()

    if not child:
        raise ValueError(f"No student found with email: {child_email}")

    if child.id == parent_id:
        raise ValueError("Cannot link to yourself")

    existing = await session.execute(
        select(ParentChildLink).where(
            ParentChildLink.parent_id == parent_id,
            ParentChildLink.child_id == child.id,
        )
    )
    if existing.scalar_one_or_none():
        raise ValueError("Already linked to this user")

    link = ParentChildLink(parent_id=parent_id, child_id=child.id)
    session.add(link)
    await session.flush()
    return link

async def unlink_child(
    session: AsyncSession,
    parent_id: int,
    child_id: int,
) -> None:
    result = await session.execute(
        select(ParentChildLink).where(
            ParentChildLink.parent_id == parent_id,
            ParentChildLink.child_id == child_id,
            ParentChildLink.status == "active",
        )
    )
    link = result.scalar_one_or_none()
    if link:
        link.status = "inactive"
        await session.flush()

async def get_linked_children(
    session: AsyncSession,
    parent_id: int,
) -> list[LinkedChildResponse]:
    result = await session.execute(
        select(ParentChildLink)
        .where(
            ParentChildLink.parent_id == parent_id,
            ParentChildLink.status == "active",
        )
        .options(selectinload(ParentChildLink.child))
    )
    links = result.scalars().all()

    children: list[LinkedChildResponse] = []
    for link in links:
        child_user = link.child

        metrics = await get_user_metrics(session, child_user.id)

        tasks_result = await session.execute(
            select(Task)
            .where(Task.owner_id == child_user.id)
            .order_by(Task.created_at.desc())
            .limit(5)
        )
        tasks = tasks_result.scalars().all()

        children.append(LinkedChildResponse(
            id=link.id,
            child_id=child_user.id,
            child_name=child_user.full_name,
            child_email=child_user.email,
            link_status=link.status,
            metrics=UserMetricsResponse.model_validate(metrics) if metrics else None,
            recent_tasks=[
                {
                    "id": t.id,
                    "title": t.title,
                    "status": t.status.value,
                    "due_at": t.due_at,
                    "created_at": t.created_at,
                }
                for t in tasks
            ],
        ))

    return children

async def get_child_stats_summary(
    session: AsyncSession,
    child_id: int,
) -> dict[str, Any]:
    metrics = await get_user_metrics(session, child_id)

    tasks_result = await session.execute(
        select(Task).where(Task.owner_id == child_id)
    )
    all_tasks = tasks_result.scalars().all()

    completed = sum(1 for t in all_tasks if t.status == TaskStatus.completed)
    overdue = sum(
        1 for t in all_tasks
        if t.status != TaskStatus.completed
        and t.due_at
        and t.due_at.replace(tzinfo=timezone.utc) < _now()
    )

    return {
        "total_tasks": len(all_tasks),
        "completed_tasks": completed,
        "overdue_tasks": overdue,
        "current_streak": metrics.current_streak if metrics else 0,
        "completion_rate": metrics.completion_rate if metrics else 0,
        "last_activity": metrics.last_activity_at if metrics else None,
    }
