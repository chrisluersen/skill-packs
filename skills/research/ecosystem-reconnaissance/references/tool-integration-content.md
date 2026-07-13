# Tool Integration Content: Zellij Worked Example

Compiled: June 2026
Source: https://zellij.dev/documentation/ (programmatic-control, creating-a-layout, cli-recipes)
Target document: `AI Architecture.html` (§03 — Runtimes & Profiles)

---

## Workflow Summary

This session followed the Phase 2d → Phase 5 pipeline:
1. **Phase 2d**: Crawled Zellij's official docs (not GitHub) for integration patterns
2. **Phase 5**: Created code-block HTML, comparison tables, and install snippets
3. **Inserted into** §03 of `AI Architecture.html` via two `patch()` calls

---

## Phase 2d: Official Docs Research (Zellij)

### Docs pages consulted

| URL | What it yielded |
|-----|----------------|
| `zellij.dev/features/` | Feature overview, native Windows, web client, floating panes, plugins |
| `zellij.dev/documentation/programmatic-control.html` | 70+ CLI actions, `zellij action new-pane`, `attach --create-background`, `subscribe --format json`, `--block-until-exit-success` |
| `zellij.dev/documentation/creating-a-layout.html` | KDL layout format: pane, tab, pane split_direction, command/args, plugin, close_on_exit |
| `zellij.dev/documentation/cli-recipes.html` | Multi-pane sessions, headless CI, session resurrection, edit scrollback |

### Key facts extracted for integration content

- **Windows**: Native binary via `winget install Zellij.Zellij`, no WSL needed
- **Layout format**: KDL (declarative, similar to Nix or HCL)
- **Programmatic**: `zellij action new-pane -- hermes --profile deep` spawns a pane running a Hermes agent
- **Headless**: `zellij attach --create-background <session>` — creates a session without attaching
- **Streaming**: `zellij subscribe --format json` streams pane output as JSON
- **Blocking**: `--block-until-exit-success` — pane exits only when command succeeds (CI pattern)
- **Web**: `zellij --server <address>` — built-in web client, no extra tools
- **Panic**: `Ctrl+Shift+P` — reset or quit stuck commands (unique vs tmux)
- **Plugins**: WASM-based, Rust SDK with 120+ commands

---

## Phase 5: Content Created

### 1. Integration scenarios table

Generated 6 rows in `<div class="tw"><table><thead><tbody>` format.
Each row: scenario name + actionable `code` approach.

Example row:
```html
<tr><td>Multi-agent workspace</td><td>Open Hermes in split panes — one per profile/context. <code>zellij action new-pane -- hermes --profile deep</code></td></tr>
```

### 2. KDL layout file

3-tab workspace with:
- **Hermes tab** (focused): vertical split — 50% Hermes TUI + 50% horizontal log/config watch
- **Terminal tab**: 60/40 vertical split with htop
- **Logs tab**: `tail -f` on Hermes log files

Saved as `~/.config/zellij/layouts/hermes.kdl`.

Styling note: code blocks use `.cb-header > .cb-dot.green + .cb-lang` for config files, `.cb-dot.purple` for scripts. Comments use `<span class="c-com">`.

### 3. Bash script: parallel multi-agent runner

Launches 3 agents (research, coding, review) in a single background Zellij session, then attaches to see all three.

```bash
SESSION="hermes-agents"
zellij attach --create-background "$SESSION"
zellij --session "$SESSION" action new-pane --name "research" \
    -- hermes --profile deep "analyze latest AI papers on agentic frameworks"
zellij --session "$SESSION" action new-pane --name "coding" \
    -- hermes --profile fast "refactor the auth module"
zellij attach "$SESSION"
```

### 4. Zellij vs tmux comparison table

13 features compared side-by-side:

| Feature | Zellij | tmux |
|---------|--------|------|
| Windows support | ✅ Native binary | ⚠️ WSL/Cygwin only |
| Web client | ✅ Built-in | ❌ Third-party |
| Floating panes | ✅ Native | ❌ (workarounds: tmux popup) |
| Programmatic API | ✅ 70+ CLI actions, JSON subscribe | ⚠️ send-keys only |
| Layouts | ✅ KDL declarative | ✅ Shell-scripted |
| Headless mode | ✅ attach --create-background | ✅ new-session -d |
| Plugin system | ✅ WASM (Rust SDK) | ❌ |
| Blocking panes | ✅ --block-until-exit-success | ⚠️ Manual loops |
| Panic/rescue | ✅ Ctrl+Shift+P | ❌ |
| Session resurrection | ✅ Auto-save/restore | ⚠️ Via tmux-resurrect |
| JSON output | ✅ Full structured | ❌ Format-only |
| Config format | KDL (clean) | Shell-based (set -g) |
| Origin | Rust, single binary | C, POSIX classic |

### 5. Quick install

```bash
winget install Zellij.Zellij
zellij --version
zellij
```

### 6. Table cross-reference update

The existing "Running Strategies" table in §03 referenced `tmux` for "Multiple parallel agents" and "Remote box (SSH)". Updated both to `zellij / tmux`.

---

## Context for Reproducing

If a future session needs to add a similar tool integration to `AI Architecture.html`:

1. **Find the insertion point**: The section-nav block before `</section>` at the end of the target section
2. **Use two patches**: One for any cross-reference updates in existing tables, one for the new subsection content
3. **Verify**: `grep -c 'Zellij'` for word count, spot-check section-nav links survived
4. **Backup**: Copy to OneDrive only after ALL changes are verified

---

## Pitfalls Encountered

- **HTML code blocks with KDL syntax**: KDL uses `{` and `}` which look like template literals. Must escape as regular text or use `<div class="cb-body">` to wrap them as verbatim.
- **Unicode in grep on MSYS**: Emoji characters like 🦎 produce `grep -c` returns 0 even when present. Use `search_files` instead.
- **Local-first workflow**: Edit `~/AppData/Local/hermes\AI Architecture.html`, copy to OneDrive only after all changes. This avoids sync corruption from intermediate writes.
