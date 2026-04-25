from __future__ import annotations

import ast
import json
import random
import re
from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

import httpx

from backend.core.config import Settings
from backend.services.ai.exceptions import AIConfigurationError, AIProviderUnavailableError, AIResponseError


def _normalize_text(value: str, limit: int) -> str:
    return re.sub(r"\s+", " ", value).strip()[:limit]


def _extract_criteria_list(evaluation_criteria: str | None) -> list[str]:
    if not evaluation_criteria:
        return []

    parts = re.split(r"[\n,;]+", evaluation_criteria)
    cleaned = [_normalize_text(part, 120) for part in parts if _normalize_text(part, 120)]
    return cleaned[:4]


def _sentence(value: str) -> str:
    value = value.strip()
    if not value:
        return ""
    return value if value.endswith((".", "!", "?")) else f"{value}."


def _build_builtin_task_title(prompt_text: str, student_name: str) -> str:
    if not prompt_text:
        return f"Практическое задание для {student_name}"

    cleaned = prompt_text.strip()
    if len(cleaned) <= 60:
        return cleaned[:1].upper() + cleaned[1:]
    return cleaned[:57].rstrip() + "..."


def _build_builtin_task_description(
    *,
    prompt_text: str,
    estimated_time: int,
    anti_fatigue_enabled: bool,
    difficulty: int,
) -> str:
    prompt_lower = prompt_text.lower()

    if "скороговор" in prompt_lower:
        parts = [
            "Прочитай скороговорку и затем попробуй повторить ее 3 раза без ошибок: «Шла Саша по шоссе и сосала сушку».",
            "После этого придумай и запиши свою собственную короткую скороговорку из 1-2 предложений.",
            "Используй повторяющиеся похожие звуки или сложные сочетания букв.",
            "Сдай именно готовую скороговорку, а не план или объяснение.",
        ]
    elif any(word in prompt_lower for word in ["арифмет", "пример", "сложен", "вычит", "умнож", "делен"]):
        max_value = {1: 10, 2: 20, 3: 50, 4: 100, 5: 200}.get(difficulty, 20)
        operations = ["+", "-"] if difficulty <= 2 else ["+", "-", "*"]
        count = 6 if difficulty <= 2 else 8 if difficulty == 3 else 10
        seed = sum(ord(ch) for ch in prompt_text) or 17
        rng = random.Random(seed)
        examples: list[str] = []
        for index in range(count):
            operation = operations[index % len(operations)] if difficulty <= 3 else rng.choice(operations)
            if operation == "+":
                a = rng.randint(1, max_value)
                b = rng.randint(1, max_value)
            elif operation == "-":
                a = rng.randint(2, max_value)
                b = rng.randint(1, a)
            else:
                a = rng.randint(2, min(12, max_value))
                b = rng.randint(2, min(12, max_value))
            examples.append(f"{index + 1}) {a} {operation} {b} =")

        parts = [
            "Реши примеры и запиши ответы аккуратно в тетрадь.",
            "Сами примеры для решения:",
            " ".join(examples),
            "Сдай готовые ответы на все примеры.",
        ]
    elif any(word in prompt_lower for word in ["стих", "рифм", "поэм"]):
        parts = [
            "Напиши короткий авторский текст в стихах по заданной теме.",
            "Сделай текст понятным, аккуратным и завершенным.",
            "Сдай готовый стих, а не черновые идеи.",
        ]
    elif any(word in prompt_lower for word in ["рассказ", "истори", "сочинен"]):
        parts = [
            f"Подготовь готовый текст по теме: {prompt_text}.",
            "У текста должно быть понятное начало, основная часть и завершение.",
            "Сдай уже оформленный ответ, а не только набросок.",
        ]
    else:
        action = (
            _sentence(prompt_text[:1].upper() + prompt_text[1:])
            if prompt_text
            else "Выполни короткое практическое задание."
        )
        parts = [
            action,
            "Ответ должен быть конкретным и готовым к сдаче.",
            "Не присылай план выполнения вместо результата.",
        ]

    parts.append(f"Постарайся уложиться примерно в {estimated_time} минут.")
    if anti_fatigue_enabled:
        parts.append("Если задание кажется сложным, выполни его по шагам и делай короткие паузы.")

    return " ".join(parts)


