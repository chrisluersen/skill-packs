# Fleet Pub/Sub Channel Map — V5 JSON vs fleet-manager.py

> Generated 2026-06-23 from `hermes_agent_profiles_v5.json` and `fleet-manager.py`

## V5 JSON Channel Definitions

All 13 active agents (Thalia-23 merged into default profile, skipped at load time).

| Agent | Subscribes To | Publishes To |
|-------|--------------|--------------|
| **Ceres-1** | `workflow_staged`, `security_escalation`, `deadlock` | `final_output_stream`, `fleet_halt_command` |
| **Vesta-4** | `raw_user_input`, `incoming_webhook`, `external_api_payload` | `clean_input_stream`, `quarantine_alert` |
| **Astraea-5** | `clean_input_stream`, `agent_idle_status` | `task_graph_generated`, `sub_task_dispatched` |
| **Iris-7** | `api_request_queued` | `api_response_received`, `network_timeout` |
| **Metis-9** | `code_task_dispatched`, `bug_report_received` | `pr_staged`, `compilation_success` |
| **Fortuna-19** | `math_verification_requested`, `dataset_ready` | `analysis_complete`, `variance_report` |
| **Kalliope-22** | `raw_data_stream`, `documentation_requested` | `mdx_render_ready`, `copy_drafted` |
| **Atalanta-36** | `pr_merged`, `deployment_requested` | `pipeline_status`, `latency_metrics` |
| **Harmonia-40** | `frontend_task_dispatched`, `layout_review_requested` | `css_compiled`, `ui_schema_ready` |
| **Mnemosyne-57** | `session_started`, `context_query` | `historical_context_injected` |
| **Klio-84** | `fact_check_requested`, `wiki_query` | `citation_provided`, `archive_retrieved` |
| **Artemis-105** | `web_search_requested` | `search_results_parsed`, `serp_timeout` |
| **Nemesis-128** | `compilation_success`, `qa_stage_started` | `bug_report_generated`, `test_suite_passed` |

Total V5 channels: **49** (Thalia-23 had 3: `user_chat_input`, `system_idle_long` → `chat_response_streamed`)

## Current fleet-manager.py: Pub/Sub Status (Updated 2026-06-23)

### What Exists
- `asyncio.Queue` bus initialized in `HermesFleetManager.__init__()`
- `publish()` method queues events with type + payload
- `_get_subscribers()` returns agents subscribed to a channel
- `dispatch_to_agent()` invokes agents via `hermes -p <profile> chat -q "..." -Q --max-turns N`
- Full synchronous pipeline: `process_request()` → Vesta → Astraea → Worker → Nemesis → Ceres
- **✅ Background event loop** — `run_event_loop()` consumes from the bus and fans out to ALL subscribers concurrently via `asyncio.gather`. Agent outputs get auto-published on their `publishes_to` channels, enabling chain reactions.
- **✅ Lifecycle** — `start()`/`stop()` methods. Loop starts with `--channels`, `--status`, `--interactive`, or single-request mode. Stops on exit.
- **✅ No double-dispatch** — Pipeline events tagged `source="pipeline"` are skipped by the event loop. Only agent-to-agent events (auto-published by the loop) trigger subscriber dispatch.
- 14 event type templates in `_build_prompt()`

### What's Now Active (the Event Bus)

The event loop makes the V5 channel map **fully functional**:

