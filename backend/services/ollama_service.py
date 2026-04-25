from __future__ import annotations

from backend.services.ai_service import evaluate_submission_with_ai
from backend.services.ai_service import generate_personalized_task_draft
from backend.services.ai_service import get_ai_status as get_ollama_status
from backend.services.ai_service import settings

__all__ = [
    "evaluate_submission_with_ai",
    "generate_personalized_task_draft",
    "get_ollama_status",
    "settings",
]
