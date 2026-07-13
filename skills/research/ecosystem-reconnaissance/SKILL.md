---
name: ecosystem-reconnaissance
description: >-
  Systematically survey the GitHub ecosystem for tools related to a project —
  competitor frameworks, companion tools, protocols, memory systems, GUIs, deployment
  options — compile structured reference data, and link into a master plan.
version: 1.1.0
author: agent
tags: [research, github, ecosystem, competitive-analysis, reference-docs]
created_from_user_sessions: true
---

# Ecosystem Reconnaissance

Map a tool's position in the broader landscape by systematically surveying GitHub for related projects, compiling structured reference data, and feeding it into a larger plan or document.

## When to Use

- User asks "what are the related tools/concepts to X on GitHub?"
- You're building a reference document that needs a "Related Tools" or "Ecosystem" section
- You need to understand where a tool fits relative to alternatives
- User's project plan needs competitive/companion context (e.g. "AI Architecture.html")

## Methodology

### Phase 1: Identify Categories

Before searching, enumerate the natural categories of related tools:

| Category | Examples |
|----------|----------|
| **Direct competitors/alternatives** | Other agent frameworks with similar scope |
| **Agent CLI tools** | Coding agents, ACP-compatible runners |
| **Memory systems** | Long-term memory for AI agents |
| **Protocols** | MCP, ACP, A2A — interop standards |
| **GUIs & Desktops** | Web UIs, desktop apps, dashboards |
| **Multi-agent orchestration** | Frameworks for agent coordination |
| **Deployment** | Nix, Docker, Modal, WSL |
| **Infrastructure** | Gateways, hub services, monitoring |

### Phase 2: Gather Raw Data

Cover **all three data surfaces** — don't rely on just one:

#### 2a. Web search (broad discovery)
```python
web_search(query="github crewai autogen langgraph agent frameworks comparison 2026")
web_search(query="agent memory system mem0 hindsight zep github stars")
```

Search for:
- "alternatives to [tool]" — competitor discovery
- "[category] github stars 2026" — find top projects
- "[specific tool name] github features" — deep dive on key targets
- "[concept] comparison" — existing comparison articles

#### 2b. Web extract (GitHub pages for star counts + descriptions)
```python
web_extract(urls=["https://github.com/mem0ai/mem0", "https://github.com/getzep/zep"])
```
- **Star counts** are in the page title or sidebar
- **Description** is in the repo header
- **Key features** in README intro paragraphs
- Note: `web_extract` on a GitHub page returns the full page (262K+ chars). Read selectively.

#### 2c. Web extract (comparison articles)
```python
web_extract(urls=["https://www.vellum.ai/blog/best-hermes-agent-alternatives"])
```
- Existing comparison articles give immediate structure
- **Treat with healthy skepticism** — articles from competitors are marketing. Verify star counts, license claims, and feature claims against actual GitHub pages.
- Extract the comparison framework (categories, scoring criteria) even if you don't trust the scores themselves.

#### 2e. Self-Audit vs Landscape

When the goal is not to survey competitors but to **audit your own project
against the ecosystem** to find gaps and prioritize what to build next:

```python
# Step 1: Survey the landscape for comparable projects
web_search(query="agent skill marketplace registry open source 2026")
web_search(query="agent skill quality vetting trust signals marketplace")
web_extract(urls=[
    "https://agentskills.io/home",
    "https://aregistry.ai/",
])

# Step 2: Compare your project against each, identify gaps
# Look for categories where competitors have something you don't,
# AND advantages you have that they don't
gaps = {
    "no versioning / dependency graph": "Agents can't resolve dep chains",
    "no trust/quality signals": "No way to tell polished from draft",
}
advantages = {
    "ships full harness": "Not just skills -- fleet, MCP, SOULs, configs",
}

# Step 3: Map each gap to a roadmap phase
roadmap = {phase: gap for phase, gap in enumerate(gaps, 1)}
```

**Key difference from competitor survey:** You look for *missing features
in your own project*, not evaluate alternatives. Output is a roadmap
(what to build in what order), not a reference doc (what else exists).

