# Windows Native Setup (No WSL Required)

Documented from session 2026-06-18. All tools installed and verified on native Windows 10.

## Installation

### Neovim
```bash
winget install Neovim.Neovim
# → C:\Program Files\Neovim\bin\nvim.exe
# Config: C:\Users\<user>\AppData\Local\nvim\init.lua
# Data:   C:\Users\<user>\AppData\Local\nvim-data\ (lazy.nvim plugins land here)
```

### SQLite (for dadbod)
```bash
winget install SQLite.SQLite
# → sqlite3.exe lands in WinGet package dir, added to user PATH automatically
# Verify: nvim --headless "+lua print(vim.fn.exepath('sqlite3'))" "+qa"
```

### Zellij
Download the native Windows binary from GitHub releases (zellij 0.44.3 confirmed working).
```
Config dir: C:\Users\<user>\AppData\Roaming\Zellij\config\
Layouts:    C:\Users\<user>\AppData\Roaming\Zellij\config\layouts\<name>.kdl
```
Note: `config.kdl` is optional — zellij falls back to defaults if missing.

### herm
Already installed via bun: `~/.bun/bin/herm.exe`. Starts a fresh TUI session by default.

## Neovim Config (init.lua)

Working config at `C:\Users\<user>\AppData\Local\nvim\init.lua`:
- lazy.nvim bootstrapped (auto-clones if missing)
- vim-dadbod (`:DB` command)
- vim-dadbod-ui (`:DBUI`, `<leader>D` to toggle sidebar)
- vim-dadbod-completion (omni completion in SQL files)
- SQL file keymaps: `<leader>r` run query, `<leader>rl` run line

### dadbod Settings (set before plugin loads)
```lua
vim.g.db_ui_save_location = vim.fn.stdpath("config") .. "/db_queries"
vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_auto_execute_table_helpers = 1
vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_win_position = "right"
vim.g.db_ui_winwidth = 40
```

### Predefined Connections (g:dbs)
```lua
vim.g.dbs = {
  test_sqlite = "sqlite:///~/AppData/Local/hermes/db/test.sqlite",
}
```
**Important:** `g:dbs` entries appear in the `:DBUI` sidebar. The `:DB` command itself
takes a direct URL, NOT a named connection from `g:dbs`. To query by name in `:DB`,
use the `g:` variable syntax: `:DB g:dbs.test_sqlite SELECT * FROM agents`.

## SQLite URL Format on Windows

Use forward slashes with the drive letter after triple-slash:
```
sqlite:///~/AppData/Local/hermes/db/test.sqlite
```

This works because dadbod's `db#url#file_path()` calls `s:canonicalize_path()` which:
1. Extracts the path after `sqlite:`
2. Converts backslashes to forward slashes
3. Resolves via `fnamemodify(path, ':p')`
4. On Windows with `!&shellslash`, converts back to backslashes for the `sqlite3.exe` argv

The adapter builds: `['sqlite3', '~/AppData/Local/hermes\db\test.sqlite']` and pipes the query
via `chansend(job, query)` then `chanclose(job, 'stdin')`.

## Windows Clipboard Fix (No win32yank Needed)

Neovim on native Windows **cannot use `unnamedplus`** without a clipboard tool.
Do NOT install win32yank — use the built-in Windows providers:

```lua
-- In init.lua, REPLACE `vim.opt.clipboard = "unnamedplus"` with:
vim.g.clipboard = {
  name = "Windows",
  copy  = { ["+"] = "clip.exe",
            ["*"] = "clip.exe" },
  paste = { ["+"] = "powershell.exe -NoProfile -Command Get-Clipboard -Raw",
            ["*"] = "powershell.exe -NoProfile -Command Get-Clipboard -Raw" },
  cache_enabled = 0,
}
```

This works because:
- `clip.exe` accepts stdin and writes it to the Windows clipboard (built into Windows)
- `powershell Get-Clipboard -Raw` reads clipboard text back (built into PowerShell)
- No third-party tools like win32yank needed
- Both `+` and `*` registers map to the same system clipboard

## Treesitter Parser Compilation (C Compiler Needed)

Treesitter parsers need a C compiler. On Windows, `tree-sitter` defaults to `cl.exe`
(MSVC), which requires Visual Studio Build Tools (~7GB). **Install MinGW-w64 GCC instead:**

```bash
winget install BrechtSanders.WinLibs.POSIX.UCRT
# → Adds gcc.exe to PATH, verified with Neovim 0.12.2 + tree-sitter 0.26.9
```

Then add this to `init.lua` **before** nvim-treesitter loads:

```lua
vim.env.CC = "gcc"
```

The template `templates/init.lua` in this skill already includes this setting.

### Installing All 16 Parsers Headlessly

After MinGW is installed and `vim.env.CC = "gcc"` is in init.lua:

```bash
# NOTE: PATH must include MinGW's bin/ directory. If winget just installed it,
# reconstruct PATH from registry first (see section below):
powershell.exe -NoProfile -Command '
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + `
            [Environment]::GetEnvironmentVariable("Path", "User")
