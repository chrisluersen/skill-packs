# Fleet Manager Architecture

> Reference for `~/AppData/Local/hermes/scripts/fleet-manager.py`
> Created 2026-06-18. Updated 2026-06-19 — Council Evaluation Protocol, peer review, aggregate scoring.

## Overview

The fleet manager is a ~1,130-line Python script that dispatches tasks through the 13-worker pipeline using a pub/sub event bus. It reads agent definitions from `hermes_agent_profiles_v5.json` and dispatches to Hermes profiles via `hermes -p <profile> chat -q "<prompt>" -Q --max-turns <N>` subprocess calls.

Thalia-23 is merged into the default profile — 13 workers + 1 synthetic `hermes_default` = 14 dispatchable targets.

## 6-Phase Pipeline

```
User Input
    │
    ▼
Phase 1: Vesta-4 (Security) ──── quarantines malicious input, can halt fleet
    │
    ▼
Phase 2: Astraea-5 (Routing) ── one-sentence intent summary
    │
    ▼
Phase 3: Worker Dispatch ─────── routes to specialist OR Hermes default
    │
    ▼
Phase 4a: Nemesis-128 (QA) ──── structured FINAL_EVALUATION: format
    │                               (quality-sensitive tasks only — may trigger Metis retry)
    ▼
Phase 4b: Peer Review ────────── blind second opinion from synergistic partner
    │                               (same structured format)
    ▼
Phase 4c: Aggregate ──────────── confidence-weighted consensus
    │
    ▼
Phase 5: Ceres-1 (Review) ────── receives {worker_output + aggregate evaluations}
    │                               Judged on output quality, NOT plan adherence
    ▼
Phase 6: Output ──────────────── structured score display with substring fallback
```

See `references/council-evaluation-protocol.md` for the full protocol details.

## Three-Tier Dispatch System (CRITICAL)

Each agent is dispatched with a `--max-turns` flag based on its role. This prevents the fleet-wide timeout that occurred when supervisor agents tried `delegate_task` loops instead of returning text.

| Tier | `--max-turns` | Timeout | Agents | Rationale |
|------|---------------|---------|--------|-----------|
| 0 (supervisor) | 0 | 60s | astraea_5, vesta_4, ceres_1, nemesis_128 | Text-only — return plan/verdict, no tools, no delegation |
| 1 (chat/data) | 1 | 90s | fortuna_19, kalliope_22, mnemosyne_57, klio_84, hermes_default | At most 1 tool call, then respond |
| 8 (execution) | 8 | 180s | metis_9, iris_7, artemis_105, atalanta_36, harmonia_40 | Full tool access for coding, web, deployment |

**Implementation:**
```python
TIER_0_AGENTS = {"astraea_5", "vesta_4", "ceres_1", "nemesis_128"}
TIER_1_AGENTS = {"fortuna_19", "kalliope_22", "mnemosyne_57", "klio_84"}
TIER_8_AGENTS = {"metis_9", "iris_7", "artemis_105", "atalanta_36", "harmonia_40"}

# In dispatch_to_agent():
mt = str(profile.max_turns)
timeout = {0: 60, 1: 90, 8: 180}.get(profile.max_turns, 90)
cmd = ["hermes", "-p", profile.hermes_profile, "chat",
       "-q", prompt, "-Q", "--max-turns", mt]
```

**Key insight:** `--max-turns 0` tells Hermes to skip the tool-calling loop entirely and return the model's text response. This is exactly right for supervisors who should return a JSON plan or verdict, not execute tools.

### Synthetic `hermes_default` Profile

Since Thalia-23 was merged into the default profile, the fleet manager creates a synthetic `hermes_default` AgentProfile entry that dispatches to the default Hermes profile for chat queries. This is used in the `else` branch of `_route_to_worker()` when no specialist routing matches:

```python
self.profiles["hermes_default"] = AgentProfile(
    pid="hermes_default",
    name="Hermes",
    role="Messenger",
    hermes_profile="default",
    max_turns=1,  # Tier 1
    ...
)
```

## Pub/Sub Channels (49 total)

Each agent has `subscribes_to` and `publishes_to` channels defined in V5 JSON. Key channels:

