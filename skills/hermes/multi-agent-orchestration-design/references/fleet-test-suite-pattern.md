# Fleet Test Suite Pattern

Tests for `fleet-manager.py` live in `test_fleet_manager.py` (same directory).
53 tests across 15 test classes, all passing in ~0.7s.

## Importing Hyphenated Python Files

`fleet-manager.py` has a hyphen — Python can't `import fleet_manager` from it.
Use `importlib.util.spec_from_file_location()`:

```python
import importlib.util
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent.resolve()
spec = importlib.util.spec_from_file_location(
    "fleet_manager", str(SCRIPT_DIR / "fleet-manager.py")
)
fleet_manager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fleet_manager)

# Access names from the loaded module
HermesFleetManager = fleet_manager.HermesFleetManager
AgentProfile = fleet_manager.AgentProfile
FleetState = fleet_manager.FleetState
```

The `from fleet_manager import X` syntax won't work because there's no
`fleet_manager.py` file on the import path. Always use the module-object
attribute access pattern.

**Don't rename the file.** `fleet-manager.py` is the established name in
the fleet agent's system prompts (loaded via `hermes cron run`). Renaming
it would break the cron schedule.

## Test Strategy

Layer tests by component, not by phase. Each component gets a test class
that covers its state machine, edge cases, and transitions:

| Component | Class | What It Covers |
|-----------|-------|----------------|
| PipelineState | `TestPipelineState` | trace_id, duration, error flag |
| FleetState | `TestFleetState` | defaults, cb_state persistence |
| Circuit breaker | `TestCircuitBreaker` | 7 tests: init, persistence, CLOSED, OPEN, HALF_OPEN transitions, threshold, pruning |
| Bulkhead | `TestBulkhead` | 6 tests: tier mapping for every agent, acquire/release cycle |
| GraSP | `TestGraSPRecovery` | substitute map targets are valid profiles |
| Idempotency | `TestIdempotency` | first call, duplicate detection, cross-agent isolation |
| Routing cache | `TestRoutingCache` | initialization, cache hit returns pattern, expired entries detected |
| Tool gateway | `TestToolGateway` | maintenance mode toggle |
| Config | `TestConfigConsistency` | TOOL_LEVELS, tier disjointness, naming convention |
| Smoke | `TestFleetManagerSmoke` | subprocess --status, --cb-status, --maintenance on|off |

## Subprocess Smoke Tests

Each test runs `fleet-manager.py` as a subprocess, so every call is a fresh
instance. Maintenance mode and circuit breaker state do NOT persist across
calls — test individual invocations, not sequencing.

```python
def _run(self, *args: str, timeout: int = 30) -> tuple[int, str]:
    script = str(SCRIPT_DIR / "fleet-manager.py")
    cmd = [sys.executable, script, *args]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    return result.returncode, result.stdout
```

## Running Tests

```bash
# All tests
python ~/AppData/Local/hermes/scripts/test_fleet_manager.py -v

# Specific component
python -m unittest test_fleet_manager.TestCircuitBreaker -v

# Smoke tests only
python -m unittest test_fleet_manager.TestFleetManagerSmoke -v
```

## Adding a Test

1. Create a test class in `test_fleet_manager.py`
2. Create a `HermesFleetManager` instance in `setUp` via `make_manager()`
3. Test individual methods — don't test subprocess dispatch paths
4. For async methods, use `asyncio.run()` 
5. For state-machine tests, manipulate the internal state directly,
   then verify the behavior

## Pitfalls

1. **Module name ≠ filename.** Importing `fleet-manager.py` as `fleet_manager`
   works via importlib but `from fleet_manager import X` will fail at
   import time because the module isn't on the path. Use
   `fleet_manager.HermesFleetManager` after loading.

2. **Each test class gets a new manager.** Avoid sharing state between
   tests within a class — `setUp` creates a fresh instance.

3. **Subprocess tests are independent.** Don't test `--maintenance on`
   then verify by running `--maintenance` in the same test — each process
   starts fresh. Verify the output of the single command.
