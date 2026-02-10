#!/bin/bash

# OpenAgents Control - Universal Start Script
# สคริปต์เดียวที่เปิดใช้งานระบบทั้งหมดได้
# Usage: ./start.sh [mode] [options]
#
# Modes:
#   dev         - โหมดพัฒนา ( Development mode)
#   test        - รันการทดสอบทั้งหมด
#   validate    - ตรวจสอบความถูกต้องของระบบ
#   agent       - เริ่มใช้งาน AI Agent
#   dashboard   - เปิด Dashboard ดูผลการทดสอบ
#   full        - รันทุกอย่าง (ติดตั้ง+ตรวจสอบ+ทดสอบ)
#   help        - แสดงวิธีใช้งาน

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ==================== LOGO & HEADER ====================
print_logo() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║           🚀 OpenAgents Control (OAC)                      ║"
    echo "║           One Script to Rule Them All                      ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# ==================== SYSTEM INFO ====================
show_system_info() {
    print_section "📊 System Information"
    
    echo -e "${MAGENTA}Project:${NC} OpenAgents Control"
    echo -e "${MAGENTA}Version:${NC} $(cat VERSION 2>/dev/null || echo 'unknown')"
    echo -e "${MAGENTA}Location:${NC} $SCRIPT_DIR"
    echo ""
    
    # Check Node.js
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✓ Node.js:${NC} $(node --version)"
    else
        echo -e "${RED}✗ Node.js:${NC} Not installed"
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        echo -e "${GREEN}✓ npm:${NC} $(npm --version)"
    else
        echo -e "${RED}✗ npm:${NC} Not installed"
    fi
    
    # Check OpenCode CLI
    if command -v opencode &> /dev/null; then
        echo -e "${GREEN}✓ OpenCode CLI:${NC} Installed"
    else
        echo -e "${YELLOW}⚠ OpenCode CLI:${NC} Not installed (will install if needed)"
    fi
    
    # Check bun
    if command -v bun &> /dev/null; then
        echo -e "${GREEN}✓ Bun:${NC} $(bun --version)"
    else
        echo -e "${YELLOW}⚠ Bun:${NC} Not installed (optional)"
    fi
    
    echo ""
}

# ==================== PROJECT STRUCTURE INFO ====================
show_project_structure() {
    print_section "🏗️  Project Structure"
    
    echo -e "${BOLD}OAC ประกอบด้วยส่วนหลัก ๆ ดังนี้:${NC}"
    echo ""
    
    echo -e "${CYAN}1. 🤖 Agents (สมองของ AI)${NC}"
    echo "   ├─ OpenAgent     → Agent หลักสำหรับงานทั่วไป"
    echo "   ├─ OpenCoder     → Agent สำหรับพัฒนาโปรดักชัน"
    echo "   ├─ SystemBuilder → สร้างระบบ AI แบบกำหนดเอง"
    echo "   └─ Subagents     → Agent ย่อย (Coder, Tester, Reviewer, etc.)"
    echo ""
    
    echo -e "${CYAN}2. 📚 Context System (คู่มือการเขียนโค้ด)${NC}"
    echo "   ├─ core/         → มาตรฐานพื้นฐาน"
    echo "   ├─ ui/           → Pattern สำหรับ UI/Web"
    echo "   ├─ project/      → ข้อมูลเฉพาะโปรเจค"
    echo "   └─ project-intelligence/ → Pattern ของทีมคุณ"
    echo ""
    
    echo -e "${CYAN}3. ⚡ Commands (คำสั่งพิเศษ)${NC}"
    echo "   ├─ /add-context  → เพิ่ม pattern ของคุณ"
    echo "   ├─ /commit       → Commit โค้ดแบบฉลาด"
    echo "   ├─ /test         → รันการทดสอบ"
    echo "   └─ /validate     → ตรวจสอบระบบ"
    echo ""
    
    echo -e "${CYAN}4. 🧪 Evaluation Framework (ระบบทดสอบ)${NC}"
    echo "   └─ evals/        → Test suite และผลการทดสอบ"
    echo ""
    
    echo -e "${CYAN}5. 📦 Registry (ฐานข้อมูล Agents)${NC}"
    echo "   └─ registry.json → รายการ Agents และ Commands ทั้งหมด"
    echo ""
}

