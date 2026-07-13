# Neovim Plugin Spec (lazy.nvim)

Complete plugin list for the AI terminal stack. Copy into `~/.config/nvim/lua/plugins/` or a single `init.lua`.

## Core
```lua
{ "folke/lazy.nvim" },                    -- Plugin manager
{ "nvim-lua/plenary.nvim" },              -- Utilities
```

## LSP & Completion
```lua
{ "neovim/nvim-lspconfig" },
{ "williamboman/mason.nvim" },
{ "williamboman/mason-lspconfig.nvim" },
{ "hrsh7th/nvim-cmp" },
{ "hrsh7th/cmp-nvim-lsp" },
{ "L3MON4D3/LuaSnip" },
{ "saadparwaiz1/cmp_luasnip" },
{ "rafamadriz/friendly-snippets" },
```

## Telescope (fzf-native)
```lua
{
  "nvim-telescope.nvim",
  dependencies = {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
  },
},
```
**Windows note:** `make` is not available on Windows by default. telescope-fzf-native's build will fail, but Telescope still works (uses slower built-in sorter). Use `pcall(require("telescope").load_extension, "fzf")` to gracefully skip the missing extension. See `templates/init.lua` for the Windows-safe config.

## Treesitter
```lua
{
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = { "lua", "vim", "vimdoc", "bash", "python", "javascript", "typescript", "go", "rust", "sql", "markdown", "yaml", "json" },
      highlight = { enable = true },
      indent = { enable = true },
    })
  end,
},
{
  "nvim-treesitter/nvim-treesitter-textobjects",
},
```

## Git
```lua
{ "tpope/vim-fugitive" },
{
  "lewis6991/gitsigns.nvim",
  config = function() require("gitsigns").setup() end,
},
{
  "kdheepak/lazygit.nvim",
  cmd = { "LazyGit", "LazyGitConfig", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
},
```

## File Manager (Yazi integration)
```lua
{
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  keys = {
    { "<leader>e", "<cmd>Yazi<cr>", desc = "Open Yazi" },
  },
  opts = { open_for_directories = true },
},
```

## Markdown
```lua
{
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown", "codecompanion" },
  opts = { render_modes = true },
},
{
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
  build = "cd app && yarn install",
  ft = { "markdown" },
},
```
**Windows note:** `yarn` may not be installed. Use `build = "cd app && npm install"` instead — verified working on Windows 10.

## Database (choose ONE approach)

### Approach 1: dadbod-ui + sqls (stable, feature-complete)
```lua
{ "tpope/vim-dadbod" },
{ "kristijanhusak/vim-dadbod-ui",
  dependencies = { "tpope/vim-dadbod" },
  cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_show_database_icon = 1
  end,
},
{ "nanotee/sqls.nvim",
  ft = "sql",
  config = function() require("lspconfig").sqls.setup{} end,
},
```

### Approach 2: nvim-dbee + sqls (modern, self-contained)
```lua
{
  "kndndrj/nvim-dbee",
  dependencies = { "MunifTanjim/nui.nvim" },
  build = function() require("dbee").install() end,
  config = function() require("dbee").setup() end,
  cmd = { "Dbee" },
},
{ "nanotee/sqls.nvim",
  ft = "sql",
  config = function() require("lspconfig").sqls.setup{} end,
},
```

## AI Coding (choose ONE)
```lua
-- Option A: Avante.nvim (inline, in-editor)
{
  "yetone/avante.nvim",
  build = "make",
  config = function() require("avante").setup() end,
},
-- Option B: Use external claude-code / aider (no Neovim plugin needed)
```

## UI
```lua
{ "nvim-lualine/lualine.nvim", config = function() require("lualine").setup() end },
{ "folke/which-key.nvim", config = function() require("which-key").setup() end },
{ "folke/noice.nvim",
  dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
  config = function() require("noice").setup() end,
},
-- Theme (choose one)
{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
-- { "folke/tokyonight.nvim", priority = 1000 },
```

## Language-Specific (add as needed)
```lua
-- Rust: rustaceanvim
-- Go: nvim-go
-- Python: pyright via Mason
```

## Bootstrap init.lua Structure
```lua
-- ~/.config/nvim/init.lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- Core settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300

-- Keymaps (add your custom ones)
-- Telescope
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")
-- LazyGit
vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>")
-- Yazi
vim.keymap.set("n", "<leader>e", "<cmd>Yazi<cr>")
```

## Mason LSP Ensured Installed
```lua
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls", "ts_ls", "pyright", "gopls", "rust_analyzer", "clangd",
    "yamlls", "jsonls", "bashls", "dockerls", "sqls",
  },
})
```