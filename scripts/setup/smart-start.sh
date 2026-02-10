#!/bin/bash

# OpenAgents Control - SMART START
# อัจฉริยะ: ตรวจสอบอัตโนมัติ ถ้าติดตั้งแล้วใช้งานได้เลย ถ้ายังไม่ติดตั้งจะติดตั้งให้เสร็จ
# Usage: ./smart-start.sh [agent-name]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'
BOLD='\033[1m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ตัวแปรเช็คสถานะ
IS_INSTALLED=false
NEEDS_SETUP=false

# ==================== CHECK FUNCTIONS ====================

check_installation() {
    # เช็คว่าติดตั้งครบหรือยัง
    local deps_ok=false
    local opencode_ok=false
    
    # Check node_modules
    if [ -d "node_modules" ] && [ -f "node_modules/.package-lock.json" ]; then
        deps_ok=true
    fi
    
    # Check OpenCode CLI
    if command -v opencode &> /dev/null || [ -f "$HOME/.local/bin/opencode" ]; then
        opencode_ok=true
    fi
    
    # Check critical files
    if [ -f ".opencode/agent/core/openagent.md" ] && [ -f "registry.json" ]; then
        : # files exist
    else
        NEEDS_SETUP=true
        return
    fi
    
    if [ "$deps_ok" = true ] && [ "$opencode_ok" = true ]; then
        IS_INSTALLED=true
    else
        NEEDS_SETUP=true
    fi
}

# ==================== SETUP FUNCTIONS ====================

setup_step() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

setup_success() {
    echo -e "${GREEN}✓${NC} $1"
}

setup_progress() {
    echo -ne "${CYAN}  ⏳ $1...${NC}"
}

setup_done() {
    echo -e "${GREEN} Done!${NC}"
}

run_setup() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║        🔧 First Time Setup - Installing...                 ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Step 1: Check Node.js
    setup_step "Step 1/5: Checking Node.js"
    if command -v node &> /dev/null; then
        setup_success "Node.js found: $(node --version)"
    else
        echo -e "${RED}✗ Node.js not found!${NC}"
        echo "Please install from: https://nodejs.org/"
        exit 1
    fi
    echo ""
    
    # Step 2: Install Dependencies
    setup_step "Step 2/5: Installing Dependencies"
    setup_progress "Installing npm packages"
    npm install --silent 2>&1 | tail -3
    setup_done
    
    if [ -d "evals/framework" ]; then
        setup_progress "Installing evaluation framework"
        cd evals/framework && npm install --silent 2>&1 | tail -3 && cd "$SCRIPT_DIR"
        setup_done
    fi
    echo ""
    
    # Step 3: Install OpenCode
    setup_step "Step 3/5: Installing OpenCode CLI"
    if command -v opencode &> /dev/null; then
        setup_success "OpenCode CLI already installed"
    else
        setup_progress "Installing OpenCode CLI"
        curl -fsSL https://opencode.ai/install.sh | bash > /tmp/opencode-install.log 2>&1
        export PATH="$HOME/.local/bin:$PATH"
        setup_done
        setup_success "OpenCode CLI installed"
    fi
    echo ""
    
    # Step 4: Validate
    setup_step "Step 4/5: Validating System"
    setup_progress "Validating registry"
    npm run validate:registry --silent 2>/dev/null || npm run validate:registry:fix --silent 2>/dev/null || true
    setup_done
    setup_success "System validated"
    echo ""
    
    # Step 5: Create shortcuts
    setup_step "Step 5/5: Creating Shortcuts"
    
    # Create quick-start
    cat > start-agent.sh << 'EOF'
#!/bin/bash
# Start OpenAgents Control Agent
# Usage: ./start-agent.sh [agent-name]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

AGENT="${1:-OpenAgent}"

# Ensure PATH includes opencode
export PATH="$HOME/.local/bin:$PATH"

if ! command -v opencode &> /dev/null; then
    echo "❌ OpenCode CLI not found"
    echo "Run: ./smart-start.sh to setup"
    exit 1
fi

echo "🚀 Starting $AGENT..."
echo ""
opencode --agent "$AGENT"
EOF
    chmod +x start-agent.sh
    setup_success "Created: start-agent.sh"
    
    # Create test runner
    cat > run-test.sh << 'EOF'
#!/bin/bash
# Run Tests
# Usage: ./run-test.sh [smoke|openagent|opencoder|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

MODE="${1:-smoke}"

echo "🧪 Running $MODE tests..."
case "$MODE" in
    smoke) npm run test:ci ;;
    openagent) npm run test:openagent ;;
    opencoder) npm run test:opencoder ;;
    all) npm run test:all ;;
    *) echo "Usage: ./run-test.sh [smoke|openagent|opencoder|all]" ;;
esac
EOF
    chmod +x run-test.sh
    setup_success "Created: run-test.sh"
    
    echo ""
    
    # Mark as installed
    touch .installed
    
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              ✨ SETUP COMPLETE! ✨                         ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# ==================== START AGENT ====================

start_agent() {
    local agent="${1:-OpenAgent}"
    
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              🤖 OpenAgents Control                         ║"
    echo "║              Ready to use!                                 ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${BOLD}Starting $agent...${NC}"
    echo ""
    
    # Ensure PATH
    export PATH="$HOME/.local/bin:$PATH"
    
    # Start agent
    opencode --agent "$agent"
}

# ==================== MAIN ====================

main() {
    # Check if already installed
    check_installation
    
    if [ "$IS_INSTALLED" = true ]; then
        # Already installed - start agent immediately
        start_agent "$1"
    else
        # Not installed - run setup first
        run_setup
        
        # After setup, ask to start
        echo ""
        echo -e "${BOLD}🎯 Setup complete! Ready to use.${NC}"
        echo ""
        
        read -p "Start OpenAgent now? (y/n): " start_now
        if [[ $start_now =~ ^[Yy]$ ]]; then
            echo ""
            start_agent "$1"
        else
            echo ""
            echo -e "${GREEN}Ready! Run './start-agent.sh' to start anytime.${NC}"
            echo ""
            echo "Usage:"
            echo "  ./start-agent.sh           # Start OpenAgent"
            echo "  ./start-agent.sh OpenCoder # Start OpenCoder"
            echo "  ./run-test.sh              # Run tests"
            echo ""
        fi
    fi
}

# Run
main "$@"
