-- ═══════════════════════════════════════════════════════════════════════
-- Neovim Config — AI Terminal Stack
-- Tested on Windows 10 with Neovim 0.12.2 + lazy.nvim
-- 38 plugins: LSP, Completion, Telescope, Treesitter, Git, Markdown, DB,
--              UI, Formatting, File Navigation, Indent, Comments
-- ═══════════════════════════════════════════════════════════════════════
--
-- USAGE: Copy to C:\Users\<user>\AppData\Local\nvim\init.lua (Windows)
--        or   ~/.config/nvim/init.lua (Linux/macOS)
-- Then run: nvim --headless "+Lazy! sync" "+sleep 30" "+qa"

-- Set C compiler for tree-sitter parser compilation (MinGW GCC, not MSVC)
-- On Windows, tree-sitter defaults to `cl.exe` (MSVC) which requires VS Build
-- Tools (~7GB). Install MinGW-w64 GCC via winget and set:
--   winget install BrechtSanders.WinLibs.POSIX.UCRT
vim.env.CC = "gcc"
--
-- USAGE: Copy to C:\Users\<user>\AppData\Local\nvim\init.lua (Windows)
--        or   ~/.config/nvim/init.lua (Linux/macOS)
-- Then run: nvim --headless "+Lazy! sync" "+sleep 30" "+qa"

-- Leader (must be set before lazy so mappings use it)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ── Basic options ─────────────────────────────────────────────────────
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
-- Clipboard: use clip.exe + PowerShell on native Windows (no win32yank needed)
vim.g.clipboard = {
  name = "Windows",
  copy  = { ["+"] = "clip.exe",                                 ["*"] = "clip.exe" },
  paste = { ["+"] = "powershell.exe -NoProfile -Command Get-Clipboard -Raw",
            ["*"] = "powershell.exe -NoProfile -Command Get-Clipboard -Raw" },
  cache_enabled = 0,
}
vim.opt.mouse = "a"
vim.opt.timeoutlen = 300
vim.opt.scrolloff = 8

