# Complete Project Rebrand — Author Removal + Message Scrub + Verification

From the cascade rename session (2026-07-03). Reference for turning a forked/derived repo into a fully independent project by rewriting its entire history.

## Goal

Remove every trace of the original author, their email, and the project name from all 61 commits. End state: only `<username>` as contributor, all commit messages reference the new project name.

## Approach

Three-phase: scrub → verify → fix edge cases → push.

### Phase 1: Replace-message (bulk term scrub)

Write a `replacements.txt`:

```
regex:hermes-router==>cascade
regex:(^|[^a-zA-Z])hr\b==>\1cascade
```

Run:

```bash
git filter-repo --force --replace-message replacements.txt
```

This handles **message bodies** (the %s). Use `regex:` prefix — without it the patterns are treated as literal text.

### Phase 2: Conditional message callbacks (fix specific messages)

After Phase 1, some messages read weird (e.g. "full rename: cascade -> cascade"). Fix those with a callback:

```bash
git filter-repo --force \
  --message-callback "
msg = message.decode('utf-8')
if 'full rename' in msg and 'cascade -> cascade' in msg:
    msg = 'docs: overhaul README, scripts, and docs for cascade standalone release'
elif 'rename: hermes-router -> cascade' in msg:
    msg = 'chore: rebrand project to cascade with full code and doc updates'
message = msg.encode('utf-8')
return message
"
```

**Note:** filter-repo runs in sequence on the **original** history each time. But in practice, since Phase 1 already ran, run Phase 2 on the Phase-1 output by adding `--force` to overwrite the backup ref.

### Phase 3: Name/email callbacks (author removal)

Replace `Shaf2665` with `<username>` across all commits — author, committer, and email:

```bash
git filter-repo --force \
  --name-callback "
name = name.decode('utf-8')
if name == 'Shaf2665':
    name = '<username>'
name = name.encode('utf-8')
return name
" \
  --email-callback "
email = email.decode('utf-8')
if 'mmshaf21@gmail.com' in email:
    email = '57424623+user@example.com'
email = email.encode('utf-8')
return email
"
```

**Key insight:** `--name-callback` and `--email-callback` can be combined in a single pass. But `--message-callback` needs its own pass or be combined in one complex inline expression. When doing all three (name + email + messages), combine into one call with all three `--*-callback` flags.

### Verification

After all passes, verify three things:

**1. Commit messages have zero old terms:**
```bash
git log --all --format="%s" | grep -i -E "\bhr\b|hermes.router|old.project"
# Empty = clean
git log --all --format="%s"
# Visual scan — messages should read naturally
```

**2. All authors/committers are you:**
```bash
git log --all --format="%an|%ae" | sort -u
# Should only show you
```

**3. GitHub API confirms (push first, then check):**
```python
import requests

# Check commits
r = requests.get("https://api.github.com/repos/chrisluersen/cascade/commits?per_page=3")
for c in r.json():
    print(f"{c['commit']['author']['name']}: {c['commit']['message'][:60]}")

# Check contributors — should show only you
r = requests.get("https://api.github.com/repos/chrisluersen/cascade/contributors")
for c in r.json():
    print(f"{c['login']}: {c['contributions']} contributions")
```

### Push

```bash
cd <repo>
git remote add origin https://github.com/chrisluersen/cascade.git
git push origin main --force
```

**Post-push:** GitHub Pages/CDN caches the old page for a few minutes. Use the API (as above) for immediate verification — it reflects the pushed state instantly.

## Pitfalls

- **filter-repo removes `origin`** every run. Re-add before push.
- **`--replace-message` defaults to literal** — always use `regex:`, `literal:`, or `glob:` prefix.
- **Chaining filter-repo passes**: each run needs `--force` to overwrite the backup ref from the previous pass. They compose correctly (each operates on the previous pass's output).
- **Callback scope**: `name`, `email`, `message` are bytes (`b'...'`). Decode → modify → re-encode.
- **Return value required**: `--name-callback`, `--email-callback`, and `--message-callback` ALL need a return. For message callbacks, assign to a local variable then `return` it:
  ```python
  msg = message.decode('utf-8')
  # ... modify msg ...
  message = msg.encode('utf-8')
  return message
  ```
  A bare `message = ...` assignment at the end without `return message` produces `Error: --message-callback should have a return statement` on modern filter-repo.
- **Nested quotes in bash callbacks**: multi-line callbacks with conditions work best with `"` wrapping the outer bash arg and single quotes inside. For very complex callbacks, use `write_file` + Python subprocess instead.
- **GitHub contributors cache**: after force-push, the contributors API reflects the rewritten history immediately but the UI may take a few minutes to update. The login names on commits change instantly.
- **Co-Authored-By footers**: filter-repo rewrites the commit **message** body. Co-author footers (e.g. `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`) remain if they were in the original message. To remove those, add a message callback that strips them.
