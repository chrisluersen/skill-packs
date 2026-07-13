---
name: skill-maintenance
title: "Skill Maintenance: Bloat Audit, Consolidation & Lifecycle"
description: "Keep Hermes skills lean and correct over time — bloat audits, consolidation workflow, version management, archive/merge decisions."
category: hermes
created: 2026-06-29
version: 2.0.0
author: agent-created
tags: [skills, maintenance, audit, consolidation]
---

# Skill Maintenance: Bloat Audit, Consolidation & Lifecycle

## When to Activate

- You're reviewing the skill library as part of session closeout
- A skill you loaded appeared bloated, repetitive, or contradictory
- user asks about the state of a skill or "can this be improved?"
- A skill has grown past 15K chars and you haven't audited it recently
- Two sessions in a row that used the same skill produced corrections to it
- **You just completed a session with user interaction** — scan the conversation for signals (see Active Signal Scanning below)

## Overview

Skills accumulate cruft: repeated instructions, stale session narratives, contradictory sections, dead weight from legacy decisions. Every 5-10 patches, audit for bloat. The consolidation pattern has been proven across two skills (hermes-router, session-closeout).

This umbrella covers the full lifecycle beyond creation:
- **Active signal scanning** — capture learnings from every session, not just closeouts
- **Bloat audit** — identify and remove duplication
- **Consolidation** — restructure for signal density
- **Verification** — ensure nothing was lost
- **Archive/merge** — when to consolidate two skills or retire one

## Active Signal Scanning & Capture

The skill library is a living artifact. Every session with user interaction produces at least one signal worth capturing — a correction, a technique, a pitfall discovered. A skill-review pass that produces nothing is a missed learning opportunity, not a neutral outcome.

### Signals to Act On

| Signal | Action |
|--------|--------|
| User corrected your style, tone, format, legibility, verbosity | Patch the skill that governed the task. **Frustration signals** like "stop doing X", "this is too verbose", "don't format like this", "why are you explaining", "just give me the answer", or "you always do Y and I hate it" are first-class skill signals, not just memory. |
| User corrected your workflow, approach, or sequence of steps | Add the correction as a pitfall or explicit step in the governing skill |
| Non-trivial technique, fix, workaround, or debugging path emerged | Capture as a reference file under the relevant umbrella skill |
| A skill loaded or consulted this session was wrong, missing a step, or outdated | Patch it NOW — don't wait for a closeout |
| Two skills overlap on the same territory | Note it in your reply — the background curator handles consolidation at scale |

### "Nothing to save" is a real option — and rarely correct

`Nothing to save` should NOT be the default. Only say it when the session ran smoothly with no corrections, produced no new technique, and no skill was wrong. If you're hesitating, act — the bar for capture is intentionally low.

### Update Path — Preference Order

1. **UPDATE A CURRENTLY-LOADED SKILL.** If any skill loaded via `skill_view` or the user's `/skill-name` covers the new learning's territory, patch that one first. It was in play — it's the right one to extend.

2. **UPDATE AN EXISTING UMBRELLA.** If no loaded skill fits but an existing class-level skill does, patch it. Add a subsection, a pitfall, or broaden a trigger.

3. **ADD A SUPPORT FILE** under an existing umbrella. Three types:
   - `references/<topic>.md` — session-specific detail (error transcripts, provider quirks) AND condensed knowledge banks (API docs, authoritative excerpts). Concise, not a full mirror.
   - `templates/<name>.ext` — starter files meant to be copied and modified.
   - `scripts/<name>.ext` — statically re-runnable actions the skill can invoke.
   Add via `skill_manage action=write_file` with `file_path` starting `references/`, `templates/`, or `scripts/`. The umbrella's SKILL.md gains a one-line pointer.

4. **CREATE A NEW CLASS-LEVEL UMBRELLA SKILL** when no existing skill covers the class. The name MUST be class-level, not a specific PR number, error string, feature codename, or session artifact. If it only makes sense for today's task, it's wrong — fall back to (1), (2), or (3).

### User-Preference Embedding

When the user expressed a style/format/workflow preference, the update belongs in the **SKILL.md body**, not just in memory. Memory captures "who the user is and what the current situation and state of your operations are"; skills capture "how to do this class of task for this user." When they complain about how you handled a task, the skill that governs that task needs to carry the lesson.

### Do NOT Capture

These become persistent self-imposed constraints that bite you later when the environment changes:

- **Environment-dependent failures** — missing binaries, fresh-install errors, post-migration path mismatches, "command not found", unconfigured credentials, uninstalled packages. The user can fix these — they are not durable rules.
- **Negative claims about tools or features** — "browser tools do not work", "X tool is broken", "cannot use Y from execute_code". These harden into refusals the agent cites against itself for months after the actual problem was fixed.
- **Session-specific transient errors** that resolved before the conversation ended. If retrying worked, the lesson is the retry pattern, not the original failure.
- **One-off task narratives** — "summarize today's market" or "analyze this PR" is not a class of work that warrants a skill.

