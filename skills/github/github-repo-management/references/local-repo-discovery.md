# Local Repository Discovery Commands

Useful patterns for finding GitHub repositories on the local filesystem.

---

## Find All Git Repos with a Given Remote URL Pattern

```bash
# Find all .git directories and check their origin remote
find ~/AppData/Local/hermes -maxdepth 4 -name ".git" -type d 2>/dev/null | while read gitdir; do
  dir=$(dirname "$gitdir")
  if [ -d "$dir" ]; then
    remote=$(cd "$dir" && git remote get-url origin 2>/dev/null)
    if echo "$remote" | grep -q "hermes-webui"; then
      echo "$dir -> $remote"
    fi
  fi
done
```

**Output example:**
```
~/AppData/Local/hermes/hermes-webui -> https://github.com/nesquena/hermes-webui.git
```

---

## Find Repos by Owner Pattern

```bash
# Find all repos owned by a specific user
find ~/AppData/Local/hermes -maxdepth 4 -name ".git" -type d 2>/dev/null | while read gitdir; do
  dir=$(dirname "$gitdir")
  if [ -d "$dir" ]; then
    remote=$(cd "$dir" && git remote get-url origin 2>/dev/null)
    if echo "$remote" | grep -q "<username>"; then
      echo "$dir -> $remote"
    fi
  fi
done
```

---

## Quick Listing of All Local Repos

```bash
# List all local git repos with their origin
find ~/AppData/Local/hermes -maxdepth 4 -name ".git" -type d 2>/dev/null | while read gitdir; do
  dir=$(dirname "$gitdir")
  if [ -d "$dir" ]; then
    remote=$(cd "$dir" && git remote get-url origin 2>/dev/null || echo "no-origin")
    echo "$dir -> $remote"
  fi
done
```

---

## Common Pitfall: Fork Created on GitHub But Not Cloned Locally

**Symptom:** You forked a repo on GitHub (`gh repo fork owner/repo` or web UI) but can't find it on disk.

**Cause:** Forking on GitHub doesn't automatically clone to your local machine.

**Fix:**
```bash
# Clone your fork
git clone https://github.com/<your-username>/repo-name.git

# Or use gh
gh repo clone <your-username>/repo-name

# Add upstream remote for syncing
cd repo-name
git remote add upstream https://github.com/original-owner/repo-name.git
```

---

## Verification Commands

```bash
# Check which remote you're tracking
git remote -v

# Check current branch and upstream
git status

# See all remotes
git remote -v
```

---

## Related: Hermes-Specific Repos

For this user's setup, common Hermes-related repos:
| Repo | Upstream | Typical Local Path |
|------|----------|-------------------|
| hermes-webui | nesquena/hermes-webui | `~/AppData/Local/hermes/hermes-webui` |
| hermes-webui (fork) | chrisluersen/hermes-webui | `~/AppData/Local/hermes/hermes-webui-fork` |
| hermes-agent | NousResearch/hermes-agent | (installed via pip, not typically cloned) |