---
name: npm-workspace-maintenance
description: "Fix npm vulnerabilities, broken lockfiles, and dependency issues in workspace monorepos. Covers the audit-fix crash workaround, override-based pinning, workspace-scoped dependency bumps, and clean-reinstall recovery — for any npm workspaces monorepo."
version: 1.0.0
author: agent
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [npm, node, security, audit, dependencies, monorepo, workspaces]
    related_skills: [hermes-agent]
created_from_user_sessions: true
---

# npm Workspace Maintenance

Resolve npm dependency vulnerabilities and lockfile issues in a workspace monorepo (root `package.json` with `"workspaces": [...]`).

## When to use this skill

- User runs `npm audit` and sees workspace-specific vulnerabilities
- User runs `hermes update` and sees npm vulnerability warnings
- `npm audit fix` crashes with `Cannot read properties of null (reading 'edgesOut')` or `Cannot read properties of null (reading 'location')`
- A `npm dedupe` fails with ERESOLVE peer dependency conflicts in one workspace
- Lockfile is stale — entries point to versions not actually installed on disk

## Workflow

### 1. Identify which workspaces are affected

```bash
# Root-level audit
npm audit

# Per-workspace audit
npm audit --workspace web
npm audit --workspace ui-tui
npm audit --workspace apps/desktop
```

Common pattern: the same package (e.g. `esbuild`, `lodash`, `cross-spawn`) is vulnerable across multiple workspaces at different nesting depths.

### 2. Choose fix approach

There are two strategies. Use whichever fits the dependency's role:

| Strategy | When | How |
|----------|------|-----|
| **Root override** | The vulnerable package is a transitive dep (not in any workspace's `package.json`) — e.g. esbuild pulled by vite | Add to `overrides` in root `package.json` |
| **Direct version bump** | The vulnerable package is a direct dep in a workspace's `package.json` | Bump the version range in that workspace's `package.json` |

#### Root override

```json
// package.json (root)
{
  "overrides": {
    "lodash": "4.18.1",
    "esbuild": "0.28.1"
  }
}
```

This overrides **every occurrence** of the named package across all workspaces and nesting levels. It's the right fix for transitive deps that aren't listed in any workspace's own `package.json`.

#### Direct version bump

```json
// ui-tui/package.json
{
  "devDependencies": {
    "esbuild": "~0.28.0"   // was "~0.27.0"
  }
}
```

### 3. Apply the fix

```bash
# Apply overrides + bumps
npm install
```

**Pitfall:** On npm 11 (and some older versions), `npm audit fix` crashes on workspace monorepos with:
```
npm error TypeError: Cannot read properties of null (reading 'edgesOut')
```
or:
```
npm error TypeError: Cannot read properties of null (reading 'location')
```

**Do not rely on `npm audit fix` for workspaces.** It's buggy on npm 11. Instead:
1. Edit `package.json` files directly (overrides + version bumps)
2. Run `npm install` to apply changes
3. If the lockfile is stale or corrupt, do a **clean reinstall**

### 4. Clean reinstall (when lockfile is stale)

When `node_modules` and `package-lock.json` get out of sync (e.g. npm removed old esbuild but lockfile still records it):

```bash
rm -rf node_modules package-lock.json
npm install
```

**Warning:** This runs npm install from scratch. It may clear peer dep warnings or install slightly different versions. Always re-run the audit after.

### 5. Verify

```bash
# Full audit
npm audit

# Per-workspace confirmation
npm audit --workspace web
npm audit --workspace ui-tui
```

## Pitfalls

- **npm 11 audit fix is broken on workspaces.** Never assume `npm audit fix` will work — it hits `edgesOut` / `location` null-reference errors. Use the manual approach above.
- **Overrides apply everywhere.** `"esbuild": "0.28.1"` at root overrides esbuild for ALL workspaces, not just one. If a workspace genuinely needs a different version, that workspace gets its own copy anyway (nested in `workspace/node_modules/`).
- **Lockfile vs filesystem divergence.** `npm audit` reads the lockfile, not the disk. If you deleted a `node_modules/` directory but the lockfile still has the old version, the audit will still flag it. Fix: clean reinstall.
- **npm dedupe often fails on monorepos** with ERESOLVE peer dep conflicts from unrelated workspaces. Don't use it as a primary repair tool.

## Verification

```bash
# Check actual installed versions
node -e "
const lock = require('./package-lock.json');
const pkgs = Object.keys(lock.packages).filter(k => k.endsWith('PACKAGE_NAME'));
pkgs.forEach(k => console.log(k, '->', lock.packages[k].version));
"
```
