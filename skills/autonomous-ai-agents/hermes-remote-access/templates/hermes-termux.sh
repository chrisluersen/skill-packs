#!/data/data/com.termux/files/usr/bin/bash
# Hermes Termux Client — Streaming + Session Support
# Usage:
#   ./hermes-termux.sh "message"                    # One-shot
#   ./hermes-termux.sh -s <session_id> "message"    # Continue session
#   ./hermes-termux.sh -l                           # List sessions
#   ./hermes-termux.sh -n "session name" "message"  # Named session

set -euo pipefail

# ─── CONFIG ──────────────────────────────────────────────
HERMES_URL="${HERMES_URL:-http://100.x.y.z:8080}"  # Set via env or edit
DEFAULT_SESSION="${HERMES_SESSION:-}"
# ─────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") [options] "message"

Options:
  -s, --session ID     Continue existing session
  -n, --name NAME      Name new session (implies new session)
  -l, --list           List recent sessions
  -h, --help           Show this help

Environment:
  HERMES_URL           Gateway URL (default: http://100.x.y.z:8080)
  HERMES_SESSION       Default session ID to continue

Examples:
  $(basename "$0") "hello"
  $(basename "$0") -n "coding" "build a REST API"
  $(basename "$0") -s abc123 "continue where we left off"
  HERMES_URL=http://100.1.2.3:8080 $(basename "$0") "hi"
EOF
}

list_sessions() {
  curl -s "$HERMES_URL/v1/sessions" | jq -r '.[] | "\(.id)  \(.title // "untitled")  \(.updated_at)"'
}

send_message() {
  local msg="$1"
  local session_id="${2:-}"
  local session_name="${3:-}"

  local payload
  if [[ -n "$session_id" ]]; then
    payload=$(jq -n --arg msg "$msg" --arg sid "$session_id" '{message: $msg, session_id: $sid, stream: false}')
  elif [[ -n "$session_name" ]]; then
    payload=$(jq -n --arg msg "$msg" --arg name "$session_name" '{message: $msg, session_name: $name, stream: false}')
  else
    payload=$(jq -n --arg msg "$msg" '{message: $msg, stream: false}')
  fi

  curl -s -X POST "$HERMES_URL/v1/chat" \
    -H "Content-Type: application/json" \
    -d "$payload" | jq -r '.response // .error // .'
}

send_message_stream() {
  local msg="$1"
  local session_id="${2:-}"
  local session_name="${3:-}"

  local payload
  if [[ -n "$session_id" ]]; then
    payload=$(jq -n --arg msg "$msg" --arg sid "$session_id" '{message: $msg, session_id: $sid, stream: true}')
  elif [[ -n "$session_name" ]]; then
    payload=$(jq -n --arg msg "$msg" --arg name "$session_name" '{message: $msg, session_name: $name, stream: true}')
  else
    payload=$(jq -n --arg msg "$msg" '{message: $msg, stream: true}')
  fi

  curl -s -N -X POST "$HERMES_URL/v1/chat" \
    -H "Content-Type: application/json" \
    -d "$payload" |
  while IFS= read -r line; do
    [[ "$line" =~ ^data:[[:space:]]*(.*)$ ]] || continue
    data="${BASH_REMATCH[1]}"
    [[ "$data" == "[DONE]" ]] && break
    echo "$data" | jq -r '.delta // .response // .error // .' 2>/dev/null || echo "$data"
  done
}

# ─── MAIN ────────────────────────────────────────────────
SESSION_ID=""
SESSION_NAME=""
STREAM=false
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--session) SESSION_ID="$2"; shift 2 ;;
    -n|--name)    SESSION_NAME="$2"; shift 2 ;;
    -l|--list)    LIST_ONLY=true; shift ;;
    --stream)     STREAM=true; shift ;;
    -h|--help)    usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    *) break ;;
  esac
done

MSG="${*:-}"

if [[ "$LIST_ONLY" == true ]]; then
  list_sessions
  exit 0
fi

if [[ -z "$MSG" ]]; then
  echo "Error: No message provided" >&2
  usage
  exit 1
fi

if [[ "$STREAM" == true ]]; then
  send_message_stream "$MSG" "$SESSION_ID" "$SESSION_NAME"
else
  send_message "$MSG" "$SESSION_ID" "$SESSION_NAME"
fi