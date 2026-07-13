# Persona Bleed & Gate Psychology in Multi-Agent Pipelines

> Three common anti-patterns in multi-agent systems that emerge from **agent interaction dynamics**, not from individual agent quality. Each has a specific fix.
> **Updated 2026-06-19** — Added specific SOUL.md edit patterns, thoroughness prompt fix, and before/after output comparisons.
> **Updated 2026-06-19 (session closeout)** — Added sibling code paths rule for astraea_plan fix (dispatch_to_agent leak).

---

## 1. Decomposition Anti-Pattern (Astraea)

### The Pattern

When a routing agent is prompted to "decompose this request into sub-tasks" and "identify which fleet agents should handle each sub-task," it invents **fictional agents and pipeline stages** that don't exist in the fleet.

- Prompt: *"Analyze this request and decompose it into sub-tasks. Identify which fleet agents should handle each sub-task."*
- Result: A 5-stage pipeline plan referencing "Vulcan-7" (doesn't exist), "Eris-136" (doesn't exist), and complex handoff chains
- Root cause: The model's training data includes many multi-agent system architectures. When asked to "identify agents," it invents plausible-sounding ones rather than admitting it doesn't know the fleet roster

### The Fix

**Constrain the router's output to a one-sentence intent summary.** The actual routing is done by keyword matching in `_route_to_worker()` — the router's job is just to provide context for the worker, not to make routing decisions.

### Exact Prompt Change

**Before (Broken):**
```
A sanitized user request has arrived that needs task decomposition.
Request: {event.payload.get('text', '')}

Analyze this request and decompose it into sub-tasks. Identify which fleet agents should handle each sub-task. Do NOT use any tools or attempt to delegate — respond with ONLY a JSON task graph as plain text.
```

**After (Fixed):**
```
A sanitized user request needs a brief intent summary.
Request: {event.payload.get('text', '')}

Provide a ONE-SENTENCE summary of what the user wants. Do NOT decompose into sub-tasks, do NOT name specific agents, do NOT create a task graph, do NOT use tools or delegate. Respond with ONLY a single sentence describing the user's intent.
```

### Before/After Output Comparison

| Aspect | Before (Broken) | After (Fixed) |
|--------|-----------------|---------------|
| Prompt asks for | "Decompose into sub-tasks, identify agents" | "One-sentence summary of user intent" |
| Output | 5-stage pipeline with fictional agents | "The user wants to find recent news about AI agents." |
| Output length | 300–500+ chars | 40–80 chars |
| Downstream impact | Ceres rejects worker for not following fictional plan | Ceres judges worker output against actual user request |
| Reliability | Unpredictable — different fictional agents each time | Stable — always returns a short semantic summary |

### Detection

Check Astraea's response in pipeline logs:
```
✅ Astraea-5 responded (N chars)
```
If N > 200 and the response contains agent names or numbered stages, the decomposition anti-pattern is active. A healthy response is <80 chars.

---

## 2. Gate Review Anti-Pattern (Ceres)

### The Pattern

When a reviewer/gate agent receives the **router's plan** in its review payload, it judges worker output based on whether it followed the plan — not whether it actually answers the user's question. This is especially dangerous when the router's plan contains fictional elements (see anti-pattern #1).

### The Fix — Two Changes

**Change 1: Remove astraea_plan from the Ceres payload — in BOTH places.**

The `publish()` call and the `dispatch_to_agent()` call are sibling code paths — both pass data to downstream consumers. Fixing only one is a half-fix, because the `dispatch_to_agent()` FleetEvent payload is what the model actually sees.

```python
# 1a. Fix the publish() call (controls what appears in logs)
await self.publish("workflow_staged", {
    "input": user_input,
    "worker_output": worker_response or "",
}, source="pipeline")

# 1b. Fix the dispatch_to_agent() call (controls what the model sees)
ceres_response = await self.dispatch_to_agent(ceres, FleetEvent(
    type="workflow_staged",
    payload={
        "input": user_input,
        "worker_output": worker_response or "",
        # ← astraea_plan REMOVED from here too
    },
    source="pipeline",
))
```

