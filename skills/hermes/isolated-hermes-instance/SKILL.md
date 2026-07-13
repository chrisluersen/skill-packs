---
name: isolated-hermes-instance
description: >-
  Create and manage completely isolated Hermes instances with separate home
  directories, configs, sessions, skills, and memory. Used for testing models,
  providers, and configurations without affecting the main installation.
category: hermes
tags: [hermes, isolated, testing, docker, profiles, configuration]
related_skills: [hermes-agent, hermes-router, agent-fleet-management]
---

# Isolated Hermes Instance

A reusable pattern for spinning up a **completely separate Hermes installation** that shares nothing with the primary instance — different `HERMES_HOME`, config, sessions, skills, memory, and SOUL.md. Runs in Docker for filesystem isolation.

## When to Use

- Testing Hugging Face models or new provider configs
- Experimenting with Docker backend without touching main instance
- Validating config changes before applying to primary profile
- Running parallel agent instances with different personas/toolsets
- Reproducing issues in a clean environment

## Architecture

```
~/.hermes/                  ← Main instance (production)
├── config.yaml
├── sessions/
├── skills/
├── memories/
├── SOUL.md
└── state.db

~/.hermes-private/          ← Isolated instance (testing)
├── config.yaml             ← Points to router, Docker backend
├── sessions/               ← Completely separate
├── skills/                 ← No shared skills
├── memories/               ← No cross-contamination
├── SOUL.md                 ← Separate persona if desired
├── state.db                ← Independent session store
└── launch-private-hermes.sh
```

The **only shared component** is the hermes-router (port 8319) — both instances can point to it, or the isolated instance can use direct providers.

## Setup

### 1. Create Isolated Home

```bash
mkdir -p ~/.hermes-private
```

### 2. Isolated Config (`~/.hermes-private/config.yaml`)

```yaml
# ~/.hermes-private/config.yaml — isolated Hermes instance for model testing
# Completely separate from main ~/.hermes

model:
  # Via router (recommended — shares your 25+ providers)
  provider: custom
  base_url: http://host.docker.internal:8319/v1
  api_key: sk-router-1
  default: any
  context_length: 256000

# Or direct HF (for arbitrary model IDs)
# model:
#   provider: hf-inference
#   base_url: https://router.huggingface.co/v1
#   api_key: ${HF_TOKEN}
#   default: meta-llama/Meta-Llama-3.1-8B-Instruct

fallback_providers:
  - provider: nous
    base_url: https://inference-api.nousresearch.com/v1
    model: deepseek/deepseek-v4-flash
    default: deepseek/deepseek-v4-flash

toolsets:
  - hermes-cli

max_live_sessions: 8

agent:
  max_turns: 60
  gateway_timeout: 1800

terminal:
  backend: docker
  docker_image: nikolaik/python-nodejs:python3.11-nodejs20
  container_memory: 8192
  container_cpu: 2
  docker_mount_cwd_to_workspace: true
  persistent_shell: true

# Reduced limits for test instance
compression:
  hygiene_hard_message_limit: 40

display:
  resume_exchanges: 5

memory:
  memory_char_limit: 500
  user_char_limit: 300
```

### 3. Launch Script (`~/.hermes-private/launch-private-hermes.sh`)

```bash
#!/usr/bin/env bash
# launch-private-hermes.sh — start isolated Hermes instance
# Usage: ./launch-private-hermes.sh [hermes-args...]

set -euo pipefail

HERMES_PRIVATE_HOME="$HOME/.hermes-private"
CONFIG="$HERMES_PRIVATE_HOME/config.yaml"

if [[ ! -f "$CONFIG" ]]; then
    echo "Config not found: $CONFIG"
    exit 1
fi

export HERMES_HOME="$HERMES_PRIVATE_HOME"
export HERMES_CONFIG="$CONFIG"

exec hermes --config "$CONFIG" "$@"
```

Make executable: `chmod +x ~/.hermes-private/launch-private-hermes.sh`

### 4. Run

```bash
# Via launch script (recommended)
~/.hermes-private/launch-private-hermes.sh chat

# Or with explicit env vars (works from any shell)
HERMES_HOME=~/AppData/Local/hermes/.hermes-private \
HERMES_CONFIG=~/AppData/Local/hermes/.hermes-private/config.yaml \
hermes chat

# Single query
~/.hermes-private/launch-private-hermes.sh chat -q "test HF model"
```

## Model Testing Options

### Option A: Via Router (Recommended)

Uses your existing hermes-router with 25+ providers. **Fixed model** per provider:

| Provider | Model Selection |
|----------|----------------|
| `huggingface` | Fixed via `HUGGINGFACE_MODEL` in router `.env` |
| `openrouter` | Client-passed model ID (45k+ models) |
| `custom` (router) | Router picks best automatically |

```yaml
model:
  provider: custom
  base_url: http://host.docker.internal:8319/v1
  api_key: sk-router-1
  default: any
```

### Option B: Direct HF Inference (Arbitrary Models)

For testing specific HF model IDs like `meta-llama/Meta-Llama-3.1-8B-Instruct`:

```yaml
model:
  provider: hf-inference
  base_url: https://router.huggingface.co/v1
  api_key: ${HF_TOKEN}   # Add to ~/.hermes-private/.env
  default: meta-llama/Meta-Llama-3.1-8B-Instruct
```

```bash
# ~/.hermes-private/.env
HF_TOKEN=hf_xxxxxxxxxxxx
```

## Docker Backend Behavior

| Aspect | Behavior |
|--------|----------|
| Container per session | Fresh container from `docker_image` each chat |
| Working directory | `/workspace` (mounted from host cwd) |
| Hermes home in container | `/opt/data` (mounted from `HERMES_HOME`) |
| Persistence | `container_persistent: true` keeps container between turns |
| Network | `host.docker.internal` reaches host router at 8319 |

## Verification Checklist

- [ ] `hermes doctor` passes for isolated home
- [ ] Sessions written to `~/.hermes-private/sessions/`
- [ ] Docker container appears (`hermes-<hash>`)
- [ ] No files in `~/.hermes/` from private instance
- [ ] Router reachable from container (`host.docker.internal:8319`)

## Troubleshooting

| Issue | Fix |
|-------|-----|
| "Unknown provider custom:hermes-router" | Use `provider: custom` + `base_url` (not `custom:hermes-router`) |
| HF 401 auth error | Add `HF_TOKEN` to `.env`, use `provider: hf-inference` |
| 503 All providers exhausted | Router has no healthy provider for that model; try different model |
| Container can't reach router | Use `host.docker.internal` (not `localhost`) in config |
| Config not loading | Verify `HERMES_HOME` and `HERMES_CONFIG` env vars set |

## Related

- [hermes-agent skill](skill_view(name="hermes-agent")) — main Hermes configuration
- [hermes-router skill](skill_view(name="hermes-router")) — router setup and providers
- [Profiles docs](https://hermes-agent.nousresearch.com/docs/user-guide/profiles/)
- [Spawning Additional Hermes Instances](https://hermes-agent.nousresearch.com/docs/user-guide/features/spawning-agents/)