| Channel | Publisher | Subscribers |
|---------|-----------|-------------|
| `raw_user_input` | user | vesta_4 |
| `clean_input_stream` | vesta_4 | astraea_5 |
| `task_decomposed` | astraea_5 | [workers] |
| `chat_query` | astraea_5 | hermes_default |
| `workflow_staged` | pipeline | ceres_1 |
| `final_output_stream` | ceres_1 | user |
| `fleet_halt_command` | ceres_1 | all |
| `security_escalation` | vesta_4 | ceres_1 |

## Response Cleaner

Hermes CLI quiet mode (`-Q`) output contains metadata that must be stripped. When using `--max-turns 0`, Hermes also prepends `⚠️ Reached maximum iterations (0). Requesting summary...` which must be filtered:

```python
def _clean_response(self, raw: str) -> str:
    """Strip ANSI codes and metadata from quiet-mode Hermes output."""
    text = strip_ansi(raw)
    lines = text.split("\n")
    response_lines = []
    in_response = False

    for line in lines:
        stripped = line.strip()
        # Skip known metadata lines
        if not stripped:
            if in_response: response_lines.append(line)
            continue
        if stripped.startswith(("Warning:", "session_id:", "Query:",
                                 "Initializing", "Grant spent",
                                 "Resume this session", "Session:",
                                 "Duration:", "Messages:")):
            continue
        # Skip Hermes CLI artifacts from --max-turns 0
        if stripped.startswith("⚠️"):
            continue
        if "Reached maximum iterations" in stripped:
            continue
        if stripped.startswith("Requesting summary"):
            continue
        # Skip box-drawing lines
        if any(c in stripped for c in ["─", "━", "┌", "┐", "└", "┘", "╰", "╭", "├", "┤"]):
            continue
        in_response = True
        response_lines.append(line)

    result = "\n".join(response_lines).strip()
    return result if result else text.strip()
```

## Dispatch Mechanism

```python
result = await asyncio.create_subprocess_exec(
    "hermes", "-p", profile.hermes_profile, "chat",
    "-q", prompt, "-Q", "--max-turns", mt,
    stdout=asyncio.subprocess.PIPE,
    stderr=asyncio.subprocess.PIPE,
)
stdout, stderr = await asyncio.wait_for(result.communicate(), timeout=timeout)
```

**Critical:** The `-Q` flag goes AFTER `chat -q`, NOT before `chat`. Argparse rejects `hermes -p <name> -Q chat -q ...`.

**Timeout handling:** On `asyncio.TimeoutError`, the subprocess is killed via `result.kill()` to prevent orphaned processes.

## State Persistence

State is saved to `~/AppData/Local/hermes/scripts/fleet-state.json`:
- Request counter
- Event log (all pub/sub events)
- Per-agent success/failure counts
- Learning rates (neuro-evolutionary)
- Quarantine status
- Fleet halt flag

## Resolved Issues

1. **Astraea-5 timeout — RESOLVED (2026-06-18).** Root cause: supervisor agents (Astraea, Vesta, Ceres, Nemesis) had `delegate_task` enabled and entered full subagent delegation loops instead of returning text. Fix: three-tier `--max-turns` system — supervisors get `--max-turns 0` (text-only, 60s), chat agents get `1` (90s), execution agents get `8` (180s). Pipeline now completes in ~98s with zero timeouts.
2. **Default routing returning raw plan — RESOLVED (2026-06-18).** The `else` branch in `_route_to_worker` returned `astraea_plan` directly, causing Ceres-1 to reject (worker_output == astraea_plan). Fix: synthetic `hermes_default` profile dispatches to the default Hermes profile for chat queries.
3. **CLI artifacts polluting downstream — RESOLVED (2026-06-18).** `--max-turns 0` prepends `⚠️ Reached maximum iterations` to output. Fix: added filters in `_clean_response`.
4. **Council Evaluation Protocol — DEPLOYED (2026-06-19).** Structured `FINAL_EVALUATION:` format replaces ad-hoc Nemesis substring matching. Peer review from synergistic partners provides blind second opinions. Aggregate scoring gives Ceres confidence-weighted consensus. See `references/council-evaluation-protocol.md`.

## Background Pub/Sub Event Loop

> Added 2026-06-23 — true asynchronous event loop that makes the bus functional.

### Architecture

`fleet-manager.py` now runs a background event loop alongside the synchronous pipeline:

```text
Pipeline (process_request)           Event Loop (run_event_loop)
        │                                   │
        ▼                                   ▼
  Direct dispatch to agents           Consumes from self.bus
  (Vesta → Astraea → Worker)          Fans out to ALL subscribers
        │                                   │
        ▼                                   ▼
  Publishes events with              Agent outputs get auto-published
  source="pipeline"                   on their publish channels
  (event loop skips these)            (enables chain reactions)
```

