# Registry-Driven Agent Loading & Health Monitoring

## Context

These patterns emerged during the fleet architecture audit (2026-06-24) where the fleet plan had a "single source of truth" (task_contracts.json) that fleet-manager.py didn't actually read from. The fix required making the code match the architecture's stated design.

## Agent Discovery — File-Backed Registry

### Problem

Adding an agent to the fleet required editing Python code:
- `PROFILE_MAP` dict
- `TIER_1_AGENTS` / `TIER_8_AGENTS` sets
- Routing blocks in `_route_to_worker()`
- `_load_profiles()` initialization

This is a code change for a config operation. At 7+ workers it's manageable; at 15+ it becomes a maintenance burden.

### Solution

1. **Create a contract registry file:** `~/AppData/Local/hermes/fleet/task_contracts.json`
   - Each agent gets: `input_schema`, `output_schema`, `max_turns`, `allowed_tools`, `cost_tier`, `privilege_level`
   - The file is the SINGLE source of truth

2. **Load at startup in fleet-manager.py:**
   ```python
   CONTRACT_PATH = Path.home() / "AppData/Local/hermes/fleet/task_contracts.json"
   if CONTRACT_PATH.exists():
       TASK_CONTRACTS = json.load(open(CONTRACT_PATH))
   else:
       TASK_CONTRACTS = {...}  # bootstrap defaults
   ```

3. **Drive PROFILE_MAP from a minimal lookup dict:**
   ```python
   HERMES_PROFILE_NAMES = {
       "vesta_4": "vesta", "astraea_5": "astraea", ...
   }
   PROFILE_MAP = {}
   for pid in TASK_CONTRACTS:
       if pid in HERMES_PROFILE_NAMES:
           PROFILE_MAP[pid] = HERMES_PROFILE_NAMES[pid]
   ```

4. **`_load_profiles()` iterates over TASK_CONTRACTS** — no more hardcoded TIER sets or profile-by-profile initialization.

### Scale Thresholds

| Worker Count | Registry Approach | Maintenance Cost |
|--------------|-------------------|-----------------|
| 1-7 (current) | File-backed + HERMES_PROFILE_NAMES dict | Low — one dict entry per agent |
| 8-15 | File-backed + HERMES_PROFILE_NAMES dict | Medium — dict grows but still manageable |
| 16+ | Fully self-describing — `hermes_profile` field IN the contract JSON | Lowest — one file entry = one agent, no code changes |

At 16+, even the HERMES_PROFILE_NAMES dict should move into the contract JSON. Add a `"hermes_profile": "vesta"` field per agent and drop the lookup dict entirely.

## On-Demand Fleet Health Check

### Problem

The observability cron (runs every 4h) provides backward-looking trend data. It answers "was the fleet healthy 2 hours ago?" but not "is the fleet healthy right now?" Acute failures (a provider key expiring, a profile silently crashing) go undetected until the user hits a broken dispatch.

### Solution

Add a `--health` flag to fleet-manager.py that checks:

1. **Circuit breaker states** — reads from fleet_state.json's circuit_breakers map
2. **Agent responsiveness** — dispatches a `ping` event to each loaded profile, measures response time
3. **Cost snapshot** — averages last 100 dispatches
4. **State file integrity** — confirms fleet_state.json exists and is parseable

### Implementation

```python
async def fleet_health_snapshot(self):
    checks = {
        "profiles_loaded": len(self.profiles),
        "state_file_ok": Path(self.state_path).exists(),
        "circuit_breakers": {},
        "agents_responsive": {},
    }
    # Poll circuit breaker states
    for agent_id in self.fleet_state.get("circuit_breakers", {}):
        cb = self.fleet_state["circuit_breakers"][agent_id]
        checks["circuit_breakers"][agent_id] = cb.get("state", "unknown")
    # Ping each profile for responsiveness
    for pid, profile in self.profiles.items():
        try:
            start = time.time()
            await self.dispatch_to_agent(
                profile,
                FleetEvent(type="ping", payload={"query": "ping"}, source="health"),
            )
            checks["agents_responsive"][pid] = {
                "status": "ok",
                "latency_ms": int((time.time() - start) * 1000),
            }
        except Exception as e:
            checks["agents_responsive"][pid] = {"status": "error", "error": str(e)[:60]}
    # Cost snapshot from last 100 dispatches
    recent = deque(self.fleet_state.get("dispatches", []), maxlen=100)
    costs = [d.get("cost_usd", 0) for d in recent if "cost_usd" in d]
    checks["cost"] = {
        "avg_cost_per_dispatch": sum(costs) / len(costs) if costs else 0,
        "total_recent_100": sum(costs),
    }
    return checks
```

### Expected Output

```json
{
  "profiles_loaded": 12,
  "state_file_ok": true,
  "timestamp": "2026-06-24T...",
  "circuit_breakers": {
    "metis_9": "CLOSED",
    "artemis_105": "CLOSED",
    ...
  },
  "agents_responsive": {
    "metis_9": {"status": "ok", "latency_ms": 2341},
    "vesta_4": {"status": "ok", "latency_ms": 512},
    ...
  },
  "cost": {
    "avg_cost_per_dispatch": 0.0032,
    "total_recent_100": 0.32
  }
}
```

### Key Design Decision

Health check pings EVERY profile. For a 12-agent fleet, that's 12 dispatches in sequence. At ~2-5s per dispatch, the full check takes 30-60s. This is acceptable for on-demand — you only run it when you suspect a problem. The observer cron does NOT do responsiveness checks (too expensive for a 4h interval).
