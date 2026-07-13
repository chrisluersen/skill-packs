# Fleet Routing Test Contracts

Test tasks for each routing category. Pass any of these to `fleet-manager.py` to verify correct agent dispatch.

| # | Category | Target Agent | Test Prompt |
|---|----------|-------------|-------------|
| 1 | wiki | Klio-84 | `look up in the wiki for information about the asteroid fleet dashboard` |
| 2 | search | Artemis-105 | `search for the latest news about AI agents and multi-agent systems` |
| 3 | data | Fortuna-19 | `analyze the CPU performance trends from the past month` |
| 4 | code | Metis-9 | `write a Python function to sort a list of dictionaries by a key` |
| 5 | design | Harmonia-40 | `design a color palette for a dark-mode operations dashboard` |
| 6 | devops | Atalanta-36 | `check the status of the cron jobs and report any failures` |

## Pass/Fail Criteria

- **PASS**: The correct worker agent is dispatched (visible in logs as `Pattern: SINGLE WORKER → <agent_id>`)
- **FAIL**: Wrong agent dispatched, timeout, or error before reaching Ceres-1
- **PARTIAL**: Correct agent dispatched but pipeline gate (Nemesis/Ceres) returned an acceptable rejection (e.g. missing data = data analysis correctly stopped)