def _extract_json_object(content: str, *, provider: str) -> dict[str, Any]:
    start = content.find("{")
    end = content.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise AIResponseError(provider, "Model response does not contain JSON")

    raw = content[start : end + 1].strip()
    candidates = [raw]
    normalized_quotes = (
        raw.replace("“", '"')
        .replace("”", '"')
        .replace("‘", "'")
        .replace("’", "'")
        .replace("\u00a0", " ")
    )
    if normalized_quotes != raw:
        candidates.append(normalized_quotes)

    trailing_commas_fixed = re.sub(r",\s*([}\]])", r"\1", normalized_quotes)
    if trailing_commas_fixed not in candidates:
        candidates.append(trailing_commas_fixed)

    for candidate in candidates:
        try:
            parsed = json.loads(candidate)
        except json.JSONDecodeError:
            try:
                python_like = re.sub(r"\btrue\b", "True", candidate, flags=re.IGNORECASE)
                python_like = re.sub(r"\bfalse\b", "False", python_like, flags=re.IGNORECASE)
                python_like = re.sub(r"\bnull\b", "None", python_like, flags=re.IGNORECASE)
                parsed = ast.literal_eval(python_like)
            except (ValueError, SyntaxError):
                continue

        if isinstance(parsed, dict):
            return parsed

    try:
        parsed = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise AIResponseError(provider, "Model response was not valid JSON") from exc

    if not isinstance(parsed, dict):
        raise AIResponseError(provider, "Model response JSON must be an object")
    return parsed


@dataclass(frozen=True)
class AIProviderStatus:
    provider: str
    provider_label: str
    ready: bool
    model: str
    detail: str
    endpoint: str = ""


class AIProvider(ABC):
    provider_name: str
    provider_label: str

    @abstractmethod
    async def status(self) -> AIProviderStatus:
        raise NotImplementedError

    @abstractmethod
    async def generate_task_draft(
        self,
        *,
        teacher_name: str,
        student_name: str,
        prompt: str,
        completion_rate: int | None,
        current_streak: int | None,
        total_completed: int | None,
        total_created: int | None,
        difficulty_level: int | None = None,
        estimated_time_minutes: int | None = None,
    ) -> dict[str, Any]:
        raise NotImplementedError

    @abstractmethod
    async def evaluate_submission(
        self,
        *,
        student_name: str,
        task_title: str,
        task_description: str | None,
        evaluation_criteria: str | None,
        submission_text: str | None,
    ) -> dict[str, Any]:
        raise NotImplementedError


