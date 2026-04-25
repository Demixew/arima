
from __future__ import annotations

from datetime import datetime, timezone, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.models.metrics import DailyStats, ParentChildLink, UserMetrics
from backend.models.user import User, UserRole
from backend.models.task import Task, TaskStatus
from backend.schemas.metrics import (
    BadgeResponse,
    DailyChallengeResponse,
    GamificationProfileResponse,
    LinkedChildResponse,
    UserMetricsResponse,
)
from backend.services import insights_service

BADGE_DEFINITIONS = [
    {
        "id": "first_task",
        "title": "First Spark",
        "description": "Create your first task.",
        "icon": "bolt",
        "accent_color": "#F59E0B",
        "unlock": lambda metrics: metrics.total_tasks_created >= 1,
    },
    {
        "id": "first_finish",
        "title": "First Finish",
        "description": "Complete your first task.",
        "icon": "check_circle",
        "accent_color": "#10B981",
        "unlock": lambda metrics: metrics.total_tasks_completed >= 1,
    },
    {
        "id": "streak_3",
        "title": "Streak Starter",
        "description": "Reach a 3-day streak.",
        "icon": "local_fire_department",
        "accent_color": "#F97316",
        "unlock": lambda metrics: metrics.longest_streak >= 3,
    },
    {
        "id": "consistency_70",
        "title": "Consistency Keeper",
        "description": "Keep completion rate at 70% or more after 5 tasks.",
        "icon": "trending_up",
        "accent_color": "#3B82F6",
        "unlock": lambda metrics: metrics.total_tasks_created >= 5 and metrics.completion_rate >= 70,
    },
    {
        "id": "week_warrior",
        "title": "Week Warrior",
        "description": "Hold a 7-day streak.",
        "icon": "military_tech",
        "accent_color": "#8B5CF6",
        "unlock": lambda metrics: metrics.longest_streak >= 7,
    },
    {
        "id": "focus_hour",
        "title": "Focus Hour",
        "description": "Log 60 focus minutes.",
        "icon": "hourglass_bottom",
        "accent_color": "#06B6D4",
        "unlock": lambda metrics: metrics.total_focus_time_minutes >= 60,
    },
    {
        "id": "ten_done",
        "title": "Ten Down",
        "description": "Finish 10 tasks.",
        "icon": "workspace_premium",
        "accent_color": "#14B8A6",
        "unlock": lambda metrics: metrics.total_tasks_completed >= 10,
    },
    {
        "id": "twenty_five_done",
        "title": "Momentum Master",
        "description": "Finish 25 tasks.",
        "icon": "auto_awesome",
        "accent_color": "#EC4899",
        "unlock": lambda metrics: metrics.total_tasks_completed >= 25,
    },
]

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
    await record_daily_stat(session, user_id, tasks_created=1)

async def update_on_task_completed(
    session: AsyncSession,
    user_id: int,
    completed_at: datetime,
    focus_time_minutes: int = 0,
    bonus_xp: int = 0,
) -> None:
    metrics = await get_or_create_user_metrics(session, user_id)

    now = _now()
    previous_completed_at = metrics.last_completed_at
    metrics.total_tasks_completed += 1
    metrics.last_completed_at = completed_at
    metrics.last_activity_at = now

    if previous_completed_at:
        days_since_last = (completed_at.date() - previous_completed_at.date()).days
        if days_since_last == 1:
            metrics.current_streak += 1
        elif days_since_last == 0:
            metrics.current_streak = max(metrics.current_streak, 1)
        elif days_since_last > 1:
            metrics.current_streak = 1
    else:
        metrics.current_streak = 1

    if metrics.current_streak > metrics.longest_streak:
        metrics.longest_streak = metrics.current_streak

    metrics.total_focus_time_minutes += max(0, focus_time_minutes)
    metrics.bonus_xp += max(0, bonus_xp)
    await update_completion_rate(session, metrics)
    await record_daily_stat(
        session,
        user_id,
        tasks_completed=1,
        focus_time_minutes=max(0, focus_time_minutes),
    )

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
    else:
        metrics.completion_rate = 0
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


