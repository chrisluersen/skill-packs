# Minimal AI-Friendly Terminal Stacks — Comprehensive Comparison

Research documented: 2026-06-18
Sources: This session — systematic comparison of all viable stacks

---

## Stack Categories

| Category | Stacks |
|----------|--------|
| **Multiplexer + Editor** | zellij+neovim, tmux+neovim, wezterm+neovim |
| **Terminal + Built-in Mux** | wezterm (mux), ghostty (external mux), kitty (external mux) |
| **Editor Only** | neovim (:terminal), Zed, VS Code |
| **Specialized** | zellij+neovim+herm (Hermes-native) |

---

## Full Comparison Matrix

| Stack | Binaries | Config Files | Persistence | AI Integration | Performance | Learning Curve | Mobile/Remote |
|-------|----------|--------------|-------------|----------------|-------------|----------------|---------------|
| **1. zellij + neovim + herm** | 3 | 3 | ✅ Full (sessions) | herm + crush + any CLI agent | Excellent (Rust) | Medium | SSH/Mosh + web client |
| **2. tmux + neovim** | 2 | 2 | ✅ Full (sessions) | crush + any CLI agent | Good (C) | Medium-High | SSH/Mosh (universal) |
| **3. wezterm + neovim** | **2** | 2 | ✅ Workspaces | crush + any CLI agent | **Best** (GPU, Rust) | Low-Medium | **Built-in SSH client** |
| **4. ghostty + tmux/zellij + neovim** | 3 | 3 | Via mux | crush + any CLI agent | **Fastest terminal** (Zig) | Medium | SSH + mux |
| **5. kitty + tmux/zellij + neovim** | 3 | 3 | Via mux | crush + any CLI agent | Excellent (GPU) | Medium | SSH + mux |
| **6. Zed only** | 1 | 1 (JSON) | ⚠️ Limited | Built-in AI, MCP | Excellent (Rust, GPU) | Low | SSH (limited) |
| **7. VS Code only** | 1 | 1 (JSON) | ⚠️ Limited | Copilot, extensions | Good (Electron) | Low | VS Code Web/Tunnel |
| **8. neovim only** | **1** | 1 | ❌ None | crush in :term splits | Excellent | Low (if vim) | SSH + nvim |

---

## Ranked by Priority

| Priority | Winner | Why |
|----------|--------|-----|
| **Absolute minimum binaries** | **wezterm + neovim** | 2 binaries (terminal+mux + editor) |
| **Absolute minimum config** | **ghostty + tmux + neovim** | Ghostty: near-zero config; tmux: one file |
| **Maximum AI integration** | **zellij + neovim + herm + agents** | Herm for Hermes, pane-per-agent |
| **Best mobile/remote** | **wezterm + neovim** or **tmux + neovim** | wezterm: built-in SSH; tmux: universal |
| **Best raw performance** | **ghostty + zellij + neovim** | Fastest terminal + fast mux + fast editor |
| **Hermes-native** | **zellij + neovim + herm** | Purpose-built for Hermes |
| **Future-proof/standard** | **tmux + neovim** | Will work 20 years from now |

---

## Deep Dive: Each Stack

---

### 1. zellij + neovim + herm ⭐ **Your Choice**

```bash
# Install
cargo install --locked zellij yazi-fm btop ripgrep fzf
# + neovim, herm, go tools (lazygit, lazydocker)
```

| Aspect | Detail |
|--------|--------|
| **Philosophy** | Rust-native, batteries-included, WASM plugins |
| **Sessions** | Persistent, named, searchable, layout-per-project |
| **AI Layout** | Tabs: [neovim+shell] [herm] [lazygit] [lazydocker] |
| **Hermes** | Native `herm` TUI — full dashboard in a pane |
| **Extensibility** | WASM plugins, KDL config, layout engine |
| **Web Client** | Built-in — `zellij --web-server` → browser access |
| **WSL** | Native Linux, best tooling |

**Best for:** Hermes power users who want full control, persistence, and Rust performance.

---

### 2. tmux + neovim — **Maximum Compatibility**

```bash
sudo apt install tmux neovim
# + AI agents: claude-code, aider, opencode, **crush**
```

| Aspect | Detail |
|--------|--------|
| **Philosophy** | Battle-tested, everywhere, scriptable |
| **Sessions** | Persistent, `tmux attach -t session` |
| **AI Layout** | Windows: [neovim] [claude-code] [aider] [herm] |
| **Config** | `.tmux.conf` — Tmux DSL (prefix + commands) |
| **Ecosystem** | **Largest** — every CI, container, SSH host has it |
| **Scripting** | `tmux send-keys`, `tmux capture-pane`, hooks |
| **Mobile** | SSH + `tmux attach` — works on any terminal app |

