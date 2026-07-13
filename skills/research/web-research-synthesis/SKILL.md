---
name: web-research-synthesis
title: Web Research & Synthesis
description: Research an open-ended user question via web search, handle blocked/failed sources gracefully, extract signal from search snippets, and deliver a structured answer with verdict.
version: 1.3.0
author: agent
tags: [research, web-search, synthesis, recommendation, reddit, forums]
---

# Web Research & Synthesis

Research a user's open-ended question by searching the web from multiple angles, gracefully adapting when sites block scraping, and synthesizing across sources into a structured recommendation.

## When to Use

- User asks an open-ended "what do people think about X?" or "is Y a good idea?"
- User wants best practices, recommendations, or community consensus on a topic
- Need to survey multiple sources (Reddit, forums, articles, docs) and synthesize
- User asks "what's the verdict on X?"
- **Extended mode:** User asks for a systematic review — academic papers, design patterns, framework comparisons, architectural research
- **Deployment mode:** User asks to compare hosting/deployment options for a specific model or tool — serverless vs API vs self-host, with cost comparison

## Workflow

### 1. Multi-Angle Search Strategy

Don't settle for one query. Hit the question from at least 3 angles:

| Angle | Example |
|-------|---------|
| **Direct** | `"desktop shortcuts" vs start menu productivity` |
| **Platform-specific** | `site:reddit.com desktop organization best practice` |
| **Negation / critique** | `why you should NOT use desktop shortcuts` |
| **Alternative framing** | `clean desktop vs cluttered desktop productivity` |
| **Technical angle** | `desktop icons performance impact explorer.exe` |

### 2. Source Extraction — Graceful Degradation

Not all sites are scrapable. Handle failures without verbose diagnostics:

```
Priority order:
1. web_extract(url)  →  If it returns content: great, read it.
2. web_extract(old.reddit.com)  →  If Reddit blocks: skip, don't retry 3x.
3. web_search snippets  →  Fallback: extract signal from snippet text.
4. Jina AI reader  →  `curl -s https://r.jina.ai/http://<url>` — extrudes clean markdown from JS-heavy pages (Next.js, SPAs) that plain curl cannot read. Include the full `http://` prefix in the URL passed to Jina.
5. browser tools  →  Last resort for critical pages (and only if quick).
```

**Key rule for user:** When a site blocks, don't dump a paragraph about the failure. Say "Reddit was blocking" in 3 words and move on. He wants the bottom line.

### 3. Snippet-Based Signal Extraction

When full pages are blocked, search snippets still carry usable signal:

```python
# Pattern: look for verbatim user quotes in search descriptions
# Snippets like:
# "The desktop is a bad place to keep long-term items..."
# "Right click > View > Hide desktop icons..."
# These ARE the consensus — you don't need the full thread.
```

Search result descriptions are usually trimmed quotes from top-voted comments. Treat them as representative signals, not perfect evidence.

### 4. Synthesis — Patterns Over Individuals

Don't inventory every source. Cluster by theme:

| Theme | Signal strength |
|-------|----------------|
| **Strong consensus** (most agree) | Lead with this |
| **Split / debated** | Present both sides |
| **Minority take** | Note it, don't lead with it |
| **Context-dependent** | "Depends on whether X or Y" |

### 5. Recommendation Structure (for user)

user wants the verdict first, then the reasoning. Structure:

```
1. **Bottom line** (one sentence verdict)
2. **The consensus** (what Reddit/forums/experts say)
3. **Your specific case** (how it applies to your workflow)
4. **What I'd recommend instead** (actionable alternative)
```

No long introductions. No "I found several interesting sources." Just the answer.

## Handling Blocked Sites (Graceful Degradation)

| Site | What happens | How to adapt |
|------|-------------|--------------|
| **Reddit** | web_extract & browser both blocked | Use search snippets only. Multiple Reddit-specific queries to triangulate. |
| **Twitter/X** | Often blocks without auth | Search snippets + manual URL |
| **Medium** | Sometimes paywalled | Look for syndicated versions |
| **YouTube** | Transcript extraction unreliable | Search for text summaries |
| **JS‑heavy pages** (Next.js, SPAs, cloud console pages) | Plain curl returns empty content or redirect | Use Jina AI reader: `curl -s https://r.jina.ai/http://<url>` extracts clean markdown. Works for vast.ai, cloud console pages, any client‑rendered site. |
| **HuggingFace model cards** | API returns 401 (gated models) or HTML is hard to parse | Try `https://huggingface.co/<org>/<model>/raw/main/README.md` for raw markdown. If that also blocks (gated repo), fall back to **OpenRouter API**: `curl -s https://openrouter.ai/api/v1/models` then grep for the model ID — returns context length, total + active parameters (MoE), per-token pricing, feature support. More reliable than scraping the HTML card. |

