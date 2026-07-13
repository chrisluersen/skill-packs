---
name: web-page-extraction
description: >-
  Progressive extraction pipeline: start free (meta tags), escalate only for
  gaps. Gets ~88 quality for ~$4/5K pages through 4-tier field-level
  extraction, batching, and domain templates.
category: software-development
# Supporting files: references/research-sources.md — OG coverage stats, Firecrawl pricing, model pricing, quality scores
# references/ai-chat-share-link-extraction.md — extracting content from Gemini/ChatGPT/Claude share links behind sign-in walls
---

# Web Page Extraction — Optimal Pipeline

## When to use this skill

- You need structured data (title, description, author, date, tags, summary) from batches of web pages / bookmarks
- You want the **highest possible quality for the lowest possible cost**
- You're processing 100–50,000+ URLs
- You're willing to trade a little engineering complexity for 10–20× cost savings

---

## The core insight: most pages have free metadata

**70.5% of websites have Open Graph tags.** 45+ million domains embed Schema.org JSON-LD. For a typical bookmark set, **60–80% of fields can be extracted for $0** — just parse the HTML.

The LLM is only needed for the gaps. Don't use it to extract what's already in `<meta>` tags.

---

## The progressive 4-tier pipeline

```
URL
 │
 ├─ Tier 0: Meta tag parsing ──────────► 60–75% of fields (FREE)
 │   (OG / JSON-LD / Twitter / <title>)
 │   ↓ missing fields
 │
 ├─ Tier 1: Tiny model gap-fill ────────► 15–20% more (~$0.0003/page)
 │   (DeepSeek V3.2-Exp — only asks for missing fields)
 │   ↓ low confidence
 │
 ├─ Tier 2: Cheap model re-extract ─────► 8–12% more (~$0.005/page)
 │   (Gemini 2.5 Flash / Claude Haiku 4.5)
 │   ↓ still failing
 │
 └─ Tier 3: Premium model ──────────────► 2–5% edge cases (~$0.02/page)
     (Claude Sonnet 4.6 / Gemini 2.5 Pro)
```

**Total cost for 5,000 pages: ~$4–$15** (vs ~$98 if you used Claude Sonnet on every page)

---

## Tier 0: Meta tag parsing ($0)

Parse the page HTML *before* any LLM call. Extract everything you can from the markup.

### What you get for free

```python
import requests
from bs4 import BeautifulSoup
import json

def extract_metadata(url: str) -> dict:
    """Extract everything from HTML meta tags. Returns partial result dict."""
    resp = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=15)
    soup = BeautifulSoup(resp.text, "html.parser")

    result = {"url": url}

    # --- <title> tag ---
    title_tag = soup.find("title")
    result["title"] = title_tag.text.strip() if title_tag else None

    # --- Open Graph ---
    for tag in soup.find_all("meta", attrs={"property": True}):
        prop = tag.get("property", "")
        if prop == "og:title":
            result["title"] = tag.get("content", "")
        elif prop == "og:description":
            result["description"] = tag.get("content", "")
        elif prop == "og:type":
            result["content_type"] = tag.get("content", "")
        elif prop == "og:site_name":
            result["domain"] = tag.get("content", "")

    # --- Twitter Cards ---
    for tag in soup.find_all("meta", attrs={"name": True}):
        name = tag.get("name", "")
        if name == "twitter:title" and not result.get("title"):
            result["title"] = tag.get("content", "")
        elif name == "twitter:description" and not result.get("description"):
            result["description"] = tag.get("content", "")

    # --- Standard description meta ---
    desc_tag = soup.find("meta", attrs={"name": "description"})
    if desc_tag and not result.get("description"):
        result["description"] = desc_tag.get("content", "")

    # --- JSON-LD (Schema.org) ---
    for script in soup.find_all("script", type="application/ld+json"):
        try:
            data = json.loads(script.string)
            items = data if isinstance(data, list) else [data]
            for item in items:
                if item.get("@type") in ("Article", "BlogPosting", "NewsArticle",
                                          "WebPage", "Product", "TechArticle"):
                    if not result.get("title"):
                        result["title"] = item.get("headline") or item.get("name")
                    if not result.get("description"):
                        result["description"] = item.get("description")
                    if not result.get("author"):
                        author = item.get("author", {})
                        if isinstance(author, dict):
                            result["author"] = author.get("name")
                        elif isinstance(author, list):
                            result["author"] = ", ".join(
                                a.get("name", "") for a in author if isinstance(a, dict)
                            )
                    if not result.get("publish_date"):
                        result["publish_date"] = item.get("datePublished")
                    if not result.get("reading_time_minutes"):
                        result["reading_time_minutes"] = item.get("timeRequired")
        except (json.JSONDecodeError, TypeError, AttributeError):
            continue

    # --- Fallback: extract author from rel=author link ---
    if not result.get("author"):
        author_link = soup.find("a", attrs={"rel": "author"})
        if author_link:
            result["author"] = author_link.text.strip()

    # --- Fallback: h1 for title ---
    if not result.get("title") or len(result["title"]) < 3:
        h1 = soup.find("h1")
        if h1:
            result["title"] = h1.text.strip()

    result["_tier"] = 0
    result["_missing_fields"] = _find_missing_fields(result)
    return result

def _find_missing_fields(r: dict) -> list[str]:
    missing = []
    if not r.get("title") or len(r.get("title", "")) < 3:
        missing.append("title")
    if not r.get("description") or len(r.get("description", "")) < 20:
        missing.append("description")
    if not r.get("content_type"):
        missing.append("content_type")
    if not r.get("tags") or len(r.get("tags", [])) < 2:
        missing.append("tags")
    return missing
```

