from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any

from backend.models.metrics import AIReviewStatus, TaskSubmission, UserMetrics
from backend.models.task import Task, TaskStatus


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _normalize(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _safe_text(value: str | None, fallback: str) -> str:
    cleaned = (value or "").strip()
    return cleaned if cleaned else fallback


def _is_due_soon(task: Task, *, hours: int = 36) -> bool:
    due_at = _normalize(task.due_at)
    if due_at is None or task.status == TaskStatus.completed:
        return False
    now = _now()
    return now <= due_at <= now + timedelta(hours=hours)


def _is_overdue(task: Task) -> bool:
    due_at = _normalize(task.due_at)
    if due_at is None or task.status == TaskStatus.completed:
        return False
    return due_at < _now()


def _task_time_minutes(task: Task) -> int:
    return task.estimated_time_minutes or max(15, task.difficulty_level * 10)


def _task_ref(task: Task) -> dict[str, Any]:
    return {
        "id": task.id,
        "title": task.title,
        "status": task.status.value,
        "due_at": task.due_at,
        "difficulty_level": task.difficulty_level,
        "estimated_time_minutes": task.estimated_time_minutes,
    }


@dataclass
class RubricSnapshot:
    strongest_area: str | None = None
    strongest_avg: float | None = None
    weakest_area: str | None = None
    weakest_avg: float | None = None
    risk_flags: int = 0
    failed_reviews: int = 0
    review_count: int = 0


def summarize_rubric_health(tasks: list[Task]) -> RubricSnapshot:
    rubric_scores: dict[str, list[int]] = {}
    risk_flags = 0
    failed_reviews = 0
    review_count = 0

    for task in tasks:
        submission = task.submission
        if submission is None:
            continue
        if submission.ai_review_status == AIReviewStatus.failed:
            failed_reviews += 1
        if submission.ai_review_status != AIReviewStatus.ready:
            continue

        review_count += 1
        risk_flags += len(_decode_json_list(submission.ai_risk_flags_json))
        for item in _decode_json_list(submission.ai_rubric_json):
            if not isinstance(item, dict):
                continue
            criterion = str(item.get("criterion", "")).strip()
            score = item.get("score")
            if not criterion or not isinstance(score, int):
                continue
            rubric_scores.setdefault(criterion, []).append(score)

    strongest_area = None
    strongest_avg = None
    weakest_area = None
    weakest_avg = None

    for criterion, scores in rubric_scores.items():
        average = sum(scores) / len(scores)
        if strongest_avg is None or average > strongest_avg:
            strongest_avg = average
            strongest_area = criterion
        if weakest_avg is None or average < weakest_avg:
            weakest_avg = average
            weakest_area = criterion

    return RubricSnapshot(
        strongest_area=strongest_area,
        strongest_avg=strongest_avg,
        weakest_area=weakest_area,
        weakest_avg=weakest_avg,
        risk_flags=risk_flags,
        failed_reviews=failed_reviews,
        review_count=review_count,
    )


def _decode_json_list(raw: str | None) -> list[Any]:
    if not raw:
        return []
    import json

    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError:
        return []
    return parsed if isinstance(parsed, list) else []


def build_teacher_risk_summary(
    *,
    tasks: list[Task],
    metrics: UserMetrics | None,
) -> dict[str, Any]:
    overdue_count = sum(1 for task in tasks if _is_overdue(task))
    missing_submissions = sum(
        1
        for task in tasks
        if task.requires_submission and task.submission is None and task.status != TaskStatus.completed
    )
    inactive_days = (
        (_now().date() - _normalize(metrics.last_activity_at).date()).days
        if metrics and _normalize(metrics.last_activity_at) is not None
        else 7
    )
    completion_rate = metrics.completion_rate if metrics else 0
    streak = metrics.current_streak if metrics else 0
    rubric = summarize_rubric_health(tasks)

    score = 0
    score += min(40, overdue_count * 18)
    score += min(20, missing_submissions * 10)
    if completion_rate < 50:
        score += 18
    elif completion_rate < 70:
        score += 10
    if inactive_days >= 5:
        score += 20
    elif inactive_days >= 3:
        score += 10
    if streak == 0 and completion_rate < 70:
        score += 8
    score += min(12, rubric.failed_reviews * 6)
    score += min(18, rubric.risk_flags * 3)
    if rubric.weakest_avg is not None and rubric.weakest_avg < 3:
        score += 14
    elif rubric.weakest_avg is not None and rubric.weakest_avg < 4:
        score += 8

    score = max(0, min(100, score))
    if score >= 65:
        risk_level = "high"
    elif score >= 35:
        risk_level = "watch"
    else:
        risk_level = "stable"

    if overdue_count >= 2:
        reason = "missing deadlines"
    elif rubric.risk_flags >= 2:
        reason = "multiple low-quality submissions"
    elif rubric.weakest_avg is not None and rubric.weakest_avg < 3.2 and rubric.weakest_area:
        reason = f"weak {rubric.weakest_area.lower()}"
    elif inactive_days >= 3:
        reason = "low recent activity"
    else:
        reason = "steady progress"

    return {
        "risk_score": score,
        "risk_level": risk_level,
        "risk_reason": reason,
        "rubric_snapshot": rubric,
        "overdue_count": overdue_count,
        "missing_submissions": missing_submissions,
        "inactive_days": inactive_days,
    }


def build_study_plan(
    *,
    tasks: list[Task],
    metrics: UserMetrics | None,
) -> dict[str, Any]:
    actionable = [task for task in tasks if task.status != TaskStatus.completed]
    overdue = [task for task in actionable if _is_overdue(task)]
    due_soon = [task for task in actionable if _is_due_soon(task) and task not in overdue]
    backlog = [task for task in actionable if task not in overdue and task not in due_soon]

    prioritized = sorted(
        overdue,
        key=lambda task: (_normalize(task.due_at) or _now(), -task.difficulty_level),
    ) + sorted(
        due_soon,
        key=lambda task: (_normalize(task.due_at) or _now(), -task.difficulty_level),
    ) + sorted(
        backlog,
        key=lambda task: (_task_time_minutes(task), _normalize(task.due_at) or _now() + timedelta(days=7)),
    )

    do_now = prioritized[:2]
    do_next = prioritized[2:4]
    estimated_total = sum(_task_time_minutes(task) for task in do_now + do_next)
    rubric = summarize_rubric_health(tasks)
    energy = metrics.completion_rate if metrics else 0

    if overdue:
        focus_message = "Start with the most urgent task first so you can get back in control today."
    elif energy >= 75:
        focus_message = "You have good momentum today. Finish the priority work first, then take on one stretch task."
    elif actionable:
        focus_message = "Aim for one clear win now, then keep the next step small and focused."
    else:
        focus_message = "You are caught up today. Use the extra time to revise your strongest subject or plan ahead."

    stretch_goal = None
    if backlog:
        stretch_goal = f"If you still have energy, finish {backlog[0].title.lower()} afterward."
    elif rubric.weakest_area:
        stretch_goal = f"Use extra time to practice {rubric.weakest_area.lower()}."

    return {
        "focus_message": focus_message,
        "do_now": [_task_ref(task) for task in do_now],
        "do_next": [_task_ref(task) for task in do_next],
        "stretch_goal": stretch_goal,
        "estimated_total_minutes": estimated_total,
        "main_skill_to_improve": rubric.weakest_area,
    }


def build_rescue_plan(task: Task) -> dict[str, Any] | None:
    if not _is_overdue(task):
        return None

    title = _safe_text(task.title, "this task")
    minutes = _task_time_minutes(task)
    tone = "light restart" if task.difficulty_level <= 2 else "guided push" if task.difficulty_level <= 4 else "steady focus"

    mini_steps = [
        f"Re-read the goal for {title} and write down the first required outcome.",
        f"Work for {min(20, max(10, minutes // 2))} minutes on the easiest part first.",
        "Finish by submitting a draft or a clear partial answer today.",
    ]
    if task.requires_submission:
        mini_steps[2] = "Finish by submitting a draft response or a clear first version today."

    return {
        "mini_steps": mini_steps,
        "recommended_new_time_block": f"{max(15, min(45, minutes))}-minute recovery session tonight",
        "difficulty_tone": tone,
    }


def build_weekly_narrative(
    *,
    role: str,
    person_name: str,
    tasks: list[Task],
    metrics: UserMetrics | None,
) -> dict[str, Any]:
    week_start = _now() - timedelta(days=7)
    completed = sum(
        1
        for task in tasks
        if task.status == TaskStatus.completed and _normalize(task.updated_at) and _normalize(task.updated_at) >= week_start
    )
    created = sum(
        1 for task in tasks if _normalize(task.created_at) and _normalize(task.created_at) >= week_start
    )
    overdue = sum(1 for task in tasks if _is_overdue(task))
    rubric = summarize_rubric_health(tasks)

    strongest = rubric.strongest_area or "consistency"
    weakest = rubric.weakest_area or "follow-through"
    next_focus = f"Focus next on {weakest.lower()}."

    if role == "teacher":
        headline = f"{person_name}: weekly learning snapshot"
        summary = (
            f"Completed {completed} tasks this week, created or received {created}, "
            f"with {overdue} still overdue. Strongest area: {strongest.lower()}. Main support area: {weakest.lower()}."
        )
    elif role == "parent":
        headline = f"{person_name}: weekly family check-in"
        summary = (
            f"This week shows {completed} completed tasks and {overdue} overdue items. "
            f"The strongest signal is {strongest.lower()}, while {weakest.lower()} needs the most support."
        )
    else:
        headline = "Your weekly progress"
        summary = (
            f"You completed {completed} tasks this week and still have {overdue} overdue. "
            f"Your strongest area is {strongest.lower()}, and your biggest growth area is {weakest.lower()}."
        )

    if metrics and metrics.completion_rate >= 75:
        next_focus = f"Keep your momentum and sharpen {weakest.lower()} with one focused practice task."
    elif overdue:
        next_focus = "Clear one overdue task first, then return to your weakest skill area."

    return {
        "headline": headline,
        "summary": summary,
        "next_focus": next_focus,
    }


def build_parent_support_feed(
    *,
    child_name: str,
    tasks: list[Task],
    metrics: UserMetrics | None,
) -> dict[str, Any]:
    rubric = summarize_rubric_health(tasks)
    overdue = sum(1 for task in tasks if _is_overdue(task))
    escalated = sum(
        1
        for task in tasks
        if task.reminder is not None and getattr(task.reminder, "escalated_to_parent", False)
    )
    completion_rate = metrics.completion_rate if metrics else 0

    positive_signal = None
    if metrics and metrics.current_streak >= 3:
        positive_signal = f"{child_name} is keeping a {metrics.current_streak}-day streak."
    elif completion_rate >= 70:
        positive_signal = f"{child_name} is keeping a healthy completion rhythm."
    elif rubric.strongest_area:
        positive_signal = f"{child_name} is showing strength in {rubric.strongest_area.lower()}."

    if overdue >= 2:
        attention_signal = f"{child_name} has several unfinished tasks that need recovery support."
        action = "Help choose one overdue task to finish tonight and keep the session short."
    elif escalated:
        attention_signal = f"{child_name} has tasks that already triggered reminder escalation."
        action = "Sit together for a quick planning check and confirm the next submission time."
    elif rubric.weakest_area:
        attention_signal = f"{child_name} may need help with {rubric.weakest_area.lower()}."
        action = f"Ask {child_name.split(' ')[0]} to explain one answer out loud and add one stronger example."
    else:
        attention_signal = None
        action = "Keep encouraging a short daily study rhythm to protect momentum."

    summary = (
        f"{child_name} is doing best when the workload stays clear and structured. "
        f"{attention_signal or 'There are no urgent concerns right now.'}"
    )

    return {
        "positive_signal": positive_signal,
        "attention_signal": attention_signal,
        "recommended_action": action,
        "support_summary": summary,
    }
