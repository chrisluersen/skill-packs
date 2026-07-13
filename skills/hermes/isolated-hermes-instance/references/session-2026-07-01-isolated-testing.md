# Isolated Instance Testing — Session Notes (2026-07-01)

## Session Summary

Created a completely isolated Hermes instance at `~/.hermes-private/` for testing Hugging Face models without affecting the main installation.

## What Was Built

1. **Isolated home**: `~/.hermes-private/` with independent config, sessions, skills, memory, SOUL.md
2. **Config**: `~/.hermes-private/config.yaml` with Docker backend and router connection
3. **Launch script**: `~/.hermes-private/launch-private-hermes.sh` for easy invocation
4. **Docker backend**: Each session spins up `nikolaik/python-nodejs:python3.11-nodejs20` container

## Key Findings

### Router Integration

The hermes-router (port 8319) provides 25+ providers but **HF provider has fixed model**:

- `huggingface` provider uses `HUGGINGFACE_MODEL` env var (default: `openai/gpt-oss-120b:cheapest`)
- Does NOT accept arbitrary `:model` suffix from client — single-model endpoint
- For arbitrary HF model IDs, must use `hf-inference` provider directly with HF token

### Working Configuration

```yaml
# Via router (fixed models per provider)
model:
  provider: custom
  base_url: http://host.docker.internal:8319/v1
  api_key: sk-router-1
  default: any

# For arbitrary HF models (direct)
model:
  provider: hf-inference
  base_url: https://router.huggingface.co/v1
  api_key: ${HF_TOKEN}
  default: meta-llama/Meta-Llama-3.1-8B-Instruct
```

### Docker Backend Verified

- Container spins up per session: `hermes-a29a9c60` (nikolaik/python-nodejs:python3.11-nodejs20)
- Network: `host.docker.internal` correctly reaches host router at 8319
- Working directory: `/workspace` mounted from host
- Hermes home in container: `/opt/data` mounted from `HERMES_HOME`

### Provider Cascade Behavior

Router cascades through tiers:
- Tier 0 (free): 13 providers including `huggingface`
- Tier 1 (cheap): `deepseek-v4-flash`, `hy3-preview`, etc.
- Tier 2 (premium): `sonnet-4.6`, `deepseek-v4-pro`, etc.

HF provider at Tier 0 but fixed model means you can't test arbitrary models through router.

## Commands That Worked

```bash
# Launch isolated instance
HERMES_HOME=~/AppData/Local/hermes/.hermes-private \
HERMES_CONFIG=~/AppData/Local/hermes/.hermes-private/config.yaml \
hermes chat

# Verify isolation
hermes doctor  # Shows ~/.hermes-private paths

# Check router health from container
curl -s http://host.docker.internal:8319/health
```

## Commands That Failed (and why)

| Command | Error | Reason |
|---------|-------|--------|
| `hermes chat -m "huggingface/meta-llama/..."` | 503 All providers exhausted | Router's HF provider has fixed model, doesn't accept client-passed model |
| `hermes model` with `custom:hermes-router` | Unknown provider | Must use `provider: custom` + `base_url` separately |

## Files Created

| File | Purpose |
|------|---------|
| `~/.hermes-private/config.yaml` | Isolated config with Docker backend |
| `~/.hermes-private/launch-private-hermes.sh` | Launch script setting HERMES_HOME/CONFIG |
| `~/.hermes-private/sessions/` | Independent session storage |

## Next Steps for User

To test arbitrary HF models:
1. Add `HF_TOKEN=hf_xxx` to `~/.hermes-private/.env`
2. Change config to `provider: hf-inference` with `base_url: https://router.huggingface.co/v1`
3. Restart private instance

This bypasses the router's fixed-model limitation and hits HF Inference API directly.