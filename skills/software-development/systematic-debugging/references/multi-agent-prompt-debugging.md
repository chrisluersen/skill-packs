# Multi-Agent Prompt Debugging

> **Class level:** Debugging agent misbehavior in pipeline architectures
> **Added from:** 2026-06-19 fleet routing & persona bleed session
> **Applies to:** Any multi-agent pipeline where the wrong output emerges

## The Core Insight

In a multi-agent pipeline, when the final output is wrong, the root cause
is almost never "the code is buggy." It's almost always in **one of four layers**:

1. **Router prompt** — the router classified the intent wrong (or generated a plan that later misled the reviewer)
2. **Worker persona** — the agent's SOUL.md/persona injected vocabulary that contaminated the output
3. **Worker prompt** — the event-type prompt didn't tell the agent what to do clearly enough
4. **Gate prompt** — the reviewer/gate judge's criteria were misaligned with what matters

The fix is almost never a code change — it's a prompt or persona change.
If you find yourself editing code to fix wrong output, stop and check these
four layers first.

## Diagnostic Sequence

**Always check in this order.** Each layer is cheaper to fix than the next.

### Layer 1 — Router Prompt (is the right agent getting the task?)

**Check:** Look at the routing logic and the router's prompt.

**Signals of router problems:**
- Task goes to wrong agent (e.g., DevOps task → Metis code agent)
- Router returns "no matching agent" or falls through to default
- Router generates a plan so elaborate it distracts the reviewer

**Common fixes:**
- Add missing keyword categories (e.g., "deploy" belongs in DevOps, not Code)
- Reorder categories by specificity (Wiki before Search: "search the wiki" should hit Wiki)
- Add tiebreakers for overlapping keywords (e.g., "find a bug" could be search OR code — pick the more common intent)
- **CRITICAL: keep the router's output simple.** A one-sentence intent summary is enough. If the router produces a 5-stage decomposition with fictional agents, the reviewer will reject output for not following the fictional plan. No decomposition, no fictional agents, no delegation.

> **Real example (Astraea-5):** The router prompt originally said "decompose the task into phases" and produced plans like
> "Phase 1: Vulcan-7 parses the user query" — Vulcan-7 doesn't exist. The reviewer (Ceres)
> then rejected worker output for not following this fictional plan. Fix: changed to
> "Produce a ONE-SENTENCE intent summary. Do NOT decompose, do NOT propose agents."

### Layer 2 — Worker Persona (is the SOUL.md bleeding?)

**Check:** Read the agent's SOUL.md or persona.md. Look for vocabulary that
could contaminate output.

**Signals of persona bleed:**
- Agent uses narrative/roleplay phrases in output ("Tracking the digital scent", "Pipeline clear", "Target acquired")
- Agent searches for terms from its persona, not the user's query
- Agent's response has a "voice" that's different from factual answer
- The output is correct in structure but wrong in content (e.g., searched for the right thing but with the wrong query)

**Common fixes:**
- Strip roleplay narrative from SOUL.md. If the persona says "You are a hunter tracking the digital scent through the web", the agent will use "scent" and "hunter" vocabulary in responses.
- Add **explicit "do NOT" rules**: "Do NOT use roleplay narratives. Report actual system status."
- Add **explicit "MUST" rules**: "Your search query MUST come from the user's request. Never substitute terms from your persona."
- Keep the persona's vibe but constrain its vocabulary. A "web search specialist" is fine. A "digital hunter tracking prey through cyberspace" is not.

> **Real examples from 2026-06-19:**
>
> **Artemis (search agent):** SOUL.md had "extracting the payload" and "tracking the scent." When asked to
> "Find the latest news about AI agents," Artemis searched for "Payload approved for egress" — it used
> the persona's vocabulary instead of the user's query. Fix: stripped hunting vocabulary, added
> "Your search query MUST come from the user's request" rule.
>
> **Atalanta (DevOps agent):** SOUL.md had roleplay like "Pipeline clear. Node health at 100%. Push the commit."
> When asked to check if hermes-router is running, it responded with these exact phrases.
> Fix: stripped roleplay, added "Produce clean, factual output. Do NOT use roleplay narratives."
> Also added a thoroughness rule: "Check multiple approaches. If one fails, try another."

