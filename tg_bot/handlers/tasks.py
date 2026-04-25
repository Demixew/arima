from __future__ import annotations

import logging
import re
from datetime import datetime, timedelta, timezone
from typing import Any

from aiogram import F, Router
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import CallbackQuery, Message

from tg_bot.client import get_client
from tg_bot.keyboards import (
    confirm_cancel_kb,
    main_menu_kb,
    retry_back_kb,
    task_detail_kb,
    task_filter_kb,
    tasks_list_kb,
)

logger = logging.getLogger(__name__)
router = Router()


class TaskCreateStates(StatesGroup):
    enter_text = State()
    confirm = State()


class TaskCompleteStates(StatesGroup):
    choose_task = State()


def _parse_task_text(text: str) -> dict[str, Any]:
    lines = [line.strip() for line in text.strip().splitlines() if line.strip()]
    title = lines[0][:255] if lines else "Новое задание"
    description = "\n".join(lines[1:])[:4000] if len(lines) > 1 else None

    due_at = None
    date_patterns = [
        r"(\d{1,2}[./]\d{1,2}(?:[./]\d{2,4})?)",
        r"(завтра|послезавтра|сегодня)",
        r"(\d{1,2}\s+(?:январ|феврал|март|апрел|ма|июн|июл|август|сентябр|октябр|ноябр|декабр)[ая]\s*\d{0,4})",
    ]
    for pat in date_patterns:
        match = re.search(pat, text, re.IGNORECASE)
        if match:
            raw = match.group(1).lower()
            now = datetime.now(timezone.utc)
            if raw == "сегодня":
                due_at = now.replace(hour=23, minute=59, second=0, microsecond=0)
            elif raw == "завтра":
                due_at = (now + timedelta(days=1)).replace(hour=23, minute=59, second=0, microsecond=0)
            elif raw == "послезавтра":
                due_at = (now + timedelta(days=2)).replace(hour=23, minute=59, second=0, microsecond=0)
            else:
                try:
                    if "." in raw:
                        parts = raw.split(".")
                        day, month = int(parts[0]), int(parts[1])
                        year = now.year
                        if len(parts) > 2 and parts[2]:
                            y = int(parts[2])
                            year = y if y > 2000 else 2000 + y
                        due_at = datetime(year, month, day, 23, 59, tzinfo=timezone.utc)
                    elif "/" in raw:
                        parts = raw.split("/")
                        day, month = int(parts[0]), int(parts[1])
                        year = now.year
                        if len(parts) > 2 and parts[2]:
                            y = int(parts[2])
                            year = y if y > 2000 else 2000 + y
                        due_at = datetime(year, month, day, 23, 59, tzinfo=timezone.utc)
                except Exception:
                    due_at = None
            break

    return {
        "title": title,
        "description": description,
        "status": "pending",
        "due_at": due_at.isoformat() if due_at else None,
        "difficulty_level": 2,
        "estimated_time_minutes": None,
    }


def _difficulty_bar(level: int) -> str:
    filled = "🔴" * level
    empty = "⚪" * (5 - level)
    return f"{filled}{empty} ({level}/5)"