# ==================== INSTALL DEPENDENCIES ====================
install_dependencies() {
    print_section "📦 Installing Dependencies"
    
    # Check if node_modules exists
    if [ -d "node_modules" ]; then
        print_info "Dependencies already installed"
        echo "   Run with --force to reinstall"
        return 0
    fi
    
    print_info "Installing npm packages..."
    npm install
    print_success "Dependencies installed"
    
    # Install evals framework dependencies
    if [ -d "evals/framework" ]; then
        print_info "Installing evaluation framework..."
        cd evals/framework
        npm install
        cd "$SCRIPT_DIR"
        print_success "Evaluation framework installed"
    fi
}

# ==================== VALIDATE SYSTEM ====================
validate_system() {
    print_section "🔍 Validating System"
    
    local has_error=0
    
    # Validate registry
    print_info "Checking registry..."
    if npm run validate:registry --silent 2>/dev/null; then
        print_success "Registry is valid"
    else
        print_error "Registry validation failed"
        has_error=1
    fi
    
    # Check critical files
    print_info "Checking critical files..."
    local critical_files=(
        ".opencode/agent/core/openagent.md"
        ".opencode/agent/core/opencoder.md"
        "registry.json"
        "package.json"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Found: $file"
        else
            print_error "Missing: $file"
            has_error=1
        fi
    done
    
    # Check if opencode is installed
    if ! command -v opencode &> /dev/null; then
        print_warning "OpenCode CLI not found"
        echo "   Install with: curl -fsSL https://opencode.ai/install.sh | bash"
    fi
    
    if [ $has_error -eq 0 ]; then
        print_success "System validation passed!"
    else
        print_error "System validation failed!"
        exit 1
    fi
}

# ==================== RUN TESTS ====================
run_tests() {
    print_section "🧪 Running Tests"
    
    echo -e "${CYAN}เลือกรูปแบบการทดสอบ:${NC}"
    echo "  1) Smoke Test (เร็ว - ตรวจสอบพื้นฐาน)"
    echo "  2) Core Tests (ปานกลาง)"
    echo "  3) Full Test Suite (ช้า - ครบถ้วน)"
    echo "  4) เลือก Agent ที่จะทดสอบ"
    echo ""
    
    read -p "เลือก (1-4): " test_choice
    
    case $test_choice in
        1)
            print_info "Running smoke tests..."
            npm run test:ci
            ;;
        2)
            print_info "Running core tests..."
            npm run test:core
            ;;
        3)
            print_info "Running full test suite..."
            npm run test:all
            ;;
        4)
            echo ""
            echo "เลือก Agent:"
            echo "  1) OpenAgent"
            echo "  2) OpenCoder"
            read -p "เลือก (1-2): " agent_choice
            
            if [ "$agent_choice" == "1" ]; then
                npm run test:openagent
            else
                npm run test:opencoder
            fi
            ;;
        *)
            print_warning "Invalid choice, running smoke tests..."
            npm run test:ci
            ;;
    esac
    
    print_success "Tests completed!"
}

