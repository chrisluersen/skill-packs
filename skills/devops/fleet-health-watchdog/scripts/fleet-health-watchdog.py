#!/usr/bin/env python3
"""Fleet health watchdog — runs fleet-manager.py health checks and alerts on failures.

Usage: python fleet-health-watchdog.py

Returns:
  Empty stdout (no output) if fleet is healthy.
  Status lines if any agent has issues (CB tripped, agent down, etc.).
"""

import os
import subprocess
import sys
import re
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
# Resolve relative to where fleet-manager.py lives
FLEET_MANAGER = Path(os.environ.get("LOCALAPPDATA", str(Path.home() / "AppData" / "Local"))) / "hermes" / "scripts" / "fleet-manager.py"


def run_flag(flag: str, timeout: int = 30) -> str:
    """Run fleet-manager.py with a flag and return stdout."""
    result = subprocess.run(
        [sys.executable, str(FLEET_MANAGER), flag],
        capture_output=True, text=True, timeout=timeout
    )
    return result.stdout


def check_cb_status():
    """Parse --cb-status output for OPEN circuit breakers."""
    out = run_flag("--cb-status", timeout=15)

    issues = []
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        if "OPEN" in line or "HALF_OPEN" in line:
            issues.append(f"⚠️  CB: {line}")

    return issues


def check_status():
    """Parse --status output for quarantines, halt, or errors."""
    out = run_flag("--status", timeout=15)

    issues = []
    # Check for quarantined agents
    q_match = re.search(r"Quarantines:?\s*(\d+)", out)
    if q_match and int(q_match.group(1)) > 0:
        issues.append(f"⚠️  {q_match.group(0)} — some agents may be down")

    # Check for maintenance mode
    if re.search(r"Maintenance.*ON", out):
        issues.append("⚠️  Fleet is in MAINTENANCE mode — no dispatches running")

    return issues


def main():
    try:
        cb_issues = check_cb_status()
        status_issues = check_status()
    except subprocess.TimeoutExpired:
        print("❌ Fleet health check TIMED OUT — fleet-manager.py may be stuck")
        sys.exit(1)
    except FileNotFoundError:
        print(f"❌ Fleet health check FAILED — fleet-manager.py not found at {FLEET_MANAGER}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Fleet health check ERROR: {e}")
        sys.exit(1)

    all_issues = cb_issues + status_issues

    if all_issues:
        print("📡 Fleet Health Alert:")
        for issue in all_issues:
            print(f"  {issue}")
        sys.exit(0)

    # Silent = healthy (no notification via cron)


if __name__ == "__main__":
    main()
