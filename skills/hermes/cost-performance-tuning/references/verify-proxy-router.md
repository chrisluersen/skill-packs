# Verifying a Proxy / Router Connection

After configuring Hermes Agent to use a custom proxy/router endpoint (`model.provider: custom`, `model.base_url: http://localhost:<port>/v1`), use this workflow to verify it's routing correctly.

## 1. Check the Router's Dashboard

Every router/proxy exposes some form of status. For Hermes-router the sibling tool:

```bash
hr status
```

Expected output shows provider health, latency, and key counts:

```
  Provider        Rating  Keys  Health   Latency
  ─────────────────────────────────────────────────
  groq            2       1     ✅ ok    204ms
  openrouter      2       1     ✅ ok    2549ms
  sambanova       2       1     ✅ ok    900ms
  cerebras        3       1     ✅ ok    222ms
  gemini          3       1     ✅ ok    642ms
```

Red flags: any provider showing `❌`, `exhausted`, or `0 keys ready`.

## 2. Direct API Test — Verify Routing

Send a simple request to the router's OpenAI-compatible endpoint and check which provider was selected:

```bash
curl -s http://localhost:8319/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-router-1" \
  -d '{"model":"hermes-router","messages":[{"role":"user","content":"say hi"}],"max_tokens":5}'
```

The `model` field in the response tells you which provider handled it:

```json
{
  "id": "g30zapv0LqCejMcPrt6YsAg",
  "model": "gemini-2.5-flash-lite",
  "choices": [{"message": {"content": "Hi! 👋"}}]
}
```

- A simple/cheap model (gemini-flash, cerebras) for easy requests → router is cost-aware ✅
- Router responds fast (<1s) → healthy ✅

On Windows with git-bash, use a Python script instead to avoid shell quoting issues:

```python
import requests
resp = requests.post(
    "http://localhost:8319/v1/chat/completions",
    headers={"Content-Type": "application/json", "Authorization": "Bearer sk-router-1"},
    json={"model": "hermes-router", "messages": [{"role":"user","content":"say hi"}], "max_tokens": 5}
)
data = resp.json()
print(f"Provider: {data.get('model')}")
print(f"Response: {data['choices'][0]['message']['content']}")
```

## 3. Watch Routing Decisions Live

Tail the router log to see every request's routing decision:

```bash
tail -f ~/.local/share/hermes-router/router.log
```

Live log shows decision-making:

```
2026-06-18 01:10:25 → Trying openrouter ...732f5b
2026-06-18 01:10:26   ✓ openrouter 200 (1021ms)
2026-06-18 01:11:28 → complexity=4 (simple) order=['cerebras','gemini','sambanova','groq','openrouter']
2026-06-18 01:11:28 → Trying cerebras ...5xxhfm
2026-06-18 01:11:28   ✓ cerebras 200 (210ms)
```

What to look for:
- **complexity=N (label)** — how the router classified the request (simple vs complex)
- **order=[...]** — which providers it considered, cheapest-first
- **Trying → ✓/✗** — whether each provider succeeded or failed
- **Auto-failover** — if a provider 429s (rate limit), router tries next in list

## 4. Verify Hermes Agent is Using the Router

Start a one-shot Hermes session with the router config to confirm it works end-to-end:

```bash
hermes chat -q "Say hello and tell me which model and provider you are using" \
  --provider custom --model hermes-router
```

If it replies, the route works. The response model field in the router log confirms which provider handled it.

## 5. Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Provider authentication failed: Unknown provider 'openai-compatible'` | Wrong provider name in config | Set `model.provider custom` |
| `patch` refused with security guard | Config file is guarded | Use `hermes config set` instead |
| File-mutation verifier warning after patch attempt | False positive from blocked patch | Ignore — config was never changed |
| Router responds with 404 on /v1/chat/completions | Router not running or wrong port | Check `hr status` or restart router |
| All providers showing ❌ in hr status | API keys missing or expired | Run `hr auth add <provider>` |