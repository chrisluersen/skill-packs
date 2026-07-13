# zellij/neovim/herm Stack — Complete Install & Config Reference

## Quick Install Script (WSL Ubuntu)

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "=== Installing zellij/neovim/herm stack ==="

# Core tools via Cargo
cargo install --locked \
  yazi-fm yazi-cli \
  btop \
  ripgrep \
  fzf \
  zellij \
  jless \
  glow \
  mdcat

# Go tools
go install github.com/jesseduffield/lazygit@latest
go install github.com/jesseduffield/lazydocker@latest

# Neovim (latest stable)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo tar -C /opt -xzf nvim-linux64.tar.gz
echo 'export PATH="$PATH:/opt/nvim-linux64/bin"' >> ~/.zshrc

# Clipboard (WSL)
sudo apt update && sudo apt install -y win32yank

# Herm (build from source - check liftaris/herm for latest)
# cargo install herm  # or build from source per repo instructions

echo "=== Done. Restart shell or run: source ~/.zshrc ==="
```

## File Locations

| Config | Path |
|--------|------|
| zellij | `~/.config/zellij/config.kdl` |
| Neovim | `~/.config/nvim/init.lua` (lazy.nvim) |
| yazi | `~/.config/yazi/` |
| herm | Runs standalone, no config needed |

## zellij/config.kdl — Starter Layout

```kdl
# ~/.config/zellij/config.kdl

theme "gruvbox"

keybinds {
    shared {
        bind "Ctrl p" { SwitchMode "Normal"; }
        bind "Ctrl h" { MoveFocus Left; }
        bind "Ctrl j" { MoveFocus Down; }
        bind "Ctrl k" { MoveFocus Up; }
        bind "Ctrl l" { MoveFocus Right; }
    }
    normal {
        bind "n" { NewPane; }
        bind "t" { NewTab; }
        bind "x" { ClosePane; }
        bind "X" { CloseTab; }
        bind "h" { MoveFocus Left; }
        bind "j" { MoveFocus Down; }
        bind "k" { MoveFocus Up; }
        bind "l" { MoveFocus Right; }
        bind "H" { Resize Left; }
        bind "J" { Resize Down; }
        bind "K" { Resize Up; }
        bind "L" { Resize Right; }
    }
}

layout {
    default {
        pane split_direction="vertical" {
            pane size="70%" name="editor" command="nvim"
            pane size="30%" name="shell" command="zsh"
        }
        pane name="herm" command="herm" focus=false
    }
    
    project {
        tab name="main" {
            pane split_direction="vertical" {
                pane size="70%" name="editor" command="nvim"
                pane size="30%" name="shell" command="zsh"
            }
        }
        tab name="git" {
            pane name="lazygit" command="lazygit"
        }
        tab name="docker" {
            pane name="lazydocker" command="lazydocker"
        }
        tab name="herm" {
            pane name="herm" command="herm"
        }
        tab name="db" {
            pane split_direction="horizontal" {
                pane name="dadbod" command="nvim -c 'DBUI'"
                pane name="sql" command="psql"
            }
        }
        tab name="logs" {
            pane split_direction="horizontal" {
                pane name="btop" command="btop"
                pane name="tail" command="tail -f /var/log/syslog"
            }
        }
    }
}

mouse {
    scroll true
    copy_on_select true
}

pane_frames true
mirror_session false
auto_layout true
```

## Neovim/init.lua — Minimal Performance Config

```lua
-- ~/.config/nvim/init.lua
-- Performance-first Neovim config for zellij/herm stack

-- Leader key
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Performance settings
vim.opt.lazyredraw = true
vim.opt.updatetime = 100
vim.opt.timeoutlen = 300
vim.opt.ttimeoutlen = 10
vim.opt.redrawtime = 1500

-- UI
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.laststatus = 3
vim.opt.showmode = false
vim.opt.cmdheight = 1

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Editing
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Clipboard (WSL)
vim.opt.clipboard = "unnamedplus"

-- Split behavior
vim.opt.splitbelow = true
vim.opt.splitright = true

