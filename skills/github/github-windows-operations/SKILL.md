---
name: github-windows-operations
description: >-
  Windows-specific GitHub operations: retrieving PATs from Windows Credential
  Manager, deleting repos when token scopes are insufficient, and working
  around the absence of `gh` CLI on Windows.
created_from_user_sessions: true
---

# GitHub Windows Operations

Use this skill when working with GitHub on Windows (git-bash) where `gh` CLI may not be installed, or when the stored token lacks sufficient scopes for admin operations like repo deletion.

## 1. Token Retrieval via Windows Credential Manager

On Windows, `gh auth login` stores OAuth tokens in the **Windows Credential Manager**, not in `~/.git-credentials`. Retrieve them with:

```bash
CREDS=$(echo "protocol=https
host=github.com" | git credential-manager get 2>/dev/null)
TOKEN=$(echo "$CREDS" | grep "^password=" | cut -d= -f2)
```

**Why this is needed:** `grep "github.com" ~/.git-credentials` fails on Windows because that file doesn't exist — the credential helper stores tokens in the OS-level vault.

### Token Scope Check

Once retrieved, check what scopes the token has:

```bash
curl -sI -H "Authorization: token $TOKEN" https://api.github.com/user 2>&1 | grep -i "x-oauth-scopes"
```

Common scope sets for Windows-stored tokens:
- `repo, gist, workflow` — can read, push, manage Actions, but **cannot delete repos** without the separate `delete_repo` scope
- `repo, delete_repo, gist, workflow` — full access including deletion

```bash
# Also verify username
curl -s -H "Authorization: token $TOKEN" https://api.github.com/user | python3 -c "import json,sys; print(json.load(sys.stdin)['login'])"

# List repos
curl -s -H "Authorization: token $TOKEN" "https://api.github.com/user/repos?per_page=100&type=owner&sort=updated" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for r in data:
    vis = 'priv' if r['private'] else 'pub '
    print(f\"{r['name']}  {vis}  {r['updated_at'][:10]}\")
print(f'Total: {len(data)}')
"
```

## 2. Deleting Repositories

### Via API (when token has `delete_repo` scope)

```bash
CREDS=$(echo "protocol=https
host=github.com" | git credential-manager get 2>/dev/null)
TOKEN=$(echo "$CREDS" | grep "^password=" | cut -d= -f2)

curl -s -X DELETE \
  -H "Authorization: token $TOKEN" \
  "https://api.github.com/repos/owner/repo-name" \
  -w "\nHTTP %{http_code}\n"
```

### Via Web UI (when token lacks scope — the common case)

If the API returns `403 "Must have admin rights to Repository"`, the token lacks `delete_repo` scope. Tell the user:

> "The stored token has `repo, gist, workflow` scopes but NOT `delete_repo`. You can delete at the repo's GitHub page: **Settings → Danger Zone → Delete this repository**."

| Response code | Meaning |
|---------------|---------|
| `HTTP 204` | Deleted successfully |
| `HTTP 403` | Token lacks `delete_repo` scope — use Web UI |
| `HTTP 404` | Already deleted (or never existed) |
| `HTTP 422` | Validation error (wrong owner, etc.) |

### Batch Verification After Deletion

After the user deletes repos (via Web UI or otherwise), verify they're gone:

```bash
CREDS=$(echo "protocol=https
host=github.com" | git credential-manager get 2>/dev/null)
TOKEN=$(echo "$CREDS" | grep "^password=" | cut -d= -f2)

for repo in repo1 repo2 repo3; do
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/owner/$repo")
  echo "$repo: $([ "$code" = "404" ] && echo 'GONE' || echo 'still there')"
done

# Or list all remaining repos
curl -s -H "Authorization: token $TOKEN" \
  "https://api.github.com/user/repos?per_page=100&type=owner&sort=updated" | python3 -c "
import json, sys
for r in json.load(sys.stdin):
    print(f\"  {r['name']}\")
"
```

## 3. Finding Local Git Repos by Remote Owner

When doing a home-dir cleanup alongside GitHub repo deletion, find all local clones pointing to repos you're about to delete:

```bash
# Find all local directories with a git remote matching an owner
for d in ~/*/; do
  if [ -d "$d/.git" ]; then
    remote=$(cd "$d" && git remote get-url origin 2>/dev/null)
    echo "$remote  →  $d"
  fi
done

# Or specific to <username> repos
for d in ~/*/; do
  if [ -d "$d/.git" ]; then
    remote=$(cd "$d" && git remote get-url origin 2>/dev/null)
    echo "$remote" | grep -q "<username>" && echo "$remote  →  $d"
  fi
done
```

## 4. Creating Repos Without gh CLI (Python urllib Fallback)

