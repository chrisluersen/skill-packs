# Memory Claim Verification

> **Class level:** Post-execution quality verification
> **Added from:** 2026-07-07 — Claude Skills pipeline ingestion session
> **Applies to:** Any session where multi-file reading produced synthesis claims stored to memory

## Why This Exists

After ingesting multiple source files (code, docs, config), the agent synthesizes
claims about them into memory: what functions exist, what files do, what the
pipeline looks like. These claims are **not automatically correct** — the synthesis
step can hallucinate function names, mischaracterize validation scope, or assert
format features that don't exist.

The only reliable correction mechanism is **cross-referencing every claim against
the actual source files.** This reference captures that pattern.

## The Pattern

### Step 1 — List Every Factual Claim Made

After storing a synthesis to memory, enumerate all specific claims:

| Claim type | Examples from 2026-07-07 |
|------------|--------------------------|
| **File contents** | `utils.py has parse_skill_md(), load_eval_set(), load_skill_list()` |
| **Behavioral descriptions** | `quick_validate.py validates SKILL.md structure and links` |
| **Numerical facts** | `viewer.html is 1,461 lines`, `17 files total` |
| **Tool/feature existence** | `aggregate_benchmark.py outputs benchmark.json + benchmark.md` |

Don't trust the synthesis. Write down the claims explicitly.

### Step 2 — Verify Each Claim Against Source Truth

For each claim class, use the appropriate verification tool:

**Function/method existence** — `search_files` with exact function names:
```
search_files(path="<dir>", pattern="def load_eval_set")
search_files(path="<dir>", pattern="def load_skill_list")
search_files(path="<dir>", pattern="parse_skill_md")
```
Zero results = hallucinated claim. Fix memory immediately.

**Behavioral descriptions** — `read_file` the relevant section:
- Search for the behavior's keywords in the file
- Read the function body or validation logic
- Compare what it *actually does* vs what *memory claims* it does

Example from 2026-07-07: `quick_validate.py` was claimed to validate "links."
Reality: validates `name` (kebab-case), `description` (1024-char limit),
frontmatter YAML, allowed properties, no angle brackets, compatibility length.
No link checking at all.

**Numerical counts** — `terminal` with shell tools:
```
find "<dir>" -type f | wc -l
wc -l <file>
wc -c <file>
find "<dir>" -type f -printf '%s\t%p\n' | sort -t/ -k5
```

**Tool/feature existence** — Search for specific output patterns:
```
search_files(path="<file>", pattern="benchmark\.md")
search_files(path="<file>", pattern="benchmark\.json")
```
If the script has code that references the output format, read the relevant
lines to confirm.

### Step 3 — Pattern-Match the Error

When a memory claim is wrong, identify the *kind* of hallucination:

| Pattern | Signal | Root cause | Fix |
|---------|--------|------------|-----|
| **Function does not exist** | `def load_eval_set` → 0 results | Cross-project contamination — function exists in OTHER codebase | Remove from memory, add note "utils.py contains only parse_skill_md()" |
| **Wrong validation scope** | Memory says "validates links" but code checks frontmatter | Summarization drift — agent inferred broader scope than actual | Rewrite to match actual behavior exactly |
| **Wrong file count** | Claimed N files, reality N+1 or N-1 | Missed files in subdirectories (agents/, eval-viewer/) | Use recursive `find`, not directory listing |
| **Wrong line count** | Claimed M lines, reality M±delta | Estimated from memory, never counted | Always count with `wc -l` for specific claims |

### Step 4 — Fix the Memory Entry

After verifying, immediately correct the memory:

```
memory(operations=[
    {'action': 'replace',
     'old_text': '<incorrect entry substring>',
     'content': '<corrected entry>'},
], target='memory')
```

The correction should:
- Remove the hallucinated claim entirely
- Add the correct fact (e.g. "utils.py has parse_skill_md only")
- Keep any claims that passed verification

### Step 5 — Report the Audit

When the user asks to double-check, deliver a clean summary:

```
**Errors caught (N)** — [brief list of what was wrong]
**Verified accurate (M)** — [confirmation of passing claims]
**One memory correction applied** — [what changed]
```

### Verification Checklist

- [ ] Function existence claims checked via `search_files(pattern="def <name>")`
- [ ] Behavioral claims checked via `read_file` of the relevant code section
- [ ] Numerical claims (file counts, line counts, byte counts) checked via `wc`/`find`
- [ ] Tool/feature output claims checked via `search_files` for output patterns
- [ ] Memory corrected for every wrong claim
- [ ] Report delivered with both errors caught AND verified-passing claims

## Common Pitfalls

- **Only checking what you're unsure of.** The claims that pass synthesis feel
  correct — that's exactly why they're dangerous. Check every claim, not just
  the ones that triggered doubt during ingestion.
- **Skipping numerical verification.** "17 files" felt right because you saw 17
  files — but that's a count from one moment. Re-count with `find | wc -l`
  before reporting it as verified.
- **Trusting memory after verification.** The verification pass confirms the
  corrected memory is accurate *right now*. If source files change later,
  memory becomes stale again. There's no auto-update — re-verify when files
  might have changed.
- **Claiming verification by inference.** "If `aggregate_benchmark.py` has
  `benchmark.md` somewhere in its code, then it definitely outputs one" —
  read the actual output-writing code, not just a reference to the filename.
- **Missed behavioral nuance.** A function *exists* but its behavior is subtly
  different from what memory claims. "Validates description length" is correct
  but incomplete if the validator also checks frontmatter, naming convention,
  and YAML structure. Always read enough of the function body to characterize
  scope correctly.

## Relationship to session-closeout-self-review.md

| Dimension | session-closeout-self-review | memory-claim-verification |
|-----------|------------------------------|---------------------------|
| When | After modifying files | After reading files and storing claims |
| What you verified | Files you wrote/patched | Claims in memory about what you read |
| Defect type | Stale claims, leftover cruft, contradictions | Hallucinated functions, wrong scope, miscounts |
| Fix target | The modified files | The memory entries |
| Trigger | Session closeout / phase completion | User request or self-check after synthesis |
