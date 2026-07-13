# Windows CLI Tools Installation (winget + scoop)

Documented from session 2026-06-18. All tools installed and verified on native Windows 10.

## Package Manager Strategy

| Source | Use For | Notes |
|--------|---------|-------|
| **winget** | First choice for all CLI tools | Pre-installed on Win10+, adds to user PATH automatically |
| **scoop** | Fallback for tools not on winget | Needs install, manages own shims dir |
| **pip** | Python-based CLI tools (httpie) | When winget version is wrong (GUI vs CLI) |

### Installing scoop (one-time)
```bash
powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression"
# Scoop shims land at ~/scoop/shims/ (added to user PATH automatically)
# Add extras bucket for more packages:
scoop bucket add extras
```

## Tool Installation Table

### Tier 1 — Daily Drivers (all via winget)

| Tool | winget Package ID | Binary Name | Verified Version |
|------|-------------------|-------------|-----------------|
| lazygit | `JesseDuffield.lazygit` | `lazygit.exe` | 0.62.2 |
| fzf | `junegunn.fzf` | `fzf.exe` | 0.73.1 |
| btop | `aristocratos.btop4win` | `btop4win.exe` ⚠️ | 1.0.5 |
| delta | `dandavison.delta` | `delta.exe` | 0.19.2 |

### Tier 2 — Useful (all via winget)

| Tool | winget Package ID | Binary Name | Verified Version |
|------|-------------------|-------------|-----------------|
| lazydocker | `JesseDuffield.Lazydocker` | `lazydocker.exe` | 0.25.2 |
| glow | `charmbracelet.glow` | `glow.exe` | 2.1.2 |
| chezmoi | `twpayne.chezmoi` | `chezmoi.exe` | 2.70.5 |
| age | `FiloSottile.age` | `age.exe` | 1.3.1 |

### Tier 3 — Via scoop (not on winget)

| Tool | scoop package | Binary Name | Verified Version |
|------|---------------|-------------|-----------------|
| yazi | `scoop install yazi` | `yazi.exe` + `ya.exe` | 26.5.6 |
| sops | `scoop install sops` | `sops.exe` | 3.13.1 |
| mdcat | `scoop install mdcat` | `mdcat.exe` | 2.7.1 |

### Special Cases

| Tool | Method | Notes |
|------|--------|-------|
| httpie | `pip install httpie` | ⚠️ winget `HTTPie.HTTPie` installs a **GUI** app, not the CLI. Use pip for the CLI version. |
| jless | **Not available** | No Windows binary. "Windows support is planned" per GitHub. Skip or use `jq` as alternative. |

## ⚠️ Windows-Specific Gotchas

### 1. btop binary is `btop4win.exe`, not `btop.exe`
The winget package `aristocratos.btop4win` installs `btop4win.exe`, not `btop.exe`. The PATH entry points to the correct directory, but if you're looking for the binary by name, use `btop4win`.

### 2. winget PATH not visible in current bash session
winget adds package directories to the **OS-level user PATH** (visible in new terminals), but the current bash/MSYS session has a stale PATH. To verify tools without restarting:
```bash
# Use full paths from the registry PATH
WINGET="$HOME/AppData/Local/Microsoft/WinGet/Packages"
"$WINGET/JesseDuffield.lazygit_Microsoft.Winget.Source_8wekyb3d8bbwe/lazygit.exe" --version
```
Or check via PowerShell (which reads the fresh registry PATH):
```bash
powershell.exe -Command "[Environment]::GetEnvironmentVariable('Path', 'User')"
```

### 3. HTTPie: GUI vs CLI
`winget install HTTPie.HTTPie` installs the HTTPie **desktop GUI** application, not the CLI tool. For the CLI:
```bash
pip install httpie
# Add Python Scripts to PATH if needed:
# C:\Users\<user>\AppData\Local\Python\pythoncore-3.14-64\Scripts
```

### 4. jless: No Windows Support
jless (github.com/PaulJulien/jless) has no Windows binary. The GitHub README states "Windows support is planned." Use `jq` or `fx` as alternatives for JSON exploration on Windows.

### 5. telescope-fzf-native: `make` not available on Windows
The telescope-fzf-native plugin specifies `build = "make"`, but `make` is not typically installed on Windows. **Telescope still works without fzf-native** — it just uses the slower built-in sorter. The plugin config should use `pcall` to gracefully handle the missing extension:
```lua
pcall(require("telescope").load_extension, "fzf")
```

### 6. markdown-preview.nvim: Use `npm install` not `yarn install`
On Windows, `yarn` may not be installed. Use `npm install` in the build step:
```lua
build = "cd app && npm install",
```

### 7. delta: One-Time Git Configuration Required

delta is installed but does nothing until configured as the git pager:

```bash
git config --global core.pager delta
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global merge.conflictstyle diff3
```

After this, `git diff`, `git log -p`, and `git show` render with syntax highlighting
and side-by-side layout. No need to launch delta directly — it intercepts git's pager output.

## Batch Installation Commands

### All winget tools (Tier 1 + 2) in one go:
```bash
winget install JesseDuffield.lazygit --accept-package-agreements --accept-source-agreements
winget install junegunn.fzf --accept-package-agreements --accept-source-agreements
winget install aristocratos.btop4win --accept-package-agreements --accept-source-agreements
winget install dandavison.delta --accept-package-agreements --accept-source-agreements
winget install JesseDuffield.Lazydocker --accept-package-agreements --accept-source-agreements
winget install charmbracelet.glow --accept-package-agreements --accept-source-agreements
winget install twpayne.chezmoi --accept-package-agreements --accept-source-agreements
winget install FiloSottile.age --accept-package-agreements --accept-source-agreements
```

### All scoop tools (Tier 3):
```bash
export PATH="$HOME/scoop/shims:$PATH"
scoop bucket add extras
scoop install yazi sops mdcat
```

## Verification

```bash
# Verify all tools (run in a NEW terminal to pick up PATH)
for tool in lazygit fzf btop4win delta lazydocker glow chezmoi age yazi sops mdcat http; do
  p=$(which $tool 2>/dev/null)
  if [ -n "$p" ]; then echo "✅ $tool → $p"; else echo "❌ $tool"; fi
done

# Verify Neovim plugins (should list ~30 plugin dirs)
ls "$HOME/AppData/Local/nvim-data/lazy/" | grep -v "pkg-cache\|readme"

# Sync plugins after config change:
nvim --headless "+Lazy! sync" "+sleep 30" "+qa"
```
