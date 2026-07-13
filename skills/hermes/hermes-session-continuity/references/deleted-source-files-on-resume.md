# Deleted Source Files on Resume

## The Pattern

User says "continue where you left off." Session search finds a prior session whose last user message was a task instruction like *"review X, Y, Z and merge relevant info into A."* You attempt to read X, Y, and Z — but they no longer exist on disk.

## Root Cause

Between sessions (or across compaction boundaries) the source files were:
- Deleted intentionally (user cleaned up)
- Moved to a different directory (restructured vault)
- Renamed (naming convention changed)
- Already absorbed into the target file

None of these are detectable from the session transcript alone.

## Workflow

1. **Confirm the previous session's intent** — Read the last user message and any assistant response that confirmed the task:
   ```python
   session_search(session_id="<id>")
   ```

2. **Attempt to read the referenced files** — at the *exact* paths mentioned in the session:
   ```python
   search_files(target="files", pattern="<exact filename>", path="<exact path from session>")
   ```

3. **If not found, broaden the search** — the files may have moved:
   ```python
   search_files(target="files", pattern="<filename glob>", path="C:\\Users\\<user>")
   ```

4. **If still not found, check for deleted directories** — the containing folder may itself be gone:
   ```
   ls -la "<parent directory from session>"
   ```
   If the parent directory doesn't exist, the entire file tree was restructured.

5. **Report the gap** — tell the user:
   - What task was pending from the prior session
   - Which files were referenced
   - Whether they're fully gone, moved, or at a different path
   - Ask for direction: "Files are gone — do you want me to rebuild, or pivot to something else?"

## Example (from this session)

```
Prior session task: "Review hermes_part2.html, when_to_use.csv, herm_vs_tmux.csv
and merge relevant info into hermes-agent-report.html"

Reality on resume: Directory ~/AppData/Local/hermes\OneDrive\Vault\AI Stack\ does not exist.
All 4 files are gone — likely deleted in a prior session.
```

## Signals That Trigger This

- `read_file` returns "File not found" for a path from a prior session
- `search_files` returns empty on the exact path
- The containing directory from the prior session doesn't exist
- File size was notably large (~130KB) but now returns 0

## Pitfalls

| Issue | Fix |
|-------|-----|
| Searching home directory times out (too many files) | Narrow with glob and path restriction |
| Files were absorbed into a larger document | Check if the target document itself was the absorption target and now contains the merged content |
| Files existed in one session but not the next | They were deleted between sessions — this is expected and common. Don't assume the session data is wrong. |
| The user may have told a *different* agent/session to delete them | This is common with multi-session workflows. The delete instruction lived in a session you haven't found yet. |