If a tool failed because of setup state, capture the FIX (install command, config step, env var to set) under an existing setup or troubleshooting skill — never "this tool does not work" as a standalone constraint.

### Target Shape: Class-Level Skills with References

Every skill should be a **class-level umbrella** with:
- A rich, self-contained SKILL.md covering the class of work
- A `references/` directory for session-specific detail, not inline narratives
- Procedures, not stories

Not a long flat list of narrow one-session-one-skill entries. When you find yourself about to create a skill named after today's specific error, ask: "what class of work does this belong to?" and extend that class-level skill instead.

## Bloat Audit Signals

| Signal | What It Looks Like | Action |
|--------|-------------------|--------|
| Duplications | Same instruction 2+ times ("one file forever" 4×, "load skill first" 2×) | Merge to 1 authoritative source |
| Contradictions | Skill says both "never X" and "when to X" (archive section in a never-archive skill) | Remove the contradictory branch |
| Dead weight | Legacy sections, conditional instructions always taking the same path | Remove or replace with a note |
| Sequential steps | Step N followed by step N+1 that's just verification of N ("reindex" + "verify reindex") | Merge into one step |
| Session narratives | "Pattern from this session:" stories in procedure body | Strip to the rule, move story to `references/` |
| Fragmented pitfalls | 4 pitfalls about same root cause (YAML + patch on tracking files) | 1 consolidated pitfall with enumerated failure modes + single fix |

## Consolidation Workflow

### Step 0: Cross-Skill Deduplication

Before consolidating within a single skill, check whether the content duplicates a **general pattern** across multiple skills. This is different from merging two skills — the goal is to make one skill the canonical reference and trim duplicates from others.

**Signal:** Content in skill A re-states a mechanism or troubleshooting step that's already documented in skill B (e.g., "MCP subprocesses get a filtered environment" appearing in both `native-mcp` and `gbrain-integration`).

