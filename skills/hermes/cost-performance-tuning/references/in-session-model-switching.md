# In-Session Model/Provider Switching — Diagnostics

## The 401 Trap

When you switch models in-session with `/model <name>` and get back:

```
Error: Error code: 401 - {'error': 'Invalid username or password.'}
```

**It is almost never an auth problem.** Most OpenAI-compatible APIs return 401 for unknown/missing models as an information-leak safeguard. The real cause is that `model.default` still points to the new model, but `model.provider` is still the OLD provider that doesn't serve it.

### Quick diagnostics

```python
# Check what provider you're currently on — run this in-session after the error:
from hermes_tools import terminal
r = terminal("grep -A3 'provider:' ~/AppData/Local/hermes/config.yaml")
print(r['output'])
# You'll likely see you're still on 'nous' when the model needs 'custom:hf-inference'
```

### Verified reproduction from 2026-06-18

```
Session on: deepseek/deepseek-v4-flash via nous

# Step 1 — User tried combined syntax (WRONG):
/model custom:hf-inference/zai-org/GLM-5.2
→ Error: Model `custom:hf-inference/zai-org/GLM-5.2` was not found in this provider's model listing.
# (Provider was still nous; the combined string was treated as a literal model name there.)

# Step 2 — User switched model only (WRONG without provider switch):
/model zai-org/GLM-5.2
→ (model name changed in config, but provider still nous)
→ User sent a message
→ Error: Error code: 401 - {'error': 'Invalid username or password.'}
# (Nous Portal returned 401 because GLM-5.2 doesn't exist on Nous servers)

# Step 3 — User switched back:
/model deepseek/deepseek-v4-flash
→ Works fine (both model AND provider now match again)
```

### The correct flow

```
/provider custom:hf-inference     ← switch to the right provider FIRST
/model zai-org/GLM-5.2            ← then switch model
```

### Why the 401 looks like auth

OpenAI-compatible APIs, including Nous Portal, Hugging Face Inference Providers, and many others, return **HTTP 401** when a model doesn't exist — rather than 404 or 400 — as a security measure against model name enumeration. This means:

| Symptom | Likely cause |
|---------|-------------|
| 401 after `/model X` | Model X not found at current provider |
| 401 on session start | Model/provider mismatch in config |
| 401 on every request | Actual auth issue (key expired/wrong) |

### How to distinguish auth vs model-mismatch 401

1. **Did you just change models?** → model-mismatch
2. **Check `/provider`** — are you on the right provider for that model?
3. **Test the provider independently** — use a known-working model at that provider first. If that works, it's a model-mismatch.
4. **Check the HF token or API key separately** — run a curl/Python test against the provider's base URL with a known model. If it works, auth is fine = model-mismatch.