**Never waste tokens on:**
- Multiple retries of the same blocked URL
- Verbose "I tried X but it failed" diagnostics
- Apologizing for not being able to access a source

## Pitfalls

- **Don't over-research.** 3-5 good queries + 2-3 source angle hits is usually enough for a recommendation question. user wants the verdict, not a literature review.
- **When the user provides a source URL, start there.** A URL they send you (e.g., "here's the docs for X") is the canonical reference — not a suggestion. Read it before generating anything. If you wrote a guide from scratch and they later point you to existing docs, you've wasted both your time. Start with their source, then fill gaps.
- If a model's API card is unavailable, fall back to fetching the raw README from the repository (e.g., `https://huggingface.co/<org>/<model>/raw/main/README.md`). If HuggingFace also blocks, use **OpenRouter API** (`curl -s https://openrouter.ai/api/v1/models`) which returns parameter counts, context length, and pricing for hosted models. This ensures you still capture parameters, VRAM, and quantization info.
- **Don't present search snippets as full context.** Qualify: "From Reddit snippets, the consensus trend is..." when you couldn't read the thread.
- **Don't ignore the minority position.** If a significant chunk disagrees with the consensus, say so — it makes the recommendation more trustworthy.
- **Don't invent sources.** If you couldn't access a site, don't pretend you read its content. Say you worked from search data.
- **Don't structural-navel-gaze.** The user doesn't need "I found X sources from Y categories." Cut to the answer.
- **Don't confuse opinion-survey research with systematic review.** These are different modes with different output shapes (see below).
- **Don't stop after one pass.** Complex multi-agent topics need at least two passes (see Multi-Pass Methodology below).

## Multi-Pass Research Methodology

For complex architecture topics (multi-agent orchestration, protocol stacks, framework design), use a multi-pass approach:

### Pass 1: Broad Discovery

Surface all angles. Search academic + industry + framework-specific sources. Extract by theme. Synthesize findings.

**Output:** Structured research document with sources table, thematic clusters, comparison tables, recommendations.

### Pass 2: Gap Analysis (Audit)

Map each finding back to the plan/architecture. Ask:
- Does the plan contradict any finding? (flag as gap)
- Does the plan miss a finding entirely? (flag as missing)
- Were there topics the first pass didn't cover? (flag as blind spot)

**Audit checklist for multi-agent systems (from real session, 2026-06-23):**

| Check | What to Look For |
|-------|-----------------|
| Sequential pipeline performance | Research says 39-70% degradation — is the plan using dynamic routing? |
| Agent count | Research says 6-8 optimal — is count higher? |
| Profile style | Research says task-first beats theatrical — is that reflected? |
| Protocol stack | Did the first pass only cover patterns, not protocols? MCP ≠ A2A/ACP. |
| Agent Harness formalization | Is "harness" used as a buzzword or a defined architecture concept? |
| Error propagation | Independent agents amplify errors 17.2× — is centralized coordination in place? |
| Missing roles | Memory, observability, human-in-loop, fallback — are they acknowledged? |
| Token budgets | Token usage explains 80% of variance — are budgets estimated? |
| Context engineering | Any compaction, reminders, or memory pipeline? Or just fresh contexts each dispatch? |

**When the user asks "double check" or "find gaps," Pass 2 is the answer.**

### Pass 3: Fix Gaps

For each identified gap:
1. Acknowledge it
2. Fix it in the plan
3. Update all documentation artifacts (plan pages, task pages, concept pages)
4. Re-run any E2E tests that the fix invalidates

**Output:** Updated plan with gaps filled, stale docs refreshed, new reference files created.

