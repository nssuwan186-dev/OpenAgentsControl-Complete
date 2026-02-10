#!/bin/bash
# OpenAgents Control - Test Runner
# Usage: ./run-test.sh [smoke|openagent|opencoder|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-smoke}"

echo "🧪 Running $MODE tests..."
echo ""

case "$MODE" in
    smoke)
        npm run test:ci
        ;;
    openagent)
        npm run test:openagent
        ;;
    opencoder)
        npm run test:opencoder
        ;;
    all)
        npm run test:all
        ;;
    *)
        echo "Usage: ./run-test.sh [smoke|openagent|opencoder|all]"
        echo ""
        echo "Modes:"
        echo "  smoke     - Quick smoke test (fast)"
        echo "  openagent - Test OpenAgent"
        echo "  opencoder - Test OpenCoder"
        echo "  all       - Full test suite (slow)"
        exit 1
        ;;
esac