def _format_task(t: dict) -> str:
    status = t.get("status", "pending")
    icons = {"pending": "⏳", "in_progress": "🔄", "completed": "✅", "overdue": "🔴"}
    icon = icons.get(status, "📌")
    title = t.get("title", "Без названия")
    desc = t.get("description") or ""
    due = t.get("due_at")
    due_str = ""
    if due:
        try:
            dt = datetime.fromisoformat(due.replace("Z", "+00:00"))
            now = datetime.now(timezone.utc)
            delta = dt - now
            if delta.total_seconds() < 0:
                overdue_hours = abs(int(delta.total_seconds() // 3600))
                due_str = f"\n📅 Дедлайн: *{dt.strftime('%d.%m.%Y %H:%M')}* 🔴 Просрочено на {overdue_hours}ч"
            elif delta.days == 0:
                due_str = f"\n📅 Дедлайн: *{dt.strftime('%d.%m.%Y %H:%M')}* ⚡ Сегодня!"
            else:
                due_str = f"\n📅 Дедлайн: *{dt.strftime('%d.%m.%Y %H:%M')}* (через {delta.days}д)"
        except Exception:
            due_str = f"\n📅 Дедлайн: {due}"

    diff = t.get("difficulty_level", 2)
    diff_bar = _difficulty_bar(diff)
    time_est = t.get("estimated_time_minutes")
    time_str = f"\n⏱ Оценка времени: *{time_est} мин*" if time_est else ""

    challenge_str = ""
    if t.get("is_challenge"):
        bonus = t.get("challenge_bonus_xp", 0)
        cat = t.get("challenge_category", "")
        challenge_str = f"\n🏆 Челлендж: *+{bonus} XP*"
        if cat:
            challenge_str += f" ({cat})"

    rescue_str = ""
    rescue = t.get("rescue_plan")
    if rescue and status in ("overdue",):
        steps = rescue.get("mini_steps", [])
        new_time = rescue.get("recommended_new_time_block")
        tone = rescue.get("difficulty_tone")
        if steps or new_time or tone:
            rescue_str = "\n\n🛟 *План спасения:*\n"
            if tone:
                rescue_str += f"💡 Уровень: {tone}\n"
            if new_time:
                rescue_str += f"⏰ Рекомендуемое время: {new_time}\n"
            if steps:
                rescue_str += "📋 Шаги:\n"
                for i, step in enumerate(steps, 1):
                    rescue_str += f"   {i}. {step}\n"

    submission = t.get("submission")
    submission_str = ""
    if submission:
        grade = submission.get("grade")
        is_graded = submission.get("is_graded", False)
        if is_graded and grade is not None:
            submission_str = f"\n📝 Оценка: *{grade}/100*"
        elif submission.get("submission_text"):
            submission_str = "\n📝 Ответ отправлен на проверку"

    header = f"{'━' * 20}\n{icon} *{title}*\n{'━' * 20}"
    body = f"\n{desc}" if desc else ""
    footer = f"{due_str}{time_str}\n📊 Сложность: {diff_bar}{challenge_str}{submission_str}{rescue_str}"

    return f"{header}{body}\n{footer}"


def _is_overdue(t: dict) -> bool:
    status = t.get("status", "")
    due = t.get("due_at")
    if status == "overdue":
        return True
    if due:
        try:
            dt = datetime.fromisoformat(due.replace("Z", "+00:00"))
            return dt < datetime.now(timezone.utc)
        except Exception:
            pass
    return False


def _is_today(t: dict) -> bool:
    due = t.get("due_at")
    if not due:
        return False
    try:
        dt = datetime.fromisoformat(due.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        return dt.date() == now.date()
    except Exception:
        return False


def _is_soon(t: dict) -> bool:
    due = t.get("due_at")
    if not due:
        return False
    try:
        dt = datetime.fromisoformat(due.replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        return now < dt <= now + timedelta(days=3)
    except Exception:
        return False


@router.callback_query(F.data == "menu:tasks")
async def menu_tasks(callback: CallbackQuery, state: FSMContext) -> None:
    await callback.message.edit_text( 
        "📋 *Мои задачи*\n\n"
        "Выбери фильтр:\n"
        "📅 Сегодня — задачи на сегодня\n"
        "⏳ Скоро — ближайшие 3 дня\n"
        "🔴 Просрочено — требуют внимания\n"
        "📋 Все — полный список",
        parse_mode="Markdown",
        reply_markup=task_filter_kb(),
    )
    await callback.answer()


@router.callback_query(F.data.startswith("filter:"))
async def filter_tasks(callback: CallbackQuery, state: FSMContext) -> None:
    filt = callback.data.split(":")[1] 
    data = await state.get_data()
    token = data.get("token")
    if not token:
        await callback.message.edit_text(  
            "❌ *Требуется авторизация*\n\n"
            "Сначала войди через /start",
            parse_mode="Markdown",
        )
        await callback.answer()
        return

    ok, tasks = await get_client().list_tasks(token)
    if not ok:
        detail = tasks.get("detail", "Ошибка загрузки задач")
        await callback.message.edit_text(  
            f"⚠️ *{detail}*",
            parse_mode="Markdown",
            reply_markup=retry_back_kb(f"filter:{filt}"),
        )
        await callback.answer()
        return

    if not tasks:
        await callback.message.edit_text(  
            "📭 *Задачи не найдены*\n\n"
            "Создай первое задание через меню! ➕",
            parse_mode="Markdown",
            reply_markup=main_menu_kb(data.get("role", "student")),
        )
        await callback.answer()
        return

    filter_names = {
        "overdue": "🔴 Просроченные",
        "today": "📅 На сегодня",
        "soon": "⏳ Скоро",
        "all": "📋 Все задачи",
    }

    if filt == "overdue":
        filtered = [t for t in tasks if _is_overdue(t)]
    elif filt == "today":
        filtered = [t for t in tasks if _is_today(t)]
    elif filt == "soon":
        filtered = [t for t in tasks if _is_soon(t)]
    else:
        filtered = tasks

    if not filtered:
        await callback.message.edit_text( 
            f"📭 *{filter_names.get(filt, filt)}*\n\n"
            "По выбранному фильтру задач нет. Всё сделано! 🎉",
            parse_mode="Markdown",
            reply_markup=main_menu_kb(data.get("role", "student")),
        )
        await callback.answer()
        return

    total = len(tasks)
    completed = sum(1 for t in tasks if t.get("status") == "completed")
    overdue_count = sum(1 for t in tasks if _is_overdue(t))

    await state.update_data(filtered_tasks=filtered)
    await callback.message.edit_text(  
        f"📊 *Статистика:* {completed}/{total} ✅ | {overdue_count} 🔴\n"
        f"📂 *{filter_names.get(filt, filt)}:* {len(filtered)} шт.\n\n"
        "Выбери задачу для деталей:",
        parse_mode="Markdown",
        reply_markup=tasks_list_kb(filtered, action_prefix="open"),
    )
    await callback.answer()


@router.callback_query(F.data.startswith("open:"))
async def open_task(callback: CallbackQuery, state: FSMContext) -> None:
    task_id = int(callback.data.split(":")[1])  
    data = await state.get_data()
    tasks = data.get("filtered_tasks", [])
    task = next((t for t in tasks if t.get("id") == task_id), None)
    if not task:
        await callback.answer("Задача не найдена", show_alert=True)
        return
    text = _format_task(task)
    can_complete = task.get("status") not in ("completed",)
    await callback.message.edit_text(  
        text,
        parse_mode="Markdown",
        reply_markup=task_detail_kb(task_id, can_complete=can_complete),
    )
    await callback.answer()



@router.callback_query(F.data == "menu:create")
async def menu_create(callback: CallbackQuery, state: FSMContext) -> None:
    await callback.message.edit_text(  
        "➕ *Создание задания*\n\n"
        "Опиши задание одним сообщением.\n"
        "Я автоматически извлеку:\n"
        "• 📌 Название (первая строка)\n"
        "• 📝 Описание (остальные строки)\n"
        "• 📅 Дедлайн (если укажешь дату)\n\n"
        "*Примеры:*\n"
        "`Контрольная по математике\n"
        "Подготовиться к производным и интегралам\n"
        "25.12.2025`\n\n"
        "`Эссе по литературе завтра`",
        parse_mode="Markdown",
    )
    await state.set_state(TaskCreateStates.enter_text)
    await callback.answer()


@router.message(TaskCreateStates.enter_text)
async def process_create_text(message: Message, state: FSMContext) -> None:
    text = message.text or ""
    parsed = _parse_task_text(text)
    await state.update_data(draft=parsed)
    preview = _format_task(parsed)
    await message.answer(
        f"👁 *Предпросмотр задания:*\n\n{preview}\n\n"
        "Сохранить это задание?",
        parse_mode="Markdown",
        reply_markup=confirm_cancel_kb("create:confirm", "menu:back"),
    )
    await state.set_state(TaskCreateStates.confirm)


@router.callback_query(TaskCreateStates.confirm, F.data == "create:confirm")
async def confirm_create(callback: CallbackQuery, state: FSMContext) -> None:
    data = await state.get_data()
    token = data.get("token")
    draft = data.get("draft")
    if not token or not draft:
        await callback.message.edit_text(  
            "❌ *Ошибка сессии*\n\n"
            "Начни с /start",
            parse_mode="Markdown",
        )
        await callback.answer()
        return

    ok, resp = await get_client().create_task(token, draft)
    if not ok:
        detail = resp.get("detail", "Ошибка создания")
        await callback.message.edit_text(  
            f"⚠️ *{detail}*",
            parse_mode="Markdown",
            reply_markup=retry_back_kb("create:confirm"),
        )
        await callback.answer()
        return

    title = resp.get("title", "Задание")
    await callback.message.edit_text(  
        f"✅ *Задание создано!*\n\n"
        f"📌 {title}\n\n"
        "Теперь оно появится в твоём списке задач.",
        parse_mode="Markdown",
        reply_markup=main_menu_kb(data.get("role", "student")),
    )
    await state.set_state(None)
    await callback.answer()



@router.callback_query(F.data == "menu:complete")
async def menu_complete(callback: CallbackQuery, state: FSMContext) -> None:
    data = await state.get_data()
    token = data.get("token")
    if not token:
        await callback.message.edit_text(  
            "❌ *Требуется авторизация*\n\n"
            "Сначала войди через /start",
            parse_mode="Markdown",
        )
        await callback.answer()
        return

    ok, tasks = await get_client().list_tasks(token)
    if not ok:
        detail = tasks.get("detail", "Ошибка загрузки")
        await callback.message.edit_text( 
            f"⚠️ *{detail}*",
            parse_mode="Markdown",
            reply_markup=retry_back_kb("menu:complete"),
        )
        await callback.answer()
        return

    open_tasks = [t for t in tasks if t.get("status") in ("pending", "in_progress", "overdue")]
    if not open_tasks:
        await callback.message.edit_text( 
            "🎉 *Все задачи выполнены!*\n\n"
            "Ты молодец! Отдыхай или создай новое задание. 😊",
            parse_mode="Markdown",
            reply_markup=main_menu_kb(data.get("role", "student")),
        )
        await callback.answer()
        return

    await state.update_data(complete_tasks=open_tasks)
    await callback.message.edit_text( 
        f"✨ *Открытые задачи:* {len(open_tasks)}\n\n"
        "Выбери задачу, которую хочешь отметить выполненной:",
        parse_mode="Markdown",
        reply_markup=tasks_list_kb(open_tasks, action_prefix="complete"),
    )
    await state.set_state(TaskCompleteStates.choose_task)
    await callback.answer()


@router.callback_query(TaskCompleteStates.choose_task, F.data.startswith("complete:"))
async def do_complete(callback: CallbackQuery, state: FSMContext) -> None:
    task_id = int(callback.data.split(":")[1])  
    data = await state.get_data()
    token = data.get("token")
    if not token:
        await callback.message.edit_text(  
            "❌ *Сессия истекла*\n\n"
            "Авторизуйся заново: /start",
            parse_mode="Markdown",
        )
        await callback.answer()
        return

    ok, resp = await get_client().update_task(token, task_id, {"status": "completed"})
    if not ok:
        detail = resp.get("detail", "Ошибка обновления")
        await callback.message.edit_text(  
            f"⚠️ *{detail}*",
            parse_mode="Markdown",
            reply_markup=retry_back_kb(f"complete:{task_id}"),
        )
        await callback.answer()
        return

    title = resp.get("title", "Задание")
    bonus_xp = resp.get("challenge_bonus_xp", 0)
    xp_text = f"\n🏆 *+{bonus_xp} XP* за челлендж!" if bonus_xp else ""

    await callback.message.edit_text( 
        f"🎉 *Задача выполнена!*\n\n"
        f"✅ {title}{xp_text}\n\n"
        "Продолжай в том же духе! 🔥",
        parse_mode="Markdown",
        reply_markup=main_menu_kb(data.get("role", "student")),
    )
    await state.set_state(None)
    await callback.answer()




@router.callback_query(F.data == "menu:study_plan")
async def menu_study_plan(callback: CallbackQuery, state: FSMContext) -> None:
    data = await state.get_data()
    token = data.get("token")
    if not token:
        await callback.message.edit_text(  
            "❌ *Требуется авторизация*\n\n"
            "Сначала войди через /start",
            parse_mode="Markdown",
        )
        await callback.answer()
        return

    ok, plan = await get_client().get_study_plan(token)
    if not ok:
        detail = plan.get("detail", "Ошибка загрузки плана")
        await callback.message.edit_text(  
            f"⚠️ *{detail}*",
            parse_mode="Markdown",
            reply_markup=retry_back_kb("menu:study_plan"),
        )
        await callback.answer()
        return

    focus = plan.get("focus_message", "")
    do_now = plan.get("do_now", [])
    do_next = plan.get("do_next", [])
    stretch = plan.get("stretch_goal", "")
    total = plan.get("estimated_total_minutes", 0)
    skill = plan.get("main_skill_to_improve", "")

    lines = [
        "🎓 *Учебный план*",
        "",
        f"💡 {focus}",
        "",
    ]

    if do_now:
        lines.append("🔥 *Сделать сейчас:*")
        for t in do_now:
            diff = t.get("difficulty_level", 2)
            time_est = t.get("estimated_time_minutes", "?")
            lines.append(
                f"  • {t.get('title', '')} "
                f"({'🔴' * diff}{'⚪' * (5 - diff)}) ⏱{time_est}мин"
            )
        lines.append("")

    if do_next:
        lines.append("⏳ *Далее:*")
        for t in do_next:
            diff = t.get("difficulty_level", 2)
            time_est = t.get("estimated_time_minutes", "?")
            lines.append(
                f"  • {t.get('title', '')} "
                f"({'🔴' * diff}{'⚪' * (5 - diff)}) ⏱{time_est}мин"
            )
        lines.append("")

    if stretch:
        lines.append(f"🚀 *Stretch-цель:* {stretch}")
        lines.append("")

    lines.append(f"⏱ *Общее время:* ~{total} мин")
    if skill:
        lines.append(f"📈 *Навык для прокачки:* {skill}")

    await callback.message.edit_text(  
        "\n".join(lines),
        parse_mode="Markdown",
        reply_markup=main_menu_kb(data.get("role", "student")),
    )
    await callback.answer()

