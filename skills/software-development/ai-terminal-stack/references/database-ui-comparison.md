# Database UI Comparison: dadbod-ui vs nvim-dbee vs sqls

Research conducted: 2026-06-18
Sources: GitHub repos, Reddit discussions, HN comments, official docs

## Quick Decision Matrix

| Criterion | dadbod-ui + sqls | nvim-dbee + sqls | sqls only |
|-----------|------------------|------------------|-----------|
| **Maturity** | ★★★★★ (5+ years) | ★★☆☆☆ (Alpha) | ★★★★☆ (Beta) |
| **DB Support** | Universal (any dadbod driver) | PostgreSQL, MySQL, SQLite, MSSQL | Same as LSP client |
| **CLI Dependencies** | Required (psql, mysql, sqlite3) | **None** (Go backend) | None |
| **Visual Schema Browser** | Yes | Yes | No |
| **Query History** | Yes (persistent) | Yes (scratchpads) | No |
| **Saved Queries** | Yes | Yes (scratchpads) | No |
| **Exports (CSV/JSON)** | Yes | Yes | No |
| **SSH Tunnels** | Yes (native) | Planned | Via LSP config |
| **LSP Features** | Via sqls (autocomplete, hover, goto def, join completion, formatting) | Same | Native |
| **Performance** | Good | **Excellent** (Go backend, iterators) | N/A (LSP only) |
| **Breaking Changes** | Rare | **Frequent** (alpha) | Occasional (beta) |
| **Config Complexity** | Medium | Low | Low |

## Detailed Comparison

### Approach 1: dadbod-ui + sqls (Recommended for Stability)

**Architecture:**
- `vim-dadbod` (core) - VimScript, executes queries via CLI tools
- `vim-dadbod-ui` (UI) - Lua, tree view, query history, saved queries
- `sqls` (LSP) - Go language server for SQL autocomplete/hover/goto

**Pros:**
- Most battle-tested, largest community
- Works with ANY database dadbod supports (PostgreSQL, MySQL, SQLite, MSSQL, Oracle, DuckDB, etc.)
- Rich UI: schema browser, query history panel, saved queries, export to CSV/JSON/Markdown
- Native SSH tunnel support in connection config
- sqls LSP provides true IDE features in SQL files

**Cons:**
- Requires CLI tools installed: `psql`, `mysql`, `sqlite3`, `sqlcmd`, etc.
- VimScript core has some legacy quirks
- Connection config via global variables or `.env` files

**Installation:**
```lua
-- lazy.nvim
{ "tpope/vim-dadbod" },
{ "kristijanhusak/vim-dadbod-ui",
  dependencies = { "tpope/vim-dadbod" },
  cmd = { "DBUI", "DBUIToggle" },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_show_database_icon = 1
    vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/dadbod_ui"
  end,
},
{ "nanotee/sqls.nvim",
  ft = "sql",
  config = function() require("lspconfig").sqls.setup{} end,
},
```
```bash
# CLI tools (WSL Ubuntu)
sudo apt install postgresql-client mysql-client sqlite3
# sqls binary
go install github.com/sqls-server/sqls@latest
```

**Configuration (sqls.yml):**
```yaml
connections:
  - alias: local_postgres
    driver: postgresql
    dataSourceName: "postgresql://user:pass@localhost:5432/dbname"
  - alias: local_mysql
    driver: mysql
    dataSourceName: "mysql://user:pass@tcp(localhost:3306)/dbname"
```

---

### Approach 2: nvim-dbee + sqls (Recommended for Performance/Modern)

**Architecture:**
- `nvim-dbee` - Go backend (connection pooling, query execution) + Lua frontend (nui.nvim)
- `sqls` (LSP) - Same as above

**Pros:**
- **Zero CLI dependencies** - Go backend handles all connections natively
- Modern Lua UI (nui.nvim) - feels native, fast
- Scratchpad workflow - iterative query development like a notebook
- Fast iterator-based result streaming (handles large result sets)
- Connection sources: config file, environment variables, Vault, 1Password
- Cross-platform binaries (Windows, Linux, macOS)

