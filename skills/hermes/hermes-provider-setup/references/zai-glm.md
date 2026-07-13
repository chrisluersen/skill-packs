# z.ai / GLM Provider Setup

## Quick Reference

| Item | Value |
|------|-------|
| Provider slug | `zai` |
| Aliases | `zai`, `z-ai`, `z.ai`, `zhipu`, `glm` |
| API key env var | `GLM_API_KEY` (also `ZAI_API_KEY`, `Z_AI_API_KEY`) |
| Base URL env var | `GLM_BASE_URL` |
| Transport | `openai_chat` (OpenAI-compatible) |
| Model name format | lowercase: `glm-5.2`, `glm-5.1`, `glm-5-turbo`, `glm-4.7`, etc. |
| Context length | 128,000 (for GLM-5.2) |

## Two Endpoints

z.ai has **two** API endpoints with different purposes:

### General API
```
https://api.z.ai/api/paas/v4
```
For standard chat/completions. Works with general API keys.

### Coding Plan API
```
https://api.z.ai/api/coding/paas/v4
```
**Required for GLM-5.2** and coding plan subscribers. If you get a `GLM_API_KEY` from the GLM Coding Plan subscription, you MUST use this endpoint.

Set via env var:
```
GLM_BASE_URL=https://api.z.ai/api/coding/paas/v4
```

## Config Steps

```bash
# 1. Add API key to .env (AppData\Local\hermes\.env on Windows)
echo "GLM_API_KEY=your_key_here" >> "$(hermes config env-path)"

# 2. Add coding base URL
echo "GLM_BASE_URL=https://api.z.ai/api/coding/paas/v4" >> "$(hermes config env-path)"

# 3. Set provider and model via hermes config set
hermes config set model.provider zai
hermes config set model.default glm-5.2
hermes config set model.context_length 128000
hermes config set model.api_key '${GLM_API_KEY}'
```

## Available Models (from z.ai docs)

Flagship: `glm-5.2`, `glm-5.1`, `glm-5-turbo`, `glm-5`, `glm-4.7`
Others: `glm-4.7-flash`, `glm-4.7-flashx`, `glm-4.6`, `glm-4.5`, `glm-4.5-air`, `glm-4.5-x`, `glm-4.5-airx`, `glm-4.5-flash`, `glm-4-32b-0414-128k`

Model names are always lowercase in API calls.

## HF Inference Providers Routing (Alternative)

Instead of hitting z.ai directly, route GLM requests through HuggingFace's router at `https://router.huggingface.co/v1`.

**Why:** Consolidated auth via `HF_TOKEN`, no need for a separate GLM API key. Possible billing/free-tier advantages through HF.

**Model name format:** `zai-org/GLM-5.2:zai-org`

**Two config approaches:**

### Approach 1: Built-in `zai` provider, hijacked URL

```bash
# .env — set GLM_API_KEY to your HF token value (NOT ${HF_TOKEN})
GLM_API_KEY=hf_you...nGLM_BASE_URL=https://router.huggingface.co/v1

# Config
hermes config set model.provider zai
hermes config set model.default zai-org/GLM-5.2:zai-org
hermes config set model.context_length 128000
```

**Credential gotcha:** The `zai` provider's credential pool checks `GLM_API_KEY`, not `HF_TOKEN`. You must write the raw HF token into `GLM_API_KEY` — `${HF_TOKEN}` indirection does NOT work because the credential pool resolves env vars from its own `api_key_env_vars` list, not the generic `model.api_key` fallback.

**Why this works:** The `zai` provider's `_resolve_zai_base_url()` function (in `hermes_cli/auth.py`) checks `GLM_BASE_URL` first and returns it immediately if set (`if env_override: return env_override`). No probing, no override — the env var is a hard redirect. This is the mechanism that lets you transparently route z.ai traffic through any OpenAI-compatible endpoint.

### Approach 2: Custom provider with `key_env`

```yaml
# config.yaml
providers:
  hf-inference:
    base_url: https://router.huggingface.co/v1
    key_env: HF_TOKEN    # Tells Hermes to read HF_TOKEN for this provider

model:
  default: zai-org/GLM-5.2:zai-org
  provider: custom:hf-inference
  context_length: 128000
```

The `key_env` field is mandatory for custom providers — without it, `api_key_env_vars=()` and the credential pool finds no key, producing an HTTP 401 even though the token is valid.

| HTTP | Code | Meaning | Action |
|------|------|---------|--------|
| 429 | 1113 | Insufficient balance or no resource package | Subscribe to Coding Plan at z.ai/subscribe |
| 401 | — | Authentication failed | Check GLM_API_KEY value |
| 404 | — | Wrong endpoint | Check GLM_BASE_URL for trailing comments/spaces |

## Pitfalls

### Trailing comment gotcha (CRITICAL)
This causes a **404** with URL-encoded spaces in the path:
```
# WRONG — comment becomes part of URL:
GLM_BASE_URL=https://api.z.ai/api/coding/paas/v4  # Override default base URL
# → /v4%20%20/chat/completions  ← 404!

# RIGHT:
GLM_BASE_URL=https://api.z.ai/api/coding/paas/v4
```

### Coding Plan vs General endpoint
If you subscribed to the GLM Coding Plan but use the general API endpoint (`.../paas/v4`), you may get 404 or auth errors. Always use `.../coding/paas/v4` for Coding Plan keys.

### "Insufficient balance" with correct setup
401/403 = wrong key. 429 "insufficient balance" = key is correct, subscription not active. Visit https://z.ai/subscribe to activate/recharge.
