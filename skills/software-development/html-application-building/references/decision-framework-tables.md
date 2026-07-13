# Decision Framework Tables for Technology Choices

A documentation pattern for technology choice tables that goes beyond "what" and "why" to provide **actionable decision guidance** — explicit use/don't-use scenarios, cost trade-offs, and upgrade triggers.

---

## The Pattern

Replace simple `Why` columns with **`Why — Decision Framework`** columns containing:

```
<choice> = <value proposition>
<strong>Pick this if:</strong> <condition 1>, <condition 2>
<strong>Don't pick if:</strong> <condition 3>
<strong>Upgrade trigger:</strong> <when to move to the next tier>
<strong>Cost control:</strong> <specific numbers or ratios>
```

Add a companion **Decision Guide table** mapping user situations to ✅/❌ recommendations.

---

## Example: Simple vs End Game Stack (AI Architecture.html)

### Layer Table with Decision Framework

| Layer | Choice | Why — Decision Framework |
|-------|--------|--------------------------|
| **Model** | Ollama local (qwen2.5:7b) **or** OpenRouter API | **Ollama** = $0/month, private, offline, no API keys. **Pick if:** GPU 8GB+ VRAM, privacy-sensitive, zero recurring cost. **OpenRouter** = 100+ models, ~$0.15/M tokens. **Pick if:** no GPU, need frontier (Claude 4, GPT-4o). **Switch anytime** with `hermes config set`. |
| **Platforms** | CLI + TUI only | No gateway = no daemon, no tokens, no exposed ports. **Perfect for:** solo dev, learning. **Upgrade trigger:** want Telegram bot or cron while sleeping. |

### Decision Guide Table

| Your Situation | Recommendation |
|----------------|----------------|
| First-time user | ✅ Start here — learn core loop first |
| Budget $0/month | ✅ Ollama + local tools = free |
| Need Discord bot | ❌ **Need End Game** — requires Gateway |
| Run 5+ parallel agents | ❌ **Need End Game** — multi-agent delegation |
| Team sharing agent | ❌ **Need End Game** — platform threads isolate context |

---

## Template Structure

### 1. Layer Comparison Table

```html
<table>
  <thead>
    <tr><th>Layer</th><th>Choice</th><th>Why — Decision Framework</th></tr>
  </thead>
  <tbody>
    <tr>
      <td data-label="Layer"><strong>Component Name</strong></td>
      <td data-label="Choice">Option A <em>or</em> Option B</td>
      <td data-label="Why — Decision Framework">
        <strong>Option A</strong> = <value prop>. <strong>Pick if:</strong> <conditions>.
        <strong>Option B</strong> = <value prop>. <strong>Pick if:</strong> <conditions>.
        <strong>Switch:</strong> <how to toggle>.
      </td>
    </tr>
  </tbody>
</table>
```

### 2. Decision Guide Table

```html
<table>
  <thead>
    <tr><th>Your Situation</th><th>Recommendation</th></tr>
  </thead>
  <tbody>
    <tr>
      <td data-label="Your Situation"><strong>Common scenario</strong></td>
      <td data-label="Recommendation">✅ <action> — <reason></td>
    </tr>
    <tr>
      <td data-label="Your Situation"><strong>Anti-pattern scenario</strong></td>
      <td data-label="Recommendation">❌ <strong>Need [Other Stack]</strong> — <why></td>
    </tr>
  </tbody>
</table>
```

---

## Required Elements per Row

| Element | Purpose | Example |
|---------|---------|---------|
| **Value proposition** | One-line "what it gives you" | "$0/month, private, offline" |
| **Pick if** | Positive conditions | "GPU 8GB+, value privacy" |
| **Don't pick if** | Explicit anti-conditions | "need frontier models, no GPU" |
| **Upgrade trigger** | When to move to next tier | "want Discord bot → End Game" |
| **Cost control** | Specific numbers | "80/20 cheap/frontier = ~$15-30/mo" |
| **Switch mechanism** | How to change without rewrite | "`hermes config set` — no code changes" |

---

## CSS for Decision Tables

```css
/* Enhanced decision framework tables */
.decision-table td:nth-child(3) {
  font-size: 13px;
  line-height: 1.7;
}
.decision-table td:nth-child(3) strong {
  color: var(--accent-primary);
}
.decision-guide td:nth-child(2) {
  font-size: 13px;
}
.decision-guide td[data-label="Recommendation"]:contains("✅") {
  color: var(--accent-green);
}
.decision-guide td[data-label="Recommendation"]:contains("❌") {
  color: var(--accent-red);
}
```

---

## When to Use This Pattern

| Document Type | Apply Pattern? |
|---------------|----------------|
| Technology stack guides | ✅ Always |
| Tool comparison pages | ✅ Always |
| Architecture decision records (ADRs) | ✅ Yes |
| "Getting started" pages with multiple paths | ✅ Yes |
| Simple feature lists | ❌ Overkill — use arrow lists |
| API reference docs | ❌ Use standard tables |

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails | Fix |
|--------------|--------------|-----|
| "Why: It's fast" | No decision guidance | "Pick if: latency critical. Don't pick if: batch processing OK" |
| Missing upgrade trigger | User stays on wrong tier forever | "Upgrade trigger: need X → move to Y" |
| No cost numbers | Hidden ongoing expense | "Cost control: 80/20 split = $X/mo" |
| "Use X for everything" | Ignores context | Split into "Pick if / Don't pick if" |
| No switch mechanism | Lock-in fear paralyzes choice | "Switch: `config set` — no code change" |

---

## Session Origin

This pattern emerged from the **AI Architecture.html Phase L** enhancement of the Simple Stack (§01) and End Game Stack (§02) sections.

**File:** `~/AppData/Local/hermes\AI Architecture.html` (189 KB, 16 sections)

**Before:** Single "Why" column with one-line explanations  
**After:** "Why — Decision Framework" column + Decision Guide tables

**Metrics:**
- Simple Stack: 7 layers × decision framework + 8-scenario decision guide
- End Game Stack: 7 layers × decision framework + 9-scenario decision guide
- File size increase: ~4 KB (acceptable for massive clarity gain)

---

## Related Patterns

- `references/content-deduplication-patterns.md` — Consolidation with cross-links instead of duplicate tables
- `references/social-meta-tags.md` — OG/Twitter cards for sharing decision guides
- `html-doc-ux` skill — Back-to-top, scroll progress, focus mode for long decision docs

---

## Implementation Checklist

- [ ] Every layer row has all 5 elements (value, pick-if, don't-pick-if, upgrade-trigger, cost/switch)
- [ ] Decision Guide covers top 5-10 user situations (mix of ✅ and ❌)
- [ ] Cross-links from guide to canonical layer row
- [ ] Cost numbers are specific (not "low"/"high")
- [ ] Switch mechanism is a real command the user can run
- [ ] Anti-pattern scenarios explicitly marked with ❌ and alternative