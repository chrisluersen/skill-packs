---
name: hermes-agent-skill-authoring
description: "Author SKILL.md: frontmatter, structure, and conventions for both user-local and in-repo Hermes skills."
version: 2.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [skills, authoring, hermes-agent, conventions, skill-md]
    related_skills: [plan, requesting-code-review]
created_from_user_sessions: true
---

# Authoring Hermes-Agent Skills

## Overview

A SKILL.md can live in two places. Both share the same frontmatter requirements and structural conventions, but differ in creation workflow and audience:

| Aspect | User-Local | In-Repo |
|--------|-----------|---------|
| Location | `~/.hermes/skills/<category>/<name>/SKILL.md` | `<repo>/skills/<category>/<name>/SKILL.md` |
| Created via | `skill_manage(action='create')` | `write_file` + git commit |
| Audience | Single user | All Hermes users |
| Scope | Personal workflows, niche tools | Reusable, shippable workflows |

This skill covers **both**. Load it whenever you create or significantly modify any SKILL.md.

## Autonomy Principle — Never Ask for Permission

The user's explicit instruction: *"if you think you should save something as a skill then you should do it without my permission."*

**This is a hard rule, not a guideline.** When you detect a signal to save a skill (reusable technique, user correction embedded, hard-won fix), act immediately — do not ask "should I save this?" or "do you want me to make a skill?". The user considers the hesitation wasteful.

The `session-closeout` skill's step 1e (Skill Library Review) runs this check at session boundaries. But autonomous creation happens *mid-session* too — when you discover a technique, patch a wrong skill after loading it, or the user corrects your approach mid-conversation. Act then, not at closeout.

**Exception:** Only ask if the proposed skill has significant trade-offs (will alter a long-running cron job, could conflict with existing skills, or requires user config). Default: save and move on.

## When to Use

- You're creating or editing a **user-local skill** via `skill_manage(action='create')` / `action='patch'`
- You're committing a reusable workflow that should ship with Hermes Agent (in-repo)
- You're editing an existing skill under `skills/<category>/<name>/` in the repo
- User asks you to "make this a skill" or "save this approach"
- You need to validate frontmatter, structure, or completeness of any skill
- **Counter-trigger:** Do NOT load this for skills that are purely data (knowledge compilations with no procedural steps). Those are better as wiki pages.

## Required Frontmatter

Source of truth: `tools/skill_manager_tool.py::_validate_frontmatter`. Hard requirements:

- Starts with `---` as the first bytes (no leading blank line).
- Closes with `\n---\n` before the body.
- Parses as a YAML mapping.
- `name` field present — lowercase, hyphens, ≤64 chars.
- `description` field present, ≤1024 chars.
- Non-empty body after the closing `---`.

### Recommended Frontmatter (user-local skills)

Every agent-created skill should match the peer shape:

```yaml
---
name: my-skill-name               # lowercase, hyphens, ≤64 chars
description: "Automated wiki librarian — lint, audit, organize..."  # ≤1024 chars
version: 1.0.0
author: agent-created              # signals it's your work, not bundled
created: 2026-06-17
updated: 2026-06-17
category: hermes                   # pick from existing categories
tags: [wiki, librarian, cron]      # top-level tags for skill_view
metadata:
  hermes:
    tags: [wiki, librarian, cron]  # same as top-level tags
    related_skills: [wiki-operations, another-skill]  # cross-references
---
```

`version` / `author` / `metadata.hermes` are NOT enforced by the validator, but every peer has them — omit and your skill sticks out.

## Size Limits

- Description: ≤1024 chars (enforced).
- Full SKILL.md: ≤100,000 chars (~36k tokens).
- Aim for **8-15k chars**. Past 20k, split detail into `references/*.md` files.

## User-Local Skill Structure (agent-created)

A well-rounded user-local skill has these sections. Not all are mandatory, but the **Minimum Viable Skill** is: Overview → When to Use → core body → Pitfalls.

### Minimum Viable Structure

```
# <Title>

## Overview
What this skill does, why it exists, and what model/provider it runs on (if fixed).

## When to Activate
- Bulleted trigger conditions
- If the skill defines an alias or nickname (e.g. "84" for Klio), ADD IT as a trigger

## <Core body — workflow, steps, commands>
Prose, tables, code blocks. Whatever gets the job done.

## Pitfalls
What goes wrong and how to avoid it.
```

### Rich Structure (preferred for complex skills)

