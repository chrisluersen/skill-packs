---
name: hermes-provider-setup
description: "Configure LLM providers in Hermes Agent — add API keys, set base URLs, pick models, and handle provider-specific quirks. Covers the z.ai/GLM, OpenRouter, Hugging Face, custom endpoints, and general provider workflow."
version: 1.3.0
author: Agent
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [hermes, configuration, providers, llm, api, setup]
    related_skills: [hermes-agent, hermes-cross-platform-sync, hermes-config-change-tracking]
---

# Hermes Provider Setup

Configure LLM providers in Hermes Agent — add API keys, set base URLs, pick models, and handle provider-specific quirks.

## How Hermes Providers Work

Hermes uses a **provider name** in `config.yaml` + **API keys in `.env`**. The flow:

1. `.env` exports env vars like `OPENROUTER_API_KEY`, `GLM_API_KEY`, etc.
2. `config.yaml` sets `model.provider` to the provider slug (e.g. `zai`, `openrouter`, `nous`, `custom:hf-inference`)
3. `config.yaml` sets `model.default` to the model name (e.g. `glm-5.2`, `anthropic/claude-sonnet-4`)
4. Optional: `model.base_url` or per-provider `GLM_BASE_URL` env vars override API endpoints

### The provider registry

Defined in `hermes_cli/providers.py` — each entry declares:
- `transport` — `openai_chat` (OpenAI-compatible), `anthropic_messages` (Anthropic-format), etc.
- `extra_env_vars` — env vars to check for auth (multiple aliases supported)
- `base_url_env_var` — env var name to override base URL (e.g. `GLM_BASE_URL`)
- `base_url_override` — hardcoded URL if `base_url_env_var` not set

Check the registry before guessing. Aliases are common: e.g., `zai`, `z-ai`, `z.ai`, `zhipu`, `glm` all map to the `zai` provider.

## General Workflow

```bash
# 1. Add API key to .env
#    echo "MYPROVIDER_API_KEY=sk-..." >> ~/.hermes/.env

# 2. Set provider in config
hermes config set model.provider myprovider_slug

# 3. Set model name
hermes config set model.default model-name-here

# 4. Set context length (matches model's max)
hermes config set model.context_length 128000

# 5. Optional: override API base URL
#    Set via env var (per provider) or model.base_url
hermes config set model.base_url "https://api.example.com/v1"

# 6. Test
hermes chat -q "Hello, what model are you?" -t terminal
```

## HuggingFace Inference Providers Routing

Some providers (z.ai/GLM, together, fireworks, etc.) are also available through **HuggingFace Inference Providers**, which routes requests through `https://router.huggingface.co/v1` instead of the provider's direct API.

This is useful when:
- Your HF token has Inference Providers permission but your provider-specific API key doesn't
- You want consolidated billing through HuggingFace
- You prefer HF's rate limiting and fallback behavior

### Two setup approaches

**Option A — Hijack the built-in provider (simpler)**

Point the built-in `zai` provider's base URL at the HF router:

```bash
# In .env:
# Use your HF token as the API key (the provider env var, not model.api_key)
GLM_API_KEY=hf_your_token_here
GLM_BASE_URL=https://router.huggingface.co/v1

# In config.yaml:
model.provider: zai
model.default: zai-org/GLM-5.2:zai-org
model.context_length: 128000
```

**Important:** The `zai` provider's credential pool only checks `GLM_API_KEY` / `ZAI_API_KEY` / `Z_AI_API_KEY` — it does NOT check `HF_TOKEN`. You must put the HF token value (not `${HF_TOKEN}`) into `GLM_API_KEY` in `.env`.

**Option B — Custom provider (cleaner)**

Define a custom provider in `config.yaml` under `providers:`:

```yaml
providers:
  hf-inference:
    base_url: https://router.huggingface.co/v1
    key_env: HF_TOKEN    # <--- CRITICAL: tells Hermes which env var holds the key
```

Then in `.env`:
```
HF_TOKEN=hf_your_token_here
```

And in `model:` config:
```yaml
model:
  default: zai-org/GLM-5.2:zai-org
  provider: custom:hf-inference
  context_length: 128000
```

The `key_env` field is what makes the credential pool find the API key. Without it, the custom provider has `api_key_env_vars=()` and Hermes can't authenticate.

### HF model name format for routed providers

When routing through HF Inference Providers, model names use this format:
```
<hf-org>/<model-name>:<provider-slug>
```

Examples:
- `zai-org/GLM-5.2:zai-org` — GLM-5.2 through z.ai via HF
- `zai-org/GLM-5:zai-org` — GLM-5 through z.ai via HF
- `zai-org/GLM-4.6V-Flash:zai-org` — vision model through z.ai via HF

The suffix after `:` is the underlying provider slug, and the prefix is the HF model page identifier.

### HF token requirements

Your `HF_TOKEN` must be a **fine-grained token** with the **"Make calls to Inference Providers"** permission enabled. Classic tokens and read-only tokens will get HTTP 401.

Generate one at: https://huggingface.co/settings/tokens

## Key Pitfalls

### 🟡 "Transient APIConnectionError on custom" + "No api key for provider custom" — the credential pool is empty

