# Multi-Agent Orchestration Research Synthesis

**Session:** 2026-06-23 (v1) | 2026-06-24 (v2 — 12 sources)
**Sources:** 12 sources across academic (arXiv), industry (IBM, Azure, Anthropic, Google, LangChain, Confluent), frameworks (Augment Code, Google ADK), and analysis (Beam AI, TrueFoundry, Galileo, InfoQ)

## Key Findings for Fleet Design

### 1. Sequential Pipeline Is the Most Expensive Pattern

Every request hits all 5 phases regardless of complexity. Research says this is wrong.

| Source | Finding |
|--------|---------|
| arXiv:2512.08296 | Multi-agent degrades performance 39-70% on sequential tasks |
| Beam AI | 4-agent pipeline adds ~950ms coordination overhead per 500ms processing |
| Azure Architecture | "If prompt engineering can solve it, you don't need an agent" |

**Impact on fleet:** Our pipeline averages ~135s per request (5 phases × ~27s each). For simple queries (status check, config lookup), this is 10x the cost of just answering directly.

### 2. Optimal Agent Count: 5-8

From the scaling paper (180 configurations tested):

> *"Coordination yields diminishing or negative returns once single-agent baselines exceed ~45%."*
> *"Tool-heavy tasks suffer disproportionately from multi-agent overhead."*

| Agent Count | Finding |
|-------------|---------|
| 1 | Best for sequential/depth-first tasks |
| 3-5 | Optimal range for most multi-agent systems |
| 5-8 | Diminishing returns begin |
| 8+ | Coordination overhead dominates |
| 50+ | Anthropic uses this for research only (massive parallelism, not pipeline) |

**For our setup (Nous Portal, deepseek-v4-flash):** 5-7 workers + 1 default = 6-8 total. The proposed reduction from 13→8 is validated by this research.

### 3. Error Amplification Scales with Agent Count

| Coordination Mode | Error Amplification |
|-------------------|-------------------|
| Independent agents (no gates) | 17.2× |
| Centralized coordination (gates) | 4.4× |

Our fleet's Nemesis+Ceres gates are the right pattern — they contain error amplification.

### 4. The 8 Design Patterns (Ranked by Relevance)

| Pattern | For Fleet | Research Verdict |
|---------|-----------|-----------------|
| **Orchestrator-Worker** | Replace keyword router with LLM Astraea | Anthropic's #1 pattern |
| **Generator+Critic** | Already works (Nemesis+Ceres) | Best quality assurance pattern |
| **Router** | Enhanced keyword → LLM classification | Stateless, per-request |
| **Fan-Out/Gather** | Parallel workers for multi-angle tasks | 75% wall-clock reduction |
| **Sequential Pipeline** | Current architecture — too rigid | Most expensive pattern |
| **Human-in-Loop** | Missing — add for fleet config changes | Essential for irreversible actions |
| **Hierarchical** | Not needed at our scale | Overkill |
| **Multi-Agent Debate** | Not useful for our tasks | Overkill |

### 5. What's Missing From Our Fleet

| Missing Role | Research Canon | Why Needed |
|-------------|---------------|-----------|
| Memory Agent | Anthropic, arXiv | Mnemosyne was removed; no state persistence |
| Observability Agent | Galileo, arXiv | No health/cost/latency monitoring |
| Fallback Handler | All frameworks | Currently hard-coded, no graceful degradation |
| Human-in-Loop Gate | Google ADK #7 | For irreversible actions (deployments, config) |

### 6. arXiv 2601.13671v1 — Three Agent Categories

This paper provides the definitive taxonomy of agent types in an orchestrated MAS. Every agent in our fleet should fit one of these categories:

| Category | Role | Our Equivalent | Purpose |
|----------|------|---------------|---------|
| **Worker Agents** | Task execution | Metis-9, Artemis-105, Fortuna-19, Klio-84, Harmonia-40, Atalanta-36, Kalliope-22 | Perform well-defined tasks. Can be stateless or stateful. Form the execution layer. |
| **Service Agents** | Shared operational capabilities | Vesta-4 (security), Nemesis-128 (QA), Ceres-1 (review) | QA enforcement, compliance checks, diagnostics, automated recovery. Reusable utilities. |
| **Support Agents** | Supervisory/analytical oversight | **MISSING** — no equivalent deployed | Monitor system behavior, analyze outcomes, manage data flows. Track latency, drift, costs, error rates. Maintain health and transparency. |

**Key insight:** We have Workers and Service agents but zero Support agents. No agent watches the fleet's health, tracks costs, or detects drift.

### 7. Augment Code — The Four Primitives

Every multi-agent system is built on four primitives. A gap in any one creates systemic failure:

| Primitive | Our Current State | Research-Backed Target | Failure Mode If Missing |
|-----------|------------------|----------------------|------------------------|
| **Task Decomposition** | ✅ Astraea-5 keyword routing | LLM-based decomposition with dependency DAG | Brittle routing, missed categories |
| **Routing** | ⚠️ Keyword-based, being upgraded | LLM classification + keyword fallback | Misroutes "analyze this PR" to data instead of code |
| **State** | ❌ Unstructured strings between pipeline stages | Typed PipelineState dataclass (like LangGraph StateGraph) | Silent data corruption, no audit trail, hard to debug |
| **Recovery** | ❌ Basic retry or fallback to default | GraSP: Rebind → Substitute → Bypass → Escalate | Single failure cascades through entire pipeline |