```
# <Title>

## Personality & Tone (optional)
For skills with a defined persona, voice, or character.

## When to Activate

## Model
If the skill runs on a specific model/provider, document it here explicitly.

## Core Workflows
Numbered workflows with exact tool calls, commands, and expected outputs.

## Cron Job Setup
If the skill runs on a schedule, document the exact cronjob() call parameters.
⚠️ Use the CORRECT API format for model:
    model: {model: "google/gemini-2.5-flash", provider: "openrouter"}
    NOT separate model:/provider: fields.

## Cost
Pricing table or per-run estimates so the agent can self-limit.

## Failure Recovery
Table of common failure modes and graceful degradation steps.

## Pitfalls
```

### Cron Config Validation

When a skill documents a cron job, **cross-reference the documented params against the actual cron job**:

1. Run `cronjob(action='list')` to find the job by name
2. Compare: `enabled_toolsets`, `model` format, `workdir`, `deliver`
3. If mismatched, update whichever is stale — skill docs or actual cron config
4. Run `cronjob(action='update')` on the actual job if needed

Common mismatches found in practice:
- Skill docs show separate `model:` / `provider:` fields → API expects `model: {model: "...", provider: "..."}`
- Skill docs omit `file` from enabled_toolsets (cron needs it to read/write files)
- Skill docs forget `workdir` → cron runs from default cwd, not the project directory

### References/ Directory Pattern

For supplementary content that would bloat SKILL.md past 15k chars:

- `references/<topic>.md` — session-specific detail (error transcripts, reproduction recipes, provider quirks) **and** condensed knowledge banks: quoted research, API docs, external authoritative excerpts
- `templates/<name>.ext` — starter files meant to be copied and modified
- `scripts/<name>.ext` — statically re-runnable actions the skill can invoke directly

Add a one-line pointer from SKILL.md to any new support file so future agents know it exists:
```
> See `references/naming-inspiration.md` for the backstory on this skill's name.
```

## In-Repo Skill Workflow

1. **Survey peers** in the target category: `ls skills/<category>/` — read 2-3 peers.
2. **Check validator constraints** in `tools/skill_manager_tool.py` if unsure.
3. **Draft** with `write_file` to `skills/<category>/<name>/SKILL.md`.
4. **Validate locally**:
   ```python
   import yaml, re, pathlib
   content = pathlib.Path("skills/<category>/<name>/SKILL.md").read_text()
   assert content.startswith("---")
   m = re.search(r'\n---\s*\n', content[3:])
   fm = yaml.safe_load(content[3:m.start()+3])
   assert "name" in fm and "description" in fm
   assert len(fm["description"]) <= 1024
   assert len(content) <= 100_000
   ```
5. **Git add + commit** on the active branch.
6. **Note:** the current session won't see the new skill until a fresh start.

## Cross-Referencing Other Skills

`metadata.hermes.related_skills` unions both trees at load time. You CAN reference a user-local skill from an in-repo skill, but it won't resolve for other users. Prefer in-repo → in-repo links. For user-local → user-local, anything goes.

## Common Pitfalls

1. **Using `skill_manage(action='create')` for an in-repo skill.** It writes to `~/.hermes/skills/`, not the repo tree. Use `write_file` for in-repo creation.

2. **Leading whitespace before `---`.** Validator checks `content.startswith("---")`; any leading blank line or BOM fails validation.

3. **Description too generic.** Peer descriptions describe the *trigger class*, not the one task. "Use when maintaining a wiki" > "Maintain wiki".

4. **Forgetting `metadata.hermes` block.** Not validator-enforced, but needed for `related_skills` cross-references.

5. **Cron config gets stale.** The API model format (`{model: "...", provider: "..."}`) is easy to get wrong. Always validate against `cronjob(action='list')`.

6. **Missing alternate-name triggers.** If the skill defines a nickname or callsign (e.g. "84" for Klio), the "When to Activate" section must list both the primary name AND aliases. Otherwise the agent never loads the skill when the user says the shorter name.

7. **No failure recovery section.** Autonomous (cron) skills WILL encounter MCP downtime, git failures, rate limits, or cost spikes. Without a recovery table, the agent either hangs or produces a useless error report. Always include graceful degradation steps.

8. **Forgetting the cost table.** Without a cost ceiling or estimate, an agent running autonomously can burn $1+ on a single cron run by looping or getting stuck. Hard ceilings ($0.05/run, $0.50/month) protect both the skill and the user's wallet.

