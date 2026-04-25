from __future__ import annotations

import logging

from aiogram import F, Router
from aiogram.filters import Command
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import CallbackQuery, Message

from tg_bot.client import get_client
from tg_bot.keyboards import main_menu_kb, role_kb
from tg_bot.scheduler import register_user_session, remove_user_session

logger = logging.getLogger(__name__)
router = Router()


class AuthStates(StatesGroup):
    choosing_role = State()
    entering_email = State()
    entering_password = State()


BANNER = (
    "╔══════════════════════════════════════╗\n"
    "║  🎯 WATA Smart Tracker  🚀           ║\n"
    "║  Твой умный помощник в учёбе!       ║\n"
    "╚══════════════════════════════════════╝"
)


@router.message(Command("start"))
async def cmd_start(message: Message, state: FSMContext) -> None:
    await state.clear()
    await message.answer(
        f"{BANNER}\n\n"
        "👋 Привет! Я помогу тебе организовать учёбу, отслеживать задания \n"
        "и достигать целей без стресса.\n\n"
        "🎭 *Выбери свою роль, чтобы начать:*",
        parse_mode="Markdown",
        reply_markup=role_kb(),
    )
    await state.set_state(AuthStates.choosing_role)


@router.callback_query(AuthStates.choosing_role, F.data.startswith("role:"))
async def process_role(callback: CallbackQuery, state: FSMContext) -> None:
    role = callback.data.split(":")[1]  # type: ignore[union-attr]
    role_names = {
        "student": "👨‍🎓 Ученик",
        "teacher": "👩‍🏫 Учитель",
        "parent": "👨‍👩‍👧 Родитель",
    }
    role_display = role_names.get(role, role)
    await state.update_data(role=role)
    await callback.message.edit_text(  # type: ignore[union-attr]
        f"✨ Отлично! Ты выбрал роль: *{role_display}*\n\n"
        f"{'🎒' if role == 'student' else '📚' if role == 'teacher' else '👨‍👩‍👧'} \n"
        "Теперь введи свой *email* для входа:",
        parse_mode="Markdown",
    )
    await state.set_state(AuthStates.entering_email)
    await callback.answer()


@router.message(AuthStates.entering_email)
async def process_email(message: Message, state: FSMContext) -> None:
    email = message.text or ""
    if "@" not in email or "." not in email.split("@")[-1]:
        await message.answer(
            "❌ *Некорректный email*\n"
            "Пожалуйста, введи действительный адрес электронной почты.",
            parse_mode="Markdown",
        )
        return
    await state.update_data(email=email.strip())
    await message.answer(
        "📧 Email принят!\n\n"
        "🔒 Теперь введи свой *пароль*:\n"
        "_В целях безопасности сообщение будет удалено._",
        parse_mode="Markdown",
    )
    await state.set_state(AuthStates.entering_password)


@router.message(AuthStates.entering_password)
async def process_password(message: Message, state: FSMContext) -> None:
    password = message.text or ""
    data = await state.get_data()
    email = data.get("email", "")
    role = data.get("role", "student")

    # Delete password message for security
    try:
        await message.delete()
    except Exception:
        pass

    client = get_client()
    ok, resp = await client.login(email, password)

    if not ok:
        detail = resp.get("detail", "Неверный логин или пароль")
        await message.answer(
            f"❌ *Ошибка авторизации*\n\n"
            f"{detail}\n\n"
            "Попробуй снова: /start",
            parse_mode="Markdown",
        )
        await state.clear()
        return

    token = resp.get("access_token")
    if not token:
        await message.answer(
            "❌ *Не удалось получить токен*\n\n"
            "Попробуй ещё раз: /start",
            parse_mode="Markdown",
        )
        await state.clear()
        return

    me_ok, me_data = await client.me(token)
    if not me_ok:
        await message.answer(
            "⚠️ *Авторизация прошла, но профиль недоступен*\n\n"
            f"Детали: {me_data.get('detail', 'неизвестно')}\n\n"
            "Попробуй /start",
            parse_mode="Markdown",
        )
        await state.clear()
        return

    await state.update_data(token=token, user=me_data, role=me_data.get("role", role))
    register_user_session(message.from_user.id, message.chat.id, token)
    name = me_data.get("full_name", "Пользователь")
    role_display = me_data.get("role", role)

    # Create personalized welcome
    welcome_msg = (
        f"🎉 *Добро пожаловать, {name}!*\n\n"
        f"{'🎒' if role_display == 'student' else '📚' if role_display == 'teacher' else '👨‍👩‍👧'} "
        f"Роль: *{role_display.upper()}*\n"
        f"📧 {email}\n\n"
        "━━━━━━━━━━━━━━━━━━━━━━━\n"
        "✨ Что я умею:\n"
        "📋 Управлять задачами\n"
        "📊 Отслеживать прогресс\n"
        "🔔 Напоминать о дедлайнах\n"
        "━━━━━━━━━━━━━━━━━━━━━━━\n\n"
        "*Выбери действие ниже:*"
    )

    await message.answer(
        welcome_msg,
        parse_mode="Markdown",
        reply_markup=main_menu_kb(role=me_data.get("role", role)),
    )
    await state.set_state(None)


@router.message(Command("reset"))
async def cmd_reset(message: Message, state: FSMContext) -> None:
    remove_user_session(message.from_user.id)
    await state.clear()
    await message.answer(
        "🔄 *Сессия сброшена*\n\n"
        "Все данные авторизации удалены.\n"
        "Чтобы начать заново, нажми /start",
        parse_mode="Markdown",
    )


@router.callback_query(F.data == "menu:reset")
async def reset_callback(callback: CallbackQuery, state: FSMContext) -> None:
    if callback.from_user:
        remove_user_session(callback.from_user.id)
    await state.clear()
    await callback.message.edit_text(  # type: ignore[union-attr]
        "🔄 *Сессия сброшена*\n\n"
        "Все данные авторизации удалены.\n"
        "Чтобы начать заново, нажми /start",
        parse_mode="Markdown",
    )
    await callback.answer()


@router.callback_query(F.data == "menu:back")
async def back_to_menu(callback: CallbackQuery, state: FSMContext) -> None:
    data = await state.get_data()
    role = data.get("role", "student")
    await callback.message.edit_text(  # type: ignore[union-attr]
        "🏠 *Главное меню*\n\n"
        "Выбери действие:",
        parse_mode="Markdown",
        reply_markup=main_menu_kb(role=role),
    )
    await callback.answer()