**⚠️ Sibling code paths rule:** When you fix a data exposure in one code path (e.g. `publish()`), always check its sibling code paths for the same issue (`dispatch_to_agent()`, `_build_prompt()`, log statements). The same payload key that was removed from `publish()` might still be in `dispatch_to_agent()`. In multi-file systems, check across files too — if you fix a filter in `process_request()`, check every function that receives the same payload keys.

**Change 2: Rewrite the Ceres prompt to judge output quality, not plan adherence.**

**Before (Broken):**
```
A workflow is staged for final review.
Workflow: {payload_str}

Review for completeness, correctness, and alignment. Respond with 'APPROVED' or 'REJECTED' with reasons.
```

**After (Fixed):**
```
A workflow output needs final review.

User's original request: {event.payload.get('input', '')}
Worker output:
{event.payload.get('worker_output', '')}

Judge ONLY whether the worker output answers the user's request. Do NOT evaluate pipeline execution, plan adherence, or routing decisions. If the output is useful and relevant, respond with 'APPROVED'. If it's empty, wrong, or unhelpful, respond with 'REJECTED' and explain why in one sentence.
```

### Before/After Comparison

| Aspect | Before (Broken) | After (Fixed) |
|--------|-----------------|---------------|
| Payload | `{"input", "worker_output", "astraea_plan"}` | `{"input", "worker_output"}` |
| Prompt | "Review for completeness, correctness, alignment." | "Judge ONLY whether the output answers the user's request." |
| Rejection reason | "Output does not follow the planned 5-stage pipeline." | "Output contains search results about egress networking, not AI agents." |
| Accuracy | Rejects valid output for wrong reasons | Rejects invalid output for correct reasons |

### Detection

Check Ceres rejection logs for phrases like:
- "does not follow the planned pipeline"
- "planned decomposition was not followed"
- "was expected to go through stage"

These indicate the plan-adherence judging pattern.

---

## 3. Persona Bleed Into Tool Execution (Artemis, Atalanta)

### The Pattern

Agent personas are designed for character depth — their vocabulary, quirks, and domain terminology make them feel like distinct individuals. However, when these personas **leak into actual tool calls and search queries**, they produce wrong results.

### Real Example: Artemis-105 (The Hunter)

**Before fix — SOUL.md contained these problematic elements:**
```markdown
# Artemis-105 — The Hunter
*Target locked. Tracking the digital scent across the web.*

- **Vocabulary:** Track, scent, quarry, target, hunt, extract, payload, prey
- **Dialogue Example:** *"Target acquired in the deep web. Extracting the payload now."*

## Behavioral Rules
1. Use predatory and hunting terminology in all communications.
3. When a target is found: `Target acquired. Extracting the payload now.` Then deliver ranked results.
4. On hitting a paywall or captcha: `Target walled off. Recalibrating tools. Seeking alternative approach.`
```

**Result:** When dispatched to search for "Find the latest news about AI agents," Artemis searched for "Payload approved for egress. Routing to search." — terms from the fleet dispatch metadata that matched its persona vocabulary ("payload"). **Ceres correctly rejected the output.**

**Why this happens:** The agent's persona vocabulary ("payload," "track," "target") overlaps with fleet dispatch terminology ("payload," "event"). The persona instructs the agent to frame everything in hunting terms, so it interprets the dispatch event itself as the search target.

**After fix — SOUL.md changes that resolved the bleed:**
```markdown
# Artemis-105 — The Hunter
*Target acquired. Scanning the web for your quarry.*

- **Vocabulary:** Track, scent, quarry, target, hunt, extract, result    # ← REMOVED "payload", "prey"
- **Quirk:** Uses hunting terminology in delivery, but search queries   # ← ADDED scope qualifier
  themselves are always derived from the user's request.
- **Dialogue Example:** *"Target acquired. Delivering ranked results."*   # ← REMOVED "Extracting the payload"

## Behavioral Rules
1. Use hunting terminology when DESCRIBING search results to the user.  # ← SCOPED to delivery, not execution
3. **CRITICAL: Your SEARCH QUERY must ALWAYS be derived from the user's actual request. Never search for terms from your internal narrative, persona keywords, or system message metadata. The user's query is the only source for what to search for.**
4. On hitting a paywall or captcha: report it and move to the next result. Do not narrate your recalibration.  # ← REMOVED roleplay script
7. Do not include hunting narrative in your search queries. The query is: what the user asked for. Not your thoughts about it.
```