class BuiltinProvider(AIProvider):
    provider_name = "builtin"
    provider_label = "Built-in"

    async def status(self) -> AIProviderStatus:
        return AIProviderStatus(
            provider=self.provider_name,
            provider_label=self.provider_label,
            ready=True,
            model="builtin-smart",
            detail="Built-in draft and review generation is available.",
        )

    async def generate_task_draft(
        self,
        *,
        teacher_name: str,
        student_name: str,
        prompt: str,
        completion_rate: int | None,
        current_streak: int | None,
        total_completed: int | None,
        total_created: int | None,
        difficulty_level: int | None = None,
        estimated_time_minutes: int | None = None,
    ) -> dict[str, Any]:
        prompt_text = _normalize_text(prompt, 140)
        title = _build_builtin_task_title(prompt_text, student_name)

        motivation_hint = "keep it short and supportive"
        difficulty = difficulty_level or 2
        estimated_time = estimated_time_minutes or 15
        anti_fatigue_enabled = False

        if completion_rate is not None:
            if completion_rate < 50:
                motivation_hint = "keep it very simple and encouraging"
                difficulty = 1
                estimated_time = 10
                anti_fatigue_enabled = True
            elif completion_rate < 80:
                motivation_hint = "balance challenge with confidence"
                difficulty = max(2, difficulty)
                estimated_time = max(15, estimated_time)
            else:
                motivation_hint = "make it slightly more challenging"
                difficulty = min(5, max(difficulty, 4))
                estimated_time = max(20, estimated_time)

        description = _build_builtin_task_description(
            prompt_text=prompt_text or "короткое практическое задание",
            estimated_time=estimated_time,
            anti_fatigue_enabled=anti_fatigue_enabled,
            difficulty=difficulty,
        )
        return {
            "title": title,
            "description": _normalize_text(description, 4000),
            "requires_submission": True,
            "difficulty_level": max(1, min(5, difficulty)),
            "estimated_time_minutes": estimated_time,
            "anti_fatigue_enabled": anti_fatigue_enabled,
            "model": "builtin-smart",
            "provider": self.provider_name,
        }

    async def evaluate_submission(
        self,
        *,
        student_name: str,
        task_title: str,
        task_description: str | None,
        evaluation_criteria: str | None,
        submission_text: str | None,
    ) -> dict[str, Any]:
        text = _normalize_text(submission_text or "", 4000)
        words = [word for word in text.split(" ") if word]
        word_count = len(words)
        criteria_list = _extract_criteria_list(evaluation_criteria)
        criteria_bonus = 1 if evaluation_criteria else 0
        topical_bonus = 1 if task_title and any(token.lower() in text.lower() for token in task_title.split()) else 0
        base_grade = 1 if word_count < 20 else 3 if word_count < 60 else 4
        grade = max(1, min(5, base_grade + criteria_bonus + topical_bonus - 1))
        score_percent = max(20, min(100, (grade * 20) + (5 if word_count > 40 else 0)))
        confidence = 88 if word_count > 40 else 76 if word_count > 15 else 62
        strengths: list[str] = []
        improvements: list[str] = []
        risk_flags: list[str] = []

        if word_count == 0:
            feedback = "No answer was submitted. Please add a short response."
            grade = 1
            score_percent = 10
            confidence = 95
            improvements.append("Submit a written answer so the work can be assessed.")
            risk_flags.append("No meaningful answer was submitted.")
        elif grade >= 5:
            feedback = (
                f"Strong work, {student_name}. The response is clear, complete, and stays focused on the task."
            )
            strengths.extend(
                [
                    "The answer stays focused on the task.",
                    "The response is complete and easy to follow.",
                ]
            )
            improvements.append("Add one extra detail or example to make it even stronger.")
        elif grade >= 4:
            feedback = (
                "Good work. The answer is understandable and mostly complete. Add a little more detail or examples to strengthen it."
            )
            strengths.extend(
                [
                    "The main idea is clear.",
                    "The answer covers most of the task.",
                ]
            )
            improvements.append("Add one more concrete example or explanation.")
        elif grade == 3:
            feedback = (
                "This is a solid start. Improve structure and add more direct evidence that you followed the task requirements."
            )
            strengths.append("The response shows a basic understanding of the task.")
            improvements.extend(
                [
                    "Organize the answer more clearly.",
                    "Use the task criteria as a checklist before submitting.",
                ]
            )
        else:
            feedback = (
                "The answer needs more detail and clarity. Try to respond step by step and use the criteria as a checklist."
            )
            improvements.extend(
                [
                    "Add more detail so the idea is easier to understand.",
                    "Answer step by step and cover each task requirement.",
                ]
            )

        if word_count < 25:
            risk_flags.append("The answer may be too short for a full assessment.")
        if evaluation_criteria and len(criteria_list) > 1 and word_count < 45:
            risk_flags.append("Some rubric criteria may not be fully addressed.")
        if task_title and not any(token.lower() in text.lower() for token in task_title.split()[:2]):
            risk_flags.append("The answer may be drifting away from the main task focus.")

        rubric_names = criteria_list or ["Task fit", "Clarity", "Detail"]
        rubric = []
        for index, criterion in enumerate(rubric_names[:4]):
            criterion_score = max(1, min(5, grade - (1 if index > 1 and word_count < 35 else 0)))
            rubric.append(
                {
                    "criterion": criterion,
                    "score": criterion_score,
                    "max_score": 5,
                    "comment": (
                        "This part looks strong."
                        if criterion_score >= 4
                        else "This part needs more support and detail."
                    ),
                }
            )
        weakest_area = rubric[0]["criterion"] if rubric else "clarity"
        if rubric:
            weakest_area = min(rubric, key=lambda item: item["score"])["criterion"]

        next_task = {
            "title": f"Follow-up practice on {weakest_area}",
            "prompt": f"Create a short follow-up activity that helps {student_name} improve in {weakest_area.lower()} for the task '{task_title}'.",
            "focus_reason": f"This area looked weakest in the latest submission: {weakest_area}.",
            "difficulty_level": max(1, min(5, grade)),
            "estimated_time_minutes": 10 if grade <= 2 else 15 if grade <= 4 else 20,
        }

        return {
            "grade": grade,
            "score_percent": score_percent,
            "confidence": confidence,
            "rating_label": {
                5: "Excellent",
                4: "Strong",
                3: "Developing",
                2: "Needs support",
                1: "Incomplete",
            }[grade],
            "feedback": _normalize_text(feedback, 4000),
            "strengths": strengths[:3],
            "improvements": improvements[:3],
            "risk_flags": risk_flags[:4],
            "rubric": rubric,
            "next_task": next_task,
            "model": "builtin-smart",
            "provider": self.provider_name,
            "checked_at": datetime.now(timezone.utc),
        }


