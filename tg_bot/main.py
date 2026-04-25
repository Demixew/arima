from __future__ import annotations

import asyncio
import logging
import sys

from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.fsm.storage.memory import MemoryStorage

from tg_bot.config import get_config
from tg_bot.handlers import auth, progress, tasks
from tg_bot.scheduler import check_overdue_loop

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger(__name__)

# Shared in-memory session store: user_id -> {chat_id, token}
_user_sessions: dict[int, dict[str, str | int]] = {}


def _collect_sessions() -> dict[int, dict[str, str | int]]:
    return _user_sessions


async def main() -> None:
    cfg = get_config()
    if not cfg.bot_token or cfg.bot_token == "your_telegram_bot_token_here":
        logger.error(
            "BOT_TOKEN not configured!\n"
            "  1. Copy tg_bot/.env.example to tg_bot/.env\n"
            "  2. Set BOT_TOKEN=your_real_telegram_bot_token"
        )
        sys.exit(1)
    bot = Bot(token=cfg.bot_token, default=DefaultBotProperties(parse_mode="HTML"))
    storage = MemoryStorage()
    dp = Dispatcher(storage=storage)

    dp.include_router(auth.router)
    dp.include_router(tasks.router)
    dp.include_router(progress.router)

    # Background overdue checker
    asyncio.create_task(check_overdue_loop(bot, interval_sec=300))

    logger.info("Bot started, polling...")
    try:
        await dp.start_polling(bot)
    finally:
        await bot.session.close()


if __name__ == "__main__":
    asyncio.run(main())

