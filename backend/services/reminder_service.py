
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from backend.models.reminder import TaskReminder
from backend.models.task import Task, TaskStatus
from backend.schemas.reminder import TaskReminderUpsert

def _now() -> datetime:
    return datetime.now(timezone.utc)

def _normalize(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt

def compute_next_reminder_at(
    due_at: datetime | None,
    remind_after_hours: int,
    reference_time: datetime,
) -> datetime:
    if due_at is not None and _normalize(due_at) > _normalize(reference_time):
        return _normalize(due_at)
    return _normalize(reference_time) + timedelta(hours=remind_after_hours)

def process_due_reminder(task: Task, reminder: TaskReminder, now: datetime) -> None:
    reminder.missed_count += 1
    reminder.last_reminded_at = now

    if reminder.missed_count >= reminder.max_missed_count:
        reminder.escalated_to_parent = True
        reminder.parent_alert_message = (
            f"Task '{task.title}' has been missed {reminder.missed_count} times. "
            f"Immediate attention required."
        )

async def upsert_task_reminder(
    session: AsyncSession,
    task: Task,
    reminder_payload: TaskReminderUpsert,
) -> TaskReminder:

    statement = select(TaskReminder).where(TaskReminder.task_id == task.id)
    reminder = (await session.execute(statement)).scalar_one_or_none()

    if reminder is None:
        reminder = TaskReminder(task_id=task.id)
        session.add(reminder)

    update_data = reminder_payload.model_dump()
    for field, value in update_data.items():
        setattr(reminder, field, value)

    if reminder_payload.is_enabled:
        reminder.missed_count = 0
        reminder.last_reminded_at = None

    await session.flush()
    await session.refresh(reminder)
    return reminder

def sync_reminder_with_task(task: Task, reminder: TaskReminder) -> None:

    if task.status == TaskStatus.completed:
        reminder.is_enabled = False
        reminder.escalated_to_parent = False
        reminder.parent_alert_message = None

async def run_reminder_tick_job() -> None:
    from backend.core.db import AsyncSessionLocal

    async with AsyncSessionLocal() as session:
        now = _now()

        statement = (
            select(Task)
            .join(TaskReminder)
            .options(selectinload(Task.reminder))
            .where(
                and_(
                    Task.status != TaskStatus.completed,
                    TaskReminder.is_enabled == True,
                )
            )
        )
        result = await session.execute(statement)
        tasks = result.scalars().all()

        for task in tasks:
            reminder = task.reminder
            if reminder is None:
                continue

            last_reminded = reminder.last_reminded_at
            if last_reminded is None:
                last_reminded = task.created_at

            next_reminder = _normalize(last_reminded) + timedelta(hours=reminder.remind_after_hours)

            if now >= next_reminder:

                reminder.missed_count += 1
                reminder.last_reminded_at = now

                if reminder.missed_count >= reminder.max_missed_count:
                    reminder.escalated_to_parent = True
                    reminder.parent_alert_message = (
                        f"Task '{task.title}' has been missed {reminder.missed_count} times. "
                        f"Immediate attention required."
                    )
                else:

                    reminder.escalated_to_parent = False
                    reminder.parent_alert_message = None

        await session.commit()
