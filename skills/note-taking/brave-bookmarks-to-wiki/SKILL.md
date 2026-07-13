---
name: brave-bookmarks-to-wiki
description: "Parse Brave bookmarks (HTML export or native JSON) into wiki pages — phased approach: catalog first, selectively deep-process high-value folders."
version: 2.2.0
author: Hermes Agent
metadata:
  hermes:
    tags: [bookmarks, brave, parsing, catalog, wiki-ingest]
    category: note-taking
    related_skills: [wiki-operations, wiki-planning, knowledge-base-organization]
---

# Brave Bookmarks → Wiki

Parse Brave bookmarks (either the HTML export `Bookmarks.html` or the native JSON `Bookmarks` file) and integrate into the wiki at `$HOME/Vault/wiki`.

This skill aligns with the **two-layer ingest pipeline** (see `wiki-operations` skill):
- Layer 1 (Feed Watcher): handles RSS/Atom feeds automatically
- Layer 2 (On-Demand): bookmarks processing is a Layer 2 activity — deliberate, quality-focused, one at a time
- Bookmark-extracted content lands in `raw/bookmarks/<slug>.md` (same pattern as `raw/articles/`)

## When This Skill Activates

Use this skill when the user:
- Has a Brave bookmarks file they want processed into wiki pages
- Wants to catalog, organize, or wiki-ify their browser bookmarks
- Has a large number of bookmarks (thousands) and needs a phased approach

## Input Sources

### Source A: HTML Export (`Bookmarks.html`)

Exported from Brave via `brave://bookmarks` → ⋮ → Export bookmarks. Standard Netscape bookmark format:

```html
<DT><H3>Folder Name</H3>
<DL><p>
  <DT><A HREF="https://..." ADD_DATE="1234567890">Bookmark Title</A>
  <DT><H3>Subfolder</H3>
  <DL><p>
    <DT><A HREF="https://...">Nested Bookmark</A>
  </DL><p>
</DL><p>
```

### Source B: Native JSON (`Bookmarks`)

Brave also stores bookmarks in a JSON file at:
```
%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Bookmarks
```
(On Windows, resolves to `~/AppData/Local/hermes\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Bookmarks`)

The JSON structure has `roots.bookmark_bar.children` and `roots.other.children` arrays. Each node has `type: "url"` or `type: "folder"`, with nested `children` arrays for folders.

The JSON file includes richer metadata: `date_added` (chrome-epoch microseconds), `date_last_used`, `guid`, and `id`. Use the JSON format when you want speeds (no parsing needed — just `json.loads`) or need the extra metadata.

## Architecture: Three Phase Approach

### Phase 1 — Parse & Catalog

Parse into a structured markdown catalog organized by folder hierarchy. No web visits — just data extraction.

**Python parsing (HTML format — use execute_code):**

```python
import re
from datetime import datetime

def parse_brave_html(html):
    """Parse Brave bookmarks HTML into structured list."""
    bookmarks = []
    folder_stack = [{"name": "Root", "path": ""}]
    folder_start = re.compile(r'<DT><H3[^>]*>(.*?)</H3>')
    bookmark = re.compile(r'<DT><A HREF="([^"]*)" ADD_DATE="([^"]*)"[^>]*>(.*?)</A>')

    for line in html.split('\n'):
        line = line.strip()
        if not line:
            continue
        fm = folder_start.search(line)
        if fm:
            name = fm.group(1).strip()
            parent_path = folder_stack[-1]["path"]
            folder_stack.append({"name": name, "path": f"{parent_path}/{name}" if parent_path else name})
            continue
        bm = bookmark.search(line)
        if bm:
            url = bm.group(1)
            add_date = bm.group(2)
            title = bm.group(3).strip()
            bookmarks.append({
                "title": title, "url": url,
                "folder": folder_stack[-1]["path"],
                "added": datetime.fromtimestamp(int(add_date)).strftime("%Y-%m-%d") if add_date.isdigit() else ""
            })
        if '</DL>' in line and len(folder_stack) > 1:
            folder_stack.pop()
    return bookmarks
```