def _calculate_total_xp(metrics: UserMetrics) -> int:
    return (
        metrics.bonus_xp
        + metrics.total_tasks_created * 15
        + metrics.total_tasks_completed * 120
        + metrics.current_streak * 40
        + metrics.longest_streak * 20
        + metrics.total_focus_time_minutes * 2
        + metrics.completion_rate * 4
    )


def _level_progress(total_xp: int) -> tuple[int, int, int]:
    level = 1
    xp_into_level = total_xp
    next_level_xp = 120

    while xp_into_level >= next_level_xp:
        xp_into_level -= next_level_xp
        level += 1
        next_level_xp = int(next_level_xp * 1.35) + 40

    return level, xp_into_level, next_level_xp


def _rank_title(level: int) -> str:
    if level >= 12:
        return "Zenith Scholar"
    if level >= 9:
        return "Goal Guardian"
    if level >= 7:
        return "Focus Ranger"
    if level >= 5:
        return "Momentum Maker"
    if level >= 3:
        return "Pathfinder"
    return "Spark Starter"


def _build_badges(metrics: UserMetrics) -> tuple[list[BadgeResponse], str | None]:
    unlocked: list[BadgeResponse] = []
    next_hint: str | None = None

    for definition in BADGE_DEFINITIONS:
        is_unlocked = bool(definition["unlock"](metrics))
        if is_unlocked:
            unlocked.append(
                BadgeResponse(
                    id=definition["id"],
                    title=definition["title"],
                    description=definition["description"],
                    icon=definition["icon"],
                    accent_color=definition["accent_color"],
                )
            )
        elif next_hint is None:
            next_hint = definition["description"]

    return unlocked, next_hint


def _build_daily_challenges(today: DailyStats | None) -> list[DailyChallengeResponse]:
    created = today.tasks_created if today else 0
    completed = today.tasks_completed if today else 0

    return [
        DailyChallengeResponse(
            id="show_up",
            title="Show Up",
            description="Complete 1 task today.",
            current=completed,
            target=1,
            reward_xp=40,
            completed=completed >= 1,
        ),
        DailyChallengeResponse(
            id="double_win",
            title="Double Win",
            description="Complete 2 tasks today.",
            current=completed,
            target=2,
            reward_xp=75,
            completed=completed >= 2,
        ),
        DailyChallengeResponse(
            id="plan_ahead",
            title="Plan Ahead",
            description="Create 1 task today.",
            current=created,
            target=1,
            reward_xp=20,
            completed=created >= 1,
        ),
    ]


async def _get_today_daily_stat(
    session: AsyncSession,
    user_id: int,
) -> DailyStats | None:
    today = _now().replace(hour=0, minute=0, second=0, microsecond=0)
    result = await session.execute(
        select(DailyStats).where(
            DailyStats.user_id == user_id,
            DailyStats.date == today,
        )
    )
    return result.scalar_one_or_none()


async def build_gamification_profile(
    session: AsyncSession,
    user_id: int,
    metrics: UserMetrics,
) -> GamificationProfileResponse:
    total_xp = _calculate_total_xp(metrics)
    level, current_level_xp, next_level_xp = _level_progress(total_xp)
    unlocked_badges, next_hint = _build_badges(metrics)
    today = await _get_today_daily_stat(session, user_id)
    daily_challenges = _build_daily_challenges(today)
    energy = min(
        100,
        int(
            metrics.completion_rate * 0.55
            + min(metrics.current_streak, 10) * 4
            + min(metrics.total_tasks_completed, 20) * 1.5
        ),
    )

    return GamificationProfileResponse(
        total_xp=total_xp,
        level=level,
        rank_title=_rank_title(level),
        current_level_xp=current_level_xp,
        next_level_xp=next_level_xp,
        progress_percent=int((current_level_xp / next_level_xp) * 100) if next_level_xp else 0,
        energy=energy,
        next_unlock_hint=next_hint,
        unlocked_badges=unlocked_badges,
        daily_challenges=daily_challenges,
    )


