## Pitfall: Context Compaction Eats Brain Dump Content

**The most dangerous failure mode for brain dumps:** if user brain dumps across multiple session continuations, the user message containing the dump content may be **permanently lost** — compacted into a summary that references the dump without preserving its content. `session_search` cannot recover it. The wiki never received it.

This happened on June 20, 2026 across the brain dump chain #45–#54: user brain dumped about zellij, the session ran through 10 continuations, and by closeout the zellij content existed only in a previous agent window's memory. Gone from every user message in every session. A raw dump page was never written.

**The fix: interleave raw saves.** Any brain dump that spans more than one user message or crosses a session window MUST persist raw content to `braindumps/` after EACH user message, not batched at the end. The `write_file` call costs ~30ms; losing a dump costs everything.

**Implementation:**
- After each user message containing brain dump content, immediately write `braindumps/YYYY-MM-DD-HHMMSS-raw-<slug>.md` with the verbatim content — before parsing, before categorizing, before anything else.
- If the dump was just a single thought ("brain dump: buy milk"): skip the interleave, the normal flow handles it.
- If the dump is multi-item or user adds items incrementally across turns: save raw after each turn.

**Recovery (when you arrive in a new session and the brain dump was already lost):** See `hermes-session-continuity` skill's `references/multi-session-brain-dump-chain.md` for the concrete recovery workflow — how to detect a lost dump chain, identify what was being brain-dumped, and report the gap to user.