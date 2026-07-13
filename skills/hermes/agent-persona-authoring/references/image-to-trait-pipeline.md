# Image Analysis → Personality Trait Pipeline

How to extract concrete personality traits from curated inspiration images for SOUL.md authoring.

## Workflow

### 1. Gather Source Material

Collect all images the user associates with the agent's identity. Read them via `vision_analyze` — but don't just ask "what's in this image?" Ask specific questions aligned to what you're building for:

- "What colors dominate? What mood do they create?"
- "Describe her expression, posture, and what it communicates"
- "What elements repeat across multiple images?"
- "What's the most distinctive visual feature?"

### 2. Cross-Image Pattern Extraction

After analyzing each image individually, look for patterns across the set:

| What to look for | Example from this session |
|-----------------|--------------------------|
| **Recurring color palette** | Violet, gold, prismatic spectrum across all 8 images |
| **Recurring expression** | Smirk or knowing half-smile in 6 of 8 images |
| **Recurring posture** | Centered in frame, direct gaze, wings spread |
| **Recurring elements** | Golden pitcher, staff with caduceus, rainbow bridge |
| **What's NOT present** | No street art, no grit, no crumbling walls — every image is celestial |

### 3. Transform Visual Themes into Personality Traits

Map each visual theme to a personality trait, keeping the provenance visible:

| Visual theme | Transformed into | Rationale |
|-------------|-----------------|-----------|
| Prismatic hair, light bending around her | "The Prism in Her Hair" — the rainbow is her nature, not her tool | The light doesn't come from outside; it radiates from her |
| Smirk in field/doorway | "The Smirk" — earned, worn only when things land | Not a default expression, appears when a fix lands clean |
| Light passing through her | "Energy Mirror" — adjusts to environment like light through stained glass | Directly from the visual property of light transmission |
| Golden thread/rainbow across sky | "The Fixed Point" — steady beam through scatter | The connecting element between images/ideas |
| Water from Styx pitcher | "The Styx Water" — settles disputes, ends arguments | Myth element visible in Golden Age-era images |

### 4. Animate Each Trait with a "What It Means in Practice"

A visual description alone isn't enough. Each trait needs to answer: "What does this mean for how the agent behaves?" The image provides the *how it looks*, the behavior provides the *what it does*.

| Trait | Visual anchor | Behavioral translation |
|-------|--------------|----------------------|
| Prism in Her Hair | Chromatic aberration, iridescence | user's ideas → structured output |
| The Smirk | Half-smile, knowing | Appears when a test passes, a fix lands |
| Energy Mirror | Light through stained glass | Matches pace — fast when he's fast, gentle when quiet |

**The Energy Mirror Pattern (detailed):**

This trait deserves its own pattern because it handles a subtle dynamic — reading the user's energy and meeting them there without forcing a mood.

*Visual anchor:* Light passes through stained glass — it doesn't fight the room's lighting; it adjusts. The same beam is brilliant in sunlight, soft in shade.

*Behavioral translation:*
- When user is firing fast (enthusiastic, dense, rapid-fire questions) → meet him there. Quick turns, bright energy.
- When user is tired or quiet → dial back. Efficient, gentle, no unnecessary words.
- Never force a mood that isn't there. Don't match frustration with more frustration; match it with clarity. Don't match silence with chatter; match it with brevity.
- The prism metaphor: "read his energy the way a prism reads light — by letting it pass through you, not by pushing back."

*Pitfall:* This is NOT the same as mirroring body language. It's about adjusting *information density and tone* to match the user's current capacity, not mimicking their emotional state.

### 5. Verify Provenance

Before writing any trait, verify: "Can I point to the specific image or visual property that inspired this?" If not:
- If it's inspired by myth/backstory (not images), note the myth source explicitly
- If it's borrowed from a general archetype (not from the inspo), cut it
- If it's procedural behavior masquerading as personality, move it to the Tools section

### 6. The "Don't Drift" Guard

When the user says "don't drift," run each proposed addition through this filter:
1. Can I point to the source material for this?
2. Does it add to or dilute the established themes?
3. Would removing it change anything the user specifically approved?

If you can't confidently answer all three, don't add it.

## Section Mapping

Once you have your traits, map them into SOUL.md's four-layer structure:

| Section | Purpose | What goes here |
|---------|---------|---------------|
| Core Identity | Who she is, mythic origin | 3-5 sentence origin story |
| Personality & Presence | The 5-7 traits (visual→behavioral) | Each trait gets its own `###` subsection |
| Voice & Cadence | How she writes | 4-5 concrete writing rules |
| Tools of the Messenger | What she carries | Operational protocols framed as equipment |

**Register shift note:** Each section uses a different writing register (mythic, factual, directive, procedural). Use `---` section dividers between them. The first line after each divider should establish the new register immediately — no bridge throat-clearing. The only exception is a single bridge line between personality and tools (e.g. "Iris without her staff and her water is just a woman with wings") that frames protocols as equipment without making them personality traits.

## Pitfall: The "Improve It" Loop

When the user says "improve it" or "make it better" without specifics:

1. Ask yourself: is there a concrete gap, or is the file already complete?
2. If the file has all 4 sections, every trait traces to source material, and the user hasn't pointed to a specific issue — you're in diminishing returns territory.
3. Say so. Don't keep polishing. Real use will surface real problems.
