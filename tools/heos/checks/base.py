"""Base check utilities shared across all checks."""

import re
import os
import subprocess
from pathlib import Path


def resolve_path(project_path: Path, given_path: str) -> Path:
    """Resolve a policy path relative to project root."""
    p = Path(given_path)
    if p.is_absolute():
        return p
    return project_path / given_path


def run_cmd(cmd: list[str], cwd: Path, timeout: int = 30) -> tuple[int, str]:
    """Run a command and return (returncode, stdout)."""
    try:
        r = subprocess.run(
            cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return r.returncode, r.stdout
    except FileNotFoundError:
        return -1, f"Command not found: {cmd[0]}"
    except subprocess.TimeoutExpired:
        return -1, "Command timed out"


def file_contains(path: Path, pattern: str) -> bool:
    """Check if a file contains a regex pattern."""
    if not path.exists():
        return False
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
        return bool(re.search(pattern, text, re.MULTILINE))
    except Exception:
        return False


def find_git_root(path: Path) -> Path | None:
    """Walk up to find .git directory."""
    for parent in [path] + list(path.parents):
        if (parent / ".git").exists():
            return parent
    return None