**Trigger:** User wants to "take my repo/project public" or "make my
collection useful for others." The landscape check reveals what's expected
vs what you ship.

**Worked pattern from 2026-07-06:** user's agent-store (185 skills,
35 categories) was strong but the landscape revealed 7 gaps (no install.sh,
no update mechanism, no agent discovery protocol). Each gap mapped to
a launch phase. The structural advantage (ships full harness, not just
skills) was the key differentiator to emphasize.

#### 2d. Official Documentation Deep Dive

When the target is a tool whose **integration patterns** you need to understand (not just GitHub stats), crawl its official documentation:

```python
web_extract(urls=[
    "https://zellij.dev/documentation/programmatic-control.html",
    "https://zellij.dev/documentation/creating-a-layout.html",
])
```

Search for:
- **Programmatic control / CLI API** — can you script it? Create panes, run commands, attach/detach?
- **Layout formats** — what config language do they use? Can you define workspaces declaratively?
- **Install instructions** — does Windows need WSL? Native binary? `winget` / `brew` / package?
- **Server/daemon modes** — can you run headless? Web client? Background sessions?
- **Plugin systems** — extensibility, ecosystem maturity

**What distinguishes docs research from GitHub research:**
- Docs tell you *how* to integrate; GitHub tells you *how popular* it is
- Docs surface CLI flags, config formats, exit codes, and edge cases — the raw material for integration examples
- GitHub shows community engagement, but rarely has the detailed API surface you need for writing a KDL layout or shell script

**When to use this phase:**
- You're creating integration content (layouts, scripts, code examples)
- You need to write a comparison that tests actual capabilities (e.g. "does this tool support floating panes?")
- Your output is going into a living reference document, not just a ecosystem survey

### Phase 3: Compile Structured Reference

Create a reference document with this structure:

```markdown
# [Tool] GitHub Ecosystem & Related Tools Reference

---

## 1. Agent Frameworks (Competitors & Alternatives)

| Framework | GitHub | Stars | Language | Key Feature |
|-----------|--------|-------|----------|-------------|
| ... | ... | ... | ... | ... |

**Key Differentiators vs [Tool]**
- Bullet points on what each competitor does differently
- Honest gaps in your tool's coverage

## 2. [Next Category]

...
```

**Rules for the reference doc:**
- **Date the document** ("Compiled: June 2026") — star counts drift
- **Use tables** — they're the most scannable format for side-by-side comparison
- **Distinguish fact from inference** — star counts from GitHub pages are facts; "gaps" or "weaknesses" are your analysis
- **Include verified source URLs** — every major claim should trace back to a specific GitHub URL or article
- **Add a Key Observations section** at the end — 5-8 synthesizing takeaways

### Phase 4: Link into Master Plan

1. Write the reference doc to `.hermes/plans/<name>.md`
2. Update the master plan's top matter:
   ```markdown
   **Companion Reference Files:**
   - `.hermes/plans/hermes-atlas-reference.md` — [description]
   - `.hermes/plans/hermes-github-reference.md` — [description]
   ```
3. Use `patch` to add the reference lines right after the plan's Goal line

### Phase 5: Integration Content Creation

When the research output feeds into a **living reference document** (like `AI Architecture.html`), create reusable integration content rather than (or alongside) a standalone survey doc.

#### When to do this phase

You've gathered docs-level research on a tool, and the user's reference doc has a section where it belongs — e.g. a tool like Zellij that enhances the Hermes terminal workflow belongs in the "Runtimes & Profiles" or "Workflows" section.

#### Content types to create

| Content Type | Example from Zellij session | Template pattern |
|---|---|---|
| **Integration scenarios table** | "Multi-agent workspace", "Headless CI pipeline", "Remote access" — each with 1-line `code` approach | `<thead>` / `<tbody>` table inside `<div class="tw">`, 3 columns |
| **Code examples — config** | KDL layout file for Hermes workspace (3 tabs: agent TUI, terminal, logs) | `<div class="code-block">` with `.cb-header`, `.cb-dot`, `.cb-lang`, `.c-com` for comments |
| **Code examples — script** | Bash script launching 3 parallel agents in Zellij panes | Same code-block structure, `.cb-dot purple` for scripts |
| **Comparison table** | Zellij vs tmux — 13 features side-by-side with ✅/⚠️/❌ | Standard table, first column is feature name, remaining are tools |
| **Quick install guide** | `winget install` + verify + launch commands | Compact code block, no more than 5 lines |

