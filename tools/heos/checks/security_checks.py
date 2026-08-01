"""Security policy checks."""

import re
from pathlib import Path
from .base import resolve_path


SECRET_PATTERNS = [
    (r'(?i)password\s*=\s*["\'][^"\']+["\']', "hardcoded password"),
    (r'(?i)(secret_key|api_key|secret|token)\s*=\s*["\'][A-Za-z0-9+/=]{16,}["\']', "hardcoded key/token"),
    (r'(?i)postgres_password\s*=\s*["\'].+["\']', "database password"),
    (r'(?i)POSTGRES_PASSWORD\s*=\s*["\']?[^"\'\s]+["\']?', "database password (env)"),
]


def no_secrets_in_source(params: dict, project_path: Path) -> tuple[bool, str]:
    """Scan source files for hardcoded secrets."""
    extensions = params.get("extensions", [".py"])
    exclude = params.get("exclude_dirs", [])

    findings = []
    for ext in extensions:
        for fpath in project_path.rglob(f"*{ext}"):
            # Check exclusion
            rel = fpath.relative_to(project_path)
            if any(part in rel.parts for part in exclude):
                continue

            try:
                text = fpath.read_text(encoding="utf-8", errors="replace")
            except Exception:
                continue

            for pattern, desc in SECRET_PATTERNS:
                for match in re.finditer(pattern, text):
                    # Skip obvious test/fake values
                    value = match.group(0)
                    if any(ignore in value.lower() for ignore in ["test", "fake", "placeholder", "your_", "example", "change-me", "changeme"]):
                        continue
                    findings.append(f"  {rel}:{match.start()} — possible {desc}")

    if not findings:
        return True, f"✓ No secrets detected in {len(extensions)} file types"
    return False, f"✗ Found {len(findings)} potential secret(s):\n" + "\n".join(findings[:10])


def debug_disabled_in_settings(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that DEBUG is not hardcoded to True in settings."""
    settings_path = resolve_path(project_path, params.get("settings_path", ""))
    if not settings_path.exists():
        return False, f"⚠ Settings file not found at {settings_path}"

    text = settings_path.read_text(encoding="utf-8", errors="replace")

    # Look for DEBUG assignment
    debug_lines = re.findall(r'^\s*DEBUG\s*=\s*(.+)$', text, re.MULTILINE)
    if not debug_lines:
        return False, "⚠ Could not find DEBUG setting"

    for line in debug_lines:
        # DEBUG = True (hardcoded) vs DEBUG = os.getenv(...)
        if line.strip() == "True":
            return False, "✗ DEBUG is hardcoded to True — use environment variable"
        if line.strip().startswith("False"):
            return False, "⚠ DEBUG is hardcoded to False — use environment variable for production safety"
        if "os.getenv" in line or "os.environ" in line or "env(" in line:
            return True, "✓ DEBUG is controlled via environment variable"

    return False, f"⚠ Could not determine DEBUG safety: {debug_lines[0]}"


def secret_key_from_env(params: dict, project_path: Path) -> tuple[bool, str]:
    """Check that SECRET_KEY comes from environment, not hardcoded default."""
    settings_path = resolve_path(project_path, params.get("settings_path", ""))
    if not settings_path.exists():
        return False, f"⚠ Settings file not found at {settings_path}"

    text = settings_path.read_text(encoding="utf-8", errors="replace")

    # Look for SECRET_KEY assignment
    import ast

    try:
        tree = ast.parse(text)
        for node in ast.walk(tree):
            if isinstance(node, ast.Assign):
                for target in node.targets:
                    if isinstance(target, ast.Name) and target.id == "SECRET_KEY":
                        if isinstance(node.value, ast.Call):
                            func = node.value.func
                            if isinstance(func, ast.Name) and "getenv" in func.id:
                                return True, "✓ SECRET_KEY comes from environment"
                            if isinstance(func, ast.Attribute) and "getenv" in func.attr:
                                return True, "✓ SECRET_KEY comes from environment"
                        if isinstance(node.value, ast.Constant):
                            return False, "✗ SECRET_KEY is a hardcoded constant — use environment variable"
    except SyntaxError:
        pass

    return False, "⚠ Could not verify SECRET_KEY source"
