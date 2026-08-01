from dataclasses import dataclass

from django.conf import settings
from django.utils.module_loading import import_string


@dataclass(frozen=True)
class PushResult:
    accepted: bool
    provider_reference: str = ""
    permanent_failure: bool = False
    failure_reason: str = ""


class DisabledPushProvider:
    name = "disabled"

    def send(self, *, token, platform, notification):
        return PushResult(
            accepted=False,
            permanent_failure=False,
            failure_reason="Push provider is not configured.",
        )


def configured_push_provider():
    backend = getattr(
        settings,
        "PUSH_PROVIDER_BACKEND",
        "apps.notifications.push.DisabledPushProvider",
    )
    return import_string(backend)()
