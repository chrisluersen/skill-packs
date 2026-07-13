---
name: obsidian
description: Read, search, create, and edit notes in the Obsidian vault.
platforms: [linux, macos, windows]
---

# Obsidian Vault

Use this skill for filesystem-first Obsidian vault work: reading notes, listing notes, searching note files, creating notes, appending content, and adding wikilinks.

## Vault path

Use a known or resolved vault path before calling file tools.

The documented vault-path convention is the `OBSIDIAN_VAULT_PATH` environment variable, for example from `${HERMES_HOME:-~/.hermes}/.env`. If it is unset, check memory for the user's vault path — this is the canonical source since the user may change it. If neither is available, try `~/OneDrive/Vault/` (common OneDrive-synced vault), then fall back to `~/Documents/Obsidian Vault`.

**Protip:** If Obsidian itself won't load (stuck on "Loading cache..."), the issue may be a wrong vault registered in `%APPDATA%\Obsidian\obsidian.json` — see `references/obsidian-app-troubleshooting.md` (section "Wrong vault registered in obsidian.json").

File tools do not expand shell variables. Do not pass paths containing `$OBSIDIAN_VAULT_PATH` to `read_file`, `write_file`, `patch`, or `search_files`; resolve the vault path first and pass a concrete absolute path. Vault paths may contain spaces, which is another reason to prefer file tools over shell commands.

If the vault path is unknown, `terminal` is acceptable for resolving `OBSIDIAN_VAULT_PATH` or checking whether the fallback path exists. Once the path is known, switch back to file tools.

## Read a note

Use `read_file` with the resolved absolute path to the note. Prefer this over `cat` because it provides line numbers and pagination.

## List notes

Use `search_files` with `target: "files"` and the resolved vault path. Prefer this over `find` or `ls`.

- To list all markdown notes, use `pattern: "*.md"` under the vault path.
- To list a subfolder, search under that subfolder's absolute path.

## Search

Use `search_files` for both filename and content searches. Prefer this over `grep`, `find`, or `ls`.

- For filenames, use `search_files` with `target: "files"` and a filename `pattern`.
- For note contents, use `search_files` with `target: "content"`, the content regex as `pattern`, and `file_glob: "*.md"` when you want to restrict matches to markdown notes.

## Create a note

Use `write_file` with the resolved absolute path and the full markdown content. Prefer this over shell heredocs or `echo` because it avoids shell quoting issues and returns structured results.

## Append to a note

Prefer a native file-tool workflow when it is not awkward:

- Read the target note with `read_file`.
- Use `patch` for an anchored append when there is stable context, such as adding a section after an existing heading or appending before a known trailing block.
- Use `write_file` when rewriting the whole note is clearer than constructing a fragile patch.

For an anchored append with `patch`, replace the anchor with the anchor plus the new content.

For a simple append with no stable context, `terminal` is acceptable if it is the clearest safe option.

## Targeted edits

Use `patch` for focused note changes when the current content gives you stable context. Prefer this over shell text rewriting.

## Create a reference guide

When creating a reference/guide document (research-backed, instructional):

1. **Research thoroughly** — check multiple sources: social media, GitHub repos (CI configs, issues, package manifests), official docs, package registries
2. **Structure the document** — start with a short answer/abstract, then detailed sections, use tables for comparisons, end with actionable takeaways
3. **Use inline citations** — place source links directly beneath each claim or quote, not in a generic footer
4. **Link related guides** — use `[[File Name]]` wikilinks to connect this guide to others in the vault on related topics
5. **Place in vault** — write to the vault path resolved from memory or `OBSIDIAN_VAULT_PATH`. The vault path is user-specific — check memory for it rather than relying on the env-var fallback alone.

## Inline citations for quotes

When a note or guide contains quotes from external sources (social media posts, interviews, documentation), add the source link on the line below the quote:

```
> *"Quote text here"*
> — [Source Name, Date](https://link-to-source.com)
```

Do not put all sources in a footer at the bottom — put each source next to its claim. This keeps attribution verifiable at a glance.

## Wikilinks

Obsidian links notes with `[[Note Name]]` syntax. When creating notes, use these to link related content.

## Proactive artifact saving

When you produce informative, high-token-output content that would be useful as a durable reference (filesystem layouts, research summaries, architecture decisions, how-to guides, comparison tables), **save it automatically** to the vault's `Artifacts/` directory — do not wait to be asked. The user has explicitly requested this.

- **Target path:** `<vault_path>/Artifacts/<Descriptive Name>.md`
- **Trigger:** Any response where you produce a structured reference doc, comprehensive comparison, multi-section guide, or similar self-contained informative artifact that took meaningful effort to compose. The user's exact framing: *"when you make informative output that is useful, takes a lot of tokens to create, and is relevant to me."*
- **Do NOT save:** transient answers, single-paragraph explanations, or content that would be stale in a week.
- **Tone:** Write the artifact clean and standalone — the user may read it outside the conversation (in Obsidian, a markdown viewer, etc.). Use headings, tables, and inline source citations.
- **Path convention:** Resolve the vault path from memory (the canonical source). The `Artifacts/` subdirectory should exist already — create it with `mkdir -p` if it doesn't. Memory records the user's current vault path and preference for this behavior.

## Second Brain Setup

This vault currently has the foundation (Obsidian installed, wiki inside it, core plugins enabled) but the full "second brain" layer is not configured. See `references/obsidian-second-brain-setup-checklist.md` for the current state and what's missing:

- Community plugins (Dataview, Templater, Kanban, Git)
- Directory structure (`_templates/`, `inbox/`, `Artifacts/`)
- `OBSIDIAN_VAULT_PATH` environment variable
- Theme
- `Captures/` cleanup

## Troubleshooting the Obsidian app itself

If Obsidian fails to render (blank dark screen, no UI), see `references/obsidian-app-troubleshooting.md` for GPU acceleration fixes, cache-clearing steps, and community plugin crash recovery. The vault file operations in this skill assume Obsidian itself is running — reach for the reference when it isn't.
