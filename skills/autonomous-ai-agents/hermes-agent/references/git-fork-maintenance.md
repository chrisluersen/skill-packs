# Git Fork Maintenance for Hermes WebUI (Valhalla)

Pattern for keeping a Hermes WebUI fork updated with upstream while preserving custom Windows integrations.

## Prerequisites

- Fork exists at `https://github.com/<your-user>/hermes-webui`
- Upstream is `https://github.com/nesquena/hermes-webui` (NOT NousResearch)
- Custom commits are distinct and cherry-pickable

## One-Time Setup

```bash
cd ~/AppData/Local/hermes/valhalla
git remote add upstream https://github.com/nesquena/hermes-webui.git
git fetch upstream
```

## Recurring Update Workflow

```bash
# 1. Fetch latest upstream
git fetch upstream

# 2. Create clean branch from upstream/master
git checkout -b valhalla-update upstream/master

# 3. Cherry-pick your custom commits in order
# (List yours with: git log --oneline --author="<your-gh-user>")
git cherry-pick <commit-1> <commit-2> ...

# 4. Resolve conflicts if any
# Common conflict: api/routes.py (hub integration imports + /api/sessions endpoint)
# Strategy: Keep upstream structure, merge your hub logic into it

# 5. Verify
git log --oneline -5  # Should show: your commits → upstream HEAD

# 6. Force push to your fork
git push origin valhalla-update:master --force

# 7. Clean up
git checkout master
git reset --hard valhalla-update
git branch -D valhalla-update
```

## Automated Script

`update-valhalla.bat` in repo root automates steps 1–3. On conflict, it pauses for manual resolution.

## Hub Service Integration Conflicts (api/routes.py)

When rebasing, `api/routes.py` often conflicts because:
- Upstream moved/removed imports
- `/api/sessions` endpoint structure changed

**Resolution pattern:**
1. Take upstream's import block as base
2. Add your hub imports after agent_sessions imports:
   ```python
   from api.config import _hub_url_set, HUB_URL, HUB_WS_URL
   from api.hub_service import HubDB
   from api.hub_client import fetch_sessions_from_hub, fetch_stats_from_hub
   ```
3. In `/api/sessions` handler, insert your hub proxy logic between `diag.stage("all_sessions")` and `diag.stage("load_settings")`:
   - Parse `?hub=1` explicit flag
   - Check `_hub_url_set()` for config-enabled hub
   - Fetch from hub with pass-through query params
   - Merge hub sessions with local profile filtering
   - Preserve stale-stream reconciliation logic

## Valhalla Custom Commits to Preserve

| Commit | Purpose |
|--------|---------|
| `Valhalla fork: Windows launchers...` | run-valhalla.bat, create-shortcut.ps1, valhalla.ico, Hub Service auto-start in server.py |
| `Add Windows startup script...` | start-webui.bat for original hermes-webui |

## Related Files in Fork

- `run-valhalla.bat` — Launches Valhalla on port 8787
- `start-webui.bat` — Legacy launcher (port 8788)
- `create-shortcut.ps1` — Creates "Valhalla" Start Menu shortcut with custom icon
- `assets/valhalla.ico` — Multi-size icon (256→16) from neofetch-ai.png
- `Makefile` — `make shortcut` / `make shortcut-pin`
- `server.py` — Hub Service auto-start on port 8788 when `HERMES_WEBUI_HUB_URL` is localhost
- `api/hub_service.py` — HubDB with FTS5 search, REST endpoints at `/api/hub/*`
- `api/routes.py` — Hub routing with explicit `?hub=1` query param

## Common Pitfalls

| Issue | Fix |
|-------|-----|
| Upstream remote wrong (NousResearch) | `git remote set-url upstream https://github.com/nesquena/hermes-webui.git` |
| Rebase skips commits as "already applied" | Use cherry-pick from clean upstream branch instead |
| LF/CRLF warnings | Cosmetic — `.gitattributes` normalizes; ignore |
| Force push rejected | Ensure you're pushing to your fork, not upstream |
| Hub service won't start | Check `HERMES_WEBUI_HUB_URL=http://127.0.0.1:8788` in .env |