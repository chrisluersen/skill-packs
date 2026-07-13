# Plugin Lifecycle & Session Reload

## Key Fact

Hermes plugins are loaded at **session start** — not on file write, not on config change, not on cron tick. An on-disk plugin fix is NOT a live fix until a new session loads it.

## Impact

- You can verify the file is correct (`grep`, `cat`, `ast.parse`) — but the running session still uses the old code.
- This caused 3 sessions of re-corruption for the wiki insight plugin: the fix was on disk, verified correct, but the running session kept writing corrupted output because it loaded the plugin at session start before the fix was applied.
- A Gateway restart kills the running session and starts a new one — which loads the fixed plugin.

## Detection

| Check | Confirms on-disk fix | Confirms runtime fix |
|-------|---------------------|---------------------|
| `grep` the plugin file | ✅ Yes | ❌ No |
| `ast.parse` / visual inspection | ✅ Yes | ❌ No |
| Session logs show old behavior | ❌ Ambient noise | ❌ Just means old code was running |
| New behavior appears after restart | ❌ Not applicable | ✅ **Definitive** |
| `curl :8642/health` | ❌ Gateway alive ≠ plugin reload | ❌ Only confirms Gateway is up |

## The Verification Workflow

1. Apply fix to the plugin file
2. Verify on-disk with `grep` / `ast.parse` / visual inspection
3. **Restart the Gateway** — `hermes gateway run --replace` (force-kills + respawns)
4. Send a test message that triggers the plugin
5. Verify runtime behavior matches expected fix

## Why Gateway Restart?

- **CLI sessions:** `/new` or close/reopen also works — fresh session loads fresh plugins.
- **Gateway sessions (Telegram, Discord):** the gateway holds the persistent session. `hermes gateway run --replace` force-kills it and spawns a new one, which starts a fresh session with fresh plugins.
- There is no hot-reload mechanism for plugins (as of Hermes 0.18.0).

## Pitfall: The "Fixed the file, why is it still broken?" trap

The most expensive variant: you find a bug, fix the plugin code, verify the fix with grep/ast/read_file, confirm the file is perfect — but the runtime still runs the old code because the session started before the fix was applied. This looks like a recurring or intermittent bug when it's actually just stale runtime state.

**Costly lesson:** On-disk fix is necessary but NOT sufficient. Until the Gateway restarts and a new session loads the plugin, the fix is effectively inert. Always add "restart Gateway" as a verification step, not an afterthought.
