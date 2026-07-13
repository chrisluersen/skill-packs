# Combined MCP Server Pattern

## Rationale

Multiple MCP servers on the same host create a double-spawn problem: Hermes independently resolves each server's `command:` entry against every Python interpreter on PATH. With 2 servers (fleet + wiki) and 2 interpreters (venv + uv), Hermes spawns 4 processes. Each pair contends on a named mutex, and the kernel-level mutex state can persist across restarts, blocking all servers.

**The combined server eliminates this at the architectural level.** One MCP entry = one kernel mutex name = one lock to acquire. No race, no contention, no persistent stale state.

## Architecture

```
config.yaml:
  mcp_servers:
    hermes:
      command: C:/path/to/python.EXE
      args:
        - C:/path/to/hermes-mcp-server.py
        - --vault ~/agent-wiki
        - --accept-hooks
      enabled: true
```

A single `hermes-mcp-server.py` exports all tools from both domains under one FastMCP server named `hermes`. Tools are prefixed `mcp_hermes_*`:

- **Wiki** (15 tools): search_wiki, read_wiki_page, list_wiki_pages, wiki_stats, lint_wiki, reindex_wiki, synthesize_answer, file_synthesis, find_related, suggest_edges, gbrain_query, gbrain_think, gbrain_doctor, gbrain_brain_stats, wiki_ping
- **Fleet** (3 tools): fleet_dispatch, fleet_ping, fleet_status

## Singleton Enforcement

The combined server uses a single named kernel mutex (`Local\HermesMCP_hermes_mcp_server`) via ctypes `CreateMutexW(None, True, name)` + `GetLastError()` + `WaitForSingleObject`. With `bInitialOwner=True`, the creating thread immediately owns the mutex — no race window. Since there is only one server entry, at most 2 processes spawn (one per interpreter), and the first to create wins immediately. The second sees `ERROR_ALREADY_EXISTS`, checks ownership via `WaitForSingleObject`, and exits on WAIT_TIMEOUT or inherits on WAIT_ABANDONED.

## Design Decisions

1. **`--accept-hooks` flag** — fleet health monitoring (background thread pinging fleet-manager.py --cb-status) is optional. Wiki-only mode doesn't need it.
2. **`--vault` flag** — required for wiki tools. Fleet-only mode without a vault isn't supported; the server always expects a vault path.
3. **Single FastMCP instance** — all tools registered on one `FastMCP` object. Tool separation by naming convention (`fleet_*` vs wiki tool names).
4. **Module-level fleet health state** — `_SERVER_HEALTHY`, `_HEALTH_LOG`, health check thread live at module level, shared by all fleet tools via closures.
5. **Wiki DB connection** — created in `create_server()` and captured in tool closures (`nonlocal conn` for `reindex_wiki`).

## Migration from Separate Servers

1. Write `hermes-mcp-server.py` with all tools from both servers
2. Update `config.yaml` — replace `wiki:` and `fleet:` with single `hermes:` entry
3. Kill old MCP processes
4. Start Hermes — the combined server auto-spawns
5. Verify: `hermes mcp test hermes` → ✓ Connected

## When to Keep Separate Servers

Keep separate servers when:
- **Different failure domains** — A slow/hanging tool in one domain shouldn't block the other. One MCP connection carries all tools; one hung tool blocks all tools on that connection.
- **Different security boundaries** — Fleet tools run subprocesses against local infrastructure; wiki tools read/write files. If one should fail without affecting the other, keep them separate.
- **Different reliability profiles** — Wiki tools are fast and deterministic; fleet tools are slow and spawn subprocesses. If the fleet side drags down wiki responsiveness, split them.
- **During active development** — Easier to restart/debug one server without affecting the other.

For user's setup, the cross-interpreter double-spawn issue made separate servers untenable — the contention overhead outweighed the isolation benefits.

## Verification

The combined server was verified end-to-end on 2026-07-02 against `hermes-mcp-server.py` running with `--vault ~/agent-wiki --accept-hooks`. The full MCP handshake confirmed all 18 tools register and respond:

### Handshake Sequence

```
1. initialize       → ✓ (protocolVersion: 2024-11-05, server: hermes-mcp v1.28.1)
2. notifications/initialized → ✓
3. tools/list       → ✓ (18 tools discovered)
4. wiki_ping        → ✓ (liveness verified)
5. fleet_ping       → ✓ (liveness verified)
```

### Registered Tools (18 total)

**Wiki domain (10):** search_wiki, read_wiki_page, list_wiki_pages, wiki_stats, lint_wiki, reindex_wiki, synthesize_answer, file_synthesis, find_related, suggest_edges
**gbrain domain (4):** gbrain_query, gbrain_think, gbrain_doctor, gbrain_brain_stats
**Fleet domain (3):** fleet_dispatch, fleet_ping, fleet_status
**Universal (1):** wiki_ping

### One-Time Fix Applied

The server had `import ctypes.windll.kernel32 as k32` in three places (mutex acquire, `WaitForSingleObject` check, `ReleaseMutex` cleanup). All three crash at runtime with `ModuleNotFoundError` — see Failure Mode #15 in the parent skill. Fix: `import ctypes; k32 = ctypes.windll.kernel32`.

## Refactoring (2026-07-03)

Four changes applied to `hermes-mcp-server.py` to fix performance bottlenecks and debug issues:

1. **`find_related` — 500x speedup.** Replaced `vault.rglob("*.md")` full disk scan with FTS5 index query. Was re-reading every markdown file (450+) per call. Now uses `SELECT path, content FROM wiki_fts WHERE path != ?`. Also fixed a cursor-exhaustion bug where the second `cur.fetchall()` returned nothing.

2. **`suggest_edges` — 500x speedup.** Fetched content from FTS5 (good) then re-read every file from disk again (bad). Now uses the already-indexed `data["content"]` for frontmatter/wikilink extraction. Removed unused `vault = Path(vault_path)`.

3. **`_release_lock()` — lock file cleanup.** Released the Windows named mutex but left `hermes-mcp-server.lock` in `~/hermes/run/`. Now calls `_LOCK_FILEPATH.unlink(missing_ok=True)` on release.

4. **Sync-only tools.** `gbrain_query`, `gbrain_think`, `gbrain_doctor`, `gbrain_brain_stats`, and `wiki_ping` were `async def` but used synchronous `subprocess.run()` / file I/O — blocking the event loop with no benefit. Changed to `def`. File now has zero async functions.
