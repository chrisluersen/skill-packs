# Hermes Skill Packs

**115 reusable skills** for [Hermes Agent](https://hermes-agent.nousresearch.com) — AI agent workflows, code, research, creative tools, productivity, devops, and more. Installed in one command via `hermes skills tap`.

[![Skills](https://img.shields.io/badge/skills-115-blue)](https://github.com/chrisluersen/skill-packs)
[![Categories](https://img.shields.io/badge/categories-19-green)](https://github.com/chrisluersen/skill-packs)
[![License](https://img.shields.io/badge/license-MIT-yellow)](LICENSE)
[![Generated](https://img.shields.io/badge/generated-2026--07--13-lightgrey)](catalog.json)

---

## Quickstart

```bash
# Add this repository as a skill source
hermes skills tap add chrisluersen/skill-packs

# Search available skills
hermes skills search <query>

# Install a skill
hermes skills install chrisluersen/skill-packs/<skill-name>
```

**Example:** `hermes skills install chrisluersen/skill-packs/web-research-synthesis`

> **New to skills?** A skill is a SKILL.md file with structured instructions, examples, and pitfalls — loaded into your agent's context on command. See the [Hermes skills docs](https://hermes-agent.nousresearch.com/docs).

---

## Featured Picks

| Skill | What it does |
|-------|-------------|
| [`web-research-synthesis`](skills/research/web-research-synthesis/SKILL.md) | Open-ended research via web search, with source handling and multi-perspective synthesis |
| [`ai-terminal-stack`](skills/software-development/ai-terminal-stack/SKILL.md) | Plan and configure a high-performance AI terminal stack: zellij, neovim, Tmux, WezTerm |
| [`research-paper-writing`](skills/research/research-paper-writing/SKILL.md) | Write ML papers for NeurIPS/ICML/ICLR: design → submit |
| [`multi-agent-orchestration-design`](skills/hermes/multi-agent-orchestration-design/SKILL.md) | Design optimal multi-agent fleet architectures for your use case |
| [`systematic-debugging`](skills/software-development/systematic-debugging/SKILL.md) | 4-phase root cause debugging — understand bugs before fixing |
| [`comfyui`](skills/creative/comfyui/SKILL.md) | Generate images, video, and audio with ComfyUI — install, manage nodes and models |
| [`skill-maintenance`](skills/hermes/skill-maintenance/SKILL.md) | Keep your skills lean and correct over time — bloat audits, consolidation |
| [`humanizer`](skills/creative/humanizer/SKILL.md) | Strip AI-isms and add real voice to your writing |

---

## Skills by Category

### autonomous-ai-agents *(9 skills)*
Coding agent delegation — Claude Code, Codex, OpenCode. Hermes setup, remote access, runtime comparison, tool diagnostics, and delegation boundaries.

| Skill | Version | Description |
|-------|---------|-------------|
| [`claude-code`](skills/autonomous-ai-agents/claude-code/SKILL.md) | 2.2.0 | Delegate coding to Claude Code CLI (features, PRs). |
| [`codex`](skills/autonomous-ai-agents/codex/SKILL.md) | 1.0.0 | Delegate coding to OpenAI Codex CLI. |
| [`delegation-boundaries`](skills/autonomous-ai-agents/delegation-boundaries/SKILL.md) | 0.0.0 | Judgment framework for delegating to subagents — cost model, failure modes, recovery. |
| [`hermes-agent`](skills/autonomous-ai-agents/hermes-agent/SKILL.md) | 2.1.0 | Configure, extend, or contribute to Hermes Agent. |
| [`hermes-browser-interfaces`](skills/autonomous-ai-agents/hermes-browser-interfaces/SKILL.md) | 1.1.0 | Set up browser UIs for Hermes — dashboard, web interface. |
| [`hermes-remote-access`](skills/autonomous-ai-agents/hermes-remote-access/SKILL.md) | 1.0.0 | Remote and mobile access via Gateway API Server, Tailscale. |
| [`hermes-runtime-comparison`](skills/autonomous-ai-agents/hermes-runtime-comparison/SKILL.md) | 2.0.0 | Compare CLI/TUI, Gateway, Dashboard, Desktop, Web runtimes. |
| [`hermes-tool-diagnostics`](skills/autonomous-ai-agents/hermes-tool-diagnostics/SKILL.md) | 1.3.0 | Troubleshoot tool availability — missing dependencies, ACP recovery. |
| [`opencode`](skills/autonomous-ai-agents/opencode/SKILL.md) | 1.2.0 | Delegate coding to OpenCode CLI. |

### creative *(17 skills)*
Visuals, diagrams, video, audio, and design — from ASCII art to ComfyUI pipelines to 3Blue1Brown-style Manim animations.

| Skill | Version | Description |
|-------|---------|-------------|
| [`architecture-diagram`](skills/creative/architecture-diagram/SKILL.md) | 1.0.0 | Dark-themed SVG architecture/cloud/infra diagrams as HTML. |
| [`ascii-art`](skills/creative/ascii-art/SKILL.md) | 4.0.0 | pyfiglet, cowsay, boxes, image-to-ascii. |
| [`ascii-video`](skills/creative/ascii-video/SKILL.md) | 0.0.0 | Video/audio to colored ASCII MP4/GIF. |
| [`baoyu-infographic`](skills/creative/baoyu-infographic/SKILL.md) | 1.56.1 | Infographics: 21 layouts × 21 styles. |
| [`claude-design`](skills/creative/claude-design/SKILL.md) | 1.1.0 | One-off HTML artifacts — landings, decks, prototypes. |
| [`comfyui`](skills/creative/comfyui/SKILL.md) | 5.1.0 | Image, video, audio generation — install, manage nodes/models. |
| [`design-md`](skills/creative/design-md/SKILL.md) | 1.0.0 | Author/validate/export Google DESIGN.md token spec files. |
| [`eikon`](skills/creative/eikon/SKILL.md) | 0.0.0 | Guide for making/editing herm sidebar avatars (eikons). |
| [`eikon-create`](skills/creative/eikon-create/SKILL.md) | 0.0.0 | Generate source images and video for herm eikons. |
| [`excalidraw`](skills/creative/excalidraw/SKILL.md) | 1.0.0 | Hand-drawn Excalidraw JSON diagrams. |
| [`html-doc-ux`](skills/creative/html-doc-ux/SKILL.md) | 0.0.0 | UX enhancements for static HTML reference documents. |
| [`humanizer`](skills/creative/humanizer/SKILL.md) | 2.5.1 | Strip AI-isms and add real voice. |
| [`manim-video`](skills/creative/manim-video/SKILL.md) | 1.0.0 | 3Blue1Brown-style math/algo animations. |
| [`p5js`](skills/creative/p5js/SKILL.md) | 1.0.0 | Gen art, shaders, interactive, 3D sketches. |
| [`popular-web-designs`](skills/creative/popular-web-designs/SKILL.md) | 1.0.0 | 54 real design systems (Stripe, Linear, Vercel) as HTML/CSS. |
| [`sketch`](skills/creative/sketch/SKILL.md) | 1.0.0 | Throwaway HTML mockups — compare 2–3 design variants. |
| [`touchdesigner-mcp`](skills/creative/touchdesigner-mcp/SKILL.md) | 1.1.0 | Control TouchDesigner via MCP — operators, parameters, networks. |

### data-science *(1 skill)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`jupyter-live-kernel`](skills/data-science/jupyter-live-kernel/SKILL.md) | 1.0.0 | Iterative Python via live Jupyter kernel (hamelnb). |

### devops *(2 skills)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`fleet-health-watchdog`](skills/devops/fleet-health-watchdog/SKILL.md) | 1.2.0 | Fleet health cron — silent when healthy, alerts on circuit breaker. |
| [`npm-workspace-maintenance`](skills/devops/npm-workspace-maintenance/SKILL.md) | 1.0.0 | Fix npm vulnerabilities, broken lockfiles, dependency issues. |

### email *(1 skill)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`himalaya`](skills/email/himalaya/SKILL.md) | 1.1.0 | IMAP/SMTP email from terminal via Himalaya CLI. |

### github *(10 skills)*
Repository management, PR workflows, code review, fork operations, and auth — all through `gh` CLI and REST API.

| Skill | Version | Description |
|-------|---------|-------------|
| [`codebase-inspection`](skills/github/codebase-inspection/SKILL.md) | 1.0.0 | Inspect codebases — LOC, languages, ratios (pygount). |
| [`fork-detach`](skills/github/fork-detach/SKILL.md) | 0.0.0 | Detach a fork from its origin — scrub identity traces. |
| [`git-history-rewrite`](skills/github/git-history-rewrite/SKILL.md) | 0.0.0 | Rewrite git history — rename authors, scrub legacy content. |
| [`github-auth`](skills/github/github-auth/SKILL.md) | 1.1.0 | HTTPS tokens, SSH keys, gh CLI login. |
| [`github-code-review`](skills/github/github-code-review/SKILL.md) | 1.1.0 | Review PRs — diffs, inline comments via gh or REST. |
| [`github-fork-workflow`](skills/github/github-fork-workflow/SKILL.md) | 0.0.0 | Standard fork → clone → develop workflow. |
| [`github-issues`](skills/github/github-issues/SKILL.md) | 1.1.0 | Create, triage, label, assign issues. |
| [`github-pr-workflow`](skills/github/github-pr-workflow/SKILL.md) | 1.1.0 | Full PR lifecycle — branch, commit, open, CI, merge. |
| [`github-repo-management`](skills/github/github-repo-management/SKILL.md) | 1.1.0 | Clone/create/fork repos, manage remotes, releases. |
| [`github-windows-operations`](skills/github/github-windows-operations/SKILL.md) | 0.0.0 | GitHub operations on Windows — credential helpers, path handling. |

### hermes *(16 skills)*
Extend, configure, and evolve Hermes Agent itself — fleet profiles, cron, MCP, gateway, skill authoring, self-evolution, session continuity, and multi-agent orchestration design.

| Skill | Version | Description |
|-------|---------|-------------|
| [`agent-persona-authoring`](skills/hermes/agent-persona-authoring/SKILL.md) | 0.0.0 | Author and refine agent personality/identity documents (SOUL.md). |
| [`cost-performance-tuning`](skills/hermes/cost-performance-tuning/SKILL.md) | 1.6.0 | Tune model, compression, streaming, delegation settings. |
| [`hermes-cron-operations`](skills/hermes/hermes-cron-operations/SKILL.md) | 1.5.0 | Operate and troubleshoot the Hermes cron scheduler. |
| [`hermes-fleet-profiles`](skills/hermes/hermes-fleet-profiles/SKILL.md) | 1.11.0 | Deploy multi-agent fleet profiles from a wiki manifest. |
| [`hermes-gateway-setup`](skills/hermes/hermes-gateway-setup/SKILL.md) | 0.0.0 | Configure Telegram, Discord, SMS gateways. |
| [`hermes-mcp-debugging`](skills/hermes/hermes-mcp-debugging/SKILL.md) | 1.11.0 | Debug MCP servers — lifecycle, diagnostics, failures. |
| [`hermes-output-visibility`](skills/hermes/hermes-output-visibility/SKILL.md) | 1.1.0 | Control what you see, how you see it. |
| [`hermes-provider-setup`](skills/hermes/hermes-provider-setup/SKILL.md) | 1.3.0 | Configure LLM providers — API keys, base URLs, model selection. |
| [`hermes-role-profile-builder`](skills/hermes/hermes-role-profile-builder/SKILL.md) | 0.0.0 | Create purpose-built profiles for specialized workflows. |
| [`hermes-session-continuity`](skills/hermes/hermes-session-continuity/SKILL.md) | 0.0.0 | Recover context across compacted or cross-platform sessions. |
| [`multi-agent-orchestration-design`](skills/hermes/multi-agent-orchestration-design/SKILL.md) | 2.8.1 | Design optimal multi-agent fleet architectures. |
| [`self-evolution`](skills/hermes/self-evolution/SKILL.md) | 0.0.0 | Run the self-evolution pipeline — DSPy optimization. |
| [`skill-maintenance`](skills/hermes/skill-maintenance/SKILL.md) | 2.0.0 | Keep skills lean — bloat audits, consolidation workflows. |
| [`cascade`](skills/hermes/cascade/SKILL.md) | — | *Documentation placeholder.* |
| [`isolated-hermes-instance`](skills/hermes/isolated-hermes-instance/SKILL.md) | — | *Documentation placeholder.* |
| [`session-wiki-pipeline`](skills/hermes/session-wiki-pipeline/SKILL.md) | — | *Documentation placeholder.* |

### knowledge-base-organization *(3 skills)*
Extract structured knowledge, migrate content, and create entity pages for your wiki or knowledge base.

| Skill | Version | Description |
|-------|---------|-------------|
| [`ai-platform-data-extraction`](skills/knowledge-base-organization/ai-platform-data-extraction/SKILL.md) | 1.2.0 | Extract knowledge from Claude.ai, ChatGPT exports. |
| [`wiki-content-migration`](skills/knowledge-base-organization/wiki-content-migration/SKILL.md) | 1.0.0 | Audit and migrate user workspace content into a wiki. |
| [`wishlist-entity-creation`](skills/knowledge-base-organization/wishlist-entity-creation/SKILL.md) | 0.0.0 | Create standardized entity pages with provenance tracking. |

### mcp *(1 skill)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`native-mcp`](skills/mcp/native-mcp/SKILL.md) | 1.3.0 | MCP client — connect servers, register tools (stdio/HTTP). |

### media *(3 skills)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`heartmula`](skills/media/heartmula/SKILL.md) | 1.0.0 | Suno-like song generation from lyrics + tags. |
| [`songsee`](skills/media/songsee/SKILL.md) | 1.0.0 | Audio spectrograms and features (mel, chroma, MFCC) via CLI. |
| [`youtube-content`](skills/media/youtube-content/SKILL.md) | 0.0.0 | YouTube transcripts to summaries, threads, blogs. |

### messaging *(1 skill)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`signal-cli`](skills/messaging/signal-cli/SKILL.md) | 1.0.0 | Install, configure, and use Signal CLI on Windows. |

### mlops *(1 skill)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`huggingface-hub`](skills/mlops/huggingface-hub/SKILL.md) | 1.0.0 | Search, download, upload models and datasets via hf CLI. |

### note-taking *(2 skills)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`brave-bookmarks-to-wiki`](skills/note-taking/brave-bookmarks-to-wiki/SKILL.md) | 2.2.0 | Parse Brave bookmarks into wiki pages. |
| [`obsidian`](skills/note-taking/obsidian/SKILL.md) | 0.0.0 | Read, search, create, and edit Obsidian vault notes. |

### productivity *(16 skills)*
ADHD-friendly tools, task management, documents, maps, notetaking, and workspace organization. Includes brain-dump, quick-win, and redirect for executive function support.

| Skill | Version | Description |
|-------|---------|-------------|
| [`airtable`](skills/productivity/airtable/SKILL.md) | 1.1.0 | REST API CRUD, filters, upserts. |
| [`brain-dump`](skills/productivity/brain-dump/SKILL.md) | 9 | Zero-friction capture for racing thoughts. |
| [`document-verification-update`](skills/productivity/document-verification-update/SKILL.md) | 0.0.0 | Audit reference docs for factual accuracy. |
| [`google-workspace`](skills/productivity/google-workspace/SKILL.md) | 1.1.0 | Gmail, Calendar, Drive, Docs, Sheets. |
| [`knowledge-base-organization`](skills/productivity/knowledge-base-organization/SKILL.md) | — | *Documentation placeholder.* |
| [`knowledge-consolidation`](skills/productivity/knowledge-consolidation/SKILL.md) | 0.0.0 | Merge fragmented knowledge files into one. |
| [`maps`](skills/productivity/maps/SKILL.md) | 1.2.0 | Geocode, POIs, routes, timezones via OSM/OSRM. |
| [`nano-pdf`](skills/productivity/nano-pdf/SKILL.md) | 1.0.0 | Edit PDF text/typos/titles via natural language. |
| [`notion`](skills/productivity/notion/SKILL.md) | 2.0.0 | Notion API + ntn CLI — pages, databases, markdown. |
| [`ocr-and-documents`](skills/productivity/ocr-and-documents/SKILL.md) | 2.3.0 | Extract text from PDFs and scans. |
| [`petdex`](skills/productivity/petdex/SKILL.md) | 1.0.0 | Install animated petdex mascots for Hermes. |
| [`powerpoint`](skills/productivity/powerpoint/SKILL.md) | 0.0.0 | Create, read, edit .pptx decks and slides. |
| [`quick-win`](skills/productivity/quick-win/SKILL.md) | 3 | ADHD dopamine hack — find a single ≤5 min task. |
| [`recipe-card-generation`](skills/productivity/recipe-card-generation/SKILL.md) | 0.0.0 | Generate formatted recipe cards as PDFs. |
| [`redirect`](skills/productivity/redirect/SKILL.md) | 3 | ADHD recovery — minimize distractions and re-engage. |
| [`teams-meeting-pipeline`](skills/productivity/teams-meeting-pipeline/SKILL.md) | 1.1.0 | Summarize Teams meetings via Hermes CLI. |

### red-teaming *(1 skill)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`godmode`](skills/red-teaming/godmode/SKILL.md) | 1.0.0 | LLM jailbreaking research — Parseltongue, GODMODE, ULTRAPLINIAN. |

### research *(8 skills)*
Academic research, market data, community mining, and paper writing — arxiv, Polymarket, blog monitoring, and full NeurIPS/ICML/ICLR paper pipelines.

| Skill | Version | Description |
|-------|---------|-------------|
| [`arxiv`](skills/research/arxiv/SKILL.md) | 1.0.0 | Search papers by keyword, author, category, or ID. |
| [`blogwatcher`](skills/research/blogwatcher/SKILL.md) | 2.0.0 | Monitor blogs and RSS/Atom feeds. |
| [`community-discourse-mining`](skills/research/community-discourse-mining/SKILL.md) | 0.0.0 | Extract insights from community discussions. |
| [`polymarket`](skills/research/polymarket/SKILL.md) | 1.0.0 | Query markets, prices, orderbooks, history. |
| [`research-paper-writing`](skills/research/research-paper-writing/SKILL.md) | 1.1.0 | Write ML papers for top conferences — design to submit. |
| [`tech-stack-research`](skills/research/tech-stack-research/SKILL.md) | 1.0.0 | Investigate what tools and workflows people use. |
| [`web-research-synthesis`](skills/research/web-research-synthesis/SKILL.md) | 1.3.0 | Open-ended research via web search — blocked sources, multi-perspective synthesis. |
| [`ecosystem-reconnaissance`](skills/research/ecosystem-reconnaissance/SKILL.md) | — | *Documentation placeholder.* |

### smart-home *(1 skill)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`openhue`](skills/smart-home/openhue/SKILL.md) | 1.0.0 | Control Philips Hue lights, scenes, rooms via CLI. |

### social-media *(1 skill)*
| Skill | Version | Description |
|-------|---------|-------------|
| [`xurl`](skills/social-media/xurl/SKILL.md) | 1.1.1 | X/Twitter — post, search, DM, media, v2 API. |

### software-development *(17 skills)*
Full-stack development workflows — terminal stack, TDD, debugging, code review, refactoring, Windows optimization, HTML app building, and local LLM setup.

| Skill | Version | Description |
|-------|---------|-------------|
| [`ai-terminal-stack`](skills/software-development/ai-terminal-stack/SKILL.md) | 0.0.0 | Plan and configure an AI terminal stack: zellij, neovim, WezTerm. |
| [`hermes-agent-skill-authoring`](skills/software-development/hermes-agent-skill-authoring/SKILL.md) | 2.0.0 | Author SKILL.md files — frontmatter, structure, conventions. |
| [`html-application-building`](skills/software-development/html-application-building/SKILL.md) | 0.0.0 | Build polished, self-contained HTML single-page apps. |
| [`local-llm-setup`](skills/software-development/local-llm-setup/SKILL.md) | 1.0.0 | Local LLM inference on Windows — Ollama, llama.cpp, vLLM. |
| [`node-inspect-debugger`](skills/software-development/node-inspect-debugger/SKILL.md) | 1.0.0 | Debug Node.js via --inspect + CDP CLI. |
| [`post-phase-review`](skills/software-development/post-phase-review/SKILL.md) | 1.0.0 | Post-execution retrospective — audit vs reality update. |
| [`professional-ai-stack`](skills/software-development/professional-ai-stack/SKILL.md) | 1.0.0 | Assess hardware and build a professional AI engineering stack. |
| [`python-debugpy`](skills/software-development/python-debugpy/SKILL.md) | 1.0.0 | Debug Python — pdb REPL + debugpy remote (DAP). |
| [`requesting-code-review`](skills/software-development/requesting-code-review/SKILL.md) | 2.0.0 | Pre-commit review — security scan, quality gates, auto-fix. |
| [`safe-large-file-editing`](skills/software-development/safe-large-file-editing/SKILL.md) | 0.0.0 | Prevent file corruption during large edits — safety patterns. |
| [`simplify-code`](skills/software-development/simplify-code/SKILL.md) | 1.0.0 | Parallel 3-agent cleanup of recent code changes. |
| [`spike`](skills/software-development/spike/SKILL.md) | 1.0.0 | Throwaway experiments to validate ideas before building. |
| [`systematic-debugging`](skills/software-development/systematic-debugging/SKILL.md) | 1.1.0 | 4-phase root cause debugging. |
| [`systematic-method-refactoring`](skills/software-development/systematic-method-refactoring/SKILL.md) | 1.0.0 | Extract large methods into focused helpers — AST-guided. |
| [`test-driven-development`](skills/software-development/test-driven-development/SKILL.md) | 1.1.0 | RED-GREEN-REFACTOR — tests before code. |
| [`web-page-extraction`](skills/software-development/web-page-extraction/SKILL.md) | — | *Documentation placeholder.* |
| [`windows-cleanup-optimization`](skills/software-development/windows-cleanup-optimization/SKILL.md) | 1.0.0 | Clean and optimize Windows — caches, startup, telemetry, disk. |

---

## Managing Installed Skills

```bash
# List installed skills
hermes skills list

# View a skill's content (loaded after install)
hermes skills view <skill-name>

# Remove a skill
hermes skills remove <skill-name>

# Update all skills from registered taps
hermes skills update
```

See the [Hermes Agent documentation](https://hermes-agent.nousresearch.com/docs) for complete CLI reference.

---

## Contributing

This repository is auto-generated from a private monorepo via PII-gated export. Skills are curated, sanitized, and published periodically.

**To suggest improvements or report issues:** open a GitHub issue with the skill name in the title.

**To create your own skills:** use the `hermes-agent-skill-authoring` skill for structure and conventions, then publish via `hermes skills tap add <your-repo>`.

---

## License

All skills in this repository are provided under the [MIT License](LICENSE). See individual skill `SKILL.md` files for author attribution.

---

*Generated from polaris monorepo. Last updated: 2026-07-13.*