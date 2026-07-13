# Fleet Tool Stripping Behavior (fixed 2026-06-24)

## Root Cause

`fleet-manager.py`'s `_load_profiles()` sourced `profile.tools` from the V5 JSON (`raw/hermes_agent_profiles_v5.json`), which uses abstract/conceptual tool names. The tool gateway in `dispatch_to_agent()` compared these against `task_contracts.json`, which uses real Hermes tool names. Since the naming conventions never matched, every profile's tools were stripped to `[]`.

### Before the Fix

```python
# fleet-manager.py line 616 — V5 JSON source (abstract names)
tools=entry.get("operational_matrix", {}).get("allowed_tools", []),
```

V5 JSON names (abstract): `wiki_search`, `headless_browser`, `ast_parser`, `payload_sanitizer`
Contract names (Hermes): `mcp_wiki_search_wiki`, `web_search`, `execute_code`, `terminal`

Result: `🚫 Stripping disallowed tools: ['wiki_search', 'wiki_read', ...]` → `📋 Profile tools restricted to: []`

### The Fix (one line)

```python
# fleet-manager.py line 616 — sourced from task_contracts.json (real Hermes names)
tools=TASK_CONTRACTS.get(pid, {}).get("allowed_tools", []),
```

Now `profile.tools` uses the SAME source the tool gateway compares against — so they always match.

## Post-Fix Behavior

| Agent | Loaded Tools (from contract) | Tier Stripping |
|-------|-----------------------------|----------------|
| Klio-84 (wiki) | `mcp_wiki_search_wiki`, `mcp_wiki_read_wiki_page`, `mcp_wiki_list_wiki_pages`, `mcp_wiki_lint_wiki`, `mcp_wiki_reindex_wiki`, `mcp_wiki_wiki_stats`, `mcp_wiki_synthesize_answer`, `read_file`, `write_file`, `terminal` | `L1 — stripped 1: ['terminal']` |
| Artemis-105 (search) | `web_search`, `web_extract` | None (Tier 8) |
| Metis-9 (code) | `read_file`, `write_file`, `terminal`, `search_files`, `patch`, `execute_code` | None (Tier 8) |
| Fortuna-19 (data) | `read_file`, `write_file`, `terminal`, `execute_code`, `search_files` | None (Tier 8) |
| Harmonia-40 (design) | `write_file`, `read_file`, `image_generate`, `vision_analyze` | `L1 — stripped N` (Tier 1) |
| Atalanta-36 (devops) | `terminal`, `read_file`, `search_files`, `process`, `cronjob` | `L1 — stripped N` (Tier 1) |
| Kalliope-22 (content) | `read_file`, `write_file`, `patch`, `search_files` | `L1 — stripped N` (Tier 1) |

**Tier-level enforcement** (`_enforce_tool_level`) is SEPARATE from contract mismatch. Tools stripped by tier level (e.g. `L1 — stripped 1 tools: ['terminal']`) is expected — it's the secondary safety ring based on max_turns.

## Impact Verified in E2E Tests

Pre-fix: Klio responded from training data only. Unable to search the wiki.
Post-fix: Klio dispatched via `hermes -p klio chat`, used `mcp_wiki_search_wiki` tool, found 5+ wiki pages about "hermes router" with real page IDs and content (2369 chars).

## The Dispatch Command (unchanged, still doesn't use profile.tools)

```python
cmd = ["hermes", "-p", profile.hermes_profile, "chat",
       "-q", prompt, "-Q", "--max-turns", mt,
       "--provider", "nous"]
```

The Hermes CLI gets its tools from the profile's `config.yaml`, not from the fleet-manager's metadata. The fix ensures metadata accuracy for logging and `_enforce_tool_level()` — the actual tool availability comes from the profile's Hermes config.
