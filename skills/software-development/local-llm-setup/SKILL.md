---
name: local-llm-setup
description: "Set up local LLM inference on Windows with Ollama, llama.cpp, or vLLM. Covers model selection by VRAM tier, Ollama Hermes integration, context length tuning, and hardware-constrained deployment for 4GB-24GB GPUs."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [local-llm, ollama, llama.cpp, vllm, hardware-constraints, model-selection, hermes-integration, windows, user-created]
    related_skills: [hermes-agent, hermes-config-review-methodology]
---

# Local LLM Setup for Hermes on Windows

Guide for setting up local LLM inference for Hermes using Ollama, llama.cpp, or vLLM, with hardware constraints (RTX 3060 Ti, 8GB VRAM).

## Trigger

- "I want to use a local model"
- "Setup local inference"
- "Which model can my GPU run?"
- "Ollama setup"
- "llama.cpp server config"
- "vLLM on Windows"

## VRAM Budgeting (RTX 3060 Ti - 8GB VRAM)

Generic VRAM budget for other GPUs (4GB → 12GB → 24GB):
| Tier | Context | Concurrent Children | Example GPUs |
|------|---------|-------------------|--------------|
| 4GB | 8192 | 0 | GTX 1650 |
| 6GB | 16384 | 0-1 | GTX 1060, RTX 2060 |
| 8GB | 32768-65536 | 1-2 | **RTX 3060 Ti**, RTX 3070 |
| 12GB | 65536-131072 | 2-3 | RTX 3080, RTX 4070 |
| 24GB | 131072+ | 3-5 | RTX 3090, RTX 4090 |

### VRAM Budget: RTX 3060 Ti (8GB)

```
Total VRAM: 8192 MB

Hermes base (model + context):
  Model weights (7B Q4_K_M):     ~4500 MB
  KV cache (65536 context):       ~2048 MB
  ──────────────────────────────────────
  Subtotal (no delegation):       ~6548 MB

Hermes with 2 concurrent agents:
  Base:                           ~4500 MB
  KV cache x1 (65536):            ~2048 MB
  KV cache x2 (32768):             ~1024 MB
  ──────────────────────────────────────
  Subtotal (2 children):          ~7572 MB  (OK - ~620 MB headroom)

Hermes with 3 concurrent agents:
  Base:                           ~4500 MB
  KV cache x3 (32768):            ~1536 MB
  ──────────────────────────────────────
  Subtotal (3 children):          ~6036 MB (but only 1 gpu layer)
  => OOM risk
```

**Key takeaway:** With delegation.max_concurrent_children: 2 on Ollama, Hermes stays within budget with ~620 MB headroom. With delegation.max_concurrent_children: 3, Hermes risks OOM.

## Ollama Setup

### Installation
1. Download Ollama from https://ollama.com/download (Windows installer)
2. Verify with `ollama --version`
3. Pull a model: `ollama pull nemotron-mini`

### Models by Size (for 8GB VRAM — RTX 3060 Ti / RTX 3070)

**⚠️ Ollama multimodal models include a vision encoder** that adds ~1 GB overhead even for text-only use. For Qwen 3.5 9B, the Ollama library version is 6.6 GB, but the text-only HF GGUF is 5.63 GB. When VRAM is tight, prefer a text-only GGUF or a smaller model altogether.

| Model | Ollama Size | VRAM @ 16K | Fits? | Cold start | Agent? | Notes |
|-------|:----------:|:----------:|:-----:|:----------:|:-----:|-------|
| **Qwen 3.5 9B** (Q4_K_M) | 6.6 GB | ~7.0 GB | ⚠️ Capped ctx | 🟡 Slow (30-60s) | ✅ Great | **Best benchmarks** but default 262K ctx spills to CPU. Use Modelfile with `num_ctx 8192`–`16384` for 8GB VRAM. See `references/8gb-vram-model-choices.md` |
| **Qwen 2.5 7B** (Q4_K_M) | 4.7 GB | ~5.5 GB | ✅ Full GPU | 🟢 Fast (15-30s) | ✅ Good | **Reliable classic** — best tool calling in 7B class. Tested at scale |
| **Llama 3.1 8B** (Q4_K_M) | 5.0 GB | ~6.0 GB | ✅ Full GPU | 🟢 Fast | ✅ Solid | **Safe English-first** general fallback |
| **Gemma 4 E4B** (Ollama lib) | ❌ **9.6 GB** | — | ❌ Won't fit | — | ✅ Native fn-call | **Ollama library version is 9.6 GB** — exceeds 8GB VRAM. Community Q4_K_M GGUFs exist at ~5.0 GB but aren't the official Ollama build |
| **Phi-3.5-mini 3.8B** | 2.5 GB | ~3.5 GB | ✅ Comfortable | 🟢 Instant (3-5s) | 🟡 Basic | **Lightest good option** — fast cold start, full GPU offload |

