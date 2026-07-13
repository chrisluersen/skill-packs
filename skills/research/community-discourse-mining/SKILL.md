---
name: community-discourse-mining
title: Community Discourse Mining
description: Systematically extract, filter, and integrate valuable insights from community discussions on reference documents — gist comments, GitHub issues, forum threads, blog discussions.
---

# Community Discourse Mining

Mine signal from noise in community discussions and integrate findings into maintained documents (schemas, wikis, specs).

## When to Use

- A reference doc (gist, RFC, blog post, paper) has a long comment thread
- You need to find actionable improvements from community feedback
- Multiple semi-structured comments need evaluation against an existing doc
- User asks "any other comments worth considering?" on a gist/blog/thread

## Workflow

### 1. Extract All Comments

`web_extract` returns page content as one large JSON-escaped string. Parse it programmatically:

```python
from hermes_tools import web_extract
import re

result = web_extract(urls=["https://gist.github.com/..."])
content = result["results"][0]["content"]

# Extract comment blocks: author, date, body
pattern = r'\*\*\[?([^\]]*)\]?\*\*\s+commented\s+\[([^\]]*)\]([^#]*?)(?=\*\*\[?[^\]]*\]?\*\*\s+commented|\Z)'
for m in re.finditer(pattern, content, re.DOTALL):
    author = m.group(1).strip()
    date_str = m.group(2).strip()
    body = m.group(3).strip()
```

If browser tools are available and web_extract truncates, fall back to `browser_navigate` + `browser_console` with JS to extract comments.

### 2. Filter by Substance

**Discard:**
- Pure product announcements ("I built X") with no transferable insight
- Code dumps without explanation
- Complaints with no actionable content
- Reposts of other people's comments

**Keep — these are your signal categories:**

| Signal | Looks like | Use it for |
|--------|-----------|------------|
| **Policy insight** | "The default treats X as Y, but in Z domains X is actually W" | New schema rule / domain distinction |
| **Implementation pattern** | "The right way: grep for citation before writing" | Workflow step addition |
| **Risk/guardrail** | "One concern: hallucination probability compounds" | Lint item / quality guardrail |
| **Architectural principle** | "Markdown + Git is the only source of truth; all else is derived" | Design principle section |
| **Concrete workaround** | "Partition writers by file + append-only → no locks needed" | Multi-agent procedure |

### 3. Evaluate Against Current Docs

For each substantive comment, map it:

- **Gap** → current doc doesn't address this → new section/page
- **Better approach** → existing section could be improved → patch
- **Missing guardrail** → risk not covered → add lint item or policy rule
- **Detail-dense** → better as a reference file under the relevant skill than inline in a schema doc

### 4. Present Cluster & Options

Group related comments. Offer clear choices:
- A) Integrate all N signals
- B) Top N only
- C) A specific selection

Avoid listing every comment individually — cluster by theme.

### 5. Apply Changes

- Use targeted `patch()` calls for inline doc changes
- Create `references/<topic>.md` under the relevant skill for session-specific detail
- Update the changelog with source attribution (comment author, date)
- Commit with a descriptive message crediting original commenters by handle

## Pitfalls

- **Over-integration:** Not every comment is schema-worthy. If it's already covered or too niche, skip it.
- **Vanity metrics:** Don't count total comments — count substantive signal. 30 comments may yield 2–5 actionable items.
- **Lost attribution:** Always credit the comment author in commit messages. The changelog is where future agents trace provenance.
- **Escaped JSON blindness:** web_extract output for large pages is JSON-escaped. Always parse in Python — don't try reading the raw escaped string.
- **Comment decay:** Some comments fail to load (shows "There was an error while loading") — skip those, they're not recoverable.
- **Browser timeout:** Large gist pages may trigger browser_navigate timeouts. Prefer web_extract + Python parsing.

## Reference Files

- `references/karpathy-gist-integration.md` — Concrete worked example: 30 comments on Karpathy's LLM Wiki gist filtered to 5 signals, each mapped to a specific schema addition. Use this as a template for your own extraction + evaluation pass.

## Related Skills

- `document-verification-update` — closely related; this skill feeds its output
- `knowledge-consolidation` — when the insights need merging across fragmented sources
