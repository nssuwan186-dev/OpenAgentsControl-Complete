#!/bin/bash
# OpenAgents Control - Dashboard
# Usage: ./open-dashboard.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f "evals/results/serve.sh" ]; then
    echo "📊 Opening dashboard at http://localhost:8000"
    echo "Press Ctrl+C to stop"
    echo ""
    cd evals/results && ./serve.sh
else
    echo "❌ Dashboard not found"
fi
