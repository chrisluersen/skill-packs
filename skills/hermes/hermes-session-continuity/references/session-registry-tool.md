# Session Registry Tool (`herms`) — Full Reference

## Overview

The session registry is an append-only mirror of Hermes `state.db` with multi-format alias generation for partial-ID lookups. Built because Hermes sessions use 7+ different ID formats across different time periods and sources, making manual SQL queries tedious.

**Purpose:** Look up any session by any partial ID fragment — suffix, timestamp, title, source — and get the full canonical ID for `herm --resume`.

## Architecture

```
                ┌── Cron (every 5 min, no_agent=true)
                │
~/.hermes/active_session ──┐   session_registry_sync.py
(PROMPT_COMMAND writes     │      │
 $HERMES_SESSION_ID        │      ├── sync from state.db
 every prompt)             ├──────┤    (new/updated sessions)
                           │      │
%TEMP%/hermes-tui-         │      ├── track_active_sessions()
active-session-*.json      │      │    (watchdog: insert in-flight
(TUI writes current        │      │     IDs not yet registered)
 session)                  │      │
                           │      └── output only if changed
state.db (Hermes writes    ──┘
 on close/compact)               session_registry.db
                                     │
                                 herms CLI
                                     │
                            lookup / resolve / list / stats
```

**Two data sources converge in one script:**

| Source | When it writes | What it catches |
|--------|---------------|-----------------|
| `state.db` | Session close/compact | Normal session lifecycle |
| `~/.hermes/active_session` | Every bash prompt | In-flight sessions, crash survival |
| TUI temp file | Every TUI session switch | `herm` TUI sessions |

The sync script (`session_registry_sync.py`) handles both: first syncs all closed sessions from `state.db`, then checks for active in-flight sessions via the watchdog and inserts any unknown IDs with `ended_at=NULL`.

## Files

| Path | Purpose |
|------|---------|
| `~/.hermes/session_registry.db` | Registry database |
| `~/AppData/Local/hermes/scripts/herms.py` | CLI tool |
| `~/AppData/Local/hermes/scripts/session_registry_sync.py` | Sync script (called by cron) |

## Schema (`session_registry.db`)

```sql
sessions          -- Append-only mirror of state.db sessions
├── id TEXT PK     -- Canonical full session ID (any format)
├── title TEXT     -- Session title from state.db
├── description TEXT -- First user message (backfilled for sessions without title)
├── started_at REAL
├── ended_at REAL
├── source TEXT    -- tui, discord, cli, cron, api_server, webui, acp, subagent
├── model TEXT
├── parent_session_id TEXT
├── end_reason TEXT
├── message_count INTEGER
├── format TEXT    -- Detected format tag (6-char-suffix, uuid, etc.)
└── first_seen_at REAL

sessions_fts       -- FTS5 virtual table (external content, auto-populated)
├── id UNINDEXED
├── title
└── description

aliases            -- Every resolvable form of each session ID
├── alias TEXT     -- The alias value (e.g. '1edadf', '20260619')
├── alias_type TEXT -- full_id, suffix, date, ts, compact, uuid_tail, etc.
├── session_id TEXT -- FK to sessions.id
└── created_at REAL

format_epochs      -- Tracks format transitions over time
├── format TEXT PK
├── first_seen_at REAL
├── last_seen_at REAL
└── count INTEGER

sync_log           -- Every sync run
├── synced_at REAL
├── sessions_added, sessions_updated, aliases_added INTEGER
├── state_db_sessions, registry_sessions INTEGER
```

## Alias Generation Rules

For each session ID format, the following aliases are generated:

