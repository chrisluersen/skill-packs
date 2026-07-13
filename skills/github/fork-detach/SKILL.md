---
name: fork-detach
description: Detach a forked repository from its origin — scrub all identity traces, rewrite metadata, and make it stand alone
category: github
tags: [github, fork, detach, cleanup, rebrand, scrub]
---

# Fork Detach: Making a Fork Standalone

When you fork a repo and decide to go your own way, every trace of the original project's identity needs scrubbing — project names, CLI aliases, env vars, config keys, package names, license references. This skill covers the systematic sweep.

## When to Use

- You forked a project and want to release it as your own
- You extracted a component from a larger project
- You're rebranding a fork and need a clean identity
- You want to ensure zero overlap before making a fork public

## Step 1 — Detect the Identity Leaks

Search across ALL file types for the original project's names and identifiers:

```bash
# Project name variants (snake_case, kebab-case, PascalCase)
grep -rn "original-project\|original_project\|OriginalProject\|OrigProject" . \
  --include="*.py" --include="*.sh" --include="*.md" --include="*.txt" \
  --include="*.yaml" --include="*.yml" --include="*.json" --include="*.env*" \
  --include="Dockerfile" --include="docker-compose*" --include="LICENSE" \
  --include="*.example" --include="*.cfg" --include="*.ini" --include="*.toml" \
  --include="Makefile" --include="*.mk" --include="*.rb" --include="*.rs" 2>/dev/null

# CLI command/alias from the original
grep -rn "\bhr \b" . ...  # replace hr with the original's CLI command

# Env var prefixes
grep -rn "ROUTER_\|ORIGINAL_ENV_" . ...

# Config keys, package names
grep -rn "original\.config\.key" . ...
```

Search targets to cover:
- **Project name** in every casing variant (snake, kebab, camel, Pascal)
- **CLI aliases** and wrapper command names
- **Env variable prefixes** (ROUTER_STATE_, PROXY_KEY_)
- **Config keys** and default values
- **Package names** in requirements.txt, setup.py, pyproject.toml
- **README/docs** — project name, badges, URLs, example commands
- **CI configs** — workflow names, job names
- **Docker** — image names, labels, container names
- **License headers** — stale copyright notices

Always exclude `venv/`, `.git/`, `node_modules/` from searches.

## Step 2 — Fix All Leaks

Classify and fix each hit:

| Category | Approach |
|----------|----------|
| **Assigned to the original** | Rewrite as your project name |
| **Descriptive of the original** | Rewrite as neutral/your project description |
| **Dead config keys** (env vars the code doesn't read) | Remove the commented-out example |
| **README / docs / badges** | Rewrite fully — your project isn't a fork anymore |
| **LICENSE** | Verify it's the intended license with your name |
| **Requirements** | Remove original-internal packages, check versions |

For bulk text fixes, use `patch` with unique context. For the README and docs, a full rewrite via `write_file` is often cleaner than N tiny patches.

## Step 3 — Update GitHub Presence

```bash
# Update description via GitHub API
# (token stored in ~/.git-credentials or passed directly)
curl -s -X PATCH "https://api.github.com/repos/$OWNER/$REPO" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -d '{"description": "Your concise, factual description"}' | jq .description
```

Also update: home page URL, topics, website field if applicable.

## Step 4 — Rewrite the Commit Message

If the sole commit still carries the original project's commit message:

```bash
git commit --amend -m "Your new standalone commit message"
```

## Step 5 — Verify Clean

Run the same grep sweep from Step 1 again and confirm zero hits. Also check:

```bash
# Any remaining references to the original author
grep -rn "original-author\|orig-org\|upstream-org" ... --include="*" . 2>/dev/null

# Check that description on GitHub actually updated
curl -s "https://api.github.com/repos/$OWNER/$REPO" | jq .description
```

## Step 6 — Push

```bash
git push origin main --force
```

## Related Skills

- `github-fork-workflow` — Setting up a fork for upstream contributions (opposite direction)
- `git-history-rewrite` — Squashing, rebasing, or modifying git history
- `codebase-inspection` — Codebase metrics and structure analysis

## Pitfalls

- **Don't skip the verification grep.** It's easy to miss hits in config files, examples, or docs that reference the original project by name.
- **Dead env vars** — commented-out examples of original project's config keys are often left as clutter. Remove them entirely; they confuse users.
- **Badges in README** — Original-project CI badges, coverage badges, or "forked from" links need updating. A detached fork should present as its own project.
- **License notices** — If you changed the license, update every file header. If you kept the same license, still verify the copyright holder name.
- **Case sensitivity** — Search for both the original project name and any abbreviations/acronyms (e.g., if the original was "Hermes Router", search for both "hermes-router" and "hr").
