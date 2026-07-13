# Performance Triage — Step-by-Step Procedure

When the user says "Hermes is slow," follow this systematic diagnostic workflow before changing anything. The goal is to isolate *where* the bottleneck is before reaching for knobs.

## Step 1: Survey Current Config

```bash
hermes config show
```

Look for red flags:
- **`reasoning_effort: high`** → 2-10x token multiplier. Set to `""` unless deep reasoning is needed.
- **Aggressive compression** (threshold < 0.50, target_ratio < 0.10) → Frequent compression calls add latency. Relax.
- **Tight tool output caps** (max_bytes < 30000, max_lines < 1000) → Mid-task truncation causes retries/confusion. Raise.
- **Stale auxiliary model IDs** (e.g. `gemini-3-flash-preview` which doesn't exist) → Every aux task call fails/retries.
- **Auxiliary provider on Nous** with 15-min token rotation → every 15 min all aux tasks fail until token refreshes.

## Step 2: Identify the Route — Direct or Via Proxy

Check `model.provider` in config:

- **`custom:hermes-router`** (or any `localhost:8319`) → Main chat routes through a local proxy cascade. Proceed to Step 2a.
- **`openrouter` / `nous` / `anthropic` / etc.** → Direct to provider. Skip to Step 3.

### Step 2a: Router Health Check

```bash
# Is the router alive?
curl -s http://localhost:8319/health | python -m json.tool

# Router watchdog (checks provider health, rate limits, latency spikes)
python /path/to/hermes/scripts/router-watchdog.py --check

# Per-provider latency and availability
python -c "
import json
with open(r'~/.local/share/hermes-router/router_state.json') as f:
    state = json.load(f)
for name, info in sorted(state['providers'].items(), key=lambda x: x[1].get('latency_ms', 0)):
    avail = 'UP' if info.get('available') else 'DOWN'
    print(f'{name:25s} {avail:5s}  {info.get(\"latency_ms\", 0):8.1f}ms  [{info.get(\"model\", \"?\")}]')
"
```

**Red flags in router state file:**
- Providers with >4000ms latency (ollama 12s, sambanova 8.5s, minimax 4.3s) — cascade hits these
- 4+ providers DOWN — cascade burns through timeouts before finding a responder
- State file >60 minutes stale — router health check thread may not be running

### Step 2b: Test Direct API Connectivity

Isolate whether the problem is the router or the upstream API:

```python
import requests, json

# Load router's stored key (if migrating off router)
with open(r'~/.local/share/hermes-router/auth.json') as f:
    auth = json.load(f)
key = auth['providers']['openrouter'][0]

# Test direct to OpenRouter
resp = requests.post(
    'https://openrouter.ai/api/v1/chat/completions',
    headers={'Authorization': f'Bearer {key}', 'Content-Type': 'application/json'},
    json={'model': 'google/gemini-2.5-flash', 'messages': [{'role': 'user', 'content': 'test'}], 'max_tokens': 5},
    timeout=10
)
print(f'Direct OpenRouter: {resp.status_code} in {resp.elapsed.total_seconds():.2f}s')
```

If direct is fast (<2s) and the router is slow (>3s), the router cascade is the bottleneck. **Move main model to direct provider.**

## Step 3: Check Auxiliary Model Settings

```bash
python -c "
import yaml
with open(r'path/to/config.yaml') as f:
    config = yaml.safe_load(f)
aux = config.get('auxiliary', {})
for k, v in aux.items():
    if isinstance(v, dict):
        p = v.get('provider', '')
        m = v.get('model', '')
        print(f'{k:25s} provider={p:15s} model={m}')
"
```

**Checklist:**
- ✅ All model names exist (no `-preview` or deprecated suffixes)
- ✅ Provider is not Nous (unless you want 15-min token rotation overhead)
- ✅ Provider is not `main` when main model is on the router (inherits cascade latency)
- **Fix:** Pin all to `openrouter:google/gemini-2.5-flash` for stable, fast aux tasks

## Step 4: Examine Logs

```bash
# Router log (last 20 lines for errors/rate limits)
tail -20 ~/.local/share/hermes-router/router.log

# Fleet manager log
tail -20 /path/to/hermes/logs/fleet-manager.log
```

Look for: 429 (rate limited), 401 (auth failures), 503 (provider down), "exhausted" (credential pool depleted), "timeout" (slow cascade).

## Step 5: Apply Fixes (Ordered by Safety)

Do NOT change everything at once. Apply in this order, verifying each step:

| Order | Fix | Risk | Verify |
|-------|-----|------|--------|
| 1 | Fix stale vision/aux model names | None (was broken) | Vision task works |
| 2 | Move aux tasks off Nous → OpenRouter | None (reliable auth) | Aux tasks don't fail every 15min |
| 3 | Lower reasoning_effort | Low (turns off paid feature) | Chat responds faster |
| 4 | Relax compression | Low (more context preserved) | Fewer "Compressing..." pauses |
| 5 | Raise tool output caps | Low (more tokens, but cleaner) | No more truncated tool output |
| 6 | Switch main model off router → direct | Medium (changes billing) | Chat starts responding in <1s |

## Step 6: Verify

```bash
# After each change in steps 1-5
python -c "
import requests
# Test the changed endpoint directly
resp = requests.post(...)
assert resp.status_code == 200
print(f'Verified: {resp.elapsed.total_seconds():.2f}s')
"

# After all changes, restart Hermes and test:
# - Send a message (should feel faster)
# - Trigger a vision task (should work now)
# - Let context grow and observe compression behavior
```

## When NOT to Use This Procedure

- **First-time setup** — Performance tuning is premature before the system is working. Fix auth/connectivity first.
- **Router-only slowness** — If the user only complains about fleet-manager dispatches (not main chat), skip router diagnostics and go directly to fleet health.
- **Known provider outage** — If a provider is down (e.g., OpenRouter 401 "User not found"), that's an auth/billing issue, not performance tuning.
