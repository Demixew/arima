from __future__ import annotations

from pydantic import BaseModel


class WeeklyNarrativeResponse(BaseModel):
    headline: str
    summary: str
    next_focus: str | None = None