async def build_user_metrics_response(
    session: AsyncSession,
    user_id: int,
    metrics: UserMetrics | None = None,
) -> UserMetricsResponse | None:
    if metrics is None:
        metrics = await get_user_metrics(session, user_id)
    if metrics is None:
        return None

    gamification = await build_gamification_profile(session, user_id, metrics)
    payload = UserMetricsResponse.model_validate(metrics).model_dump()
    payload["gamification"] = gamification
    return UserMetricsResponse(**payload)

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

        all_tasks_result = await session.execute(
            select(Task)
            .options(selectinload(Task.submission), selectinload(Task.reminder))
            .where(Task.owner_id == child_user.id)
            .order_by(Task.created_at.desc())
        )
        all_tasks = list(all_tasks_result.scalars().all())

        tasks_result = await session.execute(
            select(Task)
            .options(selectinload(Task.submission), selectinload(Task.reminder))
            .where(Task.owner_id == child_user.id)
            .order_by(Task.created_at.desc())
            .limit(5)
        )
        tasks = tasks_result.scalars().all()
        support = insights_service.build_parent_support_feed(
            child_name=child_user.full_name,
            tasks=all_tasks,
            metrics=metrics,
        )

        children.append(LinkedChildResponse(
            id=link.id,
            child_id=child_user.id,
            child_name=child_user.full_name,
            child_email=child_user.email,
            link_status=link.status,
            metrics=await build_user_metrics_response(session, child_user.id, metrics),
            recent_tasks=[
                {
                    "id": t.id,
                    "title": t.title,
                    "status": t.status.value,
                    "due_at": t.due_at,
                    "created_at": t.created_at,
                    "reminder": {
                        "escalated_to_parent": t.reminder.escalated_to_parent,
                        "parent_alert_message": t.reminder.parent_alert_message,
                    }
                    if t.reminder
                    else None,
                    "rescue_plan": insights_service.build_rescue_plan(t),
                }
                for t in tasks
            ],
            positive_signal=support["positive_signal"],
            attention_signal=support["attention_signal"],
            recommended_action=support["recommended_action"],
            support_summary=support["support_summary"],
            needs_attention=bool(support["attention_signal"]),
            weekly_narrative=insights_service.build_weekly_narrative(
                role="parent",
                person_name=child_user.full_name,
                tasks=all_tasks,
                metrics=metrics,
            ),
        ))

    return children

async def get_child_stats_summary(
    session: AsyncSession,
    child_id: int,
) -> dict[str, Any]:
    metrics = await get_user_metrics(session, child_id)

    tasks_result = await session.execute(
        select(Task)
        .options(selectinload(Task.submission), selectinload(Task.reminder))
        .where(Task.owner_id == child_id)
    )
    all_tasks = tasks_result.scalars().all()

    completed = sum(1 for t in all_tasks if t.status == TaskStatus.completed)
    overdue = sum(
        1 for t in all_tasks
        if t.status != TaskStatus.completed
        and t.due_at
        and t.due_at.replace(tzinfo=timezone.utc) < _now()
    )

    child_result = await session.execute(
        select(User).where(User.id == child_id, User.role == UserRole.student)
    )
    child = child_result.scalar_one_or_none()
    child_name = child.full_name if child else "Your child"
    support = insights_service.build_parent_support_feed(
        child_name=child_name,
        tasks=list(all_tasks),
        metrics=metrics,
    )

    return {
        "total_tasks": len(all_tasks),
        "completed_tasks": completed,
        "overdue_tasks": overdue,
        "current_streak": metrics.current_streak if metrics else 0,
        "completion_rate": metrics.completion_rate if metrics else 0,
        "last_activity": metrics.last_activity_at if metrics else None,
        "gamification": await build_gamification_profile(session, child_id, metrics)
        if metrics
        else None,
        "positive_signal": support["positive_signal"],
        "attention_signal": support["attention_signal"],
        "recommended_action": support["recommended_action"],
        "support_summary": support["support_summary"],
        "weekly_narrative": insights_service.build_weekly_narrative(
            role="parent",
            person_name=child_name,
            tasks=list(all_tasks),
            metrics=metrics,
        ),
    }
