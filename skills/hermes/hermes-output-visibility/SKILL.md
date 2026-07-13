---
name: hermes-output-visibility
description: "Configure Hermes Agent for maximum output visibility — control what you see, how you see it, and why responses get truncated. Covers CLI, TUI, and gateway platforms."
version: 1.1.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [hermes, display, output, truncation, verbose, visibility]
    related_skills: [hermes-agent, cost-performance-tuning]
---

# Hermes Output Visibility

Configure Hermes Agent to show **full, untruncated responses** — and understand the three independent systems that can clip your output.

## When This Skill Activates

- User asks "why did your response stop mid-sentence?"
- User says "I can't see the full output" / "it froze / cut off"
- User asks how to see tool output / tool progress / what the agent is doing
- User wants to configure verbosity / show more or less output
- User asks about truncation, streaming, compact mode, or `/verbose`
- User keeps seeing ⚠️ **File-mutation verifier** footer at the end of turns
- User says "stop showing me this warning / footer" about a display feature

## The Three Truncation Systems

Hermes has **three independent systems** that can truncate what you see. Fix them separately:

### 1. Display Mode (what the CLI/TUI shows you)

| Setting | Default | Effect |
|---------|---------|--------|
| `display.tool_progress` | `"all"` | How much tool output is shown: `off` (nothing) → `new` (only new) → `all` (everything) → `verbose` (full args + results) |
| `display.compact` | `false` | When `true`, strips non-essential formatting, saving scroll space but losing some verbosity |
| `display.streaming` | `false` | When `true`, responses appear token-by-token (feels faster but final response still completes) |
| `display.final_response_markdown` | `"strip"` | Controls markdown rendering: `"strip"` (plain text), `"render"` (formatted), `"raw"` (source) |

**Quick fix:** cycle through tool progress levels in-session with `/verbose`. Each press goes: `off → new → all → verbose`.

**Permanent config:**
```yaml
display:
  tool_progress: "verbose"    # show full tool output
  compact: false              # don't compact
  streaming: false            # wait for full response
  final_response_markdown: "render"  # keep formatting
```

```bash
hermes config set display.tool_progress verbose
hermes config set display.compact false
hermes config set display.streaming false
hermes config set display.final_response_markdown render
```

### 2. Context Compression (old conversation gets summarized)

When `compression.enabled: true` (default), Hermes summarizes old messages to stay within the model's context window. This can make earlier parts of a long conversation look truncted — they've been replaced by a summary.

```yaml
compression:
  enabled: true          # set false to never compress
  threshold: 0.50       # compress when context is 50% full
  target_ratio: 0.20    # keep 20% as recent tail
```

```bash
# Turn it off entirely:
hermes config set compression.enabled false

# Or make it less aggressive:
hermes config set compression.threshold 0.65   # compress later (at 65%)
hermes config set compression.target_ratio 0.30  # keep more (30% of tail)
hermes config set compression.protect_last_n 25  # keep last 25 messages verbatim
```

### 3. Tool Output Caps (how much tool output enters context)

These control how much raw terminal/file output the agent can see, not what's displayed to you — but they indirectly limit what the model can tell you about.

```yaml
tool_output:
  max_bytes: 50000       # cap on terminal output characters
  max_lines: 2000        # cap on file read lines
  max_line_length: 2000  # cap on per-line characters
```

```bash
hermes config set tool_output.max_bytes 100000  # raise for coding sessions
hermes config set tool_output.max_lines 5000
```

> **Important:** These caps affect the MODEL, not the display. Raising them means more context per turn (more tokens, higher cost). Lowering them saves tokens but the model sees less.

### 4. Provider Credits Notice (Grant / Usage Balance)

At session start, the Nous provider prints your prepaid grant balance:

```
• Grant spent · $6.55 top-up left
```

This prints when `display.credits_notices: true` (default). To suppress it:

```bash
hermes config set display.credits_notices false
```

The toggle affects **all sessions** (default + all profiles) since credentials are shared. Takes effect on next `/reset` or restart.

### 5. File-Mutation Verifier Footer

Hermes appends a ⚠️ footer when a file-modification tool (patch, write_file) in the current turn returned a result that **might** not have landed — the tool completed but the output didn't prove the write took effect (e.g. a path error, a silent skip, or ambiguous output).

**When it's useful:**
- Catches cases where the agent says "patched!" but the tool actually failed (bad path, permissions, timeout)
- Safety net for unattended runs (cron jobs, background agents)
- Helps surface platform-specific issues (path resolution, filesystem quirks)

**When to disable it (`false`):**
- You're actively supervising — you catch failures by reading tool output yourself
- Frequent false positives from Windows double-path resolution (see Pitfalls)
- The footer noise outweighs its signal in your workflow

```bash
# Disable the verifier footer permanently
hermes config set display.file_mutation_verifier false

# Re-enable if you start running unattended cron jobs
hermes config set display.file_mutation_verifier true
```

