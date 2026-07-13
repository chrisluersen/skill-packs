---
name: ai-terminal-stack
description: "Plan, configure, and maintain a high-performance AI-oriented terminal stack: zellij (multiplexer) + Neovim (editor) + herm (Hermes dashboard) + supporting CLIs."
triggers:
  - User wants to set up or modify their terminal/editor environment for AI-assisted development
  - User is comparing tmux vs zellij, VS Code vs Zed vs Neovim
  - User needs database UI for Neovim (dadbod-ui vs nvim-dbee vs sqls)
  - User wants remote access via Tailscale (SSH/Mosh, Zellij Web Client, Hermes Gateway)
  - User wants to track stack decisions in a wiki
  - User wants to understand Discord + Hermes vs local stack trade-offs
  - User wants comprehensive stack comparison (zellij, tmux, wezterm, ghostty, Zed, VS Code)
---

# AI Terminal Stack - zellij/neovim/herm

## Stack Overview

| Layer | Tool | Role |
|-------|------|------|
| **Multiplexer** | **zellij** | Sessions, panes, tabs, layouts, WASM plugins, web client |
| **Editor** | **Neovim** | Modal editing, LSP, Treesitter, Lua plugins |
| **Hermes Dashboard** | **herm** | Hermes Agent TUI (chat, tools, sessions, config) |
| **File Manager** | **yazi** | Async, image previews, vim keys |
| **Git TUI** | **lazygit** | Staging, rebasing, diffs, logs |
| **Process Monitor** | **btop** | GPU graphs, mouse-friendly |
| **Fuzzy Finder** | **fzf** | Universal fuzzy search |
| **Search** | **ripgrep (rg)** | Instant code search |
| **Docker** | **lazydocker** | Container management |
| **HTTP/API** | **httpie + jless** | API testing + JSON exploration (jless: no Windows binary yet) |
| **Database** | **dadbod-ui / nvim-dbee + sqls** | SQL in Neovim |
| **Markdown** | **glow / mdcat / render-markdown.nvim** | Preview + inline render |
| **Secrets** | **sops + age** | Encrypted secrets in git |
| **Dotfiles** | **chezmoi** | Cross-machine config management |
| **AI Coding** | **claude-code / aider / avante.nvim / crush** | AI pair programming |
| **Formatter** | **conform.nvim** | Auto-formatting on save |
| **File Navigator** | **oil.nvim** | Edit filesystem like a buffer |

**Sources:**
- https://github.com/burntsushi/ripgrep
- https://github.com/junegunn/fzf
- https://github.com/junegunn/fzf.vim
- https://github.com/zellij-org/zellij
- https://github.com/neovim/neovim
- https://github.com/liftaris/herm
- https://github.com/sxyazi/yazi
- https://github.com/jesseduffield/lazygit
- https://github.com/aristocratos/btop
- https://github.com/jesseduffield/lazydocker
- https://github.com/acheong08/httpie
- https://github.com/PaulJulien/jless
- https://github.com/charmbracelet/crush

## Installation Phases (Native Windows)

For Windows hosts (no WSL required), use winget for system packages:

```bash
# Core tools
winget install Neovim.Neovim          # → C:\Program Files\Neovim\bin\nvim.exe
winget install SQLite.SQLite          # → sqlite3.exe on user PATH
# zellij: download native Windows binary from GitHub releases
# herm: already installed via bun → ~/.bun/bin/herm.exe

# Neovim config location on Windows:
#   C:\Users\<user>\AppData\Local\nvim\init.lua
# Zellij config location on Windows:
#   C:\Users\<user>\AppData\Roaming\Zellij\config\config.kdl
#   C:\Users\<user>\AppData\Roaming\Zellij\config\layouts\<name>.kdl
```

