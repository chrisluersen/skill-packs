# Ollama + Hermes Integration — Session Notes

## Reproduction: Context Window Error (2026-06-09)

**Environment:** Windows 10, RTX 3060 Ti (4 GB VRAM), 16 GB RAM, Ollama 0.30.3, Hermes Agent

**Error sequence:**
1. Set `model.provider=custom`, `model.base_url=http://localhost:11434/v1`, `model.default=qwen2.5:7b`
2. Run `hermes chat -q "test"`
3. Error: `Model qwen2.5:7b has a context window of 32,768 tokens, which is below the minimum 64,000 required by Hermes Agent.`

**Fix applied:**
```bash
hermes config set model.context_length 65536
# Still failed — Ollama runtime still using 32K
hermes config set model.ollama_num_ctx 65536
# Success: "Ollama + qwen2.5:7b working!"
```

**Key insight:** `ollama_num_ctx` is passed as `num_ctx` in the request payload to Ollama's `/v1/chat/completions`. This is a Hermes-specific parameter (not standard OpenAI). Without it, Ollama uses model default (32K for qwen2.5:7b).

## Request Payload Structure (Observed)

When `ollama_num_ctx` is set, Hermes sends:
```json
{
  "model": "qwen2.5:7b",
  "messages": [...],
  "num_ctx": 65536,
  "temperature": 0.7,
  ...
}
```

Ollama accepts `num_ctx` as a model parameter (documented in Ollama API).

## Windows Service Management

Ollama installs as Windows service "Ollama". Restart via:
- Services.msc → Ollama → Restart
- `net stop Ollama && net start Ollama` (admin)
- `ollama serve` runs foreground (not needed if service running)

## Model Pulls Completed (2026-06-09)

| Model | Size | Pull Time | Notes |
|-------|------|-----------|-------|
| qwen2.5:7b | 4.7 GB | ~3 min | Best quality, slight VRAM spill |
| llama3.2:3b | 2.0 GB | ~1 min | Fully in VRAM, fastest |
| phi3.5:3.8b | 2.2 GB | ~1 min | Fully in VRAM, balanced |

Total disk: ~9 GB at `C:\Users\<user>\.ollama\models\`

## Verification Commands

```bash
ollama list                    # Shows installed models
ollama ps                      # Shows currently loaded (VRAM)
ollama run qwen2.5:7b "hi"     # Quick test
hermes chat -q "test"          # Full Hermes test
```