**8GB VRAM model choice guidance:**
- **Gemma 4 E4B** (5.0 GB) gives 3 GB headroom for KV cache, faster inference, and native tool-calling — best for an agent fallback role
- **Qwen 3.5 9B** (6.6 GB) wins on benchmarks but default 262K context spills to CPU on 8GB VRAM. Use a Modelfile to cap context to 8K–16K for workable fit
- Text-only GGUFs from HuggingFace (e.g. `lmstudio-community/Qwen3.5-9B-GGUF:Q4_K_M`) save ~1 GB over Ollama's multimodal build
- See `references/8gb-vram-model-choices.md` for detailed benchmark data and provider comparisons

### Hermes Ollama Integration
1. Ensure Ollama server is running: `ollama serve` (background)
2. In Hermes config.yaml:
   ```yaml
   model:
     provider: openai  # Ollama uses OpenAI-compatible endpoint
     base_url: http://localhost:11434/v1
     model: nemotron-mini:4b
     context_length: 65536
     ollama_num_ctx: 65536  # MUST match context_length
   ```

## Context Length Tuning

The `context_length` and `ollama_num_ctx` settings MUST match. Mismatch causes silent truncation:
- `context_length` in Hermes tokenizer
- `ollama_num_ctx` in Ollama KV cache size
- If `context_length > ollama_num_ctx`: Hermes thinks it can use more context than Ollama allocated → silent truncation
- Solution: Keep both at the model's actual max context, or a value that fits in VRAM:

```yaml
# 8GB VRAM config
model:
  context_length: 65536
  ollama_num_ctx: 65536

# 4GB VRAM fallback
model:
  context_length: 8192
  ollama_num_ctx: 8192
```

## Using Local GGUF Files with Ollama

When you have a GGUF file from HuggingFace (or elsewhere) that's not in Ollama's library, import it via a Modelfile:

### Step-by-step

1. **Download** the GGUF from HuggingFace to a local folder:
   ```bash
   mkdir -p ~/models/stheno
   curl -L -o ~/models/stheno/model-name.gguf "https://huggingface.co/ORG/REPO/resolve/main/model-name.gguf"
   ```

2. **Create a Modelfile** in the same directory with the correct chat template for the model architecture:
   ```dockerfile
   FROM ~/AppData/Local/hermes\models\stheno\model-name.gguf

   TEMPLATE """{{ if .System }}<|start_header_id|>system<|end_header_id|>

   {{ .System }}<|eot_id|>{{ end }}<|start_header_id|>user<|end_header_id|>

   {{ .Prompt }}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

   {{ .Response }}<|eot_id|>"""

   PARAMETER num_ctx 8192
   PARAMETER temperature 0.7
   ```

   **Template by architecture:**
   - **Llama 3** — `{{ if .System }}<|start_header_id|>system<|end_header_id|>\n\n{{ .System }}<|eot_id|>{{ end }}<|start_header_id|>user<|end_header_id|>\n\n{{ .Prompt }}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n\n{{ .Response }}<|eot_id|>`
   - **ChatML / Qwen** — `{{ if .System }}<|im_start|>system\n{{ .System }}<|im_end|>{{ end }}<|im_start|>user\n{{ .Prompt }}<|im_end|><|im_start|>assistant\n{{ .Response }}<|im_end|>`
   - **Mistral / Gemma** — `{{ .Prompt }}`
   - **Default Ollama template** — run `ollama show <existing-model> --modelfile | grep TEMPLATE` to extract from a known model