See `references/windows-native-setup.md` for full Windows setup including dadbod/SQLite configuration, the headless testing pitfall, headless Mason LSP installation (package name mapping, gopls/Go skip), treesitter compilation, clipboard fix, PATH reconstruction, and zellij layout. See `references/windows-cli-tools.md` for the complete winget + scoop installation guide (exact package IDs, gotchas like btop4win.exe / HTTPie GUI-vs-CLI / jless no-Windows). See `templates/dev.kdl` for a ready-to-use zellij layout with nvim (65%) + herm (35%) split. See `templates/init.lua` for a complete tested 38-plugin Neovim config (LSP, Telescope, Treesitter, Git, Markdown, DB, UI, formatting, navigation).

## Installation Phases (WSL Ubuntu)

### Phase 1: Core Tools
```bash
# Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# Go (for lazygit, lazydocker)
wget https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.zshrc

# Core CLIs
cargo install --locked zellij yazi-fm yazi-cli btop ripgrep fzf jless glow mdcat
go install github.com/jesseduffield/lazygit@latest
go install github.com/jesseduffield/lazydocker@latest

# Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo tar -C /opt -xzf nvim-linux64.tar.gz
echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >> ~/.zshrc

# Clipboard (WSL)
sudo apt update && sudo apt install -y win32yank
```

### Phase 2: Herm (Hermes Dashboard)
```bash
# Build from source (current)
git clone https://github.com/liftaris/herm
cd herm
cargo build --release
cp target/release/herm ~/.cargo/bin/
```

### Phase 3: Neovim Config (lazy.nvim)
Bootstrap `~/.config/nvim/init.lua` with lazy.nvim and plugins from `references/neovim-plugins.md`.

### Phase 4: Zellij Config
Create `~/.config/zellij/config.kdl` with keybindings, theme, default layout. See `references/zellij-config.kdl`.

### Phase 5: Shell Config (zsh)
Install oh-my-zsh or minimal config with aliases, fzf integration, direnv.

## Database UI Decision Framework

Three approaches - choose based on priority:

| Priority | Stack | Trade-offs |
|----------|-------|------------|
| **Stability + features** | **dadbod-ui + sqls** ⭐ **DEFAULT** | Proven, complete DB support, requires CLI tools (psql, mysql, sqlite3) |
| **Modern + self-contained** | **nvim-dbee + sqls** | No CLI deps, Go backend, alpha (breaking changes) |
| **Minimal + LSP-only** | **sqls + dadbod (core)** | Lightest, no visual schema browser |

**For "speed and performance most of all"**: nvim-dbee + sqls (Go backend = fast, no CLI spawn overhead).
**For production reliability (current default)**: **dadbod-ui + sqls** — user explicitly chose Approach 1.

See `references/database-ui-comparison.md` for full comparison with complete lazy.nvim configs for both approaches.

## Windows-Specific Pitfalls & Fixes

### 📋 Windows Clipboard (No win32yank Needed)

Neovim on native Windows **cannot use `unnamedplus`** without a clipboard tool.
Do NOT install win32yank — use the built-in Windows providers instead:

```lua
vim.g.clipboard = {
  name = "Windows",
  copy  = { ["+"] = "clip.exe",                               ["*"] = "clip.exe" },
  paste = { ["+"] = "powershell.exe -NoProfile -Command Get-Clipboard -Raw",
            ["*"] = "powershell.exe -NoProfile -Command Get-Clipboard -Raw" },
  cache_enabled = 0,
}
```

This delegates yank to `clip.exe` (stdin→clipboard) and paste to
`powershell Get-Clipboard` (clipboard→stdout). No third-party tools needed.

### 🔧 Treesitter Parser Compilation on Windows

Treesitter parsers need a C compiler. On Windows, `tree-sitter` defaults to `cl.exe`
(MSVC), which requires Visual Studio Build Tools (~7GB). **Use MinGW-w64 GCC instead:**

```bash
# Install MinGW-w64 GCC via winget
winget install BrechtSanders.WinLibs.POSIX.UCRT

# In init.lua, tell nvim-treesitter to use gcc:
vim.env.CC = "gcc"
```

Set `vim.env.CC = "gcc"` **before** nvim-treesitter loads so all `:TSInstall`
commands compile with GCC instead of searching for `cl.exe`. Verified working
with Neovim 0.12.2 + tree-sitter 0.26.9.

