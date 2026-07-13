# OpenCode Integration via A2A Protocol

**Source:** Second-pass research (2026-06-23) — a2a-opencode npm package, Hermes ACP roadmap.

## Why A2A Instead of Custom Bridges

The industry protocol stack (2026) has three layers:
- **MCP** (Model Context Protocol) — agent-to-tool. ✅ Hermes has this built-in.
- **A2A** (Agent-to-Agent, Linux Foundation) — discovery, task delegation, inter-agent comm. 🔄 Partially in Hermes.
- **ACP** (Commerce) — payments. ❌ Not relevant.

ACP (IBM's Agent Communication Protocol) merged into A2A under Linux Foundation. **A2A is now THE standard for agent-to-agent communication.**

Using A2A instead of a custom Hermes↔OpenCode bridge means:
- Same protocol works for Claude Code, Codex CLI, Copilot (14+ agent types)
- No custom code per agent harness
- Standardized Agent Cards for capability discovery
- JSON-RPC with task lifecycle (SUBMITTED → WORKING → COMPLETED/FAILED)

## a2a-opencode Setup

The `a2a-opencode` npm package wraps OpenCode as an A2A agent:

```bash
# 1. Start OpenCode headless
opencode serve                    # OpenCode on http://localhost:4096

# 2. Install the A2A wrapper
npm install -g a2a-opencode

# 3. Configure Agent Card + OpenCode connection
# Create my-agent/config.json:
```

**config.json:**
```json
{
  "agentCard": {
    "name": "Fleet Code Agent",
    "description": "Code generation via OpenCode, controlled by Stella",
    "version": "1.0.0",
    "protocolVersion": "0.3.0",
    "streaming": true,
    "skills": [
      { "id": "code-gen", "name": "Code Generation",
        "description": "Write working production code",
        "tags": ["code", "python", "typescript", "generation"] },
      { "id": "code-review", "name": "Code Review",
        "description": "Analyze code for bugs and performance",
        "tags": ["code", "review", "security"] }
    ]
  },
  "server": {
    "port": 3001,
    "advertiseHost": "localhost"
  },
  "opencode": {
    "baseUrl": "http://localhost:4096",
    "model": "anthropic/claude-sonnet-4-20250514",
    "systemPrompt": "You are a code generation specialist. Write working, production-quality code.",
    "autoApprove": true,
    "autoAnswer": true
  }
}
```

```bash
# 4. Start the A2A wrapper
a2a-opencode --config my-agent/config.json
# Agent Card: http://localhost:3001/.well-known/agent-card.json
# JSON-RPC:   http://localhost:3001/a2a/jsonrpc
# REST:       http://localhost:3001/a2a/rest
```

## Routing from Stella

Once the A2A wrapper is running, send tasks via JSON-RPC:

```bash
curl -X POST http://localhost:3001/a2a/jsonrpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": "1",
    "method": "tasks/send",
    "params": {
      "message": {
        "role": "user",
        "parts": [{"kind": "text", "text": "Write a Python prime number checker with error handling"}]
      }
    }
  }'
```

## Hermes-ACP Path (Future)

Once Hermes issue #5257 (generalized ACP client) lands on `feat/acpx-plugin`, Stella can dispatch directly:

```python
delegate_task(
    goal="Write a Python prime number checker",
    acp_command="opencode --acp"   # or claude-acp, codex-acp, gemini-acp
)
```

This makes the fleet protocol-agnostic at the orchestration layer — Hermes doesn't care which harness executes, as long as it speaks ACP/A2A.

## Future Agent Harnesses

All via the same A2A protocol:

| Agent | A2A Entry Point | Package |
|-------|----------------|---------|
| OpenCode | `a2a-opencode --config config.json` | a2a-opencode (npm) |
| Claude Code | `acpx claude exec --acp` | acpx (npm) |
| Codex CLI | `codex-acp` (via hermes #5257) | codex-acp (Zed) |
| Gemini CLI | `gemini --acp` | gemini CLI (built-in) |

## See Also

- `concepts/multi-agent-orchestration-patterns.md` in wiki — full protocol stack research
- `hermes-fleet-profiles` skill — fleet deployment and routing
- agentcommunicationprotocol.dev — A2A/ACP official docs
