#!/bin/bash
# OpenAgents Control - Quick Start
# Usage: ./start-agent.sh [agent-name]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

AGENT="${1:-OpenAgent}"

# Ensure PATH includes opencode
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

if ! command -v opencode &> /dev/null; then
    echo "❌ OpenCode CLI not found"
    exit 1
fi

echo "🚀 Starting $AGENT..."
echo ""
opencode --agent "$AGENT"