-- File handling
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require("lazy").setup({
  -- Core
  { "folke/lazy.nvim" },
  { "nvim-lua/plenary.nvim" },

  -- LSP/Completion
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", build = ":MasonUpdate" },
  { "williamboman/mason-lspconfig.nvim" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },
  { "saadparwaiz1/cmp_luasnip" },

  -- Telescope (fzf-native for speed)
  { "nvim-telescope/telescope.nvim", dependencies = {
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }
  }},

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },

  -- Git
  { "tpope/vim-fugitive" },
  { "lewis6991/gitsigns.nvim", config = true },
  { "kdheepak/lazygit.nvim", cmd = "LazyGit" },

  -- File tree (optional)
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },

  -- Markdown
  { "iamcco/markdown-preview.nvim", build = "cd app && yarn install", ft = "markdown" },
  { "MeanderingProgrammer/render-markdown.nvim", ft = "markdown" },

  -- Dadbod (SQL)
  { "kristijanhusak/vim-dadbod-ui" },
  { "tpope/vim-dadbod" },

  -- AI
  { "yetone/avante.nvim", build = "make", cmd = "AvanteAsk" },

  -- UI
  { "nvim-lualine/lualine.nvim", config = true },
  { "folke/which-key.nvim", config = true },
  { "folke/noice.nvim", config = true },
}, {
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      }
    }
  }
})

-- LSP Setup (minimal)
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "pyright", "rust_analyzer", "ts_ls" },
})
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
for _, server in ipairs({ "lua_ls", "pyright", "rust_analyzer", "ts_ls" }) do
  lspconfig[server].setup({ capabilities = capabilities })
end

-- Completion
local cmp = require("cmp")
local luasnip = require("luasnip")
cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { "i", "s" }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { "i", "s" }),
  }),
  sources = { { name = "nvim_lsp" }, { name = "luasnip" }, { name = "buffer" }, { name = "path" } },
})

-- Treesitter
require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "python", "rust", "typescript", "javascript", "markdown", "sql" },
  highlight = { enable = true },
  indent = { enable = true },
})

-- Keybindings (zellij-friendly)
local map = vim.keymap.set
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "File tree" })
map("n", "<leader>f", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>g", "<cmd>Telescope live_grep<cr>", { desc = "Grep" })
map("n", "<leader>b", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
map("n", "<leader>G", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
map("n", "<leader>d", "<cmd>DBUIToggle<cr>", { desc = "Dadbod UI" })
map("n", "<leader>h", "<cmd>split<cr>", { desc = "Horizontal split" })
map("n", "<leader>v", "<cmd>vsplit<cr>", { desc = "Vertical split" })

-- Disable netrw (nvim-tree handles it)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Terminal keymaps for zellij integration
map("t", "<C-h>", "<C-\\><C-N><C-w>h", { desc = "Move left from terminal" })
map("t", "<C-j>", "<C-\\><C-N><C-w>j", { desc = "Move down from terminal" })
map("t", "<C-k>", "<C-\\><C-N><C-w>k", { desc = "Move up from terminal" })
map("t", "<C-l>", "<C-\\><C-N><C-w>l", { desc = "Move right from terminal" })
```

## Usage Commands

```bash
# Start default layout
zellij --layout default

# Start project layout (all tabs)
zellij --layout project

# Attach to existing session
zellij attach default

# List sessions
zellij list-sessions

# Kill session
zellij kill-session default

# Neovim
nvim              # Start
:Lazy             # Plugin manager
:Mason            # LSP installer
:TSUpdate         # Update treesitter

# File manager
yazi              # In any pane

# Git
lazygit           # In git tab

# Docker
lazydocker        # In docker tab

# Process monitor
btop              # In logs tab

# Markdown
glow README.md    # Render in terminal
mdcat README.md   # Similar

# HTTP/JSON
http GET api.example.com/users | jless
```

## What You Don't Need

| Tool | Replaced By |
|------|-------------|
| ranger/nnn/lf | yazi |
| tmux | zellij |
| tmux-sessionizer | zellij layouts |
| k9s | lazydocker + kubectl |
| separate markdown editor | Neovim + render-markdown + glow |
| GUI file manager | yazi + Neovim |

## Performance Baseline (target)

| Metric | Target |
|--------|--------|
| zellij startup | <20ms |
| Neovim startup | <30ms |
| Combined cold start | <50ms |
| Memory (zellij + nvim) | ~40-50MB |
| Session restore | Instant (zellij attach) |