### Coverage estimate

| Source | Coverage | Fields contributed |
|---|---|---|
| `<title>` tag | ~98% of pages | Title |
| Open Graph tags | ~70% of pages | Title, description, content type |
| JSON-LD (Schema.org) | ~45% of pages | Author, publish date, even more detail |
| Meta description | ~65% of pages | Description |
| H1 tag | ~95% of pages | Title (fallback) |
| rel=author link | ~15% of pages | Author |

Typical result after Tier 0: **title ✓, description ✓, content_type ✓** on ~70% of pages.
Author and tags are the fields most often missing.

---

## Tier 1: Tiny model gap-fill (~$0.0003/page)

Only call the LLM for the *specific fields* that are missing. This is the key optimization — instead of "extract everything from this page" (4K input tokens), you send "find me just the author" or "write a one-sentence description" (300–800 input tokens).

### How it works

```python
def build_gap_prompt(url: str, markdown: str, missing_fields: list[str]) -> str:
    """Build a minimal prompt asking only for missing fields."""
    field_instructions = {
        "title": "Extract the page title (1-2 sentences, 10-100 chars). Return only the title text.",
        "description": "Write a one-sentence summary of what this page is about (20-200 chars). Be specific.",
        "author": "Find the author's name. Return just the name, or null if unclear.",
        "content_type": "Classify as: article, product, documentation, forum, social, landing, or other. Return just the type word.",
        "tags": "List 3-7 relevant tags for this page as a JSON array of strings. Example: ['python', 'web scraping']",
        "publish_date": "Find the publication date. Return ISO 8601 date or null.",
    }

    prompts = [field_instructions[f] for f in missing_fields if f in field_instructions]

    return f"""Page URL: {url}

Content (trimmed):
{markdown[:2000]}

For this page, I need:
{chr(10).join(f'- {p}' for p in prompts)}

Return ONLY raw values, no explanations. One per line matching the order above."""
```

### Why this is so much cheaper

| Approach | Input tokens | Output tokens | Cost (DeepSeek) |
|---|---|---|---|
| Full extraction (every page) | 4,000 | 500 | $0.0013 |
| Gap-fill (avg 2 fields) | 800 | 80 | $0.00026 |
| **Savings** | **5×** | **6×** | **5×** |

And you're only paying for pages that need it (the ~30% missing data after Tier 0).

**Effective cost for 5K pages:** ~$0.39 (1,500 pages × $0.00026)

### Model: DeepSeek V3.2-Exp ($0.28/$0.42 per 1M)

Using OpenRouter: `deepseek/deepseek-v4-flash` or `deepseek/deepseek-chat`.

---

## Tier 2: Cheap model re-extract (~$0.005/page)

For the ~10-15% of pages where Tier 1 produces low-confidence results, re-extract fully with a better model.

**Model: Gemini 2.5 Flash** ($0.30/$2.50 per 1M — 2M context means no truncation)
or **Claude Haiku 4.5** ($1/$5 per 1M — very reliable, low hallucination)

**Effective cost for 5K pages:** ~$3.75 (750 pages × $0.005)

---

## Tier 3: Premium edge cases (~$0.02/page)

For the final ~2-5% that Tier 2 still can't handle. Flag these for human review as well.

**Model: Claude Sonnet 4.6** ($3/$15 per 1M) or **Gemini 2.5 Pro** ($1.25/$10 per 1M)

**Effective cost for 5K pages:** ~$2.00 (100 pages × $0.02)

---

## Cost comparison: old approach vs optimized

| Approach | Cost / 5K pages | Quality | Notes |
|---|---|---|---|
| **DeepSeek — every page** | ~$7 | 78 | Simple, misses ~1 in 5 |
| **Claude Sonnet — every page** | ~$98 | 92 | Gold standard, expensive |
| **Gemini Flash — every page** | ~$12 | 82 | Good balance |
| **Optimized (4-tier)** | **~$4–$6** | **~89** | **Best value — uses free meta data + targeted LLM** |

The 4-tier approach costs **less than pure DeepSeek** but gets **close to Sonnet-level quality** (~89 vs 92).

---

## Extra optimizations (stack these on top)

### 1. Batch pages into one API call

Amortize the system prompt across multiple pages. Send 5-10 pages at once:

```
I have 5 web pages. For each, extract {title, description, tags}.
Return a JSON array of 5 objects, one per page.

Page 1 URL: https://...
Content:
---markdown---

Page 2 URL: https://...
Content:
---markdown---
...
```