$env:CC = "gcc"
& "C:\Program Files\Neovim\bin\nvim.exe" --headless "+TSInstall lua vim vimdoc bash python javascript typescript go rust sql markdown yaml json markdown_inline" "+sleep 120" "+qa"
'
```

All 16 parsers verified compiling and installed with GCC 16.1.0 (MinGW-W64 x86_64-ucrt-posix-seh).

### Lualine Warning After Plugin Install

After adding new plugins, lualine may show "There are some issues with your config"
on first launch. Run `:LualineNotices` to view and dismiss — this is a one-time
setup notice, not an error.

### Installed Parsers (Verified 2026-06-19)

```
lua, vim, vimdoc, bash, python, javascript, typescript, go, rust, sql,
markdown, yaml, json, markdown_inline, ecma, jsx
```

## Windows PATH Reconstruction from Registry

**Problem:** Winget adds package directories to the Windows User PATH, but child
processes inherit the PATH from when their parent shell started. A PowerShell/cmd
opened before the install won't see new tools — including tree-sitter, gcc, or
any newly installed winget binary.

**Fix:** Rebuild PATH from the Windows registry before running commands:

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User")
```

Use this pattern when running Neovim headless commands after a winget install in
the same session. Without it, nvim will report `ENOENT: no such file or directory
(cmd): 'tree-sitter'` even though the binary is on the registry PATH.

## ⚠️ CRITICAL PITFALL: Headless Testing of `:DB`

dadbod runs queries **asynchronously** via `jobstart()` + `chansend()`. In headless nvim,
if you run `+qa` immediately after `+DB`, the async job is killed mid-flight and reports
**"aborted after 0.029s"** — a false negative. The query never actually fails.

### Wrong (false "aborted"):
```bash
nvim --headless "+DB sqlite:///~/AppData/Local/hermes/db/test.sqlite SELECT * FROM agents" "+qa"
# → "DB: Query '...' aborted after 0.029s"  ← LIES
```

### Correct (add sleep before quit):
```bash
nvim --headless "+DB sqlite:///~/AppData/Local/hermes/db/test.sqlite SELECT * FROM agents" "+sleep 2" "+qa"
# → "DB: Query '...' finished in 0.022s"  ← TRUTH
```

**Root cause:** `db.vim` line 309 calls `s:job_run()` which uses `jobstart()` (async).
The `on_exit` callback (`s:query_callback`) fires on job completion. If `+qa` kills nvim
first, the job exits non-zero (killed), and `s:query_callback` reports `status=1` → "aborted".

**Lesson:** When testing any dadbod query in headless mode, ALWAYS add `+sleep 2` (or
longer for slow queries) between `+DB` and `+qa`. This is not a dadbod bug — it's the
async nature of the job system interacting with headless exit.

## Verifying dadbod + SQLite End-to-End

```bash
# 1. Verify sqlite3 is findable by nvim
nvim --headless "+lua print(vim.fn.exepath('sqlite3'))" "+qa"

# 2. Test a query (WITH sleep!)
nvim --headless \
  "+DB sqlite:///~/AppData/Local/hermes/db/test.sqlite SELECT name,role FROM agents" \
  "+sleep 2" \
  "+messages" \
  "+qa"
# Should print: "DB: Query '...' finished in 0.022s"

# 3. Verify g:dbs is set
nvim --headless "+echo g:dbs" "+qa"
# Should print: {'test_sqlite': 'sqlite:///~/AppData/Local/hermes/db/test.sqlite'}
```

## Headless Mason LSP Server Installation

LSP servers can be installed headlessly via Mason. Use the same `+sleep` pattern as
Lazy sync, but with a longer sleep (60s) because Mason downloads and installs binaries:

```bash
nvim --headless \
  "+MasonInstall lua-language-server pyright typescript-language-server gopls rust-analyzer bash-language-server yaml-language-server json-lsp sqlls marksman" \
  "+sleep 60" \
  "+qa"
```

### ⚠️ Mason Package Names ≠ lspconfig Server Names

Mason uses its own package names that differ from lspconfig server names.
Use Mason names for `:MasonInstall`, lspconfig names in `ensure_installed` and `lspconfig.<name>.setup()`:

| lspconfig name | Mason package name |
|----------------|-------------------|
| `lua_ls` | `lua-language-server` |
| `ts_ls` | `typescript-language-server` |
| `rust_analyzer` | `rust-analyzer` |
| `bashls` | `bash-language-server` |
| `yamlls` | `yaml-language-server` |
| `jsonls` | `json-lsp` |
| `sqls` | `sqlls` |
| `pyright` | `pyright` |
| `gopls` | `gopls` |
| — | `marksman` (markdown LSP, not in lspconfig) |

### gopls Fails Without Go

`gopls` will fail to install if Go is not on PATH. This is expected — Mason reports
`spawn: go failed` but all other servers install successfully. Install Go later if needed:

```bash
winget install GoLang.Go
# Then in nvim: :MasonInstall gopls
```

### ensure_installed vs Manual Install

The `mason-lspconfig` `ensure_installed` option in init.lua should auto-install servers
on first launch, but in headless mode it may not complete before exit. For reliable
headless setup, use the explicit `+MasonInstall` command with `+sleep 60`.

### Verifying Installed Servers

```bash
ls "$HOME/AppData/Local/nvim-data/mason/bin/"
# Should list: lua-language-server.cmd, pyright.cmd, typescript-language-server.cmd, etc.
```

## Launching the Stack

```bash
zellij --layout dev
# Left pane (65%): nvim with full config
# Right pane (35%): herm TUI
```

In nvim:
- `<Space>D` → Toggle DBUI sidebar
- `:DB sqlite:///C:/path/to/db.sqlite SELECT * FROM table` → Direct query
- `:DBUI` → Open database browser (shows g:dbs connections + connections.json)
- In SQL files: `<leader>r` runs the file/selection, `<leader>rl` runs current line