# ==================== START AGENT ====================
start_agent() {
    print_section "🤖 Starting AI Agent"
    
    # Check if opencode is installed
    if ! command -v opencode &> /dev/null; then
        print_error "OpenCode CLI not installed!"
        echo ""
        echo "ติดตั้ง OpenCode CLI ก่อน:"
        echo "  curl -fsSL https://opencode.ai/install.sh | bash"
        echo ""
        echo "หรือรันสคริปต์นี้ด้วยโหมด 'install':"
        echo "  ./start.sh install"
        exit 1
    fi
    
    echo -e "${CYAN}เลือก Agent ที่ต้องการใช้งาน:${NC}"
    echo ""
    echo "  ${BOLD}1) OpenAgent${NC} - Agent หลักสำหรับงานทั่วไป"
    echo "     เหมาะสำหรับ: เริ่มต้นใช้งาน, คำถามทั่วไป, งานง่าย ๆ"
    echo ""
    echo "  ${BOLD}2) OpenCoder${NC} - Agent สำหรับพัฒนาโปรดักชัน"
    echo "     เหมาะสำหรับ: Features ซับซ้อน, Refactoring, งาน Production"
    echo ""
    echo "  ${BOLD}3) SystemBuilder${NC} - สร้างระบบ AI แบบกำหนดเอง"
    echo "     เหมาะสำหรับ: สร้าง AI system ใหม่ทั้งระบบ"
    echo ""
    
    read -p "เลือก Agent (1-3): " agent_choice
    
    case $agent_choice in
        1)
            print_info "Starting OpenAgent..."
            print_info "พิมพ์คำสั่งของคุณ หรือ 'exit' เพื่อออก"
            echo ""
            opencode --agent OpenAgent
            ;;
        2)
            print_info "Starting OpenCoder..."
            print_info "พิมพ์คำสั่งของคุณ หรือ 'exit' เพื่อออก"
            echo ""
            opencode --agent OpenCoder
            ;;
        3)
            print_info "Starting SystemBuilder..."
            print_info "พิมพ์คำสั่งของคุณ หรือ 'exit' เพื่อออก"
            echo ""
            opencode --agent SystemBuilder
            ;;
        *)
            print_warning "Invalid choice, starting OpenAgent..."
            opencode --agent OpenAgent
            ;;
    esac
}

# ==================== START DASHBOARD ====================
start_dashboard() {
    print_section "📊 Starting Test Dashboard"
    
    if [ -f "evals/results/serve.sh" ]; then
        print_info "Opening dashboard..."
        print_info "Dashboard will be available at: http://localhost:8000"
        echo ""
        cd evals/results && ./serve.sh
    else
        print_error "Dashboard not found!"
        print_info "ตรวจสอบว่า evaluation framework ถูกติดตั้งแล้ว"
    fi
}

# ==================== FULL SETUP ====================
full_setup() {
    print_section "🚀 FULL SETUP MODE"
    print_info "นี่คือการติดตั้งและตรวจสอบระบบทั้งหมดในครั้งเดียว"
    echo ""
    
    # Step 1: Install
    install_dependencies
    
    # Step 2: Validate
    validate_system
    
    # Step 3: Run tests
    echo ""
    read -p "ต้องการรันการทดสอบหลังติดตั้งไหม? (y/n): " run_tests
    if [[ $run_tests =~ ^[Yy]$ ]]; then
        run_tests
    fi
    
    # Step 4: Show completion
    print_section "✨ Setup Complete!"
    
    echo -e "${GREEN}ระบบพร้อมใช้งานแล้ว!${NC}"
    echo ""
    echo "คำสั่งที่ใช้บ่อย:"
    echo "  ./start.sh agent      → เริ่มใช้งาน AI Agent"
    echo "  ./start.sh test       → รันการทดสอบ"
    echo "  ./start.sh validate   → ตรวจสอบระบบ"
    echo "  ./start.sh dashboard  → ดูผลการทดสอบ"
    echo ""
    echo "หรือใช้ OpenCode CLI โดยตรง:"
    echo "  opencode --agent OpenAgent"
    echo "  opencode --agent OpenCoder"
    echo ""
}

# ==================== INSTALL OPENCODE ====================
install_opencode() {
    print_section "📥 Installing OpenCode CLI"
    
    if command -v opencode &> /dev/null; then
        print_success "OpenCode CLI already installed"
        opencode --version 2>/dev/null || echo "   (version check failed)"
        return 0
    fi
    
    print_info "Installing OpenCode CLI..."
    curl -fsSL https://opencode.ai/install.sh | bash
    
    if command -v opencode &> /dev/null; then
        print_success "OpenCode CLI installed successfully!"
    else
        print_error "Installation failed"
        print_info "ลองติดตั้งด้วยตนเองที่: https://opencode.ai/docs"
        exit 1
    fi
}