**Best for:** Maximum portability, CI/CD, containers, teams, "it just works everywhere."

---

### 3. wezterm + neovim — **Single Binary (Terminal + Mux)**

```bash
# Install: single binary
# Config: ~/.config/wezterm/wezterm.lua (Lua)
```

| Aspect | Detail |
|--------|--------|
| **Philosophy** | One binary: terminal + multiplexer + SSH client |
| **Config** | **Lua** — programmable, hot-reload, typed (via sumneko) |
| **Persistence** | **Workspaces** — survive restart, restore tabs/panes/cwd |
| **GPU** | **Best-in-class** — Metal/Vulkan/OpenGL, shaders, ligatures |
| **SSH** | **Built-in SSH client** — `wezterm ssh host` — multiplexes remote! |
| **Multiplexer** | Tabs, panes, workspaces, key tables, leader key |
| **AI Layout** | Tabs: [neovim] [claude-code] [aider] [shell] |
| **Cross-platform** | Identical config on Windows/Mac/Linux |

**wezterm.lua example:**
```lua
local wezterm = require 'wezterm'
return {
  leader = { key = 'a', mods = 'CTRL' },
  keys = {
    { key = 'c', mods = 'LEADER', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
    { key = 'h', mods = 'LEADER', action = wezterm.action.ActivatePaneDirection 'Left' },
    { key = 's', mods = 'LEADER', action = wezterm.action.ShowLauncherArgs { flags = 'WORKSPACES' } },
  },
  ssh_domains = { { name = 'wsl', remote_address = 'localhost' } },
  unix_domains = { { name = 'unix' } },  -- persistent daemon
}
```

**Best for:** Fewest moving parts, best rendering, built-in SSH, cross-platform identical setup.

---

### 4. ghostty + tmux/zellij + neovim — **Fastest Terminal**

| Aspect | Detail |
|--------|--------|
| **Terminal** | **Ghostty** — Zig, GPU, near-zero config |
| **Config** | `~/.config/ghostty/config` — simple key=value |
| **Mux** | External (tmux or zellij) |
| **Performance** | **Lowest latency**, fastest startup |
| **Status** | Beta (Mac/Linux), **no Windows yet** |
| **Ligatures** | Yes |
| **Config reload** | Auto |

**Best for:** Raw speed above all, minimal config, Mac/Linux primary.

---

### 5. kitty + tmux/zellij + neovim — **GPU Terminal with Kittens**

| Aspect | Detail |
|--------|--------|
| **Terminal** | **Kitty** — GPU, ligatures, kittens (extensions) |
| **Config** | `~/.config/kitty/kitty.conf` — simple key=value |
| **Mux** | External (tmux or zellij) |
| **Performance** | Excellent (GPU), fast startup |
| **Windows** | ✅ **Native support** |
| **Kittens** | `kitten ssh`, `kitten icat`, `kitten diff`, `kitten hints` |
| **Config reload** | Auto |

**Best for:** Windows + WSL, GPU rendering, kittens for SSH/images/diff, external mux.

---

### 6. Zed Only — **Editor with Built-in AI**

| Aspect | Detail |
|--------|--------|
| **Binary** | 1 (Zed) |
| **AI** | **Built-in** — Anthropic, OpenAI, local (Ollama), MCP |
| **Collaboration** | **Native multiplayer** — real-time co-editing |
| **Terminal** | Built-in (tabs, panes) — but **no persistence** |
| **Performance** | Excellent (Rust, GPU, CRDT) |
| **Config** | JSON (`settings.json`) |
| **Extensions** | Growing ecosystem (WASM) |
| **Mobile** | **Zed Preview** (iOS TestFlight) — limited |

**Best for:** Collaborative editing, want AI built-in, don't need session persistence.

---

### 7. VS Code Only — **Maximum Ecosystem**

| Aspect | Detail |
|--------|--------|
| **Binary** | 1 (VS Code) |
| **AI** | Copilot, extensions (Cline, Roo, Continue, etc.) |
| **Terminal** | Built-in — **no persistence** |
| **Remote** | **SSH, Containers, WSL, Tunnels, Web** — best in class |
| **Extensions** | **Largest** marketplace |
| **Config** | JSON (`settings.json`) + profiles |
| **Performance** | Good (Electron, improving) |

**Best for:** Maximum extensions, remote development, team standardization, GUI preference.

---

## AI Agent Integration (All Stacks)

### Pane-per-Agent Pattern (zellij/tmux/wezterm)

```kdl
# zellij layout
layout {
  ai-tab {
    pane name="editor" command="nvim"
    pane name="claude" command="claude-code" focus=false
    pane name="aider" command="aider" focus=false
    pane name="opencode" command="opencode" focus=false
    pane name="herm" command="herm" focus=false
    pane name="crush" command="crush" focus=false
  }
}
```

