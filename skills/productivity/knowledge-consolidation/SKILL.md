---
name: knowledge-consolidation
description: Merge multiple fragmented knowledge files (markdown, HTML, text) into one comprehensive, self-contained document. Plan-first, execute-second methodology for vault/folder decluttering.
category: productivity
created_from_user_sessions: true
---

# Knowledge Consolidation Skill

Merge many fragmented files on the same topic into a single master document, then clean up the sources.

## Trigger

User says any of:
- "Merge these files into one"
- "Consolidate [folder] into a single document"
- "Take the content from X, Y, Z and put it all in one [file]"
- "Clean up this folder — keep only the consolidated file"
- Points at a directory with 5+ files on the same topic and says "make this into one thing"

## Workflow

### Phase 1: Inventory

1. **List all files** in the target directory:
   ```
   search_files(path="<dir>", pattern="*", target="files")
   ```
   or
   ```
   ls -la "<dir>"
   ```

2. **Read every source file** — use `read_file` for each. Do NOT ask the user what's in them; you're doing discovery.

3. **Catalog content by topic** — mentally (or in a working file) note what each source covers:
   - Installation
   - Configuration
   - Modes / features
   - Commands / reference
   - Philosophy / opinions
   - Ecosystem / related tools

4. **Read the target** (the document being consolidated into) completely using `read_file` with `limit`/`offset` pagination if it's large.

5. **Identify gaps** — for each topic area, is the content already in the target? If yes, skip. If no, note it for the plan.

### Phase 2: Plan

6. **Write a structured plan** listing:
   - Each new section/hunk to add
   - Which source file it comes from
   - Where it goes in the target (after which existing section)
   - Why it adds value (not already covered)

7. **Verify the plan** — re-check source files for anything you might have overlooked. Re-check the target to avoid duplication.

### Phase 3: Execute

8. **Patch new content in** — use `patch` (replace mode) with enough surrounding context for uniqueness. Insert new sections with a clear HTML/markdown comment marker so the boundary is obvious.

9. **Update navigation** — after inserting new sections, update:
   - Navbar / top nav links
   - Sidebar TOC
   - Mobile TOC panel
   - Section numbers or labels

10. **Add utility JS/CSS** if needed — e.g. `expandAllAccordionsIn(id)` functions for accordion sections.

11. **Verify each patch succeeded** — check `success: true` and `diff` in the result. If failed (non-unique match), re-read context and add more surrounding lines.

### Phase 4: Cleanup

12. **After verifying** the consolidated document looks good, delete the source files:
    ```
    rm "<dir>/file1.md" "<dir>/file2.html" ...
    ```

13. **One last read** of the final document to confirm it's clean.

## Pitfalls

- **NEVER feed a paginated `read_file` result into `write_file`** — `read_file` returns only the first 500 lines by default. Calling `write_file` with that truncated content OVERWRITES the entire file, silently dropping everything after line 500. Always check `total_lines` vs actual content length before overwriting. Use the terminal append pattern (`cat part2 >> main`) instead for large file modifications — see `html-application-building` skill's `references/large-file-recovery.md`.

- **Patches fail on non-unique strings** — always include surrounding context (the div/section wrapper, surrounding tags, or adjacent content) to guarantee uniqueness. If a patch fails, read the area around the intended insertion point and include more context in `old_string`.
- **Large files need paginated reading** — `read_file` returns partial content over ~100K chars. Use `offset`/`limit` to read sections, or use the `execute_code` tool with `from hermes_tools import read_file` for programmatic reads.
- **PDFs are binary** — `read_file` can handle some PDFs (Auto-extracted to readable text) but compressed PDFs (FlateDecode) may need `marker-pdf` or `pymupdf` from the `ocr-and-documents` skill. Check the `ocr-and-documents` skill for extraction when PDFs are present.
- **Search returns phantom files** — `search_files(target="files")` with a broad pattern can return matches from outside the target directory (e.g. `.stfolder`, temp caches). Always `ls -la` the exact directory to get the real file list.
- **Nav/TOC updates are easy to forget** — every new section needs a link in both desktop sidebar and mobile panel. Add them immediately after the section patch, not as a separate later step.
- **Don't ask the user to re-read what's already in the files** — you read them, you know what's there. Present the plan, don't make them confirm file contents.
- **Windows paths with spaces/special chars** — use MSYS2 paths (`/c/Users/...`) or escaped Windows paths for `terminal` commands. The `read_file` and `patch` tools handle native `C:\...` paths fine.
- **After large file patches, the local paginated cache may be stale** — the tool warns about this. Re-read a fresh section around the patched area to verify.

## User Preferences (user)

- Prefers **one comprehensive file** over many fragmented ones — less vault clutter, easier to find
- Values **plan-first, execute-second** — make the plan explicit before touching files
- **Does not want to be asked** to confirm what's already in the files (you read them already)
- Uses Obsidian vault as knowledge hub: `~/AppData/Local/hermes\\OneDrive\\Vault\\`
- Report output is **HTML** with a polished interactive design. See companion skills:\n  - `html-doc-ux` — surgically add UX enhancements to the already-consolidated HTML document (back-to-top, scroll indicators, clipboard fallback, mobile touch targets, stagger animations, theme toggle, reading progress)\n  - `html-application-building` — build polished HTML SPAs from scratch (4-pass iteration, fusion design system, all UX patterns)\n  This skill handles content merging; `html-doc-ux` handles post-merge UX enhancement; `html-application-building` handles scratch-built apps.

## Related Skills

- `html-doc-ux` — **post-consolidation companion skill** for surgically adding UX enhancements (back-to-top, scroll indicators, clipboard fallback, mobile touch targets, stagger animations, theme toggle, reading progress) to the already-merged HTML document. Use after consolidation is complete and the user wants a more polished feel.
- `html-application-building` — **companion skill** for turning consolidated content into a polished HTML single-page app (4-pass design methodology, fusion design system, all UX patterns). Use when the output format is HTML and you're building from scratch rather than enhancing an existing doc.
- `architecture-diagram` — dark-themed SVG diagrams for the consolidated document
- `popular-web-designs` — 54 design system templates for design inspiration (used by `html-application-building`)

## Verification

After consolidating:
- [ ] All source files read and cataloged
- [ ] Plan written with what goes where
- [ ] Each patch succeeded
- [ ] Navigation/TOC updated for new sections
- [ ] Source files deleted after verification
- [ ] Final document reads cleanly when opened in browser