**Bonus:** MinGW also ships `cmake` and `mingw32-make` in the same `bin/` directory
— no separate installation needed for tools that need a C build system (e.g.
telescope-fzf-native, see section below).

See `references/windows-native-setup.md` for a full guide including all 16 parsers.

### 🧩 Windows PATH Reconstruction from Registry

Winget adds package directories to the Windows User PATH, but child processes
**inherit the PATH from when their parent shell started** — so a PowerShell/cmd
opened before the install won't see new tools.

To run nvim with an up-to-date PATH without restarting the shell:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User")
nvim --headless "+TSUpdateSync all" "+qa"
```

This rebuilds PATH from the registry, picking up all newly-installed winget
tools. Use this pattern when running Neovim headless commands after a winget
install in the same session.

### 🧩 QoL Plugin Suite (Added 2026-06-19)

Eight quality-of-life plugins enhance the stock 30-plugin config. See `templates/init.lua`:

| Plugin | Purpose | Key binding |
|--------|---------|-------------|
| **nvim-autopairs** | Auto-close brackets, quotes, HTML tags | Automatic |
| **Comment.nvim** | Toggle line/block comments | `gcc` (line), `gbc` (block) |
| **nvim-surround** | Add/change/delete surroundings | `ysiw"`, `cs"'`, `ds"` |
| **indent-blankline** | Visual indent guides + scope | Automatic |
| **conform.nvim** | Format on save (lsp_fallback) | `<leader>f` format buffer |
| **todo-comments** | Highlight TODO/FIXME/HACK/NOTE keywords | `]t` / `[t` navigate |
| **trouble.nvim** | Diagnostics list in a side panel | `<leader>xx` toggle |
| **oil.nvim** | Edit directory as a buffer | `<leader>-` open parent |

### 🐚 Shell Aliases (.bashrc)

The `.bashrc` at `~/.bashrc` provides quick-launch aliases and fzf integration.
Sourced automatically by `~/.bash_profile`.

**Shell Aliases from .bashrc:**
```
v / vi → nvim         z → zellij        zd → zellij --layout dev
lg → lazygit          y → yazi          ld → lazydocker
d → delta             http → httpie     fgl → fuzzy git log (copy SHA to clipboard)
```

**Custom functions:**
- `fg <term>` — fuzzy grep file contents via ripgrep, fuzzy-find via fzf, open in nvim on Enter.
- `fgl` — fuzzy git log browser: pick a commit, SHA copied to clipboard via clip.exe.
- `cheatsheet` — prints a quick-reference box of all aliases/shortcuts to terminal.

**PS1:** Clean prompt with git branch indicator (colored for TUI, plain inside neovim terminals via `$NVIM` guard).

**Implementation:** See `references/msys2-shell-setup.md` for the full `.bashrc` content and installation steps.

### 🔮 FZF + fd on MSYS2 (Critical Windows Pitfall)

**Problem:** On MSYS2/git-bash, fzf's default file-scanning command uses `find`,
which traverses the ENTIRE C: drive. Sourcing `fzf/key-bindings.bash` triggers
this immediately, causing a multi-minute hang before the shell prompt appears.

**Fix:** Install `fd` (fast alternative to find) and set `FZF_DEFAULT_COMMAND`
BEFORE sourcing the fzf key-bindings:

```bash
# Install fd via winget
winget install sharkdp.fd

# In .bashrc, BEFORE sourcing fzf key-bindings:
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
```

**Additional:** fzf shell integration scripts (`key-bindings.bash`, `completion.bash`)
are NOT shipped by the winget fzf package. Download them separately:

```bash
curl -sL -o ~/.fzf.key-bindings.bash \
  https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.bash
curl -sL -o ~/.fzf.completion.bash \
  https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.bash
```

Then source both in `.bashrc`. Created: `~/.fzf.key-bindings.bash`, `~/.fzf.completion.bash`.