-- ── Bootstrap lazy.nvim ────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo(
      { { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" },
        { "\nPress any key to exit...", "MoreMsg" } }, true, { err = true })
    vim.fn.getchar()
    vim.cmd.quit()
  end
end
vim.opt.rtp:prepend(lazypath)

-- ── dadbod settings (must be set before plugin loads) ──────────────────
vim.g.db_ui_save_location = vim.fn.stdpath("config") .. "/db_queries"
vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_auto_execute_table_helpers = 1
vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_win_position = "right"
vim.g.db_ui_winwidth = 40
-- Predefined connections (edit/extend as needed — also addable via :DBUI with `+`)
vim.g.dbs = {
  test_sqlite = "sqlite:///~/AppData/Local/hermes/db/test.sqlite",
  -- Example: postgres = "postgresql://user:pass@localhost:5432/mydb",
}

-- ═══════════════════════════════════════════════════════════════════════
-- Plugins
-- ═══════════════════════════════════════════════════════════════════════
require("lazy").setup({

  -- ── Core ────────────────────────────────────────────────────────────
  { "nvim-lua/plenary.nvim" },

  -- ── Theme ───────────────────────────────────────────────────────────
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false,
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- ── LSP & Completion ────────────────────────────────────────────────
  {
    "williamboman/mason.nvim",
    config = function() require("mason").setup() end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", "pyright", "gopls", "rust_analyzer",
          "ts_ls", "bashls", "yamlls", "jsonls", "sqls",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })
      lspconfig.pyright.setup({})
      lspconfig.gopls.setup({})
      lspconfig.rust_analyzer.setup({})
      lspconfig.ts_ls.setup({})
      lspconfig.bashls.setup({})
      lspconfig.yamlls.setup({})
      lspconfig.jsonls.setup({})
      lspconfig.sqls.setup({})
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }),
      })
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },

  -- ── Telescope (fuzzy finder) ────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
    },
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Help tags" },
    },
    config = function()
      require("telescope").setup({})
      -- fzf-native is optional — works without it, just slower.
      -- pcall prevents errors if make/cmake isn't available (Windows).
      pcall(require("telescope").load_extension, "fzf")
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = "make",
    -- On Windows without `make`, the build fails silently.
    -- Telescope still works — just uses the slower built-in sorter.
  },

  -- ── Treesitter (syntax highlighting & parsing) ─────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "bash", "python", "javascript",
          "typescript", "go", "rust", "sql", "markdown", "yaml", "json",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
  { "nvim-treesitter/nvim-treesitter-textobjects" },

  -- ── Git ─────────────────────────────────────────────────────────────
  { "tpope/vim-fugitive" },
  {
    "lewis6991/gitsigns.nvim",
    config = function() require("gitsigns").setup() end,
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Open LazyGit" },
    },
  },

  -- ── File Manager (Yazi integration) ────────────────────────────────
  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>e", "<cmd>Yazi<cr>", desc = "Open Yazi" },
    },
    opts = { open_for_directories = true },
  },

  -- ── Markdown ────────────────────────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "codecompanion" },
    opts = { render_modes = true },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewToggle" },
    build = "cd app && npm install",  -- npm, not yarn (Windows-friendly)
    ft = { "markdown" },
  },

  -- ── Database ────────────────────────────────────────────────────────
  { "tpope/vim-dadbod", cmd = { "DB", "DBUI" } },
  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIFindBuffer" },
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<CR>", desc = "Toggle DB UI" },
    },
  },
  { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" } },

  -- ── Quality of Life ─────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Toggle comment line" },
      { "gbc", mode = "n", desc = "Toggle comment block" },
      { "gc",  mode = "x", desc = "Toggle comment selection" },
    },
    config = function() require("Comment").setup() end,
  },
  {
    "kylechui/nvim-surround",
    keys = { "ys", "cs", "ds", "yS" },
    config = function() require("nvim-surround").setup() end,
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    event = "VeryLazy",
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = { char = "┊" },
        scope = { enabled = true },
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      { "<leader>f", function() require("conform").format() end, desc = "Format buffer" },
    },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "isort", "black" },
          javascript = { "prettierd", "prettier" },
          typescript = { "prettierd", "prettier" },
          json = { "prettierd", "prettier" },
          yaml = { "prettierd", "prettier" },
          go = { "gofumpt", "goimports" },
          rust = { "rustfmt" },
          markdown = { "prettierd", "prettier" },
        },
        format_on_save = { timeout_ms = 500, lsp_fallback = true },
      })
    end,
  },
  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble", "TodoTelescope" },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
      { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo Troubles" },
    },
    config = function() require("todo-comments").setup() end,
  },
  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle" },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer diagnostics" },
      { "<leader>cs", "<cmd>Trouble symbols toggle<cr>",       desc = "Symbols" },
    },
    config = function() require("trouble").setup() end,
  },
  {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    keys = {
      { "<leader>-", "<cmd>Oil<cr>", desc = "Open parent directory (Oil)" },
    },
    opts = {
      default_file_explorer = true,
      keymaps = {
        ["<C-p>"] = "actions.preview",
        ["<C-h>"] = false,
      },
    },
  },

  -- ── UI ──────────────────────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({ options = { theme = "catppuccin" } })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function() require("which-key").setup() end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function() require("noice").setup() end,
  },

}, {
  install = { missing = true },
  checker = { enabled = false },
})

-- ═══════════════════════════════════════════════════════════════════════
-- Keymaps & Autocmds
-- ═══════════════════════════════════════════════════════════════════════

-- SQL file niceties
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sql", "mysql", "plsql" },
  callback = function()
    local opts = { buffer = true, silent = true }
    vim.keymap.set("n", "<leader>r", "<Plug>(DBExec)", opts)
    vim.keymap.set("x", "<leader>r", "<Plug>(DBExec)", opts)
    vim.keymap.set("n", "<leader>rl", "<Plug>(DBExecLine)", opts)
  end,
})
