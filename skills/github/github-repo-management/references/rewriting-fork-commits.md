# Rewriting Fork Commit Messages — Reference

Session where this was validated: Valhalla fork (chrisluersen/valhalla) sync with nesquena/hermes-webui.

## Scenario

You have a fork with 3+ custom commits that have terse messages. You want to rewrite them with proper conventional commits format + detailed bodies **before** rebasing onto upstream, so the rewritten history is what gets rebased.

## Technique: `git commit-tree` Chain

This approach gives you full control and is scriptable. Used successfully to rewrite 3 commits.

### Step-by-step

```bash
# 1. Identify the commits to rewrite (oldest first)
git log --oneline -3 --reverse
# 3347af3b Valhalla fork: Windows launchers...
# 5b4ca3b7 Add Windows startup script...
# 618d88e4 Add update-valhalla.bat...

# 2. Get the tree hash for each commit
git rev-parse 3347af3b^{tree}   # a9acd92f...
git rev-parse 5b4ca3b7^{tree}   # cffcf3e0...
git rev-parse 618d88e4^{tree}   # 51452be2...

# 3. Identify the upstream parent (commit before your first custom commit)
git log --oneline | grep -n "Release PH"
# 70b7cf86 Release PH (v0.51.447)...

# 4. Reset to upstream parent (detaches HEAD)
git reset --hard 70b7cf86

# 5. Chain commit-tree calls, piping new message via stdin
NEW1=$(git commit-tree a9acd92f... -p 70b7cf86 <<'EOF'
feat: Add Valhalla Windows launchers and Start Menu integration

Add complete Windows launcher setup for Valhalla (Hermes WebUI fork):
- start.ps1: PowerShell launcher that activates venv and starts gateway
- create-shortcut.ps1: Creates Start Menu shortcut with custom Valhalla icon
- assets/valhalla.ico: Multi-size icon (256, 128, 64, 48, 32, 16) generated from neofetch-ai.png
- Makefile targets: `make shortcut` and `make shortcut-pin` for easy setup

The shortcut targets the gateway entry point and sets working directory to the
repo root. Taskbar pinning requires manual right-click → Pin to taskbar due to
Windows security restrictions on programmatic pinning.
EOF
)

NEW2=$(git commit-tree cffcf3e0... -p $NEW1 <<'EOF'
feat: Add Windows startup script for Hermes WebUI gateway

Add start-valhalla.bat for double-click launching on Windows:
- Activates the Python virtual environment automatically
- Starts the Hermes gateway on http://localhost:8000
- Opens the default browser to the Valhalla UI
- Handles missing venv gracefully with clear error message

This enables zero-config launch from Start Menu, desktop shortcut,
or taskbar without requiring a terminal.
EOF
)

NEW3=$(git commit-tree 51452be2... -p $NEW2 <<'EOF'
chore: Add update-valhalla.bat for upstream sync workflow

Add automated upstream rebase workflow to keep Valhalla fork current:
- Fetches latest from upstream (nesquena/hermes-webui)
- Rebases local commits on top of upstream/master
- Preserves Valhalla-specific commits (launchers, shortcuts, Hub Service config)
- Force-pushes to origin with --force-with-lease for safety

Run this script periodically to pull upstream fixes/features while
maintaining fork customizations. Uses rebase (not merge) for clean history.
EOF
)

# 6. Move branch pointer to new HEAD
git reset --hard $NEW3

# 7. Verify
git log --oneline -6
git log -3 --format=fuller

# 8. Force-push with lease
git push origin master --force-with-lease
```

### Why This Worked Well

- **No editor interaction** — fully scriptable (used from execute_code)
- **Preserves exact file trees** — each new commit has identical content to original
- **Clean parent chain** — each new commit parents the previous new commit
- **No rebase conflicts** — you're not replaying patches, just re-pointing commits

### Caveats

- **Author dates reset** to now (unlike `rebase -i` which preserves them). For fork commits that don't need historical accuracy, this is fine.
- **Requires knowing tree hashes** upfront. Get them before `git reset --hard`.
- **Only works for linear history** — if your custom commits have merges or are interleaved with upstream, use `rebase -i` instead.

## Alternative: Interactive Rebase (Preserves Dates)

```bash
git rebase -i upstream/master
# Change 'pick' to 'reword' for each of your commits
# Save, editor opens for each — write new message
# Continue until done
```

Use this when author dates matter and commit count is small (<10).