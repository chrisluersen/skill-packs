# telescope-fzf-native Build on Windows (MinGW + cmake)

**Build date:** 2026-06-19
**Status:** ✅ Built and verified (extension type=table)
**Neovim version:** 0.12.2
**Output:** `libfzf.dll` (~68KB) in plugin `build/` directory

## Why This Matters

telescope-fzf-native provides native fzf sorting for Telescope. Without it,
Telescope falls back to pure-Lua emulation — functional but ~3-10x slower
on repositories with 10K+ files.

## Build Command

```bash
cd ~/AppData/Local/nvim-data/lazy/telescope-fzf-native.nvim
mingw32-make
```

## Verification

```lua
:lua local t = require("telescope"); print(t.extensions.fzf)
-- Expected output: "table"
```

## Key Details

- MinGW-w64 is the **only** compiler that worked. MSVC (`cl.exe`) is not
  available on this system (no Visual Studio Build Tools installed).
- `mingw32-make` is used instead of `make` — the MinGW naming convention.
- The MinGW `bin/` directory is added to PATH via `.bashrc` under the
  `MINGW_DIR` variable.
- lazy.nvim's `build = "mingw32-make"` in the plugin spec handles rebuilds
  on plugin updates automatically.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `module not found` | Extension not loaded by lazy.nvim | Restart Neovim after build |
| `'mingw32-make' not found` | MinGW not on PATH | `export PATH="$MINGW_DIR:$PATH"` where MINGW_DIR is the MinGW bin/ |
| Extension loads as `nil` | DLL not found or wrong format | Rebuild: `cd plugin && mingw32-make clean && mingw32-make` |