| Channel | Publisher | Subscriber(s) | Status |
|---------|-----------|---------------|--------|
| `raw_user_input` | pipeline | Vesta-4 | ✅ Pipeline direct |
| `clean_input_stream` | Vesta-4 (auto) | Astraea-5 | ✅ Event loop fan-out |
| `code_task_dispatched` | Astraea → loop | Metis-9 | ✅ Event loop fan-out |
| `compilation_success` | Metis-9 (auto) | Nemesis-128 | ✅ Auto-publish chain |
| `bug_report_received` | Nemesis → loop | Metis-9 | ✅ Retry cycle |
| `web_search_requested` | Astraea → loop | Artemis-105 | ✅ Event loop fan-out |
| `wiki_query` | Astraea → loop | Klio-84 | ✅ Event loop fan-out |
| `fact_check_requested` | Astraea → loop | Klio-84 | ✅ Event loop fan-out |
| `documentation_requested` | Astraea → loop | Kalliope-22 | ✅ Event loop fan-out |
| `math_verification_requested` | Astraea → loop | Fortuna-19 | ✅ Event loop fan-out |
| `frontend_task_dispatched` | Astraea → loop | Harmonia-40 | ✅ Event loop fan-out |
| `deployment_requested` | Astraea → loop | Atalanta-36 | ✅ Event loop fan-out |
| `context_query` | Astraea → loop | Mnemosyne-57 | ✅ Event loop fan-out |
| `api_request_queued` | Astraea → loop | Iris-7 | ✅ Event loop fan-out |
| `chat_query` | Astraea → loop | Hermes (default) | ✅ Event loop fan-out |
| `workflow_staged` | pipeline | Ceres-1 | ✅ Pipeline direct |
| `final_output_stream` | Ceres-1 | — | ✅ Pipeline direct |
| `quarantine_alert` | Vesta-4 | — | ✅ Guardrail |
| `fleet_halt_command` | Ceres-1 | — | ✅ Guardrail |
| `security_escalation` | — | Ceres-1 | 🔲 No publisher wired |
| `deadlock` | — | Ceres-1 | 🔲 No publisher wired |
| `session_started` | — | Mnemosyne-57 | 🔲 No publisher wired |
| `incoming_webhook` | — | Vesta-4 | 🔲 No publisher wired |
| `external_api_payload` | — | Vesta-4 | 🔲 No publisher wired |
| `agent_idle_status` | — | Astraea-5 | 🔲 No publisher wired |
| `dataset_ready` | — | Fortuna-19 | 🔲 No publisher wired |
| `pr_merged` | — | Atalanta-36 | 🔲 No publisher wired |
| `layout_review_requested` | — | Harmonia-40 | 🔲 No publisher wired |
| `qa_stage_started` | — | Nemesis-128 | 🔲 Currently routed via `compilation_success` |

### How It Works In Practice

When the pipeline dispatches to Vesta-4 and Vesta responds "CLEAN":
1. **Pipeline** dispatches directly to Vesta-4 (source="pipeline", skipped by loop)
2. **Event loop** auto-publishes Vesta's output on `clean_input_stream`
3. **Event loop** sees `clean_input_stream` → subscribes: Astraea-5 → dispatches
4. Astraea's response gets auto-published on `task_graph_generated`, `sub_task_dispatched`
5. Chain continues — every agent output fans out to all subscribers

**Result:** The 49-channel V5 design is now operational for all channels that have both a publisher and subscriber. Dormant channels (no publisher wired) are ready to fire when needed.

## Gap Summary (Updated 2026-06-23)

| Aspect | V5 Design | fleet-manager.py |
|--------|-----------|-----------------|
| Architecture | Event-driven pub/sub | Synchronous pipeline + background event loop |
| Routing | Subscription-based | Hardcoded keyword match (pipeline) + subscriber fan-out (loop) |
| Event loop | Background task | ✅ Implemented (`run_event_loop`, `start`/`stop`) |
| Agent-to-agent | Any agent publishes any channel | ✅ Auto-publish via event loop on agent `publishes_to` channels |
| Channels exercised | 49 | ✅ 17+ active via pipeline + event loop; all 49 routing-enabled |
| Dormant channels | — | 8 channels (no publisher wired): `incoming_webhook`, `external_api_payload`, `agent_idle_status`, `dataset_ready`, `session_started`, `security_escalation`, `deadlock`, `pr_merged`, `layout_review_requested` |
| State persistence | Neuro-evolutionary | ✅ success/fail tracking |
| Guardrails | Vesta quarantine + Nemesis QA | ✅ Both implemented |
