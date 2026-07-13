# Windows HTTP Testing Pitfalls

## IPv6 Resolution Delay (Python vs curl)

**Symptom:** Python `urllib` takes ~2000ms for a simple request, but `curl` returns in ~200ms. Same URL, same machine, same network.

**Root cause:** On Windows, `localhost` resolves to **IPv6 first** (`::1`). Python's `urllib` (and most stdlib HTTP clients) tries `::1`, waits for a timeout (~2s), then falls back to IPv4 (`127.0.0.1`) which succeeds instantly. The 2s is the IPv6 connection timeout, not the actual request latency.

**Fix:** Always use `127.0.0.1` instead of `localhost` in Python test clients on Windows.

```python
# ❌ Slow (2s delay on Windows)
resp = urllib.request.urlopen("http://localhost:8319/health")

# ✅ Fast (~28ms)
resp = urllib.request.urlopen("http://127.0.0.1:8319/health")
```

**Tools affected:** `urllib`, `requests`, `httpx`, `aiohttp` — any Python HTTP client that uses the default name resolution.

**Tools NOT affected:** `curl`, browsers, Node.js `fetch` — these resolve IPv4 directly on Windows.

## Diagnosis

```bash
# Time Python vs curl to confirm
time curl -s http://localhost:8319/health > /dev/null
time python3 -c "import urllib.request; urllib.request.urlopen('http://localhost:8319/health')"

# Compare with IPv4
time python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8319/health')"
```

If Python is ~2s slower with `localhost` but matches curl with `127.0.0.1`, you've hit the IPv6 fallback delay.

## Scope

This affects **all** Python HTTP testing on Windows, not just Cascade. Any test suite, health check, or monitoring script using `localhost` will have a ~2s false latency penalty on the first DNS resolution. Use `127.0.0.1` everywhere in Python test code.

## Why This Happens

Windows DNS resolution order: IPv6 (AAAA) → IPv4 (A). Python stdlib resolves both addresses and tries IPv6 first. The IPv6 connection attempt times out (no `::1` listener), and the fallback to IPv4 adds the timeout penalty. curl on Windows skips IPv6 when there's no IPv6 listener, so it goes straight to IPv4.

## Also affecting: Node.js

Node.js `fetch` and `http.request` resolve IPv4 directly by default on Windows, so they're immune to this issue. If you see Node.js being slow, look elsewhere.