class _ExternalJsonProvider(AIProvider):
    timeout: float = 90.0

    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    @staticmethod
    def _build_ollama_prompt(*, system_prompt: str, user_prompt: str) -> str:
        return (
            f"{system_prompt}\n\n"
            "Do not show your thinking.\n"
            "Do not add markdown fences.\n"
            "Return exactly one valid JSON object.\n\n"
            f"{user_prompt}"
        )

    async def _call_json(
        self,
        *,
        url: str,
        headers: dict[str, str] | None,
        payload: dict[str, Any],
        provider: str,
    ) -> dict[str, Any]:
        try:
            async with httpx.AsyncClient(timeout=self.timeout, trust_env=False) as client:
                response = await client.post(url, headers=headers, json=payload)
                response.raise_for_status()
        except httpx.HTTPStatusError as exc:
            detail = str(exc)
            response_text = exc.response.text.strip() if exc.response is not None else ""
            if provider == "ollama" and exc.response is not None and exc.response.status_code >= 500:
                detail = (
                    "Ollama accepted the request but failed during model inference. "
                    "This usually means the selected model/runtime is unstable on the current machine. "
                    "Try restarting Ollama and switching to a smaller model such as `qwen2.5:3b`."
                )
                if response_text:
                    detail = f"{detail} Ollama said: {response_text[:240]}"
            elif response_text:
                detail = f"{detail}: {response_text[:240]}"
            raise AIProviderUnavailableError(provider, detail) from exc
        except httpx.HTTPError as exc:
            raise AIProviderUnavailableError(provider, str(exc)) from exc

        data = response.json()
        if provider == "ollama":
            content = ""
            if isinstance(data, dict):
                content = str(data.get("response", "")).strip()
                if not content:
                    content = str(data.get("message", {}).get("content", "")).strip()

            if not content:
                raise AIResponseError(provider, "Ollama returned no usable response text")
        else:
            try:
                content = data["choices"][0]["message"]["content"]
            except (KeyError, IndexError, TypeError) as exc:
                raise AIResponseError(provider, "Invalid OpenAI-compatible response format") from exc

        return _extract_json_object(str(content), provider=provider)