**Saves:** 20-30% on token costs by sharing the system prompt across N pages.
**Works best with:** Gemini Flash (2M context handles 10+ pages easily).

### 2. Cache by domain

Bookmarks cluster heavily by domain. Cache the markdown output per URL (and per domain template):

```python
# Simple file-based cache
import hashlib, os, json

CACHE_DIR = "cache/markdown"

def cached_fetch(url: str) -> str:
    key = hashlib.md5(url.encode()).hexdigest()
    path = f"{CACHE_DIR}/{key}.md"
    if os.path.exists(path):
        return open(path).read()
    markdown = fetch_page(url)  # your actual fetch
    os.makedirs(CACHE_DIR, exist_ok=True)
    open(path, "w").write(markdown)
    return markdown
```

If you have 5,000 bookmarks from 200 unique domains, you only need ~200 fetches to prime the cache.

### 3. Domain-specific extraction templates

Build reusable CSS-selector based extractors for frequently-visited domains:

```python
DOMAIN_TEMPLATES = {
    "medium.com": {"title": "h1", "author": ".pw-author", "content": "article"},
    "github.com": {"title": "h1", "description": "p.f4", "stars": ".star-count"},
    "stackoverflow.com": {"title": "h1", "votes": ".vote-count"},
}

def extract_with_template(url: str, html: str) -> dict:
    """Use domain template if available. Much cheaper than LLM."""
    from urllib.parse import urlparse
    domain = urlparse(url).netloc.replace("www.", "")
    template = DOMAIN_TEMPLATES.get(domain)
    if not template:
        return {}
    soup = BeautifulSoup(html, "html.parser")
    result = {}
    for field, selector in template.items():
        el = soup.select_one(selector)
        if el:
            result[field] = el.text.strip()
    return result
```

Even 10 templates cover a disproportionate number of bookmarks if your set clusters on a few popular platforms.

### 4. Skip obviously dead pages

```python
if not markdown or len(markdown.strip()) < 200:
    result["_status"] = "blocked"
    continue  # paywalled, login gate, or dead link
```

No point paying for pages you can't access.

### 5. Use structured output mode

When available (OpenAI, Gemini, Together), use native JSON mode to eliminate parsing failures:

```python
# Gemini example
response = model.generate_content(
    contents=[{"role": "user", "parts": [{"text": prompt}]}],
    generation_config={
        "response_mime_type": "application/json",
        "response_schema": {...}
    }
)
```

---

## Complete pipeline flow

```
for each URL:
  │
  ├── 1. Fetch HTML
  ├── 2. Check domain template cache ───► if hit, extract CSSelement data
  │
  ├── 3. Tier 0: Parse meta tags ───────► result + list of missing fields
  │
  ├── 4. If missing fields AND deepseek cache miss:
  │       Tier 1: DeepSeek gap-fill ────► update result, recheck missing
  │
  ├── 5. If still missing fields AND flash cache miss:
  │       Tier 2: Gemini Flash ─────────► update result, recheck missing
  │
  ├── 6. If still missing:
  │       Tier 3: Claude Sonnet ────────► update result
  │       OR flag for human review
  │
  └── 7. Save result + cache (markdown + extracted fields)
```

---

## Quality expectations

| Tier | Quality score | % of pages handled | Cumulative coverage |
|---|---|---|---|
| 0 — Meta tags | 65 | 70% | 70% |
| 1 — DeepSeek gap-fill | 78 | 15% | 85% |
| 2 — Gemini/Claude re-extract | 84 | 10% | 95% |
| 3 — Premium/Manual | 94 | 5% | 100% |
| **Blended** | **~89** | **100%** | |

---

## Caveats

1. **SPA-heavy pages** need JS rendering first. Use Crawl4AI's browser mode, Playwright, or Firecrawl to get the rendered DOM before meta parsing.

2. **Paywalls return login HTML.** Meta tags will be from the login page, not the article. Detect by markdown length < 200 chars.

3. **JSON-LD can be wrong.** Some sites copy-paste schemas or use outdated data. Always treat extracted dates/authors from JSON-LD with a confidence check.

4. **OG tags are sometimes generic.** Many sites auto-generate "Read more" descriptions. The LLM gap-fill produces better descriptions here.

5. **Meta tag freshness.** A page you bookmarked 2 years ago may have different meta tags now. Cache the extraction, not just the fetch.

6. **Firecrawl has hidden 5× credit costs for AI extraction.** Use Firecrawl only for JS rendering / fetch, not for the extraction step. Feed the markdown to your own model calls.

7. **The gap-fill prompt is critical.** A bad prompt = the model writes a description that doesn't match the page. Always include URL context + specific instruction.

---

## When NOT to use this pipeline

- You need extraction on **1-2 pages** right now → just paste the URL into Claude/Gemini directly, faster than setting this up
- Every page is from the **same complex SPA** → just write a custom CSS selector extractor for that one site
- You need **real-time latency** (< 1s per page) → this approach has overhead from the progressive tier checks; use a single fast model