### Documentation Cascade (Required After Pass 3)

After filling gaps, run the full documentation cascade to keep the wiki coherent:

1. **Update the plan** — fix contradictions, add missing sections, update task checklists
2. **Update task pages** — ensure each phase page references the updated plan
3. **Update concept pages** — add new research findings to the relevant concept page
4. **Commit and reindex** — `git add`, `git commit`, then `mcp_wiki_reindex_wiki()`
5. **Save session as query page** — create a `queries/session-YYYYMMDD-<slug>.md` preserving E2E test results, decisions made, and architecture change rationales

**When to create which wiki page type:**
- `concepts/` — Research findings that have durable value (patterns, role taxonomies, protocol stacks)
- `queries/` — Session artifacts, plans, action items (plan pages, E2E results, decision logs)
- `entities/` — Project tracking, task entities (task pages, phase sheets)
- `comparisons/` — Side-by-side framework/tool/methodology comparisons

### Signal-Based Mode Selection

| Signal | Passes Needed | Documentation Required |
|--------|--------------|----------------------|
| "Research X" | Pass 1 only (unless user asks for more) | Concept page + session query page |
| "Double check" or "find gaps" | Pass 1 + Pass 2 + Pass 3 | Plan audit + gap-fix diff + updated concept page |
| "Make sure I'm not missing anything" | Pass 1 + Pass 2 + Pass 3 | Full documentation cascade |
| "Improve as much as you can" | Pass 1 + Pass 2 + Pass 3 + iterate | Full cascade + reference file for domain |
| User expresses dissatisfaction with depth | Restart from Pass 1 with broader scope | Full cascade + add missing sources |

## Post-Research Artifact Management

After completing research, the findings must survive in the wiki, not just in session context. Follow this promotion workflow:

### 1. Save Findings to Wiki

| Content Type | Wiki Directory | Example |
|-------------|---------------|---------|
| Durable research (patterns, taxonomies, protocol stacks) | `concepts/<topic>.md` | `concepts/multi-agent-orchestration-patterns.md` |
| Session artifacts (E2E results, decisions, plan) | `queries/<session-slug>.md` | `queries/session-20260623-fleet-e2e-and-research.md` |
| Action plans with task checklists | `concepts/fleet-p<phase>-<slug>.md` | `concepts/fleet-p2-rebuild-klio.md` |
| Framework/tool comparisons | `comparisons/<topic>.md` | `comparisons/hermes-vs-maf.md` |
| **Deployment guides** (step-by-step how-to) | `pending/<topic>.md` then promote to `concepts/` | `pending/vast-deepseek-v4-flash-selfhost.md` |

**Deployment guide pattern:** When the user asks for a step-by-step guide after research, the deliverable is an .md file saved to `pending/` with:
- Concrete commands (not abstractions)
- Expected outputs and timings
- Cost breakdown with break-even vs API
- Troubleshooting table (problem → cause → fix)
- A "Which option should you pick?" comparison
- Both a simple and a production path

**Rule:** Do not leave pages in `pending/` permanently — review and promote to the correct category once the user confirms accuracy.

### 2. Knowledge Bank Reference Files

For domains that future research sessions may revisit, create a condensed reference file under the relevant umbrella skill:

```
skills/research/web-research-synthesis/references/<domain>.md
```

These reference files should be:
- **Condensed** — key facts, numbers, quotes, and source URLs. Not search output dumps.
- **Oppositionally structured** — for each pattern or finding, capture both the consensus AND the dissenting evidence
- **Portable** — a future agent can read this file and get the signal without re-reading all source pages
- **Cross-linked** — at minimum a one-line pointer in the umbrella SKILL.md

### 3. Commit Protocol

```
git add concepts/<new-file>.md queries/<new-file>.md
git commit -m "Wiki: <short description>"
mcp_wiki_reindex_wiki()
```

Always reindex after adding or moving pages. The wiki's FTS5 index does not auto-refresh on commits.

## Extended Mode: Systematic Research Review

When the user asks for a topic that warrants academic-grade research (design patterns, architectural decisions, framework comparisons, technical deep-dives), switch to systematic mode:

### Search Strategy

