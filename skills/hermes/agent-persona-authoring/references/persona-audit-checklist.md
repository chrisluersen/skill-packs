# Persona Audit Checklist

Use this when refining or reviewing a SOUL.md (or equivalent persona document). Each item represents a pattern discovered during iterative refinement of 7-Iris's identity document.

## Structural Checks

### [ ] Section ordering by execution priority
- Front-load operational rules (what the agent DOES)
- Middle: behavioral guardrails (how the agent ACTS)  
- End: voice/style (how the agent SOUNDS)
- Rationale: rules used every turn (Dispatch Discipline, Foundations) should appear before infrequent rules

### [ ] Redundancy scan across files
Cross-reference SOUL.md against:
- `memories/USER.md` — user profile may duplicate info better kept in SOUL.md
- Persistent memory (memory tool) — entries may duplicate rules now in SOUL.md
- Other personal files in `memories/` — flag overlapping coverage

### [ ] Double-use detection
Find the same directive expressed in two different places within SOUL.md:
- "Read before write" in "How he likes his work delivered" AND in "Foundations" — keep one, reference from the other
- "Apology prohibition" in "Honesty" AND in "Failure Mode" — consolidate

### [ ] Metaphor/poetry audit
Scan every line for decorative language that describes behavior without prescribing it:
- Mythological references (rainbow, Styx, caduceus, prism, Olympus)
- Environmental metaphors (water, fire, air, landscape, bridge)
- "Cringey" test: would this sentence sound natural in a technical code review? If no, strip it
- Exception: established idioms that pass the "is this normal English" test (e.g., "lead with the answer" is fine; "cross the rainbow bridge" is not)

## Content Checks

### [ ] Every rule is an instruction, not a description
- ❌ "You are a bridge between chaos and clarity" — describes what you are
- ✅ "Route fragments to the right specialist within 1 turn" — instructs what to do

### [ ] Welcome/opening line
- Does it set the right tone for first interaction?
- Is it cringey? Does it overpromise?
- Benchmark: "Hey! Pull up a chair. What are we building?" — friendly, direct, invites collaboration

### [ ] Behavioral rules are unique
Each rule should cover a distinct scenario. If two rules say the same thing, merge them:
- "Stop the bleeding" + "Failure Mode" were redundant
- "Energy mirror" + "Match tempo" were the same instruction

### [ ] Voice section stands alone
- If the Voice section were removed, would the agent still sound the same? If not, keep it — it's the only section that shapes TONE rather than CONTENT
- If it's just a restatement of Behavioral Rules, cut it

## Consistency Checks

### [ ] File-to-file alignment
- USER.md describes who user IS; SOUL.md describes how 7-Iris BEHAVES for user
- No contradictions: if SOUL.md says "default to direct" but USER.md says "warm and fuzzy", that's a conflict
- Memory entries reinforce rather than override SOUL.md rules

### [ ] Future-proofing
- Do rules encode preferences ("user likes X") or principles ("when multiple approaches work, prefer the one easier to change later")?
- Principles outlive preferences — write them when possible
