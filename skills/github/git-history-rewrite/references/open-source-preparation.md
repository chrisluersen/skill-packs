# Open-Source Preparation — Going Public

Workflow for taking a private/internal repo public: PII scrub, README polish, topics, licensing, and verification. Used during the agent-store public release (2026-07-04).

## Phase 1 — Audit

- Check each repo: description, topics, public/private, default branch
- Detect forks (API parent field)
- **Key signals:** clear description, 5-8 topics, text README (not just SVG), `main` branch, no personal paths

## Phase 2 — PII Scrub

```bash
grep -rn "C:/Users/<user>" --include="*" . 2>/dev/null | grep -v ".git/"
grep -rn "<old-username>" --include="*" . 2>/dev/null | grep -v ".git/"
grep -rn "<employer>" --include="*" . 2>/dev/null | grep -v ".git/"
```

**Standard replacements:**
- `C:/Users/<user>` → `$HOME`
- `~/agent-wiki` → `$WIKI_DIR`
- Personal GH username → `your-username` (except repo self-refs)
- Employer name → `[Your Employer]`
- API keys/secrets → purge to secrets vault (OneDrive backup)

**Check templates, example configs, test fixtures** — most common leak sources.

## Phase 3 — Identity Separation

Move personal files out of repo:
- USER.md, MEMORY.md → `~/OneDrive/hermes-backup/identity/`
- config.yaml (real keys) → `~/OneDrive/hermes-backup/`
- secrets → `~/OneDrive/hermes-backup/secrets/`

## Phase 4 — Public Content

| Item | Minimum |
|------|---------|
| README.md | What, quick start, badges |
| LICENSE | MIT (default for public tools) |
| CONTRIBUTING.md | Basic PR guidelines |
| install.sh (CLI tools) | Shebang, works cross-platform |
| .gitignore | Standard + `.git_bak*`, `.env`, `venv/`, `__pycache__` |
| catalog / index | Auto-generated if large skill library |

## Phase 5 — History

**Squash (PII-sensitive repos):**
```bash
git reset --soft $(git rev-list --max-parents=0 HEAD)
git commit --amend -m "Initial commit: description"
```

**filter-repo (preserve history):**
```bash
pip install git-filter-repo
git filter-repo --force --name-callback "return name.replace(b'OldUser', b'your-username')"
```

**Verify:**
```bash
git grep -c "C:/Users/" HEAD --   # must be 0
git grep -c "old-username" HEAD --  # must be 0
```

## Phase 6 — Repo Settings (API)

```bash
# Make public
curl -s -X PATCH -H "Authorization: Bearer $TOKEN" \
  https://api.github.com/repos/$OWNER/$REPO \
  -d '{"private": false}'

# Set topics
curl -s -X PUT -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github.mercy-preview+json" \
  https://api.github.com/repos/$OWNER/$REPO/topics \
  -d '{"names": ["topic1", "topic2"]}'
```

## Phase 7 — Archive Merged Repos

Replace README with archive notice, commit, push, then GitHub-archive via Settings → Danger Zone.

## Summary Checklist

- [ ] Topics set (5-8 per repo)
- [ ] Description written
- [ ] README has text content (not SVG-only)
- [ ] License file present
- [ ] No personal paths in HEAD
- [ ] Default branch is `main`
- [ ] Old repos archived with notice
- [ ] Identity backed up externally