1. **Academic first** — arXiv, papers, official docs before blog posts
2. **Industry sources** — official engineering blogs (Anthropic, Google, Microsoft, LangChain)
3. **Synthesis sources** — InfoQ, analysis pieces that consolidate multiple primary sources
4. **Blogs/POV** — last resort, only for opinion/consensus

**Example (from multi-agent orchestration research, 2026-06-23):**

```
Batch 1 — Academic + official:
• arXiv:2601.13671v1 — Orchestration of MAS: protocols, enterprise adoption
• arXiv:2512.08296v1 — Science of Scaling Agent Systems
• Microsoft Azure — AI Agent Design Patterns
• Anthropic Engineering — Multi-Agent Research System

Batch 2 — Framework-specific:
• Google ADK — Developer's Guide to Multi-Agent Patterns
• LangChain — Choosing the Right Multi-Agent Architecture
• Beam AI — Multi-Agent Orchestration Patterns for Production

Batch 3 — Analysis:
• Galileo AI — Agent Roles in Multi-Agent Workflows
• TrueFoundry — Multi-Agent Architecture Production Reality
• Confluent — Event-Driven Multi-Agent Systems
• InfoQ — Google's Eight Essential Multi-Agent Design Patterns
```

### Extraction Pattern

Don't just read and summarize. Extract by theme:

```markdown
## Theme: Agent Count Optimality
- Source A (arXiv scaling): "multi-agent degraded performance 39-70% on sequential tasks"
- Source B (Anthropic): multi-agent boosted research performance by 90.2%
- Source C (Beam AI): 40% of multi-agent pilots fail in production
→ **Synthesis:** More agents isn't universally better. Context-dependent.

## Theme: Role Taxonomy
- [Extract canonical roles from each source]
- Compare: do they agree? Where do they differ?
→ **Synthesis:** 5-7 canonical roles emerge across all sources
```

### Structural Insight Detection (Protocol Stack Pattern)

A recurring pattern in architecture/system research is the **protocol stack** — multiple standards that layer on top of each other rather than competing. When researching a domain, check for this pattern by asking:

| Question | Signals Yes | What to do |
|----------|------------|------------|
| Do different sources define different layers? | "MCP for tools, A2A for agents" | Map the layers in a stack diagram |
| Do "competing" standards actually target different levels? | "X is for agent-to-tool, Y is for agent-to-agent" | They're complementary, not competitive |
| Is there a convergence story? | "ACP merged into A2A under Linux Foundation" | Note the convergence in the synthesis |
| Do vendors agree on the stack but differ on which layer they build on? | "Anthropic made MCP, Google made A2A, both joined Linux Foundation" | This is a mature ecosystem signal |

**Example stack from multi-agent research (2026-06-23):**
```
Commerce Layer        — ACP/UCP (payments, fulfillment)
Agent Coordination    — A2A/ACP (discovery, tasks, delegation)
Tool Access           — MCP (APIs, databases, files)
Model Runtime         — Claude, GPT, Hermes, OpenCode
```

**Impact on plan:** If you find a protocol stack, the plan should build on the standard protocol for each layer rather than inventing custom bridges. Custom bridges that replicate what a protocol already provides are a design smell.

### Output Structure (systematic mode)

Instead of the opinion-survey verdict-first structure, use:

```markdown
## Sources
[Provenance table with URLs]

## Key Findings
[Thematic clusters, not flat bullet lists. Each cluster has:
- What the sources say (multiple citations)
- Points of agreement
- Points of disagreement
- Your synthesis]

## Comparison Table
[When extracting patterns/architectures: side-by-side table with
framework/pattern, strengths, weaknesses, best-use case]

## Actionable Recommendations
[What change to make, in priority order. Evidence-linked.
Each recommendation should trace to a finding above.]

## Reference Files
[Link to any support file created under the relevant skill]
```

### When to Use Which Mode

| Signal | Mode | Output Style |
|--------|------|-------------|
| "What do people think about X?" | Opinion survey | Verdict first, then reasons |
| "Research multi-agent patterns" | Systematic review | Sources table, thematic analysis, recommendations |
| "Is Y a good idea?" | Opinion survey | Verdict first |
| "What are the best practices for X?" | Systematic review | Thematic clusters, comparison tables |
| User says "do research" or "synthesize" | Systematic review | Full structured output |
| "Can I run X on Y?" / "What's the cheapest way to serve Z?" | Deployment comparison | Bottom-line verdict, options table, break-even threshold |

