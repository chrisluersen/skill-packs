---
title: Reference Document Layout
name: reference-document-layout
description: Design scannable, well-tiered markdown reference documents that present structured information — filesystem layouts, config maps, priority-ordered lists, system anatomies.
category: productivity
created: 2026-06-28
---

# Reference Document Layout

Design markdown reference documents that are **scannable**, **tiered by importance**, and **not visually busy**. Applies when presenting structured information like filesystem layouts, configuration inventories, entity catalogs, or any list of items with attributes and priorities.

## Tier system (standard ordering)

When entries need priority/ownership labels, use this standardized tier system **in this order**:

| Icon | Tier | When to use |
| :--- | :--- | :--- |
| 👑 | **Governance** | Defines identity, rules, schema. The constitution. |
| ⭐ | **Required** | System breaks or is incomplete without this. |
| ✅ | **Default** | Ships standard. Safe to prune intentionally. |
| 📝 | **Personal** | User-authored content. Life context, not system. |
| ⚙️ | **Operational / Extensions** | Support infrastructure or add-on capabilities. |
| 🗄 | **Storage** | Accumulates passively. Archive, trash, WIP. |

Always sort groups in this order within each section. Governance first, Storage last.

## Group size discipline

Aim for **4-8 purpose groups per section**. Fewer than 4 means you're lumping unrelated things. More than 8 means scanning gets harder, not easier. If a group has only 2 entries, consider whether it can merge with an adjacent group before adding a new header.

**Watch out for hybrid groups.** "Archive & Roadmap" mixes passive storage (work/, archive/, trash) with active planning docs (todos, roadmap, changelog). These are different purposes — split them. Similarly, "Wiki Content" that bundles references, cookbook, queries, and raw materials may need splitting if the entries are numerous enough.

## Purpose-named headers, not generic tier names

Section headers inside a tree should describe **what the group IS for**, not just its tier:

```
│  👑 WIKI CONSTITUTION     ← good: describes purpose
│  👑 GOVERNANCE            ← ok but generic
```

The tier icon still signals the priority. The header text tells you why it matters at that tier.

## Edge entries

When documenting a directory, scan for files that don't fit any purpose group:
- **Do-not-touch markers** (`[DNT]✨.md`) — belong in Governance
- **Hidden metadata** (`.wiki.db`, internal databases) — use a `HIDDEN METADATA` footer or comment line at the bottom of the tree
- **The document itself** — if the anatomy doc lives in the directory it documents, add `← YOU ARE HERE` to its entry

## Principles

### 1. Know your user: trees vs tables

A text tree (`├── └──`) is for showing **nesting**. A table is for showing **attributes** (importance, description, owner). **Ask or calibrate early** — this user prefers TUI-style trees for filesystem layouts and anatomy docs. When they say "too busy," simplify the tree (shorter descriptions, section headers), don't switch to a table.

**Tree format (preferred by this user):**

Group entries by purpose using section header lines with tier icons:

```text
│  👑 BOOT CONFIG
├── config.yaml          Master config — providers, models, tools
├── .env                 API keys & secrets — never committed
│
│  ✅ DEFAULT
├── logs/                Runtime diagnostics — auto-rotating
├── cron/                Scheduled job registry
```

Keep descriptions to one line, bold the key phrase. Do NOT add icons to every individual line — section headers handle the tier signal.

**Table format (use when the user asks for it or when nesting is irrelevant):**

| Tier | Entry | What it does |
| :--- | :--- | :--- |
| 👑 | config.yaml | **Master config** — providers, models, tools. Boot-critical. |
| ✅ | logs/ | Runtime diagnostics. Auto-rotating. Safe to prune. |

Tables work when every entry shares the same depth. Trees work when the user needs to see what lives inside what. **Default to trees for filesystem layouts and anatomy docs.**

### 2. Sort by priority, not by location

Group entries by importance/ownership, not by filesystem path or alphabetical order. The reader's first question is "what matters here?", not "what's nested inside what?"

Priority order: Governance → Required → Default → Personal → Operational → Storage.

If nesting matters, put a **plain tree** after the table as an appendix. The table does quick-reference work; the tree satisfies structural curiosity.

### 3. First column = the scannable signal

The leftmost column gets the most eye-fixation. Put the differentiating signal there — tier icon, status badge, owner initial. Not the entry name.

### 4. One-line descriptions, bold the key phrase

Each description is one line max. Bold the 2-3 words that explain **why it matters**. The reader scans the bold, then reads the full line only if they need detail.

| Tier | Entry | What it does |
| :--- | :--- | :--- |
| 👑 | SOUL.md | **Agent persona** — injected slot #1 in system prompt. Defines who the agent IS. |
| ⭐ | state.db | **Continuity-critical** — every conversation lives here. Irreplaceable. |
| 📝 | personal/ | **Your life** — cooking recipes, dog care, wishlists. Human context. |

### 5. One legend, at the bottom

A single key explaining icons. Put it at the bottom so new readers find it after the main content, but it doesn't clutter the top. Icons should be intuitive enough to scan from context.

### 6. Separate scopes with section headers

Two scopes in one document → two trees (or two tables), each with its own heading. Use `---` or `##` between them. Don't merge different scopes into one section.

## When to use

- Filesystem anatomy docs (what lives where, what's important)
- System configuration inventories (config keys, purpose, sensitivity)
- Entity catalogs with importance tiers
- Any markdown document where entries have 2+ attributes and the primary use case is **quick reference**

## When NOT to use

- Procedural/how-to documents — use step-by-step or cookbook format instead
- Diagrams that need spatial/layout relationships — use Excalidraw or architecture-diagram
- Deeply nested structures (15+ levels) — nesting IS the signal, use a tree
- Pure creative or narrative documents

## Pitfalls

- **Per-line icons in trees**: putting `[👑]` or `[⭐]` on each line of a text tree breaks the visual flow. Use **section headers** (`│  👑 PURPOSE NAME`) at the start of each group instead — the reader scans the header for the tier signal, then scans entries for structure.
- **Over-explaining in the primary view**: descriptions should be one line per entry. If an entry needs paragraphs, put them after the tree, not in it.
- **Multiple legends**: one legend per document section. Repeat the legend in multi-section docs so each section is self-contained.
- **Ignoring the "so what"**: a description like "contains configuration files" tells the reader nothing. "**Boot-critical** — defines providers, models, and secrets" tells them when to care.
- **Defaulting to tables without asking**: some users strongly prefer trees for filesystem layouts. If the user says "too busy" or "confusing," simplify the tree — don't switch to a table. Section headers handle the tier signal; one-line descriptions keep the tree scannable.
