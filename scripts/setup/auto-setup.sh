#!/bin/bash

# OpenAgents Control - AUTO SETUP
# รันครั้งเดียว ติดตั้งทั้งหมดอัตโนมัติ พร้อมใช้งานทันที
# Usage: ./auto-setup.sh

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

# ==================== UI FUNCTIONS ====================
print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║           🚀 OpenAgents Control Auto Setup                 ║"
    echo "║           Installing everything automatically...           ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}▶ $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_progress() {
    echo -ne "${CYAN}  ⏳ $1...${NC}"
}

print_done() {
    echo -e "${GREEN} Done!${NC}"
}

# ==================== STEP 1: CHECK SYSTEM ====================
step1_check_system() {
    print_step "Step 1/7: Checking System Requirements"
    
    # Check Node.js
    print_progress "Checking Node.js"
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_done
        print_success "Node.js found: $NODE_VERSION"
    else
        print_error "Node.js not found!"
        echo ""
        echo "Please install Node.js first:"
        echo "  https://nodejs.org/ (version 14 or higher)"
        exit 1
    fi
    
    # Check npm
    print_progress "Checking npm"
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        print_done
        print_success "npm found: $NPM_VERSION"
    else
        print_error "npm not found!"
        exit 1
    fi
    
    echo ""
}

# ==================== STEP 2: INSTALL DEPENDENCIES ====================
step2_install_deps() {
    print_step "Step 2/7: Installing Dependencies"
    
    if [ -d "node_modules" ]; then
        print_info "Dependencies already installed, skipping..."
    else
        print_progress "Installing npm packages (this may take a few minutes)"
        npm install --silent 2>&1 | tail -5
        print_done
        print_success "Main dependencies installed"
    fi
    
    # Install evals framework
    if [ -d "evals/framework" ]; then
        if [ -d "evals/framework/node_modules" ]; then
            print_info "Evals framework already installed, skipping..."
        else
            print_progress "Installing evaluation framework"
            cd evals/framework
            npm install --silent 2>&1 | tail -3
            cd "$SCRIPT_DIR"
            print_done
            print_success "Evaluation framework installed"
        fi
    fi
    
    echo ""
}

# ==================== STEP 3: INSTALL OPENCODE CLI ====================
step3_install_opencode() {
    print_step "Step 3/7: Installing OpenCode CLI"
    
    if command -v opencode &> /dev/null; then
        print_info "OpenCode CLI already installed, skipping..."
        opencode --version 2>/dev/null || true
    else
        print_progress "Installing OpenCode CLI"
        curl -fsSL https://opencode.ai/install.sh | bash > /tmp/opencode-install.log 2>&1
        
        # Source the updated PATH
        export PATH="$HOME/.local/bin:$PATH"
        
        if command -v opencode &> /dev/null; then
            print_done
            print_success "OpenCode CLI installed successfully"
        else
            print_error "Installation may have failed"
            print_info "Please install manually: https://opencode.ai/docs"
        fi
    fi
    
    echo ""
}

# ==================== STEP 4: VALIDATE REGISTRY ====================
step4_validate_registry() {
    print_step "Step 4/7: Validating System Registry"
    
    print_progress "Checking registry integrity"
    if npm run validate:registry --silent 2>/dev/null; then
        print_done
        print_success "Registry validation passed"
    else
        print_done
        print_info "Registry needs fixing, auto-fixing..."
        npm run validate:registry:fix --silent 2>/dev/null || true
        print_success "Registry fixed"
    fi
    
    echo ""
}

# ==================== STEP 5: CHECK CRITICAL FILES ====================
step5_check_files() {
    print_step "Step 5/7: Checking Critical Files"
    
    local files=(
        ".opencode/agent/core/openagent.md:OpenAgent"
        ".opencode/agent/core/opencoder.md:OpenCoder"
        ".opencode/context:Context System"
        "registry.json:Registry"
        "package.json:Package Config"
    )
    
    for item in "${files[@]}"; do
        IFS=':' read -r file name <<< "$item"
        if [ -e "$file" ]; then
            print_success "$name"
        else
            print_error "$name - MISSING!"
        fi
    done
    
    echo ""
}