Hermes reports this two-phase error when a custom provider definition has a `base_url` but no way to find an API key:

```
Transient APIConnectionError on custom - rebuilt client, waiting 6s before one last primary attemp
No api key for provider custom
```

**What's happening:**
1. Phase 1 (APIConnectionError): Hermes builds an HTTP client for the custom provider's base_url and tries to connect. The provider's API rejects the unauthenticated request (usually 401), which surfaces as a connection error.
2. Phase 2 (no api key): After the retries fail, Hermes checks the credential pool and finds it empty — the custom provider has `api_key_env_vars=()` because neither `key_env` nor `model.api_key` were set.

**Root cause:** The custom provider was registered under `providers:` in config.yaml with a `base_url` but without the `key_env` field that tells Hermes which env var holds the API key:

```yaml
# ❌ Broken — no key_env, credential pool stays empty
providers:
  hf-inference:
    base_url: https://router.huggingface.co/v1

# ✅ Fixed — key_env tells Hermes where to find the token
providers:
  hf-inference:
    base_url: https://router.huggingface.co/v1
    key_env: HF_TOKEN
```

**Three fix options** (in order of robustness):

**Option A — Add `key_env` to the provider definition (best for long-term)**
```yaml
providers:
  hf-inference:
    base_url: https://router.huggingface.co/v1
    key_env: HF_TOKEN
```
Then set the value in `.env`:
```
HF_TOKEN=hf_xxx
```
Then use with `model.provider: custom:hf-inference`.

**Option B — Set `model.api_key` directly (simplest for quick test)**
```bash
hermes config set model.provider custom
hermes config set model.base_url https://router.huggingface.co/v1
hermes config set model.api_key hf_xxx
```
The `model.api_key` is the fallback — Hermes checks it when the custom provider's credential pool is empty.

**Option C — Route through the hermes-router instead**
Add the key to the router's `.env` and let the router handle auth:
```
HUGGINGFACE_API_KEYS=hf_xxx
```
Then point Hermes at the router (`http://localhost:8319/v1`) with `model.provider: custom` and `model.api_key: sk-router-1`.