**fd path on Windows:** fd installs to a versioned subdirectory under WinGet packages.
The `.bashrc` must add it explicitly:
```bash
FD_DIR="/c/Users/<user>/AppData/Local/Microsoft/WinGet/Packages/sharkdp.fd_.../fd-v<x.y.z>-x86_64-pc-windows-msvc"
export PATH="$FD_DIR:$PATH"
```

### ⌨️ Ctrl+Z Closes Zellij on MSYS2/git-bash (EOF Trap)

**Problem:** On MSYS2/git-bash, Ctrl+Z sends **EOF** (DOS legacy). At a bash prompt inside a zellij pane, this causes bash to exit → pane closes → session gone.

**Fix — bind Ctrl+Z in zellij to consume the keypress:**
```kdl
bind "Ctrl z" { SwitchToMode "normal"; }
```
Add to `shared_except "locked"` in config.kdl. Switches to normal mode (no-op) and prevents the keypress from reaching the terminal.

**Trade-off:** Lose Ctrl+Z for suspending foreground processes (neovim). On this stack, `Alt+n` (new pane) replaces that pattern, so the loss is negligible.

**Alternative (bash-level, preserves suspend):** `set -o ignoreeof` — but requires 10 consecutive EOF chars to actually exit bash. Not recommended for this stack.

### 🪟 Zellij Layout — Full Paths Required on Native Windows

**Problem:** On native Windows, zellij creates new panes via the Windows subsystem,
not via MSYS bash. A pane command like `command="nvim"` fails with
"Command not found" because the Windows PATH doesn't include MSYS bash's PATH.

**Fix:** Use absolute (forward-slash) paths in `.kdl` layout files:

```kdl
pane name="editor" size="65%" command="C:/Program Files/Neovim/bin/nvim.exe"
pane name="hermes" command="~/AppData/Local/hermes/.bun/bin/herm.exe"
```

Windows happily accepts forward slashes in executable paths. Do NOT use
backslashes — KDL interprets `\` as an escape character.

**To avoid repeating absolute paths across layouts,** use a shell wrapper script
as the pane command instead, or accept the hardcoded path per-layout.

### 🩺 telescope-fzf-native Build on Windows (MinGW + cmake)

**What it is:** telescope-fzf-native accelerates Telescope file searching (fzf
sorting) via a compiled C extension. Without it, Telescope falls back to
pure-Lua emulation — functional but noticeably slower on large file trees.

**Prerequisites (already satisfied if MinGW was installed per section above):**
- MinGW-w64 GCC (provides `gcc`, `cmake`, `mingw32-make`)
- The MinGW `bin/` directory must be on PATH

**Build steps:**

```bash
# cd into the lazy-managed plugin directory
cd ~/AppData/Local/nvim-data/lazy/telescope-fzf-native.nvim

# Build with mingw32-make (NOT make — mingw32-make is the MinGW name)
# Uses the bundled CMakeLists.txt / Makefile which compiles libfzf.dll
mingw32-make

