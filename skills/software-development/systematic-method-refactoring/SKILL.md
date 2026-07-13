---
name: systematic-method-refactoring
description: "Extract large methods into focused helpers using AST-guided analysis, phased extraction, and compile verification. Reduces cognitive load without changing behavior."
version: 1.0.0
author: Hermes Agent (from fleet-manager.py refactor 2026-07-03)
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [refactoring, code-quality, method-extraction, python, ast, decomposition]
    related_skills: [simplify-code, systematic-debugging, test-driven-development, safe-large-file-editing]
---

# Systematic Method Refactoring

**Extract large methods into focused helpers.** No behavior changes — only structural decomposition. Reduces method sizes by 30-60% per pass, removes dead code, and surfaces implicit structure that inline code hides.

## When to Use

Use this approach when:

- A method exceeds ~100 lines and contains multiple distinct responsibilities
- You can identify cohesive blocks within a method by their comments (`# ── section ──`, `# Stage N`, `# Step X`)
- The user says "refactor X" without specifying an exact approach
- AST analysis shows a method >150 lines that other methods don't call

**Do NOT use this when:**

- The code needs behavioral changes (bug fixes, feature additions) — use TDD instead
- The method is short (<60 lines) and already focused — splitting it adds indirection without clarity
- The refactor target is a third-party dependency or code you don't own

## The Process

### Phase 0 — Scan with AST

Before reading any code, identify the biggest methods.

```python
import ast, os

path = "<target_file.py>"
with open(path) as f:
    tree = ast.parse(f.read())

for node in ast.iter_child_nodes(tree):
    if isinstance(node, ast.ClassDef):
        print(f"=== {node.name} ===")
        for n in node.body:
            if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef)):
                lines = n.end_lineno - n.lineno + 1
                print(f"  {lines:4d} - {n.name}")
```

This prints method sizes sorted by definition order. Look for:
- **Spikes**: methods >100 lines (hard to reason about)
- **Notable**: methods >60 lines (worth inspecting but may be cohesive)
- **Flattened distribution**: many methods ~30-50 lines each (healthy)

Also identify **dead code** — methods defined but never called elsewhere in the class:

```python
def find_dead_methods(source_path, class_name):
    with open(source_path) as f:
        tree = ast.parse(f.read())

    defined = set()
    called = set()

    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            defined.add(node.name)
        elif isinstance(node, ast.Call):
            if isinstance(node.func, ast.Attribute) and isinstance(node.func.value, ast.Name):
                called.add(node.func.attr)  # self.<method>()
            elif isinstance(node.func, ast.Name):
                called.add(node.func.id)    # bare method call

    return defined - called - set(('__init__', '__len__'))
```

### Phase 1 — Read & Understand

Read the FULL target method (not paginated — use `execute_code` + `open()` for methods over 2000 chars or files over 2000 lines). Mark the blocks:

- **Comments as section boundaries**: `# ── X ──`, `# Stage N`, `# Step Y` — these are the author's natural extraction boundaries
- **Distinct responsibilities**: payload construction, parsing, dispatch, error handling, result formatting
- **Duplicated patterns**: same keyword lists, same dict shapes, same try/except blocks appearing twice

### Phase 2 — Plan Extraction

Pick extraction targets by type:

| Type | Example | Extraction Signature |
|------|---------|---------------------|
| **Payload builder** | Constructing a dict from params | `_build_X(a, b, c) -> dict` — can be `@staticmethod` |
| **Conditional branch** | A large if/elif block that handles one case | `_handle_X_case(a, b) -> return_type` |
| **Evaluation/parsing** | Extracting values from a response | `_parse_X(response) -> dict` — can be `@staticmethod` |
| **Side-effectful action** | Publishing events, dispatching to agents, logging | `_do_X(a, b) -> result` — async method |
| **Result construction** | Building a multi-field return dict | `_format_X_result(a, b, c) -> dict` |
| **Keyword/constant list** | Duplicate inline lists across methods | Module-level `KW_*` constant |

For each target, verify it's **cohesive** (all lines serve one purpose) and **callable** (the extracted method has a clear entry point and return contract).

### Phase 3 — Insert Helpers First

Always insert the helper methods BEFORE the method they serve — Python doesn't require forward declarations within a class, but inserting before keeps discovery linear for future readers.

```python
# ── target helpers ────────────────────────────────────
def _build_X(self, a, b):
    """..."""
    pass

async def _do_Y(self, a, b):
    """..."""
    pass

def _target_method(self, input):
    """..."""
    # Now calls _build_X and _do_Y
```

**Insert with `patch`:** use `old_string` that matches the annotation line before the target method (`async def _target_method(...)`), and prepend the helpers. Keep the `old_string` unique by including 1-2 context lines above the target.

### Phase 4 — Replace Inline Blocks

After helpers are inserted, use `patch` to replace each inline block with its helper call. Patterns:

**Simple replacement** (no indentation change):
```
old_string: "            payload = {\n                \"key\": a,\n            }"
new_string: "            payload = self._build_X(a)"
```

