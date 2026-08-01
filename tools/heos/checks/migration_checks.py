"""Migration compliance checks."""

from pathlib import Path
from .base import resolve_path, run_cmd


def migrations_applied(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that there are no un-applied migrations (makemigrations --check --dry-run)."""
    manage_py = resolve_path(project_path, params.get("manage_py", "manage.py"))

    if not manage_py.exists():
        # Try backup/ dir
        manage_py = project_path / "backend" / "manage.py"
        if not manage_py.exists():
            return False, "⚠ manage.py not found — cannot check migrations"

    python = "python3" if _is_unix() else "python"

    rc, stdout = run_cmd(
        [python, str(manage_py), "makemigrations", "--check", "--dry-run"],
        cwd=manage_py.parent,
        timeout=60,
    )

    if rc == 0:
        return True, "✓ No un-applied migrations"
    if rc == 1:
        lines = [l for l in stdout.split("\n") if l.strip()]
        return False, f"✗ Un-applied migrations detected\n" + "\n".join(lines[:5])
    return False, f"⚠ Migration check failed (rc={rc}): {stdout[:200]}"


def migration_has_rollback(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that migration files have reverse operations."""
    migrations_dir = resolve_path(project_path, params.get("migrations_dir", "migrations"))

    if not migrations_dir.is_dir():
        return False, f"⚠ migrations/ not found at {migrations_dir}"

    no_rollback = []
    for mfile in sorted(migrations_dir.glob("*.py")):
        if mfile.name == "__init__.py":
            continue
        text = mfile.read_text(encoding="utf-8", errors="replace")
        # Check for reverse migration patterns
        if "migrations.DeleteModel" in text:
            # Has a reverse
            if "RemoveField" not in text and "AddField" not in text:
                # Simple delete model — reversible by re-creating
                continue
        if "migrations.RemoveField" in text and "migrations.AddField" not in text:
            no_rollback.append(mfile.name)
        if "migrations.AlterField" in text:
            # Check if it has a reverse
            if "reverse_" not in text.lower() and "state" not in text.lower():
                no_rollback.append(mfile.name)

    if no_rollback:
        return False, f"✗ {len(no_rollback)} migrations may lack rollback: [{', '.join(no_rollback[:5])}]"
    return True, f"✓ {len(list(migrations_dir.glob('*.py'))) - 1} migrations checked"


def _is_unix() -> bool:
    import os
    return os.name == "posix"