**No double-dispatch:** Pipeline events are tagged `source="pipeline"` and the event loop skips them. The loop only dispatches events published by agents themselves (from `dispatch_to_agent()` responses back to the bus).

### The Event Loop (`run_event_loop()`)

```python
async def run_event_loop(self):
    """Background coroutine — consumes events from self.bus and routes to subscribers."""
    while True:
        event = await self.bus.get()
        if event.source == "pipeline":
            continue  # Already handled by synchronous pipeline

        subscribers = self._get_subscribers(event.type)
        if not subscribers:
            continue

        # Fan out to ALL subscribers concurrently
        tasks = [self.dispatch_to_agent(profile, event) for profile in subscribers]
        results = await asyncio.gather(*tasks, return_exceptions=True)

        # Auto-publish agent outputs on their publish channels
        for profile, result in zip(subscribers, results):
            if isinstance(result, Exception):
                log.error(f"⚠️ {profile.name} event loop error: {result}")
                continue
            if result and len(result.strip()) > 10:
                for pub_channel in profile.pubs:
                    await self.publish(pub_channel, {
                        "output": result,
                        "source_event": event.type,
                    }, source=profile.pid)
```

### Lifecycle

- `manager.start()` — creates an `asyncio.Task` for the event loop (called in `main()`)
- `manager.stop()` — cancels the task on exit (interactive mode `exit`, or after single request)
- The loop handles per-agent errors gracefully — one bad dispatch won't crash it
- Events with no subscribers are silently dropped (no dispatch, no error)

### Channel Chain Example

When the pipeline dispatches to Vesta-4 and Vesta responds "CLEAN...":
1. Pipeline dispatches directly to Vesta-4 (source="pipeline", skipped by loop)
2. Event loop auto-publishes Vesta's output on `clean_input_stream`
3. Astraea-5 (subscribed to `clean_input_stream`) gets dispatched by the event loop
4. Astraea's output gets auto-published on `task_graph_generated`
5. ...chain continues through all 49 channels

This makes the V5 JSON's pub/sub channel map **fully functional** — every channel with a subscriber will route events to that subscriber when the channel fires.

### Channel Coverage

With the event loop active, all 49 channels become functional:

| Channel | Publisher | Subscriber(s) | Now Active? |
|---------|-----------|---------------|-------------|
| `raw_user_input` | pipeline | Vesta-4 | ✅ (pipeline + loop) |
| `clean_input_stream` | Vesta-4 | Astraea-5 | ✅ (auto-publish) |
| `code_task_dispatched` | Astraea-5 | Metis-9 | ✅ (via dispatch) |
| `compilation_success` | Metis-9 | Nemesis-128 | ✅ (auto-publish) |
| `web_search_requested` | Astraea-5 | Artemis-105 | ✅ (via dispatch) |
| `wiki_query` | Astraea-5 | Klio-84 | ✅ (via dispatch) |
| `bug_report_received` | Nemesis-128 | Metis-9 | ✅ (via retry cycle) |
| `workflow_staged` | pipeline | Ceres-1 | ✅ (pipeline + loop) |
| `final_output_stream` | Ceres-1 | — | ✅ (logging) |
| `session_started` | — | Mnemosyne-57 | 🔲 (no publisher wired) |
| `incoming_webhook` | — | Vesta-4 | 🔲 (no publisher wired) |

Channels without publishers (`session_started`, `incoming_webhook`, `deadlock`, `dataset_ready`, `pr_merged`, etc.) remain dormant until a publisher is wired up. They're ready to fire when needed.

### Key Design Decision

The event loop supplements the pipeline — it does NOT replace it. The synchronous `process_request()` remains the user-facing API because:
1. It returns a result synchronously (caller needs the final output)
2. The 5-phase pipeline is a proven, working sequence
3. The event loop handles agent-to-agent communication outside the pipeline

If future work makes the pipeline fully event-driven, `process_request()` would need to collect results via a Future/callback pattern instead of direct dispatch.

## CLI Commands

```
python fleet-manager.py "message"          # Run through full pipeline
python fleet-manager.py --interactive       # Interactive REPL mode
python fleet-manager.py --status            # Show fleet status table
python fleet-manager.py --channels          # Show pub/sub channel map
```
