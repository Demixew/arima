from __future__ import annotations

from aiogram.types import InlineKeyboardButton, InlineKeyboardMarkup


def role_kb() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(text="👨‍🎓 Ученик", callback_data="role:student"),
                InlineKeyboardButton(text="👩‍🏫 Учитель", callback_data="role:teacher"),
                InlineKeyboardButton(text="👨‍👩‍👧 Родитель", callback_data="role:parent"),
            ]
        ]
    )


def main_menu_kb(role: str = "student") -> InlineKeyboardMarkup:
    buttons = [
        [InlineKeyboardButton(text="📋 Мои задачи", callback_data="menu:tasks")],
        [InlineKeyboardButton(text="➕ Создать задание", callback_data="menu:create")],
        [InlineKeyboardButton(text="✅ Отметить выполненным", callback_data="menu:complete")],
        [InlineKeyboardButton(text="📊 Прогресс", callback_data="menu:progress")],
    ]
    if role == "student":
        buttons.insert(1, [InlineKeyboardButton(text="🎓 Учебный план", callback_data="menu:study_plan")])
    buttons.append([InlineKeyboardButton(text="🔄 Сбросить сессию", callback_data="menu:reset")])
    return InlineKeyboardMarkup(inline_keyboard=buttons)


def task_filter_kb() -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(text="📅 Сегодня", callback_data="filter:today"),
                InlineKeyboardButton(text="⏳ Скоро", callback_data="filter:soon"),
            ],
            [
                InlineKeyboardButton(text="🔴 Просрочено", callback_data="filter:overdue"),
                InlineKeyboardButton(text="📋 Все", callback_data="filter:all"),
            ],
            [InlineKeyboardButton(text="🔙 В меню", callback_data="menu:back")],
        ]
    )


def tasks_list_kb(tasks: list[dict], action_prefix: str = "open") -> InlineKeyboardMarkup:
    buttons: list[list[InlineKeyboardButton]] = []
    for t in tasks:
        tid = t["id"]
        title = t["title"][:30]
        status_icon = _status_icon(t.get("status", ""))
        buttons.append(
            [InlineKeyboardButton(text=f"{status_icon} {title}", callback_data=f"{action_prefix}:{tid}")]
        )
    buttons.append([InlineKeyboardButton(text="🔙 В меню", callback_data="menu:back")])
    return InlineKeyboardMarkup(inline_keyboard=buttons)


def task_detail_kb(task_id: int, can_complete: bool = True) -> InlineKeyboardMarkup:
    buttons: list[list[InlineKeyboardButton]] = []
    if can_complete:
        buttons.append(
            [InlineKeyboardButton(text="✅ Выполнено", callback_data=f"complete:{task_id}")]
        )
    buttons.append([InlineKeyboardButton(text="🔙 К списку", callback_data="menu:tasks")])
    buttons.append([InlineKeyboardButton(text="🏠 В меню", callback_data="menu:back")])
    return InlineKeyboardMarkup(inline_keyboard=buttons)


def confirm_cancel_kb(confirm_data: str, cancel_data: str = "menu:back") -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(text="✅ Подтвердить", callback_data=confirm_data),
                InlineKeyboardButton(text="❌ Отмена", callback_data=cancel_data),
            ]
        ]
    )


def retry_back_kb(retry_data: str) -> InlineKeyboardMarkup:
    return InlineKeyboardMarkup(
        inline_keyboard=[
            [
                InlineKeyboardButton(text="🔄 Повторить", callback_data=retry_data),
                InlineKeyboardButton(text="🔙 В меню", callback_data="menu:back"),
            ]
        ]
    )


def _status_icon(status: str) -> str:
    return {
        "pending": "⏳",
        "in_progress": "🔄",
        "completed": "✅",
        "overdue": "🔴",
    }.get(status, "📌")

