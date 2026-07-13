# Context File Ecosystem

> The four file types that define agent behavior, where they live, and how they layer.
> Relevant when: authoring a persona (SOUL.md) and the user asks how it relates to project-level config files.

## The Prompt Stack (highest leverage first)

```
1. Hermes system prompt  →  core agent loop (do not edit)
2. SOUL.md               →  global agent identity
3. MEMORY.md / USER.md   →  learned facts (persistent memory)
4. AGENTS.md             →  global operational protocol
5. CLAUDE.md /.hermes.md →  per-project context (discovered from CWD)
6. Session context       →  chat history
```

Each file sits at a specific layer. Higher = near the top of the system prompt = more influence per token.

---

## File-by-File Reference

### 1. SOUL.md — Agent Identity

| Attribute | Value |
|-----------|-------|
| **Slot** | #1 in system prompt (right after core loop) |
| **Location** | `~/.hermes/SOUL.md` or `~/.hermes/profiles/<name>/SOUL.md` |
| **Scope** | Global — every session, every project |
| **Purpose** | Who the agent IS. Personality, voice, behavioral rules, values, guardrails. |
| **Discoverers** | Hermes Agent (`prompt_builder.py`), OpenClaw |
| **Format** | YAML frontmatter (optional) + markdown body |
| **Token budget** | ~50 lines / ~400 tokens ideal. Loaded EVERY turn — aggressive compression essential. |

**What goes in vs what stays out:**

| SOUL.md (identity) | Not for SOUL.md |
|--------------------|-----------------|
| Core values & ethics | Coding conventions |
| Communication style | Framework preferences |
| Behavioral guardrails | CI/CD instructions |
| Autonomy boundaries | Per-project constraints |
| Voice & cadence rules | Build commands |

---

### 2. AGENTS.md — Operational Protocol

| Attribute | Value |
|-----------|-------|
| **Slot** | Project context (after SOUL.md, before session chat) |
| **Location** | `~/.hermes/AGENTS.md` or git repo root |
| **Scope** | Global or per-project — auto-discovered from CWD |
| **Purpose** | How the agent WORKS. Tool discipline, dispatch rules, communication protocol, failure mode. |
| **Discoverers** | Hermes Agent (`prompt_builder.py` alongside SOUL.md) |
| **Format** | Plain markdown (no frontmatter) |

AGENTS.md is the operational counterpart to SOUL.md. SOUL.md says who the agent IS — AGENTS.md says how it EXECUTES. Think of it as the agent's internal operating manual.

Common sections:
- Tool discipline (read-before-write, batch parallel calls)
- Dispatch table (what to keep vs delegate to specialists)
- Communication protocol (status updates, error format, summary style)
- Failure mode triage

---

### 3. CLAUDE.md — Project Constitution

| Attribute | Value |
|-----------|-------|
| **Slot** | Project context — discovered via CWD-to-git-root walk |
| **Location** | Git repo root (or subdirectories for nested scope) |
| **Scope** | Per-project — version-controlled with the codebase |
| **Purpose** | What the PROJECT expects. Code style, testing, architecture, deployment. |
| **Discoverers** | Claude Code (originator), OpenClaw, Hermes Agent (as fallback) |
| **Format** | Plain markdown (no frontmatter) |

**The pattern (cloned by many):**
- `.cursorrules` — Cursor (JSON or markdown)
- `.windsurfrules` — Windsurf
- `CLAUDE.md` — Claude Code (gold standard)
- All three are discovered and loaded by Hermes Agent's `prompt_builder.py`

**Nested override rule:** A CLAUDE.md in a subdirectory extends/replaces parent rules. Most specific wins.

---

### 4. .hermes.md — Hermes Project Config

| Attribute | Value |
|-----------|-------|
| **Slot** | Project context — same slot as CLAUDE.md |
| **Location** | Git repo root (`<root>/.hermes.md` or `<root>/HERMES.md`) |
| **Scope** | Per-project with nested override (subdirectories) |
| **Purpose** | Same as CLAUDE.md but Hermes-native. Adds YAML frontmatter for structured config, `.hermesignore` support. |
| **Discoverers** | Hermes Agent (PR #1712, implemented in prompt_builder.py) |
| **Format** | YAML frontmatter (optional, structured) + markdown body |

**What .hermes.md can do that CLAUDE.md can't:**
- YAML frontmatter: `model:`, `personality:`, `tools: disabled: [...]`
- `.hermesignore` companion file (same syntax as `.gitignore`)
- Model/toolset override per-repo

**Discovery order:**
1. `.hermes.md` in CWD
2. `HERMES.md` in CWD
3. Walk parent directories up to git root
4. Nested configs extend/override parents

---

## Which File to Use When

| Situation | File | Why |
|-----------|------|-----|
| Creating a new agent persona | SOUL.md | Defines identity and voice |
| Setting global operational rules | AGENTS.md | Tool discipline, dispatch, comms |
| Documenting a project's code conventions | CLAUDE.md | Universal — every agent CLI reads it |
| Pinning a specific model per repo | .hermes.md | YAML frontmatter supports model override |
| Disabling tools per project | .hermes.md | `tools: disabled:` in frontmatter |
| Quick per-repo rules without frontmatter | CLAUDE.md | Simpler format, broader compatibility |

---

## Quick Comparison Table

| | SOUL.md | AGENTS.md | CLAUDE.md | .hermes.md |
|---|---|---|---|---|
| **Scope** | Global (agent) | Global/Project | Per-project | Per-project |
| **Owned by** | Agent user | Agent user | Project team | Project team |
| **Version-controlled** | No (personal) | No / Optional | Yes | Yes |
| **Frontmatter** | Optional | No | No | Yes (structured) |
| **Prompt slot** | #1 — highest leverage | Project context | Project context | Project context |
| **Token cost** | Every turn | When discovered | When discovered | When discovered |
| **Hermes loads it?** | Yes | Yes | Yes | Yes |
| **Claude Code loads it?** | No | No | Yes | No |
| **OpenClaw loads it?** | Yes | Yes | Fallback | No |

---

## Templates

Starter templates for all four file types are at:

```
C:/Hermes-Vault/templates/
  ├── soul.md           → agent identity (144 lines, comprehensive + quick-start)
  ├── agents.md         → operational protocol (130 lines, includes dispatch table)
  ├── claude.md         → project constitution (201 lines, includes minimal quick-start)
  └── hermes.md         → Hermes project config (208 lines, with YAML frontmatter)
```

Each template includes a **HOW TO USE** section, ✅ good / ❌ weak examples alongside every placeholder, a ⚡ Quick-Start minimal version (~20 lines) that can be shipped in 2 minutes, and decision guidance for which sections to keep vs delete.

**Vault visibility note:** Files in `C:/Hermes-Vault/` must use `.md` extension — Obsidian only renders `.md` files in its file explorer. Never use `.template` or other extensions for vault files.

Copy the relevant `.md` to the target location, fill in the placeholders, and delete unused sections.
