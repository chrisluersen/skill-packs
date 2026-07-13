# GLM-5.2 Deployment Research

**Date:** 2026-07-01  
**Source:** Session with Stella  
**Model:** Z.ai GLM-5.2 (released 2026-06-16, MIT license)  
**Use case:** Serverless self-host to replace/reduce Nous portal spend

## Model Specs

| Attribute | Value |
|-----------|-------|
| Architecture | MoE (IndexShare sparse attention) |
| Total parameters | ~753B |
| Active per token | ~39-40B |
| Context window | 1M tokens (full on 8×B200, configurable on 8×H200) |
| Max output tokens | 128K (via 5-token MTP speculative decoding) |
| License | MIT (open weights, no restrictions) |
| Quantizations available | BF16 (1.5TB), FP8 (~893GB), NVFP4, Q4_K_M GGUF (~376GB), 2-bit UD-IQ2_XXS (~241GB) |
| Inference engines | vLLM ≥0.23.0, SGLang ≥0.5.13, Transformers ≥5.12, KTransformers, llama.cpp |
| Tool calling | Yes (`--tool-call-parser glm47`, `--enable-auto-tool-choice`) |
| Reasoning modes | `high` and `max` (`xhigh`) effort levels |

## vLLM Launch (from recipes.vllm.ai)

**FP8 on 8×H200 (standard):**
```bash
vllm serve zai-org/GLM-5.2-FP8 \
  --kv-cache-dtype fp8 \
  --tensor-parallel-size 8 \
  --speculative-config.method mtp \
  --speculative-config.num_speculative_tokens 5 \
  --tool-call-parser glm47 \
  --reasoning-parser glm45 \
  --enable-auto-tool-choice \
  --served-model-name glm-5.2-fp8
```

**Minimum viable hardware:** 8×H200 (141GB each) or 8×H100 80GB for FP8.  
**Full 1M context:** 8×B200 (180GB each).  
**Does not fit on:** Single GPU (any), 4×H100 (need Q4 GGUF), consumer hardware (RTX 5090 = 32GB).

## Provider Cost Comparison

### API Providers (per million tokens)

| Provider | Input /M | Output /M | Cache /M | Latency | Throughput | Uptime |
|----------|----------|-----------|----------|---------|------------|--------|
| **DeepInfra** (via OR) | **$0.93** | **$3.00** | $0.18 | 0.98s | 27 tps | 98.01% |
| Together AI | $1.40 | $4.40 | $0.26 | — | — | — |
| Z.ai (direct) | $1.40 | $4.40 | $0.26 | 5.36s | 37 tps | 99.43% |
| Fireworks | $1.40 | $4.40 | $0.14 | 1.55s | 45 tps | 99.24% |
| Wafer (via OR) | $1.20 | $4.10 | $0.20 | 1.29s | 72 tps | 99.80% |

**Best deal:** DeepInfra at $0.93/$3.00 — 34% cheaper than Z.ai direct.

### Self-Host / Serverless

| Option | Hardware | Cost | Notes |
|--------|----------|------|-------|
| RunPod serverless | 8×H100 workers | $4.18/hr × 8 = **$33.44/hr** | Auto-scales to 0, but 70-460s cold start |
| RunPod serverless | 5×A100 (Q4 GGUF) | $2.72/hr × 5 = **$13.60/hr** | Lower quality from quantization |
| RunPod dedicated pod | 8×H100 (secure) | $3.29/hr × 8 = **$26.32/hr** | Always-on, no cold start |
| RunPod dedicated pod | 8×H100 (community) | $2.89/hr × 8 = **$23.12/hr** | Always-on, preemptible |

### Volume-Based Break-Even

Assumptions: typical agent session = 300K in + 700K out tokens, ~2 min GPU active time.

| Provider | Cost per Session | Monthly at 1/day | Monthly at 10/day | Monthly at 100/day |
|----------|-----------------|-----------------|------------------|-------------------|
| Nous Plus ($20/mo) | ~$0.67 (flat) | $20 | $20 | $20 |
| DeepInfra API | ~$2.38 | $71 | $714 | $7,140 |
| RunPod serverless (8×H100) | ~$1.11 | $33 | $333 | $3,330 |

**Key insight:** API is cheapest under ~8-10 sessions/day. Serverless only wins at very high volume (30+ sessions/day) AND only if cold starts are tolerable or min workers are used.

## Integration with Hermes

- **All API providers** support OpenAI-compatible endpoints → drop into `hermes-router` as a model/provider pair
- **RunPod vLLM** also exposes an OpenAI-compatible endpoint → works as a custom provider
- **Tool calling:** GLM-5.2 supports it natively via `--tool-call-parser glm47` and `--reasoning-parser glm45`
- **Context caching:** Not available via DeepInfra/OpenRouter for this model yet. Z.ai direct supports it.

## Recommended Path (for user)

1. **Start with DeepInfra via OpenRouter** — cheapest API access ($0.93/$3.00 per M), no infra, drop-in Hermes router config
2. **Use selectively** — route heavy coding/agent sessions to GLM-5.2, keep cheaper models for chat
3. **Re-evaluate at scale** — if spending >$50/mo on API, investigate RunPod serverless with FlashBoot + min 1 worker

## Source URLs

- https://huggingface.co/zai-org/GLM-5.2 — Official model card
- https://z.ai/blog/glm-5.2 — Official blog post
- https://recipes.vllm.ai/zai-org/GLM-5.2 — vLLM launch recipe
- https://openrouter.ai/z-ai/glm-5.2 — Provider comparison table
- https://www.runpod.io/pricing — GPU pricing
- https://ofox.ai/blog/glm-5-2-self-host-vllm-hardware-cost-2026/ — Third-party hardware analysis