**GraSP Recovery Primitives** (from arXiv:2601.13671v1 further reading on local graph repair):

| Primitive | What It Does | In Fleet Terms |
|-----------|-------------|---------------|
| **Rebind** | Update arguments of a failed node | Retry Metis-9 with restructured prompt |
| **Substitute** | Replace a skill while preserving downstream | Send search task to Klio-84 instead of Artemis-105 |
| **Bypass** | Skip a node if downstream requirements already met | Return partial output instead of crashing |
| **Escalate** | Global replan when local repair fails | Run full sequential pipeline as fallback |

### 8. Beam AI — Production Pattern Failure Modes

From 2026 production data across enterprise deployments:

| Pattern | Key Benefit | How It Fails | Mitigation |
|---------|-------------|-------------|------------|
| **Orchestrator-Worker** | 40-60% cost reduction | Context overflow with 4+ workers. Orchestrator accumulates all worker context. | Context budget (max 3 workers, summary-based handoff) |
| **Sequential Pipeline** | Deterministic ordering | 950ms overhead for 4-agent chain vs 500ms processing. Error propagation. | Use only for complex tasks. Skip gates for simple ones. |
| **Fan-out/Fan-in** | 75% wall-clock reduction | API rate limits (collective load exceeds limits). Race conditions (N(N-1)/2 potential conflicts). | asyncio.Semaphore, unique result keys |
| **Multi-Agent Debate** | Reduced hallucinations | Conversation loops, sycophancy cascade (agents agree with majority) | Limit to 3 agents, don't use for our tasks |

**Critical stat:** 40% of multi-agent pilots fail within 6 months. Organizations average 12 agents, growing 67% in two years.

### 9. Agent Role Taxonomy (Consolidated)

| Canonical Role | Our Equivalent | Design Pattern for Profiles |
|----------------|---------------|-----------------------------|
| **Orchestrator/Dispatcher** | Astraea-5 | Decompose tasks → delegate. LLM-based, not keyword |
| **Worker** | Metis-9, Artemis-105, Kalliope-22 | Task-first [ROLE]/[BEHAVIOR]/[OUTPUT]/[RULES] |
| **Gate/Guardrail** | Vesta-4 (security) | Explicit criteria for pass/fail |
| **Critic/Validator** | Nemesis-128 (QA), Ceres-1 (review) | Structured evaluation format |
| **Service (memory)** | Missing | Long-term state management |
| **Support (observability)** | Missing | System health, drift, cost tracking |

### 7. Profile Design — The Research-Validated Pattern

From E2E tests (2026-06-23):

```
[ROLE]: One sentence. What you do.
[BEHAVIOR]: 2-3 bullet instructions. How you work.
[OUTPUT]: What you deliver. Format expectations.
[RULES]: Non-negotiables — no preamble, no roleplay, direct answer first.
[PERSONALITY]: One line of voice style (optional).
```

**Evidence:** Klio-84 (mythological) = 8/100. Artemis-105 (task-first) = 100/100. Theatrical prompts cause catastrophic failure in worker agents.

### Source Provenance

| Source | Topics Covered | Type |
|--------|---------------|------|
| **arXiv:2601.13671v1** | Three agent categories (Worker/Service/Support). Orchestration layer = Planning + Policy + State + Quality. MCP/A2A protocols. Governance + observability as core modules. | Academic paper |
| arXiv:2512.08296v1 | Scaling laws, optimal agent count, error amplification | Academic paper |
| **IBM Think** | Orchestration steps: Assess → Select → Framework → Assign → Coordinate. Centralized vs decentralized vs hierarchical vs federated orchestration types. | Architecture guide |
| **Augment Code** | Four primitives of MAS: Task Decomposition, Routing, **State**, **Recovery**. GraSP local repair (Rebind, InsertPrereq, Substitute, Rewire, Bypass, Escalate). Context reset with structured handoff. | Engineering guide |
| **Beam AI (6 production patterns)** | Fan-out = 75% wall-clock reduction. Orchestrator context overflow with 4+ workers. 40% of multi-agent pilots fail within 6 months. API rate limits = #1 fan-out failure. Sequential pipeline adds 950ms overhead for 4-agent chain vs 500ms processing. | Production patterns |
| **Confluent / InfoWorld** | Event-driven MAS: pub/sub as coordination backbone. Blackboard pattern = shared knowledge base. Key-based partitioning for work distribution. | Architectural patterns |
| Microsoft Azure | AI Agent Design Patterns, production guidance | Architecture docs |
| Anthropic Engineering | Multi-agent research system, orchestrator-worker pattern | Engineering blog |
| Google ADK Blog | 8 essential multi-agent design patterns | Engineering blog |
| LangChain Blog | Architecture comparison, when to use which pattern | Framework blog |
| Galileo AI | Agent roles, counterfactual evaluation, action advancement | Analysis |
| TrueFoundry | Governance: access controls, permissions, audit trails. Cost tracking essential (15+ inference calls for 5-agent workflow). | Industry analysis |
| InfoQ | Summary of Google ADK 8 patterns | News analysis |
