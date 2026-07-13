# Cascade Performance Audit

Systematic methodology for auditing Cascade router token waste, provider health, routing efficiency, and optimization opportunities.

## When to Run This Audit

- User says "Cascade feels slow" or "token usage is high"
- After adding/removing providers from auth.json
- Monthly health check
- Before and after config changes to measure impact

## Methodology

### Phase 1 — Provider Health Survey

Every provider has three data sources:

**1. Router state file** (`cascade_state.json`)

```bash
python3 -c "
import json, time
with open('$HOME/.local/share/cascade/cascade_state.json') as f:
    d = json.load(f)
print(f'State age: {(time.time()-d[\"last_updated_ts\"]):.0f}s')
for n,i in sorted(d['providers'].items()):
    s = '✅' if i.get('available') else '❌'
    m = i.get('model','?')
    lat = i.get('latency_ms',0)
    t = 'tools' if i.get('supports_tools') else 'no_tools'
    r = 'reasoning' if i.get('reasoning') else ''
    print(f'  {s} {n:25s} {lat:>5.0f}ms {m[:35]:35s} {t} {r}')
"
```

**2. Log scan for startup probes** (first 50 lines of cascade.log)

Each provider gets probed at startup. Fast probe failure pattern:
- **25–35ms ❌** → auth rejection (401 invalid key, 402 insufficient credits)
- **100–300ms ❌** → model/endpoint mismatch
- **5000+ms ❌** → true timeout

**3. Runtime log for request failures** (401, 403, 429, 413, 5xx)

```bash
grep -E '(401|403|429|413|5xx|ERROR|✗)' ~/.local/share/cascade/cascade.log | tail -30
```

### Phase 2 — Classify Each Provider

| State | State File | Log Probe | Meaning |
|-------|-----------|-----------|---------|
| 🔴 Dead | `available: false` | 25-35ms probe fail | Auth broken — remove it |
| 🟡 Degraded | `available: true` but >2s latency | Rate limits or slow | Consider demoting |
| 🟢 Healthy | `available: true`, <1s latency | Probe OK | Keep |

**Dead auth pattern:** When a provider returns 401 at 25-35ms during probe, the key is invalid/corrupt/expired. These providers are **harmful** — they waste ~35ms per probe AND every non-prompt-routed request scans them before reaching a healthy provider. Prune them.

### Phase 3 — Prompt Routing Analysis

Check how often prompt routing fires and where it sends traffic:

```bash
# Count prompt-routed requests
grep -c "prompt-route" ~/.local/share/cascade/cascade.log

# Check what model they're pinned to
grep "prompt-route" ~/.local/share/cascade/cascade.log | grep -o 'model=[^ ]*' | sort | uniq -c | sort -rn

# Check which providers they actually hit
grep "→ Trying" ~/.local/share/cascade/cascade.log | grep -o "[a-z_-]*" | sort | uniq -c | sort -rn
```

**Prompt routing waste pattern:** If prompt routing pins to a model that only 1-2 providers serve, and those providers are dead or slow, every prompt-routed request either fails or hits a 3s+ latency provider. The fix is either:
- Fix the target provider's auth (if the key is expired)
- Add an alternative provider that serves the same model
- Remove the prompt route pinning if the model isn't reliably available

### Phase 4 — Cache Efficiency

```bash
grep -c "↩ cache hit" ~/.local/share/cascade/cascade.log
grep -c "cache miss" ~/.local/share/cascade/cascade.log
```

If cache count < 10 in a long session: cache is not a significant factor. Chat conversations rarely repeat identical payloads. Don't optimize for cache — focus on routing efficiency and dead provider pruning.

### Phase 5 — Fast Routing & Token Estimation

Check whether `FAST_ROUTE_THRESHOLD` is enabled:

```bash
grep "Fast routing" ~/.local/share/cascade/cascade.log
```

If disabled (threshold=0): short requests take the same cascade path as long ones. Enable with `FAST_ROUTE_THRESHOLD=200` in `.env` for simple queries (status checks, one-liners) to hit low-latency providers first.

Check whether tiktoken is available:

```bash
grep "tiktoken" ~/.local/share/cascade/cascade.log
```

If "unavailable": token counts use char/4 heuristic which is less accurate. Install with the cascade venv's pip: `venv/Scripts/pip install tiktoken`

### Phase 6 — Pre/Post Processing Audit

Check whether Cascade has any prompt compression or output filtering:

```bash
grep -n "_preprocess_prompt\|_postprocess_output\|def _preprocess\|def _postprocess" ~/.local/share/cascade/cascade.py
```

If both are empty/no-op bodies: Cascade is purely a routing layer with zero token optimization. Every byte the client sends is forwarded as-is. No compression, dedup, or summarization.

### Phase 7 — Total Provider Count vs Working Count

```bash
python3 -c "
import json
with open('$HOME/.local/share/cascade/cascade_state.json') as f:
    d = json.load(f)
ps = d['providers']
total = len(ps)
avail = sum(1 for p in ps.values() if p.get('available'))
dead = total - avail
print(f'Total: {total}  Available: {avail}  Dead: {dead}')
print(f'Waste ratio: {dead}/{total} = {dead/total*100:.0f}% providers failing every cascade')
"
```

## Recommended Fixes (by risk)

### Zero-risk (immediate)

1. **Prune dead providers** — remove providers showing `available: false` from auth.json or set their keys to empty. Saves 25-35ms per probe × N dead providers per request.
2. **Add healthy provider aliases** — if a prompt route targets a model only served by dead providers, add a new provider entry that serves the same model through a working key.
3. **Install tiktoken** — `venv/Scripts/pip install tiktoken` for accurate token estimation.

### Low risk

4. **Enable FAST_ROUTE_THRESHOLD** — set `FAST_ROUTE_THRESHOLD=200` in `.env`. Short requests route to low-latency providers first.
5. **Re-balance cost tiers** — if several dead providers were in tier 0 (free), the remaining tier 0 providers carry more load. Adjust tier assignment.

### Medium risk

6. **Add prompt compression to Cascade** — refactor `_preprocess_prompt` to strip repeated system messages, collapsible whitespace, or very old messages. This is a code change to cascade.py, not config.
7. **Add output filtering** — `_postprocess_output` can strip trailing/leading whitespace, dedup newlines, etc. Saves token cost per response.

## Example: Full Audit Report Template

```
## Cascade Health Report — YYYY-MM-DD

**Providers:** X total, Y available, Z dead (Z% waste)

**Dead provider list:**
- provider_a (auth: 401, 28ms)
- provider_b (auth: 401, 31ms)
- provider_c (auth: 402, 25ms)

**Prompt routing:** X hits, pinned to model Y.
Affected request count: Z
Average latency when pin fires: Xms vs healthy route Yms

**Cache:** X hits, Y misses. Cache hit rate: Z%

**Fast route:** Enabled/Disabled
**Tiktoken:** Available/Unavailable

**Recommendations:**
1. Prune providers: [list]
2. Fix/mitigate prompt route for model X
3. Enable fast route
4. Install tiktoken
```
