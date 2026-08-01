"""Git-related checks."""

from pathlib import Path
from .base import run_cmd


def commit_convention(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that the latest commit message follows conventional commits format."""
    rc, stdout = run_cmd(
        ["git", "log", "-1", "--pretty=%s"],
        cwd=project_path,
    )
    if rc != 0:
        return False, "⚠ Could not read git log (not a git repository?)"

    msg = stdout.strip()
    if not msg:
        return False, "⚠ No commits found"

    # Conventional commit pattern: type(scope)!: description
    import re
    pattern = r'^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\(.+\))?!?:\s.+'
    if re.match(pattern, msg):
        return True, f"✓ Latest commit follows conventional format: {msg[:60]}"
    return False, f"✗ Latest commit does not follow conventional format: {msg[:60]}"


def gitignored(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that given patterns are listed in .gitignore."""
    gitignore = project_path / ".gitignore"
    if not gitignore.exists():
        return False, "✗ No .gitignore file found"

    content = gitignore.read_text(encoding="utf-8", errors="replace")
    missing = []
    for pattern in params["patterns"]:
        if pattern not in content:
            missing.append(pattern)

    if not missing:
        return True, f"✓ All patterns [{', '.join(params['patterns'])}] present in .gitignore"
    return False, f"✗ Missing from .gitignore: [{', '.join(missing)}]"
