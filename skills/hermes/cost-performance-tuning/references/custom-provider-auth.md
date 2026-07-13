# Custom Provider Authentication Troubleshooting

## The Problem

You configured a custom provider (e.g. `hf-inference` pointing to `https://router.huggingface.co/v1`) but get HTTP 401 on every API call:

```
AuthenticationError [HTTP 401]
  Provider: custom  Model: zai-org/GLM-5.2
  Endpoint: https://router.huggingface.co/v1
  Error: HTTP 401: Error code: 401 - {'error': 'Invalid username or password.'}
```

## Root Cause: api_key Mismatch

Hermes stores **two independent pieces** of provider configuration:

| Config key | Purpose | Where it lives |
|------------|---------|----------------|
| `providers.<name>.base_url` | The API endpoint to hit | `config.yaml` under `providers:` section |
| `model.api_key` | The credential sent as Bearer token | `config.yaml` under `model:` section |
| `providers.<name>.api_key` | Provider-level credential override (optional) | `config.yaml` under `providers.<name>` |

The model's `api_key` is what gets sent as the `Authorization: Bearer <key>` header to the provider's `base_url`. If you previously used a different endpoint (e.g. a local router at `localhost:8319` with a local router key `sk-router-1`), and then switched the provider's `base_url` to a new endpoint (e.g. HuggingFace Inference Providers), **the old api_key is still being sent to the new endpoint** → HTTP 401.

## Debugging Workflow

### Step 1: Identify which endpoint is actually being hit

Check the error message — it shows the actual URL:

```
Endpoint: https://router.huggingface.co/v1
```

If this doesn't match what you expect, the provider's `base_url` is overriding the model's `base_url`.

### Step 2: Check what api_key is being sent

```bash
hermes config | grep -A2 'Model:'
```

Look for `api_key` — if it's a stale key from a previous provider setup, that's your culprit.

### Step 3: Verify the correct credential works

Test directly with curl to isolate Hermes from the auth issue:

```bash
source "$HOME/AppData/Local/hermes/.env" 2>/dev/null
curl -s -w "\nHTTP:%{http_code}" \
  -H "Authorization: Bearer $HF_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"model":"zai-org/GLM-5.2","messages":[{"role":"user","content":"hi"}],"max_tokens":10}' \
  https://router.huggingface.co/v1/chat/completions
```

- **HTTP 200** → token is valid, the issue is Hermes config
- **HTTP 401** → token is invalid/expired, or the model is gated

### Step 4: Fix the model's api_key

Set the api_key to the correct credential. Hermes supports `${ENV_VAR}` syntax in config values — use it instead of hardcoding secrets:

```bash
hermes config set model.api_key '${HF_TOKEN}'
```

This stores the literal `${HF_TOKEN}` in config.yaml and resolves it from the environment at runtime. The env var must be set in `~/.hermes/.env`:

```
HF_TOKEN=hf_your_token_here
```

### Step 5: Clear stale model.base_url (if needed)

If the model has a `base_url` that conflicts with the provider's `base_url`, clear it so the provider's URL takes full effect:

```bash
hermes config set model.base_url ''
```

**Precedence rule:** When a `model.provider` is set to `custom:<name>`, the `<name>` provider's `base_url` is used as the primary endpoint. The `model.base_url` only applies when `model.provider` is `custom` (without a named provider subkey) or an empty string.

### Step 6: Restart the session

```bash
/reset   # in-session
# or start a new 'hermes' process
```

Config changes only take effect on new sessions.

## Two Flavors of 401

| Flavor | Signal | Cause | Fix |
|--------|--------|-------|-----|
| **Config-level auth mismatch** | `model.api_key` is wrong for the provider's `base_url` | Switched provider endpoint but kept old api_key | `hermes config set model.api_key '${CORRECT_ENV_VAR}'` |
| **Model-not-found-at-provider** (Pitfall #14) | 401 after `/model <name>` in-session | Model name doesn't exist at the current provider | `/provider <correct-one>` then `/model <name>` |

The second flavor is covered in `references/in-session-model-switching.md`.

## Provider-Level api_key

You can also set the api_key at the provider level instead of the model level:

```yaml
providers:
  hf-inference:
    base_url: https://router.huggingface.co/v1
    api_key: ${HF_TOKEN}
```

If both model-level and provider-level api_key are set, **model-level takes precedence**. If the model-level api_key is empty, the provider-level api_key is used. If neither is set, Hermes falls back to the env var named `<PROVIDER_NAME>_API_KEY` (uppercased), or `HF_INFERENCE_API_KEY` in this case.

## Common Scenarios

### Scenario A: Local router → HuggingFace

You had `model.api_key: sk-router-1` and `model.base_url: http://localhost:8319/v1` for a local router. You then added a custom provider `hf-inference` with `base_url: https://router.huggingface.co/v1` and set `model.provider: custom:hf-inference`.

**Result:** Hermes hits `https://router.huggingface.co/v1` but sends `sk-router-1` as the Bearer token → 401.

**Fix:** Change `model.api_key` to `${HF_TOKEN}`.

### Scenario B: Env var not loaded

`model.api_key` is `${HF_TOKEN}` but the env var isn't set in `.env`.

**Result:** Hermes sends an empty or literal `${HF_TOKEN}` string → 401.

**Fix:** Add `HF_TOKEN=hf_...` to `~/.hermes/.env`, or verify it's uncommented.

### Scenario C: Wrong env var name

The custom provider is called `hf-inference`. Hermes looks for `HF_INFERENCE_API_KEY` as the fallback env var, but the user's env var is `HF_TOKEN`.

**Fix:** Set `model.api_key: ${HF_TOKEN}` explicitly, or add `api_key: ${HF_TOKEN}` under the `providers.hf-inference` section.

## Verification

After fixing, run a test query:

```bash
hermes chat -q "say hello" --model "zai-org/GLM-5.2" --provider "custom:hf-inference"
```

Or test directly (as in Step 3) to isolate the auth layer before involving the full agent loop.

---

## Env Var References Don't Expand At Runtime

**Critical finding:** When you set `model.api_key: "${OPENROUTER_API_KEY}"` in config.yaml, Hermes stores the literal string `${OPENROUTER_API_KEY}` and sends it as the Authorization header. It does **not** expand environment variables at runtime. The env var must either:

1. Be set in the process environment **before Hermes starts** (in `.env` or shell profile), AND the config must NOT contain the `${...}` placeholder — the literal key must be in config.yaml
2. Or use a literal key in config.yaml directly

When migrating from router (which has keys in `~/.local/share/hermes-router/auth.json`) to direct OpenRouter, you must copy the actual key from auth.json → config.yaml `model.api_key`. The `${OPENROUTER_API_KEY}` placeholder will NOT work — it sends the literal string to OpenRouter, which returns 401 "Missing Authentication header".

**Fix procedure:**
```bash
# Extract actual key from router's auth.json
python -c "
import json
with open(r'~/.local/share/hermes-router/auth.json') as f:
    data = json.load(f)
print(data['providers']['openrouter'][0])
"
# Copy output to config.yaml model.api_key
```

See `references/router-migration-auth.md` for the full migration checklist.