**Related diagnostic:** If `model.provider: nous` (or another named provider) but `model.api_key` is set to `sk-router-1` (the router's auth key) while `model.base_url` points at the provider's direct API endpoint (e.g. `https://inference-api.nousresearch.com/v1`), Hermes sends the router key to the provider → **401**. The `sk-router-1` key is only valid on `localhost:8319`. Fix: point `model.base_url` at `http://localhost:8319/v1` to route through the router.

### Trailing comments in .env values (CATASTROPHIC)
Do NOT write:
```
GLM_BASE_URL=https://api.z.ai/api/paas/v4  # Override default base URL
```
The `  # Override...` becomes part of the URL as URL-encoded spaces: `/v4%20%20/chat/completions` → **HTTP 404**.

Write:
```
GLM_BASE_URL=https://api.z.ai/api/paas/v4
```
No trailing spaces, no comments on the same line. Comments go on their own line:
```
# Override default base URL
GLM_BASE_URL=https://api.z.ai/api/paas/v4
```

### Use `hermes config set` — not direct file editing
The `patch` and `write_file` tools are BLOCKED on `config.yaml` and `.env` for security. Always use:
```bash
hermes config set section.key value
```
This is the canonical path and bypasses the guard.

### Quoting for template variables in `model.api_key`
When setting `model.api_key` to reference an env var, use **single quotes** to prevent shell expansion:
```bash
hermes config set model.api_key '${GLM_API_KEY}'
```
Hermes resolves `${VAR_NAME}` template variables internally from the `.env` file at startup. Double quotes (`"${GLM_API_KEY}"`) would expand the variable in the shell at config-set time, which is wrong — you want the literal `${GLM_API_KEY}` string stored in config.yaml so Hermes resolves it later from its own environment.

This pattern is specifically useful when:
- The built-in provider's `api_key_env_vars` doesn't include your preferred env var name
- You want to use a different env var than the provider's default
- You're working with a custom provider that lacks `key_env` config

### Windows path: check before assuming
On Windows (git-bash), `~/.hermes/` may resolve to a different location than `C:\\Users\\<user>\\.hermes\\`. Hermes reports its real paths at:
```bash
hermes config path      # config.yaml location
hermes config env-path  # .env location
```
Always check these before writing config.

### 🟡 `hermes config set` on complex keys silently creates YAML artifacts when JSON is malformed

When setting complex config keys (`fallback_providers`, `model.provider_settings`, etc.) that expect JSON arrays or objects, `hermes config set` does NOT validate the JSON. Instead of erroring, it silently creates a YAML key like `fallback_providers[0]:` with the raw string as its value. The config key appears set but in the wrong format — the CLI reports exit 0, no error, and the failure only surfaces at runtime when Hermes ignores the malformed key.

**What to check after setting a complex key:**
```bash
grep -A2 "^<key>:" ~/.hermes/config.yaml
```
If you see `fallback_providers[0]:` instead of a proper YAML list, the JSON was malformed.

**Safe pattern:** Pass valid JSON as a single-quoted string with quoted property names:
```bash
hermes config set fallback_providers '[{"provider":"nous","default":"deepseek/deepseek-v4-flash"}]'
```

**Verify it took:**
```bash
hermes config get fallback_providers
```
Exit code 0 with structured output = success. Exit code 2 = key is not valid YAML — re-check your JSON syntax and re-apply.

**Root cause:** `hermes config set` stores the raw string value under a config key. For simple keys (strings, booleans, numbers) this works fine. For keys parsed as YAML, a malformed string creates a YAML fragment instead of overwriting the key. The CLI's write path doesn't round-trip and validate.

### API key aliases vary
Some providers accept multiple env var names. Check `providers.py`:
- z.ai: `GLM_API_KEY`, `ZAI_API_KEY`, `Z_AI_API_KEY`
- HuggingFace: `HF_TOKEN`
- OpenRouter: `OPENROUTER_API_KEY`

Set the one listed in `extra_env_vars` or the canonical name from the Hermes docs.

### 🟡 `provider: openrouter` + wrong `base_url` → HTTP 401 "User not found"
Common misconfiguration: `model.provider: openrouter` with the OpenRouter API key, but `base_url` still pointing at another provider's endpoint (e.g. `https://inference-api.nousresearch.com/v1`). OpenRouter keys are rejected by non-OpenRouter hosts with a fast 401. Fix: set `base_url` to `https://openrouter.ai/api/v1`, or route through `localhost:8319/v1` with `api_key: sk-router-1`.

## Handling Depleted Provider Credits

When a paid provider runs out of credits (`HTTP 429 "insufficient balance"` or `404 "account balance too low"`), do NOT assume all inference is blocked. Several subsystems may route independently.

### The compression auxiliary routes separately

The `auxiliary.compression` block in `config.yaml` has its own `provider/model/base_url` — it does NOT follow the main `model.provider`. In a Cascade-routed setup:

```yaml
# Main model — routes through Cascade
model:
  provider: custom:cascade
  base_url: http://localhost:8319/v1

# Compression — also through Cascade, independently
auxiliary:
  compression:
    provider: custom
    base_url: http://localhost:8319/v1
    api_key: sk-router-1
```

Cascade has its own free-tier chain (Cohere → Cerebras → Nvidia free DeepSeek), so **compression keeps working even when a specific provider's credits are depleted**. Always check `auxiliary.compression.provider` separately before assuming compression is blocked.

### Fallback providers — multi-layer safety net

The `fallback_providers` config defines alternative providers when the main provider fails (all retries exhausted). Add multiple fallbacks as a JSON array:

```bash
hermes config set fallback_providers '[{provider:"nous",default:"deepseek/deepseek-v4-flash"},{provider:"openrouter",default:"anthropic/claude-sonnet-4"}]'
```

The array is ordered — Hermes tries fallback 1 first, then 2, etc. Each entry has:
- `provider` — the provider slug (must exist in the registry or be a named provider)
- `default` — the model name to use with that provider

**Best practice:** Always pair a paid provider fallback with at least one free-tier provider (OpenRouter, Cohere, Cerebras) so a credit depletion at the primary doesn't cascade into a total outage.

### Diagnostic: which provider is actually blocking?

```bash
# Check main model provider
hermes config get model.provider

# Check compression route (often independent)
hermes config get auxiliary.compression

# Check fallback chain
hermes config get fallback_providers
```

If `model.provider` points at Cascade (`custom:cascade` → `localhost:8319/v1`), then the provider block is on Cascade's side, not Hermes config. Fix there, or add a `fallback_providers` entry that skips Cascade entirely (e.g. direct OpenRouter).

### 🟡 Free model returns HTTP 404 — slug retired or converted to paid
OpenRouter returns `This model is unavailable for free. The paid version is available now - use this slug instead: ...` when a `:free` model is retired or converted. Fix: switch to the suggested replacement slug, or pick another known-working free model.

### Quick validity probe for OpenRouter
Before changing Hermes config, verify the key and model directly:
```python
import urllib.request, json
key='sk-or-...'
data=json.dumps({'model':'vendor/model-name:free','messages':[{'role':'user','content':'hi'}],'max_tokens':5}).encode()
r=urllib.request.Request('https://openrouter.ai/api/v1/chat/completions', data=data, headers={'Content-Type':'application/json','Authorization':f'Bearer {key}'})
try:
    resp=json.loads(urllib.request.urlopen(r, timeout=20).read().decode())
    print('OK:', resp.get('model'))
except urllib.error.HTTPError as e:
    print(f'HTTP {e.code}:', e.read().decode()[:300])
```

HTTP 200 → key + model both valid. HTTP 401 → bad key or sent to wrong host. HTTP 402 → valid key, zero/inadequate credits. HTTP 404 → model slug invalid or no longer available.

### "Insufficient balance" after correct setup
If the API authenticates (no 401/403) but returns 429 "insufficient balance", the config is CORRECT — the problem is on the provider side (subscription not active, credits exhausted).

## Reference Files

- `references/zai-glm.md` — z.ai / GLM provider setup, Coding Plan endpoint, model names, error codes
