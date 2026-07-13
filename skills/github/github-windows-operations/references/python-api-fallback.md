# Python urllib Fallback for GitHub API (Windows git-bash)

When `gh` is unavailable and `curl` with embedded JSON fails on Windows
git-bash (single-quote quoting mismatch), use Python's `urllib.request`
in `execute_code` as a reliable third path.

## When to use this

1. `gh` not installed (check: `command -v gh`)
2. `curl` in terminal has quoting issues with JSON body payloads
3. You already have token in `.env` and want to call the GitHub API without
   shell escaping

## Token extraction from .env

```python
import os, re
env = os.path.expanduser("~/AppData/Local/hermes/.env")
with open(env) as f:
    content = f.read()
m = re.search(r'^GITHUB_TOKEN=(.+)$', content, re.MULTILINE)
token = m.group(1).strip().strip("'\"")
```

## Pattern: Create a repo

```python
import urllib.request, json

data = json.dumps({
    "name": "repo-name",
    "description": "Optional description",
    "private": True,
    "auto_init": False
}).encode()

req = urllib.request.Request(
    "https://api.github.com/user/repos",
    data=data,
    headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
)
try:
    resp = urllib.request.urlopen(req)
    result = json.loads(resp.read())
    print(f"OK: {result['full_name']}")
except urllib.error.HTTPError as e:
    body = json.loads(e.read())
    print(f"HTTP {e.code}: {body.get('message', e.reason)}")
```

## Common operations

| Operation | Endpoint | Notes |
|-----------|----------|-------|
| Create repo (user) | `POST /user/repos` | `name` required, `private` optional |
| Create repo (org) | `POST /orgs/{org}/repos` | Need org membership |
| Delete repo | `DELETE /repos/{owner}/{repo}` | Classic PAT with `repo`+`delete_repo` |
| Get user info | `GET /user` | Returns `login`, `id`, etc. |
| List repos | `GET /user/repos?per_page=20&sort=updated` | Returns array |
| Test token | `GET /user` with auth header | 200=ok, 401=expired/revoked |

## Pitfalls

- **Fine-grained PAT vs classic**: both work, but fine-grained tokens need
  explicit repo/organization access. Classic PATs with `repo` scope always
  work for user-owned repos.
- **Bearer vs token**: Use `f"Bearer {token}"`. GitHub accepts both `token`
  and `Bearer` schemes, but Bearer is the modern format and some newer API
  endpoints require it.
- **Rate limits**: 5,000/hour authenticated, 60/hour unauthenticated.
- **Token expiry**: If a previously-working token returns 401, the user
  likely needs to regenerate it at https://github.com/settings/tokens.
