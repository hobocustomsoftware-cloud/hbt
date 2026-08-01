"""Repository structure checks."""

from pathlib import Path


def directory_exists(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that a directory exists."""
    target = project_path / params["path"]
    if target.is_dir():
        return True, f"✓ {params['path']}/ exists"
    return False, f"✗ {params['path']}/ is missing"


def file_exists(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that a file exists."""
    target = project_path / params["path"]
    if target.is_file():
        return True, f"✓ {params['path']} exists"
    return False, f"✗ {params['path']} is missing"


def any_file_exists(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that at least one of the listed paths exists."""
    for p in params["paths"]:
        target = project_path / p
        if target.exists():
            return True, f"✓ found {p}"
    return False, f"✗ none of [{', '.join(params['paths'])}] exist"


def file_not_empty(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that a file exists and is non-empty."""
    target = project_path / params["path"]
    if target.is_file() and target.stat().st_size > 0:
        return True, f"✓ {params['path']} exists and is non-empty"
    if target.is_file() and target.stat().st_size == 0:
        return False, f"✗ {params['path']} exists but is empty (0 bytes)"
    return False, f"✗ {params['path']} is missing"


def directory_not_empty(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that a directory exists and contains at least one file."""
    target = project_path / params["path"]
    if not target.is_dir():
        return False, f"✗ {params['path']}/ is missing"
    contents = list(target.iterdir())
    if contents:
        return True, f"✓ {params['path']}/ has {len(contents)} items"
    return False, f"✗ {params['path']}/ is empty"
