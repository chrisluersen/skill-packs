## Fleet-Manager Fixes and Improvements

This document details common issues encountered with the Fleet Manager tool and their resolutions, particularly concerning pathing, tool invocation, and health checks.

### Pathing Issues

**Problem:** Fleet Manager previously used incorrect paths when referencing V5 JSON profile data, leading to `FileNotFoundError`.

**Incorrect Path:** `wiki/raw/`
**Correct Path:** `llm-wiki/raw/`

**Resolution:** Ensure all internal references within Fleet Manager scripts and configurations point to the correct `llm-wiki/raw/` directory. This was addressed in session `2026-06-27`.

### Health Check Errors

**Problem:** The `--health` command for Fleet Manager could raise a `RuntimeError` if `asyncio.run()` was called within an already running event loop. This typically occurs when the health check is invoked as part of a larger asynchronous operation.

**Resolution:** Modify the health check implementation to correctly integrate with the existing event loop, avoiding nested `asyncio.run()` calls. The fix involves ensuring the health check logic respects the running event loop context.

### Tool Loading and Contracts

**Observation:** Profiles were loading conceptual tool names from V5 JSON (`wiki_search`, `ast_parser`) instead of real Hermes tool names from `task_contracts.json` (`mcp_wiki_search_wiki`, `read_file`). This caused tools to be silently stripped because the names did not match.

**Resolution:** Ensure that tool loading mechanisms within Fleet Manager and related profile configurations correctly reference tool names as defined in `task_contracts.json`.

### Tool Level Tuning

**Enhancement:** The L1 tool level was expanded to include `image_generate`, `cronjob`, and `process`, allowing lower-level agents (Harmonia, Atalanta) to utilize these tools without requiring L8 promotion. Note that `cronjob` and `process` remain in the `DESTRUCTIVE_TOOLS` set and still require confirmation.

### General Recommendations

- Always verify paths used by scripts and configurations, especially after directory renames or migrations (e.g., `wiki` vs. `llm-wiki`).
- Ensure that asynchronous operations, particularly within health checks or command-line interfaces, correctly handle existing event loops to avoid runtime errors.
- Use `task_contracts.json` as the source of truth for tool names, rather than design artifacts like V5 JSON, to prevent tool invocation failures.