When `gh` is not installed and `curl -d '{json...}'` fails on git-bash
(single-quote quoting mismatch with embedded JSON), use Python via
`execute_code`:

```python
import urllib.request, json

# Get token from .env
import os, re
env = os.path.expanduser("~/AppData/Local/hermes/.env")
with open(env) as f:
    content = f.read()
m = re.search(r'^GITHUB_TOKEN=(.+)$', content, re.MULTILINE)
token = m.group(1).strip().strip("'\"")
req = urllib.request.Request(
    "https://api.github.com/user/repos",
    data=json.dumps({"name": "repo-name", "description": "...",
                     "private": True, "auto_init": False}).encode(),
    headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
)
result = json.loads(urllib.request.urlopen(req).read())
print(f"Created: {result['full_name']}")
```

Then use `terminal()` for git init/add/commit/push.

> **Reference:** [`references/python-api-fallback.md`](references/python-api-fallback.md) — common operations, error handling, and pitfalls.

### End-to-end flow

1. **Test token**: `execute_code` with `GET /user` → confirm 200
2. **Create remote repo**: Python `urllib.request` → `POST /user/repos`
3. **Init local** (terminal): `mkdir repo && cd repo && git init`
4. **Stage** (terminal): copy files, `git add -A`
5. **Commit** (terminal): `git commit -m "message"`
6. **Rename branch** (terminal): `git branch -m master main` (GitHub defaults to `main`)
7. **Set remote + push** (terminal): `git remote add origin https://... && git push -u origin main`
8. **Optional: store creds** (terminal): `git config --global credential.helper store && echo "https://user:token@github.com" > ~/.git-credentials`

### Git-bash curl JSON pitfall

On Windows git-bash, single-quoted JSON in `curl -d '{json}'` often
fails with "Problems parsing JSON" — shell quoting mismatch. **Don't**
escape it. **Do** switch to Python `urllib.request`.

## 5. Cross-Platform CI Failure: CRLF Line Endings

When a git-bash created or edited file gets committed with Windows CRLF (`\r\n`) line endings, CI on Linux runners will see every line as different when using `diff` — even if the content is identical.

**Detection:**

```bash
# Check if a file has CRLF
file suspicious-file.md
# Output: "with CRLF line terminators" → bad for Linux CI

# Verify with cat -A — LF-only lines end with $, CRLF lines end with ^M$
head -5 suspicious-file.md | cat -A
# "## Header^M$" = CRLF    "## Header$" = LF-only
```

**Fix:** Convert to LF before committing:

```bash
dos2unix suspicious-file.md
# Fallback if dos2unix not available:
sed -i 's/\r$//' suspicious-file.md
```

**Verify the git blob has LF** (critical — git on Windows with `core.autocrlf=true` may silently convert back on commit):

```bash
git show HEAD:suspicious-file.md | head -1 | cat -A
# Must show $ not ^M$
```

**Permanent prevention:** Add a `.gitattributes` file to the repo that enforces LF for auto-generated files:

```
# Auto-generated CI artifacts — must match Linux runner output
SKILLS_INDEX.md text eol=lf
*.md text eol=lf
```

**Common scenario:** A "check-index" or "validate-generated-file" CI step on Ubuntu runs `diff` between a committed file and a freshly generated one. The workflow generates LF (Ubuntu default), but the committed file has CRLF (committed from Windows). Result: every line differs → CI fails → root cause is invisible in logs because `diff` output just shows content mismatch.

## 6. Pitfalls

- **Windows Credential Manager is the ONLY token source on git-bash** — don't check `~/.git-credentials` or `~/.config/gh/` on Windows; they don't exist. (Exception: if you explicitly set `git config --global credential.helper store`, then `~/.git-credentials` is used instead.)
- **OAuth `repo` scope does NOT include `delete_repo`** — they are separate scopes. A token with `repo` but not `delete_repo` can push code, manage issues, and run Actions, but cannot delete repos.
- **Classic PATs need explicit `delete_repo` scope** — for tokens created after ~2022, `delete_repo` is a checkbox on the token creation page at https://github.com/settings/tokens, not included in `repo`.
- **GitHub web UI works with any auth** — the user can delete repos from their browser regardless of token scopes, as long as they own the repo.
- **Private repos don't show in unauthenticated API calls** — use the authenticated token to list all repos including private ones.
- **The `#` token prefix is `token` not `Bearer`** — `-H "Authorization: token $TOKEN"` (not `Bearer`). GitHub supports both but `token` is the documented scheme for PATs.
- **CRLF line endings cause silent CI failures** on Linux runners using `diff` — every line compares as different. Check `file` output and `cat -A` before chasing deeper root causes. The fix is `dos2unix`, the prevention is `.gitattributes`.
