# Teknium's Development Setup

**Who**: Cofounder & Lead Engineer of Nous Research (Hermes Agent), previously @StabilityAI  
**X/Twitter**: @Teknium  
**Sources**: Direct X posts (Feb–June 2026), screenshot of active session (June 11, 2026)

## The Full Timeline

### Before Nous — JetBrains (pre-2025)
Teknium used JetBrains during his earlier career. This is mentioned in retrospect — he was a traditional IDE user before building Hermes.

> *"codex didn't have a plugin for jetbrains which is what i was using"*
> — [@Teknium, Feb 2026](https://x.com/Teknium/status/1968338197169221873)

### Agentic Coding Shootout (Feb 2026)
He ran a direct comparison of the three main agentic coding tools and declared a winner:

> *"Guys between claude code, codex and cursor there's a clear winner. Cursor lets me inspect and deal with each change much cleaner and faster than cc and codex didnt have a plugin for jetbrains which is what i was using."*
> — [@Teknium, Feb 2026](https://x.com/Teknium/status/1968338197169221873)

| Tool | Verdict |
|---|---|
| **Cursor** | Winner — cleanest change inspection, fastest workflow |
| **Claude Code** | Works, but change management is worse |
| **Codex (OpenAI)** | Lost by default (no JetBrains plugin at the time) |

### Current Day — Hermes Agent in VS Code (June 2026)
Teknium dogs his own product as his primary development environment. He runs Hermes inside **VS Code's integrated terminal** on a remote SSH session (host `tekniium-dev`).

> *"This is my IDE experience with Hermes right now, though, one day I'll probably switch to ACP version with VSCode or Zed."*
> — [@Teknium, June 2026](https://x.com/Teknium/status/2062826652640649292)

He also keeps other agents handy:
> *"(and claude code, I used in the terminal - also tried cursor in their CLI thing)"*
> — [@Teknium, June 2026](https://x.com/Teknium/status/2062826440396300336)

**Observed (screenshot, June 11, 2026)**: VS Code Dark+ theme, remote SSH to `tekniium-dev`, working dir `~/.hermes/hermes-agent`, running `hermes -w` in the integrated terminal performing a PR review. A Hermes gateway startup error notification is visible — confirming he uses VS Code[+Hermes] for troubleshooting Hermes itself.

### Looking Ahead — Zed via ACP (future)
VS Code already works as his editor canvas (via integrated terminal). He specifically wants **native ACP integration** — where Hermes can control editors, show diffs inline, and manage files directly — rather than just running Hermes in a terminal pane. Zed already supports this; VS Code / JetBrains / Neovim support is tracked.

## The Layered Stack

```
┌──────────────────────────────────────────────────┐
│              PRIMARY ORCHESTRATOR                │
│              Hermes Agent (TUI/CLI)              │
│   "This is my IDE experience with Hermes"        │
├──────────────────────────────────────────────────┤
│               EDITOR CANVAS                      │
│       VS Code (integrated terminal + SSH)        │
│    file explorer · editor pane · diffs           │
├──────────────────────────────────────────────────┤
│           SECONDARY AGENTS (terminal)            │
│          Cursor CLI · Claude Code CLI            │
│     "I also used in the terminal"                │
├──────────────────────────────────────────────────┤
│          EDITOR FRONTEND (under evaluation)      │
│              Zed (via native ACP)                │
│     "one day I'll switch to ACP version"         │
└──────────────────────────────────────────────────┘
```

## Key Takeaway

Teknium doesn't have one editor. He has a **layered agent workflow**:

- **Hermes** (in VS Code terminal) → heavy lifting: refactors, PRs, complex changes
- **VS Code** → editor canvas: file explorer, diffs, viewing files Hermes touches
- **Cursor CLI** → surgical changes with diff-by-diff review
- **Claude Code** → alternative agent for different model/approach
- **Zed** → (future) alternative frontend via native ACP

The agent is the center. The editor is just the window.