| Format | Aliases generated |
|--------|------------------|
| `6-char-suffix` (`20260619_102733_1edadf`) | `full_id`, `suffix` (1edadf), `date` (20260619), `ts` (20260619_102733), `compact` (20260619_1edadf) |
| `8-char-suffix` (`20260601_174914_db332727`) | `full_id`, `suffix` (db332727), `suffix_trunc` (db3327), `date` (20260601), `ts` (20260601_174914) |
| `uuid` (`1e8eb132-...-dcf1d81`) | `full_id`, `uuid_tail` (dcf1d81), `suffix` (dcf1d8) |
| `12-hex` (`00767e933d69`) | `full_id`, `suffix` (933d69) |
| `10-hex` | `full_id`, `suffix` (last 6) |
| `cron-timestamp` (`cron_15433..._20260614_084509`) | `full_id`, `cron_task` (15433...), `date` (20260614), `ts` (20260614_084509) |
| `bg-task` (`bg_120426_cc4ee3`) | `full_id`, `suffix` (cc4ee3) |
| `label` / `unknown` | `full_id` only |

The `suffix` alias type is the key bridge: all timestamped formats generate it so you can search by hex fragment and match across format boundaries.

## CLI Reference

### `herms lookup <query>` [aliases: l, find, search]

Search sessions by partial ID, alias, or title.

```bash
herms lookup 1edadf           # Search by suffix
herms lookup discord -n 5     # Search title for "discord" (falls through from alias)
herms lookup 20260614 --verbose  # Show match details
```

Args:
- `--limit / -n` — max results (default 10)
- `--verbose / -v` — show matched-by and format info

Resolution order: aliases → title → none.

### `herms resolve <query>` [aliases: r]

Get full session ID for piping to `herm --resume`. Outputs only the ID on stdout.

```bash
herm --resume $(herms resolve 1edadf --pick-first)
```

Args:
- `--pick-first` — auto-select first match when ambiguous

On multiple matches without `--pick-first`: outputs a numbered list to stderr and exits 1.

### `herms search <query>` [aliases: s, ftsearch]

Full-text search across session titles and descriptions using FTS5 (BM25 ranking).

```bash
herms search "fleet"                         # AND by default
herms search "router OR tailscale"           # boolean OR
herms search '"session registry"'            # exact phrase
herms search "disc*"                         # prefix wildcard
herms search "fleet" --verbose               # show description + BM25 rank
herms search "screen" -n 3                  # limit results
```

**FTS5 query syntax:**
- Multiple words = AND: `discord screen` matches sessions with both words
- `OR` = boolean OR: `router OR tailscale`
- `"quoted phrase"` = exact phrase match
- `prefix*` = prefix wildcard: `disc*` matches discord, discover, etc.

**Fallback:** On FTS5 syntax error (e.g. invalid token), falls back to `LIKE '%query%'` on title + description.

**`--verbose / -v`** — Show description snippet (80 chars), BM25 rank, format tag, and message count.

**`--limit / -n`** — Max results (default 10).

Args:
- `--limit / -n` — max results (default 10)
- `--verbose / -v` — show description snippet and BM25 rank

### `herms list` [aliases: ls]

List sessions with filters.

```bash
herms list --since 2026-06-15
herms list --source discord --limit 5
herms list --since 2026-06-18 --until 2026-06-19 --quiet
herms list --source cron --count-only   # Just the count
```

Args:
- `--since` / `--until` — date range (YYYY-MM-DD)
- `--source` — filter by source (tui, discord, cli, cron, api_server, webui, acp, subagent)
- `--format` — filter by ID format tag
- `--model` — filter by model name (partial match)
- `--limit / -n` — max results (default 20)
- `--quiet / -q` — IDs only, one per line
- `--count-only` — just the count

### `herms stats` [aliases: status, health]

Registry health: total sessions, aliases, source breakdown, format epochs, last sync details.

### `herms sync`

Force an immediate sync from state.db. Useful when:
- You just ended a session and want it in the registry now
- You need to verify a session that was created in the last hour

## Cron Behavior

- **Schedule:** Every 5 minutes (`*/5 * * * *`)
- **Mode:** `no_agent=true` — script stdout is delivered verbatim, no LLM wrap
- **Silence on no-change:** If 0 new, 0 updated, 0 active sessions tracked — no output, no delivery
- **Alert on change:** Only outputs when something actually happened (new sessions, new active session tracked)
- **Deliver:** Broadcast to all connected channels so user sees "tracked new active session: X" wherever they are

## Known Gaps

### 1. ✅ In-Flight Sessions — Proactive Watchdog (Implemented)

