# Hermes Gateway API Server — Endpoint Reference

Base URL: `http://<host>:<port>` (default port 8080)

---

## Health Check
```
GET /health
```
**Response:**
```json
{ "status": "ok" }
```

---

## Chat (Non-Streaming)
```
POST /v1/chat
Content-Type: application/json

{
  "message": "string",
  "session_id": "string (optional)",
  "session_name": "string (optional)",
  "stream": false
}
```

**Response:**
```json
{
  "response": "string",
  "session_id": "string",
  "session_title": "string",
  "usage": { ... }
}
```

---

## Chat (Streaming / SSE)
```
POST /v1/chat
Content-Type: application/json

{
  "message": "string",
  "session_id": "string (optional)",
  "session_name": "string (optional)",
  "stream": true
}
```

**Response:** Server-Sent Events stream
```
data: {"delta": "partial response token"}

data: {"delta": "another token"}

...

data: {"response": "full final response", "session_id": "...", "usage": {...}}

data: [DONE]
```

**Parsing in shell:**
```bash
curl -N -X POST ... | while IFS= read -r line; do
  [[ "$line" =~ ^data:[[:space:]]*(.*)$ ]] || continue
  data="${BASH_REMATCH[1]}"
  [[ "$data" == "[DONE]" ]] && break
  echo "$data" | jq -r '.delta // .response // .'
done
```

---

## Sessions

### List Sessions
```
GET /v1/sessions
```

**Response:**
```json
[
  {
    "id": "20260115_143052_a1b2c3",
    "title": "My coding session",
    "created_at": "2026-01-15T14:30:52Z",
    "updated_at": "2026-01-15T14:45:10Z",
    "message_count": 12
  },
  ...
]
```

### Get Session
```
GET /v1/sessions/:id
```

**Response:** Full session with messages array.

### Delete Session
```
DELETE /v1/sessions/:id
```

---

## Error Responses

All endpoints may return:
```json
{ "error": "error description" }
```

HTTP status codes:
- `200` — Success
- `400` — Bad request (invalid JSON, missing fields)
- `401` — Unauthorized (if auth configured)
- `404` — Session not found
- `500` — Internal server error

---

## Authentication (Optional)

If gateway has auth enabled (API key):
```
Authorization: Bearer <API_KEY>
```

Add to requests:
```bash
curl -H "Authorization: Bearer $HERMES_API_KEY" ...
```

---

## WebSocket (Alternative)

For bidirectional real-time:
```
WS /v1/ws?session_id=<id>
```
Messages: JSON `{type: "user_message", content: "..."}`
Receives: JSON `{type: "assistant_delta", content: "..."}`, `{type: "assistant_complete", ...}`

---

## Rate Limits

Default: No hard limits. Configure in `config.yaml`:
```yaml
gateway:
  api_server:
    rate_limit:
      requests_per_minute: 60
      burst: 10
```

---

## CORS

Enabled by default for all origins. Configure:
```yaml
gateway:
  api_server:
    cors_origins:
      - "https://myapp.com"
```

---

## Full Example: cURL One-Shot
```bash
curl -s -X POST http://100.x.y.z:8080/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Write a Python hello world", "stream": false}' \
  | jq -r '.response'
```

## Full Example: Streaming with Session
```bash
# First message (creates session)
SESSION=$(curl -s -X POST http://100.x.y.z:8080/v1/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "stream": false}' | jq -r '.session_id')

# Continue session with streaming
curl -N -X POST http://100.x.y.z:8080/v1/chat \
  -H "Content-Type: application/json" \
  -d "{\"message\": \"Tell me more\", \"session_id\": \"$SESSION\", \"stream\": true}" |
while IFS= read -r line; do
  [[ "$line" =~ ^data:[[:space:]]*(.*)$ ]] || continue
  data="${BASH_REMATCH[1]}"
  [[ "$data" == "[DONE]" ]] && break
  echo "$data" | jq -r '.delta // .response // .'
done
```