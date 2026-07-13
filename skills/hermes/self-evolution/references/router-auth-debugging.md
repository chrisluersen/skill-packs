# Router Auth Debugging — DSPy → LiteLLM → Hermes Router

This file captures the exact debugging path from the 2026-06-21 setup session where `hermes-agent-self-evolution` needed auth routing through the local router. Future sessions should read this before retracing the same path.

## The Problem

The self-evolution tool creates `dspy.LM(model_name)` instances that need `api_base` and `api_key` to route through the local Hermes Router at `http://localhost:8319/v1/`. Four files create these LMs, and none pass the router credentials.

## Initial Diagnostic Attempts

1. **Environment variables only (`OPENAI_API_BASE`, `OPENAI_API_KEY`)** — DSPy 3.2.1's `dspy.LM` does NOT reliably pick up these env vars when forwarding to LiteLLM. The `OPENAI_API_KEY` env var IS needed for the `dspy.LM` initialization to find the key, but it's not sufficient — the kwargs must be passed explicitly.

2. **Router key confusion** — The cascade router's code default `PROXY_API_KEYS` is `sk-cascade-1`, but it's overridden to `sk-router-1` via `~/.local/share/cascade/.env`. The canonical key is `sk-router-1`. If Hermes config has a different key, the router returns `401: unauthorized`. Check `echo "$PROXY_API_KEYS"` to see what the running instance expects.

3. **`import os` scoping** — When patching, `import os` must be at module level, not inside the function body. Python raises `NameError` for local imports that come from patched code.

## Working Patch Pattern

```python
# At top of file:
import os

# At each dspy.LM() creation site:
lm_kwargs = {}
if os.environ.get("OPENAI_API_BASE"):
    lm_kwargs["api_base"] = os.environ.get("OPENAI_API_BASE")
if os.environ.get("OPENAI_API_KEY"):
    lm_kwargs["api_key"] = os.environ["OPENAI_API_KEY"]
lm = dspy.LM(model_name, **lm_kwargs)
```

## Files Patched

| File | Function | Line (approx) |
|------|----------|---------------|
| `evolution/skills/evolve_skill.py` | `evolve()` main LM config | 141 |
| `evolution/core/fitness.py` | `LLMJudge.score()` | 75 |
| `evolution/core/dataset_builder.py` | `SyntheticDatasetBuilder._build()` | 126 |
| `evolution/core/external_importers.py` | `SessionDBImporter._import()` | 493 |

## Verification Command

```bash
python3 -c "
import os
os.environ['OPENAI_API_BASE'] = 'http://localhost:8319/v1/'
os.environ['OPENAI_API_KEY'] = 'sk-router-1'\nimport dspy\nlm = dspy.LM('openai/deepseek/deepseek-v4-flash', api_base='http://localhost:8319/v1/', api_key='sk-router-1', max_tokens=100)
dspy.configure(lm=lm)
resp = lm(messages=[{'role':'user','content':'say hi in one word'}])
print('OK:', resp)
"
# Expected: Resp: ['Hi']
```

## Key Insight for Future Debugging

DSPy 3.2.1's `dspy.LM.__init__` takes `**kwargs` and stores them in `self.kwargs`. On `forward()`, it merges `**self.kwargs` into the LiteLLM completion call. So `api_key` and `api_base` must be passed at LM construction time, not set as env vars afterwards.

The `OPENAI_API_BASE` and `OPENAI_API_KEY` env vars are only used by LiteLLM's default OpenAI client constructor when `dspy.LM` doesn't pass explicit kwargs. Since `dspy.LM` DOES forward its kwargs, the env vars are redundant — but setting them doesn't hurt and provides a fallback.

## Recommended Run Command

```bash
cd ~/hermes-agent-self-evolution
export HERMES_AGENT_REPO=~/AppData/Local/hermes/hermes-agent
export OPENAI_API_BASE=http://localhost:8319/v1/
export OPENAI_API_KEY=sk-router-1   # must match cascade's PROXY_API_KEYS (set via .env)

python3 -m evolution.skills.evolve_skill \
    --skill <skill-name> \
    --iterations 5 \
    --eval-source synthetic \
    --optimizer-model openai/deepseek/deepseek-v4-flash \
    --eval-model openai/deepseek/deepseek-v4-flash
```

Note: The evolution source files have already been patched in the local clone. Re-patching is only needed after a `git pull` or fresh clone updates the files.

**Important:** The API key must match the cascade router's `PROXY_API_KEYS` env var. The canonical value is `sk-router-1` (set in `~/.local/share/cascade/.env`). Check with `echo $PROXY_API_KEYS`.
