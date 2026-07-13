---
name: git-history-rewrite
category: github
description: Rewrite git repository history using git-filter-repo — rename authors, scrub legacy references, rebrand projects, and force-push cleaned history. Covers inline callbacks, replace-message files, Windows pitfalls, and the complete scrub → verify → push workflow.
tags:
  - git
  - filter-repo
  - history
  - scrub
  - rename
  - rebrand
---

# Git History Rewrite

Rewrite git repository history to remove sensitive/legacy references, rename authors, or scrub stale branding. Uses `git-filter-repo` — safe, fast, and preserves merges.

**Never rebase or rewrite history on repos others depend on** without coordinating the force-push window. These steps destroy the old history.

## Prerequisites

```bash
pip install git-filter-repo
```

## Workflow

### 1. Clean the working tree first

Before rewriting history, fix all files in HEAD. Filter-repo operates on commits — if you clean files first, the new history starts fresh with no dirty tree.

```
# Fix ALL files in the current commit
# Every file-level change (rename, replace, delete)
git add -A
git commit -m "prep: clean tree before history rewrite"
```

### 2. Choose your filter approach

#### Option A — name/email/message callbacks (inline)

Rewrite author name, email, and commit messages in one pass:

```bash
cd <repo>
git filter-repo --force \
  --name-callback "return name.replace(b'OldName', b'NewName')" \
  --email-callback "return email.replace(b'old@email.com', b'new@email.com')" \
  --message-callback "return message.replace(b'old-term', b'new-term')"
```

**Callbacks MUST:**
- Start with `"return ..."` — the value is the string AFTER `return`
- Operate on bytes (`b'...'`), not strings
- Be self-contained (no imports from files)

#### Option B — replace-message (text file)

Use a replacements file for bulk message rewrites:

```bash
git filter-repo --force --replace-message replacements.txt
```

**File format** (one per line):

```
regex:\bhr\b==>cascade
hermes-router==>cascade
literal:exact text==>replacement
glob:*.md==>NEW.md
```

- **`regex:`** prefix for regex patterns (use `\b` for word boundaries)
- **`literal:`** prefix for exact text (also the default — prefix is optional)
- **`glob:`** prefix for glob patterns
- `==>` is the delimiter between pattern and replacement

#### Option C — squash all history to one commit

When you don't need the commit history at all — collapse everything into a single "Initial release" commit. No trace of old authors, messages, or filenames in the history.

```bash
cd <repo>

# Get the root commit hash
ROOT=$(git rev-list --max-parents=0 HEAD)

# Soft-reset to root — HEAD moves to root, all changes stay staged
git reset --soft $ROOT

# Amend the root commit with a clean message
git commit --amend -m "Initial release — project description"

# Remove filter-repo backup refs if any, expire reflog, prune
git update-ref -d refs/original/refs/heads/main 2>/dev/null
git reflog expire --expire=now --all
git gc --prune=now

# Re-add origin (filter-repo removes it; plain reset does not, but check)
git remote add origin https://github.com/<owner>/<repo>.git 2>/dev/null
git push origin main --force
```

**When to use this over filter-repo:**
- You only want 1 commit visible on GitHub
- No need to preserve contribution timeline or commit messages
- Simpler: no Python deps (`git-filter-repo` not required), single command, fewer failure modes
- File-level changes already made (LICENSE copyright, stale URLs) are included in the squashed commit automatically

**Pitfalls:**
- **Destroys all commit history** — squash first, then decide if you really need it.
- **`git reset --soft <root>` keeps all changes staged** — the amend creates one commit with ALL files. Verify the staged file list with `git diff --cached --name-only` first.
- **No filter-repo backups created** — once the reflog is expired and pruned, the old commits are truly gone. `git reflog expire --expire=now --all` is irreversible.
- **GitHub CDN cache** — the UI may still show old contributors for a few minutes after push. The API (`/repos/<owner>/<repo>/contributors`) reflects the new state instantly. Verify with the API, not the web page.

### 3. Verify the result

