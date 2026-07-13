# Hermes Skill Packs

Community Hermes skill packs — curated from polaris monorepo. Generic, reusable skills for Hermes Agent users.

**115 skills** across **19 categories**.

[![Skills](https://img.shields.io/badge/skills-115-blue)](https://github.com/chrisluersen/skill-packs)
[![Categories](https://img.shields.io/badge/categories-19-green)](https://github.com/chrisluersen/skill-packs)

## Usage

```bash
hermes skills tap add chrisluersen/skill-packs
hermes skills search <query>       # search all skills
hermes skills install chrisluersen/skill-packs/<skill-name>
```

## Skills by Category

### autonomous-ai-agents

| Skill | Version | Description |
|-------|---------|-------------|
| [claude-code](skills/autonomous-ai-agents/claude-code/SKILL.md) | 2.2.0 | Delegate coding to Claude Code CLI (features, PRs). |
| [codex](skills/autonomous-ai-agents/codex/SKILL.md) | 1.0.0 | Delegate coding to OpenAI Codex CLI (features, PRs). |
| [delegation-boundaries](skills/autonomous-ai-agents/delegation-boundaries/SKILL.md) | 0.0.0 | Judgment framework for deciding when to delegate work to subagents (delegate_tas |
| [hermes-agent](skills/autonomous-ai-agents/hermes-agent/SKILL.md) | 2.1.0 | Configure, extend, or contribute to Hermes Agent. |
| [hermes-browser-interfaces](skills/autonomous-ai-agents/hermes-browser-interfaces/SKILL.md) | 1.1.0 | Set up and use browser-based UIs for Hermes Agent — the built-in dashboard and t |
| [hermes-remote-access](skills/autonomous-ai-agents/hermes-remote-access/SKILL.md) | 1.0.0 | Configure remote and mobile access to Hermes Agent via Gateway API Server, Tails |
| [hermes-runtime-comparison](skills/autonomous-ai-agents/hermes-runtime-comparison/SKILL.md) | 2.0.0 | Compare Hermes Agent runtime modes (CLI/TUI, Gateway, Dashboard, Desktop App, We |
| [hermes-tool-diagnostics](skills/autonomous-ai-agents/hermes-tool-diagnostics/SKILL.md) | 1.3.0 | Troubleshoot Hermes tool availability — resolve 'system dependency not met', 'mi |
| [opencode](skills/autonomous-ai-agents/opencode/SKILL.md) | 1.2.0 | Delegate coding to OpenCode CLI (features, PR review). |

### creative

| Skill | Version | Description |
|-------|---------|-------------|
| [architecture-diagram](skills/creative/architecture-diagram/SKILL.md) | 1.0.0 | Dark-themed SVG architecture/cloud/infra diagrams as HTML. |
| [ascii-art](skills/creative/ascii-art/SKILL.md) | 4.0.0 | ASCII art: pyfiglet, cowsay, boxes, image-to-ascii. |
| [ascii-video](skills/creative/ascii-video/SKILL.md) | 0.0.0 | ASCII video: convert video/audio to colored ASCII MP4/GIF. |
| [baoyu-infographic](skills/creative/baoyu-infographic/SKILL.md) | 1.56.1 | Infographics: 21 layouts x 21 styles (信息图, 可视化). |
| [claude-design](skills/creative/claude-design/SKILL.md) | 1.1.0 | Design one-off HTML artifacts (landing, deck, prototype). |
| [comfyui](skills/creative/comfyui/SKILL.md) | 5.1.0 | Generate images, video, and audio with ComfyUI — install, launch, manage nodes/m |
| [design-md](skills/creative/design-md/SKILL.md) | 1.0.0 | Author/validate/export Google's DESIGN.md token spec files. |
| [eikon](skills/creative/eikon/SKILL.md) | 0.0.0 | Guide the user through making or editing a herm sidebar avatar (eikon) using her |
| [eikon-create](skills/creative/eikon-create/SKILL.md) | 0.0.0 | Interactively generate source images (and optionally short videos) for a herm ei |
| [excalidraw](skills/creative/excalidraw/SKILL.md) | 1.0.0 | Hand-drawn Excalidraw JSON diagrams (arch, flow, seq). |
| [html-doc-ux](skills/creative/html-doc-ux/SKILL.md) | 0.0.0 | Surgically add UX enhancements to existing static HTML reference documents — bac |
| [humanizer](skills/creative/humanizer/SKILL.md) | 2.5.1 | Humanize text: strip AI-isms and add real voice. |
| [manim-video](skills/creative/manim-video/SKILL.md) | 1.0.0 | Manim CE animations: 3Blue1Brown math/algo videos. |
| [p5js](skills/creative/p5js/SKILL.md) | 1.0.0 | p5.js sketches: gen art, shaders, interactive, 3D. |
| [popular-web-designs](skills/creative/popular-web-designs/SKILL.md) | 1.0.0 | 54 real design systems (Stripe, Linear, Vercel) as HTML/CSS. |
| [pretext](skills/creative/pretext/SKILL.md) | 1.0.0 | Use when building creative browser demos with @chenglou/pretext — DOM-free text  |
| [sketch](skills/creative/sketch/SKILL.md) | 1.0.0 | Throwaway HTML mockups: 2-3 design variants to compare. |
| [songwriting-and-ai-music](skills/creative/songwriting-and-ai-music/SKILL.md) | 0.0.0 | Songwriting craft and Suno AI music prompts. |
| [touchdesigner-mcp](skills/creative/touchdesigner-mcp/SKILL.md) | 1.1.0 | Control a running TouchDesigner instance via twozero MCP — create operators, set |

### data-science

| Skill | Version | Description |
|-------|---------|-------------|
| [jupyter-live-kernel](skills/data-science/jupyter-live-kernel/SKILL.md) | 1.0.0 | Iterative Python via live Jupyter kernel (hamelnb). |

### devops

| Skill | Version | Description |
|-------|---------|-------------|
| [fleet-health-watchdog](skills/devops/fleet-health-watchdog/SKILL.md) | 1.2.0 | Fleet health watchdog cron job — silent when healthy, alerts on circuit breaker  |
| [npm-workspace-maintenance](skills/devops/npm-workspace-maintenance/SKILL.md) | 1.0.0 | Fix npm vulnerabilities, broken lockfiles, and dependency issues in workspace mo |

### email

| Skill | Version | Description |
|-------|---------|-------------|
| [himalaya](skills/email/himalaya/SKILL.md) | 1.1.0 | Himalaya CLI: IMAP/SMTP email from terminal. |

### github

| Skill | Version | Description |
|-------|---------|-------------|
| [codebase-inspection](skills/github/codebase-inspection/SKILL.md) | 1.0.0 | Inspect codebases w/ pygount: LOC, languages, ratios. |
| [fork-detach](skills/github/fork-detach/SKILL.md) | 0.0.0 | Detach a forked repository from its origin — scrub all identity traces, rewrite  |
| [git-history-rewrite](skills/github/git-history-rewrite/SKILL.md) | 0.0.0 | Rewrite git repository history using git-filter-repo — rename authors, scrub leg |
| [github-auth](skills/github/github-auth/SKILL.md) | 1.1.0 | GitHub auth setup: HTTPS tokens, SSH keys, gh CLI login. |
| [github-code-review](skills/github/github-code-review/SKILL.md) | 1.1.0 | Review PRs: diffs, inline comments via gh or REST. |
| [github-fork-workflow](skills/github/github-fork-workflow/SKILL.md) | 0.0.0 | Standard workflow for forking a GitHub repository and setting up local developme |
| [github-issues](skills/github/github-issues/SKILL.md) | 1.1.0 | Create, triage, label, assign GitHub issues via gh or REST. |
| [github-pr-workflow](skills/github/github-pr-workflow/SKILL.md) | 1.1.0 | GitHub PR lifecycle: branch, commit, open, CI, merge. |
| [github-repo-management](skills/github/github-repo-management/SKILL.md) | 1.1.0 | Clone/create/fork repos; manage remotes, releases. |
| [github-windows-operations](skills/github/github-windows-operations/SKILL.md) | 0.0.0 | >- |

### hermes

| Skill | Version | Description |
|-------|---------|-------------|
| [agent-persona-authoring](skills/hermes/agent-persona-authoring/SKILL.md) | 0.0.0 | Author and iteratively refine an agent's personality/identity document (SOUL.md) |
| [cascade](skills/hermes/cascade/SKILL.md) | 0.0.0 | >- |
| [cost-performance-tuning](skills/hermes/cost-performance-tuning/SKILL.md) | 1.6.0 | Tune Hermes Agent model, compression, streaming, delegation, and auxiliary setti |
| [hermes-cron-operations](skills/hermes/hermes-cron-operations/SKILL.md) | 1.5.0 | Operate, troubleshoot, and understand the Hermes Agent cron scheduler — architec |
| [hermes-fleet-profiles](skills/hermes/hermes-fleet-profiles/SKILL.md) | 1.11.0 | Deploy multi-agent fleet profiles from a wiki manifest — clone Hermes profiles f |
| [hermes-gateway-setup](skills/hermes/hermes-gateway-setup/SKILL.md) | 0.0.0 | Configure, operate, and troubleshoot the Hermes messaging gateway — set up Teleg |
| [hermes-mcp-debugging](skills/hermes/hermes-mcp-debugging/SKILL.md) | 1.11.0 | Debug MCP servers in Hermes — lifecycle, diagnostics, common failures, Windows f |
| [hermes-output-visibility](skills/hermes/hermes-output-visibility/SKILL.md) | 1.1.0 | Configure Hermes Agent for maximum output visibility — control what you see, how |
| [hermes-provider-setup](skills/hermes/hermes-provider-setup/SKILL.md) | 1.3.0 | Configure LLM providers in Hermes Agent — add API keys, set base URLs, pick mode |
| [hermes-role-profile-builder](skills/hermes/hermes-role-profile-builder/SKILL.md) | 0.0.0 | Create purpose-built Hermes profiles for specialized workflows — clone from ligh |
| [hermes-session-continuity](skills/hermes/hermes-session-continuity/SKILL.md) | 0.0.0 | Recover context across compacted, queued, or cross-platform Hermes sessions (CLI |
| [isolated-hermes-instance](skills/hermes/isolated-hermes-instance/SKILL.md) | 0.0.0 | >- |
| [multi-agent-orchestration-design](skills/hermes/multi-agent-orchestration-design/SKILL.md) | 2.8.1 | Design optimal multi-agent fleet architectures — agent topology, orchestration l |
| [self-evolution](skills/hermes/self-evolution/SKILL.md) | 0.0.0 | Run the Hermes Agent Self-Evolution pipeline — evolve skills using DSPy optimiza |
| [session-wiki-pipeline](skills/hermes/session-wiki-pipeline/SKILL.md) | 0.0.0 | >- |
| [skill-maintenance](skills/hermes/skill-maintenance/SKILL.md) | 2.0.0 | Keep Hermes skills lean and correct over time — bloat audits, consolidation work |

### knowledge-base-organization

| Skill | Version | Description |
|-------|---------|-------------|
| [ai-platform-data-extraction](skills/knowledge-base-organization/ai-platform-data-extraction/SKILL.md) | 1.2.0 | Extract structured knowledge from external AI platform exports (Claude.ai, ChatG |
| [wiki-content-migration](skills/knowledge-base-organization/wiki-content-migration/SKILL.md) | 1.0.0 | Audit user workspace locations — .hermes/plans/, home directory, Hermes_Artifact |
| [wishlist-entity-creation](skills/knowledge-base-organization/wishlist-entity-creation/SKILL.md) | 0.0.0 | Create standardized entity pages for wishlist/to-buy items with provenance track |

### mcp

| Skill | Version | Description |
|-------|---------|-------------|
| [native-mcp](skills/mcp/native-mcp/SKILL.md) | 1.3.0 | MCP client: connect servers, register tools (stdio/HTTP). |

### media

| Skill | Version | Description |
|-------|---------|-------------|
| [heartmula](skills/media/heartmula/SKILL.md) | 1.0.0 | HeartMuLa: Suno-like song generation from lyrics + tags. |
| [songsee](skills/media/songsee/SKILL.md) | 1.0.0 | Audio spectrograms/features (mel, chroma, MFCC) via CLI. |
| [youtube-content](skills/media/youtube-content/SKILL.md) | 0.0.0 | YouTube transcripts to summaries, threads, blogs. |

### messaging

| Skill | Version | Description |
|-------|---------|-------------|
| [signal-cli](skills/messaging/signal-cli/SKILL.md) | 1.0.0 | Install, configure, and register Signal CLI on Windows for local Signal messagin |

### mlops

| Skill | Version | Description |
|-------|---------|-------------|
| [huggingface-hub](skills/mlops/huggingface-hub/SKILL.md) | 1.0.0 | HuggingFace hf CLI: search/download/upload models, datasets. |

### note-taking

| Skill | Version | Description |
|-------|---------|-------------|
| [brave-bookmarks-to-wiki](skills/note-taking/brave-bookmarks-to-wiki/SKILL.md) | 2.2.0 | Parse Brave bookmarks (HTML export or native JSON) into wiki pages — phased appr |
| [obsidian](skills/note-taking/obsidian/SKILL.md) | 0.0.0 | Read, search, create, and edit notes in the Obsidian vault. |

### productivity

| Skill | Version | Description |
|-------|---------|-------------|
| [airtable](skills/productivity/airtable/SKILL.md) | 1.1.0 | Airtable REST API via curl. Records CRUD, filters, upserts. |
| [brain-dump](skills/productivity/brain-dump/SKILL.md) | 9 | ADHD-friendly brain dump: zero-friction capture of whatever's racing through you |
| [document-verification-update](skills/productivity/document-verification-update/SKILL.md) | 0.0.0 | 'Audit reference documents for factual accuracy or completeness. Three modes: (1 |
| [google-workspace](skills/productivity/google-workspace/SKILL.md) | 1.1.0 | Gmail, Calendar, Drive, Docs, Sheets via gws CLI or Python. |
| [knowledge-base-organization](skills/productivity/knowledge-base-organization/SKILL.md) | 0.0.0 | >- |
| [knowledge-consolidation](skills/productivity/knowledge-consolidation/SKILL.md) | 0.0.0 | Merge multiple fragmented knowledge files (markdown, HTML, text) into one compre |
| [maps](skills/productivity/maps/SKILL.md) | 1.2.0 | Geocode, POIs, routes, timezones via OpenStreetMap/OSRM. |
| [nano-pdf](skills/productivity/nano-pdf/SKILL.md) | 1.0.0 | Edit PDF text/typos/titles via nano-pdf CLI (NL prompts). |
| [notion](skills/productivity/notion/SKILL.md) | 2.0.0 | Notion API + ntn CLI: pages, databases, markdown, Workers. |
| [ocr-and-documents](skills/productivity/ocr-and-documents/SKILL.md) | 2.3.0 | Extract text from PDFs/scans (pymupdf, marker-pdf). |
| [petdex](skills/productivity/petdex/SKILL.md) | 1.0.0 | Install and select animated petdex mascots for Hermes. |
| [powerpoint](skills/productivity/powerpoint/SKILL.md) | 0.0.0 | Create, read, edit .pptx decks, slides, notes, templates. |
| [quick-win](skills/productivity/quick-win/SKILL.md) | 3 | ADHD dopamine hack. When nothing feels doable, find a single task that takes ≤5  |
| [recipe-card-generation](skills/productivity/recipe-card-generation/SKILL.md) | 0.0.0 | Generate formatted recipe cards as PDFs for coffee/tea brewing, cooking, or any  |
| [redirect](skills/productivity/redirect/SKILL.md) | 3 | ADHD recovery skill. When a distraction steals your train of thought, minimize t |
| [reference-document-layout](skills/productivity/reference-document-layout/SKILL.md) | 0.0.0 | Design scannable, well-tiered markdown reference documents that present structur |
| [task-management-workflow](skills/productivity/task-management-workflow/SKILL.md) | 0.0.0 | Full-stack task management — create, track, update, and complete tasks via CLI w |
| [teams-meeting-pipeline](skills/productivity/teams-meeting-pipeline/SKILL.md) | 1.1.0 | Operate the Teams meeting summary pipeline via Hermes CLI — summarize meetings,  |

### red-teaming

| Skill | Version | Description |
|-------|---------|-------------|
| [godmode](skills/red-teaming/godmode/SKILL.md) | 1.0.0 | Jailbreak LLMs: Parseltongue, GODMODE, ULTRAPLINIAN. |

### research

| Skill | Version | Description |
|-------|---------|-------------|
| [arxiv](skills/research/arxiv/SKILL.md) | 1.0.0 | Search arXiv papers by keyword, author, category, or ID. |
| [blogwatcher](skills/research/blogwatcher/SKILL.md) | 2.0.0 | Monitor blogs and RSS/Atom feeds via blogwatcher-cli tool. |
| [community-discourse-mining](skills/research/community-discourse-mining/SKILL.md) | 0.0.0 | Systematically extract, filter, and integrate valuable insights from community d |
| [ecosystem-reconnaissance](skills/research/ecosystem-reconnaissance/SKILL.md) | 1.1.0 | >- |
| [polymarket](skills/research/polymarket/SKILL.md) | 1.0.0 | Query Polymarket: markets, prices, orderbooks, history. |
| [research-paper-writing](skills/research/research-paper-writing/SKILL.md) | 1.1.0 | Write ML papers for NeurIPS/ICML/ICLR: design→submit. |
| [tech-stack-research](skills/research/tech-stack-research/SKILL.md) | 1.0.0 | Investigate what tools, software, and workflows people and organizations use by  |
| [web-research-synthesis](skills/research/web-research-synthesis/SKILL.md) | 1.3.0 | Research an open-ended user question via web search, handle blocked/failed sourc |

### smart-home

| Skill | Version | Description |
|-------|---------|-------------|
| [openhue](skills/smart-home/openhue/SKILL.md) | 1.0.0 | Control Philips Hue lights, scenes, rooms via OpenHue CLI. |

### social-media

| Skill | Version | Description |
|-------|---------|-------------|
| [xurl](skills/social-media/xurl/SKILL.md) | 1.1.1 | X/Twitter via xurl CLI: post, search, DM, media, v2 API. |

### software-development

| Skill | Version | Description |
|-------|---------|-------------|
| [ai-terminal-stack](skills/software-development/ai-terminal-stack/SKILL.md) | 0.0.0 | Plan, configure, and maintain a high-performance AI-oriented terminal stack: zel |
| [hermes-agent-skill-authoring](skills/software-development/hermes-agent-skill-authoring/SKILL.md) | 2.0.0 | Author SKILL.md: frontmatter, structure, and conventions for both user-local and |
| [html-application-building](skills/software-development/html-application-building/SKILL.md) | 0.0.0 | Build polished, self-contained HTML single-page applications from research, data |
| [local-llm-setup](skills/software-development/local-llm-setup/SKILL.md) | 1.0.0 | Set up local LLM inference on Windows with Ollama, llama.cpp, or vLLM. Covers mo |
| [node-inspect-debugger](skills/software-development/node-inspect-debugger/SKILL.md) | 1.0.0 | Debug Node.js via --inspect + Chrome DevTools Protocol CLI. |
| [post-phase-review](skills/software-development/post-phase-review/SKILL.md) | 1.0.0 | Post-execution retrospective cycle: audit what was done vs reality, update the p |
| [professional-ai-stack](skills/software-development/professional-ai-stack/SKILL.md) | 1.0.0 | Assess a user's hardware and OS, then build a verified professional AI engineeri |
| [python-debugpy](skills/software-development/python-debugpy/SKILL.md) | 1.0.0 | Debug Python: pdb REPL + debugpy remote (DAP). |
| [requesting-code-review](skills/software-development/requesting-code-review/SKILL.md) | 2.0.0 | Pre-commit review: security scan, quality gates, auto-fix. |
| [safe-large-file-editing](skills/software-development/safe-large-file-editing/SKILL.md) | 0.0.0 | Prevent file corruption and verify mutations for all file types. Root causes, sa |
| [simplify-code](skills/software-development/simplify-code/SKILL.md) | 1.0.0 | Parallel 3-agent cleanup of recent code changes. |
| [spike](skills/software-development/spike/SKILL.md) | 1.0.0 | Throwaway experiments to validate an idea before build. |
| [systematic-debugging](skills/software-development/systematic-debugging/SKILL.md) | 1.1.0 | 4-phase root cause debugging: understand bugs before fixing. |
| [systematic-method-refactoring](skills/software-development/systematic-method-refactoring/SKILL.md) | 1.0.0 | Extract large methods into focused helpers using AST-guided analysis, phased ext |
| [test-driven-development](skills/software-development/test-driven-development/SKILL.md) | 1.1.0 | TDD: enforce RED-GREEN-REFACTOR, tests before code. |
| [web-page-extraction](skills/software-development/web-page-extraction/SKILL.md) | 0.0.0 | >- |
| [windows-cleanup-optimization](skills/software-development/windows-cleanup-optimization/SKILL.md) | 1.0.0 | Windows cleanup & optimization — caches, startup, services, telemetry, disk heal |

## License

All skills in this repository are provided under the MIT License.
See individual skill SKILL.md files for author attribution.
