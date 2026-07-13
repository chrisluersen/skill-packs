# Windows Cleanup Session Notes

Quick-win batch used in this session:
1. Temp files (%TEMP%) — ~1,500 files / ~1.3 GB removed after confirming no locked items
2. Codex cache — drop to ~27 MB after killing `extension-host.exe` and removing `.tmp`, `plugins/cache`, `app-server-runtime/codex` bloat
3. HuggingFace cache — ~19 GB reclaimed when `odysseus/data/huggingface` was only Phi-mini-MoE-instruct; stale/unlinked download
4. Startup items — disabled BingSvc, EdgeAutoLaunch, DiscordPTB, GoogleDriveFS, TSMApplication, CurseForge, Jagex Launcher via registry + Startup folder
5. Browser caches — Edge and Brave caches removed: Cache, Code Cache, GPUCache, Service Worker, Storage\ext (~30 MB each)
6. Brave IndexedDB — 102 domains removed with 180–526 day age; safe because user last accessed Brave ages ago
7. Unused installer/screenshot/duplicate HTML/JSX exports from Desktop/Downloads/Documents
8. Ollama — `qwen3.5:9b` (~6.3 GB) removed; `.ollama/cache` cleared (4 KB); models
