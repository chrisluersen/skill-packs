# Stack Decision Log

Documenting key architectural decisions for the AI terminal stack. Created: 2026-06-18

## 1. Multiplexer: zellij over tmux

**Decision:** zellij

**Rationale:**
- Native Windows support (Cargo/Scoop) — no WSL required for multiplexer itself
- Modern keybindings (Ctrl+p prefix, vim navigation) vs tmux's C-b/C-a prefix
- Built-in layouts, session resurrection, WASM plugin system
- Web client (v0.43+) enables browser-based remote access
- Mouse-first design works out of the box
- Cleaner config (KDL vs tmux's custom DSL)
- Active development, Rust-based performance

**Trade-offs accepted:**
- Younger ecosystem (4 years vs 15+)
- Fewer third-party plugins (but WASM plugins growing)
- Some tmux muscle memory doesn't transfer

**Rejected:** tmux — WSL-only, steeper learning curve, no web client, legacy config

## 2. Editor: Neovim over VS Code / Zed

**Decision:** Neovim (with lazy.nvim)

**Rationale:**
- **Raw performance:** <50ms startup, ~30-50MB memory (vs 500MB-1GB for VS Code)
- **Persistence:** Runs inside zellij — sessions survive reboots, SSH drops, crashes
- **Keyboard-first:** Modal editing pays compounding dividends over decades
- **Extensibility:** Lua plugin API, infinite customization
- **AI coding:** avante.nvim, claude-code, aider all work in terminal
- **Runs everywhere:** SSH, containers, remote servers, phone (via SSH/Mosh)

**Trade-offs accepted:**
- Steep learning curve (modal editing + plugin config)
- No built-in debugger UI (requires nvim-dap config)
- No native collaborative editing (requires plugins)
- Setup time investment (hours vs minutes)

**Rejected:**
- VS Code — Electron overhead, no session persistence, mouse-dependent workflows
- Zed — Fast but no session persistence, smaller extension ecosystem, tied to single vendor

**Hybrid option kept open:** zellij for persistent shells/herm + VS Code/Zed for editing (if Neovim proves too steep)

## 3. Hermes Dashboard: herm (liftaris/herm)

**Decision:** herm TUI inside zellij

**Rationale:**
- Purpose-built for Hermes Agent (chat, tools, sessions, config)
- OpenTUI (React/Solid) — modern TUI framework
- Runs in zellij pane — persistent, side-by-side with Neovim
- Active development by Hermes community member

**Trade-offs accepted:**
- Alpha/early stage — breaking changes expected
- Build from source currently (not on crates.io)
- Limited to Hermes workflows (not a general terminal tool)

## 4. Database UI: **dadbod-ui + sqls** ⭐ LOCKED AS DEFAULT

**Decision:** dadbod-ui + sqls (Approach 1)

**Rationale:**
- **User explicitly requested Approach 1 be locked in** — production reliability over alpha performance
- **Stability + features:** Proven (5+ years), complete DB support, schema browser, query history, saved queries, CSV/JSON export
- **Same LSP layer:** sqls provides autocomplete/hover/goto for both options
- **Team sharing:** Mature, well-understood, config via connections.json

**Trade-offs accepted:**
- Requires CLI tools: `psql`, `mysql`, `sqlite3` (easy on WSL)
- VimScript core has some legacy quirks

**Fallback available:** nvim-dbee + sqls (if performance becomes critical and breaking changes stabilize)

**Rejected:** sqls only — no visual schema browser, no query history UI

## 5. Remote Access: Tailscale + SSH/Mosh (primary), Zellij Web Client (secondary)

**Decision:** Tailscale SSH + Mosh via Blink Shell (iOS) / Termux (Android)

**Rationale:**
- **Best coding UX:** Native terminal app > browser terminal
- **Mosh:** Survives IP changes, roaming, sleep/wake, high latency
- **Tailscale SSH:** Zero key management, device-based auth
- **Blink Shell/Termux:** Best-in-class mobile terminal apps
- **Zellij attach:** Full persistent session on phone

**Secondary:** Zellij Web Client via `tailscale serve` — browser access when no SSH app

**Tertiary:** Hermes Gateway API exposure — for AI apps on phone

**Rejected:** Raw SSH keys (Tailscale SSH simpler), VPN-only (Tailscale handles NAT traversal)

## 6. File Manager: yazi

**Decision:** yazi

**Rationale:**
- Async, non-blocking UI
- Image/video previews in terminal
- Vim keybindings
- Plugin system
- Written in Rust, fast

**Rejected:** ranger (slower, Python), nnn (less features), lf (less maintained), nvim-tree (redundant with yazi)

## 6. Git TUI: lazygit

**Decision:** lazygit

**Rationale:**
- De facto standard for terminal Git UIs
- Staging, rebasing, diffs, logs, conflict resolution
- Single binary, no config needed
- Integrates with Neovim via lazygit.nvim

## 7. Process Monitor: btop

**Decision:** btop

**Rationale:**
- GPU graphs, mouse support, beautiful UI
- C++ (fast), cross-platform
- Better than htop/gtop for visual monitoring

## 8. Shell: zsh (with minimal config)

**Decision:** zsh over fish/nu

**Rationale:**
- Ubiquitous, POSIX-compatible
- fzf integration mature
- Direnv support
- Team compatibility

## 9. Dotfiles: chezmoi

**Decision:** chezmoi

**Rationale:**
- Template support (machine-specific configs)
- Encrypted secrets (age/sops)
- Cross-platform (Windows/macOS/Linux)
- Git-based, declarative

## 10. Secrets: sops + age

**Decision:** sops + age

**Rationale:**
- Age: modern, simple encryption (no GPG complexity)
- sops: encrypts specific fields in YAML/JSON/ENV files
- Works with chezmoi, git, CI/CD

## Performance Baselines (Target)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Neovim startup | <50ms | `nvim --startuptime log` |
| Zellij startup | <100ms | `time zellij` |
| Full stack (zellij + nvim + herm) | <200ms | Manual |
| Memory (idle) | <100MB | `ps aux` |
| Mosh reconnect | <2s | Network change test |

## Decision Review Triggers

Revisit decisions when:
- [ ] Neovim learning curve blocks productivity for >2 weeks → consider Zed hybrid
- [ ] nvim-dbee breaking changes disrupt workflow → migrate to dadbod-ui
- [ ] Herm becomes stable on crates.io → simplify install
- [ ] Zellij web client UX improves significantly → may replace SSH for phone
- [ ] Tailscale funnel/serve GA → simplify HTTPS cert management