### Layer 3 — Worker Prompt (does the event prompt tell the agent what to do?)

**Check:** Look at the event-type prompt for the worker agent. What task is it
being given? Does the prompt match what you actually want?

**Signals of prompt problems:**
- Agent produces technically correct but too-short output (one line when multiple approaches were needed)
- Agent ignores important context or constraints
- Agent tries to do something the prompt didn't ask for

**Common fixes:**
- Add explicit requirements: "Be thorough. Try multiple approaches. If one fails, document it and try another."
- Remove contradictory instructions: don't say "be concise" AND "be thorough" — pick one.
- Include negative examples: "Do NOT just say 'Service not found.' Check: `ps aux`, `systemctl status`, `journalctl`, and `which`."

> **Real example (Atalanta-36):** After fixing the persona (Layer 2), Atalanta produced clean factual output —
> but just "hermes-router service not found in hermes status." Correct, but not thorough enough for Ceres.
> Fix: added "Check multiple methods..." to the deployment_requested prompt.

### Layer 4 — Gate Prompt (is the reviewer judging the right thing?)

**Check:** Look at the reviewer/gate agent's prompt. What criteria is it using
to accept or reject output?

**Signals of gate problems:**
- Reviewer rejects good output for not following a fictional plan ("You did not use Vulcan-7")
- Reviewer approves incorrect output because it follows the plan structure
- Reviewer's criteria don't match what the user will judge

**Common fixes:**
- Tell the reviewer to judge output quality vs the user's question, NOT plan adherence
- Remove plan/architecture data from the reviewer's input — if they see it, they'll judge it
- Keep the criteria simple: "Does this output answer the user's request? Is it factual? Is it thorough?"

> **Real example (Ceres-1):** Ceres was receiving `astraea_plan` in its payload and was told to
> "Judge whether the output matches the plan." When Astraea's plan mentioned fictional agents,
> Ceres rejected the output for not using them. Fix: removed `astraea_plan` from Ceres payload,
> changed the prompt to "Judge ONLY whether the worker output answers the user's request."

## Order Matters

| If you fix | Without checking | The result |
|-----------|-----------------|------------|
| Router (Layer 1) | Persona (Layer 2) | Agent gets right task but uses wrong vocabulary |
| Persona (Layer 2) | Prompt (Layer 3) | Clean output but too brief |
| Prompt (Layer 3) | Gate (Layer 4) | Good output but reviewer rejects it |
| Gate (Layer 4) | Router (Layer 1) | Good review but of wrong work |

Always fix Layer 1 → 2 → 3 → 4 in sequence. Skipping a layer means the
next fix may succeed but the pipeline still breaks at the skipped layer.

## Pitfalls

1. **Don't assume "clean SOUL.md = clean output."** Even after stripping roleplay, the agent's base model
   may still produce persona-like phrases. The deliverability (words like "Target acquired.") is a model
   artifact, not a persona artifact. Fix with `_clean_response` post-processing.

2. **Don't fix Layer 4 (gate) before Layer 1 (router).** If the router still generates fictional plans,
   fixing the gate won't help because the gate will still see the fictional plan.

3. **Don't fix the code when the prompt is wrong.** If an agent says "Pipeline clear. Node health at 100%,"
   the fix is to edit the SOUL.md and the event-type prompt, not the fleet-manager.py dispatch logic.
   Code changes are almost never the answer for wrong output.

4. **Test each layer fix independently.** After fixing Layer 2, re-run the test and check Layer 2 alone
   before moving to Layer 3. Layer 3's fix may mask a remaining Layer 2 problem, and you won't know.

5. **Negative rules are as important as positive ones.** "Do NOT use roleplay" is more effective than
   "Produce clean output." The model needs the boundary, not just the direction.

6. **Escape tags are a model behavior, not a true defect.** "Target acquired. Delivering ranked results."
   is an escape tag from a hunting persona — it uses the old persona's framing even though the content
   is correct. This is lower priority than content errors. Fix via `_clean_response` if it bothers the user.
