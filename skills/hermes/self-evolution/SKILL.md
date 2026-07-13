---
name: self-evolution
description: Run the Hermes Agent Self-Evolution pipeline — evolve skills using DSPy optimization through the local router
trigger: User wants to evolve, improve, or optimize skills using hermes-agent-self-evolution
---

# Self-Evolution (Hermes Agent Skill Evolution)

Run Nous Research's `hermes-agent-self-evolution` pipeline to evolve Hermes skills using DSPy optimization (MIPROv2), routed through the local Hermes Router.

## Prerequisites

- `hermes-agent-self-evolution` cloned: `~/hermes-agent-self-evolution/`
- Dependencies installed: `pip install -e ".[dev]"` from that directory
- Hermes Router running at `http://localhost:8319/v1/`
- Router API key: `sk-router-1` (set via `PROXY_API_KEYS` in `~/.local/share/cascade/.env`; override with different key in that file)
- DSPy 3.2.1+ installed (comes with `.[dev]`)

## Patches Required

The self-evolution code creates `dspy.LM()` instances without passing `api_base`/`api_key`. Four files need patching to pick up env vars:

### Files to patch (already done, re-check after updates):

1. **`evolution/skills/evolve_skill.py`** — main LM config (around line 141)
2. **`evolution/core/fitness.py`** — `LLMJudge.score()` LM (around line 75)
3. **`evolution/core/dataset_builder.py`** — judge LM (around line 126)
4. **`evolution/core/external_importers.py`** — sessiondb import LM (around line 493)

### Patch pattern for each:

```python
# Before:
lm = dspy.LM(model_name)

# After:
lm_kwargs = {}
if os.environ.get("OPENAI_API_BASE"):
    lm_kwargs["api_base"] = os.environ["OPENAI_API_BASE"]
if os.environ.get("OPENAI_API_KEY"):
    lm_kwargs["api_key"] = os.environ["OPENAI_API_KEY"]
lm = dspy.LM(model_name, **lm_kwargs)
```

Add `import os` at the top of each file if not present.

## References

- `references/router-auth-debugging.md` — Full debugging path from first setup: DSPy auth failures, key confusion, env var vs. kwarg approach, patch confirmation tests. Read this before re-patching after a git pull.

## Running

```bash
cd ~/hermes-agent-self-evolution
export HERMES_AGENT_REPO=~/AppData/Local/hermes/hermes-agent
export OPENAI_API_BASE=http://localhost:8319/v1/
export OPENAI_API_KEY=***

python3 -m evolution.skills.evolve_skill \
    --skill <skill-name> \
    --iterations 5 \
    --eval-source synthetic \
    --optimizer-model openai/deepseek/deepseek-v4-flash \
    --eval-model openai/deepseek/deepseek-v4-flash
```

### Key args:
- `--skill`: Skill name (must match a dir under `skills/` in HERMES_AGENT_REPO)
- `--iterations`: DSPy optimization iterations (default 10, use 5 for testing)
- `--eval-source`: `synthetic` (default, generates from skill text) or `sessiondb` (uses real sessions)
- `--optimizer-model` / `--eval-model`: Both use `openai/deepseek/deepseek-v4-flash` through the router
- `--dry-run`: Validate config without running

### Skill size limit: **15KB max** (configurable in `evolution/core/config.py`)

## How It Works

1. **Dataset generation**: Creates synthetic eval examples from the skill text (20 examples)
2. **Constraint validation**: Checks size, structure, growth limits
3. **GEPA attempt** → falls back to **MIPROv2** (DSPy 3.2.1 uses different GEPA API)
4. **MIPROv2 pipeline**: Bootstrap 6 few-shot sets → Propose 3 instruction candidates → 10 Bayesian trials
5. **Validation**: Size, growth, structure checks on evolved output
6. **Deployment**: Saves to `output/<skill>/evolved_<status>.md`

## Known Issues

- **GEPA unavailable** in DSPy 3.2.1 — expects `auto=` param, not `max_steps=`. Falls back to MIPROv2 automatically.
- **YAML frontmatter constraint** fails for skills without `---` frontmatter — false alarm for most skills. The evolved skill is saved as `evolved_FAILED.md` regardless.
- **MIPROv2 optimizes prompt structure**, not skill text content. The DSPy program's behavior changes but the skill text artifact stays the same.
- **Score metric** is keyword overlap between expected behavior and agent output — basic but functional.
- **Some bootstrap examples fail** during dataset evaluation — normal, MIPROv2 continues with partial traces.

## Output

Results saved to `~/hermes-agent-self-evolution/output/<skill-name>/`:
- `evolved_FAILED.md` — evolved skill that failed constraint checks
- `evolved_SUCCESS.md` — fully validated evolution (rare due to frontmatter constraint)

## Improving Impact

For actual skill text evolution, consider:
1. Fixing GEPA to use `dspy.GEPA(metric=..., auto='light')` instead of `max_steps=`
2. Writing a direct LLM skill rewriter that proposes text improvements and validates via eval
3. Relaxing the `skill_structure` constraint for non-DSPy-native skills