```lua
-- wezterm: same concept via keybindings
-- tmux: separate windows
```

### Neovim :terminal Pattern (Any Stack)

```vim
" Keymaps (works in any stack)
nnoremap <leader>ac :term claude-code<CR>
nnoremap <leader>aa :term aider<CR>
nnoremap <leader>ao :term opencode<CR>
nnoremap <leader>ah :tabnew\|term herm<CR>
nnoremap <leader>cz :term crush<CR>
```

### In-Editor AI (Stack-Independent)

| Plugin | Integration | Best For |
|--------|-------------|----------|
| **avante.nvim** | Inline diff, chat in buffer | Never leave neovim |
| **copilot.vim** | Inline suggestions | Passive completion |
| **codecompanion.nvim** | Chat buffer, tools | Structured AI workflows |
| **supermaven-nvim** | Fast inline completion | Speed |

### Terminal-Native AI Agents (Stack-Independent)

| Agent | Language | Model Support | Key Feature | Install |
|-------|----------|---------------|-------------|---------|
| **claude-code** | TypeScript | Anthropic (Claude) | Official Anthropic, filesystem tools | `npm i -g @anthropic-ai/claude-code` |
| **aider** | Python | Any (OpenAI, Anthropic, Ollama, etc.) | Git-native, diff-based edits | `pip install aider-chat` |
| **opencode** | Go | OpenAI, Anthropic, Ollama, LM Studio | Minimal, scriptable, headless | `go install github.com/sst/opencode@latest` |
| **crush 💘** | **Go (Charm)** | **OpenAI, Anthropic, Ollama, LM Studio, LiteLLM, OpenRouter** | **Beautiful TUI (bubbletea/lipgloss), local-first, auto Ollama discovery** | `go install github.com/charmbracelet/crush@latest` |

**All four run in any terminal pane** — zellij/tmux/wezterm/neovim :term — giving you the "pane-per-agent" pattern regardless of stack.

---

## Mobile/Remote by Stack

| Stack | Best Mobile Access | Fallback |
|-------|-------------------|----------|
| **zellij + neovim** | SSH/Mosh + `zellij attach` \| Zellij web client | Hermes Gateway/Dashboard |
| **tmux + neovim** | SSH/Mosh + `tmux attach` | VS Code Tunnel |
| **wezterm + neovim** | **Built-in SSH** (`wezterm ssh host`) \| SSH/Mosh | Zellij web client (if added) |
| **ghostty + mux** | SSH/Mosh + mux attach | — |
| **kitty + mux** | SSH/Mosh + mux attach | — |
| **Zed** | Zed Preview (iOS) \| SSH + Zed CLI | VS Code Web |
| **VS Code** | **VS Code Web / Tunnel** (best) | SSH + CLI |

---

## Decision Flowchart

```
START: What's your #1 priority?
│
├─→ Fewest binaries → wezterm + neovim (2)
│
├─→ Zero config → ghostty + tmux + neovim
│
├─→ Maximum AI integration → zellij + neovim + herm
│
├─→ Best mobile → wezterm (built-in SSH) or tmux (universal)
│
├─→ Best performance → ghostty + zellij + neovim
│
├─→ Hermes-native → zellij + neovim + herm ⭐
│
├─→ Future-proof → tmux + neovim
│
├─→ Collaboration → Zed (multiplayer) or VS Code (Live Share)
│
└→ Maximum ecosystem → VS Code
```

---

## Recommendation for Your Context

**You chose: zellij + neovim + herm**

This is the **optimal choice** for:
- ✅ Hermes user (native `herm` TUI)
- ✅ Windows + WSL (Linux-native tooling)
- ✅ Speed/performance focus (Rust stack)
- ✅ Session persistence (zellij sessions)
- ✅ Mobile via Tailscale (SSH/Mosh + web client)
- ✅ Project layouts (AI pane arrangements)
- ✅ **Terminal: kitty** (Windows native, GPU, kittens)

**Only consider switching if:**
- You want **one less binary** → wezterm + neovim (adds built-in SSH)
- You need **maximum compatibility** → tmux + neovim (works everywhere)
- You want **zero config terminal** → ghostty + tmux (but no Windows yet)

---

## Related Pages

- `ai-terminal-stack` — Your chosen stack implementation
- `ai-terminal-stack-remote-access` — Mobile via Tailscale
- `discord-vs-stack-comparison` — Discord + Hermes vs local stack
- `neovim-database-ui-options` — Database UI deep dive

---

## Tags

`#terminal-stack` `#comparison` `#zellij` `#tmux` `#wezterm` `#neovim` `#ai-coding` `#multiplexer` `#minimalism` `#crush` `#kitty`