**Criteria for canonical home:**
- **General mechanism** → the skill named after the mechanism (`native-mcp` for MCP env filtering, `llama-cpp` for GGUF inference)
- **Specific implementation** → the skill named after the domain (`gbrain-integration` for gbrain's PGLite lock recovery)
- When in doubt, the more general skill wins — domain-specific skills can cross-reference it

**Fix pattern:**
1. Identify the canonical skill (already has the authoritative version)
2. In the duplicate skill(s), replace the duplicated explanation with a short cross-reference: `(see \`<canonical-skill>\` skill for the mechanism)`
3. Confirm nothing was lost — the cross-reference plus the domain-specific context (API key name, binary path, config key) must still make sense in isolation
4. Bump version on the trimmed skill (minor bump for active trimming)
5. Do NOT bump the canonical skill — it didn't change

**Example from this session:**
`gbrain-integration` had 5 instances of MCP env-filtering explanations that duplicated `native-mcp`. Each was replaced with `(see \`native-mcp\` skill)` plus only the gbrain-specific detail (ZEROENTROPY_API_KEY, gbrain.exe path). All 5 patches applied, version bumped 1.6→1.7.

### Step 1: Audit

1. `skill_view(name)` — read the full content (no offset/limit)
2. Map bloat: grep for repeated phrases, note contradictions, identify dead weight
3. Check linked files — are they all still relevant?

### Step 2: Write

Write the consolidated version in one pass:
- Merge duplications to one authoritative location
- Cut dead weight sections
- Group related pitfalls into 1 entry with `N failure modes, 1 root cause` structure
- Merge leaf verification steps into their parent
- Strip session-specific narrative, keep only the rule
- Keep reference file pointers intact

### Step 3: Verify

Systematic comparison against the old version:

- **Every procedure step** from old → present in new (even if renumbered/restructured)
- **Every pitfall** from old → present in new (even if consolidated into a grouped entry)
- **Intentional removals** documented with a reason (contradicts philosophy, covered elsewhere, dead weight)
- **No session narratives** in procedure body — `references/` is the right home
- **Reference files** intact and pointed to from SKILL.md
- **Version bumped** (minor for reorganization, major for structural rewrite)

If any step/signal/pitfall from the old version is missing and not documented as intentional, **restore it** before reporting done.

### Step 4: Cross-Reference Sweep (Critical After Any Retirement)

After retiring a skill with `absorbed_into=<umbrella>`, search all other skills for stale references:

```bash
grep -r "skill-name" ~/AppData/Local/hermes/skills/*/SKILL.md
```

Fix in:
1. **related_skills frontmatter** — remove the retired name, add the umbrella if needed
2. **Body references** — "see the full X skill" → either inline the content or redirect to the umbrella
3. **Cron skill loads** — if a cron loaded the retired skill, update to the umbrella
4. **Companion skills tables** — update any coordinator skills (like Klio) that reference the retired name

Common misses: `gbrain-integration` (related_skills), `knowledge-base-organization` (body references), Klio/other coordinators (companion tables, cron loads).

### Step 5: Bump

Use the skill's existing version convention. When there isn't one (common for skills without a version field):
- **No version field** → add `version: 1.0.0` as the first bump
- **Patch** (`1.1.0 → 1.1.1`): typo fixes, single pitfall added, command correction
- **Minor** (`1.1.0 → 1.2.0`): reorganization, new sections, consolidation — **default for a bloat audit**
- **Major** (`1.0.0 → 2.0.0`): complete rewrite, structural change, merged with another skill

## Companion Skills Table Pattern

When a coordinator agent (like Klio) manages work across multiple specialist skills, add a companion skills reference table to their SKILL.md. This helps future sessions load the right companion without guessing.

**Format:**
```markdown
## Companion Skills

| Task | Load With |
|------|-----------|
| General health check | `wiki-operations` |
| Entity lifecycle (create, bulk edit) | `wiki-entity-management` |
| ... | ... |

> **Cron note:** Routine crons load only the minimum pair. Additional skills loaded ad-hoc or via dedicated one-shot cron.
```

**When to add:** After a consolidation that changes the skill landscape, or when a coordinator agent is first created. The table serves as the map of which skill does what.

## Provenance Scanning (Batch Audit)

When you need to extract a specific attribute from every SKILL.md (source, size, tags, description), batch-scan with a script rather than loading each skill individually. This is the pattern used for the skill-packs provenance badges.

### Provenance Categorization

```python
# Python script — run from the polaris root
import os, sys
from pathlib import Path

for fpath in Path('./skills').rglob('SKILL.md'):
    name = fpath.parent.name
    content = fpath.read_text(encoding='utf-8', errors='replace')[:2000]
    author = ''
    created = False
    for line in content.split('\n'):
        if line.startswith('author:'):
            author = line.split('author:',1)[1].strip()
        if 'created_from_user_sessions: true' in line:
            created = True

    al = author.lower()
    if 'community' in al: src='🌐'
    elif 'teknium' in al: src='⚡'
    elif 'orchestra' in al: src='🔬'
    elif created or 'session' in al or 'agent-created' in al or '7-iris' in al or al in ('agent', 'Agent'): src='🤖'
    elif 'adapted' in al or 'ported by' in al or 'inspired' in al or 'fork of' in al: src='🔧'
    elif 'hermes' in al: src='🏛️'
    elif not author: src='❓'
    else: src='🌐'
    print(f'{src}\t{name}')
```

### When to Scan

- Building a README/dashboard that shows skill inventory
- Auditing for stale, retired, or orphaned skills
- Checking author attribution across the library
- Counting skills by category or source for stats/badges

## Reference Files

- `references/eval-adapt-loop.md` — Systematic eval-adapt pipeline for optimizing skill descriptions. 3-phase loop (author → evaluate → iterate) with train/test split, parallel subprocess evaluation, and blinded test scores. Adapted from the 17-file Claude Skills quality pipeline.
- `references/worked-examples.md` — Examples of past skill consolidations with before/after.

## Pitfalls

- **"Nothing was removed" means you didn't audit.** Real audits produce removals. Document what and why.
- **Consolidation ≠ information loss.** Verify every failure mode from a consolidated pitfall group is represented in the single entry. If you merge 4 pitfalls into 1, the 1 must cover all 4 scenarios.
- **Session narratives feel valuable — strip them anyway.** The lesson, not the story, belongs in procedure. Move genuinely valuable stories to `references/`.
- **Reference files are not dead weight.** Optimize SKILL.md body, leave support files intact.
- **Bundled skills can't be edited.** If the skill needing maintenance is bundled with Hermes (`author: Hermes Agent`), you cannot patch it. Create a sibling reference skill or capture the pattern in an agent-created umbrella instead.
- **Naming collisions across sections.** When a project uses the same short identifier (P2, P4, v3, C1) in different contexts (Priority level vs Pattern number, version vs configuration), the collision can confuse both humans and automated readability checks. Audit for:
  - Same acronym used for different concepts in the same document
  - Priority labels (`P0-P3`) that collide with pattern numbers (`Pattern 1-6`)
  - Version numbers that share prefixes with release codes
  - **Fix:** Prefix with the category name: "Pattern 2" not "P2", "Priority 2" not "P2". A document that uses `P2` in a roadmap table AND in a smoke test results table has a naming collision — disambiguate both uses.
  - Check bullet lists, table headers, and section titles for unqualified short identifiers.
