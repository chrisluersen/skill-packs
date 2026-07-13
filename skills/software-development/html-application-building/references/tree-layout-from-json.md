# Tree + Card Layout from JSON: Worked Example

## Session arc: Asteroid Fleet Dashboard

The user had a JSON file with 14 agents across 6 groups — the fleet dashboard UI went through 3 iterations before arriving at the right structure.

### The dataset shape (abbreviated)

```json
{
  "available_groups": [
    "Leadership & Routing",
    "Security & Validation",
    "Core Execution",
    "Infrastructure & Ops",
    "Data & Memory",
    "Creative & Interface"
  ],
  "fleet_agents": [
    { "designation": "Ceres-1", "fleet_classification": { "system_group": "Leadership & Routing", ... }, ... },
    { "designation": "Astraea-5", "fleet_classification": { "system_group": "Leadership & Routing", ... }, ... },
    { "designation": "Vesta-4", "fleet_classification": { "system_group": "Security & Validation", ... }, ... },
    // ... 11 more agents
  ]
}
```

### Iteration 1: Table (user said no)

Flat table of all 14 agents with columns (Designation, Role, MBTI, Tier, Context, Metric, Partner). The user's first correction: **"make it a tree structure instead and make each agent a card in the tree"**.

**Lesson:** For hierarchical data, lead with a tree, not a table. The user's mental model is "groups contain agents", not "a flat spreadsheet of agents".

### Iteration 2: Flat tree of peer groups (user said "too flat")

6 group headers side-by-side, each containing its agent cards. All groups at the same depth level with branch lines and junction dots. User's second correction: **"all the groups dont fall into each other … theyre all the same level still / dont make the tree diagram so flat"**.

**Lesson:** Same-depth group headers are still a flat tree. The user sees "Leadership & Routing" as the root — everything else should nest under it. Always check: **is any group a parent of the others?** Ask this before building, not after.

### Iteration 3: Nested hierarchy (accepted)

Three-level tree:

```
✦ Leadership & Routing ─── ROOT CANOPY
│
├── Ceres-1 (card)
├── Astraea-5 (card)
│
├── ▾ Security & Validation ─── BRANCH
│   ├── Vesta-4 (card)
│   └── Nemesis-128 (card)
│
├── ▾ Core Execution ─── BRANCH
│   ├── Metis-9 (card)
│   ├── Iris-7 (card)
│   └── Artemis-105 (card)
│
├── ▾ Infrastructure & Ops ─── BRANCH
│   └── Atalanta-36 (card)
│
├── ▾ Data & Memory ─── BRANCH
│   ├── Fortuna-19 (card)
│   ├── Mnemosyne-57 (card)
│   └── Klio-84 (card)
│
└── ▾ Creative & Interface ─── BRANCH
    ├── Kalliope-22 (card)
    ├── Harmonia-40 (card)
    └── Thalia-23 (card)
```

## Implementation key: Three visual depth levels

### Depth Level 1: Root Canopy (Leadership & Routing)

Distinct visual treatment from branches:
- Gradient background (`linear-gradient(135deg, #1c1440, var(--bg-card))`)
- Purple-tinted border (`#2a1f5c`)
- Elevated shadow (`0 0 30px rgba(124,92,252,.12)`)
- White accent chevron (not muted)
- Shows total agent count + child branch count

### Depth Level 2: Child Branches (each other group)

Nested 40px inside the root with a vertical spine line:
- Color-coded left border accent per group (red=security, green=core, blue=infra, purple=data, amber=creative)
- Each branch gets a junction dot + horizontal line on the vertical spine
- Individually collapsible (click header toggles agent cards)
- Standard `#1e2444` border + muted text for hierarchy perception

### Depth Level 3: Agent Cards

Nested 32px inside each branch:
- Each card has its own horizontal branch line from the spine
- Each card has a junction dot that glows accent on hover
- Cards contain: color dot + designation + nickname + role pill + tag row
- Expandable detail panel with 4-column grid (Psychology, Operations, Architecture, Failure)

## Collapse semantics

| Level | Collapsing… | Hides |
|-------|-------------|-------|
| Root → Root header | Click root header | All branches + all agents |
| Branch → Branch header | Click branch header | That branch's agents only |
| Card → Detail | Click card or `▸` | Detail panel (not the card itself) |

Each collapse is independent — the root can be open while specific branches are closed, etc.

## Search behavior

When searching (filter input), the tree should:
1. Hide cards that don't match (`display: none`)
2. If a branch has zero visible cards, hide that branch entirely
3. If the root canopy + all branches have zero visible agents, show an empty state
4. Do NOT collapse branches during search — just hide/show

## Pitfalls from this session

- **Initial flatness is the #1 risk.** The user will say "it's too flat" or "they're all the same level" if you don't identify the hierarchy root. Ask proactively: "Is Leadership & Routing the parent of the other groups?"
- **Branch lines must be visible against the background.** `#1e2444` on `#080a14` (dark mode) is readable. On lighter surfaces or light mode, increase contrast. Test the branch lines.
- **Cards need hover cues.** `translateX(2px)` + border color shift + junction dot glow makes the tree feel alive. Without hover feedback, cards feel like static text blocks.
- **Detail panel overflow.** When a card's detail opens, the parent list containers need their `max-height` updated (see the grow-parent-containers pattern in the main skill). Without this, the detail panel clips visually.
- **Staggered entrance animation order.** Root → branches → agents. Not agents → branches → root. The tree should unfold top-down, not leaf-first.

## The correction sequence (what NOT to do)

| Round | What was built | User reaction | Correction |
|-------|---------------|---------------|------------|
| 1 | Flat table | "make it a tree, make each agent a card" | Build tree |
| 2 | Flat peer-group tree | "dont make it so flat / all same level" | Add depth cues |
| 3 | Tree with connectors + branch lines | "all the groups dont fall into each other" | Identify root |

The user corrected the same core problem 3 times with escalating clarity. Starting with a hierarchical tree + root identification would have eliminated all 3 rounds.
