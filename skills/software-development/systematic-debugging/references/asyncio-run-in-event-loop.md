# `asyncio.run()` Inside a Running Event Loop

## The Bug

```python
async def main():
    manager = HermesFleetManager()
    # ...
    if sys.argv[1] == "--health":
        checks = asyncio.run(manager.fleet_health_snapshot())  # ❌
```

This fails with:
```
RuntimeError: asyncio.run() cannot be called from a running event loop
```

## Root Cause

`asyncio.run()` creates a **new** event loop. When called from inside `async def main()` (which is already running in an event loop via `asyncio.run(main())` at the module level), you get nested event loops — which Python explicitly forbids.

## Fix

```python
async def main():
    manager = HermesFleetManager()
    # ...
    if sys.argv[1] == "--health":
        checks = await manager.fleet_health_snapshot()  # ✅
```

## Rule

Only **one** `asyncio.run()` call per process: the bootstrap at `if __name__ == "__main__":`. Every other async call inside an `async def` should use `await`.

| Pattern | Correct? |
|---------|----------|
| `if __name__: asyncio.run(main())` | ✅ Bootstrap |
| Inside `async def main()`: `await fn()` | ✅ Normal |
| Inside `async def main()`: `asyncio.run(fn())` | ❌ Nested loop |
| Sync function calling async: `asyncio.run(fn())` | ✅ Correct usage (but only from sync context) |

## Pattern: CLI Flag Dispatch in Async

Common in async CLI tools with flag-based dispatch (fleet-manager, wiki tools):

```python
async def main():
    manager = HermesFleetManager()
    if sys.argv[1] == "--health":
        checks = await manager.fleet_health_snapshot()   # await
    elif sys.argv[1] == "--interactive":
        while True:
            result = await manager.process_request(...)   # await
    # Sync methods don't need await:
    elif sys.argv[1] == "--status":
        manager.print_status()                            # no await

if __name__ == "__main__":
    asyncio.run(main())    # ← only asyncio.run() call
```

If you find yourself adding `asyncio.run()` inside an `async def`, you're almost certainly wrong. Replace with `await`.