**Cons:**
- **Alpha software** - breaking changes between versions
- Smaller community, fewer DB-specific features
- No SSH tunnel support yet (planned)
- Fewer export formats

**Installation:**
```lua
-- lazy.nvim
{
  "kndndrj/nvim-dbee",
  dependencies = { "MunifTanjim/nui.nvim" },
  build = function() require("dbee").install() end,  -- downloads Go binary
  config = function() require("dbee").setup() end,
  cmd = { "Dbee" },
},
{ "nanotee/sqls.nvim",
  ft = "sql",
  config = function() require("lspconfig").sqls.setup{} end,
},
```
```bash
# Only sqls binary needed (nvim-dbee installs its own binary)
go install github.com/sqls-server/sqls@latest
```

**Configuration (dbee config):**
```lua
require("dbee").setup({
  sources = {
    require("dbee.sources").EnvSource:new("DBEE_CONNECTIONS"),
    -- or file source
    require("dbee.sources").FileSource:new(vim.fn.stdpath("config") .. "/dbee/connections.json"),
  },
})
```
```json
// connections.json
{
  "connections": [
    {
      "name": "local_postgres",
      "type": "postgres",
      "url": "postgresql://user:pass@localhost:5432/dbname",
      "options": { "sslmode": "disable" }
    }
  ]
}
```

**Keybindings (default):**
- `o` - Toggle tree node
- `r` - Refresh tree
- `<CR>` on connection - Set active / view history
- `cw` - Edit connection
- `dd` - Delete connection
- `<CR>` on `new` scratchpad - Create new
- `BB` (visual/normal) - Execute query
- Results: `j/k` navigate, `Enter` expand, `y` yank

---

### Approach 3: sqls Only (Minimal)

**Use case:** You only want LSP features (autocomplete, hover, goto definition) in SQL files, no visual UI.

**Setup:**
```lua
{ "nanotee/sqls.nvim",
  ft = "sql",
  config = function() require("lspconfig").sqls.setup{} end,
},
```
```bash
go install github.com/sqls-server/sqls@latest
```

**Pair with:** `vim-dadbod` (core only) for `:DB` query execution, Telescope for history.

---

## sqls LSP Features (Common to All Approaches)

| Feature | Status |
|---------|--------|
| Auto-completion (DML: SELECT, INSERT, UPDATE, DELETE) | ✅ |
| Auto-completion (DDL: CREATE TABLE, ALTER TABLE) | 🚧 Planned |
| Join completion (FK-aware) | ✅ |
| Code actions (Execute, Explain, Switch Connection) | ✅ |
| Hover (schema info) | ✅ |
| Signature help | ✅ |
| Document formatting | ✅ |
| Go to definition (tables, columns) | ✅ |
| Find references | ✅ |

**Supported Databases:** PostgreSQL, MySQL, SQLite, MSSQL, Vertica, H2

---

## Recommendation for This Stack

Given: **Speed/performance priority**, **WSL Ubuntu**, **Hermes/AI coding focus**, **User explicitly chose Approach 1**

| Your Priority | Choose |
|---------------|--------|
| **Maximum raw performance, zero CLI deps, modern UX** | **nvim-dbee + sqls** (accept alpha risk) |
| **Production reliability, maximum features, team sharing** | **dadbod-ui + sqls** ⭐ **DEFAULT (user-locked)** |
| **Minimal config, LSP only** | **sqls + dadbod (core)** |

**Current default: dadbod-ui + sqls** — user explicitly requested Approach 1 be locked in. If you hit breaking changes with nvim-dbee later, migrate to dadbod-ui (same sqls LSP). The Neovim plugin spec in `references/neovim-plugins.md` includes both approaches commented.

---

## Complete Setup: Approach 1 (dadbod-ui + sqls) — Current Default

