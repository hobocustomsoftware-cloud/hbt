"""Dependency health checks."""

from pathlib import Path
from .base import resolve_path, run_cmd


def pip_check(params: dict, project_path: Path) -> tuple[bool, str]:
    """Run pip check to verify dependency consistency."""
    requirements = resolve_path(project_path, params.get("requirements", "requirements.txt"))

    if not requirements.exists():
        return False, f"⚠ requirements.txt not found at {requirements}"

    python = "python3" if _is_unix() else "python"

    rc, stdout = run_cmd(
        [python, "-m", "pip", "check"],
        cwd=requirements.parent,
        timeout=60,
    )

    if rc == 0:
        return True, "✓ pip check: all dependencies are consistent"
    return False, f"✗ pip check found issues:\n{stdout[:300]}"


def pip_audit(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check for known vulnerabilities in dependencies."""
    requirements = resolve_path(project_path, params.get("requirements", "requirements.txt"))

    if not requirements.exists():
        return False, f"⚠ requirements.txt not found at {requirements}"

    python = "python3" if _is_unix() else "python"

    rc, stdout = run_cmd(
        [python, "-m", "pip_audit", "-r", str(requirements)],
        cwd=requirements.parent,
        timeout=120,
    )

    if "No known vulnerabilities found" in stdout:
        return True, "✓ No known vulnerabilities in dependencies"
    if rc == 0:
        return True, "✓ pip-audit passed (no vulnerabilities found)"
    return False, f"✗ pip-audit found vulnerabilities:\n{stdout[:300]}"


def _is_unix() -> bool:
    import os
    return os.name == "posix"