class OllamaProvider(_ExternalJsonProvider):
    provider_name = "ollama"
    provider_label = "Ollama"

    @property
    def model(self) -> str:
        return self.settings.resolved_ai_model

    @property
    def endpoint(self) -> str:
        return self.settings.ollama_url.rstrip("/")

    async def status(self) -> AIProviderStatus:
        try:
            async with httpx.AsyncClient(timeout=5.0, trust_env=False) as client:
                response = await client.get(f"{self.endpoint}/api/tags")
                response.raise_for_status()
        except httpx.HTTPError as exc:
            return AIProviderStatus(
                provider=self.provider_name,
                provider_label=self.provider_label,
                ready=False,
                model=self.model,
                detail=f"Ollama is unreachable: {exc}. Start Ollama with `ollama serve`.",
                endpoint=self.endpoint,
            )

        data = response.json()
        models = [
            item.get("name", "")
            for item in data.get("models", [])
            if isinstance(item, dict) and item.get("name")
        ]
        ready = self.model in models
        detail = (
            "Ollama is reachable and the configured model is installed. Generation can still fail if the machine does not have enough memory for this model."
            if ready
            else f"Ollama is running, but model '{self.model}' is not available. Pull it with `ollama pull {self.model}`."
        )
        return AIProviderStatus(
            provider=self.provider_name,
            provider_label=self.provider_label,
            ready=ready,
            model=self.model,
            detail=detail,
            endpoint=self.endpoint,
        )

    async def generate_task_draft(
        self,
        *,
        teacher_name: str,
        student_name: str,
        prompt: str,
        completion_rate: int | None,
        current_streak: int | None,
        total_completed: int | None,
        total_created: int | None,
        difficulty_level: int | None = None,
        estimated_time_minutes: int | None = None,
    ) -> dict[str, Any]:
        system_prompt = (
            "Ты создаешь готовые школьные задания для ученика. "
            "Return only valid JSON with keys: title, description, requires_submission, "
            "difficulty_level, estimated_time_minutes, anti_fatigue_enabled. "
            "Write the result as the final task card the student will see. "
            "ВАЖНО: нужно создать само содержимое задания, а не инструкцию в общем виде. "
            "Если учитель просит арифметические примеры, ты должен написать сами примеры. "
            "Если учитель просит скороговорку, ты должен написать конкретную скороговорку или набор скороговорок. "
            "Если учитель просит слова, вопросы, предложения, текст, примеры или упражнения, ты должен включить их прямо в description. "
            "Do not write a lesson introduction, teacher greeting, motivational speech, or explanation of what you are doing. "
            "Do not write phrases like 'Today we will', 'Let's start', 'Hello', 'Dear student', or 'We begin'. "
            "Do not write a template. Do not describe the learning process. "
            "The title must be short and specific. "
            "The description must contain the actual exercise content plus short instructions on what to submit. "
            "If the teacher asks to create something, the task must tell the student exactly what to create and what constraints to follow. "
            "The description must be 2 to 6 short sentences, student-facing, clear, and immediately actionable. "
            "requires_submission must be a boolean. "
            "difficulty_level must be an integer from 1 to 5. "
            "estimated_time_minutes must be an integer if possible. "
            "anti_fatigue_enabled must be a boolean. "
            "Good example: 'Реши примеры: 1) 7 + 5 = 2) 13 - 4 = 3) 6 + 8 = ... Запиши ответы и сдай решение.' "
            "Bad example: 'Реши 10 примеров по арифметике.'"
        )
        user_prompt = (
            f"Учитель: {teacher_name}\n"
            f"Ученик: {student_name}\n"
            f"Запрос учителя: {prompt}\n"
            f"Успешность ученика: {completion_rate if completion_rate is not None else 'unknown'}%\n"
            f"Текущая серия: {current_streak if current_streak is not None else 'unknown'} дней\n"
            f"Выполнено задач: {total_completed if total_completed is not None else 'unknown'}\n"
            f"Создано задач: {total_created if total_created is not None else 'unknown'}\n"
            f"Желаемая сложность: {difficulty_level if difficulty_level is not None else 'auto'}\n"
            f"Желаемое время: {estimated_time_minutes if estimated_time_minutes is not None else 'auto'} минут\n"
            "Сгенерируй одно конкретное задание. "
            "Ученик должен сразу увидеть содержимое задания, а не общую формулировку. "
            "Если это арифметика, вставь сами примеры. "
            "Если это русский язык, вставь сами слова, предложения, скороговорки или упражнения. "
            "Если это творческое задание, дай конкретную тему, ограничения и ожидаемый результат. "
            "В конце коротко укажи, что нужно сдать. "
            "Если успешность низкая, упростить задание и снизить перегрузку. "
            "Если успешность высокая, можно сделать немного сложнее."
        )
        parsed = await self._call_json(
            url=f"{self.endpoint}/api/generate",
            headers=None,
            payload={
                "model": self.model,
                "prompt": self._build_ollama_prompt(system_prompt=system_prompt, user_prompt=user_prompt),
                "stream": False,
                "think": False,
                "format": "json",
                "options": {
                    "temperature": 0.15,
                    "num_predict": 180,
                },
            },
            provider=self.provider_name,
        )
        return parsed

    async def evaluate_submission(
        self,
        *,
        student_name: str,
        task_title: str,
        task_description: str | None,
        evaluation_criteria: str | None,
        submission_text: str | None,
    ) -> dict[str, Any]:
        if not submission_text or not submission_text.strip():
            raise AIConfigurationError("Submission text is required for AI review")

        system_prompt = (
            "You are an educational assistant that grades school submissions. "
            "Return only valid JSON with keys: "
            "grade, score_percent, confidence, rating_label, strengths, improvements, risk_flags, rubric, next_task, feedback. "
            "Grade must be an integer from 1 to 5. "
            "score_percent must be an integer from 0 to 100. "
            "confidence must be an integer from 0 to 100. "
            "rating_label must be a short rating phrase. "
            "strengths must be an array of 1 to 3 short strings. "
            "improvements must be an array of 1 to 3 short strings. "
            "risk_flags must be an array of 0 to 4 short strings about review uncertainty or concerns. "
            "rubric must be an array of 2 to 4 objects with keys: criterion, score, max_score, comment. "
            "next_task must be an object with keys: title, prompt, focus_reason, difficulty_level, estimated_time_minutes. "
            "Use this grading scale: 5 = excellent, 4 = strong, 3 = acceptable, "
            "2 = weak, 1 = missing or seriously incorrect. "
            "Feedback must be short, constructive, specific, and written for a student. "
            "Keep feedback to 2 or 3 sentences. "
            "Return one compact JSON object only, with no markdown and no extra text. "
            "Even for a very short student answer, you must still return valid JSON. "
            "Example of valid shape: "
            '{"grade":3,"score_percent":60,"confidence":74,"rating_label":"Developing","strengths":["Main idea is present"],"improvements":["Add one more step of explanation"],"risk_flags":["The answer is short, so confidence is lower"],"rubric":[{"criterion":"Clarity","score":3,"max_score":5,"comment":"Understandable but brief"}],"next_task":{"title":"Short follow-up","prompt":"Solve 3 similar examples and show the steps.","focus_reason":"More practice is needed","difficulty_level":2,"estimated_time_minutes":10},"feedback":"Good start. Add a little more detail so the answer is easier to check."}'
        )
        criteria_list = _extract_criteria_list(evaluation_criteria)
        criteria_text = (
            "\n".join(f"- {criterion}" for criterion in criteria_list)
            if criteria_list
            else "- General correctness\n- Clarity\n- Effort"
        )
        user_prompt = (
            f"Student: {student_name}\n"
            f"Task title: {task_title}\n"
            f"Task description: {task_description or 'No description'}\n"
            f"Evaluation criteria:\n{criteria_text}\n"
            f"Submission: {submission_text}\n"
            "Evaluate the submission fairly for a school setting. "
            "If the work is incomplete, explain what is missing. "
            "If it is strong, mention one specific strength. "
            "If evaluation criteria are given, reflect them directly in the rubric. "
            "Risk flags should only be included when there is a real concern such as brevity, off-topic content, weak evidence, or low confidence. "
            "Use next_task to suggest one short personalized follow-up task based on the weakest rubric area. "
            "Do not return commentary outside JSON. "
            "Do not surround the JSON with markdown fences."
        )
        parsed = await self._call_json(
            url=f"{self.endpoint}/api/generate",
            headers=None,
            payload={
                "model": self.model,
                "prompt": self._build_ollama_prompt(system_prompt=system_prompt, user_prompt=user_prompt),
                "stream": False,
                "think": False,
                "format": "json",
                "options": {
                    "temperature": 0.1,
                    "num_predict": 200,
                },
            },
            provider=self.provider_name,
        )

        try:
            grade = int(parsed.get("grade"))
        except (TypeError, ValueError) as exc:
            raise AIResponseError(self.provider_name, "External AI returned an invalid grade") from exc

        feedback = str(parsed.get("feedback", "")).strip()
        if not feedback or grade < 1 or grade > 5:
            raise AIResponseError(self.provider_name, "External AI returned an incomplete review")

        return {
            "grade": grade,
            "score_percent": parsed.get("score_percent"),
            "confidence": parsed.get("confidence"),
            "rating_label": parsed.get("rating_label"),
            "feedback": feedback[:4000],
            "strengths": parsed.get("strengths", []),
            "improvements": parsed.get("improvements", []),
            "risk_flags": parsed.get("risk_flags", []),
            "rubric": parsed.get("rubric", []),
            "next_task": parsed.get("next_task"),
            "model": self.model,
            "provider": self.provider_name,
            "checked_at": datetime.now(timezone.utc),
        }
