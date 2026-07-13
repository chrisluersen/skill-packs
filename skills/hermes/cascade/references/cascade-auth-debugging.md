# Cascade Auth Debugging — Proxy Key Mismatch

## Symptom

Hermes shows `⚠️ Provider authentication failed. Check the configured credentials` — or cascade returns `401 {"error":"unauthorized"}` on all endpoints (models, chat completions, health).

## Root Cause

Cascade's proxy authentication uses `PROXY_API_KEYS` (env var, default in `cascade.py`). This is **separate** from downstream provider keys in `auth.json`. When Hermes sends a different key than cascade expects, every request gets rejected with 401.

This commonly happens **after a subsystem rename** (hermes-router → cascade) — the source code default changes (e.g. `sk-router-1` → `sk-router-1`) but Hermes config and skills still reference the old key.

## Diagnostic Flow

### 1. Check what cascade expects

```bash
# Check env var (empty = uses code default)
echo "PROXY_API_KEYS=$PROXY_API_KEYS"

# Check the code default
grep "PROXY_API_KEYS" ~/.local/share/cascade/cascade.py
# Expected: PROXY_API_KEYS = os.environ.get("PROXY_API_KEYS", "sk-router-1").split(...)
```

### 2. Check what Hermes is sending

```bash
# Key locations in config.yaml
grep "api_key:" ~/AppData/Local/hermes/config.yaml | grep -v "''" | grep -v "$$"
```

### 3. Test directly

```bash
# Test known-good key
curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer sk-router-1" \
  -H "Content-Type: application/json" \
  http://localhost:8319/v1/models
# Expected: 200

# If 401: key mismatch. Try the default from cascade.py source code.
```

### 4. Fix

Update all 4 config locations to match cascade's expected key:

```bash
hermes config set auxiliary.compression.api_key <expected-key>
hermes config set delegation.api_key <expected-key>
hermes config set custom_providers.0.api_key <expected-key>
hermes config set fallback_providers[0].api_key <expected-key>
```

Then reset stale exhausted credential status:

```bash
hermes auth reset custom:cascade
```

## Verification

```bash
# Full end-to-end test — cascade should route and return
curl -s -H "Authorization: Bearer <expected-key>" \
  -H "Content-Type: application/json" \
  http://localhost:8319/v1/chat/completions \
  -d '{"model":"any","messages":[{"role":"user","content":"hi"}],"max_tokens":10}'
# Expected: {"choices":[{"message":{"content":"Hi!..."}},...]}
```

## Environment Pitfall — `.env` + `setdefault`

Cascade loads `.env` via `os.environ.setdefault()` — meaning it **only sets env vars that aren't already set**. If `PROXY_API_KEYS` is already in the environment (even as empty string `""`), the `.env` file value is silently ignored.

```python
# cascade.py, line 42:
os.environ.setdefault(k.strip(), v.strip())
#          ^^^^^^^^^^
# only applies if env var is NOT already set
```

**When this bites you:**
- Hermes starts cascade from a parent process that has `PROXY_API_KEYS=""` (set by shell init, config manager, or another tool)
- Cascade loads `.env` with `PROXY_API_KEYS=sk-router-1` — but `setdefault` skips it
- Cascade falls through to the code default (a potentially wrong key)
- Hermes sends `sk-router-1` → 401 unauthorized mismatch

**Fixes (pick one):**

```bash
# A) Pass env var inline (always works, overrides both .env and code default)
PROXY_API_KEYS=sk-router-1 python3 cascade.py

# B) Unset first so .env can take effect
unset PROXY_API_KEYS; python3 cascade.py

# C) Set in Windows startup script (start-cascade.bat)
set PROXY_API_KEYS=sk-router-1
```

**Verification:** The `.env` approach (B) is fragile because the parent environment is out of your control. Option (A) or (C) is recommended for production start paths.

After fixing the config, sweep skills for stale references:

```bash
grep -rn "sk-router-1" ~/AppData/Local/hermes/skills/ --include="*.md" --include="*.py"
# Replace any hits with the new default key
```

Key skills that commonly need updating:
- `cascade` — SKILL.md (config examples, bash alias, verification curl, prompt routing test)
- `session-startup` — verification checklist, curl examples
- `cost-performance-tuning` — `hermes config set` commands
- `cascade-cost-optimization` — compression config set commands
- `isolated-hermes-instance` — cascade config examples
- `hermes-provider-setup` — router setup examples
- `glm-52-serverless` — curl header examples
