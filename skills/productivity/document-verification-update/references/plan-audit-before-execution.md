# Plan Audit Before Execution

A specialized sub-pattern of Document Verification & Update: auditing a multi-phase plan document against live system state **before** beginning to execute.

## When to use

The user says "double check everything one last time for accuracy and quality" or similar on a plan/strategy document. The plan makes claims about:

- File counts, sizes, or existence
- Numbers of sensitive data patterns to scrub
- Merge decisions between repositories
- Presence/absence of specific files
- Backup target readiness

## Workflow

### Phase 1: Audit plan claims against live data

Read the plan. Extract every verifiable quantitative claim. For each, run the live check:

| Plan claim | Live check |
|------------|------------|
| "132 hardcoded paths" | `grep -rn "~/AppData/Local/hermes\|~/agent-wiki" . --include="*.md" --include="*.py"... \| wc -l` then exclude plan file itself |
| "35 categories" | `find skills -mindepth 1 -maxdepth 1 -type d \| wc -l` |
| "16 missing DESCRIPTION.md" | `for d in skills/*/; do [ -f "$d/DESCRIPTION.md" ] \|\| echo "✗ $d"; done \| wc -l` |
| "agent-fleet file is newer" | `diff agent-fleet/X agent-store/scripts/X \| head -30` then compare byte counts |
| "OneDrive backup exists" | `ls ~/OneDrive/hermes-backup/identity/` |

**Exclude the plan file itself** from grep searches — the plan references its own estimates in prose.

### Phase 2: Cross-repo file comparison

When the plan says "File X from repo A should overwrite file Y from repo B":

1. **Check existence** in both repos
2. **Compare sizes** — `wc -c` each version. Bigger ≠ newer, but large deltas (20%+) are suspicious
3. **Run `diff`** — read the actual differences to determine which version is truly better
4. **Categorize each merge decision:**

| Decision | Criteria |
|----------|----------|
| ✅ Overwrite A→B | A is clearly newer (more features, bug fixes, better architecture) |
| ✅ Keep B (skip copy) | B is newer or A regresses features |
| 🔴 Plan says overwrite but A regresses | Flag — plan has wrong direction |
| ⚪ Same content | Either — no-op copy |

**Specific gotcha:** MCP server files often have different docstrings, import structures, and lifecycle management between repos. Don't assume "agent-fleet is always newer" — agent-store may have extracted/improved them after the split.

### Phase 3: PII/sensitive-data audit

When the plan makes claims about how many personal data patterns exist:

1. **Count by pattern** (not just total):

```bash
for pattern in "C:/Users/<user>" "~/agent-wiki" "[employer]" "[tailnet]"; do
    count=$(grep -rn "$pattern" . --include="*.md" --include="*.py"... 2>/dev/null | grep -v ".git/" | grep -v "__pycache__" | grep -v ".hermes/plans/" | wc -l)
    echo "$pattern: $count"
done
```

2. **Compare to plan's estimate** — plans often underestimate because:
   - They don't include hidden/test/meta files
   - They miss patterns not in the original scrub list (e.g. "[employer]" in skill examples)
   - They forget merged-in files from other repos

3. **Flag undercounts** — if actual count is significantly higher than plan estimate, the plan needs a pre-execution patch before Phase 0.

### Phase 4: Present findings by severity

Structure output as a concise severity table with counts:

```
## Audit Results: N Issues Found

### 🔴 Issue 1: [Title]
- **What:** [one line fact]
- **File(s):** [specific files/line numbers]
- **Impact:** [why it matters for execution]
- **Fix:** [specific action to update the plan]

### 🟡 Issue 2: [Title]
...

### 🟢 [No-action observation]
...
```

**Order:** 🔴 blocking issues first, then 🟡 non-blocking refinements, then 🟢 observations (no action needed). Each issue gets a clear "Fix:" line.

**Don't bury the lead:** If the plan's estimated PII count is off by 50+, say it as the first 🔴 issue. If the plan says overwrite when it should keep, that's 🔴.

### Phase 5: Update the plan before execution

For each 🔴 and 🟡 finding, write a targeted patch to the plan document. The user asked for "double check" — converting findings into plan patches closes the loop.

## Relationship to main skill

This pattern fits under Phase 2 (Run verification commands) + Phase 3 (Compare & flag) of the main `document-verification-update` SKILL.md, but adds:

- **Cross-repo file comparison** — the main skill assumes a single document; plans often reference external repos
- **PII counting** — specific audit pattern not covered by generic "verify claims" flow
- **Severity-classified findings table** — a proven output format (🔴🟡🟢) that was received without correction
- **Plan-as-claim-source** — the plan's OWN estimates become claims that need verification, not just the plan's claims about the world