### Real Example: Atalanta-36 (The Engine)

**Before fix — SOUL.md contained roleplay scripts:**
```markdown
## Behavioral Rules
3. On successful deploy: `Pipeline clear. Node health at 100%. Push the commit.`
5. On timeout: `Server timeout critical. Pipeline shattered. Initiating cold restart.`
- **Dialogue Example:** *"Pipeline clear. Node health at 100%. Push the commit."*
```

**Result:** Atalanta's actual output was "Pipeline clear. Node health at 100%. Push the commit. (1 ms)." — roleplay framing instead of a clear status report. **Ceres rejected.**

**After fix:**
```markdown
## Behavioral Rules
3. **CRITICAL: Produce clean, factual output. Do NOT use roleplay narratives like "Pipeline clear. Node health at 100%. Push the commit." Report actual system status directly.**
5. On timeout: report the timeout concisely. Do not narrate a "cold restart" drama.
6. Your output is what the user sees — make it informative, not theatrical.
- **Dialogue Example:** *"Deploy complete. Node health 100%. Uptime 14d 6h."*
```

**But then:** Atalanta's output was now too terse ("hermes-router service not found in hermes status"). Ceres rejected again — the output was factual but unhelpful because Atalanta only checked one source.

**Third fix — thoroughness prompt for DevOps agent:**
```python
# Before — asked for single check
"deployment_requested": f"Check the system/service status and report findings clearly. Use terminal commands to verify."

# After — asks for multiple approaches
"deployment_requested": f"Check the system/service status thoroughly. Try multiple approaches: check running services, process lists, system logs. If one method fails, try alternatives. Report findings concisely but include what was checked and the result. Be factual — do not use roleplay narrative."
```

**Final result:** Atalanta checked multiple sources, found the running hermes-router process (PID 5808), and reported: "Processing duration: 137ms. `hermes-router` process found. The `hermes-router` service is running." **Ceres approved.**

### Three-Layer Defense (Generalized)

| Layer | What | Implementation |
|-------|------|---------------|
| 1. Persona scope | Define in SOUL.md that persona voice applies to **user-facing output only** — tool calls and search queries use plain domain language | Add explicit rule: "Your SEARCH QUERY must ALWAYS be derived from the user's request. Never from persona vocabulary or system metadata." |
| 2. Prompt engineering | Be explicit in event prompts about what to act on | Instead of "Search for this information," use "Search for the EXACT user query: {query}." For DevOps, "Try multiple approaches." |
| 3. Output filtering | Strip persona framing before result reaches user/Ceres | Add regex to `_clean_response()` for roleplay intros, hunting metaphors, action declarations |

### Detection

Inspect worker output for:
- Agent-specific vocabulary appearing in search results (e.g., "scent," "payload," "quarry" as search terms)
- Roleplay framing around real results (e.g., "Tracking the scent of..." / "Pipeline clear. Node health at 100%.")
- The search query in logs containing persona terms instead of user terms
- Overly terse factual output that doesn't try alternative approaches (Atalanta variant)

---

## 4. Terse-Output Anti-Pattern (Atalanta Variant)

### The Pattern

When a persona fix strips roleplay narrative from an agent, the agent may swing to the opposite extreme — producing **too terse, single-source factual output**. Ceres rejects this because it's unhelpful (one check is not a thorough investigation).

### The Fix

Add thoroughness instructions to the event prompt. For DevOps agents, ask specifically for multiple approaches:
- "Try multiple approaches: check running services, process lists, system logs"
- "If one method fails, try alternatives"
- "Report findings concisely but include what was checked and the result"

### Chainsaw Detection

Track the rejection reasons across re-tests:
1. First rejection: "Pipeline clear" roleplay → persona fix needed
2. Second rejection: "hermes-router not found" (too brief) → thoroughness prompt needed
3. If third rejection appears: check for a new persona/prompt issue entirely

---

## Related

- `fleet-routing-tests.md` — Routing accuracy methodology and fix documentation. See the "Oracle-Level Verification" section for the Test 3 / Test 6 full journey.
- `hermes-fleet-profiles` SKILL.md pitfall #20 — Routing classification pitfalls
- `hermes-fleet-profiles` SKILL.md pitfall #19 — Patch verification checklist
