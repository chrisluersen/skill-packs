# Speech-to-Text Setup on Windows (faster-whisper)

Setup performed 2026-07-04 during foundation infrastructure execution. Enables local STT via Hermes config `stt.provider=local` with `faster-whisper`.

## Installation

```bash
# Ensure you're in the Hermes venv, NOT system Python
cd ~/AppData/Local/hermes/AppData/Local/hermes/hermes-agent
venv/Scripts/python.exe -m pip install faster-whisper
```

This installs `faster-whisper` + `ctranslate2`. On first use the base model (~150MB) downloads automatically.

## git-bash pitfall

`source venv/Scripts/activate` does NOT work reliably in git-bash/MSYS2. Always use the full path to the venv Python directly:

```bash
# WRONG — venv activation breaks in git-bash
source venv/Scripts/activate && python -c "import faster_whisper"

# RIGHT — use the full path
~/AppData/Local/hermes/AppData/Local/hermes/hermes-agent/venv/Scripts/python.exe -c "import faster_whisper"
```

## Config

Already set (no changes needed):
```yaml
stt:
  provider: local       # Uses faster-whisper
  model: whisper-1
```

## Verification

```bash
~/AppData/Local/hermes/AppData/Local/hermes/hermes-agent/venv/Scripts/python.exe -c "
from faster_whisper import WhisperModel
model = WhisperModel('base', device='cpu', compute_type='int8')
print('STT ready — base model loaded')
"
```

Model downloads on first import. Subsequent loads use cached model.

## Resource requirements

- **CPU mode** with `int8`: ~1-2GB RAM, usable on 5600X
- **Model sizes**: base (~150MB) recommended for speed; small/medium/large available
- **GPU mode**: possible via cuBLAS but not tested on this setup (3060Ti 16GB)
