
from __future__ import annotations

from apscheduler.schedulers.asyncio import AsyncIOScheduler

from backend.services.reminder_service import run_reminder_tick_job

def build_scheduler() -> AsyncIOScheduler:
    scheduler = AsyncIOScheduler()
    scheduler.add_job(
        run_reminder_tick_job,
        trigger="interval",
        minutes=15,
        id="task-reminder-tick",
        replace_existing=True,
    )
    return scheduler
