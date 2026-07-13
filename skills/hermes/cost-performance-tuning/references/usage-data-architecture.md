# Hermes Usage Data Architecture

**Last updated:** 2026-07-07  
**Applies to:** Hermes Agent v0.18.0

Hermes Agent stores session data but has **no built-in token usage or cost tracking**. Cost data must be estimated from session metadata, extracted from provider APIs, or built from scratch.

## Data Sources

### 1. session_registry.db — Session Metadata

**Location:** `~/.hermes/session_registry.db` (or `AppData/Local/hermes/` on Windows)  
**Size:** ~2.6MB (for 1999 sessions)  
**Accessible:** ✅ Yes — SQLite, fast queries

**Schema:**
```sql
sessions (id, title, started_at, ended_at, source, model,
          parent_session_id, end_reason, message_count, format,
          first_seen_at, description)
```

**What it has:**
- `model` — which model was used (e.g. `deepseek/deepseek-v4-flash`)
- `message_count` — total messages in the session
- `started_at` / `ended_at` — Unix timestamps
- `source` — where the session ran (`cli`, `discord`, etc.)
- `end_reason` — why it ended (`compression`, `user_stop`, etc.)

**What it does NOT have:**
- Token counts per message
- Dollar costs
- Provider info (which API key was charged)
- Per-request granularity

**Usage:** Query per-model session counts and message totals, then estimate costs using model pricing × estimated token-per-message ratios.

### 2. state.db — Raw Message Content

**Location:** `~/.hermes/state.db` (or `AppData/Local/hermes/` on Windows)  
**Size:** ~1.8GB  
**Accessible:** ⚠️ Schema only — full queries time out

**Schema:**
```sql
messages (id, session_id, role, content, tool_call_id)
-- Plus FTS tables for full-text search
```

**What it has:**
- Full message content (system, user, assistant, tool)
- Role and session association

**What it does NOT have:**
- Token counts (not stored per message)
- Cost data
- Model information per message

**Usage:** Nearly useless for cost analysis due to size and lack of token data. Only useful for recovering lost content (see `hermes-state-db-recovery` skill).

### 3. cost-snapshots/ — Intended Cost Store

**Location:** `~/.hermes/cost-snapshots/openrouter.json`  
**Size:** ~386 bytes (empty)  
**Accessible:** ✅ Yes but contains no data

**Content (zeroed-out):**
```json
{
  "snapshot_date": "2026-07-07",
  "total_spent_usd": 0.0,
  "total_tokens": 0,
  "models": []
}
```

**Status:** The directory exists but has never been populated with real data. Snapshots may be populated by a future cost-tracking cron or plugin.

### 4. sessions/ request_dump_cron_*.json — Per-Request Cost Data

**Location:** `~/.hermes/sessions/request_dump_cron_*.json`  
**Size:** ~6-9KB per file  
**Accessible:** ✅ Yes — JSON files

**Content:**
```json
{
  "request": {
    "model": "google/gemini-2.0-flash-001",
    "cost": 0.0012,
    "tokens": {
      "prompt": 1847,
      "completion": 203,
      "total": 2050
    }
  },
  "response": {
    "success": true
  }
}
```

**Limitation:** These files are created by the `request_dump_cron` job only — they capture cron-jobs requests, not user-facing chat sessions. User-initiated sessions leave no cost trail in these files.

### 5. Provider APIs — External Cost Data

**Sources:**
- OpenRouter: `https://openrouter.ai/activity` (web UI only — no public cost API endpoint documented)
- Nous Portal: `https://portal.nousresearch.com/usage`
- Vast.ai: `console.vast.ai` instance billing

**Access:** Manual web UI only — no programmatic API for usage statistics.

## Cost Estimation Method

Since no direct cost data exists, the recommended method is:

1. **Query session_registry.db** for sessions per model in the target date range
2. **Sum message_count** per model
3. **Estimate tokens per message:**
   - Each session: ~22,000 token overhead (system prompt, persona, memory, skills list, tool definitions, context summary)
   - Each user message: ~800 tokens (typical)
   - Each assistant response: ~2,000 tokens (typical)
4. **Apply model pricing** ($/M input, $/M output) from known rates
5. **Calculate estimated cost** per model, sum for total

### Pricing Reference (as of 2026-07-07)

| Model | Provider | Input $/M | Output $/M |
|-------|----------|:---------:|:----------:|
| deepseek/deepseek-v4-flash | Nous | $0.15 | $0.60 |
| google/gemini-2.5-flash | OpenRouter | $0.15 | $0.60 |
| anthropic/claude-sonnet-4 | OpenRouter | $3.00 | $15.00 |
| deepseek/deepseek-v4-pro | Nous | $2.00 | $8.00 |
| stepfun/step-3.7-flash:free | Free | $0.00 | $0.00 |
| nvidia/nemotron-3-ultra:free | Free | $0.00 | $0.00 |

## Investigation Workflow

When asked "how much am I spending on Hermes?"

```
Step 1: Check session_registry.db model breakdown
  → Get sessions per model, message count, date range

Step 2: Check cost-snapshots/ for any real data
  → Probably empty — note as gap

Step 3: Check sessions/ for request_dump_cron_*.json samples
  → Confirm the data model exists but covers cron only

Step 4: Estimate using message_count × pricing model
  → Apply the estimation script (see below)

Step 5: Report findings + recommend building actual tracking
```

## Cost Estimation Script

A reusable script `_usage_audit.py` is available in `scripts/` under this skill. It:
- Queries session_registry.db for session counts, message counts, and models
- Breaks down by model, source, and end_reason
- Estimates token usage and dollar cost using known pricing
- Produces a formatted report suitable for sharing

Run it:
```bash
cd ~/.hermes
python3 scripts/_usage_audit.py
```

## Knowing What to Track Going Forward

To get real (not estimated) cost data, you need to build one of:

1. **Router middleware** — logging proxy that captures each API call, model, tokens, and cost
2. **Provider API scraping** — cron job that fetches usage from OpenRouter/Nous web UIs
3. **Hermes wrapper** — intercept `provider.send_request()` to log before forwarding
4. **Cron tracker** — periodic summary from request_dump_cron files plus session_registry

The simplest path: Cron job that aggregates request_dump_cron files weekly.
