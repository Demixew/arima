
from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from backend.core.db import get_db_session
from backend.api.auth import get_current_user
from backend.models.user import User, UserRole
from backend.schemas.metrics import (
    ChildStatsSummary,
    DailyStatsResponse,
    LinkChildRequest,
    LinkedChildResponse,
    UserMetricsResponse,
)
from backend.services import metrics_service

router = APIRouter(prefix="/metrics", tags=["metrics"])

@router.get("/me", response_model=UserMetricsResponse)
async def get_my_metrics(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> UserMetricsResponse:
    metrics = await metrics_service.build_user_metrics_response(session, current_user.id)

    if metrics is None:
        raise HTTPException(status_code=404, detail="Metrics not found")

    return metrics

@router.get("/me/daily", response_model=list[DailyStatsResponse])
async def get_my_daily_stats(
    days: int = 7,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> list[DailyStatsResponse]:
    stats = await metrics_service.get_daily_stats(session, current_user.id, days)
    return [DailyStatsResponse.model_validate(s) for s in stats]

@router.get("/children", response_model=list[LinkedChildResponse])
async def get_linked_children(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> list[LinkedChildResponse]:
    if current_user.role != UserRole.parent:
        raise HTTPException(
            status_code=403,
            detail="Only parents can view linked children",
        )

    return await metrics_service.get_linked_children(session, current_user.id)

@router.post("/children/link")
async def link_child(
    request: LinkChildRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, str]:
    if current_user.role != UserRole.parent:
        raise HTTPException(
            status_code=403,
            detail="Only parents can link children",
        )

    try:
        link = await metrics_service.link_child_to_parent(
            session, current_user.id, request.child_email
        )
        await session.commit()
        return {"status": "linked", "child_id": str(link.child_id)}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.delete("/children/{child_id}/unlink")
async def unlink_child(
    child_id: int,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> dict[str, str]:
    if current_user.role != UserRole.parent:
        raise HTTPException(
            status_code=403,
            detail="Only parents can unlink children",
        )

    await metrics_service.unlink_child(session, current_user.id, child_id)
    await session.commit()
    return {"status": "unlinked"}

@router.get("/children/{child_id}/stats", response_model=ChildStatsSummary)
async def get_child_stats(
    child_id: int,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db_session),
) -> ChildStatsSummary:
    if current_user.role != UserRole.parent:
        raise HTTPException(
            status_code=403,
            detail="Only parents can view child stats",
        )

    stats = await metrics_service.get_child_stats_summary(session, child_id)
    return ChildStatsSummary(**stats)
