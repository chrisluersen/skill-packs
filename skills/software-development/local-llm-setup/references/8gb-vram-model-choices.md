# 8GB VRAM Model Choices (Qwen 3.5 vs Gemma 4)

Researched 2026-06-21 for the local fallback role on a 3060 Ti (8GB VRAM).

## Top Contenders

### Gemma 4 E4B (Q4_K_M) — In Practice: Too Big for 8GB VRAM
- **Ollama library size:** **9.6 GB** (includes vision + audio encoders, 8B total params)
- **Community GGUF variant:** 5.0 GB (text-only, e.g. `igorls/gemma-4-E4B-it-heretic-GGUF`)
- **VRAM @ 16K (Ollama lib):** ❌ Won't fit on 8GB VRAM
- **Full GPU offload:** ❌ Only the 5.0 GB community variant fits
- **Cold start (community variant):** 🟢 Fast (~5s)
- **Context:** 128K native
- **Key features:** Native function calling, structured JSON output, Google DeepMind quality, Apache 2.0
- **The case for it (community variant):** Leaves room for KV cache and concurrent agents. Faster than Qwen 3.5 9B in practice on 8GB VRAM because no CPU spillover.
- **The case against:** Ollama library build at 9.6 GB (Q4_K_M) is unusable on 8GB VRAM. Community GGUF variant is not the official Ollama build — may have compatibility issues or lack updates.

### Qwen 3.5 9B (Q4_K_M) — Smartest, Tightest Fit
- **Ollama size:** 6.6 GB (multimodal, includes vision encoder)
- **Text-only HF GGUF:** 5.63 GB (`lmstudio-community/Qwen3.5-9B-GGUF:Q4_K_M`)
- **VRAM @ 16K:** ~7.0 GB (Ollama version), ~6.5 GB (text-only)
- **Full GPU offload:** ✅ Only with capped context (8–16K via Modelfile)
- **Default Ollama context:** 262K → creates massive KV cache, spills 75% to CPU
- **Cold start:** 🟡 Slow (30–60s to load)
- **Decode speed (fully GPU):** 54–58 t/s
- **Context:** 262K native, extensible to 1M
- **AA Intelligence Index:** 32.4 (beats most 12B+ models)
- **The case for it:** Highest benchmark scores in the 8GB VRAM class. Vision-capable.
- **The case against:** Ollama multimodal build is 6.6 GB leaving ~1.4 GB for KV cache. Default context window overloads VRAM. Needs Modelfile workaround.

### Qwen 2.5 7B (Q4_K_M) — Reliable Classic
- **Ollama size:** 4.7 GB
- **VRAM:** ~5.5 GB at 16K
- **Full GPU offload:** ✅ Yes
- **Key feature:** Best tool calling in the 7B class. Battle-tested.

## Benchmark Data (from RTX 3070 on llama.cpp, localllm.in)

| Model | Context | GPU Layers | Weights (GPU) | Total VRAM Used |
|-------|:------:|:----------:|:-------------:|:---------------:|
| Qwen3.5-9B Q4_K_M | 4K | 33/33 | 5,061 MiB | 6,117 MiB |
| Qwen3.5-9B Q4_K_M | 16K | 33/33 | 5,061 MiB | 6,493 MiB |
| Qwen3.5-9B Q4_K_M | 32K | 33/33 | 5,061 MiB | 7,013 MiB |

**Note:** These figures are for the **text-only GGUF** (5.63 GB). The Ollama multimodal build (6.6 GB) will be ~1 GB higher across the board.

## Provider Latency for Qwen 3.5 9B (via OpenRouter)

| Provider | Latency | Throughput | Price /1M in/out | Uptime |
|----------|:------:|:----------:|:----------------:|:-----:|
| Together | 0.55s | 35 t/s | $0.17 / $0.25 | 98.8% |
| Venice | 0.67s | 71 t/s | $0.10 / $0.15 | 99.8% |
| DeepInfra | 0.90s | 14 t/s | $0.10 / $0.15 | 99.9% |
| SiliconFlow | 1.92s | 12 t/s | $0.10 / $0.15 | 99.1% |

## Ollama Modelfile for Context Capping

To cap Qwen 3.5 9B's context on 8GB VRAM, create a Modelfile:

```dockerfile
FROM qwen3.5:9b

# Cap context to fit VRAM (8K = ~6.3 GB, 16K = ~6.7 GB)
PARAMETER num_ctx 8192
```

Then build and run:
```bash
ollama create qwen3.5:9b-8k -f Modelfile
ollama run qwen3.5:9b-8k
```

Update the router's `.env`:
```
OLLAMA_MODEL=qwen3.5:9b-8k
```

## Key Insight: Vision Encoder Overhead

Ollama's Qwen 3.5 9B build includes a vision encoder even though it's not needed for text-only fallback. The encoder adds ~1 GB to the model size. For VRAM-constrained setups:
1. Use a text-only GGUF from HuggingFace (`lmstudio-community/Qwen3.5-9B-GGUF:Q4_K_M` at 5.63 GB)
2. Or choose a model that's text-only by design (Gemma 4 E4B, Qwen 2.5 7B, Llama 3.1 8B)
3. Or use a Modelfile to import the HF GGUF directly
