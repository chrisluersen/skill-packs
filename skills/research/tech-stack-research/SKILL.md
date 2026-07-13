---
name: tech-stack-research
description: "Investigate what tools, software, and workflows people and organizations use by examining public signals (social media, GitHub, docs) with proper source verification and inline citation."
version: 1.0.0
author: agent
tags: [research, verification, social-media, sourcing, twitter, people]
created_from_user_sessions: true
---

# Tech Stack Research

Investigate a person's or org's tooling, workflow, and setup preferences by analyzing their public social media presence. Includes source verification methodology and citation formatting.

## When to Use

- User asks "what tools does X use?" or "what's Y's workflow?"
- User asks about team preferences or tool adoption patterns
- Need to verify a claim before presenting it as fact
- Researching how specific people/teams work

## Methodology

### 1. Gather Raw Evidence from Twitter/X

Extract the person's recent posts. Key patterns to look for:

- **Direct mentions**: Posts naming specific tools (Cursor, VS Code, Claude Code, etc.)
- **Screenshots**: Often reveal the actual IDE, terminal theme, OS, file browser
- **Replies to others**: Sometimes more revealing than main posts
- **Thread posts**: Look at chain for additional context
- **Reposts/Quotes**: What they amplify tells you what they care about

Search operators:
```
from:@username toolname             # direct mentions
from:@username "vscode"             # exact phrase
from:@username desktop OR terminal  # workflow signals
from:@username June 2026            # recent activity
```

### 2. Source Verification — The Critical Step

**Mark every claim with its provenance level:**

| Marker | Meaning | Example |
|--------|---------|---------|
| ✅ | Directly from a public source (tweet, doc, interview) | "Uses Cursor" ✅ from [tweet link] |
| ⚠️ | From session context (past conversation analysis) | "Runs Hermes in VS Code terminal via SSH" ⚠️ from session context |
| ❓ | Inference, not directly stated | "Probably evaluates Zed" ❓ inference from ecosystem trends |

**Rules:**
- If a claim cannot be linked to a public source, say so explicitly
- Never present session-context information as public fact
- When unsure, say "I can't source this" — honesty beats fabrication

### 3. Source Extraction Workflow

```python
# Step 1: Get the person's profile + latest posts
web_extract(urls=["https://x.com/username"])

# Step 2: Get individual post content for detailed claims
web_extract(urls=["https://x.com/username/status/12345"])

# Step 3: Check replies for additional context
# The same page often includes reply threads

# Step 4: Search for specific tool mentions
web_search(query="from:@username toolname")
```

### 4. Presentation Format

**Inline citation style:** Place the source link right next to the claim in the same sentence or bullet point, NOT in a generic footer block at the end.

✅ Good:
> Uses Cursor as primary IDE — [Sep 2025 tweet](https://x.com/...)

❌ Bad:
> Uses Cursor as primary IDE. *(Sources at bottom.)*

**Table format for multiple claims:**

| Claim | Source | Confidence |
|-------|--------|------------|
| Uses Cursor | [tweet link](...) | ✅ Direct |
| Runs Hermes via VS Code terminal | Previous session analysis | ⚠️ Context |
| Evaluating Zed ACP | From ecosystem docs, not personal statement | ❓ Inference |

### 5. Temporal Accuracy

- **Date every source** — a claim from Sep 2025 may be stale by Jun 2026
- When sources contradict (old tweet vs recent tweet), note the evolution
- Label pre-vs-post major releases (e.g. "before Desktop app existed" vs "after Desktop launch")

## Pitfalls

- **Don't present session-only context as public fact.** If you learned something in a past conversation with the user, say "from session context" — not as if it's a known public detail.
- **Don't fabricate tweet links.** If you can't find a tweet, say so. Never make up a URL.
- **Don't hide low-confidence claims in a generic footer.** Transparent provenance markers (✅/⚠️/❓) are better than pretending everything is equally certain.
- **Don't conflate "ships a feature" with "uses it themselves."** Someone building a tool may not be its primary user.
- **Old tweets can mislead.** A preference from Sep 2025 may have completely changed by Jun 2026. Use recency as a confidence signal.

## Related Skills

- `blogwatcher` — RSS monitoring for ongoing research
- `dogfood` — QA/evaluation of web apps (complementary investigation style)
