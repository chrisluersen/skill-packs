# Toad Agent Registration

Register Hermes Agent as a permanent ACP agent in [Toad](https://www.batrachian.ai/) so it shows up in Toad's agent selector alongside Claude Code, OpenCode, Copilot, etc.

## Quick Summary

Create `nousresearch.com.toml` in Toad's `data/agents/` directory with the agent definition. That's it — Toad scans this directory on launch.

## Where to Put It

When Toad is installed via `uv tool install batrachian-toad` (common in WSL/Linux):

```
~/.local/share/uv/tools/batrachian-toad/lib/python3.14/site-packages/toad/data/agents/
```

The exact Python version in the path may differ. To find it:

```bash
find /root/.local/share/uv/tools/batrachian-toad -type d -name "agents"
```

## TOML Format

Reference the bundled agents (`claude.com.toml`, `opencode.ai.toml`, etc.) for the latest schema. Key fields:

| Field | Required | Description |
|-------|----------|-------------|
| `identity` | Yes | Unique domain-based ID (e.g. `"nousresearch.com"`) |
| `name` | Yes | Display name in Toad (e.g. `"Hermes Agent"`) |
| `short_name` | Yes | Short label for compact UI |
| `url` | Yes | Product/homepage URL |
| `protocol` | Yes | Must be `"acp"` |
| `author_name` / `author_url` | Yes | Author identity |
| `publisher_name` / `publisher_url` | Yes | Publisher identity |
| `type` | Yes | Agent type — `"coding"` or omit |
| `description` | No | One-line summary |
| `tags` | No | Array of keyword tags |
| `run_command."*"` | Yes | Command to launch the ACP agent |
| `help` | No | Markdown help text shown in agent detail |
| `actions."*".install` | No | Install action with `command` + `description` |

## Complete Example

```toml
# Schema defined in agent_schema.py
# https://hermes-agent.nousresearch.com

identity = "nousresearch.com"
name = "Hermes Agent"
short_name = "hermes"
url = "https://hermes-agent.nousresearch.com"
protocol = "acp"
author_name = "Nous Research"
author_url = "https://nousresearch.com/"
publisher_name = "Nous Research"
publisher_url = "https://nousresearch.com/"
type = "coding"
description = "General-purpose AI agent with tool use, persistent memory, multi-session orchestration."
tags = ["agent", "coding", "research", "tools"]

run_command."*" = "/root/.local/bin/hermes-acp"

help = '''
# Hermes Agent

Hermes is a fully open-source, general-purpose AI agent built by Nous Research.
Combines powerful reasoning with practical tool use — web, code, files, terminal, browser, images, and more.

## Key Features

- **Persistent Memory**: Remembers preferences, conventions, and environment facts across sessions
- **Tool Ecosystem**: Web search, file ops, code execution, terminal, browser automation, image gen, TTS
- **Multi-Session Orchestration**: Delegates subtasks to parallel agents, manages cron jobs
- **Self-Improving**: Saves workflows as reusable skills, learns from corrections
- **Model Agnostic**: Any LLM provider — OpenAI, Anthropic, Nous, OpenRouter, Ollama, and more
- **ACP Native**: Full Agent Client Protocol via `hermes-acp` for Toad and other ACP clients
'''

[actions."*".install]
command = "uv tool install hermes-agent --with hermes-agent[acp]"
description = "Install Hermes Agent with ACP support"
```

## Pitfalls

### Absolute path required in WSL

`/root/.local/bin` is not always on Toad's PATH when it spawns child processes. Always use the full path in `run_command`:

```toml
run_command."*" = "/root/.local/bin/hermes-acp"
```

### Writing the TOML file

Bash heredocs (`cat > file << 'EOF' ... EOF`) frequently break on TOML triple-quoted strings and special characters. Use Python heredocs instead:

```bash
wsl -d Ubuntu -- python3 << 'PYEOF'
content = '''# your TOML content here
with triple-quoted blocks
'''
with open('/path/to/nousresearch.com.toml', 'w') as f:
    f.write(content)
print('Written OK')
PYEOF
```

### Auth tokens across environments

When Hermes runs in WSL, it needs its own auth credentials. Copy the Nous OAuth token from the Windows host:

```bash
# From Windows side (git-bash):
cp /c/Users/$(whoami)/AppData/Local/hermes/shared/nous_auth.json /root/.hermes/auth.json

# The refresh token allows automatic token renewal after access token expiry.
```

### Package updates wipe the agent file

`data/agents/` is inside the Toad Python package. Reinstalling `batrachian-toad` via uv overwrites this directory. Keep a backup of your TOML or script the install step.

## Verification

After placing the TOML file, verify:
1. The binary exists: `ls -la /root/.local/bin/hermes-acp`
2. The agent can start: `timeout 3 /root/.local/bin/hermes-acp --version`
3. Launch Toad and check the agent selector: `toad run`

## Related

- `hermes acp --help` — ACP server entrypoint
- Toad docs: https://www.batrachian.ai/
- ACP protocol: https://agentclientprotocol.com/
