# Router Health Impact on Auxiliary Tasks

**Context:** When `model.provider: custom:hermes-router` and `auxiliary.*.provider: main`, auxiliary tasks (vision, compression, web_extract, skills_hub, approval, etc.) route through the same router cascade as main chat.

## The Problem

If the router is unhealthy (rate-limited, few providers up, high latency), **every auxiliary call inherits that degradation**:
- Vision calls time out or fail
- Compression summaries take 10s+ instead of 1-2s
- Web extract fails on long documents
- Skills hub/curator/approval all slow down

## Quick Diagnosis

```bash
# 1. Check router liveness
curl -s http://localhost:8319/health
# Should return: {"providers":[...],"status":"ok"}

# 2. Check provider health
python ~/AppData/Local/hermes/.local/share/hermes-router/scripts/router-watchdog.py --check
# Look for: "Issue: Rate limited" or "(< 17/21 providers up)"

# 3. Check router log for patterns
tail -50 ~/AppData/Local/hermes/.local/share/hermes-router/router.log
# Look for: 429, 503, 401 repeated for same provider
```

## Mitigation Strategies

### Option A: Pin aux tasks to OpenRouter directly (recommended)
```bash
for section in vision compression web_extract skills_hub approval \
               title_generation curator monitor triage_specifier \
               kanban_decomposer profile_describer mcp; do
  hermes config set "auxiliary.$section.provider" openrouter
  hermes config set "auxiliary.$section.model" "google/gemini-2.5-flash"
done
```
**Pros:** Bypasses router entirely for aux tasks. Stable, cheap, fast.
**Cons:** Uses OpenRouter quota; need `OPENROUTER_API_KEY` in `.env`.

### Option B: Pin aux tasks to Nous directly
```bash
for section in vision compression web_extract skills_hub approval \
               title_generation curator monitor triage_specifier \
               kanban_decomposer profile_describer mcp; do
  hermes config set "auxiliary.$section.provider" nous
  hermes config set "auxiliary.$section.model" "deepseek/deepseek-v4-flash"
done
```
**Pros:** Uses Nous subscription (already paid).
**Cons:** 15-min JWT rotation; needs wrapper or `hr auth refresh` before long sessions.

### Option C: Fix the router (root cause)
- Remove chronically slow providers from free tier in `router.py` `_build_providers()`
- Ensure `auth.json` has fresh keys for all active providers
- Deploy `router-watchdog.py` as cron (every 5m, no_agent=True)
- Run `hr auth refresh` to rotate tokens

## Decision Guide

| Situation | Best Option |
|-----------|-------------|
| Router healthy, want cascade benefits | Keep `provider: main` |
| Router rate-limited, aux tasks failing | **Option A** (OpenRouter) |
| On Nous subscription, want zero extra cost | **Option B** (Nous) |
| Willing to maintain router long-term | **Option C** (fix router) |

## Related Files

- `agent-fleet-management` → `references/router-health-check.md` — full router debugging
- `cost-performance-tuning` → `references/stale-aux-model-ids.md` — stale model ID bulk fix