```bash
git log --all --format="%H|%an|%ae|%s"
git log --all --format="%s" | grep -i "\bhr\b\|old-term"  # should be empty
```

### 4. Re-add remote and force push

`git-filter-repo` **always removes the origin remote** for safety.

```bash
git remote add origin <url>
git push origin main --force
```

### 5. Verify on GitHub

```bash
# Check commits via API
curl -s https://api.github.com/repos/<owner>/<repo>/commits?per_page=5

# Check contributors (old authors removed)
curl -s https://api.github.com/repos/<owner>/<repo>/contributors
```

## Pitfalls

- **filter-repo removes origin** — always re-add it before pushing.
- **Inline callbacks use `b'...'` bytes** — not strings. The callback body runs in a restricted eval context; imports are NOT available unless inlined.
- **`--replace-message` defaults to literal matching** — use `regex:` prefix for patterns. Without it, `\bhr\b` will try to match the literal string `\bhr\b`.
- **Cannot chain filter-repo passes easily** — each run rewrites from the original. If you need name+email AND regex message replacements, do them together in one `--message-callback`.
- **`--force` is required** when filter-repo detects a backup ref already exists from a previous run.
- **Backup refs** live under `refs/original/`. List with `git for-each-ref refs/original/`. Run filter-repo again (with `--force`) to overwrite them.
- **Force push overwrites remote history** — any open PRs or forks referencing old commits will break. Coordinate.

## Windows-specific notes

- **git-bash** (MSYS2) works. The inline callbacks run under the system Python, not a venv.
- **`eval: line N: syntax error near unexpected token`** — caused by nested quotes in bash. Use `execute_code` tool (Python subprocess) or a separate `write_file` approach for complex callbacks instead of trying to pass them through shell quoting.
- **`--message-callback MUST return message`** — contrary to old docs, modern filter-repo requires `return message` at the end of `--message-callback`, just like `--name-callback`/`--email-callback`. Without it you get `Error: --message-callback should have a return statement`. Always end with `return message`.
- **`--message-callback "import re; ..."`** — the `import re` must be inlined in the callback string. Multi-line callbacks use semicolons or `\n` inside the string.
- **Stripping Co-Authored-By lines** — use a one-liner:
  ```python
  import re; message = re.sub(b'Co-Authored-By: Claude[^\n]*\n?', b'', message); return message
  ```
- **CRLF warnings** are cosmetic — git-filter-repo handles them fine.
- **Path separators**: Use forward slashes (`/c/Users/...`) inside callbacks, not backslashes.

## When to use this vs. other approaches

| Scenario | Tool |
|----------|------|
| Rename author in all commits | `git filter-repo --name-callback` |
| Remove a file from all history | `git filter-repo --path [file] --invert-paths` |
| Split a subdirectory to new repo | `git filter-repo --subdirectory-filter` |
| Bulk message rewrite with regex | `git filter-repo --replace-message` |
| **Collapse all history to 1 commit** | **`git reset --soft <root>` + `git commit --amend`** |
| Remove a single commit | `git rebase -i` |
| Rename a local-only branch | `git branch -m` |
| Just change the latest commit message | `git commit --amend` |
| Scorched-earth (delete + recreate repo) | Admin: delete repo on GitHub, recreate, push fresh |

### Decision: squash vs. filter-repo vs. delete+recreate

| Goal | Best approach | Why |
|------|---------------|-----|
| Remove sensitive/old author names from history | filter-repo `--name-callback` | Preserves all commit timestamps and progression |
| Remove old terms from commit messages | filter-repo `--message-callback` or `--replace-message` | Targeted rewrite, keeps history intact |
| Repo was forked and needs to be fully independent | filter-repo (all callbacks) | Removes original author + legacy references while keeping contribution timeline |
| **No history needed — clean slate** | **Squash** (`reset --soft` + amend) | Simpler than filter-repo, no Python deps, one command. Same result on GitHub (1 commit, no old trace). |
| GitHub UI still shows old contributors and CDN is stale | Squash or filter-repo both work | Wait a few minutes for CDN cache to expire; API reflects the new state instantly |
| User wants *no trace* the repo ever existed | Delete repo + recreate | Overkill for most cases — squash achieves the same visible result with zero admin overhead |

