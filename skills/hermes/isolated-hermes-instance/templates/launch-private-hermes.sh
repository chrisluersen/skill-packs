#!/usr/bin/env bash
# launch-private-hermes.sh — Start isolated Hermes instance for model testing
# Usage: ./launch-private-hermes.sh [hermes-args...]
#
# Place at ~/.hermes-private/launch-private-hermes.sh
# Make executable: chmod +x ~/.hermes-private/launch-private-hermes.sh

set -euo pipefail

HERMES_PRIVATE_HOME="${HERMES_PRIVATE_HOME:-$HOME/.hermes-private}"
CONFIG="${CONFIG:-$HERMES_PRIVATE_HOME/config.yaml}"

if [[ ! -f "$CONFIG" ]]; then
    echo "ERROR: Config not found: $CONFIG"
    echo "Create it from templates/isolated-config.yaml first"
    exit 1
fi

if [[ ! -d "$HERMES_PRIVATE_HOME" ]]; then
    echo "ERROR: Isolated home not found: $HERMES_PRIVATE_HOME"
    exit 1
fi

export HERMES_HOME="$HERMES_PRIVATE_HOME"
export HERMES_CONFIG="$CONFIG"

# Show which instance we're launching
echo "🚀 Launching isolated Hermes instance"
echo "   Home: $HERMES_HOME"
echo "   Config: $CONFIG"
echo ""

exec hermes --config "$CONFIG" "$@"