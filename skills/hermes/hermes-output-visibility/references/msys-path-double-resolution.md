# MSYS Path Double-Resolution on Windows

## The Bug

When using MSYS-style paths (`~/AppData/Local/hermes/...`) with Hermes file tools
(patch, write_file), the workspace prefix `C:\` gets prepended to produce
`C:\c\Users\chris\...` — a path that doesn't exist.

**Example failure:**
```
/patch on ~/AppData/Local/hermes/AppData/Local/hermes/skills/.../SKILL.md
→ Failed to read file:C:\c\Users\chris\AppData\Local\hermes\skills\...\SKILL.md
```

The tool exits with error, the file is **not modified**, and the file-mutation
verifier flags it at turn-end.

## Root Cause

Hermes runs inside git-bash/MSYS on this machine. MSYS translates `/c/...`
to `C:\...` at the shell layer. But the **Hermes workspace prefix** is
`~/AppData/Local/hermes` — when it concatenates the workspace to the relative path
derived from the MSYS absolute path, it produces `C:\c\...`.

This only affects the `patch` and `write_file` tools — `read_file` and
`search_files` handle the path differently and don't double-resolve.

## How to Avoid

Always use native Windows paths with file tools on this host:

| Right | Wrong |
|-------|-------|
| `~/AppData/Local/hermes\...` | `~/AppData/Local/hermes/...` |
| `~/AppData/Local/hermes/...` (forward slashes work) | `~/AppData/Local/hermes/...` |

## How to Detect Mid-Conversation

If the file-mutation verifier fires and the flagged path contains
`C:\c\` or a doubled drive letter, this is the bug. Re-run the
operation with a native `C:\Users\...` path.

## How to Confirm the Fix

```bash
# After retrying with correct path, check the file was actually modified:
head -5 "~/AppData/Local/hermes\AppData\Local\hermes\skills\hermes\hermes-output-visibility\references\msys-path-double-resolution.md"
```
