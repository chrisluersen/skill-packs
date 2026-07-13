# Context Window Deep Dive — Why 64K for Hermes

## The 64K Requirement

Hermes Agent enforces a **minimum 64,000 token context window** for any model used with tool calling. This is hardcoded in the agent initialization:

```python
# agent/model_tools.py (conceptual)
MIN_CONTEXT_FOR_TOOLS = 64000
if model_context < MIN_CONTEXT_FOR_TOOLS:
    raise ValueError(f"Model context {model_context} < {MIN_CONTEXT_FOR_TOOLS}")
```

**Why?** Tool calling (function calling) requires:
1. System prompt (~3-5K tokens with skills, tools, environment hints)
2. Conversation history (grows with each turn)
3. Tool schemas (each tool ~500-2000 tokens; 20+ tools = 10-40K)
4. Tool results (web search returns ~2-5K per call)
5. Reasoning traces (if enabled)

A 32K window fills up in 3-5 tool calls, causing truncation or failure.

## Two Config Knobs — Different Purposes

### `model.context_length` (Hermes-side)
- **What:** Tells Hermes "this model supports N tokens"
- **Used for:** Startup validation, context compression triggers, token budgeting
- **Does NOT affect:** Actual model inference
- **If wrong (too high):** Hermes thinks it has room, but model truncates → garbage output
- **If wrong (too low):** Hermes refuses to start even if model could handle it

### `model.ollama_num_ctx` (Ollama-side, passed at request time)
- **What:** Sent as `num_ctx` parameter in `/v1/chat/completions` request
- **Used for:** Ollama allocates KV cache of this size for the inference
- **Critical:** Must be ≥ `model.context_length` or model will truncate
- **Default if omitted:** Model's default (32K for qwen2.5, llama3, phi3)

## Request Flow

```
User: "Search for X and write code"
      ↓
Hermes builds messages (system + history + tools)
      ↓
Hermes checks: model_context (65536) >= 64000 ✓
      ↓
Hermes calls Ollama /v1/chat/completions with:
{
  "model": "qwen2.5:7b",
  "messages": [...],
  "num_ctx": 65536,        ← from ollama_num_ctx
  "tools": [...],
  ...
}
      ↓
Ollama allocates 64K KV cache, runs inference
      ↓
Returns response (may include tool_calls)
```

## Common Misconfigurations

| Scenario | context_length | ollama_num_ctx | Result |
|----------|----------------|----------------|--------|
| Both unset | 32K (model default) | 32K (model default) | ❌ Hermes rejects: "below 64K" |
| Only context_length=65536 | 65536 | 32K (model default) | ❌ Ollama truncates at 32K → garbled tool calls |
| Only ollama_num_ctx=65536 | 32K (model default) | 65536 | ❌ Hermes rejects at startup |
| **Both 65536** | **65536** | **65536** | ✅ Works |

## Other Local Endpoints

| Server | Parameter | Notes |
|--------|-----------|-------|
| Ollama | `num_ctx` | In request body |
| llama.cpp server | `n_ctx` | In request body or server startup `--ctx-size` |
| vLLM | `max_model_len` | Server startup flag (not per-request) |
| LM Studio | `max_tokens` | In request, but context = model default |
| Text-Gen-WebUI | `max_context_length` | Model load setting |

**For non-Ollama:** Set `model.context_length` correctly. Use server-specific startup flags for actual context size. Hermes has no `*_num_ctx` equivalent for other servers yet.

## Verification

```bash
# Check what Hermes thinks
hermes config show | grep -A5 "Model:"

# Check what Ollama actually uses (enable debug logging)
OLLAMA_DEBUG=1 ollama serve
# Then run request, watch for "num_ctx" in logs
```

## Future: Dynamic Context

Hermes may support per-model context config in future. Track: https://github.com/NousResearch/hermes-agent/issues (search "context_length" "ollama_num_ctx")