**Multi-line block replacement** (if/else branch):
```
old_string: "            if condition:\n                # long block\n                ...\n            else:\n                # alternative\n                ..."
new_string: "            result = await self._do_Y(a, b)\n            if result < 0:\n                return ..."
```

**⚠️ Pitfall: `patch` with deeply nested Python** — methods at ≥12-space indentation (4+ levels) cause the fuzzy matcher to match the wrong sibling block. For deeply nested replacements, use `execute_code` with Python `open()` + `readlines()` + slice assignment instead of `patch`.

### Phase 5 — Verify Compilation

After EVERY extraction phase:

```python
import py_compile
py_compile.compile(path, doraise=True)
```

Also verify method sizes changed as expected:

```python
import ast
expected_reductions = {
    'target_method': (171, 117),  # (before, after)
}
with open(path) as f:
    tree = ast.parse(f.read())
for node in ast.walk(tree):
    if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
        if node.name in expected_reductions:
            actual = node.end_lineno - node.lineno + 1
            before, after = expected_reductions[node.name]
            assert actual == after, f"{node.name}: expected {after}, got {actual}"
```

### Iterate

One extraction phase per method. Don't refactor two methods in one round — compile-verify between them to catch cross-method issues (dead variables, accidental name shadowing).

## What to Extract — Decision Table

| Inline code | Extract when | Signature pattern |
|-------------|-------------|-------------------|
| Dict construction from method params | Used ≥2 times in the loop body | `@staticmethod _build_X(...) -> dict` |
| Duplicate keyword list | Appears in ≥2 methods side by side | Module-level `KW_X = [...]` |
| Conditional branch >15 lines | Branch logic is self-contained | `_handle_X(...)` returns early or sets state |
| Error/edge-case handler >10 lines | Same pattern repeated (`if x is None: default`) | `_resolve_X(x, default) -> value` |
| Return-dict construction >5 lines | Same keys assembled in multiple places | `_format_X(...) -> dict` |
| Try/except with rollback >10 lines | Cleanup logic is complex | `_safe_X(...)` with standardized error return |
| Log + publish pattern >3 lines | Same log message + publish to same topic | `_log_and_publish(topic, msg, data)` |

## Dead Code Removal

After extraction, check if any of the extracted helpers replaced code that also left behind a standalone helper that is now unused. Run the dead-code AST scan from Phase 0 again. If a method was extracted but never called (common when extraction discovers the helper was already dead), remove it.

**Verification:** After removal, convince yourself with a second AST scan that the only removed names are the ones you intended.

## Keyword Constant Extraction

This is a special case of Phase 3-4 that deserves its own pattern:

1. **Collect all inline lists** from the methods that use them (`[ "wiki", "look up in the wiki", ...]`)
2. **Name each list** by purpose: `KW_CLASSIFY_WIKI`, `KW_ROUTE_WIKI`, `KW_QA_CODE`
3. **Insert constants** at module level near the other routing constants (after `ALL_PATTERNS`)
4. **Replace each inline list** with its constant name across ALL methods that use it (classify, route, predict, needs_qa)
5. **Verify no stray inline lists** remain — `grep` for `\"wiki\"` inside method bodies should now only hit unique strings, not the 6-element lists

**Benefit:** One edit updates all callers. Adding `"hermes"` to `KW_ROUTE_WIKI` instantly affects `_route_to_worker`, `_predict_routing`, and `_needs_qa` — zero drift.

## Pitfalls

- **Don't extract too fine.** A 6-line method that returns a dict from 3 fields is an abstraction boundary, not a helper. Extract blocks that represent real conceptual units.
- **Don't rename variables during extraction.** Keep exact variable names from the original method. Renaming is a separate refactoring pass.
- **Don't extract across method boundaries.** Each extraction phase affects ONE method. Extracting a helper used by two methods belongs in a separate pass.
- **`patch` on deeply nested Python triggers indentation corruption.** At ≥12-space indent, use `execute_code` + Python `open()` + `str.replace()` instead.
- **Compile verify after EVERY phase.** One bad `patch` on Python code that creates a `SyntaxError` blocks all subsequent patches. Catch it immediately.
- **Dead code from extraction is common.** After replacing inline blocks with helper calls, the helpers may now be the only callers of an existing utility. Run the dead-code scan again.
- **Keyword constant names must be unique across the module.** Don't prefix all with `KW_` — use domain prefixes (`KW_CLASSIFY_`, `KW_ROUTE_`, `KW_QA_`) to distinguish lists used by different methods even when they contain the same words.

## References

| Reference | What It Covers |
|-----------|---------------|
| `references/fleet-manager-phases-a-d.md` | Full worked example — extracting 8 pattern handlers, 3 QA stage helpers, 18 keyword constants, and 3 Ceres retry helpers from fleet-manager.py (69 → 80 methods, 10 → 5 methods >100 lines, avg 37 → 33 lines) |

## Related Skills

- `simplify-code` — parallel 3-agent review of RECENT changes, not systematic extraction
- `test-driven-development` — behavior-changing refactoring via RED-GREEN-REFACTOR
- `safe-large-file-editing` — file corruption prevention for large Python files
- `systematic-debugging` — bug-finding, not restructuring