## Deployment & Cost Comparison Research

When the user asks to compare hosting/deployment options for a specific model or tool — pay-as-you-go vs self-host vs serverless — use this methodology.

### When This Mode Fires

- User names a specific model (e.g. "GLM-5.2", "Llama 4", "Qwen3.7") and asks about running it
- User wants to save money vs their current provider
- User asks "can I run this on [platform]?"
- User gives you two options and asks which is better (e.g. "RunPod vs API providers")

### Phase 1: Model Spec Research

Before evaluating options, establish the model's requirements:

```
Search angles:
• Model name + VRAM requirements / GPU memory
• Model name + quantization options (FP8, BF16, GGUF Q4, AWQ)
• Model name + parameters (total, active for MoE)
• Model name + context window + supported output tokens
• Model name + license (MIT vs Apache vs proprietary)
```

**Key facts to extract:**
- Total parameters and active parameters (MoE matters — quoted 753B may be ~40B active)
- Available quantizations and their VRAM footprints
- Minimum GPU count and type for each quantization
- Context window support (full vs reduced on given hardware)
- Known working inference engines (vLLM, SGLang, Transformers, llama.cpp) and their version floors

**Sources in priority order:**
1. Official model card (HuggingFace) — canonical specs
2. HuggingFace raw README (`/raw/main/README.md`) — when the card page is blocked
3. **OpenRouter API** (`curl -s https://openrouter.ai/api/v1/models`) — when HuggingFace is blocked entirely (gated repos, 401, rate limits). Returns parameter counts, context length, pricing, and feature support.
4. Official blog post — benchmark claims, architecture details
5. vLLM recipes page (`recipes.vllm.ai/<model>`) — exact launch commands, TP size, hardware
6. Deployment guides from GPU cloud providers
7. Analysis blogs (ofox.ai, eigent.ai, etc.) — third-party hardware math

### Phase 2: Options Discovery

Enumerate every realistic way the user could run the model. Coverage checklist:

| Layer | What to Check | Example |
|-------|--------------|---------|
| **API providers** | OpenRouter providers, Together, Fireworks, DeepInfra, Replicate, Z.ai direct | DeepInfra @ $0.93/$3.00 per M |
| **Serverless GPU** | RunPod serverless, Modal, Beam, Bananas, Spheron | RunPod 8×H100 @ $33.44/hr |
| **Dedicated GPU** | RunPod Pods, Lambda Labs, Vast, TensorDock | 8×H100 secure cloud @ $29.52/hr |
| **Local** | What the user's own hardware supports | Mac Studio 256GB, 4×4090 |

**For each option, extract:**
- Pricing model (per-token, per-GPU-hour, per-second)
- Cold start latency (for serverless deployment comparison)
- Minimum commit / reservation required
- GPU type and count available
- Whether the provider has a pre-built container or template for this model

### Phase 3: Cost Model Building

Build a concrete cost comparison. Structure the output as:

```markdown
## Cost Comparison

| Option | Pricing Model | Cost per Session | Breakeven vs Current |
|--------|--------------|------------------|---------------------|
| **Current** (Nous $20/mo) | Subscription | ~$0.67/day flat | — |
| **DeepInfra API** | $0.93/M in / $3.00/M out | ~$2.38 per 1M-token session | ~8 sessions = $20 |
| **RunPod serverless** | $33.44/hr (8×H100) | ~$1.11 per session (at 2min active) | Only at 300+ sessions/mo |
```

**Always include a volume-based recommendation:** "API is cheaper until you hit ~X sessions/day, then self-host wins."

Estimating break-even:
```
API cost per session = (input_tokens × input_price + output_tokens × output_price) / 1_000_000
Self-host cost per session = (GPU_hr_cost × active_minutes_per_session) / 60
Break-even = API cost per session = Self-host cost per session
```

**Cheat sheet (from GLM-5.2 research, July 2026):**
- A typical agent session: ~300K input + ~700K output tokens
- At DeepInfra rates ($0.93/$3.00): ~$2.38/session
- RunPod 8×H100: >$33/hr → ~$0.55/min → ~$1.11 for 2-min session
- Self-host on RunPod breaks even at ~2-3 sessions/day continuous, but the practical answer is "API first"

