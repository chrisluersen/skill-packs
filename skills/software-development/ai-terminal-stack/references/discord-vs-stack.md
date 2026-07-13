# Discord + Hermes vs AI Terminal Stack — Complementary Roles

Research conducted: 2026-06-18
Sources: Hermes Discord integration docs, stack architecture analysis

---

## The Core Distinction

| Dimension | **Discord + Hermes** | **zellij/neovim/herm Stack** |
|-----------|----------------------|------------------------------|
| **Primary Role** | Communication, notifications, async chat | **Active development environment** |
| **Interface** | Discord client (GUI, mobile, web) | Terminal (zellij + neovim + herm TUI) |
| **Latency** | Message-based, async | Real-time, local, sub-ms |
| **Persistence** | Discord servers (cloud) | Local sessions (zellij), files (git) |
| **AI Access** | Hermes via Discord messages | Hermes via herm TUI + CLI agents |
| **Context** | Conversational, threaded | Code-aware, file-aware, project-aware |
| **Mobile** | Native Discord app (excellent) | Tailscale + Mosh/Blink/Zellij web |
| **Collaboration** | Multi-user, threads, mentions | Single-user (tmux/zellij pairing possible) |

---

## How They Work Together

### Discord + Hermes: "The Notification & Chat Layer"

```
You (phone/desktop) → Discord → Hermes Bot → Hermes Agent → Tools → Response → Discord
```

- **Ask quick questions** without opening terminal
- **Get notifications** when long tasks complete
- **Share context** with team members via threads
- **Review history** in Discord search
- **Mobile-first** — always in pocket

### zellij/neovim/herm Stack: "The Development Layer"

```
You (terminal) → zellij → panes: [neovim] [herm] [shell] [lazygit] [btop]
```

- **Write code** with full editor power (LSP, refactoring, git)
- **Run AI agents** in dedicated panes (claude-code, aider, opencode, herm)
- **Persist sessions** across reboots, network changes
- **Full terminal tools** (btop, yazi, lazydocker, databases)
- **Local-first, zero latency**, works offline

---

## Mobile Comparison

| Scenario | Discord + Hermes | zellij/neovim/herm (Tailscale) |
|----------|------------------|--------------------------------|
| **"Hey Hermes, what's the status?"** | ✅ Discord message, instant | ❌ Need terminal app |
| **"Fix this bug in auth.ts"** | ❌ No code context | ✅ neovim + LSP + AI agent |
| **"Run tests and tell me results"** | ✅ Hermes can run tools | ✅ Full shell + test output |
| **"Review this PR"** | ✅ Discord thread + links | ✅ neovim + fugitive + diff |
| **"Quick config change"** | ✅ Hermes tools | ✅ neovim + herm pane |
| **Long coding session (30min+)** | ❌ Painful on phone | ✅ Blink/Mosh + real keys |

---

## Recommended Workflow: Both Together

### Daily Driver (Desktop/Laptop)

```
┌─────────────────────────────────────────────────────────────┐
│  zellij session "main"                                      │
│  ├─ Tab 1: neovim (70%) + shell (30%) — CODING             │
│  ├─ Tab 2: herm (full) — Hermes chat, tools, sessions      │
│  ├─ Tab 3: lazygit — Git workflow                           │
│  └─ Tab 4: lazydocker / btop — Infrastructure              │
└─────────────────────────────────────────────────────────────┘
```

### Mobile (Phone)

```
┌─────────────────────────────────────────────────────────────┐
│  Discord app                                                │
│  ├─ DM with Hermes Bot — Quick questions, notifications    │
│  ├─ #dev channel — Team context, PR links                  │
│  └─ Threads — Long-running task tracking                   │
│                                                             │
│  Blink Shell / Termux (when needed)                        │
│  └─ mosh → zellij attach main — Full dev environment       │
└─────────────────────────────────────────────────────────────┘
```

### Integration Points

| Event | Discord Action | Stack Action |
|-------|----------------|--------------|
| **Deploy fails** | Hermes posts to #alerts | You open Blink → zellij → fix |
| **PR review needed** | Bot mentions you in thread | You `gh pr view` in stack shell |
| **Long build done** | Hermes DMs "build passed" | You `zellij attach` to see logs |
| **Quick question** | "Hey Hermes, explain X" | Alt-tab to herm pane, ask |
| **Config change** | Hermes updates via tool | You verify in neovim + reload |

---

## Technical Integration

### Hermes Config (Discord)

```yaml
# ~/.config/hermes/config.yaml
discord:
  enabled: true
  bot_token: "${DISCORD_BOT_TOKEN}"
  app_id: "${DISCORD_APP_ID}"
  public_key: "${DISCORD_PUBLIC_KEY}"
  allowed_channels:
    - "1234567890"  # #dev channel
    - "0987654321"  # #alerts channel
  dm_enabled: true
  mention_trigger: true
  slash_commands: true
```

### Hermes Config (Gateway for Stack)

```yaml
# Same config — gateway serves the stack
gateway:
  enabled: true
  host: "0.0.0.0"
  port: 8319
dashboard:
  enabled: true
  host: "0.0.0.0"
  port: 8080
```

### Herm (TUI in Stack) — Local Hermes Control

```bash
# In zellij herm tab:
herm
# Full Hermes session management, tool invocation, config
```

---

## Decision Matrix: When to Use Which

| Task | Use |
|------|-----|
| "What's the weather in Tokyo?" | Discord DM |
| "Explain this React pattern" | Discord DM or herm pane |
| "Refactor auth module" | **Stack** (neovim + AI agent) |
| "Run test suite" | **Stack** (shell pane) |
| "Check GPU usage" | **Stack** (btop pane) |
| "Team: review this PR" | Discord thread + **Stack** for actual review |
| "Deploy to staging" | Hermes via Discord **or** herm pane |
| "Mobile: quick status check" | Discord |
| "Mobile: fix production bug" | **Stack** via Blink/Mosh |
| "Pair program with teammate" | Discord call + **Stack** (screen share) |

---

## Key Insight

**Discord + Hermes = Asynchronous, conversational, mobile-first, team-visible**

**zellij/neovim/herm = Synchronous, code-aware, local-first, maximum control**

**You need both.** Discord extends Hermes to where you *aren't* at your terminal. The stack is where you *are* when doing real work.

---

## Related Pages

- `ai-terminal-stack` — Main stack documentation
- `references/tailscale-remote-access.md` — Mobile access via Tailscale
- `references/minimal-stack-comparison.md` — Stack alternatives comparison
- `references/database-ui-comparison.md` — Database UI options