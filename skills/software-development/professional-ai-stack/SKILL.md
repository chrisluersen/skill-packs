---
name: professional-ai-stack
description: Assess a user's hardware and OS, then build a verified professional AI engineering tool stack recommendation with honest cross-platform compatibility and honest tradeoffs.
version: 1.0.0
author: Hermes Agent
metadata:
  hermes:
    tags: [stack, environment, setup, windows, linux, cuda, gpu, tools, ai-engineering, professional]
created_from_user_sessions: true
---

# Professional AI Engineering Stack Assessment

When a user asks "what tools should I use?" or "build me an AI engineering setup" — especially when they say they want the endgame/professional level, not tutorials — follow this methodology.

## When to Use

- User asks for tool/stack recommendations for AI engineering
- User wants a development environment setup plan
- User says "I don't want beginner setup, I want the real/professional/endgame stack"
- User shares their hardware specs and asks what they can run
- User is choosing between editors, frameworks, or serving tools

## The Methodology

### Step 1: Hardware & Environment Assessment

Gather these facts about the user's machine before making any recommendation:

```bash
# GPU (critical for ML)
nvidia-smi                          # GPU model, VRAM, driver version, CUDA version

# Python toolchain
python --version
uv --version                        # modern package manager (preferred over pip)
pip --version                       # fallback

# Installed tools (check relevance)
which ollama docker git code gh     # common AI tools
which npx                           # Node tooling

# System resources
free -h                             # RAM (Linux/WSL)
df -h /                             # Disk space
```

**Key things to note from nvidia-smi:**
- **GPU architecture**: Turing (RTX 20xx, 3060), Ampere (RTX 30xx), Ada Lovelace (RTX 40xx), Blackwell (RTX 50xx) — affects CUDA compatibility and attention optimization support
- **VRAM**: 8GB = can fine-tune 7B models with QLoRA, 12GB = 13B, 24GB = 34B. Be honest about the ceiling.
- **CUDA version in driver**: e.g. 13.2 — this dictates whether the user needs PyTorch nightly (cu132) or stable (cu130/126)
- **WDDM vs TCC driver model**: WDDM (default on Windows) adds ~500MB VRAM overhead vs TCC on Linux

### Step 2: Verify Tool Compatibility on Their OS

**Do not assume** a tool works on Windows. Verify each one. For each major tool in your recommendation, check:

| Check | How |
|---|---|
| Official docs | Look for Windows install instructions |
| PyPI package | Does `pip install <tool>` work on Windows? |
| GitHub issues | Search "windows support" in the repo |
| GitHub discussions | "Does X support windows?" threads |
| Recent PRs | Any recent Windows support PRs? |

**Known Windows quirks (as of mid-2026):**