# Verify the output
ls -la build/
# Should show: -rwxr-xr-x  ...  libfzf.dll  (~68KB)
```

**Verification in Neovim:**
```lua
:lua local t = require("telescope"); print(t.extensions.fzf)
-- Should output: "table" (not nil)
```

**Detection via lazy.nvim:** The telescope-fzf-native plugin spec should use
`build = "mingw32-make"` on Windows (or handle both `make` and `mingw32-make`).
The lazy.nvim `build` command runs only on fresh install/update, not every sync.

**Troubleshooting:**
| Symptom | Cause | Fix |
|---------|-------|-----|
| `libfzf.dll not found` after install | Build didn't run | `nvim --headless "+Lazy build telescope-fzf-native.nvim" "+qa"` |
| `'mingw32-make' not found` | MinGW not on PATH | Add MinGW `bin/` to PATH; verify with `which mingw32-make` |
| `'gcc' not found` during build | MinGW not on system PATH | Re-install or verify PATH entry in .bashrc |

## Remote Access via Tailscale

### Terminal Emulator Recommendation: **kitty** (over ghostty)

| Factor | Ghostty | Kitty |
|--------|---------|-------|
| **Windows support** | ❌ None (Mac/Linux only) | ✅ Native Windows + WSL |
| **GPU acceleration** | ✅ | ✅ |
| **Ligatures** | ✅ | ✅ |
| **Kittens/extensions** | ❌ | ✅ (ssh, diff, icat, hints) |
| **Config** | Single file | Single file + kittens |

**Ghostty not an option on Windows yet** — track: github.com/ghostty-org/ghostty/issues/1339

### Option A: Zellij Web Client (browser-based)
```bash
# Zellij config: web_server true, web_server_ip "0.0.0.0", SSL certs
# Expose via Tailscale:
tailscale serve --https=443 /zellij=http://localhost:8082
# Phone: open https://<machine>.tailnet.ts.net/zellij
```

### Option B: SSH + Mosh (native terminal app - recommended for coding)
```bash
# WSL: sudo apt install openssh-server mosh
# Tailscale SSH: tailscale ssh <machine>
# Phone: zellij attach
```

### Phone Clients — Deep Comparison

| Feature | **Blink Shell (iOS)** | **Termius (iOS/Android)** | **Prompt 3 (iOS)** | **Termux (Android)** | **JuiceSSH (Android)** |
|---------|----------------------|---------------------------|-------------------|----------------------|------------------------|
| **Mosh** | ✅ Native, first-class | ✅ Native | ✅ Native | ✅ `pkg install mosh` | ✅ Plugin |
| **Background** | ✅ Always On mode | ⚠️ Limited (iOS) | ⚠️ Limited (iOS) | ✅ **Full background** | ⚠️ Limited |
| **Price** | $19.99 once | Free / $12/mo Pro | $9.99 once | **Free (F-Droid)** | Free / $9.99 Pro |
| **Sync** | iCloud (settings) | **Full cloud sync (Pro)** | iCloud | Manual (GitHub/dotfiles) | Google Drive (Pro) |
| **Scripting** | Lua (limited) | Snippets (Pro) | Limited | **Full shell (bash/zsh/fish)** | Limited |
| **Termux API** | ❌ | ❌ | ❌ | ✅ Notifications, GPS, sensors | ❌ |
| **Best For** | **iOS power users, Mosh + background** | Teams, cross-platform sync | iPad + hardware keyboard | **Android power users, full Linux** | Quick SSH, widgets |

### Option C: Hermes Gateway API (for AI apps on phone)
```bash
tailscale serve --https=443 /hermes=http://localhost:8319
# Phone: any OpenAI-compatible client -> https://<machine>.tailnet.ts.net/hermes/v1/chat/completions
```

See `references/tailscale-remote-access.md` for diagrams and setup details.

## ⚠️ Keybinding Reference — Custom Config (clear-defaults=true)

**user's zellij config uses `clear-defaults=true` with mode-based prefixes, NOT the default single-prefix system.** Always load and check the actual `config.kdl` before documenting bindings.

### Mode Switching (from any mode)

| Trigger | Mode | Purpose |
|---------|------|---------|
| `Ctrl + p` | **Pane** | Split, close, move, resize panes |
| `Ctrl + t` | **Tab** | Create, close, switch tabs |
| `Ctrl + s` | **Scroll** | Scroll pane history, search |
| `Ctrl + o` | **Session** | List/attach sessions, share, settings |
| `Ctrl + n` | **Resize** | Resize panes |
| `Ctrl + h` | **Move** | Move panes to different positions |
| `Ctrl + b` | **Tmux** | Tmux-style keybindings (compatibility) |
| `Ctrl + g` | **Lock** | Lock keyboard input |

### Alt Shortcuts (work from any unlocked mode)

| Shortcut | Action |
|----------|--------|
| `Alt + h/l` | Move focus left/right (or switch tabs at edges) |
| `Alt + j/k` | Move focus down/up |
| `Alt + n` | New pane (split) |
| `Alt + f` | Toggle floating panes |
| `Alt + + / -` | Resize / Decrease |
| `Alt + [` / `]` | Previous / next swap layout |
| `Alt + i` / `Alt + o` | Move tab left / right |
| `Ctrl + q` | Quit zellij entirely |

### Pane Mode (Ctrl + p)

| Key | Action |
|-----|--------|
| `h/j/k/l` or arrows | Move focus |
| `r` | Split right |
| `d` | Split down |
| `n` | Split default |
| `s` | Stacked pane |
| `x` | Close pane |
| `f` | Toggle fullscreen |
| `p` | Next pane |
| `c` | Rename pane |
| `e` | Toggle embed/floating |
| `i` | Toggle pin |
| `w` | Toggle floating |
| `z` | Toggle pane frames |

### Tab Mode (Ctrl + t)

| Key | Action |
|-----|--------|
| `h/j/k/l` or arrows | Switch tabs |
| `n` | New tab |
| `x` | Close tab |
| `1`–`9` | Go to tab by number |
| `r` | Rename tab |
| `b` | Break pane to tab |
| `[` / `]` | Break left / right |
| `s` | Toggle sync |
| `tab` | Toggle last tab |

### Resize Mode (Ctrl + n)

| Key | Action |
|-----|--------|
| `h/j/k/l` or arrows | Resize direction |
| `+` / `-` / `=` | Increase / Decrease |
| `H/J/K/L` (shift) | Decrease direction |

### Scroll Mode (Ctrl + s)

| Key | Action |
|-----|--------|
| `j/k` or arrows | Scroll line |
| `u/d` | Half page |
| `Ctrl + b/f` | Page |
| `s` | Search mode |
| `e` | Edit scrollback |

### Session Mode (Ctrl + o)

| Key | Action |
|-----|--------|
| `s` | Session manager |
| `w` | List sessions |
| `l` | Layout manager |
| `c` | Configuration |
| `p` | Plugin manager |
| `a` | About |
| `d` | Detach |

See `references/zellij-keybindings.md` for the full keybinding matrix from the actual `config.kdl`.

### Neovim (leader: Space)
| Key | Action |
|-----|--------|
| ff | Find files (Telescope) |
| fg | Live grep (rg) |
| fb | Buffers |
| fh | Help tags |
| gg | LazyGit |
| gd | Go to definition (LSP) |
| K | Hover documentation |
| leader e | Yazi file manager |
| leader D | Toggle DB UI |
| leader xx | Toggle diagnostics |
| leader xq | Toggle quickfix |
| leader ca | Code action |
| leader cf | Format buffer |
| - | Open Oil (parent dir) |

## Tracking Board (in wiki)

wiki page: `pending/ai-terminal-stack.md` - update checkboxes as phases complete.

### Immediate
- [x] Install Neovim (winget on native Windows) ✅
- [x] Install zellij (native Windows binary) ✅
- [x] herm already installed (~/.bun/bin/herm) ✅
- [x] Bootstrap Neovim config with lazy.nvim ✅
- [x] Create zellij layout (nvim + herm split) — `templates/dev.kdl` ✅
- [x] Test full stack: `zellij --layout dev` launches both panes ✅

### Short-term
- [x] Configure LSP servers via Mason (lua, pyright, rust_analyzer, ts_ls, bashls, yamlls, jsonls, sqls, marksman) ✅ — gopls skipped (no Go installed)
- [x] Set up Telescope with fzf-native (native libfzf.dll built successfully with MinGW cmake + mingw32-make, extension loaded as table) ✅
- [x] Configure database UI (dadbod-ui + SQLite on native Windows) ✅
- [x] Install full CLI tool suite via winget + scoop (lazygit, fzf, btop, delta, lazydocker, glow, httpie, chezmoi, age, yazi, sops, mdcat) ✅
- [x] Configure delta as git pager (side-by-side, navigate, diff3 conflict style) ✅
- [x] Create how-to guide at `~/ai-terminal-stack-guide.md` (12 sections, 1,104 lines, 37KB) ✅

### How-To Guide Maintenance — Pitfalls
When updating the user-facing guide (`~/ai-terminal-stack-guide.md`), always **verify every claim against live config files** before writing. The old guide was generated from session memory and had three factual errors discovered during audit:
1. **Zellij keybindings** — old guide claimed default single-prefix. user's actual config has `clear-defaults=true` with mode-based prefixes. Read `config.kdl` directly.
2. **Plugin count** — old guide said 30. Actual plugin count is 39 (`ls ~/AppData/Local/nvim-data/lazy/ | wc -l`).
3. **LSP count** — old guide undercounted. Run `ls ~/AppData/Local/nvim-data/mason/bin/` for the actual list.

**Workflow for guide updates:**
1. Read the current guide
2. Read ALL live configs (init.lua, config.kdl, layout kdls)
3. `which <tool>` to verify each tool is actually on PATH
4. `ls` the lazy/ directory for real plugin count
5. `ls` the mason/bin/ directory for real LSP list
6. Write with architecture section first, then verified details
7. Cross-check every keybinding table against raw config.kdl
- [x] Fix Windows clipboard (clip.exe + PowerShell provider, not win32yank) ✅
- [x] Install MinGW-w64 GCC for treesitter parser compilation ✅
- [x] Install all 16 treesitter parsers (lua, vim, vimdoc, bash, python, javascript, typescript, go, rust, sql, markdown, yaml, json, markdown_inline, ecma, jsx) ✅
- [x] Add 8 QoL plugins to init.lua (autopairs, comment, surround, indent-blankline, conform, todo-comments, trouble, oil) ✅
- [ ] Set up avante.nvim or claude-code
- [ ] Create project-specific zellij layouts

### Ongoing
- [ ] Dotfiles management with chezmoi
- [ ] Secrets management with sops+age
- [ ] Benchmark startup time (target: <50ms)

## References
- `references/windows-cli-tools.md` - Windows CLI tool installation via winget + scoop (exact package IDs, gotchas, batch commands)
- `references/neovim-plugins.md` - Complete lazy.nvim plugin spec
- `references/zellij-config.kdl` - Starter zellij configuration
- `references/zellij-keybindings.md` - Full custom keybinding matrix (verified from config.kdl 2026-06-19)
- `references/verified-stack-manifest.md` - Single source of truth for user's actual installed state (plugins, LSPs, CLI tools, git config)
- `references/database-ui-comparison.md` - dadbod-ui vs nvim-dbee vs sqls (with full configs)
- `references/windows-native-setup.md` - Native Windows install (winget), dadbod/SQLite config, headless testing pitfall, treesitter compilation, clipboard fix, PATH reconstruction
- `references/msys2-shell-setup.md` - .bashrc, aliases, fzf+fd on MSYS2, shell functions, MSYS2-specific PATH quirks
- `references/telescope-fzf-native-build.md` - Build log and verification for native Telescope fzf acceleration on Windows (MinGW cmake + mingw32-make)
- `references/tailscale-remote-access.md` - Tailscale + SSH/Mosh/Web Client/Gateway setup (4 methods, mobile clients deep comparison)
- `references/stack-decision-log.md` - Why zellij over tmux, Neovim over VS Code, etc.
- `references/discord-vs-stack-comparison.md` - Discord + Hermes vs local stack trade-offs
- `references/minimal-ai-terminal-stacks.md` - 8-stack comparison (zellij, tmux, wezterm, ghostty, Zed, VS Code, kitty) with crush integration
- `templates/dev.kdl` - Zellij layout: nvim (left 65%) + herm (right 35%) split
- `templates/init.lua` - Complete tested 38-plugin Neovim config (LSP, Telescope, Treesitter, Git, Markdown, DB, UI, formatting, navigation)

## Related Skills
- `hermes-agent` - Hermes configuration, gateway, dashboard
- `software-development/local-llm-setup` - Local LLM inference for AI coding
- `software-development/plan` - Planning methodology for multi-phase setup