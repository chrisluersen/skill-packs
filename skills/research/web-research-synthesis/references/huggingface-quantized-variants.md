# Finding Quantized / Distilled Model Variants on HuggingFace

When a model is too large to self-host at full precision, community quantized and distilled variants on HuggingFace often make self-hosting practical. Use this methodology to find them.

## Search Strategy

### 1. HuggingFace API search

```bash
curl -s "https://huggingface.co/api/models?search=<model-name>&sort=downloads&direction=-1&limit=30"
```

Filter results for quantized variants by checking the model ID for keywords:
- GGUF — `gguf`, `ggml`, `iq`, `q8`, `q4`, `q2`, `ds4`, `dwarfstar`
- AWQ — `awq`, `int4`
- GPTQ — `gptq`
- ExLlamaV2 — `exl2`, `bpw`
- Distilled — `distill`, `mini`, `spark`, `small`, `reap`
- Other — `bml`, `unslo`, `quan`, `mix`

### 2. Key signal: download count + likes

```python
# High download count + high likes = trusted community variant
# 0xSero/DeepSeek-V4-Flash-162B-GGUF: 16K downloads, 24 likes
# bartowski/DeepSeek-V4-Flash-GGUF: 120K downloads, 26 likes
# unsloth/GLM-5.2-GGUF: 239K downloads, 491 likes
```

Prioritize variants with:
- **Downloads > 10K** — sufficient community testing
- **Likes > 10** — community endorsement
- **Known quantizer** — TheBloke, bartowski, unsloth, 0xSero, LoneStriker are reputable

### 3. Check on-disk file size

```bash
curl -s "https://huggingface.co/api/models/<org>/<model>" | python -c "import json, sys; d=json.load(sys.stdin); [print(f'{s[\"rfilename\"]:50s} {s.get(\"size\",0)/1e9:.1f} GB') for s in d.get('siblings',[]) if s['rfilename'].endswith('.gguf')]"
```

The GGUF file size tells you the VRAM requirement:
- File ≤ GPU VRAM → fits on single GPU with room for KV cache
- File ~1.5× GPU VRAM → needs 2 GPUs with model parallelism
- File > 2× GPU VRAM → needs multi-GPU setup

### 4. Read the variant's README

```bash
curl -s "https://huggingface.co/<org>/<model>/raw/main/README.md"
```

Look for:
- **"At a glance" table** — shows total params, active params (MoE), on-disk size
- **"Which variant should I pick?"** — recommended quantization level
- **"Files" table** — lists each GGUF file with exact size and quantization level
- **Quantization types** — Q2 = 2-bit, Q3 = 3-bit, Q4 = 4-bit, Q5 = 5-bit, Q6 = 6-bit, Q8 = 8-bit
- **MoE-specific** — DS4 (DwarfStar), REAP-pruned, expert-offloaded variants

## Known distilled variants (as of 2026-07-02)

### DeepSeek-V4-Flash (official: 284B MoE, 13B active)

| Variant | Params | GGUF Q2 size | GPUs needed | Best for |
|---------|--------|-------------|-------------|----------|
| **0xSero/DeepSeek-V4-Flash-162B-GGUF** | **162B** (REAP-distilled) | **49 GB** | **1× A100 80GB** | Cheapest self-host |
| 0xSero/DeepSeek-V4-Flash-180B-GGUF | 180B | ~54 GB | 1× A100 80GB | More quality headroom |
| 0xSero/DeepSeek-V4-Flash-213B-GGUF | 213B | ~64 GB | 1× H100 80GB | Closer to original quality |
| bartowski/DeepSeek-V4-Flash-GGUF | 284B (MXFP4) | 4 shards ~172 GB | 2× A100 80GB | Full model, 4-bit |

### GLM-5.2 (official: 753B MoE, 40B active)

| Variant | Format | On-disk size | GPUs needed | Best for |
|---------|--------|-------------|-------------|----------|
| **unsloth/GLM-5.2-GGUF** | IQ2 (2-bit) | **~239 GB** | 1× RTX 4090 + RAM (offload) | Cheapest GLM-5.2 path |
| QuantTrio/GLM-5.2-Int4-Int8Mix | 4-bit | ~378 GB | 5× A100 80GB | Near-lossless quality |

## MoE VRAM calculation rule

For Mixture-of-Experts models, **ALL parameters must be loaded** even though only active experts fire per token:

```
VRAM = total_params × bytes_per_param
```

| Quantization | Bytes/param | 284B model | 162B model | 753B model |
|-------------|-------------|-----------|-----------|-----------|
| FP16 | 2 | 568 GB | 324 GB | 1,506 GB |
| 8-bit | 1 | 284 GB | 162 GB | 753 GB |
| 4-bit (Q4) | 0.5 | 142 GB | 81 GB | 377 GB |
| 3-bit (Q3) | 0.375 | 107 GB | 61 GB | 282 GB |
| **2-bit (Q2)** | **0.25** | **71 GB** | **41 GB** | **188 GB** |

Active parameter count (e.g., 13B active for DeepSeek-V4-Flash) only affects **throughput (tokens/sec)**, not VRAM. A model with small active params runs fast but still needs full VRAM.

## Multi-GPU sizing

Once you know the model's on-disk GGUF size, plan GPU count:

```
GPUs needed = ceil(gguf_file_size / GPU_VRAM)
```

Leave ~10 GB headroom per GPU for KV cache, intermediate buffers, and the running system.

| GGUF size | 1× RTX 3090 (24 GB) | 1× A100 (80 GB) | 2× A100 (160 GB) |
|-----------|--------------------|-----------------|------------------|
| 49 GB (162B Q2) | ❌ too big | ✅ fits | ✅ overkill |
| 71 GB (284B Q2) | ❌ too big | ✅ fits | ✅ overkill |
| 142 GB (284B Q4) | ❌ | ❌ | ✅ fits |
| 239 GB (GLM-5.2 IQ2) | ❌ | ❌ | ❌ (needs CPU offload) |