3. **Create the model in Ollama** (run from the Modelfile's directory):
   ```bash
   cd ~/AppData/Local/hermes/models/stheno
   ollama create my-model-name -f Modelfile
   ```

4. **Verify** it's registered:
   ```bash
   ollama list
   ```

5. **Test inference:**
   ```bash
   curl -s --max-time 120 -X POST http://localhost:11434/api/generate \
     -d '{"model": "my-model-name", "prompt": "Hi", "stream": false}'
   ```

### Windows path format

The `FROM` line in a Modelfile **must use Windows paths** (`C:\Users\...\file.gguf`), not MSYS paths (`/c/Users/.../file.gguf`). Ollama rejects MSYS paths with "400 Bad Request: invalid model name."

The `-f Modelfile` flag must resolve from the current directory — run `ollama create` inside the folder containing the Modelfile.

### Changing quantizations

To switch to a different quantization (e.g. Q4_K_M → Q5_K_M):
1. Download the new GGUF
2. Update the `FROM` path in the Modelfile
3. `ollama rm old-model-name`
4. `ollama create model-name -f Modelfile`

The old GGUF can be deleted after the new one is registered.

## Embedding Models in Ollama

Ollama can serve embeddings (vector representations of text) via `/api/embed`, used for RAG, semantic search, and tools like Open Notebook. But there are important gotchas.

### Which models support embeddings?

**Ollama 0.30+:** The `/api/embed` endpoint only works with **dedicated embedding models**, not general LLMs. If you try `qwen3:8b` or `llama3` you'll see:
```
Failed to get embeddings: Ollama API error: This server does not support embeddings.
```

This error is **misleading** — the `--embeddings` flag it suggests was removed from Ollama 0.30. The real fix is using a proper embedding model.

### Dedicated embedding models

| Model | Size | Quality | Use Case |
|-------|------|---------|----------|
| `nomic-embed-text:v1.5` | ~274MB | Excellent general purpose | Best all-rounder |
| `snowflake-arctic-embed:33m` | ~67MB | Fast, lightweight | Quick semantic search |
| `all-minilm:l6-v2` | ~43MB | Fastest, tiny | Caching / low-resource |

Pull one:
```bash
ollama pull nomic-embed-text
```

### Testing embeddings

```bash
# Quick test that embeddings work
curl -s http://localhost:11434/api/embed \
  -d '{"model": "nomic-embed-text", "input": "test embedding"}' | \
  python -c "import sys,json; d=json.load(sys.stdin); print('OK, vector len:', len(d['embeddings'][0]))"
```

Expected output: `OK, vector len: 768` (or similar dimension)

### Registering for Open Notebook / other tools

When integrating with Open Notebook, register the embedding model separately from the chat model:

```python
# Chat model (LLM)
{"name": "qwen3:8b", "provider": "ollama", "type": "llm"}

# Embedding model (separate)
{"name": "nomic-embed-text", "provider": "ollama", "type": "embedding"}
```

Set the embedding default to the SurrealDB ID assigned during registration:
```python
{"default_embedding_model": "model:<surrealdb-id-for-embedding-model>"}
```

### Verifying end-to-end in a container

Inside Docker containers (Open Notebook, etc.), the worker process uses `uv run --no-sync` (not bare `python`) to run embedding commands. Check worker logs for errors:
```bash
docker logs <container-name> 2>&1 | grep -i "embed\|error\|traceback"
```

When retrying failed embeddings:
1. Delete old failed commands: `DELETE source_embedding`
2. Submit new `embed_source` commands with the correct model default
3. The worker processes them asynchronously

## Pitfalls
- **WDDM VRAM leak (Windows)** — When Ollama's `llama-server.exe` crashes or OOMs, the Windows WDDM driver may pin VRAM allocations even after the process is dead. The process disappears from `tasklist` but `nvidia-smi` still shows the same memory usage. Symptom: `ollama ps` shows "Stopping..." forever, and new model loads fail silently. **Fix:** Reboot Windows. Workaround: keep a known-good model (e.g. Q4_K_M of the same architecture) that fits with headroom.
- **\"Real-world\" VRAM on Windows is less than 8GB** — WDDM mode + background apps (browser, Discord, Steam, wallpaper engine, shell compositor) typically consume 1-2 GB of VRAM before any models are loaded. On an 8GB card, actual usable VRAM for models is ~6-6.5 GB on a clean boot with a browser open. Budget accordingly.
- **Ollama server must be running** — Hermes won't start it for you
- **Ollama only exposes one model at a time** — switching models on the fly is not supported well
- **VRAM limits delegation** — each concurrent agent child adds KV cache overhead
- **Don't mix `model.context_length` and `agent.max_turns`** — they interact; reduce context_length first if OOM
- **Ollama's `num_ctx` defaults to 2048** — always set explicitly to match Hermes config
