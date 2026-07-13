# Fleet Routing Tests — Methodology & Baseline

This reference documents the baseline fleet routing test methodology, original test results, and the P0 routing fix.

## Original 6 Routing Tests (2026-06-19)

From `session:20260619_102932_7fdc72`:

| # | Category | Target Agent | Result | Notes |
|---|----------|-------------|--------|-------|
| 1 | Code → Metis | Metis-9 | ✅ PASS | Correctly dispatched. |
| 2 | Wiki search | Klio-84 | ⚠️ PARTIAL | Routed to Artemis. Topology fix applied. |
| 3 | Web search | Artemis-105 | ✅ PASS | Correctly dispatched. |
| 4 | Data analysis | Fortuna-19 | ⚠️ PARTIAL | Ceres correctly rejected (missing file — expected behaviour). |
| 5 | Creative content | Kalliope-22 | ✅ PASS | Correctly dispatched. |
| 6 | DevOps | Atalanta-36 | ✅ PASS | Correctly dispatched. |

**P0 fix applied:** Routing expanded from 6 to 10 categories (added `complex`, `devops`, `memory`, `api`, `search`). LLM routing cache added (5min TTL). `_dispatch_with_fallback()` retry chains implemented.

## Current Routing Categories (10)

```
Categories: direct, wiki, search, data, code, design, devops, content, complex
```

Worker mapping from `fleet-manager.py`:

| Pattern | Worker ID | Hermes Profile | Tier |
|---------|-----------|---------------|------|
| direct | hermes_default | default | default |
| wiki | klio_84 | klio | 1 (single turn) |
| search | artemis_105 | artemis | 8 (full access) |
| data | fortuna_19 | fortuna | 1 (single turn) |
| code | metis_9 | metis | 8 (full access) |
| design | harmonia_40 | harmonia | 1 (single turn) |
| devops | atalanta_36 | atalanta | 1 (single turn) |
| content | kalliope_22 | kalliope | 1 (single turn) |
| complex | — | full pipeline | Vesta→Astraea→Worker→Nemesis→Ceres |

## How to Run Tests

```bash
cd ~/AppData/Local/hermes/scripts
python fleet-manager.py --status          # Quick health check
python fleet-manager.py "<test prompt>"   # Dispatch through pipeline
```

Use the test prompts in `templates/fleet-test-contracts.md` for each category.

## Pass/Fail Criteria

- **PASS**: Correct agent dispatched, Ceres-1 approves output
- **FAIL**: Wrong agent, pipeline timeout, gate rejection (should not happen in normal operation)
- **PARTIAL**: Correct worker dispatched but pipeline gate rejects for a valid reason (e.g. Ceres rejecting an incomplete output = gate working correctly)

## Known Pitfalls

- `--health` flag has a nested `asyncio.run()` bug (double event loop). Use `--status` instead.
- Pipeline calls take 1-5 minutes. Use background mode with 300s timeout.
- Run tests sequentially — `fleet-state.json` has no file locking.
