# Prompt Routing Rules — Cascade

Current `PROMPT_ROUTE_RULES` as defined in `cascade.py`. Last verified: 2026-07-04.

## Rule table

| Label | Keywords (any match triggers) | Negative (cancel match) | Model | Tier |
|-------|-------------------------------|-------------------------|-------|------|
| code | code, python, debug, function , class , import , ```, fix, refactor, test, pytest, unittest, exception, traceback | — | deepseek/deepseek-v4-flash | 1 |
| creative | creative, write, story, essay, blog, poem, script | — | openai/gpt-4o | 1 |
| fast | fast, simple, quick, brief, one sentence, yes or no, what is, who is, define, spell, explain simply, tldr | translate to python, convert to python, migrate to python | deepseek/deepseek-v4-flash | 1 |
| complex | architect, design, implement, refactor, algorithm, optimize, research, step by step, walk me through, plan, review, compare, analyze | — | anthropic/claude-sonnet-5 | 2 |
| long_context | context, long, document, migrate, convert, summarize | summarize in one sentence, tldr | minimax-m3 | 1 |

## Behavior

- **Case-insensitive substring match** against the last user message content
- **First rule wins** — rules evaluated in order above
- **Model pinned before provider selection** — cascade cannot override
- **Greetings & unmatched** → normal cost-first cascade (Tier 0→3)

## Accuracy notes

- Negative lists prevent "summarize in one sentence" from triggering long-context
- Tool-aware routing skips free-tier models when tools present
- Length-aware routing skips free-tier for prompts >2K estimated tokens
- Generic greetings removed from routing (were causing unnecessary model-pinning)

## Change procedure

1. Edit `PROMPT_ROUTE_RULES` in `cascade.py`
2. Update this file
3. Restart cascade (kill all processes, clear state, restart)
4. Run `scripts/validate-prompt-routing.sh` to verify