# ==================== QUICK START GUIDE ====================
show_quick_start() {
    print_section "🎯 Quick Start Guide"
    
    echo -e "${BOLD}เริ่มต้นใช้งาน OAC ใน 3 ขั้นตอน:${NC}"
    echo ""
    
    echo -e "${CYAN}ขั้นตอนที่ 1:${NC} ติดตั้งระบบ"
    echo "  ./start.sh full"
    echo ""
    
    echo -e "${CYAN}ขั้นตอนที่ 2:${NC} เริ่มใช้งาน Agent"
    echo "  ./start.sh agent"
    echo ""
    
    echo -e "${CYAN}ขั้นตอนที่ 3:${NC} ขอให้ Agent ทำงาน"
    echo '  > "Create a React todo list"'
    echo '  > "Help me understand this codebase"'
    echo '  > "Refactor this function"'
    echo ""
    
    echo -e "${BOLD}คำสั่งอื่น ๆ ที่มีประโยชน์:${NC}"
    echo ""
    echo "  ${YELLOW}เพิ่ม Pattern ของคุณ:${NC}"
    echo "    opencode"
    echo "    > /add-context"
    echo ""
    echo "  ${YELLOW}ดูโครงสร้างโปรเจค:${NC}"
    echo "    ./start.sh structure"
    echo ""
    echo "  ${YELLOW}รันการทดสอบ:${NC}"
    echo "    ./start.sh test"
    echo ""
    echo "  ${YELLOW}ตรวจสอบระบบ:${NC}"
    echo "    ./start.sh validate"
    echo ""
}

# ==================== SHOW HELP ====================
show_help() {
    print_logo
    
    echo -e "${BOLD}วิธีใช้งาน:${NC} ./start.sh [mode] [options]"
    echo ""
    
    echo -e "${CYAN}Modes:${NC}"
    echo "  ${BOLD}full${NC}        - ติดตั้ง+ตรวจสอบ+ทดสอบ ทั้งหมดในครั้งเดียว"
    echo "  ${BOLD}dev${NC}         - โหมดพัฒนา (ติดตั้ง dependencies)"
    echo "  ${BOLD}install${NC}     - ติดตั้ง OpenCode CLI"
    echo "  ${BOLD}validate${NC}    - ตรวจสอบความถูกต้องของระบบ"
    echo "  ${BOLD}test${NC}        - รันการทดสอบทั้งหมด"
    echo "  ${BOLD}agent${NC}       - เริ่มใช้งาน AI Agent"
    echo "  ${BOLD}dashboard${NC}   - เปิด Dashboard ดูผลการทดสอบ"
    echo "  ${BOLD}structure${NC}   - แสดงโครงสร้างโปรเจค"
    echo "  ${BOLD}info${NC}        - แสดงข้อมูลระบบ"
    echo "  ${BOLD}quickstart${NC}  - แสดงคู่มือเริ่มต้นใช้งาน"
    echo "  ${BOLD}help${NC}        - แสดงวิธีใช้งานนี้"
    echo ""
    
    echo -e "${CYAN}Examples:${NC}"
    echo "  ./start.sh full              # ติดตั้งทั้งหมด"
    echo "  ./start.sh agent             # เริ่มใช้งาน Agent"
    echo "  ./start.sh test              # รันการทดสอบ"
    echo "  ./start.sh validate          # ตรวจสอบระบบ"
    echo ""
    
    echo -e "${CYAN}Options:${NC}"
    echo "  --force    - บังคับติดตั้งใหม่ (สำหรับ dev mode)"
    echo ""
}

# ==================== MAIN ====================
main() {
    print_logo
    
    # Get mode from argument
    MODE="${1:-help}"
    
    case "$MODE" in
        full)
            full_setup
            ;;
        dev)
            show_system_info
            install_dependencies
            validate_system
            print_success "Development environment ready!"
            ;;
        install)
            install_opencode
            ;;
        validate)
            show_system_info
            validate_system
            ;;
        test)
            run_tests
            ;;
        agent)
            start_agent
            ;;
        dashboard)
            start_dashboard
            ;;
        structure)
            show_project_structure
            ;;
        info)
            show_system_info
            show_project_structure
            ;;
        quickstart)
            show_quick_start
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown mode: $MODE"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
