# Fleet Health Watchdog — Silent Monitoring Cron

## What

A `no_agent=True` cron job that monitors the fleet's health every 30 minutes.
- **Silent when healthy** — no output = no notification (0 tokens spent)
- **Alerts on problems** — CB trips, quarantines, maintenance mode

## Files

- `fleet-health-watchdog.py` at `~\AppData\Local\hermes\scripts\fleet-health-watchdog.py`
- Cron job: `fleet-health-watchdog` (job_id: `ef69645802eb`)

## What It Checks

1. `--cb-status` — scans for OPEN or HALF_OPEN circuit breakers
2. `--status` — checks for quarantined agents, maintenance mode

## Cron Config

```
no_agent=True           # LLM is NOT invoked — the script IS the job
schedule: every 30m     # Frequent enough to catch acute failures
deliver: origin         # Delivers to the current conversation
```

## How It Works

```python
# no_agent=True semantics:
# - Empty stdout → SILENT (no notification)
# - Non-empty stdout → delivered as-is to user
# - Non-zero exit → error alert

def main():
    try:
        cb_issues = check_cb_status()
        status_issues = check_status()
    except TimeoutExpired:
        print("❌ Health check TIMED OUT")
        sys.exit(1)

    all_issues = cb_issues + status_issues
    if all_issues:
        print("📡 Fleet Health Alert:")
        for issue in all_issues:
            print(f"  {issue}")
    # else: silent (healthy)
```

## Verification

```bash
cd ~/AppData/Local/hermes/scripts
timeout 30 python fleet-health-watchdog.py
# No output = healthy
```

## Pitfalls

- Each subprocess call creates a new HermesFleetManager, so no state persists. The watchdog checks the current snapshot — it doesn't track trends.
- The watchdog uses `subprocess.run` with `capture_output=True`. Console output from fleet-manager.py goes to stderr (logging) while structured output goes to stdout. The watchdog only reads stdout.
- If fleet-manager.py hangs (stuck on a background task), the watchdog's 15s timeout per flag will catch it as an error.
