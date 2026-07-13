---
name: github-fork-workflow
description: Standard workflow for forking a GitHub repository and setting up local development
category: github
tags: [github, fork, clone, workflow, setup]
---

# GitHub Fork & Clone Workflow

Standard procedure for forking a repository on GitHub and cloning it locally for development.

## Prerequisites

- GitHub account
- `git` installed locally
- (Optional) `gh` CLI authenticated (`gh auth login`)

## Steps

### 1. Fork on GitHub

Navigate to the source repository (e.g., `nesquena/hermes-webui`) and click **Fork** → choose your account/org → **Create fork**.

Result: `your-org/hermes-webui` (or `your-username/hermes-webui`)

### 2. Clone Your Fork Locally

```bash
git clone https://github.com/your-org/hermes-webui.git
cd hermes-webui
```

### 3. Add Upstream Remote (Recommended)

```bash
git remote add upstream https://github.com/nesquena/hermes-webui.git
git fetch upstream
```

This lets you sync changes from the original repo:
```bash
git pull upstream main
```

### 4. Create a Feature Branch

```bash
git checkout -b feature/hub-integration
```

### 5. Push to Your Fork

```bash
git push -u origin feature/hub-integration
```

### 6. Open a Pull Request

Use `gh` CLI or GitHub web UI:
```bash
gh pr create --title "Add Hub Service integration" --body "..."
```

## Syncing with Upstream (Ongoing)

```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
git checkout feature/hub-integration
git rebase main
```

## Common Pitfalls

| Issue | Fix |
|-------|-----|
| Forgot to add upstream | `git remote add upstream <original-repo-url>` |
| Local main diverged | `git reset --hard upstream/main` (if no local commits) |
| Push rejected (non-fast-forward) | `git pull --rebase origin main` then push |

## Related Skills

- `github-pr-workflow` — Full PR lifecycle (branch, commit, CI, merge)
- `github-repo-management` — Clone/create/fork repos, manage remotes
- `github-code-review` — Review PRs with diffs and inline comments