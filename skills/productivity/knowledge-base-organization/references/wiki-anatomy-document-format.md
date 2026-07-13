# Anatomy Document Format

When a user asks for a filesystem layout overview ("show me the anatomy of X", "do the same thing for Y", "make an infographic of this directory"), use this format.

## Format Rules

### TUI-Style Tree
Use real `├── └── │` tree characters. The visual tree structure is the primary element.

```
directory-root/
│
│  👑 TIER HEADER
├── entry-name           Short description — what it IS, not what it does
├── another/
│   ├── child            One line per entry
│   └── ...
│
│  ⭐ NEXT TIER
├── entry-name           Description line — ends at char ~45
```

### Tier System
Group entries by priority. Use section headers delimited by `│` and blank lines:

| Tier | Header | Meaning |
| :--- | :--- | :--- |
| Governance | `│  👑 GOVERNANCE` | Defines schema, rules, identity. Constitution-level. |
| Required | `│  ⭐ REQUIRED` | System breaks without this. |
| Default | `│  ✅ DEFAULT` | Ships standard. Prune intentionally. |
| Personal | `│  📝 PERSONAL` | User-authored content, not wiki knowledge. |
| Operational | `│  ⚙️ OPERATIONAL` | Support infrastructure — backups, audits, config. |
| Storage | `│  🗄 STORAGE` | Accumulates passively — archive, trash, WIP. |

### Priority Ordering
Always sort: Governance → Required → Default → Personal → Operational → Storage.
Within a tier, sort by logical importance or alphabetically.

### Purpose-Named Headers

Don't use bare tier names — label headers by WHAT THE GROUP IS FOR:

| Good (purpose) | Avoid (tier-only) |
| :--- | :--- |
| `│  👑 AGENT IDENTITY` | `│  👑 GOVERNANCE` |
| `│  ⭐ BOOT CONFIGURATION` | `│  ⭐ REQUIRED` |
| `│  ✅ MEMORY & STATE` | `│  ✅ DEFAULT` |
| `│  ⚙️ EXTENSIONS` | `│  ⚙️ OPTIONAL` |

The tier icon still signals priority. The header label tells you what the group is *for*. This makes scanning by purpose instant.

Use ALL-CAPS short noun phrases. Examples from the two canonical anatomy docs:

**~/.hermes** (5 groups):
- `👑 AGENT IDENTITY`
- `⭐ BOOT CONFIGURATION`
- `✅ MEMORY & STATE`
- `✅ AUTOMATION & LOGS`
- `⚙️ EXTENSIONS`

**Hermes-Vault** (8 groups):
- `👑 WIKI CONSTITUTION`
- `⭐ CORE KNOWLEDGE`
- `✅ REFERENCE & DATA`
- `✅ PLANNING`
- `📝 PERSONAL SPACE`
- `⚙️ INFRASTRUCTURE`
- `🗄 STORAGE`
- `🗄 ROADMAP`

### Group Count Discipline

Aim for **5-8 purpose groups per section**. Fewer than 5 means you're lumping unrelated things. More than 8 means headers overwhelm the content.

Signs you have too many groups:
- A group has only 1-2 entries that could logically live with another group
- Headers take up more vertical space than the entries
- You have both STORAGE and ARCHIVE — pick one umbrella

When in doubt, merge small groups. Splitting is easy to undo; merging keeps the scan clean.

### Description Style
- One line per entry, max ~40-50 chars before description
- Describe what the file IS, not what it does in detail
- Short phrases, no complete sentences
- Bold key terms only for very important entries (use `**Master config**` not `**every entry**`)
- Examples of good descriptions:
  - `config.yaml          Master config — providers, models, tools`
  - `SCHEMA.md            🛡️ The rulebook — schema, validation, lint rules`
  - `concepts/            Core knowledge — 97 pages: architecture, patterns`
  - `state.db             SQLite store with FTS5 — continuity-critical`

### Key/Legend
Include a small key table at the bottom of each section:

```
| Icon | Meaning |
| :--- | :--- |
| 👑 **Governance** | Defines identity, rules, or schema. The constitution. |
| ⭐ **Required** | System is broken or incomplete without this. |
```

### Two-Section Documents (Multiple Trees)
When the user says "do the same thing for X", create a second tree under its own H1. Each section is self-contained with its own legend.

## Anti-Patterns

| Don't | Why |
| :--- | :--- |
| `[👑]` prefix on every tree line | Breaks visual flow of tree — too noisy. Use section headers instead. |
| Tables instead of trees | Harder to show nesting and hierarchy. Users consistently prefer trees. |
| Paragraph descriptions after entries | Destroys scannability. Max one line per entry. |
| Per-line descriptions that explain the obvious | `config.yaml — configuration file` is waste. Say *what kind* of config. |
| Section header prose | `│  👑 GOVERNANCE — defines rules, schema, identity` is fine. Don't add 3-line explanations inside the tree. |
| Mixing tiers in the tree | All Governance entries together, then Required, etc. Don't group by path. |
