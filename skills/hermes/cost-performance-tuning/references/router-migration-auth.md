# Router → Direct Provider Migration: Auth Checklist

**Scenario:** Moving main model from `custom:hermes-router` (localhost:8319) to direct `openrouter` (or `nous`, `anthropic`, etc.)

## The Problem

Router stores keys in `~/.local/share/hermes-router/auth.json`. Hermes main config (`config.yaml`) has `model.api_key` set to the router's key (`sk-router-1`). When you switch `model.provider` to `openrouter`, the old router key gets sent to OpenRouter → 401 "Missing Authentication header".

## Migration Steps

### 1. Extract actual key from router auth.json

```bash
python -c "
import json
with open(r'~/.local/share/hermes-router/auth.json') as f:
    data = json.load(f)
print(data['providers']['openrouter'][0])
"
```

### 2. Write literal key to Hermes config.yaml

```bash
# Using hermes config set (may hit Windows PermissionError)
hermes config set model.api_key "sk-or-actual-key-here"

# OR direct YAML edit (more reliable on Windows)
python -c "
import yaml
with open(r'~/AppData/Local/hermes/AppData/Local/hermes/config.yaml') as f:
    config = yaml.safe_load(f)
config['model']['api_key'] = 'sk-or-actual-key-here'
with open(r'~/AppData/Local/hermes/AppData/Local/hermes/config.yaml', 'w') as f:
    yaml.dump(config, f, sort_keys=False)
"
```

### 3. Verify config has literal key (not `${OPENROUTER_API_KEY}`)

```bash
python -c "
import yaml
with open(r'~/AppData/Local/hermes/AppData/Local/hermes/config.yaml') as f:
    config = yaml.safe_load(f)
key = config['model']['api_key']
print(f'Key starts with: {key[:10]}')
print(f'Contains env var ref: {\"$\" in key or \"{\" in key}')
"
```

### 4. Update model.provider and related fields

```bash
hermes config set model.provider openrouter
hermes config set model.default "anthropic/claude-sonnet-4"
hermes config set model.base_url ""
hermes config set model.context_length 128000
```

### 5. Restart Hermes session

```bash
/reset   # in TUI
# or new CLI process
```

## Verification

```bash
# Direct API test
curl -s -H "Authorization: Bearer sk-or-actual-key" \
  -H "Content-Type: application/json" \
  -d '{"model":"anthropic/claude-sonnet-4","messages":[{"role":"user","content":"hi"}],"max_tokens":5}' \
  https://openrouter.ai/api/v1/chat/completions | python -m json.tool

# Should return 200 with completion
```

## Common Pitfalls

| Pitfall | Symptom | Fix |
|---------|---------|-----|
| Using `${OPENROUTER_API_KEY}` in config.yaml | 401 "Missing Authentication header" | Use literal key |
| Forgetting to clear `model.base_url` | Requests go to wrong endpoint | Set to empty string |
| Keeping `fallback_providers` with router key | Fallback sends wrong key | Update fallback auth or remove |
| Not restarting session | Old config still active | `/reset` or new process |

## Auxiliary Tasks

Keep `auxiliary.compression.provider: main` if you want compression to cascade through router (free-tier budget saver). But set all OTHER aux tasks to `openrouter`:

```bash
for s in vision web_extract skills_hub approval title_generation curator monitor triage_specifier kanban_decomposer profile_describer mcp; do
  hermes config set "auxiliary.$s.provider" openrouter
  hermes config set "auxiliary.$s.model" "google/gemini-2.5-flash"
done
```

## Rollback

To go back to router:

```bash
hermes config set model.provider custom
hermes config set model.base_url http://localhost:8319/v1
hermes config set model.api_key sk-router-1
hermes config set model.default any
hermes config set model.context_length 256000
```