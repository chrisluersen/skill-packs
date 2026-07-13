# Cross-Document Consistency Audit (After Bulk Edits)

After performing bulk renames, section insertions, or structural changes across a multi-section document, run this systematic consistency check to catch issues the patch tool can miss.

## When to Use

- After a `replace_all=true` rename (e.g., "7-Iris"→"Iris-7" across 37 occurrences)
- After inserting/removing sections (harmonia re-added, kalliope→fortuna rename)
- After multiple sequential patches to the same file
- Before declaring a large document audit complete

## ✅ Audit Checklist

### 1. Section Headers vs. Content

Check that every section header's count/claim matches its content:

| What to check | Example from session | How |
|---------------|---------------------|-----|
| Header count vs table rows | `### Already Removed (1)` had 2 rows | Read the header number, count the rows below it |
| Table title vs column values | "Removed (2)" but only 2 agents listed | Read the title, verify row count matches |
| Done signals vs reality | "Phase 5: Already verified" → wasn't | Check if the done signal's implied state is actually true |

### 2. Cross-Reference Consistency (After Renames)

After a bulk rename, verify every occurrence is correct IN CONTEXT:

1. **Do the rename** — `replace_all=True` for mechanical changes
2. **Check ambiguous context** — Some occurrences may need DIFFERENT text than the mechanical replacement. Example: When renaming "7-Iris"→"Iris-7", the removed-table entry "7-Iris IS the API" needed disambiguation to "Iris-7 (old) | API integration | Never fired." because "Iris-7" now refers to the orchestrator, not the removed agent.
3. **Search for remaining old name** — Verify 0 hits (except intentional historical references)
4. **Verify by category** — Run through each section type that references the renamed entity:

**Category checklist for renames:**
- [ ] Architecture diagrams / ASCII art — text labels inside boxes
- [ ] Decision trees — dispatch targets in table cells
- [ ] Harness tables / profile tables — agent name entries
- [ ] Flow patterns — sequence diagrams
- [ ] Fleet manifests — agent listings, removed tables
- [ ] Success criteria — target counts, agent references
- [ ] Phase checkboxes — especially removal lists and verify commands
- [ ] Token budgets — agent names in estimate rows
- [ ] Dependency chains — agent references in blocking/routing descriptions

### 3. Truncation Detection (After Sequential Patches)

When you apply multiple patches to the same file — especially near the end of lines — check for truncated content:

```
# BAD — content was cut off after a prior patch
- [ ] 🟢 **Astraea-5** — [ROLE]: Task decomposer.
```

**Detection method:** Look for lines that end abruptly with just a `[ROLE]:` or `[BEHAVIOR]:` fragment, or for bullet points that clearly had more content implied (e.g., an example usage without a verify command). Cross-reference against the original source (backup file, plan template, or adjacent similar entries).

**Prevention:** After every batch of patches near a section boundary, read the full section and confirm no lines got truncated. The patch tool merges adjacent edits — overlapping context can swallow content.

### 4. Checkbox / Marker State Audit

After completing phases or tasks, verify every status marker reflects current reality:

```
# BAD — says "Phase 0: Read State" but all checkboxes are [ ]
# BAD — says "9 agents" but we have 10
# BAD — says "Fleet runs X Hermes agents" after count changed
```

**Checklist:**
- [ ] Phase headings checked against actual completion
- [ ] Done signals updated (e.g., "10 agents" after Harmonia revived)
- [ ] Agent counts correct in ALL sections (architecture, manifest, success criteria, phase descriptions, fallback notes)
- [ ] Batch/scheduling sections reflect what's actually remaining
- [ ] "Fleet runs X agents" text updated everywhere

### 5. Ambiguity Scan

After a rename that repurposes an old name, check every occurrence for ambiguity:

| Pattern | Issue | Fix |
|---------|-------|-----|
| Old name = new name | Two different things now share a name | Disambiguate one with "(old)" or a clarifying note |
| Removal reason mentions the agent by its new shared name | "Domain covered by Iris-7" when old Iris-7 was removed | Context makes sense (Iris-7 orchestrator covers that domain) — verify it reads correctly |
| Merged agents in history | "Thalia merged into Iris-7" | Fine — the active agent absorbed the merged one |

## Common Pitfalls

- **Headers lie:** "Already Removed (1)" doesn't mean there's 1 row — count the actual rows. Headers often get updated independently from their tables.
- **Patch truncation is silent:** The patch tool doesn't warn you it cut off content. You must re-read and verify.
- **Checkbox rust:** Done markers don't automatically update when the state changes. "9 agents" from Phase 1 stays "9 agents" even after Harmonia was revived — you must re-check.
- **Ambiguity from reuse:** When you rename the orchestrator to match a removed agent's name (7-Iris→Iris-7, where Iris-7 was a dead API agent), every reference needs context-checking. The removed table says "Iris-7 | API integration" — is that the old one or the new one? Tag the old one as "(old)".
- **Counts propagate:** An agent count change in the manifest must be updated in: architecture header, decision tree notes, fleet manifest total, success criteria, phase done-signals, batch scheduling, fallback descriptions, and token budget introduction. Search for every occurrence of the old number.