```lua
-- ~/.config/nvim/lua/plugins/database.lua
return {
  -- Core adapter
  {
    "tpope/vim-dadbod",
    cmd = { "DB" },
  },
  -- UI
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = { "tpope/vim-dadbod" },
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_winwidth = 50
      vim.g.db_ui_auto_execute_table_helpers = 1
    end,
  },
  -- LSP (sqls)
  {
    "nanotee/sqls.nvim",
    ft = "sql",
    config = function()
      require("lspconfig").sqls.setup{
        on_attach = function(client, bufnr)
          require("sqls").on_attach(client, bufnr)
        end,
      }
    end,
  },
}
```

```bash
# WSL dependencies
sudo apt update && sudo apt install -y postgresql-client mysql-client sqlite3
go install github.com/sqls-server/sqls@latest
```

**Usage:**
- `<leader>db` → Toggle DBUI
- In SQL file: LSP autocomplete works automatically
- `:DBUIAddConnection` → Add new connection (saves to `~/.config/db_ui/connections.json`)

---

## Complete Setup: Approach 2 (nvim-dbee + sqls) — Modern

```lua
-- ~/.config/nvim/lua/plugins/database.lua
return {
  -- Modern UI (self-contained)
  {
    "kndndrj/nvim-dbee",
    dependencies = { "MunifTanjim/nui.nvim" },
    build = function() require("dbee").install() end,
    config = function() require("dbee").setup() end,
    cmd = { "Dbee", "DbeeToggle", "DbeeOpen" },
    keys = {
      { "<leader>db", "<cmd>DbeeToggle<cr>", desc = "Toggle Dbee" },
    },
  },
  -- LSP (sqls) — same as above
  {
    "nanotee/sqls.nvim",
    ft = "sql",
    config = function()
      require("lspconfig").sqls.setup{
        on_attach = function(client, bufnr)
          require("sqls").on_attach(client, bufnr)
        end,
      }
    end,
  },
}
```

```bash
# Only sqls needed (dbee installs its own binary)
go install github.com/sqls-server/sqls@latest
```

**Usage:**
- `<leader>db` → Toggle Dbee (floating window)
- Connection manager in UI
- Scratchpads for quick queries

---

## sqls Configuration (Both Approaches)

```yaml
# ~/.config/sqls/config.yml (optional)
databases:
  - name: "project-db"
    dsn: "postgresql://user:pass@localhost:5432/dbname"
  - name: "local-sqlite"
    dsn: "sqlite3:///path/to/db.sqlite"
```

```lua
-- sqls.nvim auto-discovers this, or configure in lspconfig:
require("lspconfig").sqls.setup{
  cmd = { "sqls", "-config", vim.fn.expand("~/.config/sqls/config.yml") },
  on_attach = function(client, bufnr)
    require("sqls").on_attach(client, bufnr)
  end,
}
```

---

## Secrets Management (Both)

```lua
-- Use sops + age for encrypted connection files
-- dadbod-ui: connections.json can be sops-encrypted
-- dbee: supports age encryption natively
```

```bash
# Encrypt connections
sops --age age1... --encrypt ~/.config/db_ui/connections.json > ~/.config/db_ui/connections.json.enc
# Decrypt on load (via shell wrapper or chezmoi)
```

---

## Mobile/Remote Access

| Method | dadbod-ui | nvim-dbee |
|--------|-----------|-----------|
| **SSH + Mosh** | ✅ Full UI in zellij pane | ✅ Full UI in zellij pane |
| **Zellij web client** | ⚠️ Limited (terminal UI) | ⚠️ Limited |
| **VS Code Remote** | ✅ Works (with dadbod-vscode) | ❌ No VS Code ext |

---

## Migration Path

Both approaches use the **same sqls LSP**. Switching UI layer:
1. Disable one plugin, enable the other
2. Reconfigure connections (different format)
3. sqls config (sqls.yml) works for both

No lock-in on the LSP layer.