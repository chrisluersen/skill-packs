# Post-Fix Audit Pattern

> After applying fleet pipeline fixes, run a systematic self-review that catches
> stale documentation, sibling code paths, and verification gaps. A manual QA
> pass finds issues that automated tests miss.

## When to Apply

- After completing a P0/P1/P2 priority fix round
- Before declaring routing issues "resolved"
- When the user says "double check" or "make sure you did the best job possible"
- Before session closeout

## The Six-Point Audit

### 1. Re-read every file you patched

Don't trust the diff tool alone. Re-read the affected sections in context.
The diff shows what changed, but not whether the surrounding code is still coherent.

**Checklist:**
- Search for stale field references (old field names that should be gone)
- Check that ALL code paths using the same data structure are updated (publish, dispatch, prompt, log)
- Verify that skipped/removed agents are NOT in any tier set or routing table

### 2. Verify sibling code paths

> The most common pattern: you fix a data exposure in `publish()`, but the same
> key still leaks through `dispatch_to_agent()`.

**Rule:** Any payload key removed from one code path must be checked in ALL its siblings:
- `publish()` — controls what appears in logs
- `dispatch_to_agent()` — controls what the model sees in FleetEvent payload
- `_build_prompt()` — controls how the payload renders into the prompt
- Log statements — controls debugging output

**Detection:** `grep -n 'payload' <function_body_file>` will reveal all sibling paths.

### 3. Check documentation for stale statements

When you fix something, the documentation about its status becomes outdated.
If a doc says "needs re-testing" but you already tested it, that's stale.

**Scan for:**
- "Needs re-testing" / "Not yet verified" — confirm these are still true
- "Remaining issues" sections — check each is actually still open
- Checklist items — are there `[ ]` items that were already done?
- Test result tables — do they reflect current state?

### 4. Re-run the tests that previously failed

Don't assume. Run each failed test again and confirm Ceres approves.

| Test | Original Issue | After Fix | Verify |
|------|---------------|-----------|--------|
| Web search → Artemis | Misrouted / persona bleed | Should route correctly, return real results | Check Ceres approves |
| DevOps → Atalanta | No route / roleplay / too brief | Should find the service with thoroughness | Check Ceres approves |

### 5. Check every agent boots

Quick health check:

```bash
for agent in atalanta harmonia iris klio mnemosyne; do
  echo "$agent: $(timeout 30 hermes -p $agent chat -q 'respond with one word: ok' -Q 2>/dev/null | grep -vE 'Warning|session_id|Query|Initializing|Grant spent|⚠️')"
done
```

Each should respond in ~25s or under.

### 6. Update fleet-state.json

After the tests, `fleet-state.json` counters may be stale. Update:
- `total_requests` — count from log `grep "Fleet request #" ~/AppData/Local/hermes/logs/fleet-manager.log | tail -1`
- `events_published` — rough estimate
- Per-agent counters should be auto-maintained by `_record_outcome()`

## Real Example (2026-06-19)

After applying P0-P5 routing fixes and re-running tests, a self-review found:

| Issue | Where | Why Missed | Fix |
|-------|-------|-----------|-----|
| `astraea_plan` still in `dispatch_to_agent()` payload | fleet-manager.py:560 | `publish()` was fixed but sibling path wasn't | Removed from both |
| "Needs re-testing" for Artemis/Atalanta | plan doc lines 167-170 | Written before re-tests completed | Updated to "Resolved" |
| Stale checklist items | plan doc lines 339-340 | Same — written before verification | Marked `[x]` |

All three were caught by manually re-reading the plan doc and checking sibling code paths.