The registry now captures active sessions BEFORE they reach state.db. See the Architecture diagram above.

**The three-layer chain:**

1. **PROMPT_COMMAND in `.bashrc`** — fires on every prompt, writes `$HERMES_SESSION_ID` to `~/.hermes/active_session`. Dirt cheap (one file write), always captures the current session.
2. **Cron `*/5 * * * *`** — `session_registry_sync.py` calls `track_active_sessions()`, which reads both the `active_session` file and the TUI temp file for any session IDs not yet in the registry.
3. **Insert as in-flight** — unknown IDs get `ended_at=NULL`, `source='active_watchdog'`, title `'(in-flight)'`. The main sync later updates them when state.db gets the close record.

**What it still doesn't cover:**

- **Empty sessions** (opened and closed without typing) — by design, user said those aren't worth tracking
- **Immediate crash before first prompt** — the session starts and crashes before `PROMPT_COMMAND` fires. No ID was ever written. This is a ~1-second window and fundamentally unrecoverable (the session ID exists only in Hermes's in-memory state, which dies with the process)

### 2. Last-Hour Latency (Reduced)

Sessions from the last 0-5 minutes won't be in the registry until the next cron tick. At `*/5 * * * *`, maximum latency is 5 minutes — down from 59 minutes with the hourly cron. Run `herms sync` to force an immediate pull.

### 3. Title Search Is FTS5 (with LIKE fallback)

The primary search (`herms search`) uses FTS5 over `id`, `title`, and `description` with BM25 ranking. Supports AND/OR/"phrases"/prefix* syntax. On FTS5 syntax error, falls back to `LIKE '%query%'` on title + description. The old SQL-only LIKE limitation only applies to the fallback path.

### 4. SQLite Schema Migrations

The sync script handles schema evolution via try/except ALTER TABLE:
```python
for col, col_type in [('description', 'TEXT DEFAULT ""'), ('descriptions_added', 'INTEGER DEFAULT 0')]:
    try:
        reg_conn.execute(f"ALTER TABLE {target} ADD COLUMN {col} {col_type}")
    except sqlite3.OperationalError:
        pass  # already exists
```

This pattern adds columns non-destructively to pre-existing databases without dropping/recreating tables. New migrations go in the same block after `CREATE TABLE IF NOT EXISTS`.

### 5. Format Detection Is Regex-Based (update note)

The `detect_format()` function uses regex patterns for known ID shapes. New format patterns need to be added to `ID_PATTERNS` in `session_registry_sync.py`. Unknown formats get tagged `'unknown'` and only generate a `full_id` alias (no suffix/date aliases).

Latest format distribution (from live sync):
```
formats: 12-hex=12, 6-char-suffix=940, 8-char-suffix=49, bg-task=1, cron-timestamp=48, label=1, uuid=11
```

## Pitfalls

1. **Current session may be stale in registry** — The session you're in right now (`$HERMES_SESSION_ID`) is tracked as "(in-flight)" by the watchdog (≤5 min latency), but its title and ended_at are NULL until state.db gets the close record. `herms lookup` will find it but show `(in-flight)` as the title.

2. **5-minute watchdog latency** — If a session starts and crashes within seconds AND the PROMPT_COMMAND hadn't fired yet (before the first prompt rendered), the ID is lost. This is a ~1-second window — fundamentally unrecoverable (the session ID exists only in Hermes's in-memory state).

3. **Last-hour sync** — Sessions from the last 0-5 minutes won't be in the registry until the next cron tick. Run `herms sync` to force an immediate pull.

4. **Registry is a mirror, not a source** — The registry copies what's in state.db and adds watchdog-tracked in-flight sessions. If both sources miss a session, the registry does too.

5. **Title search is FTS5, LIKE is fallback** — The primary search uses FTS5 (BM25-ranked, supports AND/OR/phrases). The LIKE fallback only triggers on FTS5 syntax error.

6. **Format detection is regex-based** — New format patterns need to be added to `ID_PATTERNS` in the sync script. Unknown formats get tagged `'unknown'` and only generate a `full_id` alias.
