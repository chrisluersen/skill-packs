#!/usr/bin/env python3
"""
verify-isolated-instance.py — Verify isolated Hermes instance is properly configured
Run from ~/.hermes-private/ or pass --home path
"""

import os
import sys
import subprocess
from pathlib import Path

def run(cmd, cwd=None):
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=cwd, timeout=30)
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "", "timeout"

def check_file(path, description):
    exists = Path(path).exists()
    status = "✅" if exists else "❌"
    print(f"  {status} {description}: {path}")
    return exists

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--home", default=str(Path(os.environ.get("USERPROFILE", str(Path.home()))) / ".hermes-private"))
    args = parser.parse_args()

    home = Path(args.home).expanduser()
    config = home / "config.yaml"
    launch_script = home / "launch-private-hermes.sh"

    print(f"🔍 Verifying isolated Hermes instance at: {home}")
    print()

    all_ok = True

    # Check directory structure
    print("📁 Directory structure:")
    all_ok &= check_file(home, "Home directory")
    all_ok &= check_file(config, "Config file")
    all_ok &= check_file(launch_script, "Launch script")
    all_ok &= check_file(home / "sessions", "Sessions directory")
    all_ok &= check_file(home / "skills", "Skills directory")
    all_ok &= check_file(home / "memories", "Memories directory")
    all_ok &= check_file(home / "SOUL.md", "SOUL.md")
    all_ok &= check_file(home / "state.db", "State database")

    print()

    # Check config content
    print("⚙️  Config validation:")
    if config.exists():
        content = config.read_text()
        checks = [
            ("provider: custom", "Custom provider"),
            ("host.docker.internal:8319", "Router URL (Docker-accessible)"),
            ("backend: docker", "Docker backend"),
            ("docker_image:", "Docker image specified"),
            ("container_memory: 8192", "Memory allocation"),
        ]
        for needle, desc in checks:
            found = needle in content
            status = "✅" if found else "❌"
            print(f"  {status} {desc}")
            all_ok &= found

    print()

    # Check launch script executable
    print("🚀 Launch script:")
    if launch_script.exists():
        executable = os.access(launch_script, os.X_OK)
        status = "✅" if executable else "❌"
        print(f"  {status} Executable")
        all_ok &= executable

    # Check Docker availability
    print()
    print("🐳 Docker:")
    ok, out, _ = run("docker version --format '{{.Server.Version}}'")
    if ok:
        print(f"  ✅ Docker daemon running ({out})")
    else:
        print(f"  ❌ Docker not available")
        all_ok = False

    # Check router reachable
    print()
    print("🌐 Router connectivity:")
    ok, out, _ = run("curl -s http://localhost:8319/health")
    if ok and "ok" in out.lower():
        print(f"  ✅ Router healthy at localhost:8319")
    else:
        print(f"  ❌ Router not reachable at localhost:8319")
        all_ok = False

    print()
    if all_ok:
        print("✅ All checks passed — isolated instance ready")
        return 0
    else:
        print("❌ Some checks failed — review above")
        return 1

if __name__ == "__main__":
    sys.exit(main())