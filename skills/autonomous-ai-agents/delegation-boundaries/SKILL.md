---
name: delegation-boundaries
title: Delegation Boundaries — When to Use Subagents vs Direct Execution
description: Judgment framework for deciding when to delegate work to subagents (delegate_task, background subagents) versus executing directly. Covers the cost model, the failure modes, and the recovery patterns.
category: autonomous-ai-agents
created: 2026-06-20
updated: 2026-06-20
tags:
  - delegation
  - subagents
  - judgment
  - workflow
  - performance
---

# Delegation Boundaries

**The judgment framework for when to use `delegate_task` (subagents) vs. direct tool execution.**

Every delegation decision has a cost. Subagents are powerful for the right kind of work and wasteful or dangerous for the wrong kind. This skill captures the boundary.

---

## Core Principle

Delegation is a **cost, not a default**. Every subagent call:
- Burns tokens on context serialization + subagent session setup
- Adds a model availability risk (the subagent's default model may not be available — see pitfall below)
- Adds a round-trip delay (async calls improve this, but sync calls block the parent)
- Produces a **self-reported summary** that must be verified, not trusted

Ask before delegating: **"Is this work better done by me directly?"** If the answer isn't a clear "no", do it directly.

---

## Decision Matrix

### When TO Delegate

| Task type | Example | Why |
|-----------|---------|-----|
| **Heavy reasoning** | Debugging a complex bug across multiple files | Keeps intermediate data out of parent context |
| **Parallel independent analysis** | Research topic A and topic B simultaneously | Subagents run in parallel, 2× throughput |
| **Code review on unfamiliar codebase** | Reviewing a PR for a project you haven't read | Subagent loads the codebase fresh, no context pollution |
| **Data-heavy processing** | Parsing 1000-line CSV, filtering, transforming | Keeps raw data out of parent context window |
| **Multi-source research synthesis** | Reading 5+ documents and synthesizing findings | Each read stays in subagent context, not parent |
| **Background fetch** (async only) | Long-running data collection the user doesn't need to wait on | User keeps working while subagent runs |

### When NOT To Delegate

| Task type | Example | Why |
|-----------|---------|-----|
| **Well-defined mechanical work** | Writing a wiki page with known MCP tools | Faster to execute directly — one tool call vs subagent setup + teardown + model availability risk |
| **Single-file operation** | Patching a config, reading a file, running a quick command | Direct tool call is instant — subagent adds 500+ tokens of overhead |
| **Task that fits in one direct call** | A single `web_search`, `read_file`, or `mcp_wiki_file_synthesis` | Subagent setup costs exceed any benefit |
| **Tool output that needs immediate verification** | Writing files, making HTTP requests, creating resources with side effects | Subagent summaries are self-reported and may be wrong — direct execution lets you verify the result yourself |
| **Task requiring user interaction** | Anything that needs `clarify()` | Subagents cannot use `clarify` — they will proceed with wrong defaults or get stuck |
| **Narrow wiki operations** | Creating a wiki page, linting, reindexing | The MCP tools exist specifically for direct use. Subagent adds failure risk for zero benefit |

### The "Smell Test"

If you find yourself writing a goal like "Write a wiki page using mcp_wiki_file_synthesis" — **stop**. That's a direct execution task. The subagent will:
1. Fail if its model isn't available (common — see pitfall)
2. Return a self-reported result you have to verify anyway
3. Burn tokens you didn't need to spend

A subagent goal should need **reasoning**, not just **tool invocation**. If the task is "take these inputs and call one tool with them", do it yourself.

---

## Cost Model

| Factor | Direct | Subagent (sync) | Subagent (async, background=true) |
|--------|--------|------------------|-----------------------------------|
| **Setup tokens** | 0 | ~200-500 (context serialization) | ~200-500 |
| **Result tokens** | 0 (result is structured tool output) | ~200-500 (summary generation) | ~200-500 |
| **Model availability risk** | None | Subagent uses its own model — may 404 | Same risk |
| **Latency** | Round-trip time of tool call | Subagent setup + tool calls + summary | Async — user keeps working |
| **Verification cost** | 0 (tool output is authoritative) | Must verify side effects | Must verify side effects |
| **Reliability** | High | Medium (model, MCP, tool availability) | Medium |

**Key insight:** For a simple task (1-2 tool calls), subagent overhead can **double or triple the token cost** while adding a failure mode. The breakeven point where delegation makes economic sense is roughly 5+ tool calls with reasoning between them.

---

## Failure Patterns & Recovery

### Pattern 1: Model 404 (most common)

**Symptom:** Subagent returns immediately with `status: "failed"`, `error: "HTTP 404: Model '...' not found"`, 0 tool calls.

**Root cause:** The subagent inherits the parent's default model endpoint, but the provisioned model (e.g. `deepseek/deepseek-v4-flash`) isn't registered under OpenRouter's model catalog for subagent sessions. The parent model exists on Nous Portal but the subagent tries to resolve it through a different provider chain.

**Recovery:**
```
1. Do NOT re-delegate — the same model will 404 again
2. Execute the task directly yourself
3. The task is usually simple enough for direct execution
```

### Pattern 2: Self-Reported Success with Actual Failure

**Symptom:** Subagent returns `"Task completed successfully"` but the file wasn't created, the HTTP request didn't land, or the result is wrong.

**Root cause:** Subagents return **summaries of what they intended to do**, not verifiable evidence of side effects.

**Recovery:**
```
1. Always verify side effects: stat the file, fetch the URL, read back the content
2. If the subagent claimed "file written at X", read_file(X) immediately to confirm
3. Never tell the user "done" based on a subagent summary alone
```

### Pattern 3: Stuck Subagent

**Symptom:** Subagent runs for 60+ seconds with no output, hits iteration limit.

**Root cause:** The subagent can't call `clarify` and gets stuck in a loop trying to resolve ambiguity.

**Recovery:**
```
1. Cancel (it will timeout automatically)
2. The task was poorly scoped — split it more finely next time
3. Execute the ambiguous part directly so you can ask the user
```

---

## Verification Rules

When you DO delegate, these are non-negotiable:

1. **Verify every side effect.** If the subagent wrote a file, read it. If it made an API call, check the response. If it committed to git, check the log.
2. **Do not chain delegations.** Each subagent's summary is self-reported. Chaining A→B→C means errors compound invisibly. One level of delegation is the max.
3. **Prefer direct execution for anything the user will see.** A 404'd subagent looks unprofessional — the user sees a failure, not the intent behind it.
4. **If delegation fails, catch it and do it yourself.** Don't retry the same delegation with a different goal string — the model availability issue won't change.

---

## Related

- [[plan-continuity-injection|Plan Continuity Injection]] — handling mid-task injections that might shift delegation boundaries
- [[post-phase-review|Post-Phase Review]] — retrospective patterns that assess whether delegation was worth it