**Python parsing (JSON format — simpler):**

```python
import json
from datetime import datetime, timezone

def parse_brave_json(data):
    """Parse native Brave Bookmarks JSON into structured list."""
    bookmarks = []

    def walk_node(node, folder_path=""):
        if node.get("type") == "url":
            url = node.get("url", "")
            # Chrome epoch: microseconds since 1601-01-01
            date_added = int(node.get("date_added", "0"))
            dt = datetime(1601, 1, 1, tzinfo=timezone.utc) + timedelta(microseconds=date_added) if date_added else ""
            bookmarks.append({
                "title": node.get("name", ""),
                "url": url,
                "folder": folder_path,
                "added": dt.strftime("%Y-%m-%d") if dt else ""
            })
        elif node.get("type") == "folder":
            name = node.get("name", "Unnamed")
            new_path = f"{folder_path}/{name}" if folder_path else name
            for child in node.get("children", []):
                walk_node(child, new_path)

    for root_key in ["bookmark_bar", "other", "synced"]:
        root = data.get("roots", {}).get(root_key)
        if root:
            walk_node(root)
    return bookmarks
```

**Pre-classification (no web visits):**

```python
def classify_bookmark(url, title, folder):
    url_lower = url.lower()
    dead_link_patterns = ['http://localhost', 'http://127.0.0.1', 'chrome://', 'about:']
    login_patterns = ['login', 'signin', 'auth', 'sso.', 'oauth']
    video_patterns = ['youtube.com', 'youtu.be', 'vimeo.com', 'twitch.tv']
    doc_patterns = ['docs.google.com', 'drive.google.com', 'notion.so']
    social_patterns = ['twitter.com', 'x.com', 'reddit.com', 'linkedin.com', 'github.com/']

    for p in dead_link_patterns:
        if p in url_lower: return "dead-link"
    for p in login_patterns:
        if p in url_lower: return "login-dashboard"
    for p in video_patterns:
        if p in url_lower: return "video"
    for p in doc_patterns:
        if p in url_lower: return "document"
    for p in social_patterns:
        if p in url_lower: return "social-profile"
    return "website"
```

### Output path

The structured catalog goes to `<WIKI_ROOT>/raw/bookmarks/bookmark-catalog.md` — following the same `raw/` convention as `raw/articles/` from the feed watcher.

```markdown
# Brave Bookmarks Catalog

> Generated from Bookmarks.html on YYYY-MM-DD
> Total: N bookmarks across M folders

## /Folder/Path

### [Bookmark Title](https://...)
- **Added:** 2024-03-15
- **Type:** website | video | document | login-dashboard | dead-link | social-profile
```

### Phase 2 — Select Deep Processing

After the catalog is built, identify high-value folders to wiki-ify:

1. **GitHub repos** → highest ROI — README extracts cleanly via `web_extract`, produces structured content perfect for entity pages. Create one entity page per repo with frontmatter, summary, and `relates_to: [hermes-agent]` links.
2. **Reference / Guides** → most likely reusable content → concept pages
3. **Tools / Software** → comparison pages or entity pages
4. **Reading / Blog / Articles** → summaries into `raw/articles/`

**Processing flow for each high-value bookmark:**

1. `web_extract(url)` to get page content
2. Write to `raw/bookmarks/<slug>.md` with proper frontmatter:
   ```yaml
   ---
   title: "Page Title"
   type: concept
   tags: [bookmarks, dev-tools]
   sources: [raw/bookmarks/<slug>.md]
   relates_to:
     - rel: similar
       page: some-other-page
   ---
   ```
3. Optionally synthesize into a wiki page via `mcp_wiki_synthesize_answer` then `mcp_wiki_file_synthesis` → `pending/`
4. Update `index.md` and `log.md`

