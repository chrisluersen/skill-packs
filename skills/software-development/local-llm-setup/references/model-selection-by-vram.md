# Model Selection by VRAM — Extended Reference

## NVIDIA Consumer GPUs (4-bit Quantization)

| GPU | VRAM | 7B | 13B | 30B | 34B | 70B | Notes |
|-----|------|----|-----|-----|-----|-----|-------|
| RTX 3050 / 4050 | 4-6 GB | ✅ spill | ⚠️ heavy spill | ❌ | ❌ | ❌ | 4GB: 7B spills ~1GB |
| RTX 3060 / 4060 | 8 GB | ✅ full | ✅ spill | ⚠️ heavy | ❌ | ❌ | 8GB sweet spot for 13B |
| RTX 3060 Ti / 3070 | 8 GB | ✅ full | ✅ spill | ⚠️ heavy | ❌ | ❌ | Same as 3060 |
| RTX 3070 Ti / 4070 | 12 GB | ✅ full | ✅ full | ✅ spill | ✅ spill | ❌ | 12GB runs 30-34B with spill |
| RTX 3080 / 3080 Ti | 10-12 GB | ✅ full | ✅ full | ✅ spill | ✅ spill | ❌ | |
| RTX 3090 / 4090 | 24 GB | ✅ full | ✅ full | ✅ full | ✅ full | ✅ spill (4-bit) | 24GB runs 70B 4-bit |

**Spill penalty:** ~30-50% speed reduction per GB spilled to system RAM.

## Recommended Models by Tier (2024-2025)

### Coding Specialized
| Model | Sizes | Notes |
|-------|-------|-------|
| qwen2.5-coder | 1.5B, 3B, 7B, 14B, 32B | Best open coding model family |
| deepseek-coder-v2 | 16B, 236B | Strong, but 16B needs 10GB+ |
| codellama | 7B, 13B, 34B | Meta's coding models, older |
| starcoder2 | 3B, 7B, 15B | Good for code completion |

### General Reasoning + Coding (Best All-Rounders)
| Model | Sizes | Notes |
|-------|-------|-------|
| qwen2.5 | 0.5B, 1.5B, 3B, 7B, 14B, 32B, 72B | **Top pick** — strong reasoning, coding, multilingual |
| llama3.1 / 3.2 | 1B, 3B, 8B, 70B | Meta's latest, good but qwen2.5 often beats at same size |
| nemotron-3-ultra | 550B (MoE) | **Not for consumer** — 55B active, needs 256GB+ |
| nemotron-mini | 4B | NVIDIA small model, decent |

### Small & Fast (< 4B)
| Model | Size | VRAM | Use Case |
|-------|------|------|----------|
| phi3.5 | 3.8B | 2.5 GB | Microsoft, efficient, balanced |
| gemma2 | 2B, 9B | 1.5 / 5.5 GB | Google, good for size |
| llama3.2 | 1B, 3B | 0.8 / 2 GB | Tiny, fast, limited reasoning |

## Quant Selection Guide

| Quant | Quality | Size (7B) | VRAM (7B) | Recommendation |
|-------|---------|-----------|-----------|----------------|
| Q2_K / UD-IQ2 | Low | ~2.8 GB | ~3.2 GB | Emergency only |
| Q3_K_M / UD-IQ3 | Medium | ~3.3 GB | ~3.8 GB | Acceptable for chat |
| **Q4_K_M** | **Good** | **~3.8 GB** | **~4.3 GB** | **Default recommendation** |
| Q5_K_M | Better | ~4.3 GB | ~4.8 GB | Quality boost |
| Q6_K | Near-fp16 | ~5.0 GB | ~5.5 GB | Diminishing returns |
| FP16 | Full | 14 GB | 15 GB | Don't use locally |

**Ollama defaults to Q4_K_M** — this is the sweet spot.

## Decision Flowchart

```
START: What's your GPU VRAM?
├── 4 GB → qwen2.5:7b (spill) OR llama3.2:3b / phi3.5:3.8b (full VRAM)
├── 6 GB → qwen2.5:7b (full VRAM) OR qwen2.5:14b (spill)
├── 8 GB → qwen2.5:14b (full) OR llama3.1:8b (full)
├── 10-12 GB → qwen2.5:32b (spill) OR nemotron-mini:4b + qwen2.5:14b
├── 16-24 GB → qwen2.5:32b/72b (full) OR deepseek-coder-v2:16b
└── 24 GB+ → 70B models, mixing multiple

THEN: Primary use case?
├── Coding-heavy → qwen2.5-coder variant
├── General + coding → qwen2.5 (default)
├── Pure speed → 3B models (llama3.2, phi3.5, gemma2)
└── Max quality → largest that fits without heavy spill
```
