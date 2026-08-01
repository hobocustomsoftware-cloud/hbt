"""HEOS CLI — policy checking, scaffolding, validation."""

import argparse
import sys
import yaml
from pathlib import Path
from importlib import import_module


CHECK_MODULES = {
    "directory_exists": "structure_checks",
    "file_exists": "structure_checks",
    "any_file_exists": "structure_checks",
    "file_not_empty": "structure_checks",
    "directory_not_empty": "structure_checks",
    "commit_convention": "git_checks",
    "gitignored": "git_checks",
    "no_secrets_in_source": "security_checks",
    "debug_disabled_in_settings": "security_checks",
    "secret_key_from_env": "security_checks",
    "migrations_applied": "migration_checks",
    "migration_has_rollback": "migration_checks",
    "pip_check": "dependency_checks",
    "pip_audit": "dependency_checks",
}


def find_heos_root() -> Path | None:
    """Find the HEOS repository root (where policies.yaml lives)."""
    candidates = [Path.cwd()] + list(Path.cwd().parents)
    for p in candidates:
        heos_dir = p / "tools" / "heos"
        if (heos_dir / "policies.yaml").exists():
            return p
    tools = Path(__file__).resolve().parent.parent.parent
    if (tools / "tools" / "heos" / "policies.yaml").exists():
        return tools
    return None


