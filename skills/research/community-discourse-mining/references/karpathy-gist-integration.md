# Karpathy LLM Wiki Gist — Community Comment Integration (2026-06-17)

## Source

https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f

## Extraction

Thirty comments extracted via Python regex from web_extract JSON output. Pattern:

```python
pattern = r'\*\*\[?([^\]]*)\]?\*\*\s+commented\s+\[([^\]]*)\]([^#]*?)(?=\*\*\[?[^\]]*\]?\*\*\s+commented|\Z)'
```

## Signal Categories Found

| Category | Commenter | Key Insight | Action Taken |
|----------|-----------|-------------|--------------|
| **Architectural principle** | vvvvvivekkk | "Markdown + Git is the only source of truth. All indices are derived." | Added `### Source of Truth` section to SCHEMA.md |
| **Implementation pattern** | watsonrm | "Grep for citation before writing → ingest becomes commutative" | Added citation-keyed dedup to Ingest Step 3 |
| **Implementation pattern** | watsonrm | "Partition writers by file + append-only → no locking" | Added `### Multi-Agent Operation` section |
| **Policy insight** | watsonrm | "Confidence tiers: high auto-applies, ambiguous flags for review" | Added to Convergent Update Policy |
| **Risk/guardrail** | Archimondstat | "Hallucination probability compounds toward 1 as notes grow" | Added hallucination compounding to lint + `needs-review` tag |

## Discarded Comments (with rationale)

- **Z-M-Huang, mikhashev, MuhammadSaqlainAslam, kytmanov (x2), Electro-resonance, theluk, nishchay7pixels, paulmchen (x2), skyllwt, Sistema2D, witwaycorp, theafh, hereisSwapnil, Clod, wiltodelta, gowtham0992, SinghAbhinav04, psinetron, deepak-bhardwaj-ps** — Product/project announcements with no transferable insight into the wiki pattern itself.
- **studebaker8** — Meta-complaint about self-promotion, not substantive.
- **lastforkbender** — Code dump without explanation.
- **pursultani** — Already ingested via user's paste in a prior session (convergent vs dialogic epistemology). Did not re-integrate.
- **lioragronov2203-stack** — Interesting (Logseq vs Obsidian granularity debate) but outside current schema scope. Flagged for future reference.

## Commit

`205a6ba` — feat(schema): integrate community comments from Karpathy gist