9. **Writing a skill that duplicates a peer.** Before creating, `skills_list` your category and open 2-3 peers. Prefer extending an existing skill to creating a narrow sibling.

14. **One-shot naming.** Skill name must be a reusable class-level concept, not a session artifact. "Fix-chrome-crash" → bad. "Chrome-crash-debugging" → better. "Systematic-debugging" → best (already exists as a peer).

15. **Missing version-bumping convention.** Bumping the version number is the only way to signal "this skill has changed since the last time you looked." Without a convention, every call to `skill_view` returns the same version, and nothing indicates whether the skill was improved or still has old content.

    Convention for this fleet:
    - **Patch** (`1.1.0 → 1.1.1`): typo fixes, single pitfall added, command correction, minor step reordering. Surface-level changes that don't change the skill's scope.
    - **Minor** (`1.1.0 → 1.2.0`): new sections added, new reference files created, new patterns documented, new pitfalls discovered. Substantive content addition. The skill does MORE than it did before. **Default for most sessions.**
    - **Major** (`1.0.0 → 2.0.0`): complete rewrite, skill restructured, breaking change in approach, merged with another skill. Rare.

    Apply at the END of any skill edit session. Bump BEFORE writing to disk so the version metadata reflects the new content. If you update multiple things (SKILL.md + references/), it's ONE bump — don't inflate versions per file.

16. **Updating an umbrella + adding a reference file mid-session.** When you discover new patterns during a session and the umbrella skill already exists:
    - Step 1: `skill_view(name)` to see current content
    - Step 2: `skill_manage(action='patch', ...)` to patch SKILL.md with a new section or expand an existing one
    - Step 3: `skill_manage(action='write_file', name=name, file_path='references/<topic>.md', file_content=...)` to create a session-specific reference
    - Step 4: Patch SKILL.md's Linked Files section to add a one-line pointer to the new reference file
    - Step 5: Bump minor version
    - Do NOT create a separate narrow skill for session-specific learnings — the umbrella IS the capture point. The reference file holds the session detail, the SKILL.md holds the reusable pattern.

    This pattern keeps the umbrella skill class-level (not session-specific) while preserving the detail in the reference file. The next session can read the reference for context or skip it for the general pattern.

11. **F-string `{[func()]}` list literal trap.** Inside a Python triple-quoted f-string (`f"""..."""`), the expression `{[func()]}` creates a list literal `[func()]`, not a function call insertion. This produces `['| row1 | ... |\\n| row2 | ... |']` in the output instead of the expected multi-line table rows. **Fix:** use `{func()}` without surrounding brackets. This is extremely hard to spot because the visual difference is just `{[` vs `{` and Python doesn't raise a syntax error since `[func()]` is valid as a one-element list.

12. **Windows path handling in Python scripts.** When writing a script that constructs filesystem paths on Windows + git-bash:
    - `Path('/c/Users/...')` does NOT resolve — `/c/` is a git-bash/MSYS convention, not understood by Python's `pathlib`.
    - Use `Path('C:/Users/...')` or `Path(r'C:\Users\...')` instead.
    - Inside `terminal()` tool calls (git-bash), keep using `/c/Users/...` — that's correct for the shell.
    - The mismatch causes `FileNotFoundError` when a script works in the terminal but fails when Python runs it directly (e.g. via cron or `execute_code`).

## Verification Checklist

For any skill you create or significantly edit:

- [ ] Frontmatter starts at byte 0 with `---`, closes with `\n---\n`
- [ ] `name`, `description`, `version`, `author`, `created`, `updated` all present
- [ ] `metadata.hermes.{tags, related_skills}` present
- [ ] Name ≤ 64 chars, lowercase + hyphens
- [ ] Description ≤ 1024 chars, describes trigger class
- [ ] "When to Activate" lists all aliases/nicknames the skill defines
- [ ] Total file ≤ 100,000 chars (aim for 8-15k)
- [ ] Cron setup uses correct API format: `model: {model: "...", provider: "..."}`
- [ ] Cron setup validated against actual cron job via `cronjob(action='list')`
- [ ] Cron setup includes `workdir` if the skill works in a specific directory
- [ ] Failure recovery section present for autonomous/cron skills
- [ ] Cost estimation table present for skills that make paid API calls
- [ ] For user-local skills: `skill_manage(action='patch')` for small edits, `skill_manage(action='edit')` for rewrites
- [ ] For in-repo skills: `write_file` to create, `git add + commit` to ship
