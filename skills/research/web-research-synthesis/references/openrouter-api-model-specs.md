# OpenRouter API — Model Specs as a Fallback Source

When HuggingFace blocks (gated models, 401, rate limits), the **OpenRouter API** at `https://openrouter.ai/api/v1/models` returns canonical specs for every model they host, including DeepSeek, Anthropic, Google, Meta, and others.

## Usage

```bash
# Fetch all models
curl -s https://openrouter.ai/api/v1/models | python -m json.tool

# Search for a specific model
curl -s https://openrouter.ai/api/v1/models | python -c "
import json, sys
data = json.load(sys.stdin)
for m in data.get('data', []):
    if 'deepseek-v4' in m.get('id', '').lower():
        print(json.dumps(m, indent=2))
"
```

## What it returns

| Field | Example (DeepSeek-V4-Flash) | Use case |
|-------|------------------------------|----------|
| `id` | `deepseek/deepseek-v4-flash` | Exact model slug for OpenRouter calls |
| `name` | `DeepSeek: DeepSeek V4 Flash` | Human-readable name |
| `description` | `DeepSeek V4 Flash is an efficiency-optimized MoE model with 284B total parameters and 13B activated parameters...` | **Parameter counts** (total + active for MoE) |
| `context_length` | `1048576` | **1M token context window** |
| `pricing.prompt` | `0.000000089` | Per-token input price |
| `pricing.completion` | `0.00000018` | Per-token output price |
| `pricing.input_cache_read` | `0.000000018` | Cached input price (if available) |
| `top_provider.context_length` | `1048576` | Actual serving context length |
| `supported_parameters` | `[tools, structured_outputs, ...]` | Tool calling, streaming, etc. |
| `architecture.instruction_type` | null | Whether it's a chat/completion model |

## When to use

- HuggingFace model card is blocked (gated repo, 401)
- HuggingFace raw README also blocked
- You need exact parameter counts for MoE models (total vs active)
- You need per-token pricing for cost comparison
- You need to verify feature support (tool calling, structured outputs, streaming)

## Example: DeepSeek-V4-Flash specs (from OpenRouter API)

- **Architecture:** Mixture-of-Experts (MoE)
- **Total parameters:** 284B
- **Active parameters:** 13B (per token)
- **Context window:** 1,048,576 tokens (1M)
- **Pricing:** ~$0.089/M input, ~$0.18/M output
- **Features:** Tools, structured outputs, reasoning (xhigh/high), logprobs, frequency/presence penalty, top_logprobs, repetition_penalty, min_p, seed, stop, response_format
- **Providers:** GMICloud, Baidu Qianfan, Alibaba Cloud, NovitaAI, AtlasCloud, StreamLake, Weights & Biases, Morph, Parasail

## MoE VRAM calculation

For MoE models, **all parameters must be loaded into VRAM** (only the active ones are computed per token, but the full weight matrix exists):

| Quantization | VRAM formula | Example (284B params) |
|-------------|-------------|----------------------|
| FP16 | total_params × 2 bytes | 284B × 2 = **568 GB** |
| 8-bit | total_params × 1 byte | 284B × 1 = **284 GB** |
| 4-bit (Q4) | total_params × 0.5 bytes | 284B × 0.5 = **142 GB** |
| 2-bit | total_params × 0.25 bytes | 284B × 0.25 = **71 GB** |

**Multi-GPU implications:** Divide total VRAM need by GPU VRAM to find minimum GPU count.
- 4-bit, 284B: 142 GB → 6× RTX 3090 (24 GB each) = 144 GB → $0.78/hr on Vast.ai
- 4-bit, 284B: 142 GB → 2× A100 PCIE (80 GB each) = 160 GB → $1.02/hr on Vast.ai