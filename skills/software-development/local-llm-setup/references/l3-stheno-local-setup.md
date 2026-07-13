# L3-8B-Stheno-v3.1 — Local GGUF Setup on Ollama

**Source:** Repo `Lewdiculous/L3-8B-Stheno-v3.1-GGUF-IQ-Imatrix`
**Hardware:** RTX 3060 Ti (8GB VRAM), Windows 10 WDDM
**Quantizations tested:** Q5_K_M (failed), Q4_K_M (success)

## Available Quants

| File | Size | Fits 8GB VRAM | 
|------|:----:|:-----------:|
| `-Q4_K_M-imat.gguf` | 4.69 GB | ✅ Yes (~2 GB headroom) |
| `-Q5_K_M-imat.gguf` | 5.47 GB | ❌ No (OOM during inference) |
| `-Q6_K-imat.gguf` | 6.29 GB | ❌ No (won't even load) |

## Modelfile Used

```dockerfile
FROM ~/AppData/Local/hermes\models\stheno\L3-8B-Stheno-v3.1-Q4_K_M-imat.gguf

TEMPLATE """{{ if .System }}<|start_header_id|>system<|end_header_id|>

{{ .System }}<|eot_id|>{{ end }}<|start_header_id|>user<|end_header_id|>

{{ .Prompt }}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

{{ .Response }}<|eot_id|>"""

PARAMETER num_ctx 8192
PARAMETER temperature 0.7
PARAMETER top_p 0.9
```

## Performance (Q4_K_M, 8192 ctx)

| Metric | Value |
|--------|-------|
| Cold start (first load) | ~25s |
| Inference speed | ~62 t/s (92% GPU offload) |
| VRAM at idle (loaded) | ~6.2 GB (model + KV cache) |
| VRAM during inference | ~7.0 GB (compute overhead) |

## WDDM Debug Trace

When the Q5_K_M quant OOM'd during inference:
1. `nvidia-smi` showed 7785/8192 MiB used
2. `ollama ps` showed model stuck in "Stopping..." state
3. `tasklist /fi "imagename eq llama-server.exe"` showed no process
4. VMAM never released — stayed at ~7747 MiB even after killing all Ollama processes
5. Only a reboot cleared the allocation

**Cause:** Windows WDDM driver pins VRAM allocations from crashed GPU processes. The process exits but the driver doesn't reclaim the memory. Subsequent model loads fail silently (curl to Ollama API times out).

## Model Details

- **Architecture:** Llama 3 (general.architecture = "llama")
- **Base:** L3-8B-Stheno-v3.1 (roleplay fine-tune of Llama 3 8B)
- **Template:** Llama 3 chat format (`<|begin_of_text|><|start_header_id|>...<|end_header_id|>`)
- **Download URL pattern:** `https://huggingface.co/ORG/REPO/resolve/main/FILENAME`
