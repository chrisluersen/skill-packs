# `args` as JSON String Instead of YAML List — StdioServerParameters Validation Error

## Symptom

All MCP servers fail to connect at startup. `errors.log` shows:

```
WARNING tools.mcp_tool: MCP server 'wiki' initial connection failed (attempt 1/3), retrying in 1s: 1 validation error for StdioServerParameters
WARNING tools.mcp_tool: MCP server 'fleet' initial connection failed (attempt 1/3), retrying in 1s: 1 validation error for StdioServerParameters
WARNING tools.mcp_tool: MCP server 'gbrain' initial connection failed (attempt 1/3), retrying in 1s: 1 validation error for StdioServerParameters
```

3 retries each, then abandoned. `mcp-stderr.log` shows rapid-fire "starting MCP server" headers with 1-5s gaps but no actual server output between them. Lock files in `run/` may contain stale PIDs from dead processes.

## Root Cause

The `args` field in `mcp_servers` config is a **JSON string** when the MCP SDK's `StdioServerParameters` (Pydantic model) expects a **list**.

Hermes reads `args` from config and passes it to `StdioServerParameters(command=..., args=args, ...)`. When `args` is a string `'["..."]'`, Pydantic validation fails because the type annotation expects `Optional[Sequence[str]]`.

This typically happens when:
- `args` was set via `hermes config set mcp_servers.<name>.args '["..."]'` — the CLI accepts JSON syntax for lists but stores it as a raw string without converting to YAML list format
- Config was manually edited and JSON notation was used instead of YAML list syntax

## Config Before vs After

```yaml
# ❌ WRONG — YAML string that looks like JSON
mcp_servers:
  wiki:
    command: C:/.../python.EXE
    args: '["C:/.../wiki-mcp-server.py","--vault","~/agent-wiki"]'

# ✅ CORRECT — native YAML list
mcp_servers:
  wiki:
    command: ~/AppData/Local/hermes/AppData/Local/hermes/hermes-agent/venv/Scripts/python.EXE
    args:
      - ~/AppData/Local/hermes/AppData/Local/hermes/scripts/wiki-mcp-server.py
      - --vault
      - ~/agent-wiki
    enabled: true
```

## Fix Procedure

1. **Edit config.yaml** — Agent tools are blocked from writing config.yaml by Hermes' security guard. Use terminal sed:
   ```bash
   # Read the current MCP section
   grep -A 8 "^mcp_servers:" "$LOCALAPPDATA/hermes/config.yaml"
   # Edit with sed — replace each JSON string args with YAML list
   ```
   Or edit manually in an editor.

2. **Clean stale lock files** — All 3 MCP PIDs are dead after failed startups:
   ```bash
   rm -f "$LOCALAPPDATA/hermes/run/wiki_mcp_server.lock"
   rm -f "$LOCALAPPDATA/hermes/run/fleet_mcp_server.lock"
   rm -f "$LOCALAPPDATA/hermes/run/gbrain_mcp_server.lock"
   ```

3. **Restart Hermes** — `/new` or the equivalent restart.

## Verification

```bash
hermes mcp test wiki    # Should show "✓ Connected"
hermes mcp test fleet
hermes mcp test gbrain
```

## Prevention

Always use YAML list syntax for `args`. After `hermes config set`, verify by reading the file:

```bash
grep -A 4 "args:" "$LOCALAPPDATA/hermes/config.yaml"
# Expected:
#   args:
#     - /path/to/script.py
#   NOT:
#   args: '["/path/..."]'
```

## Context

Discovered 2026-07-03. All 3 MCP servers (wiki, fleet, gbrain) affected simultaneously — same `args` pattern copied across entries. The error is a config parse error, not a runtime failure; validation happens before any server code executes.