**GitHub repo deep-processing (highest ROI):**

For batch processing GitHub repos into entity pages, use this pattern:
1. Check for existing file in `entities/<repo-slug>.md` — skip if it exists (slug collision)
2. `web_extract(url)` to get README content
3. Create entity page at `entities/<repo-slug>.md` with:
   - Frontmatter: `title`, `created`, `type: concept`, `tags: [bookmarks, hermes-ecosystem, imported]`, `source URL`
   - One-line description from the repo
   - Short summary paragraph from README
   - `relates_to` links to related wiki pages (e.g., `hermes-agent` with `rel: extension_of`)
4. After batch, create `raw/bookmarks/community-ecosystem-index.md` listing all processed repos with descriptions and wikilinks

**Slug collision handling:** Before creating any entity page, `read_file` the target path. If it exists, skip it (note the collision in the index) — the existing page may be more authoritative.

Skip types automatically: dead-link, login-dashboard, video (unless article notes), document.

### Phase 3 — Classify & Triage by Subject

After the catalog exists (Phase 1) and the initial gems are extracted (Phase 2), the next step is to **classify bookmarks by wiki subject area** before deciding what to wiki-ify. This is the triage layer between "we know what we have" and "what should we build."

**Why subject-index before wiki-ifying:**
- Not all bookmarks are equal — some are dead links, search pages, or low-value
- Grouping by subject reveals gaps in wiki content and duplication
- The subject-index becomes the roadmap for Phase 4 wiki promotion
- Without it, you risk processing low-value bookmarks or missing high-value ones buried in large folders

**Classification technique (from Brave JSON source):**

```python
import json, re
from collections import defaultdict

# Read native Brave JSON
with open(r'~/AppData/Local/hermes\AppData\Local\BraveSoftware\Brave-Browser\User Data\Default\Bookmarks', encoding='utf-8') as f:
    data = json.load(f)

# Extract all bookmarks with folder paths
def get_bookmarks(node, path=''):
    results = []
    name = node.get('name', '')
    current_path = f'{path}/{name}' if path else name
    children = node.get('children', [])
    url = node.get('url', '')
    if children:
        for child in children:
            results.extend(get_bookmarks(child, current_path))
        if url:
            results.append((current_path, url, name))
        return results
    elif url:
        return [(current_path, url, name)]
    return []

# Classify by domain pattern into wiki subject areas
def classify_to_subject(url, title):
    combined = (url + ' ' + (title or '')).lower()
    
    subjects = {
        '🤖 LLMs & Models': ['huggingface', 'civitai', 'gguf', 'llama', 'gemma', 'qwen', 'gpt-', 'claude-', 'nous', 'deepseek', 'model'],
        '🤖 AI Agents & Frameworks': ['hermes agent', 'crewai', 'langchain', 'openai agents', 'autogen', 'mcp', 'aicp', 'goose', 'browser use', 'computer use', 'claude code', 'opencode', 'fusion agent'],
        '💻 Dev Tools & IDEs': ['cursor', 'windsurf', 'antigravity', 'vscode', 'neovim', 'nvim', 'zed', 'ghostty', 'terminal'],
        '📝 Knowledge & Wiki': ['obsidian', 'logseq', 'notion', 'wiki', 'knowledge', 'second brain'],
        '🔧 Infrastructure & DevOps': ['docker', 'kubernetes', 'k8s', 'tailscale', 'proxmox', 'linux', 'nginx', 'postgres', 'sqlite'],
        '🎨 Design & Creative': ['comfyui', 'stable diffusion', 'figma', 'excalidraw', 'design system'],
    }
    
    for subject, keywords in subjects:
        for kw in keywords:
            if kw in combined:
                return subject
    return '🌐 Uncategorized / Other'

# Classify all bookmarks in a root (e.g., bookmark_bar)
bookmarks = get_bookmarks(data['roots']['bookmark_bar'])
by_subject = defaultdict(list)
for path, url, title in bookmarks:
    if url and url != 'data,':
        by_subject[classify_to_subject(url, title)].append((url, title, path))
```

