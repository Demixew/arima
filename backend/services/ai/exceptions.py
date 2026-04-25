from __future__ import annotations


class AIServiceError(RuntimeError):
    """Base error for AI service failures."""


class AIConfigurationError(AIServiceError):
    """Raised when the configured provider cannot be used."""


class AIProviderUnavailableError(AIServiceError):
    """Raised when a configured external provider is unreachable or unready."""

    def __init__(self, provider: str, detail: str) -> None:
        super().__init__(detail)
        self.provider = provider
        self.detail = detail


class AIResponseError(AIServiceError):
    """Raised when a provider returns malformed or unusable output."""

    def __init__(self, provider: str, detail: str) -> None:
        super().__init__(detail)
        self.provider = provider
        self.detail = detail
