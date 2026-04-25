from __future__ import annotations

import logging
from datetime import datetime, timezone

from aiogram import F, Router
from aiogram.fsm.context import FSMContext
from aiogram.types import CallbackQuery

from tg_bot.client import get_client
from tg_bot.keyboards import main_menu_kb, retry_back_kb

logger = logging.getLogger(__name__)
router = Router()


def _progress_bar(percent: int, width: int = 12) -> str:
    """ASCII progress bar."""
    filled = int(width * percent / 100)
    bar = "█" * filled + "░" * (width - filled)
    return f"[{bar}] {percent}%"


def _xp_bar(current: int, next_level: int, width: int = 12) -> str:
    """XP progress bar."""
    if next_level <= 0:
        return "[████████████] MAX"
    percent = min(100, int(current / next_level * 100))
    filled = int(width * percent / 100)
    bar = "█" * filled + "░" * (width - filled)
    return f"[{bar}] {current}/{next_level} XP"


def _energy_bar(energy: int, width: int = 10) -> str:
    """Energy bar with color-like emojis."""
    filled = int(width * energy / 100)
    if energy > 60:
        icon = "🟢"
    elif energy > 30:
        icon = "🟡"
    else:
        icon = "🔴"
    bar = icon * filled + "⚪" * (width - filled)
    return f"{bar} {energy}%"


def _streak_flame(streak: int) -> str:
    """Visual streak indicator."""
    if streak >= 7:
        return f"🔥🔥🔥 {streak} дней (невероятно!)"
    elif streak >= 3:
        return f"🔥🔥 {streak} дней (круто!)"
    elif streak >= 1:
        return f"🔥 {streak} день (отлично!)"
    return "💨 Нет активной серии"


@router.callback_query(F.data == "menu:progress")
async def menu_progress(callback: CallbackQuery, state: FSMContext) -> None:
    data = await state.get_data()
    token = data.get("token")
    if not token:
        await callback.message.edit_text(  # type: ignore[union-attr]
            "❌ *Требуется авторизация*\n\n"
            "Сначала войди через /start",
            parse_mode="Markdown",
        )
        await callback.answer()
        return

    ok, metrics = await get_client().get_metrics(token)
    if not ok:
        detail = metrics.get("detail", "Ошибка загрузки прогресса")
        await callback.message.edit_text(  # type: ignore[union-attr]
            f"⚠️ *{detail}*",
            parse_mode="Markdown",
            reply_markup=retry_back_kb("menu:progress"),
        )
        await callback.answer()
        return

    ok2, daily = await get_client().get_daily_stats(token, days=7)
    if not ok2:
        daily = []

    total_completed = metrics.get("total_tasks_completed", 0)
    total_created = metrics.get("total_tasks_created", 0)
    streak = metrics.get("current_streak", 0)
    longest = metrics.get("longest_streak", 0)
    completion_rate = metrics.get("completion_rate", 0)
    focus_min = metrics.get("total_focus_time_minutes", 0)
    avg_hours = metrics.get("avg_completion_time_hours", 0.0)

    gamification = metrics.get("gamification") or {}
    xp = gamification.get("total_xp", 0)
    level = gamification.get("level", 1)
    rank = gamification.get("rank_title", "Новичок")
    current_level_xp = gamification.get("current_level_xp", 0)
    next_level_xp = gamification.get("next_level_xp", 100)
    progress_percent = gamification.get("progress_percent", 0)
    energy = gamification.get("energy", 100)

    # Badges
    badges = gamification.get("unlocked_badges", [])
    badges_str = ""
    if badges:
        badges_str = "\n🏅 *Значки:* " + " ".join(b.get("icon", "🏆") for b in badges)

    # Daily challenges
    challenges = gamification.get("daily_challenges", [])
    challenges_str = ""
    if challenges:
        challenges_str = "\n\n📋 *Ежедневные челленджи:*\n"
        for ch in challenges:
            status = "✅" if ch.get("completed") else "⏳"
            curr = ch.get("current", 0)
            target = ch.get("target", 1)
            title = ch.get("title", "")
            reward = ch.get("reward_xp", 0)
            bar_filled = int(10 * curr / target) if target > 0 else 0
            bar = "█" * bar_filled + "░" * (10 - bar_filled)
            challenges_str += f"{status} {title}\n   [{bar}] {curr}/{target} (+{reward} XP)\n"

    # Last activity
    last = metrics.get("last_completed_at")
    last_str = ""
    if last:
        try:
            dt = datetime.fromisoformat(last.replace("Z", "+00:00"))
            last_str = f"\n🕒 Последнее выполнение: {dt.strftime('%d.%m.%Y %H:%M')}"
        except Exception:
            pass

    # Daily stats chart
    daily_str = ""
    if daily:
        daily_str = "\n📅 *Активность за 7 дней:*\n"
        for d in daily[:7]:
            date = d.get("date", "")
            try:
                dt = datetime.fromisoformat(date.replace("Z", "+00:00"))
                date_s = dt.strftime("%d.%m")
            except Exception:
                date_s = str(date)[:5]
            comp = d.get("tasks_completed", 0)
            crea = d.get("tasks_created", 0)
            focus = d.get("focus_time_minutes", 0)
            # Mini bar for completed
            comp_bar = "✅" * min(comp, 5) + "⚪" * max(0, 5 - comp)
            daily_str += f"  {date_s} │{comp_bar}│ 📝{crea} ⏱{focus}м\n"

    # Rank emoji
    rank_emojis = {
        "Новичок": "🌱",
        "Ученик": "📖",
        "Отличник": "⭐",
        "Ботан": "🤓",
        "Гений": "🧠",
        "Легенда": "👑",
    }
    rank_emoji = rank_emojis.get(rank, "🎯")

    text = (
        f"📊 *Твой прогресс*\n"
        f"{'━' * 22}\n\n"
        f"{rank_emoji} *Уровень {level}* — {rank}\n"
        f"{_xp_bar(current_level_xp, next_level_xp)}\n\n"
        f"⭐ *Всего XP:* {xp}\n"
        f"⚡ *Энергия:* {_energy_bar(energy)}\n"
        f"🔥 *Серия:* {_streak_flame(streak)}\n"
        f"📈 *Макс. серия:* {longest} дней\n"
        f"{badges_str}\n"
        f"{challenges_str}\n"
        f"{'━' * 22}\n"
        f"✅ *Выполнено:* {total_completed}\n"
        f"📝 *Создано:* {total_created}\n"
        f"📊 *Завершённость:* {_progress_bar(completion_rate)}\n"
        f"⏱ *Фокус-время:* {focus_min} мин\n"
        f"🕐 *Ср. время:* {avg_hours:.1f} ч"
        f"{last_str}"
        f"{daily_str}\n"
        f"{'━' * 22}"
    )

    await callback.message.edit_text(  # type: ignore[union-attr]
        text,
        parse_mode="Markdown",
        reply_markup=main_menu_kb(data.get("role", "student")),
    )
    await callback.answer()

