# Common Cron Failure Checklist

Check these FIRST before deep-diving any cron issue. Ordered by probability.

## □ Pattern 1: WSL bash missing
**Symptom:** `execvpe(/bin/bash) failed: No such file or directory`
**Root cause:** Cron resolves `bash` to WSL's `/bin/bash` (doesn't exist)
**Fix:** Convert `.sh` → `.py`. All cron scripts must be `.py`.
**Test:** Does the cron use a `.sh` script? → Convert it.

## □ Pattern 2: MSYS path mangling
**Symptom:** "no such table" / "file not found" from cron but script works standalone
**Root cause:** MSYS translates `/c/Users/...` to garbage inside `file://` URIs. `HERMES_HOME` env var is itself MSYS-mangled (`/c/Users/...`). `Path.home()` returns a Cygwin-aware path, not raw Win32.
**Fix:** Detect and convert MSYS paths with regex `^/([a-zA-Z])/(.+)` → `f"{drive}:\" / rest.replace("/", "\\")`. **Pitfall:** `Path("C:")` is relative — must be `Path("C:\\")` (escape drive root). Prefer `LOCALAPPDATA` over `Path.home()` for Hermes home; `USERPROFILE` for user home.
**Test:** Does the script use `Path.home()` or `/c/` paths? → Use env var + MSYS detection instead.
**Snippet:** See `references/msys-path-detection-pattern.md` for the full reusable pattern.

## □ Pattern 3: Unpinned agent model
**Symptom:** `HTTP 503: All providers exhausted`
**Root cause:** Agent cron has no `model`/`provider` pinned; gateway down = no route
**Fix:** Pin `model={'model': 'deepseek/deepseek-v4-flash', 'provider': 'nous'}`
**Test:** `cronjob(action='list')` — check agent crons for null model/provider fields

## □ Pattern 4: Chatty no_agent script
**Symptom:** Script sends message every run even when nothing changed
**Root cause:** Unconditional print() in a script that runs every 5 minutes
**Fix:** `if total_changes > 0: print(...)` — silent when idle
**Test:** Run the script standalone — does it print when nothing changed?

## □ Pattern 5: Wrapper anti-pattern
**Symptom:** Thin wrapper script that only passes flags to another script
**Root cause:** no_agent cron `script` field doesn't support arguments
**Fix:** Make the real script default to those flags when called with no args; delete wrapper
**Test:** Does a wrapper .sh exist that's just `python real_script.py --flag`? → Merge into real_script.py

## □ Pattern 6: Orphaned .sh scripts
**Symptom:** Old `.sh` files still in `scripts/` after conversion to `.py`
**Root cause:** Superseded scripts left behind, confusing future audits
**Fix:** Delete immediately after conversion. Only `memory-restore.sh` is kept (manual interactive).
**Test:** `ls ~/AppData/Local/hermes/scripts/*.sh` — should be empty or only memory-restore.sh

## □ Pattern 7: Over-Aggressive Schedule (Agent Crons)
**Symptom:** Agent cron runs 12x/day but the data it monitors only changes 2-3x/day
**Root cause:** Schedule set too aggressively without considering cost profile vs rate of change
**Fix:** no_agent crons can do 5-15m for watchdogs (zero token cost). Agent crons (LLM-powered) should be 6h minimum — task curation, wiki audits, and reports don't meaningfully change every 2h. For syncing/polling crons, 15-30m is sufficient; 5m floods notification channels with 288 deliveries/day.
**Test:** `cronjob(action='list')` — flag any agent cron under 360m; flag any sync/poll no_agent under 15m. Check if the human actually reads 288 deliveries/day.
**Rationale:** 2h agent cron = 12 LLM calls/day. 6h = 4 calls/day. At ~128M tokens/night budget, saving 8 calls/day per agent cron adds up.