**Creating the subject-index page:**

The output goes to `raw/bookmarks/subject-index.md` — a structured reference page that:

1. **Summarizes classification** — table of subject areas with item counts and wiki destinations
2. **Breaks down each subject** — sub-topics, counts, example bookmarks, notable finds
3. **Flags top gems** — items ready for immediate wiki promotion (15-20 max)
4. **Links to the dashboard** for progress tracking

```markdown
# 📑 Bookmarks Subject Index

> **858 Bookmarks Bar items** classified into **6 wiki subject areas**

| Subject | Items | Wiki Destination | Priority |
|---------|-------|------------------|----------|
| 🤖 LLMs & Models | 140 | entities/ (tools), concepts/ (models) | 🔥 High |
| 🤖 AI Agents & Frameworks | 98 | concepts/ (agents), entities/ (tools) | 🔥 High |
| 💻 Dev Tools & IDEs | 61 | entities/ (tools), comparisons/ | 🟢 Medium |
| ...
```

**Gem-flagging heuristic:**

After classification, scan each subject area for items with high wiki value:
- **GitHub repos** in the bookmark's ecosystem context (Hermes, AI agents, MCP tools)
- **Research papers / arxiv** relevant to core wiki concepts
- **Tutorials / masterclasses** about tools already in the wiki
- **Awards / foundation announcements** (e.g., Agentic AI Foundation)
- **Comparison articles** between tools the wiki tracks

