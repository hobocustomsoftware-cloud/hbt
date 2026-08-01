import shlex
# The antivirus integration intentionally invokes a fixed-argv child process.
import subprocess  # nosec B404
import tempfile
from pathlib import Path

from django.conf import settings
from django.core.exceptions import ValidationError


def scan_upload(upload):
    """Run the configured malware scanner and always restore the upload cursor."""
    command = getattr(settings, "MALWARE_SCAN_COMMAND", "").strip()
    required = getattr(settings, "MALWARE_SCAN_REQUIRED", False)
    if not command:
        if required:
            raise ValidationError("File scanning is unavailable.")
        return upload

    suffix = Path(upload.name).suffix[:16]
    position = upload.tell() if hasattr(upload, "tell") else 0
    try:
        with tempfile.NamedTemporaryFile(suffix=suffix) as temporary:
            for chunk in upload.chunks():
                temporary.write(chunk)
            temporary.flush()
            # The command is administrator-configured argv and never uses a shell.
            result = subprocess.run(  # nosec B603
                [*shlex.split(command), temporary.name],
                capture_output=True,
                text=True,
                timeout=settings.MALWARE_SCAN_TIMEOUT_SECONDS,
                check=False,
            )
        if result.returncode != 0:
            raise ValidationError("The uploaded file failed security scanning.")
    except (OSError, subprocess.TimeoutExpired) as exc:
        if required:
            raise ValidationError("File security scanning failed.") from exc
    finally:
        if hasattr(upload, "seek"):
            upload.seek(position)
    return upload
