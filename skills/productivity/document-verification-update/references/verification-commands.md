# Verification Commands Reference

Quick lookup of commands to verify claims against live system state. Organized by domain.

## Hermes Agent

| Claim | Command |
|-------|---------|
| Version | `hermes --version` |
| All tool statuses + PIDs | `hermes status --all` |
| Config values (model, context, compression) | `hermes config show` |
| Skill health | `hermes curator status` |
| Active cron jobs | `hermes cron list` |
| Profile list | `hermes status` (profiles section) |

## Python

| Claim | Command |
|-------|---------|
| Python version | `python3 --version` or `python --version` |
| Pip/uv presence | `uv --version` |
| Venv active? | `echo "$VIRTUAL_ENV"` |
| Installed package | `uv pip show <pkg>` or `pip show <pkg>` |

## Node.js

| Claim | Command |
|-------|---------|
| Node version | `node --version` |
| npm version | `npm --version` |
| bun version | `bun --version` |
| Installed global | `npm list -g <pkg>` |

## Git / GitHub

| Claim | Command |
|-------|---------|
| Git version | `git --version` |
| Auth status | `gh auth status` |
| Remote URL | `git remote -v` |
| Current branch | `git branch --show-current` |

## File system

| Claim | Command |
|-------|---------|
| Path exists | `ls -la <path>` |
| File count in dir | `ls <dir> \| wc -l` |
| File size | `wc -c <path>` or `ls -lh <path>` |
| Symlink target | `readlink -f <path>` |

## System

| Claim | Command |
|-------|---------|
| OS version | `uname -a` (Linux) or `ver` (Windows cmd) |
| Disk free | `df -h .` |
| Memory | `free -h` (Linux) or `wmic OS get FreePhysicalMemory` (Win) |
| GPU | `nvidia-smi` (Linux/Win) |

## Services / processes

| Claim | Command |
|-------|---------|
| Process running | `ps aux \| grep <name>` or `tasklist /fi "PID eq <n>"` |
| Port in use | `ss -tlnp \| grep <port>` or `netstat -ano \| grep <port>` |
| Service status | `systemctl status <name>` or `sc query <name>` (Win) |