## 6. Delete + Recreate (Scorched-Earth Cleanup)

When you need absolute removal — no commit history, no contributors list, no fork network, no stale CDN cache showing old data — delete the repo on GitHub and recreate it fresh. This is the only approach that guarantees zero ancestral trace.

### When to choose this

| Scenario | Why delete+recreate beats the alternatives |
|----------|--------------------------------------------|
| Fork needs to be fully independent with *no link* to the original | filter-repo preserves contributor timeline; squash still shows a repo that *was* a fork. Delete+recreate starts from scratch. |
| User explicitly wants it | The user may prefer the clean break, even if squash is technically sufficient |
| GitHub CDN cache stubbornly shows old data after squash | API is authoritative, but if the user keeps seeing stale data, delete+recreate is definitive |
| Repo was published publicly with the wrong identity | No trace of old name, description, or commits anywhere |

### Workflow

**Step 1 — User deletes repo via GitHub UI**

API deletion requires a classic PAT with `repo` scope. Fine-grained tokens lack this. Safest: ask the user to delete via GitHub.com → Settings → Danger Zone → Delete this repository.

**Step 2 — Recreate the repo via API**

Extract the token from `.git-credentials` (format: `https://username:TOKEN@github.com`):

```bash
token=$(grep 'github.com' ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\\([^@]*\\)@.*|\\1|')
```

Create the repo:

```bash
curl -s -X POST \
  -H "Authorization: Bearer $token" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/user/repos \
  -d '{"name": "repo-name", "description": "Description", "private": false}'
```

**Step 3 — Push from local**

```bash
cd /path/to/repo
git remote add origin https://github.com/username/repo-name.git
```

Check branch name — new GitHub repos default to `main`, but local may be `master`:

```bash
git rev-parse --abbrev-ref HEAD   # check
git push origin master:main --force   # push if local is master
git push origin main --force          # push if local is main
```

**Step 4 — Update GitHub description (separate API call)**

The `POST /user/repos` description field sets the initial description but the recreate is fast enough that a separate `PATCH` is cleaner:

```bash
curl -s -X PATCH \
  -H "Authorization: Bearer $token" \
  https://api.github.com/repos/username/repo-name \
  -d '{"description": "Final description covering token-saving features"}'
```

**Step 5 — Verify**

```bash
# Check commits (should be 1)
curl -s https://api.github.com/repos/username/repo-name/commits?per_page=3 | python3 -c "import sys,json; print(len(json.load(sys.stdin)), 'commits')"

# Check contributors (should be only you)
curl -s https://api.github.com/repos/username/repo-name/contributors
```

### Pitfalls

- **`Authorization: token` is deprecated** — GitHub still accepts it, but `Bearer` is the modern header. If a `.git-credentials` token gives 401 with `token`, try `Bearer`.
- **Fine-grained PAT cannot delete repos** — classic PAT with `repo` scope required. Delete via GitHub UI to avoid token scope issues entirely.
- **Remote origin still points to deleted repo** — `git remote add origin` will fail on first push. Must re-add after recreation.
- **Local branch name mismatch** — don't rename `master`→`main` locally unless the local name causes confusion. `git push origin master:main` works fine.
- **Push may time out on first try** — the repo is brand new and GitHub needs a moment. Retry once if the first push times out.
- **GitHub UI cache** — "This repository has been deleted" or old contributors list may linger for a few minutes. The API is authoritative.
- **This destroys all commit history, issues, PRs, discussions, Actions runs, and releases.** Nothing survives. Do not use if you want to preserve any of those — use filter-repo or squash instead.

## References

- `references/filter-repo-callbacks.md` — exact session transcript of working inline callback patterns
- `references/complete-project-rebrand.md` — full workflow for removing an original author, scrubbing project name from 61 commits, conditional message rewrites, and GitHub API verification
