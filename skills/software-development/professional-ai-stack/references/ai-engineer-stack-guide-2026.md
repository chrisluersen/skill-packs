# AI Engineering Stack Guide — June 2026

> Example output of the professional-ai-stack skill.
> Written for: Windows 10, RTX 3060 Ti (8GB VRAM), CUDA 13.2, Python 3.11, uv

---

## 1. Hardware Constraints

| Component | Spec | Implication |
|---|---|---|
| GPU | RTX 3060 Ti (8GB VRAM) | Fine-tune 7B with QLoRA. Run 7B GGUF Q4_K_M. |
| CUDA | 13.2 (driver 596.49) | Needs PyTorch nightly (cu132) or stable (cu130). |
| Disk | ~130GB free | Enough for a few models, not a collection. |
| OS | Windows 10 | Some tools need WSL (SGLang, Triton, mainline vLLM). |

**Ceiling**: 7B fine-tune via QLoRA, 13B inference via Q3_K_M (slow).

## 2. Editors

| Tool | Cost | Verdict |
|---|---|---|
| VS Code + Copilot | $10/mo | Default choice. Familiar, extensible. |
| Cursor | $20/mo | Fork of VS Code, deeper multi-file AI. Worth $20 if you refactor a lot. |

## 3. Python & Package Management

Use **uv** (already installed). Not pip, not poetry, not conda.

```bash
uv pip install <pkg>              # 10x faster than pip
uv run python script.py           # Auto-activates venv
uv add <pkg>                      # pyproject.toml management
uv lock && uv sync                # Lockfile reproducibility
```

## 4. Deep Learning: PyTorch

Your CUDA 13.2 is bleeding edge. Map:

| PyTorch | CUDA | Install |
|---|---|---|
| 2.12 stable | 13.0 (PyPI) | `uv pip install torch torchvision torchaudio` |
| 2.12 nightly | 13.2 (experimental) | `uv pip install torch --index-url https://download.pytorch.org/whl/nightly/cu132` |

Start with stable. Switch to nightly only if you need a specific feature on CUDA 13.2.

## 5. Training Stack

| Tool | Windows? | Why |
|---|---|---|
| Transformers | Yes | Industry standard model hub |
| PEFT (LoRA/QLoRA) | Yes | Fine-tune 7B on 8GB VRAM |
| Unsloth | Yes (native) | 2x faster LoRA, half the memory |
| Accelerate | Yes | HF training launcher |
| DeepSpeed | Partial | ZeRO optimization |
| W&B | Yes | Experiment tracking |

## 6. Serving Path

```
Ollama (today) → llama.cpp (week 1) → vLLM fork (month 1) → SGLang in WSL (month 3)
```

**Windows notes:**
- Ollama: native, zero-config
- llama.cpp: native, more control
- vLLM: Windows fork at SystemPanic/vllm-windows; mainline PR not yet merged
- SGLang: WSL only

## 7. Data & RAG

| Tool | Windows? | Start | Graduate To |
|---|---|---|---|
| ChromaDB | Yes | ✓ | |
| Qdrant | Docker | | ✓ |
| LlamaIndex | Yes | ✓ | |
| Unstructured | Yes | ✓ | |
| DuckDB | Yes (in `hf` CLI) | ✓ | |

## 8. MLOps

| Tool | Windows? | Why |
|---|---|---|
| W&B | Yes | Experiment tracking, sweeps, registry |
| MLflow | Yes | Open-source alternative |
| BentoML | Yes | Package models as services |
| Docker | Yes | Reproducibility |
| GitHub Actions | Yes | CI/CD |

## 9. The WSL Decision

**Needs WSL on Windows**: SGLang, Triton, mainline vLLM, Flash Attention 2 custom builds.

**Works natively on Windows**: Unsloth, Ollama, llama.cpp, HF ecosystem, PEFT, ChromaDB, LlamaIndex, W&B, MLflow, BentoML, DuckDB.

Install WSL 2 with Ubuntu 24.04 if you need the first group.

## 10. One-Shot Install

```bash
uv pip install torch torchvision torchaudio
uv pip install transformers accelerate peft datasets
uv pip install "unsloth[cu121] @ git+https://github.com/unslothai/unsloth.git"
uv pip install chromadb sentence-transformers llama-index langchain unstructured
uv pip install wandb mlflow bentoml
uv pip install ruff pytest pytest-xdist
uv pip install nvitop gpustat
uv pip install "huggingface_hub[hf]"
ollama pull llama3.2:3b
ollama pull qwen2.5:7b-instruct
```
