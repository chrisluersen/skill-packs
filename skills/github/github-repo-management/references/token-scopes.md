# GitHub Token Scopes — Quick Reference

## Token Types

| Token Type | UI Label | Can Rename Repo? | Can Manage Secrets? | Scope Granularity |
|------------|----------|------------------|---------------------|-------------------|
| **Classic PAT** | "Personal access tokens (classic)" | ✅ Yes (needs `repo` scope) | ✅ Yes | Coarse (org/repo/user level) |
| **Fine-grained PAT** | "Fine-grained personal access tokens" | ❌ No `repo` scope exists | ✅ Yes (per-repo) | Fine (per-repo, per-permission) |

## Required Scopes for Common Operations

| Operation | Required Scope(s) | Token Type |
|-----------|-------------------|------------|
| Repo rename (`PATCH /repos/{owner}/{repo}`) | `repo` | Classic only |
| Create/delete repo | `repo` | Classic only |
| Fork repo | `repo` | Classic only |
| Branch protection | `repo` | Classic only |
| Actions secrets | `repo` | Both (fine-grained: "Repository administration: Read+Write") |
| Read repo contents | `public_repo` or `repo` | Both |
| Install skill from GitHub | `read:packages` or fine-grained "Contents: Read" | Both |

## For Hermes Users

Your `.env` should have **both**:

```env
# Fine-grained PAT — for skill search/install (Contents: Read on target repos)
GITHUB_TOKEN=ghp_fine_grained_token...

# Classic PAT — for repo operations (rename, create, fork, branch protection)
# Must have `repo` scope checked at https://github.com/settings/tokens/new
GITHUB_REPO_TOKEN=ghp_classic_token...
```

## Pitfall: Fine-Grained PAT Cannot Rename Repos

This session's error: `{"message": "Bad credentials", "status": 401}` on `PATCH /repos/chrisluersen/hermes-webui` — the token was valid but **lacked `repo` scope** because fine-grained PATs don't offer it.

**Fix:** Generate a classic PAT with `repo` scope, or use `gh repo rename` which uses your gh CLI auth (may have broader permissions).