| Tool | Windows Status |
|---|---|
| **PyTorch** | Full support (stable CUDA 13.0, nightly CUDA 13.2) |
| **Hugging Face Transformers** | Full support |
| **PEFT** | Full support |
| **Unsloth** | Native Windows support confirmed since 2025 |
| **llama.cpp** | Full support (winget, prebuilt binaries, or build from source) |
| **Ollama** | Full support |
| **vLLM** | Windows fork exists (SystemPanic/vllm-windows); mainline PR submitted, not yet merged |
| **SGLang** | No Windows support — needs WSL |
| **DeepSpeed** | Partial Windows support (many features work, some don't) |
| **Flash Attention 2** | Tricky on Windows — may need custom build or WSL |
| **Triton** | Linux only — needs WSL |
| **W&B** | Full support (Python SDK works everywhere) |
| **MLflow** | Full support |
| **ChromaDB** | Full support |
| **LlamaIndex / LangChain** | Full support (pure Python) |
| **BentoML** | Full support |
| **DuckDB** | Full support |

### Step 3: Hardware-Constrained Recommendations

Be honest about what the user's hardware can and cannot do. Template:

```
Your practical ceiling on this hardware:
- Fine-tuning: <X>B models via QLoRA (<Y>B full fine-tune)
- Inference: <X>B at Q4_K_M, <Y>B at Q3_K_M (slow)
- Training batch size: Small (1-<N>) for LoRA due to <Z>GB VRAM
- Everything else: Docker, RAG pipelines, API serving — runs fine
```

For reference:
- **8GB VRAM** (RTX 3060 Ti/4060 Ti): Fine-tune 7B with QLoRA, run 7B GGUF at Q4_K_M
- **12GB VRAM** (RTX 4070/3080): Fine-tune 13B with QLoRA, run 13B GGUF comfortably
- **16GB VRAM** (RTX 4080/4060 Ti 16GB): Fine-tune 34B with QLoRA
- **24GB+ VRAM** (RTX 4090/A-series): Fine-tune 70B with QLoRA, or 8B full fine-tune

### Step 4: Structure the Stack by Layer

Organize the recommendation as layers from bottom to top:

1. **Development Environment**: Terminal, editor (VS Code vs Cursor vs Copilot), AI agent (Hermes)
   - **Terminal Multiplexer Assessment**: Compare tmux vs zellij on raw performance (startup latency, memory, persistence), Windows/WSL compatibility, learning curve, and plugin ecosystem. For "speed/performance most of all" users: zellij + Neovim wins on raw metrics (<50ms startup, ~40MB RAM). For "productivity today" users: Zed wins on DX (collab, debug, Git UI, zero config).
   - **Editor Assessment**: Evaluate VS Code / Zed / Neovim on startup latency, memory, LSP/DX out of box, debugging UI, Git UI, collab editing, AI integration, and whether they run inside a multiplexer (Neovim) or standalone (VS Code, Zed). Modal editing (Neovim) has steeper curve but compounds long-term.
   - **Hermes Dashboard**: herm (liftaris/herm) is a specialized TUI for Hermes Agent — runs inside any multiplexer, not a replacement.
2. **Python Toolchain**: uv, ruff, pytest, typing
3. **Deep Learning Framework**: PyTorch + the right CUDA version
4. **Training & Fine-Tuning**: Transformers, PEFT, Unsloth, Accelerate, DeepSpeed
5. **Serving & Inference**: Ollama → llama.cpp → vLLM → SGLang (phased from "works now" to "aspirational")
6. **Data & RAG**: ChromaDB → Qdrant, LlamaIndex/LangChain, Unstructured, DuckDB
7. **MLOps**: W&B, MLflow, BentoML, Docker, GitHub Actions

### Step 4b: Recommended Terminal Stack Additions (zellij/neovim/herm)

For users choosing the zellij/neovim/herm stack, include these essential additions:

| Category | Tool | Why | Install |
|----------|------|-----|---------|
| **File Manager** | **yazi** | Best TUI file manager — async, image previews, vim keys, plugin system | `cargo install --locked yazi-fm yazi-cli` |
| **Git TUI** | **lazygit** | Standard for a reason — staging, rebasing, diffs, logs in one view | `go install github.com/jesseduffield/lazygit@latest` |
| **Process Monitor** | **btop** | Beautiful, mouse-friendly, GPU graphs, better than htop | `cargo install btop` |
| **Fuzzy Finder** | **fzf** | Powers everything — Neovim Telescope, zellij sessions, file search | `cargo install fzf` |
| **Search** | **ripgrep (rg)** | Neovim grep, instant file search | `cargo install ripgrep` |
| **Clipboard** | **wl-clipboard** / **win32yank** | System clipboard sync for Neovim/yazi | WSL: `sudo apt install win32yank` |

**Highly Recommended:**
| Category | Tool | Why |
|----------|------|-----|
| **Docker** | **lazydocker** | Manage containers/images/logs without leaving terminal |
| **HTTP/API** | **httpie** + **jless** | `http GET api/users \| jless` — JSON explore + syntax highlight |
| **Database** | **dadbod-ui** (Neovim plugin) | Query Postgres/MySQL/SQLite inside Neovim |
| **Markdown Preview** | **glow** \| **mdcat** | `glow README.md` — rendered markdown in terminal |
| **Session Persist** | **zellij-sessionizer** / `zellij attach` | Save/restore named layouts per project |
| **Secrets** | **sops** + **age** | Encrypt secrets in git, decrypt in shell |
| **Dotfiles** | **chezmoi** | Manage dotfiles across machines, templating |
| **AI Coding** | **claude-code** / **aider** / **avante.nvim** | AI pair programming in terminal |

**Neovim Plugins (lazy.nvim starter):**
```lua
-- Core
{ "folke/lazy.nvim" },                    -- Plugin manager
{ "nvim-lua/plenary.nvim" },              -- Utils

-- LSP/Completion
{ "neovim/nvim-lspconfig" },
{ "williamboman/mason.nvim" },
{ "williamboman/mason-lspconfig.nvim" },
{ "hrsh7th/nvim-cmp" },
{ "hrsh7th/cmp-nvim-lsp" },
{ "L3MON4D3/LuaSnip" },

-- Telescope (fzf-powered)
{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-telescope/telescope-fzf-native.nvim" } },

-- Treesitter (syntax)
{ "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

-- Git
{ "tpope/vim-fugitive" },
{ "lewis6991/gitsigns.nvim" },
{ "kdheepak/lazygit.nvim" },              -- :LazyGit in Neovim

-- File tree (optional — yazi handles this better)
{ "nvim-tree/nvim-tree.lua" },

-- Markdown
{ "iamcco/markdown-preview.nvim", build = "cd app && yarn install" },  -- Browser preview
{ "MeanderingProgrammer/render-markdown.nvim" },                       -- Inline render

-- Dadbod (SQL in Neovim)
{ "kristijanhusak/vim-dadbod-ui" },
{ "tpope/vim-dadbod" },

-- AI
{ "yetone/avante.nvim", build = "make" },  -- Or use claude-code externally

-- UI
{ "nvim-lualine/lualine.nvim" },
{ "folke/which-key.nvim" },
{ "folke/noice.nvim" },                    -- Better cmdline/messages
```

**Zellij Layout (one config, all projects):**
```kdl
# ~/.config/zellij/config.kdl
layout {
    default {
        pane split_direction="vertical" {
            pane size="70%" name="editor" command="nvim"
            pane size="30%" name="shell" command="zsh"
        }
        pane name="herm" command="herm" focus=false
    }
}
```

**Usage:** `zellij --layout default` → Neovim (70%), shell (30%), herm (hidden tab)

**Recommended Zellij Tab Layout per Project:**
| Tab | Panes |
|-----|-------|
| **main** | Neovim (70%) \| shell (30%) |
| **git** | lazygit (full) |
| **docker** | lazydocker (full) |
| **herm** | herm (full) |
| **db** | dadbod-ui in Neovim \| psql/mysql shell |
| **logs** | `tail -f` \| `btop` |

### Step 5: Present Honest Tradeoffs

For every decision point, give:
- **What the tool does** (one line)
- **Why it's endgame** (what makes it professional-grade)
- **Windows compatibility** (exact status, not assumed)
- **The alternative** if Windows support is lacking (WSL, fork, different tool)

### Step 6: User Preference — Professional Depth

**This user clearly stated they want the advanced/endgame answer, not tutorials.**

When the user says variations of "I don't want beginner stuff, give me the real stack":
- Skip the "what is X" explanations — assume they know the domain
- Lead with professional use cases and production patterns
- Include honest VRAM/GPU ceilings rather than pretending everything works
- Show the upgrade path (e.g., "Ollama → llama.cpp → vLLM → SGLang") rather than just the easiest option
- Include the "why this tool wins" so they understand tradeoffs, not just the name

### Step 7: Include WSL Guidance

For Windows users, always address the WSL question:

- **Tools that need WSL** (be specific: SGLang, Triton, mainline vLLM)
- **Tools that work natively** (the majority: Unsloth, Ollama, llama.cpp, HF ecosystem, ChromaDB, etc.)
- **One-liner WSL recommendation**: "Your biggest bottleneck is Windows, not your GPU."

### Step 8: Deliver as a Durable Artifact

Write the guide to a file (`.md`) so the user can reference it later. Include:
- A table of contents
- Verified install commands
- A "one-shot setup" block
- A visual stack map (ASCII art)
- A month-by-month learning path

**Format preferences (this user):**
- **Sources inline, next to the claim they support** — not in a footer or bibliography. Every quote, stat, or tool compatibility claim needs its URL right beneath it. Use `> — [@Source, Date](url)` format for quotes.
- **Chronological order** — oldest to newest. If a person's setup evolved over time, present it as a timeline, not a flat list.
- **Canonical export location** — the Obsidian vault at `~/AppData/Local/hermes/Vault/` (not home directory, not Desktop). Check for this path first on this user's machine.

## Pitfalls

- **Don't assume Linux support = Windows support.** Always verify. The vLLM and SGLang cases prove this.
- **Don't recommend CUDA 13.2 nightly unless the user specifically needs it.** The stable CUDA 13.0 build has broader package compatibility.
- **Don't oversell VRAM capacity.** 8GB is tight. The user will hit OOM errors quickly. Be upfront.
- **Don't recommend tools that don't serve the user's stated goal.** If they said "endgame," don't waste time on beginner notebooks.
- **Don't mention the Hermes subscription unprompted.** The persona instructions already cover this — only bring it up if the user asks or it directly solves a missing capability.
- **Don't promise things haven't verified.** Always do the web research before stating a tool works or doesn't work on a given platform.

### Step 9: Research What Specific Leaders in the Field Use

When the user asks "what does X person/company use?" — don't guess. Use a repeatable research methodology:

1. **Check their X/Twitter profile** — Look at recent posts. Leaders often tweet about tools, editors, and workflows.
2. **Search their X posts for keywords** — Search `site:x.com <handle> "cursor" OR "neovim" OR "vscode" OR "editor" OR "setup"` to find specific tool mentions.
3. **Check the org's GitHub repo** — Look for `.vscode/`, `.editorconfig`, `.cursor/`, `pyproject.toml` dev dependencies, CI lint config. A repo without these tells you they don't enforce a specific editor.
4. **Check GitHub Issues** — Look for issues where the person comments on editor/tool UX (e.g., "we should match Cursor's behavior here"). This reveals what they use as a benchmark.
5. **Check the repo's own README/CONTRIBUTING.md** — May mention preferred tools.
6. **Cross-reference with interviews/podcasts** — Search for "X person interview setup" or "X person tools."

**Teknium case study (from June 2026):**
- **Primary orchestrator**: **Hermes Agent** (his own product), running in **VS Code** integrated terminal over SSH — the de facto "ACP with VSCode" pattern
- **Editor canvas**: **VS Code** (Dark+ theme) — file explorer, integrated terminal, diffs
- **Previous editor**: **JetBrains**
- **Agentic coding shootout winner**: **Cursor** > Claude Code > Codex (because Cursor lets him inspect changes cleanly)
- **Also uses**: **Claude Code CLI**, **Cursor CLI**
- **Frontend under evaluation**: **Zed** (for native ACP protocol — VS Code's ACP support is not yet available)

The takeaway from this pattern: leaders in AI engineering often use **multiple tools layered** — a primary orchestrator (Hermes), an editor canvas (VS Code), secondary agent tools (Cursor/Claude Code CLI), and a future frontend (Zed). Don't look for one tool. Look for the **workflow stack**.

## Related Skills

- `hermes-agent` — Configuring and using Hermes itself (protected, bundled)
- `llama-cpp` — Local GGUF inference, quant selection, HF Hub discovery
- `weights-and-biases` — ML experiment tracking, sweeps, model registry, dashboards

## Reference Files

- `references/ai-engineer-stack-guide-2026.md` — Comprehensive AI engineering tool stack guide with verified Windows compatibility
- `references/teknium-development-setup.md` — Teknium's development workflow (Hermes + VS Code + Cursor + Claude Code CLI)
- `references/zellij-neovim-herm-stack.md` — Terminal stack setup: zellij + Neovim + herm dashboard
- `references/hermes-stack-decision-guide.md` — Hermes Agent stack decision guide: Simple vs End Game stacks, 7-step upgrade path, environment audit, gap analysis, and AI OS architecture concepts
