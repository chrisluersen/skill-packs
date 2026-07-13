# Inline git-filter-repo Callback Patterns

Working syntax from a real session — each pattern was verified via API after force push.

## Name + Email + Message in one pass

```bash
git filter-repo --force \
  --name-callback "return name.replace(b'Shaf2665', b'<username>')" \
  --email-callback "return email.replace(b'mmshaf21@gmail.com', b'57424623+user@example.com')" \
  --message-callback "import re; return re.sub(b'\\\\bhr\\\\b', b'cascade', message.replace(b'hermes-router', b'cascade'))"
```

Note the **triple-escaped backslash** (`\\\\b`) — needed because the string passes through bash then Python eval. In a write_file context or execute_code tool, use `\\b` (double).

## Regex replacement via --replace-message file

The `--replace-message` flag reads a text file. **Regex patterns require the `regex:` prefix** — without it, even patterns like `\bhr\b` are treated as literal text.

**Replacements.txt format:**
```
regex:hermes-router==>cascade
regex:(^|[^a-zA-Z])hr\b==>\1cascade
```

Note: there's no `b'...'` bytes wrapper — the file is read as-is.

## After filter-repo

filter-repo **always removes the origin remote**. Re-add before push:

```bash
git remote add origin https://github.com/<owner>/<repo>.git
git push origin main --force
```

## Verification

```bash
# Check commits
git log --all --format="%H|%an|%ae|%s"

# Check contributors via API (authoritative — shows GitHub auth not just local)
curl -s https://api.github.com/repos/<owner>/<repo>/contributors
```

## key insight

Do file-level cleanup FIRST (fix all files in HEAD, commit), THEN rewrite history. The new history will be clean without needing extra commits on top. Reverse order (rewrite history then fix files) requires an extra rewrite pass.