> **Note:** The verifier itself still runs internally — disabling it only suppresses the user-visible footer. If you ever want to check whether a file write was silently dropped, call `read_file` on the target to confirm the content changed.

## Platform-Specific Behavior

### CLI (hermes chat)
- **No truncation** of final responses — text wraps in the terminal
- **But** terminal scrollback is limited by your terminal emulator (increase buffer in settings)
- **Piping** to `less` or `more` adds paging
- **TUI** (`/skin` themes) may render long responses differently — can pause on long blocks

### TUI (hermes, full-screen mode)
- **Split-panel UI** — response panel has its own scroll area
- **PgUp/PgDown** to scroll within the response panel
- **/clear** to reset the screen
- **/redraw** to force a full repaint if the UI gets confused

### Gateway (Telegram, Discord, Slack, etc.)
- **Platform message length limits** — Telegram: 4096 chars, Discord: 2000 chars, Slack: 40K chars
- Hermes auto-splits long messages into chunks, but very long responses may be cut
- **Streaming** helps on Telegram (native draft) but hurts on Discord (edit-based jank)
- **/verbose** may not work on all platforms — set `tool_progress_command` in gateway config

### Discord: Native Markdown Formatting

On Discord, always use **Discord-native markdown** — never code blocks for tables, never raw asterisks for formatting that Discord can render natively.

| Format | Syntax | Notes |
|--------|--------|-------|
| Tables | `\| Col1 \| Col2 \|` with `\|---\|---\|` separator row | Do NOT put `**bold**` inside table cells — Discord ignores markdown inside pipe tables. The `---|---` separator auto-bolds the header row. |
| Bold | `**text**` | Works everywhere except inside pipe tables |
| Italic | `*text*` | Standard |
| Underline | `__text__` | Discord-specific |
| Strikethrough | `~~text~~` | Standard |
| Spoiler | `\|\|text\|\|` | Discord-specific |
| Blockquote | `> text` or `>>> ` for multi-line | Standard |
| Code block | \`\`\`language\\ncode\\n\`\`\` | Always tag the language |
| Inline code | \`code\` | Standard |
| Task list | `- [ ] todo` / `- [x] done` | Discord supports this |
| Link | `[text](url)` | Standard |
| Horizontal rule | `***` | Standard |

**Key pitfalls:**
- **No markdown formatting inside pipe tables.** Bold, italic, code, etc. inside table cells render as raw asterisks/backticks. Headers auto-bold via the `---|---` separator.
- **Code blocks** are the fallback for very wide tables or data that needs strict monospace — use native pipe tables by default.
- **Discord strips trailing whitespace** — don't rely on space-padding for alignment outside code blocks.

### WebUI / Dashboard
- Standard HTML rendering — no character truncation
- Long responses scroll naturally in the chat pane

## Quick Reference

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| "You just stopped after ## Entities" | Response too long for display mode | Check scrollback or switch display mode |
| "Output kept getting shorter" / "Old messages are gone" | Context compression is on | `hermes config set compression.enabled false` |
| "I can't see the tool calls, just the final answer" | `display.tool_progress` is too low | `/verbose` or set to `"all"` or `"verbose"` |
| "Text appears character by character" | Streaming is on | `hermes config set display.streaming false` |
| "My terminal has the output but I can't scroll up to it" | Terminal scrollback too small | Increase terminal buffer size in settings |
| "Telegram says message too long" / message got cut | Platform message length limit | Hermes auto-splits but very long messages hit platform caps |
| "Tool output is cut off mid-way" | `tool_output.max_bytes` too low | `hermes config set tool_output.max_bytes 100000` |
| "Grant spent · $6.55 top-up left" at session start | `display.credits_notices: true` | `hermes config set display.credits_notices false` |

## Pitfalls

- **Compression off means more tokens.** Disabling compression means every message stays verbatim forever. Long sessions will hit the model's context window and fail. Turn compression off only when you keep sessions very short or use models with 128K+ context.
- **`display.tool_progress: verbose` adds overhead.** Every tool's full args and results are shown, which can be noisy. Good for debugging, switch back to `"all"` for normal use.
- **`display.streaming` and `streaming.enabled` are two different switches.** The first controls CLI/TUI/dashboard streaming; the second controls the HTTP/protocol layer. Set both for gateway streaming.
- **Platform truncation is unavoidable.** If you need very long output on a messaging platform, redirect to a file or use the API server.
- **MSYS path double-resolution can trigger the file-mutation verifier on Windows.** When using MSYS-style `/c/Users/...` paths (from git-bash) with file tools, Hermes may resolve them as `C:\c\Users\...` — doubling the drive letter prefix. The file write silently fails or lands elsewhere, and the verifier flags the mismatch. Always use native `C:\Users\...` or forward-slash `C:/Users/...` paths in file tools on Windows. See `references/msys-path-double-resolution.md` for the full diagnostic.
- **Config changes need `/reset`.** Display and compression settings are loaded once at session start. `/reset` or restart the CLI/gateway for changes to take effect.