#### Matching the document's structure

Before writing any HTML, **sample 2-3 existing code blocks and tables** from the target document to understand its exact markup conventions:

```python
# Check code block pattern
grep -n -B1 -A5 'class="code-block"' doc.html | head -30
# Check table pattern
grep -n -B1 -A5 '<div class="tw">' doc.html | head -30
# Check subsection heading level
grep -n 'class="section-meta"\\|<h[234]' doc.html | head -20
```

Common patterns the Zellij session revealed:
- Code blocks: `.code-block > .cb-header (cb-dot green/purple + cb-lang) + .cb-body`
- Tables: wrapped in `<div class="tw">` with `<thead>`/`<tbody>` semantics
- Comment lines in code: `<span class="c-com"># comment text</span>`
- Subsection headers: `<h4>` inside a `<h3>` section (not `<h2>`)

#### Inserting the content

Use the section-injection workflow from `html-doc-restructure` (§Section-injection workflow):

1. Find the boundary — the text just **before** the section's `</div><div class="section-nav">` is the insertion point
2. `patch()` with that boundary as `old_string` — `new_string` prepends your new subsections + re-emits the boundary
3. Update any cross-references (tables that mention the old tool name now mention `new_tool / old_tool`)

#### What to include for each integrated tool

For a tool integration subsection, always cover:

1. **What it is** — 1-paragraph intro with a comparison anchor (e.g. "like tmux with batteries included")
2. **Integration scenarios** — table of 4-8 use cases with concrete CLI commands
3. **At least one concrete example** — either a config file with real paths or a runnable script
4. **Comparison table** — if the tool has a well-known alternative (Zellij↔tmux, Docker↔Podman, etc.)
5. **Quick install** — one-liner install + verify command + launch command

## Pitfalls

- **Don't rely on a single page's star count** — check the GitHub repo page directly for the canonical number. Web search results often show stale stars.
- **Don't copy comparison article conclusions uncritically** — a competitor's comparison article is marketing material. Its star counts may be wrong, feature lists misleading.
- **Don't miss "also related" chains** — one Github repo's README often links to related projects. Follow those links.
- **Don't mix categories** — keep competitors, companion tools, protocols, and infrastructure in separate tables. Each has different comparison dimensions.
- **Don't ask the user to re-discover what you just found** — present the compiled doc, don't ask "what categories do you want?"
- **Star counts go stale** — if you reference a count like "58K stars", date the observation. The user may read the doc months later.

## Verification

After compiling:
- [ ] Every category has at least 3 entries (or a note explaining why fewer)
- [ ] GitHub star counts are from actual repo pages, not search snippets
- [ ] Each entry has: GitHub URL, star count, language, key differentiator
- [ ] Key Observations section synthesizes 5+ insights
- [ ] Reference doc is linked from the master plan
- [ ] Sources are dated for freshness

## Reference Files

- `references/hermes-github-ecosystem.md` — Full worked example: Hermes Agent ecosystem reconnaissance covering 8 categories, 50+ projects, with structured tables and key observations. Concrete output format reference.
- `references/tool-integration-content.md` — Worked example: Zellij integration research + content creation for `AI Architecture.html`. Covers official docs research, KDL layout creation, bash scripting for multi-agent workflows, Zellij↔tmux comparison table, and section-injection patterns into a living HTML reference doc. Uses the Phase 2d + Phase 5 workflow documented above.

## Related Skills

- `tech-stack-research` — research individuals' tool preferences via social media (complementary: people-focused vs landscape-focused)
- `knowledge-base-organization` — structure reference docs into a full wiki (follow-on step after reconnaissance)
- `knowledge-consolidation` — merge multiple reference docs into one
- `html-doc-restructure` — section-injection workflow for inserting researched content into an existing HTML document (Phase 5 depends on this)
