# How to Diff config.yaml Against Canonical DEFAULT_CONFIG

Compare your Hermes config against the source of truth to find every non-default setting — useful for auditing drift, rolling back, or understanding what was changed by a setup wizard vs. an agent.

## Prerequisites

```bash
pip install pyyaml
```

## One-Liner Script

Run this from anywhere — it imports the installed Hermes source. The output lists three categories:
1. **Added keys** — settings in your config that don't exist in DEFAULT_CONFIG at all
2. **Changed values** — settings that exist in both but have different values
3. **Type mismatches** — same key, different Python type (string vs dict, etc.)

```python
import sys, yaml

# === CONFIGURE THESE ===
CONFIG_PATH = r"~/AppData/Local/hermes\AppData\Local\hermes\config.yaml"
HERMES_SOURCE = r"~/AppData/Local/hermes\AppData\Local\hermes\hermes-agent"
# =======================

sys.path.insert(0, HERMES_SOURCE)
from hermes_cli.config import DEFAULT_CONFIG

def flatten(d, prefix=""):
    items = []
    for k, v in d.items():
        p = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict):
            items.extend(flatten(v, p))
        else:
            items.append((p, v))
    return items

with open(CONFIG_PATH) as f:
    user_cfg = yaml.safe_load(f)

default_flat = dict(flatten(DEFAULT_CONFIG))
user_flat = dict(flatten(user_cfg))

added = {k: v for k, v in user_flat.items() if k not in default_flat}
changed = {}
for k, v in user_flat.items():
    if k in default_flat and v != default_flat[k] and not k.startswith("_"):
        changed[k] = (default_flat[k], v)

print(f"Total keys in DEFAULT_CONFIG: {len(default_flat)}")
print(f"Total keys in user config:    {len(user_flat)}")
print(f"Added keys: {len(added)}")
print(f"Changed values: {len(changed)}")
print()

print("=== ADDED KEYS (not in DEFAULT_CONFIG at all) ===")
for k, v in sorted(added.items()):
    if k.startswith("_") or k.startswith("providers."):
        continue
    print(f"  {k} = {repr(v)}")

print("\n=== CHANGED VALUES ===")
for k, (dv, uv) in sorted(changed.items()):
    print(f"  {k}")
    print(f"    default: {repr(dv)}")
    print(f"    current: {repr(uv)}")
```

## Categorizing Changes

Once you have the diff output, annotate each entry by source:

- **`🖊 user`** — set by `hermes setup`, `hermes model`, `hermes gateway setup`, or a manual config edit. Includes wizard output like `model.default`, `model.provider`, `model.base_url`, `web.backend`, `browser.cdp_url`, and infrastructure keys like `*.use_gateway`, `gateway.api_server.*`, `platform_toolsets.*`, `onboarding.seen.*`.
- **`🤖 agent`** — set by an agent via `hermes config set`. Track these so the user can roll back agent tuning without losing their intentional wizard-set config.

## Notes on Specific Keys

| Key | Notes |
|-----|-------|
| `model` (top level) | DEFAULT_CONFIG has `model: ""` (a string). The dict form is written by `hermes model` or `hermes setup` — user-set, not canonical. |
| `agent.reasoning_effort` | No DEFAULT_CONFIG entry. Code defaults to `""` when absent. |
| `browser.cloud_provider` | Not in DEFAULT_CONFIG. Set by setup/subscription. |
| `compression.protect_last` | Not in DEFAULT_CONFIG — the canonical key is `protect_last_n`. If you see this, it was accidentally added by `hermes config set` and should be deleted. |
| `*.use_gateway` | Not in DEFAULT_CONFIG. Set by setup/subscription. |
| `platform_toolsets.*` | Not in DEFAULT_CONFIG. Set by `hermes tools` interactive config. |
| `known_plugin_toolsets.*` | Not in DEFAULT_CONFIG. Plugin registration. |
| `onboarding.seen.*` | Not in DEFAULT_CONFIG. Wizard progress tracking. |
