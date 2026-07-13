# Content Accuracy Audit — Reusable Reference

This reference captures the full content accuracy verification workflow from a real wiki
refactor session (2026-06-16). Use after any structural refactor to catch factual errors
before the user does.

## Full Audit Script (Python)

```python
import os, re, subprocess
from collections import defaultdict

WIKI = "~/AppData/Local/hermes/wiki"  # adjust
RAW_SOURCE = f"{WIKI}/raw/Hermes Agent — Full Documentation.md"

# ─── 1. Structure Check ───
required_dirs = ["entities", "concepts", "comparisons", "queries", "raw", "_archive"]
for d in required_dirs:
    path = f"{WIKI}/{d}"
    print(f"{'✅' if os.path.isdir(path) else '❌'} {d}/")

# ─── 2. File Inventory ───
all_md = []
for root, dirs, files in os.walk(WIKI):
    dirs[:] = [d for d in dirs if d != ".git"]
    for f in files:
        if f.endswith(".md"):
            rel = os.path.relpath(os.path.join(root, f), WIKI)
            all_md.append(rel)

wiki_pages = [f for f in all_md if not f.startswith("raw/")]
raw_pages = [f for f in all_md if f.startswith("raw/")]
print(f"\nTotal .md files: {len(all_md)}")
print(f"Wiki pages: {len(wiki_pages)}")
print(f"Raw files: {len(raw_pages)}")

# ─── 3. Frontmatter Audit ───
required_fields = {"title", "created", "updated", "id", "type", "tags", "sources"}
issues = 0
for page in wiki_pages:
    path = f"{WIKI}/{page}"
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    if not lines or lines[0].strip() != "---":
        print(f"  ❌ No frontmatter: {page}")
        issues += 1
        continue
    # Find frontmatter end
    end = None
    for i, line in enumerate(lines[1:], 1):
        if line.strip() == "---":
            end = i
            break
    if end is None:
        print(f"  ❌ Unclosed frontmatter: {page}")
        issues += 1
        continue
    fm_text = "".join(lines[1:end])
    for field in required_fields:
        if f"{field}:" not in fm_text:
            print(f"  ❌ Missing '{field}' in {page}")
            issues += 1

if issues == 0:
    print("✅ ALL FRONTMATTER PASSED")

# ─── 4. Wikilink Audit ───
wikilink_re = re.compile(r"\[\[([^\]|]+)")
inbound = defaultdict(int)
outbound = {}
broken = []
for page in wiki_pages:
    path = f"{WIKI}/{page}"
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    links = set()
    for m in wikilink_re.finditer(content):
        target = m.group(1).strip().lower().replace(" ", "-").replace("_", "-")
        links.add(target)
    outbound[page] = links
    for link in links:
        inbound[link] += 1

# Check all wikilinks resolve to actual pages
page_slugs = set(os.path.splitext(f)[0].lower().replace(" ", "-") for f in all_md)
for page, links in outbound.items():
    for link in links:
        if link not in page_slugs:
            broken.append((page, link))

print(f"\n=== BROKEN WIKILINKS ===")
for page, link in broken[:10]:
    print(f"  {page} -> ['{link}']")
if not broken:
    print("  ✅ 0 broken links")

# ─── 5. Orphans ───
lower_page_slugs = {os.path.splitext(f)[0].lower(): f for f in wiki_pages}
orphans = []
for page in wiki_pages:
    slug = os.path.splitext(page)[0].lower()
    if slug in ["readme", "index", "log", "schema", "nav"]:
        continue
    if inbound[slug] == 0:
        orphans.append(page)

print(f"\n=== ORPHANS (0 inbound) ===")
if orphans:
    for p in orphans:
        print(f"  ⚠️  {p}")
else:
    print("  ✅ 0 orphans")

# ─── 6. Content Accuracy Spot-Check ───
# Verify high-impact claims against the raw source
claims_to_verify = {
    "license": ["Apache", "MIT", "GPL"],
    "version": ["v[0-9]", "version"],
    "model": ["[0-9]+K", "[0-9]B", "parameter"],
}

print(f"\n=== SPOT CHECK: Verifying claims against source ===")
for claim_type, patterns in claims_to_verify.items():
    for page in wiki_pages[:5]:  # spot-check first 5 pages
        path = f"{WIKI}/{page}"
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        for pattern in patterns:
            if re.search(pattern, content, re.IGNORECASE):
                # Search source for the claim
                try:
                    result = subprocess.run(
                        ["grep", "-i", pattern, RAW_SOURCE],
                        capture_output=True, text=True, timeout=5
                    )
                    if not result.stdout.strip():
                        print(f"  ⚠️  '{pattern}' on {page} — NOT FOUND in source")
                except:
                    pass

print("\n=== AUDIT COMPLETE ===")
```

## Error Verification: License Check

The most common high-impact error. Always verify from the actual project repo:

```python
import requests

repos = {
    "hermes-agent": "NousResearch/hermes-agent",
    # add more as needed
}

for name, repo in repos.items():
    url = f"https://raw.githubusercontent.com/{repo}/main/LICENSE"
    resp = requests.get(url)
    if resp.status_code == 200:
        # First line usually has the license name
        first_line = resp.text.split("\n")[0]
        print(f"{name}: {first_line}")
    else:
        print(f"{name}: Could not fetch LICENSE (HTTP {resp.status_code})")
```

## Known High-Error Claim Patterns

| Pattern | Why it's wrong | How to fix |
|---------|---------------|------------|
| "MIT licensed" for any Nous Research project | Hermes Agent is Apache 2.0 | Check LICENSE file, patch all pages |
| "~2s startup" for CLI vs TUI comparison | TUI starts instantly; the "~2s" was made up | Remove quantification, use source wording |
| "Hermes CLI" as product name | Official name is "Hermes Agent" | Patch every occurrence |
| "300+ features" or "15+ tools" | Inflated from source prose like "many features" | Match source wording exactly |
| Company name typos | "Anthrophic", "Open AI", "Anthropic AI" | Check official website/README for exact name |
| Model hallucinated params | "7B parameters" for a 8B model | Check original model card on HuggingFace |
| Wrong version numbers | "v1.7.0" when latest is v1.8.0 | Check `hermes --version` or GitHub releases |
| "Built with Textual" | Hermes TUI is built with Rich/Textual? Check pyproject.toml | Cross-reference project dependencies |

## Verification Checklist

Before declaring a wiki refactor complete:

- [ ] Structure: all 6 required dirs exist (entities, concepts, comparisons, queries, raw, _archive)
- [ ] File count: .md files on disk ≈ index claim (± 1 for meta pages)
- [ ] Frontmatter: every page has title, created, updated, type, tags, sources, confidence
- [ ] Wikilinks: 0 broken links; every page has 2+ outbound links
- [ ] Orphans: 0 pages with zero inbound links
- [ ] Content accuracy: at least spot-checked high-impact claims (license, version, quantified claims)
- [ ] Project sources verified: license from actual GitHub repo, not assumed
- [ ] Git: initialized if not already, clean working tree
- [ ] Log updated: refactor action recorded with page counts