def load_policies(heos_root: Path | None = None) -> list[dict]:
    """Load policy definitions from policies.yaml."""
    if heos_root:
        policy_path = heos_root / "tools" / "heos" / "policies.yaml"
    else:
        policy_path = Path(__file__).resolve().parent / "policies.yaml"
    if not policy_path.exists():
        print(f"  Error: policies.yaml not found at {policy_path}")
        sys.exit(1)
    with open(policy_path, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data.get("policies", [])


def run_check(policy: dict, project_path: Path) -> dict:
    """Execute a single policy check."""
    check_name = policy.get("check")
    if not check_name:
        return {
            "policy": policy["id"], "severity": policy.get("severity", "error"),
            "passed": False, "message": "No check function specified",
        }
    module_name = CHECK_MODULES.get(check_name)
    if not module_name:
        return {
            "policy": policy["id"], "severity": policy.get("severity", "error"),
            "passed": False, "message": f"Unknown check: {check_name}",
        }
    try:
        mod = import_module(f"tools.heos.checks.{module_name}")
        func = getattr(mod, check_name)
    except (ImportError, AttributeError) as e:
        return {
            "policy": policy["id"], "severity": policy.get("severity", "error"),
            "passed": False, "message": f"Could not load check {check_name}: {e}",
        }
    try:
        params = policy.get("params", {})
        passed, message = func(params, project_path)
    except Exception as e:
        return {
            "policy": policy["id"], "severity": policy.get("severity", "error"),
            "passed": False, "message": f"Check threw exception: {e}",
        }
    return {
        "policy": policy["id"], "severity": policy.get("severity", "error"),
        "domain": policy.get("domain", "unknown"), "source": policy.get("source", ""),
        "description": policy.get("description", ""), "passed": passed, "message": message,
    }


def print_report(results: list[dict], verbose: bool = False):
    """Print a formatted policy check report (ASCII-safe for Windows console)."""
    total = len(results)
    passed_count = sum(1 for r in results if r["passed"])

    errors = [r for r in results if not r["passed"] and r.get("severity") == "error"]
    warnings = [r for r in results if not r["passed"] and r.get("severity") == "warning"]
    infos = [r for r in results if not r["passed"] and r.get("severity") == "info"]
    failed_count = total - passed_count

    print()
    print("=" * 70)
    print("  HEOS -- Policy Check Report")
    print("=" * 70)
    print()
    print(f"  Results: {passed_count}/{total} passed  ({failed_count} failed, {len(errors)} errors, {len(warnings)} warnings)")

    if verbose:
        domains = {}
        for r in results:
            d = r.get("domain", "unknown")
            domains.setdefault(d, {"total": 0, "passed": 0})
            domains[d]["total"] += 1
            if r["passed"]:
                domains[d]["passed"] += 1
        print()
        print("  -- Domain Summary --")
        for domain, counts in sorted(domains.items()):
            bar = "P" * counts["passed"] + "F" * (counts["total"] - counts["passed"])
            print(f"  {domain:20s}  {bar}")
    print()

    if failed_count > 0:
        print("  -- Failed Checks --")
        for r in results:
            if r["passed"]:
                continue
            tag = {"error": "FAIL", "warning": "WARN", "info": "INFO"}.get(r.get("severity"), "FAIL")
            pname = r["policy"]
            print(f"\n  [{tag}] {pname}")
            print(f"         {r.get('description', r['message'])}")
            print(f"         {r['message']}")

    if verbose:
        print()
        print("  -- All Checks --")
        for r in results:
            mark = "PASS" if r["passed"] else "FAIL" if r.get("severity") == "error" else "WARN" if r.get("severity") == "warning" else "INFO"
            msg = r["message"][:60]
            print(f"  {mark:5s} {r['policy']:20s} {r.get('domain',''):15s} {msg}")
    print()
    print("=" * 70)
    if errors:
        print("  BLOCKED - errors must be resolved before merging")
    elif warnings:
        print("  WARNINGS - review suggested items (manual approval may be required)")
    else:
        print("  PASSED - all policies satisfied")
    print("=" * 70)
    print()

    return len(errors) == 0


def cmd_check_policy(args):
    """Run all policy checks against a project."""
    project_path = Path(args.project).resolve()
    if not project_path.is_dir():
        print(f"Error: {args.project} is not a directory")
        sys.exit(1)

    print(f"HEOS Policy Check")
    print(f"  Project: {project_path}")
    print(f"  Filters: severity >= {args.min_severity}")

    heos_root = find_heos_root()
    policies = load_policies(heos_root)

    severity_order = {"info": 0, "warning": 1, "error": 2}
    min_sev = severity_order.get(args.min_severity, 0)
    filtered = [p for p in policies if severity_order.get(p.get("severity", "error"), 0) >= min_sev]

    if args.domain:
        filtered = [p for p in filtered if p.get("domain") == args.domain]
        print(f"  Domain:  {args.domain}")

    if not filtered:
        print("No policies match the filter criteria.")
        sys.exit(0)

    print(f"  Policies: {len(filtered)}")
    print()

    results = []
    for policy in filtered:
        result = run_check(policy, project_path)
        results.append(result)

    all_ok = print_report(results, verbose=args.verbose)
    sys.exit(0 if all_ok else 1)


def cmd_list_policies(args):
    """List all available policies."""
    heos_root = find_heos_root()
    policies = load_policies(heos_root)

    print()
    print(f"HEOS Policies ({len(policies)} total)")
    print("=" * 70)

    by_domain: dict[str, list[dict]] = {}
    for p in policies:
        domain = p.get("domain", "other")
        by_domain.setdefault(domain, []).append(p)

    for domain, pols in sorted(by_domain.items()):
        print(f"\n  [{domain}]")
        for p in pols:
            tag = {"error": "ERR", "warning": "WRN", "info": "INF"}.get(p.get("severity"), "???")
            desc = p.get("description", "")[:70]
            print(f"    [{tag}] {p['id']:20s} {desc}")

    print()
    print(f"  Use: python -m tools.heos check policy --domain <domain>")
    print()


def cmd_init(args):
    """Initialize HEOS in a project."""
    project_path = Path(args.project).resolve()
    print()
    print(f"HEOS Init -- {project_path}")
    print("=" * 50)

    heos_target = project_path / "tools" / "heos"
    heos_target.mkdir(parents=True, exist_ok=True)
    (project_path / "tools").mkdir(parents=True, exist_ok=True)

    print(f"  Created: tools/heos/")
    print()
    print(f"  To enable HEOS governance in this project:")
    print(f"    1. Copy policies.yaml from HEOS root")
    print(f"    2. Add to CI: python -m tools.heos check policy")
    print()
    print("  HEOS initialized.")
    print()


def main():
    parser = argparse.ArgumentParser(
        description="HEOS -- HoBo Engineering Operating System CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python -m tools.heos check policy
  python -m tools.heos check policy --project D:\\hobosaas-project
  python -m tools.heos check policy --domain git --min-severity warning
  python -m tools.heos list policies
  python -m tools.heos init --project .
        """,
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed output")

    sub = parser.add_subparsers(dest="command", help="Available commands")

    check = sub.add_parser("check", help="Run checks against a project")
    check_sub = check.add_subparsers(dest="check_command", help="Check type")
    cp = check_sub.add_parser("policy", help="Check project against HEOS policies")
    cp.add_argument("--project", default=".", help="Project directory to check (default: cwd)")
    cp.add_argument("--min-severity", choices=["info", "warning", "error"], default="info", help="Minimum severity to report")
    cp.add_argument("--domain", choices=["structure", "git", "security", "migration", "documentation", "config", "dependencies"], help="Filter checks to a specific domain")

    sub.add_parser("list", help="List available policies")

    init = sub.add_parser("init", help="Initialize HEOS in a project")
    init.add_argument("--project", default=".", help="Project directory")

    args = parser.parse_args()

    if args.command == "check":
        if args.check_command == "policy":
            cmd_check_policy(args)
        else:
            print("Unknown check type. Use: heos check policy [options]")
            sys.exit(1)
    elif args.command == "list":
        cmd_list_policies(args)
    elif args.command == "init":
        cmd_init(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