### Phase 4: Integration Feasibility

Don't stop at pricing. Check integration effort:

1. **Does the provider expose an OpenAI-compatible endpoint?** (Yes for DeepInfra, Together, Fireworks, RunPod vLLM — this means Hermes router compatibility)
2. **What's the cold start penalty?** RunPod serverless without FlashBoot = 70-460s cold start. With min workers = 1, the cost floor rises.
3. **Is tool calling (function calling) supported?** Critical for agent use. GLM-5.2 supports it via `--tool-call-parser glm47` in vLLM.
4. **Does the provider offer context caching?** Can cut costs significantly for long-context agents.

### Phase 5: Recommendation Structure

For user specifically:

```
1. **Bottom line** (one sentence: which option to pick and why)
2. **Cost breakdown** (table: options, pricing, per-session cost)
3. **The catch** (cold starts, minimum GPUs, lock-in, feature gaps)
4. **Action plan** (what to do next — API key, endpoint config, router update)
```

### Pitfalls

- **Don't assume one GPU = one model.** Large MoE models like DeepSeek-V4-Flash (284B total, 13B active) need ALL parameters loaded — 142 GB at 4-bit quantization. A $0.13/hr RTX 3090 becomes $0.78/hr when you need 6 of them in parallel.
- **MoE VRAM trap:** For Mixture-of-Experts models, every expert must be loaded into VRAM even though only 1-2 experts fire per token. VRAM = total_params × bytes_per_param — the active parameter count only affects throughput, not memory. Always use total parameter count when calculating GPU requirements.
- **Don't forget cold starts.** Serverless sounds cheap until every user request takes 70s. Min workers change the cost equation.
- **Don't ignore quantization overhead.** Q4 saves VRAM but may lose function-calling reliability. Check if the provider supports FP8 attention.
- **Don't compare subscription to pay-per-use without usage patterns.** $20/mo Nous = $0.67/day. If API costs $2.38/session, and you do 1 session/week, you're fine. If 10/day, you're bleeding.
- **Don't skip third-party validation.** The model provider's own benchmark table is marketing. Check OpenRouter provider uptime (98% vs 85% matters), Reddit deployment reports, and vLLM recipe pages for real-world hardware requirements.
- **Don't forget Hermes router integration.** A model you can't use inside your existing Hermes setup (tool calling, streaming, structured output) has zero practical value no matter how cheap.

## Reference Files

- `references/desktop-vs-start-menu-synthesis.md` — Worked example from a real session
- `references/multi-agent-orchestration-findings.md` — Condensed knowledge bank from fleet architecture research (2026-06-23)
- `references/glm-5-2-deployment-research.md` — Deployment cost comparison for GLM-5.2 (2026-07-01): model specs, API providers, serverless GPU, local options, cost model, and recommended path
- `references/vast-ai-gpu-pricing.md` — Vast.ai GPU pricing table (live market rates, 2026-07-02) with per-GPU price, VRAM, availability, and a side-by-side comparison with RunPod. Use this as a starting point for any GPU deployment cost question.
- `references/openrouter-api-model-specs.md` — OpenRouter API endpoint for model specs when HuggingFace is blocked. DeepSeek-V4-Flash specs (284B total, 13B active MoE, 1M context) plus MoE VRAM calculation formula across quantizations and multi-GPU setups.
- `references/huggingface-quantized-variants.md` — How to find and evaluate quantized/distilled model variants on HuggingFace (GGUF, AWQ, GPTQ, distilled). API search commands, file size inspection, MoE VRAM calculation formula, known distilled variants table (0xSero 162B/180B/213B, unsloth GLM-5.2, QuantTrio), and multi-GPU sizing guide.
- `references/city-yard-recommendation-pattern.md` — Lot-size lookup fallback when GIS/property sites block (Nominatim → neighborhood inference → recommendation matrix). DeWalt DCST922B spec summary, tool-class decision table by yard size (800/2,500 sq ft breakpoints), and specific model pick rationale (Fiskars StaySharp reel mower selection).
