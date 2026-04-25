
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from backend.models.reminder import TaskReminder
from backend.models.task import Task, TaskStatus
from backend.services.reminder_service import compute_next_reminder_at, process_due_reminder

def test_compute_next_reminder_prefers_future_due_date() -> None:
    now = datetime.now(timezone.utc)
    due_at = now + timedelta(hours=4)

    next_reminder = compute_next_reminder_at(
        due_at=due_at,
        remind_after_hours=6,
        reference_time=now,
    )

    assert next_reminder == due_at

def test_due_reminder_escalates_after_max_misses() -> None:
    task = Task(
        id=1,
        title="Complete science project",
        status=TaskStatus.pending,
        owner_id=1,
    )
    reminder = TaskReminder(
        task_id=1,
        is_enabled=True,
        remind_after_hours=4,
        max_missed_count=2,
        missed_count=1,
        last_reminded_at=datetime.now(timezone.utc) - timedelta(minutes=5),
    )

    process_due_reminder(task, reminder, datetime.now(timezone.utc))

    assert reminder.missed_count == 2
    assert reminder.escalated_to_parent is True
    assert reminder.parent_alert_message is not None
