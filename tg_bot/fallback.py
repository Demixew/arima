from __future__ import annotations

from datetime import datetime, timedelta, timezone

DEMO_TASKS = [
    {
        "id": 1,
        "title": "📚 Подготовиться к контрольной по математике",
        "description": "Повторить темы: производные, интегралы, пределы. Решить 10 задач из учебника.",
        "status": "pending",
        "due_at": (datetime.now(timezone.utc) + timedelta(hours=3)).isoformat(),
        "difficulty_level": 3,
        "estimated_time_minutes": 45,
        "is_challenge": False,
        "challenge_bonus_xp": 0,
        "rescue_plan": None,
    },
    {
        "id": 2,
        "title": "📝 Написать сочинение по литературе",
        "description": "Тема: образ Мцыри в одноимённом произведении Лермонтова. Объём: 2-3 страницы.",
        "status": "in_progress",
        "due_at": (datetime.now(timezone.utc) + timedelta(days=1)).isoformat(),
        "difficulty_level": 4,
        "estimated_time_minutes": 90,
        "is_challenge": True,
        "challenge_bonus_xp": 50,
        "challenge_category": "writing",
        "rescue_plan": None,
    },
    {
        "id": 3,
        "title": "🔬 Лабораторная работа по физике",
        "description": "Определение ускорения свободного падения с помощью математического маятника.",
        "status": "overdue",
        "due_at": (datetime.now(timezone.utc) - timedelta(hours=5)).isoformat(),
        "difficulty_level": 2,
        "estimated_time_minutes": 60,
        "is_challenge": False,
        "challenge_bonus_xp": 0,
        "rescue_plan": {
            "mini_steps": [
                "📦 Собрать необходимое оборудование (нить, груз, секундомер)",
                "📏 Провести 10 измерений периода колебаний",
                "🧮 Заполнить таблицу результатов и рассчитать g",
                "✍️ Оформить выводы в тетради",
            ],
            "recommended_new_time_block": "Сегодня с 16:00 до 17:00",
            "difficulty_tone": "лёгкая",
        },
    },
    {
        "id": 4,
        "title": "🌍 Выучить страны Африки",
        "description": "Запомнить столицы 15 стран Северной Африки. Использовать карту.",
        "status": "pending",
        "due_at": (datetime.now(timezone.utc) + timedelta(days=2)).isoformat(),
        "difficulty_level": 2,
        "estimated_time_minutes": 30,
        "is_challenge": True,
        "challenge_bonus_xp": 25,
        "challenge_category": "memory",
        "rescue_plan": None,
    },
]

DEMO_METRICS = {
    "id": 1,
    "user_id": 1,
    "total_tasks_completed": 12,
    "total_tasks_created": 15,
    "current_streak": 3,
    "longest_streak": 7,
    "avg_completion_time_hours": 1.5,
    "total_focus_time_minutes": 480,
    "completion_rate": 80,
    "last_completed_at": (datetime.now(timezone.utc) - timedelta(days=1)).isoformat(),
    "last_activity_at": (datetime.now(timezone.utc) - timedelta(hours=2)).isoformat(),
    "created_at": datetime.now(timezone.utc).isoformat(),
    "updated_at": datetime.now(timezone.utc).isoformat(),
    "gamification": {
        "total_xp": 1250,
        "level": 5,
        "rank_title": "Отличник",
        "current_level_xp": 200,
        "next_level_xp": 500,
        "progress_percent": 40,
        "energy": 85,
        "next_unlock_hint": "Достигните 6 уровня, чтобы открыть новый аватар!",
        "unlocked_badges": [
            {
                "id": "streak_3",
                "title": "Серия х3",
                "description": "Выполняй задания 3 дня подряд",
                "icon": "🔥",
                "accent_color": "#FF5722",
            },
            {
                "id": "early_bird",
                "title": "Жаворонок",
                "description": "Выполни 5 задач до 9 утра",
                "icon": "🐦",
                "accent_color": "#4CAF50",
            },
        ],
        "daily_challenges": [
            {
                "id": "dc1",
                "title": "Завершить 2 задания",
                "description": "Выполни любые 2 задания сегодня",
                "current": 1,
                "target": 2,
                "reward_xp": 50,
                "completed": False,
            },
            {
                "id": "dc2",
                "title": "Фокус 30 минут",
                "description": "Проведи 30 минут в фокус-режиме",
                "current": 20,
                "target": 30,
                "reward_xp": 30,
                "completed": False,
            },
        ],
    },
}

DEMO_DAILY_STATS = [
    {
        "id": i,
        "user_id": 1,
        "date": (datetime.now(timezone.utc) - timedelta(days=i)).isoformat(),
        "tasks_created": 2 if i % 2 == 0 else 1,
        "tasks_completed": 1 if i > 0 else 2,
        "focus_time_minutes": 45 + i * 5,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    for i in range(7)
]

DEMO_STUDY_PLAN = {
    "focus_message": "Начни с просроченной лабораторной — так вернёшь контроль над ситуацией! 🔬",
    "do_now": [
        {
            "id": 3,
            "title": "🔬 Лабораторная работа по физике",
            "status": "overdue",
            "due_at": (datetime.now(timezone.utc) - timedelta(hours=5)).isoformat(),
            "difficulty_level": 2,
            "estimated_time_minutes": 60,
        }
    ],
    "do_next": [
        {
            "id": 1,
            "title": "📚 Подготовиться к контрольной по математике",
            "status": "pending",
            "due_at": (datetime.now(timezone.utc) + timedelta(hours=3)).isoformat(),
            "difficulty_level": 3,
            "estimated_time_minutes": 45,
        },
        {
            "id": 2,
            "title": "📝 Написать сочинение по литературе",
            "status": "in_progress",
            "due_at": (datetime.now(timezone.utc) + timedelta(days=1)).isoformat(),
            "difficulty_level": 4,
            "estimated_time_minutes": 90,
        },
    ],
    "stretch_goal": "Если останется время — повтори страны Африки (20 мин) 🌍",
    "estimated_total_minutes": 195,
    "main_skill_to_improve": "тайм-менеджмент",
}

