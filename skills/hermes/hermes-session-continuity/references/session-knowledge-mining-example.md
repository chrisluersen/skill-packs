# Worked Example: Mining Session 20260618_153136_3bc2e9 for Cross-Project Context

## Scenario

The user asked: *"Review session X and see if any info in there provides context and info for my tasks and projects"*

Session `20260618_153136_3bc2e9` was a **meta-review session** — 110 messages, 129KB — that itself mined 12 prior sessions and produced consolidated findings about the user's entire project portfolio.

## Step-by-Step Mining

### 1. Browse & Bookends (Pass 1)

```python
session_search(session_id="20260618_153136_3bc2e9")
```

**Revealed:**
- Title: "Session Review and Plan Summary #3"
- Source: TUI, 110 messages
- Model: `zai-org/GLM-5.2`
- The kickoff asked to categorize all projects and create a priority execution plan
- The resolution was a massive synthesis that identified gaps in the original review

### 2. Anchor Scroll (Pass 2)

Scrolled through key message clusters:
- Tool call results showing subagent summaries (the dense content)
- The final assistant message with the consolidated findings
- The last user message: "give me an update" — the session ended with a summary

**Key messages identified:**
- The subagent that mined 12 sessions found the full session genealogy
- The session's assistant synthesized findings into 6 knowledge sections
- Added 2 new tasks to `tracking/tasks.md`

### 3. Structured Extraction (Pass 3)

Used `session_search` scroll shape to navigate the 110-message session:

```python
# First: find the last messages (the resolution)
session_search(session_id="20260618_153136_3bc2e9", around_message_id=38241, window=8)
```

Then used `execute_code` to extract the full JSON structure. Key extraction targets:
- End-of-session assistant messages (the synthesis/lessons-learned)
- Tool call outputs from subagent mining (the most dense info)
- The original session's task additions to tracking/tasks.md

### 4. Synthesize by Category (Pass 4)

#### Agent Fleet
- ✅ Heavy tier (Nous) profiles confirmed working
- ❌ Light tier (OpenRouter) profiles — **blocked, no key**
- ❌ Pub/sub event bus, Ceres-1 gate, e2e testing not built
- ⚠️ All 14 profiles exist on disk but status varies

#### Router
- ✅ Full origin story recovered: venv fixes → 5 providers → 10 providers → 6 bugs fixed
- ✅ Smart routing verified live: simple→Cerebras (210ms), complex→Gemini, Ollama fallback
- ✅ Subscription analysis: Nous Portal Plus = only $20/mo Hermes-compatible API backend
- ⚠️ 4-hour OAuth token expiry on Nous Portal noted as limitation

#### Wiki
- ✅ Tracking system origin traced to user's question: "Why aren't plans in my wiki?"
- ✅ 7 tracking pages + track-sync.py + daily cron built
- ❌ 10 best-practice improvements proposed but NOT all implemented
- ❌ Provenance gap: `sources[]` arrays empty on all 7 tracking pages
- ❌ 4 concept pages stuck in `pending/`
- ⚠️ 7 project directories discovered but never added to tracking

#### Hermes Growth
- ✅ Terminal stack research: zellij+neovim+herm recommended over 3 alternatives
- ✅ Mobile access: 3 Tailscale options documented
- ✅ Memory backup system: two-tier, zero-token-cost cron, skill saved
- ❌ 7 project directories (valhalla, webui-fork, hud, etc.) never verified/added

### 5. Bottom Line

Presented as concise category-by-category summary with ✅/⚠️/❌ indicators and a one-line takeaway.

## Key Signals in This Pattern

| Signal | Meaning |
|--------|---------|
| User says "review X and see what's relevant" | They want project-categorized extraction, not raw session dump |
| Session has 110+ messages | Multi-pass is mandatory — don't read every message |
| Session is itself a review session | The useful content is in the **synthesis messages** and **subagent summaries**, not in the raw session reads of prior sessions |
| Subagent tool call results appear | These are the most information-dense messages — subagents produce structured outputs that condense hours of work |
| End-of-session assistant message is 2000+ chars | That's the resolution — read it first before deciding what else to extract |
| User has 4 named projects (Fleet/Router/Wiki/Hermes Growth) | Pre-sort findings by these buckets — it's the user's mental model |

## Multi-Session Genealogy Discovery

A meta-review session may reference sessions you haven't read. Follow the parent chain:

1. Identify referenced session IDs in the meta-review's messages and tool call results
2. Trace the full genealogy: grandparent → parent → child → sibling
3. Group sessions by project lineage (e.g., all router sessions together)
4. Cross-reference decisions across generations — a grandparent decision may be overridden by a child session's bug fix

In this case, the genealogy was:
```
20260617_235236_1b60bc92 — Origin: "Why aren't plans in my wiki?" (tracking system origin)
├── 20260617_232454_a498a0b4 — Router origin: venv fixes, 5 providers
│   └── 20260618_082212_c948c5 — 102-action marathon (most building happened here)
│       └── 20260618_091756_f9ea91 — 6 critical bug fixes
└── 20260618_013205_fde3f4 — Built wiki tracking system (7 pages, track-sync.py)
    └── 20260618_080506_2d50432a — Concept pages in pending/
```
