---
name: cascade
description: >-
  Install, configure, maintain, and extend Cascade — the local
  OpenAI-compatible smart model cascade with cost-based provider priority (free → cheap → premium).
  Covers Windows setup, adding custom providers, auth management, cost-field configuration,
  lifecycle operations, and 401/402 error recovery.
tags: [cascade, ai-provider, windows, load-balancing, smart-routing, provider, fallback, prompt-routing, openai-compatible, cost-priority]
related_skills: [cost-performance-tuning, fleet-health-watchdog, web-research-synthesis]
---

# Cascade

Installed at `~/.local/share/cascade/`. Flask-based OpenAI-compatible proxy, cost-first cascade (free → cheap → premium). **Runs from a venv:** `venv/Scripts/python.exe cascade.py`.

Renamed from `hermes-router` on 2026-07-03. Data dir migrated from `~/.local/share/hermes-router/`.

**Repo:** [github.com/chrisluersen/cascade](https://github.com/chrisluersen/cascade) — public, MIT. The public face of the routing infrastructure. README is SVG-only; this SKILL.md is the authoritative operating guide.

## Quick reference

**Active config:**
- `custom_providers` name: `cascade`
- `base_url: http://localhost:8319/v1`, `api_key: sk-router-1`, `default: any`
- Port 8319

**Cascade tiers:**
```
Tier 0 (cost=0, free):     groq → cerebras → sambanova → gemini → github_models
                            → cohere → mistral → huggingface → nvidia → zai
                            → naga → openrouter → nemotron-ultra-free
Tier 1 (cost=1, cheap):    deepseek-v4-flash → hy3-preview → mimo-v2.5
                            → minimax-m3 → nous_portal
Tier 2 (cost=2, premium):  deepseek-v4-pro → glm-5.2 → sonnet-4.6 → sonnet-5
Tier 3 (cost=3, local):    ollama
```

## Built-in Features

### Trace IDs (distributed tracing)

Every request through cascade gets a unique trace ID (12-hex UUID prefix), logged on every line and returned as the `X-Trace-Id` response header. This makes it possible to correlate a response with its internal routing decisions, provider selection, and cost.

| Feature | Detail |
|---------|--------|
| Format | 12-char hex (`uuid4().hex[:12]`) |
| Header | `X-Trace-Id` in every response |
| Logging | Every log line in `_route_completion` prefixed with `[trace_id]` |
| Status | `/v1/status` → `trace.enabled`, `trace.header` |
| Config | `TRACE_ENABLED: bool = True` (constant in cascade.py) |

**Diagnostic usage:** When debugging a slow/failed request, grep the trace ID from cascade's log output. Every step (provider selection, filtering, cost) is logged under the same ID.

### Cost Tracking (per-request USD estimate)

Every request records estimated cost using `KNOWN_MODEL_COSTS` — a dict of 21+ models with input/output pricing per 1M tokens. Costs accumulate per-provider and are exposed at `/v1/status` and `/metrics`.

**Pricing lookup:**
1. Exact model ID match (e.g., `deepseek/deepseek-v4-flash` → `(0.098, 0.196)`)
2. Longest-prefix substring fallback (e.g., `gpt-4o-*` matches `gpt-4o` entry)
3. Default: `0.0` (free tier safe default)

**Outputs:**
| Endpoint | What it shows |
|----------|--------------|
| `/v1/status` | Per-provider `stats.cost_total_usd`, `stats.prompt_tokens`, `stats.completion_tokens` |
| `/metrics` | `cascade_cost_total_usd` Prometheus gauge per provider |
| Log file | `$ cost=0.000646 (2976+1806 tok)` on every successful request |

**Config:**
- Prices live in `KNOWN_MODEL_COSTS` dict in cascade.py (lines ~119-141)
- Provider-level accumulation via `stats.record_cost(name, pt, ct, model)` method

### Bulkheads (per-provider concurrency limits)

Semaphore-based per-provider concurrency limit. Prevents one slow provider from consuming all worker threads.

| Config | Default | Env var |
|--------|---------|---------|
| Max concurrent per provider | 4 | `BULKHEAD_MAX_CONCURRENT` |

**How it works:**
- Before calling a provider, `bulkhead.acquire(provider_name)` is called (blocking if at max)
- After response/error, `bulkhead.release(provider_name)` releases the slot
- `/v1/status` shows `bulkhead.enabled`, `bulkhead.max_concurrent`, and `bulkhead.per_provider.{name}.active`

### Response cache (in-memory LRU)
Cascade has an in-memory LRU response cache for non-streaming requests. Identical requests (same model + messages) return cached results — saving free-tier quota for novel queries.

| Env var | Default | Description |
|---------|---------|-------------|
| `CACHE_TTL_SECONDS` | `600` | TTL for cached responses. Set `0` to disable. |
| `CACHE_MAX_SIZE` | `500` | Maximum cached entries before LRU eviction. |

Check cache efficiency via `/metrics` — look for `cascade_cache_hits` / `cascade_cache_misses` (Prometheus counters).

### Adaptive max_tokens (via `_compute_max_tokens`)

When `max_tokens=0` in the request, Cascade allocates a budget based on input length:

```python
def _compute_max_tokens(request_max, input_tokens):
    if request_max and request_max > 0:
        return request_max
    return min(4096 + 2 * input_tokens, 8192)
```

**Behavior:**
- If `max_tokens > 0`, honoured as-is.
- If `max_tokens=0` or absent, computes `min(4096 + 2*input_tokens, 8192)`.
- Tool call requests exempted from clamping.

## Lifecycle

### Full restart sequence

**⚠️ Proxy key gotcha:** If `PROXY_API_KEYS` is set (even empty `""`) in your current shell, `load_dotenv()` from `.env` is silently ignored and `os.environ.get("PROXY_API_KEYS", "sk-cascade-1")` falls through to the code default. Always pass the key inline or unset it first.

```bash
# 1) Kill all cascade processes (may need multiple PIDs)
wmic process where "commandline like '%%cascade.py%%' and not commandline like '%%bash%%'" delete 2>&1
# Verify port is clear:
netstat -ano | grep 8319 | grep LISTEN

# 2) Clear stale state
rm -f ~/.local/share/cascade/cascade_state.json
rm -f ~/cascade_state.json
rm -f ~/.local/share/cascade/.watchdog_state

# 3) Start with PROXY_API_KEYS inline (defeats setdefault)
export CASCADE_AUTH_FILE="~/AppData/Local/hermes/.local/share/cascade/auth.json"
export CASCADE_STATE_FILE="~/AppData/Local/hermes/.local/share/cascade/cascade_state.json"
cd ~/.local/share/cascade && PROXY_API_KEYS=sk-router-1 venv/Scripts/python cascade.py

# 4) Wait ~2 min for probes, then verify
netstat -ano | grep 8319 | grep LISTEN
curl -s http://localhost:8319/health
```

### Feature extension workflow

Adding a new feature to cascade follows a consistent pattern. Reference this when patching cascade.py:

1. **Constants** — add env-var-backed constants at module top (~line 109-163). Defaults make features self-documenting.
2. **Core logic** — modify `_route_completion()` or add helper methods. Add Stats class methods for tracking (`record_cost`, `record_trace`).
3. **Route handlers** — update `chat()` or `anthropic_messages()` to extract and return new data (e.g., trace ID in response headers).
4. **Status endpoint** — add new section to the `/v1/status` dict (currently ~line 2360). Include enabled flag + state.
5. **Metrics** — add Prometheus gauge/ counter to `/metrics` (~line 2420-2458). Every feature that aggregates data should expose it.
6. **Validation** — restart cascade, verify routing works, check `/v1/status` has new fields, check `/metrics` has new counters.

**Caught a 500 on /v1/status?** Check the cascade log output first — `NameError` for undefined constants is the most common cause after adding status sections. Add the missing constant and restart.

### Auto-Start (Dual Mechanism)
- **VBS wrapper:** `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\CascadeLauncher.vbs`
- **Task Scheduler:** "Cascade" task (logon trigger, 30s delay)
- **Launcher script:** `~/AppData/Local/hermes/scripts/start-cascade.bat`

### Config in Hermes
```yaml
custom_providers:
  - name: cascade
    provider: custom
    api_key: sk-router-1
    base_url: http://127.0.0.1:8319/v1
    default: any
```

### Bash alias
```bash
alias cascade='hermes config set model.provider custom && hermes config set model.base_url http://localhost:8319/v1 && hermes config set model.api_key sk-router-1 && hermes config set model.default any && echo "Cascade active"'
```

## Verification
```bash
# Alive?
netstat -ano | grep 8319 | grep LISTEN
curl -s http://localhost:8319/health

# Cascade works?
## ⚠️ On Windows, Python urllib resolves `localhost` to IPv6 first → 2s delay.
##    Always use `127.0.0.1` in Python test clients (see references/windows-http-testing-pitfalls.md)
python3 -c "
import urllib.request, json
data = json.dumps({'model':'any','messages':[{'role':'user','content':'hi'}],'max_tokens':5}).encode()
r = urllib.request.Request('http://127.0.0.1:8319/v1/chat/completions', data=data,
  headers={'Content-Type':'application/json','Authorization':'Bearer sk-router-1'})
resp = json.loads(urllib.request.urlopen(r, timeout=15).read().decode())
print(f'Cascade: {resp[\"model\"]}')
"

# Provider state
python3 -c "
import json, time
with open('~/AppData/Local/hermes/.local/share/cascade/cascade_state.json') as f:
    d = json.load(f)
print(f'State: {(time.time()-d[\"last_updated_ts\"]):.0f}s old')
for n,i in sorted(d['providers'].items()):
    s='✅'if i.get('available')else'❌'
    print(f'  {s} {n:20s} {i.get(\"latency_ms\",0):>5.0f}ms model={i.get(\"model\",\"?\")} tools={i.get(\"supports_tools\",\"?\")}')
"
```

## Diagnostics

### Log files
| File | Purpose |
|------|---------|
| `~/.local/share/cascade/cascade.log` | Request/cascade log (start with `2>> cascade.log`) |
| `~/.local/share/cascade/autostart.log` | Boot diagnostics from start-cascade.bat |
| `~/.local/share/cascade/cascade_state.json` | Provider probe cache (24h TTL) |
| `~/.local/share/cascade/auth.json` | Credential store |

### Metrics
`GET /metrics` at `localhost:8319/metrics` — Prometheus counters.

### Fast probe = auth rejection
- **25-35ms ❌** → key rejected (401 invalid key / 402 insufficient credits)
- **100-300ms ❌** → model/endpoint mismatch
- **5000+ms ❌** → true timeout

## Systematic Health Audit

Run this when Cascade feels slow, providers show as unavailable, or after adding/removing any keys. Combines three data sources to produce a complete provider inventory.

### 1 — Auth Coverage Scan

cascade.py declares 21 providers in `PROVIDERS`. auth.json may not cover them all.

```bash
# Count configured vs keyed providers
curl -s http://localhost:8319/health | python3 -c "
import sys, json
d = json.load(sys.stdin)
configured = len(d['providers'])
print(f'Configured: {configured} providers')
" 2>&1

python3 -c "
import json
with open('~/AppData/Local/hermes/.local/share/cascade/auth.json') as f:
    d = json.load(f)
keyed = list(d.get('providers', {}).keys())
print(f'Keyed in auth.json: {len(keyed)} — {sorted(keyed)}')
"
```

**Unkeyed providers** (configured but no auth.json entry) are expected for OpenRouter-reusing providers (deepseek-v4-flash, etc.) and ollama (local). Every other unkeyed provider wastes probe cycles.

### 2 — Provider State Inspection

`cascade_state.json` shows what the background probes found:

```bash
python3 -c "
import json, time
with open('~/AppData/Local/hermes/.local/share/cascade/cascade_state.json') as f:
    d = json.load(f)
print(f'State age: {(time.time()-d[\"last_updated_ts\"]):.0f}s (TTL: 24h)')
print(f'{\"Provider\":25s} {\"Avail\":6s} {\"Rating\":6s} {\"Lat(ms)\":>8s} {\"Tools\":6s} {\"Model\":30s}')
print('-'*85)
for n,s in sorted(d['providers'].items()):
    a = '✅' if s.get('available') else '❌'
    r = str(s.get('rating','?'))
    l = f\"{s.get('latency_ms',0):.0f}\"
    t = '✓' if s.get('supports_tools') else '✗'
    m = s.get('model','?')[:30]
    print(f'{n:25s} {a:6s} {r:6s} {l:>8s} {t:6s} {m:30s}')
"
```
**Key patterns to look for:**

- **0 requests, avail=False** — never probed or probe skipped (unkeyed provider). Harmless noise since availability filtering now skips them at route time.
- **N requests, ALL errors (reqs == errs)** — provider is configured, tried, and failing every time. **Mitigated by availability filtering:** `_route_completion()` now filters providers where `available=False` before the routing loop, so error-storm providers are skipped silently. The provider state still probes them (keeps state fresh), but they never waste request time.
- **N requests, low/zero errors, avail=False** — probe failed despite some past success. Likely stale state or intermittent issue. Force re-probe.
- **Latency wildly different from expected** — fast probe (25-35ms) = auth rejection; medium (100-300ms) = model endpoint mismatch

### 3 — Live Status Check

The `/v1/status` endpoint shows runtime state including circuit breakers, key cooldowns, and request counts:

```bash
curl -s http://localhost:8319/v1/status -H 'Authorization: Bearer sk-router-1' | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f'Cache: {json.dumps(d.get(\"cache\",{}), indent=2)}')
print(f'Fast routing: enabled={d.get(\"fast_routing\",{}).get(\"enabled\",False)}')
print()
print(f'{\"Provider\":25s} {\"Avail\":6s} {\"Rating\":6s} {\"Keys\":8s} {\"Lat(ms)\":>8s} {\"Tools\":6s} {\"Reqs\":>6s} {\"Errs\":>6s} {\"Breaker\":10s}')
print('-'*90)
for n,p in sorted(d.get('providers',{}).items()):
    keys = p.get('keys', [])
    rdy = sum(1 for k in keys if k['status']=='ready')
    cool = sum(1 for k in keys if k['status']=='cooling')
    brk = p.get('breaker',{})
    brk_open = 'OPEN' if brk.get('open') else 'closed'
    brk_in = brk.get('opens_in_s', '')
    print(f'{n:25s} {str(p.get(\"available\",\"?\")):6s} {str(p.get(\"rating\",\"?\")):6s} {rdy}/{rdy+cool:7s} {str(p.get(\"latency_ms\",\"?\")):>8s} {str(p.get(\"supports_tools\",\"?\")):6s} {str(p.get(\"stats\",{}).get(\"total_requests\",0)):>6s} {str(p.get(\"stats\",{}).get(\"errors\",0)):>6s} {brk_open:10s}')
"
```

### 4 — Synthesis: What to Do

| Finding | Action |
|---------|--------|
| Provider configured, no key in auth, not OpenRouter-reusing | Add key or remove from cascade.py PROVIDERS |
| reqs == errs (e.g. deepseek-v4-flash: 386/386) | **Mitigated by availability filtering** — providers with `available=False` are skipped at route time, so error-storm providers never waste request time. Still worth adding the key or pruning the provider to reduce state file noise. |
| All 21 providers, only 3 working | Prune dead weight: providers with no key and no route are pure overhead |
| avail=False but lat < 50ms | Auth rejection — check key validity |
| Cache hit rate < 1% | Expected for chat traffic; not a problem to fix |

### 5 — Quick One-Liner: Working vs Dead Count

```bash
python3 -c "import json; d=json.load(open('~/AppData/Local/hermes/.local/share/cascade/cascade_state.json')); ps=d['providers']; print(f'Available: {sum(1 for p in ps.values() if p.get(\"available\"))}/{len(ps)}')"
```

## Auth.json structure
```json
{
  "providers": {
    "gemini": ["AI..."],
    "sambanova": ["uuid-format"],
    "cerebras": ["csk-..."],
    "cohere": ["alphanumeric"],
    "mistral": ["alphanumeric"],
    "groq": ["gsk_..."],
    "github_models": ["ghp_..."],
    "nous_portal": ["sk-..."],
    "huggingface": ["hf_..."]
  }
}
```
OpenRouter-reusing providers (deepseek-v4-flash, deepseek-v4-pro, glm52, sonnet-4.6, sonnet-5, nemotron-ultra-free, hy3-preview, mimo-v2.5, minimax-m3) need NO auth.json entry — they share the `openrouter_keys` array in `cascade.py`.

## Common Pitfalls
- `model.default: any` only works through cascade (port 8319). Direct providers return 404.
- `AUTH_FILE` and `STATE_FILE` default to `./` relative paths. Always set both env vars.
- Stale state may live in `~/cascade_state.json` if started without `CASCADE_STATE_FILE`. Check both paths.
- `model.provider: openrouter` + non-OpenRouter `base_url` → HTTP 401 "User not found".
- `hermes config set` can silently fail on Windows. Verify by reading the file.
- Config layering: `$HERMES_HOME/config.yaml`, `~/.hermes/config.yaml`, wiki-synced copies all conflict.
- **Proxy key mismatch:** When Hermes config uses a different key than cascade expects (e.g. after a rename or env var change), update all **4 locations**: `auxiliary.compression`, `delegation`, `custom_providers`, `fallback_providers`. Also sweep all skills for stale key references. See `references/cascade-auth-debugging.md`.

## Watchdog
Deployed: `cascade-watchdog.py` (cron, every 5m, no_agent). Compares `cascade_state.json` snapshots, detects availability flips, latency spikes, rate limits. Silent when healthy.

## Prompt Routing (keyword-based model pinning)

Cascade supports keyword-based prompt routing — certain prompts automatically pin a specific OpenRouter model before the cost cascade runs. This is implemented in `cascade.py` as `PROMPT_ROUTE_RULES` in `_route_completion()`.

**How it works:** Before provider selection, `_pick_model_by_prompt()` scans the user message for keywords. First match wins. If no rule matches, normal cost-first cascade runs. The pinned model is set **before** `_ordered_providers()` so the cascade cannot override it.

**Current rules** (see `references/prompt-routing-rules.md` for the exact list):
- **Code/debug** → deepseek/deepseek-v4-flash
- **Creative/writing** → openai/gpt-4o
- **Fast/simple** → deepseek/deepseek-v4-flash (with negative matches to avoid false positives)
- **Complex engineering** → anthropic/claude-sonnet-5
- **Long-context** → minimax-m3

**Key behaviors:**
- Case-insensitive substring match against full prompt content
- First matching rule wins
- Each rule has a `negative` list: keywords that CANCEL the match
- Tool-aware: skips free-tier models when tools are present in the request
- Length-aware: skips free-tier for long prompts (>2K estimated tokens)
- Greetings fall through to normal cost cascade (no greedy catch-all)

**To add/change a rule:**
1. Edit `PROMPT_ROUTE_RULES` in `cascade.py`
2. Restart cascade (kill all, clear state, restart — see Lifecycle above)
3. Validate with the test script in `scripts/validate-prompt-routing.sh` (see below)
4. Update this skill's reference doc

## ⚠️ On Windows, use `127.0.0.1` not `localhost` in Python test clients
##    (see references/windows-http-testing-pitfalls.md)
**To validate:**
```bash
python -c "
import urllib.request, json

tests = [
    ('code', 'debug this python function', ['deepseek-v4-flash']),
    ('creative', 'write a short story', ['gpt-4o']),
    ('fast', 'what is HTTP in one sentence', ['deepseek-v4-flash']),
    ('complex', 'architect a cache plan', ['claude-sonnet-5', 'claude-5']),
    ('long_context', 'summarize this document', ['minimax-m3']),
]

for name, prompt, expected_models in tests:
    data = json.dumps({'model':'openrouter/auto','messages':[{'role':'user','content':prompt}],'max_tokens':5}).encode()
    req = urllib.request.Request('http://127.0.0.1:8319/v1/chat/completions', data=data,
      headers={'Content-Type':'application/json','Authorization':'Bearer sk-router-1'})
    resp = json.loads(urllib.request.urlopen(req, timeout=20).read().decode())
    model = resp.get('model', '')
    passed = any(exp in model for exp in expected_models)
    print(f"{'✓' if passed else '✗'} {name}: {model}")
"
```

## Cost Optimization

Five independent optimizations that reduce token consumption when running Hermes through Cascade. They work together: less context retained → cheaper compression runs → shorter prompts → smaller output budgets.

All five can be applied independently. Apply them in order — #1 saves the most immediately.

### 1. Route Compression Through Cascade

Moves context summarization from Nous (paid, ~$0.30/Mtok output) to Cascade's free-tier providers.

```bash
hermes config set auxiliary.compression.provider custom
hermes config set auxiliary.compression.base_url http://localhost:8319/v1
hermes config set auxiliary.compression.api_key "sk-router-1"
hermes config set auxiliary.compression.model "any"
hermes config set auxiliary.compression.timeout 30
```

**Saved per compression:** ~10K-30K output tokens × $0.30 = **$3-9K/Mtok at scale**

### 2. Reduce `agent.max_turns`

```bash
hermes config set agent.max_turns 30
```

Default is 60. At 30 turns, context compresses twice as often — but each compression call is cheaper because the context is half the size. Few-turn tasks (<10 turns) unaffected. Long research sessions compress earlier.

### 3. Tighter Compression Threshold & Target Ratio

```bash
hermes config set compression.threshold 0.25
hermes config set compression.target_ratio 0.12
```

Triggers compression when context exceeds 25% of model's context window (was 35%) and squeezes to 12% (was ~15%). Context compresses 30% sooner and targets 20% more aggressive reduction.

### 4. Adaptive max_tokens

Adds a block at the top of `_route_completion()` in `cascade.py` that clamps excessive output budgets. **Patch location:** inside `_route_completion()` right after `est_tokens` and before `# Prompt-based routing`:

```python
    # ── Adaptive max_tokens ──────────────────────────────────────────────────
    _client_mt = payload.get("max_tokens") or payload.get("max_completion_tokens") or 0
    _adaptive_mt = None
    if not payload.get("tools"):
        if _client_mt <= 0 or _client_mt > 16384:
            content = " ".join(
                m["content"] if isinstance(m.get("content"), str)
                else " ".join(p.get("text", "") for p in m["content"] if isinstance(p, dict))
                for m in messages if m.get("content")
            )
            clen = len(content)
            if clen < 50:         _adaptive_mt = 256
            elif clen < 200:      _adaptive_mt = 512
            elif clen < 1000:     _adaptive_mt = 2048
            else:                 _adaptive_mt = 4096
        elif _client_mt > 8192 and est_tokens < 2000:
            _adaptive_mt = 4096
    if _adaptive_mt and (_client_mt <= 0 or _adaptive_mt < _client_mt):
        payload = dict(payload)
        payload["max_tokens"] = _adaptive_mt
```

Saves ~40-60% fewer output tokens on short queries. Tool calls bypass the clamp (need room for tool responses).

### 5. Cascade Cache Tuning

Already applied in cascade.py defaults:
```python
CACHE_TTL      = 600   # was 300  — 10 min instead of 5
CACHE_MAX_SIZE = 500   # was 100  — 5× more cached responses
```

Override via env vars: `CACHE_TTL_SECONDS=0` to disable, `CACHE_MAX_SIZE=1000` to grow further.

### Cost Impact Estimate

| Optimization | Est. savings | Complexity |
|---|---|---|
| Compression via Cascade | ~$3-9/Mtok on compression output | Simple config |
| max_turns 60→30 | ~2× compression frequency, half-size prompts | One config key |
| Threshold 35%→25% | ~30% more aggressive | One config key |
| Adaptive max_tokens | ~40-60% fewer output tokens on short queries | One `patch` to cascade.py |
| Cache TTL/size increase | Hit rate improvement depends on usage pattern | Two env vars |

### Pitfalls

- **Adaptive max_tokens skips tool calls.** The `not payload.get("tools")` guard is correct — don't remove it.
- **max_turns too low in long sessions.** Raise to 40 (not back to 60) if context compaction breaks flow.
- **Cascade restart resets cache.** The `ResponseCache` is in-memory. Warm-up takes ~500 unique requests.
- **Compression timeout.** If `auxiliary.compression.timeout` is too low, compression may fail on long contexts — Hermes backfills uncompressed (no data loss, just unoptimized).

## Provider Setup Guide

Add LLM API providers to Cascade's routing system. Two tiers:
- **Existing providers** (code already in `_build_providers`): just add API keys to `auth.json`
- **New providers** (not yet in `_build_providers`): add a code block + keys

### Provider Ranking (Best Value for Setup)

| Priority | Provider | Setup | Free Model | Notes |
|----------|----------|-------|------------|-------|
| 1 | OpenRouter | Keys only | 300+ models | One key unlocks ~9 cascade entries |
| 2 | Groq | Keys only | Llama-3.3-70b | Fastest, generous free tier |
| 3 | Gemini | Keys only | Gemini 2.5 Flash | 1M context, free |
| 4 | GitHub Models | Keys only | GPT-4o via PAT | Free GPT-4o |
| 5 | SambaNova | Keys only | DeepSeek V3.2 | Free, fast |
| 6 | Cerebras | Keys only | GPT-OSS-120B | Fastest inference |
| 7 | Z.AI | Keys only | GLM-4.5-Flash | Instant signup at z.ai, 1K req/day |
| 8 | NVIDIA NIM | Keys only | DeepSeek V4-Flash | build.nvidia.com, 40 req/min |
| 9 | Naga | Keys only | Nemotron-3-Super | naga.ac, 100 req/day, supports tools+reasoning |
| 10 | DeepInfra | Code + keys | Llama-3.3-70B | deepinfra.com, free tier |
| 11 | Fireworks AI | Code + keys | Llama-3.3-70B | fireworks.ai, free tier |
| 12 | Mistral | Keys only | Mistral Medium | Free tier |
| 13 | Cohere | Keys only | Command-A | 1K free calls/mo |
| 14 | HuggingFace | Keys only | GPT-OSS-120B | Free, rate-limited |

### Adding New Provider Code Blocks

Edit `~/.local/share/cascade/cascade.py` in `_build_providers()` (around line 690-720, after `huggingface` block, before the `if not providers:` check).

**Standard pattern:**
```python
    # --- provider-name (description) ---
    provider_keys = _keys_for("provider-name", "PROVIDER_API_KEYS")
    if provider_keys:
        providers.append({
            "name":     "provider-name",
            "base_url": "https://api.provider.com/v1",
            "model":    os.environ.get("PROVIDER_MODEL", "default-model-name"),
            "keys":     provider_keys,
            "cost":     0,  # 0=free, 1=cheap, 2=premium, 3=local
        })
```

Key fields: `name` (provider id in routing), `base_url` (OpenAI-compatible `/v1/chat/completions`), `model` (default model, overridable via env var), `keys` (list from `_keys_for()` for rate-limit fan-out), `cost` (0=free, 1=cheap, 2=premium, 3=local).

Placement: insert near other free providers (Tier 1-2) based on quality.

### Pitfalls

- **Process kill on Windows**: MSYS2 `kill` doesn't work for Windows-native PIDs. Use `taskkill /F /PID <PID>` or `Stop-Process`.
- **Restart loses cache**: ResponseCache is in-memory. Warm-up takes ~500 unique requests.
- **model name mismatch**: The provider's model field must match what the API expects.
- **auth.json file locking**: Kill the server before modifying auth.json.
- **`_keys_for` order**: auth.json is checked first, then .env.

### Verification

```bash
# 1. Restart, check startup logs for key loading
# 2. Health check + provider listing
curl -s http://127.0.0.1:8319/health | python3 -c "import sys, json; d=json.load(sys.stdin); print(f'{len(d[\"providers\"])} providers')"
```

## Refs absorbed from old skills
- `hermes-router` skill → merged into this one on 2026-07-03
- `openrouter-hermes-router-fix` skill → merged into this one on 2026-07-03
- `cascade-cost-optimization` skill → merged 2026-07-09
- `cascade-provider-setup` skill → merged 2026-07-09
- See `references/cascade-performance-audit.md` for systematic performance audit methodology (provider health, dead auth detection, prompt routing waste, cache efficiency, fast routing analysis)