# ==================== STEP 6: CREATE LAUNCHER SCRIPT ====================
step6_create_launcher() {
    print_step "Step 6/7: Creating Quick Launch Scripts"
    
    # Create quick start script
    cat > quick-start.sh << 'EOF'
#!/bin/bash
# Quick Start Script for OpenAgents Control
# Usage: ./quick-start.sh [agent-name]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

AGENT="${1:-OpenAgent}"

echo "🚀 Starting $AGENT..."
echo ""

if ! command -v opencode &> /dev/null; then
    export PATH="$HOME/.local/bin:$PATH"
fi

opencode --agent "$AGENT"
EOF
    chmod +x quick-start.sh
    print_success "Created: quick-start.sh"
    
    # Create test runner script
    cat > run-tests.sh << 'EOF'
#!/bin/bash
# Test Runner for OpenAgents Control
# Usage: ./run-tests.sh [mode]

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
        echo "Unknown mode: $MODE"
        echo "Usage: ./run-tests.sh [smoke|openagent|opencoder|all]"
        exit 1
        ;;
esac
EOF
    chmod +x run-tests.sh
    print_success "Created: run-tests.sh"
    
    # Create dashboard script
    cat > open-dashboard.sh << 'EOF'
#!/bin/bash
# Open Test Dashboard
# Usage: ./open-dashboard.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f "evals/results/serve.sh" ]; then
    echo "📊 Opening dashboard at http://localhost:8000"
    echo "Press Ctrl+C to stop"
    cd evals/results && ./serve.sh
else
    echo "❌ Dashboard not found"
    echo "Make sure evaluation framework is installed"
fi
EOF
    chmod +x open-dashboard.sh
    print_success "Created: open-dashboard.sh"
    
    echo ""
}

# ==================== STEP 7: COMPLETION ====================
step7_completion() {
    print_step "Step 7/7: Setup Complete!"
    
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║              ✨ SETUP COMPLETE! ✨                         ║"
    echo "║                                                            ║"
    echo "║         OpenAgents Control is ready to use!                ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${BOLD}🎯 เริ่มใช้งานได้ทันที:${NC}"
    echo ""
    echo -e "  ${CYAN}1. เริ่มใช้งาน AI Agent:${NC}"
    echo "     ./quick-start.sh              # ใช้ OpenAgent (เริ่มต้น)"
    echo "     ./quick-start.sh OpenCoder    # ใช้ OpenCoder (พัฒนา)"
    echo ""
    echo -e "  ${CYAN}2. รันการทดสอบ:${NC}"
    echo "     ./run-tests.sh smoke          # ทดสอบพื้นฐาน (เร็ว)"
    echo "     ./run-tests.sh openagent      # ทดสอบ OpenAgent"
    echo "     ./run-tests.sh all            # ทดสอบทั้งหมด (ช้า)"
    echo ""
    echo -e "  ${CYAN}3. ดูผลการทดสอบ:${NC}"
    echo "     ./open-dashboard.sh           # เปิด dashboard"
    echo ""
    echo -e "  ${CYAN}4. หรือใช้ OpenCode CLI โดยตรง:${NC}"
    echo "     opencode --agent OpenAgent"
    echo "     opencode --agent OpenCoder"
    echo ""
    
    echo -e "${BOLD}💡 ตัวอย่างคำสั่งที่จะใช้:${NC}"
    echo ""
    echo '  "Create a React todo list with TypeScript"'
    echo '  "Help me understand this codebase"'
    echo '  "Refactor this function to use async/await"'
    echo '  "Create API endpoint for user authentication"'
    echo ""
    
    echo -e "${BOLD}📚 คำสั่งพิเศษใน OpenCode:${NC}"
    echo ""
    echo "  /add-context    - เพิ่ม pattern การเขียนโค้ดของคุณ"
    echo "  /commit         - Commit โค้ดแบบฉลาด"
    echo "  /test           - รันการทดสอบ"
    echo "  /validate       - ตรวจสอบระบบ"
    echo ""
    
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Auto-start prompt
    read -p "ต้องการเริ่มใช้งาน OpenAgent ตอนนี้เลยไหม? (y/n): " start_now
    
    if [[ $start_now =~ ^[Yy]$ ]]; then
        echo ""
        echo "🚀 Starting OpenAgent..."
        echo ""
        ./quick-start.sh
    else
        echo ""
        echo -e "${GREEN}พร้อมใช้งานแล้ว! รันคำสั่ง ./quick-start.sh เมื่อต้องการใช้งาน${NC}"
        echo ""
    fi
}

# ==================== MAIN ====================
main() {
    print_header
    
    # Record start time
    START_TIME=$(date +%s)
    
    # Run all steps
    step1_check_system
    step2_install_deps
    step3_install_opencode
    step4_validate_registry
    step5_check_files
    step6_create_launcher
    step7_completion
    
    # Calculate duration
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    MINUTES=$((DURATION / 60))
    SECONDS=$((DURATION % 60))
    
    echo -e "${CYAN}⏱️  Setup completed in ${MINUTES}m ${SECONDS}s${NC}"
    echo ""
}

# Run
main