Filter out: search engine result pages, dead links (localhost/127.0.0.1/chrome://), personal documents, shopping pages, domain-root-only bookmarks (bare URLs like `github.com`).

**Mobile Bookmarks triage:** The `synced` root (Mobile Bookmarks) has a different signal-to-noise ratio — bulk phone dumps mixed with tech content. Classify separately and triage only the explicitly tech-named folders (AI, Claude, code, founder mode, riverbirds, desk, design). Skip phone-dump folders unless they're small enough to scan manually.

**Progress tracking:** After classification, update the project dashboard:
- Mark Phase 3 as `in_progress`
- Add classification stats (items classified, gems flagged)
- Update remaining work checklist
- Update the phase-3 task entity `next_action`

### Phase 3A — Ingestion Progress Dashboard

After Phase 1 (catalog created), Phase 2 (gems), and Phase 3 (classification), a persistent dashboard in `dashboards/` tracks what's been processed and what remains.

**Canonical location:** `dashboards/bookmarks.md` (not `tracking/entities/`). See the `project-dashboard-buildout` skill for full dashboard creation pattern.

**Progress view** — phase-level status table in the dashboard body:

```markdown
## Progress Summary

| Phase | Status | What | Items |
|-------|--------|------|-------|
| **1. Parse** | ✅ Done | Native Brave JSON → catalog | 5,701 |
| **2. Ecosystem gems** | ✅ Done | Top community tools → entity pages | 9 |
| **3. Classify & triage** | 🏗️ In progress | Subject-index created, gems flagged | ~858 classified |
| **4. Wiki-ify priority content** | ⏳ Pending | Promote gems to wiki pages | TBD |
| **5. Long-tail archive** | ⏳ Pending | Remaining bulk → archive index | ~4,892 |
```

**Update workflow:**
1. After each session, patch the dashboard in `dashboards/bookmarks.md` and any related task entities
2. Add folder row with status and wikilinks to created pages
3. Update phase task entity `task_status` and `next_action`
4. Reindex wiki after every update
5. Commit to git

**Shopping list parallel:** Same pattern applies at `dashboards/shopping.md` — category-level progress, purchase status, priority flags. See the `project-dashboard-buildout` skill for the full shopping dashbaord pattern.

### Phase 4 — Batch Processing Over Time

For large sets:

**Option A: Delegate parallel workers** — batch N bookmarks via `delegate_task`, each worker processes 5-10.

   Recommended prompt template for the delegate:
   ```
   For each GitHub repo URL below, use web_extract to get the README, then create a wiki page at
   `<WIKI_ROOT>/entities/<repo-slug>.md` with:
   - Frontmatter: title, created: YYYY-MM-DD, type: concept, tags: [bookmarks, hermes-ecosystem, imported], source URL
   - One-line description from the repo
   - A short summary paragraph
   - relates_to links to related pages where applicable

   Only create pages for repos that extract successfully. If a page already exists in
   <WIKI_ROOT>/entities/, skip it (read_file to check first). Use write_file for each page.

   Also create an index page at <WIKI_ROOT>/raw/bookmarks/community-ecosystem-index.md
   listing all processed repos with brief descriptions and links to their entity pages.
   ```

   Key parameters: set `toolsets=["file", "web", "terminal"]` — the delegate needs web_extract for READMEs, write_file for pages, and terminal for checking existing files.

**Option B: Cron job** — schedule every few days to process next batch:
```bash
hermes cron create --schedule "every 2d" --prompt "Process next 10 'website' bookmarks from raw/bookmarks/bookmark-catalog.md"
```

**Option C: Manual per-session** — pick a folder, process that batch.

## Volume Guidelines

| # Bookmarks | Phase 1 | Phase 2 | Best Approach |
|:-----------:|:-------:|:-------:|:-------------:|
| < 20 | ✅ Instant | ✅ Full | Single session |
| 20-100 | ✅ 1-2 turns | ⚠️ Partial | Pick 2-3 folders |
| 100-500 | ✅ Manageable | Selective | Batch delegate_task |
| 500-5000 | ✅ Needs code | ⚠️ Minimal | Catalog + cron |
| 5000+ | ✅ Scripted | ❌ Impractical | Catalog only |

## Alignment With Two-Layer Pipeline

Brave bookmarks processing fits the **Layer 2 (On-Demand)** pattern — you're deliberately choosing what to process, one at a time:

1. Bookmarks land in `raw/bookmarks/` (parallel to `raw/articles/`)
2. When ready, use `synthesize_answer` to check against existing wiki content
3. Tier-filter: novel → `file_synthesis` → `pending/`; extends → update existing page; trivial/duplicate → skip
4. Promote from `pending/` to `entities/` or `concepts/` after review
5. Update `log.md`, `index.md`, reindex, lint, commit

The `wiki-operations` skill has the full Layer 2 processing workflow details.

## Pitfalls

- **Dead links are common** — pre-classify URLs before visiting to save tokens. Many bookmarks are years old.
- **Login walls** — SaaS tools, dashboards, internal tools won't extract via `web_extract`. Skip these.
- **YouTube links** — skip automated extraction; use `youtube-content` skill if needed.
- **Google Docs / Drive** — don't extract via `web_extract`. Note as external references in catalog.
- **Token cost for bulk web extraction** — `web_extract` calls consume API credits. Batch wisely.
- **Don't create wiki pages for low-value items** — a bookmark to "npm-docs" doesn't need a full concept page.
- **Folder hierarchy preservation** — tag wiki pages with categories from folder structure.
- **Phase 1 is parse-only** — no web visits, no API calls. Pure Python.
- **Memory limits** — 5K-bookmark HTML file could be 2-5MB. Read in chunks or parse via execute_code.
- **Session continuity** — for multi-phase work, save progress in the catalog file and use `log.md` entries.
- **JSON vs HTML** — the JSON file at `%LOCALAPPDATA%` has the most up-to-date data. The HTML export may be stale if not freshly exported. Prefer the JSON source when the user hasn't explicitly exported.
- **Do NOT process `bookmark_bar.other` — it's the "Other bookmarks" folder** — usually lower value. Scan the bookmark_bar (bookmarks bar) first.
