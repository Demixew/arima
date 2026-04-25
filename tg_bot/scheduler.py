from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone
from typing import Any

from aiogram import Bot

from tg_bot.client import get_client

logger = logging.getLogger(__name__)

# user_id -> {skip_count, last_notified_task_ids}
_overdue_tracker: dict[int, dict[str, Any]] = {}


def _format_overdue_task(t: dict, index: int) -> str:
    """Format a single overdue task for notification."""
    title = t.get("title", "Без названия")
    due = t.get("due_at")
    due_str = ""
    if due:
        try:
            dt = datetime.fromisoformat(due.replace("Z", "+00:00"))
            now = datetime.now(timezone.utc)
            overdue_hours = int((now - dt).total_seconds() // 3600)
            overdue_days = overdue_hours // 24
            if overdue_days > 0:
                due_str = f" (просрочено {overdue_days}д {overdue_hours % 24}ч)"
            else:
                due_str = f" (просрочено {overdue_hours}ч)"
        except Exception:
            pass

    diff = t.get("difficulty_level", 2)
    diff_dots = "🔴" * diff + "⚪" * (5 - diff)

    return f"  {index}. 🔴 *{title}*{due_str}\n     Сложность: {diff_dots}"


async def check_overdue_loop(bot: Bot, interval_sec: int = 300) -> None:
    """Background loop: every N seconds check all active users for overdue tasks."""
    logger.info("Overdue checker started with interval %ss", interval_sec)
    while True:
        try:
            await asyncio.sleep(interval_sec)
            await _run_check(bot)
        except Exception:
            logger.exception("Error in overdue checker loop")


async def _run_check(bot: Bot) -> None:
    from tg_bot.main import _user_sessions  # avoid circular import

    sessions = dict(_user_sessions)
    if not sessions:
        return

    for user_id, session in sessions.items():
        token = session.get("token")
        chat_id = session.get("chat_id")
        if not token or not chat_id:
            continue

        ok, tasks = await get_client().list_tasks(token)
        if not ok:
            logger.warning("Scheduler: failed to fetch tasks for user %s", user_id)
            continue

        overdue_tasks = []
        for t in tasks:
            status = t.get("status", "")
            due = t.get("due_at")
            if status == "overdue":
                overdue_tasks.append(t)
                continue
            if due:
                try:
                    dt = datetime.fromisoformat(due.replace("Z", "+00:00"))
                    if dt < datetime.now(timezone.utc):
                        overdue_tasks.append(t)
                except Exception:
                    pass

        if not overdue_tasks:
            _overdue_tracker.pop(user_id, None)
            continue

        tracker = _overdue_tracker.setdefault(user_id, {"skip_count": 0, "notified_ids": set()})
        current_ids = {t["id"] for t in overdue_tasks}
        new_ids = current_ids - tracker["notified_ids"]

        if new_ids:
            tracker["notified_ids"].update(new_ids)
            tracker["skip_count"] = 0

            # Build pretty notification
            new_tasks = [t for t in overdue_tasks if t["id"] in new_ids]
            task_lines = [_format_overdue_task(t, i + 1) for i, t in enumerate(new_tasks)]
            tasks_text = "\n\n".join(task_lines)

            header = (
                f"🔴 *ВНИМАНИЕ: Просроченные задачи!*\n"
                f"{'━' * 20}\n\n"
            )
            footer = (
                f"\n{'━' * 20}\n"
                f"💡 *Совет:* Начни с самой простой задачи, чтобы войти в ритм.\n"
                f"Отметь выполненные через меню ✅"
            )

            message_text = f"{header}{tasks_text}{footer}"

            try:
                await bot.send_message(
                    chat_id=chat_id,
                    text=message_text,
                    parse_mode="Markdown",
                )
                logger.info("Sent overdue notification to user %s", user_id)
            except Exception as exc:
                logger.warning("Failed to send overdue notification to %s: %s", user_id, exc)
        else:
            tracker["skip_count"] += 1
            if tracker["skip_count"] >= 3:
                # Escalation warning
                total_overdue = len(overdue_tasks)
                escalation_text = (
                    f"⚠️ *ЭСКАЛАЦИЯ*\n"
                    f"{'━' * 20}\n\n"
                    f"У тебя всё ещё *{total_overdue}* просроченных задач!\n\n"
                    f"🔥 Это влияет на твою серию и прогресс.\n"
                    f"🎯 Рекомендую разобрать их как можно скорее!\n\n"
                    f"{'━' * 20}\n"
                    f"Нажми 📋 *Мои задачи* → 🔴 *Просрочено* для списка"
                )
                try:
                    await bot.send_message(
                        chat_id=chat_id,
                        text=escalation_text,
                        parse_mode="Markdown",
                    )
                    logger.info("Sent escalation warning to user %s", user_id)
                except Exception as exc:
                    logger.warning("Failed to send escalation to %s: %s", user_id, exc)
                tracker["skip_count"] = 0


def register_user_session(user_id: int, chat_id: int, token: str) -> None:
    from tg_bot.main import _user_sessions
    _user_sessions[user_id] = {"chat_id": chat_id, "token": token}


def remove_user_session(user_id: int) -> None:
    from tg_bot.main import _user_sessions
    _user_sessions.pop(user_id, None)
    _overdue_tracker.pop(user_id, None)

