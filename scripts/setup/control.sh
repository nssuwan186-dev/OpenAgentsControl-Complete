#!/bin/bash

# OpenAgents Control - Control Center
# เมนูหลักสำหรับเลือกฟังก์ชันการทำงาน
# Usage: ./control.sh

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
clear_screen() {
    clear
}

print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║           🤖 OpenAgents Control Center                     ║"
    echo "║           Control Your AI Development                      ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_menu_item() {
    local num="$1"
    local icon="$2"
    local title="$3"
    local desc="$4"
    
    echo -e "  ${BOLD}${WHITE}${num}.${NC} ${icon} ${CYAN}${title}${NC}"
    echo -e "     ${desc}"
    echo ""
}

print_status() {
    echo -e "  ${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
}

print_info() {
    echo -e "  ${YELLOW}ℹ${NC} $1"
}

show_loading() {
    echo -ne "  ${CYAN}⏳ $1...${NC}"
}

# ==================== SYSTEM CHECK ====================
check_system() {
    local status=""
    
    # Check Node.js
    if command -v node &> /dev/null; then
        status+="${GREEN}●${NC} Node.js $(node --version 2>/dev/null | head -1)  "
    else
        status+="${RED}●${NC} Node.js missing  "
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        status+="${GREEN}●${NC} npm $(npm --version 2>/dev/null)  "
    else
        status+="${RED}●${NC} npm missing  "
    fi
    
    # Check OpenCode
    if command -v opencode &> /dev/null; then
        status+="${GREEN}●${NC} OpenCode CLI  "
    else
        status+="${RED}●${NC} OpenCode CLI missing  "
    fi
    
    # Check node_modules
    if [ -d "node_modules" ]; then
        status+="${GREEN}●${NC} Dependencies"
    else
        status+="${YELLOW}●${NC} Dependencies not installed"
    fi
    
    echo -e "$status"
}

# ==================== MENU FUNCTIONS ====================
show_main_menu() {
    clear_screen
    print_header
    
    echo -e "  ${MAGENTA}System Status:${NC}"
    check_system
    print_status
    echo ""
    
    echo -e "  ${BOLD}${WHITE}เลือกฟังก์ชันที่ต้องการ:${NC}"
    echo ""
    
    print_menu_item "1" "⚡" "Setup & Install" "ติดตั้ง dependencies และตั้งค่าระบบ"
    print_menu_item "2" "🤖" "Start AI Agent" "เริ่มใช้งาน AI Agent (OpenAgent/OpenCoder)"
    print_menu_item "3" "🧪" "Run Tests" "รันการทดสอบต่าง ๆ"
    print_menu_item "4" "🔍" "Validate System" "ตรวจสอบความถูกต้องของระบบ"
    print_menu_item "5" "📊" "Open Dashboard" "ดูผลการทดสอบและสถิติ"
    print_menu_item "6" "🏗️" "Project Info" "ดูโครงสร้างและข้อมูลโปรเจค"
    print_menu_item "7" "❓" "Help & Guide" "คู่มือการใช้งานและตัวอย่าง"
    print_menu_item "0" "🚪" "Exit" "ออกจากโปรแกรม"
    
    print_status
    echo ""
}

# ==================== FUNCTION 1: SETUP ====================
run_setup() {
    clear_screen
    print_header
    echo -e "  ${BOLD}${CYAN}⚡ Setup & Install${NC}"
    print_status
    echo ""
    
    echo -e "  ${YELLOW}เลือกการติดตั้ง:${NC}"
    echo ""
    echo "  1) ติดตั้ง Dependencies ทั้งหมด"
    echo "  2) ติดตั้ง OpenCode CLI"
    echo "  3) ตั้งค่า Context เริ่มต้น"
    echo "  4) กลับไปเมนูหลัก"
    echo ""
    
    read -p "  เลือก (1-4): " setup_choice
    
    case $setup_choice in
        1)
            echo ""
            show_loading "Installing npm packages"
            npm install 2>&1 | grep -v "^npm WARN" | tail -5
            print_success "Dependencies installed!"
            
            if [ -d "evals/framework" ]; then
                show_loading "Installing evals framework"
                cd evals/framework && npm install 2>&1 | tail -3 && cd "$SCRIPT_DIR"
                print_success "Evals framework installed!"
            fi
            ;;
        2)
            echo ""
            if command -v opencode &> /dev/null; then
                print_info "OpenCode CLI already installed"
            else
                show_loading "Installing OpenCode CLI"
                curl -fsSL https://opencode.ai/install.sh | bash
                print_success "OpenCode CLI installed!"
            fi
            ;;
        3)
            echo ""
            print_info "การตั้งค่า Context จะทำผ่าน OpenCode CLI"
            print_info "พิมพ์คำสั่ง: /add-context"
            echo ""
            read -p "  กด Enter เพื่อเปิด OpenCode..."
            if command -v opencode &> /dev/null; then
                opencode --agent OpenAgent
            else
                print_error "OpenCode CLI not installed"
                read -p "  กด Enter เพื่อกลับ..."
            fi
            return
            ;;
        4)
            return
            ;;
    esac
    
    echo ""
    read -p "  กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==================== FUNCTION 2: START AGENT ====================
run_agent() {
    clear_screen
    print_header
    echo -e "  ${BOLD}${CYAN}🤖 Start AI Agent${NC}"
    print_status
    echo ""
    
    if ! command -v opencode &> /dev/null; then
        print_error "OpenCode CLI not installed!"
        print_info "ไปที่เมนู Setup (1) เพื่อติดตั้งก่อน"
        echo ""
        read -p "  กด Enter เพื่อกลับ..."
        return
    fi
    
    echo -e "  ${YELLOW}เลือก Agent:${NC}"
    echo ""
    echo -e "  ${BOLD}1) OpenAgent${NC}    - Agent หลักสำหรับงานทั่วไป"
    echo "                    (เหมาะสำหรับ: เริ่มต้นใช้งาน, คำถาม, งานง่าย)"
    echo ""
    echo -e "  ${BOLD}2) OpenCoder${NC}    - Agent สำหรับพัฒนาโปรดักชัน"
    echo "                    (เหมาะสำหรับ: Features ซับซ้อน, Refactoring)"
    echo ""
    echo -e "  ${BOLD}3) SystemBuilder${NC} - สร้างระบบ AI แบบกำหนดเอง"
    echo "                    (เหมาะสำหรับ: สร้าง AI system ใหม่ทั้งระบบ)"
    echo ""
    echo "  4) กลับไปเมนูหลัก"
    echo ""
    
    read -p "  เลือก (1-4): " agent_choice
    
    case $agent_choice in
        1)
            clear_screen
            echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║${NC}  ${BOLD}OpenAgent Started${NC}                                          ${CYAN}║${NC}"
            echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo "พิมพ์คำสั่งของคุณ เช่น:"
            echo '  "Create a React todo list"'
            echo '  "Help me understand this codebase"'
            echo '  "Refactor this function"'
            echo ""
            echo "พิมพ์ 'exit' เพื่อออก"
            echo ""
            opencode --agent OpenAgent
            ;;
        2)
            clear_screen
            echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║${NC}  ${BOLD}OpenCoder Started${NC}                                          ${CYAN}║${NC}"
            echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo "พิมพ์คำสั่งของคุณ เช่น:"
            echo '  "Create user authentication system"'
            echo '  "Add real-time notifications"'
            echo '  "Refactor codebase to use DI"'
            echo ""
            echo "พิมพ์ 'exit' เพื่อออก"
            echo ""
            opencode --agent OpenCoder
            ;;
        3)
            clear_screen
            echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║${NC}  ${BOLD}SystemBuilder Started${NC}                                      ${CYAN}║${NC}"
            echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo "พิมพ์คำสั่งของคุณ เช่น:"
            echo '  "Create customer support AI system"'
            echo ""
            echo "พิมพ์ 'exit' เพื่อออก"
            echo ""
            opencode --agent SystemBuilder
            ;;
        4)
            return
            ;;
    esac
}

# ==================== FUNCTION 3: RUN TESTS ====================
run_tests() {
    clear_screen
    print_header
    echo -e "  ${BOLD}${CYAN}🧪 Run Tests${NC}"
    print_status
    echo ""
    
    if [ ! -d "evals/framework" ]; then
        print_error "Evaluation framework not found!"
        print_info "ไปที่เมนู Setup (1) เพื่อติดตั้งก่อน"
        echo ""
        read -p "  กด Enter เพื่อกลับ..."
        return
    fi
    
    echo -e "  ${YELLOW}เลือกการทดสอบ:${NC}"
    echo ""
    echo "  1) Smoke Test (เร็ว - ตรวจสอบพื้นฐาน)"
    echo "  2) OpenAgent Tests"
    echo "  3) OpenCoder Tests"
    echo "  4) Core Tests (ตรวจสอบส่วนหลัก)"
    echo "  5) Full Test Suite (ช้า - ครบถ้วน)"
    echo "  6) กลับไปเมนูหลัก"
    echo ""
    
    read -p "  เลือก (1-6): " test_choice
    
    case $test_choice in
        1)
            echo ""
            print_info "Running smoke tests..."
            npm run test:ci 2>&1 | tail -20
            ;;
        2)
            echo ""
            print_info "Running OpenAgent tests..."
            npm run test:openagent 2>&1 | tail -30
            ;;
        3)
            echo ""
            print_info "Running OpenCoder tests..."
            npm run test:opencoder 2>&1 | tail -30
            ;;
        4)
            echo ""
            print_info "Running core tests..."
            npm run test:core 2>&1 | tail -30
            ;;
        5)
            echo ""
            print_warning "This will take a while..."
            read -p "  ยืนยัน? (y/n): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                print_info "Running full test suite..."
                npm run test:all 2>&1 | tail -50
            else
                return
            fi
            ;;
        6)
            return
            ;;
    esac
    
    echo ""
    read -p "  กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==================== FUNCTION 4: VALIDATE ====================
run_validate() {
    clear_screen
    print_header
    echo -e "  ${BOLD}${CYAN}🔍 Validate System${NC}"
    print_status
    echo ""
    
    local has_error=0
    
    print_info "Checking Registry..."
    if npm run validate:registry --silent 2>/dev/null; then
        print_success "Registry is valid"
    else
        print_error "Registry validation failed"
        has_error=1
    fi
    
    echo ""
    print_info "Checking Critical Files..."
    local files=(
        ".opencode/agent/core/openagent.md:OpenAgent"
        ".opencode/agent/core/opencoder.md:OpenCoder"
        "registry.json:Registry"
        "package.json:Package Config"
    )
    
    for item in "${files[@]}"; do
        IFS=':' read -r file name <<< "$item"
        if [ -f "$file" ]; then
            print_success "$name"
        else
            print_error "$name - File missing!"
            has_error=1
        fi
    done
    
    echo ""
    print_info "Checking Context System..."
    if [ -d ".opencode/context" ]; then
        local context_count=$(find .opencode/context -name "*.md" | wc -l)
        print_success "Context system found ($context_count files)"
    else
        print_error "Context system not found!"
        has_error=1
    fi
    
    echo ""
    if [ $has_error -eq 0 ]; then
        echo -e "  ${GREEN}✓ System validation passed!${NC}"
    else
        echo -e "  ${RED}✗ System has issues!${NC}"
    fi
    
    echo ""
    read -p "  กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==================== FUNCTION 5: DASHBOARD ====================
run_dashboard() {
    clear_screen
    print_header
    echo -e "  ${BOLD}${CYAN}📊 Open Dashboard${NC}"
    print_status
    echo ""
    
    if [ -f "evals/results/serve.sh" ]; then
        print_info "Starting dashboard server..."
        print_info "Dashboard will be available at: http://localhost:8000"
        echo ""
        print_warning "กด Ctrl+C เพื่อหยุด server"
        echo ""
        cd evals/results && ./serve.sh
    else
        print_error "Dashboard not found!"
        print_info "ตรวจสอบว่า evaluation framework ถูกติดตั้งแล้ว"
        echo ""
        read -p "  กด Enter เพื่อกลับ..."
    fi
}

# ==================== FUNCTION 6: PROJECT INFO ====================
show_project_info() {
    clear_screen
    print_header
    echo -e "  ${BOLD}${CYAN}🏗️ Project Information${NC}"
    print_status
    echo ""
    
    echo -e "  ${BOLD}📋 Project:${NC} OpenAgents Control (OAC)"
    echo -e "  ${BOLD}📌 Version:${NC} $(cat VERSION 2>/dev/null || echo 'unknown')"
    echo -e "  ${BOLD}📁 Location:${NC} $SCRIPT_DIR"
    echo ""
    
    echo -e "  ${CYAN}${BOLD}โครงสร้างหลัก:${NC}"
    echo ""
    
    echo -e "  ${YELLOW}1. 🤖 Agents${NC} (สมอง AI)"
    echo "     ├─ OpenAgent      - Agent หลัก"
    echo "     ├─ OpenCoder      - พัฒนาโปรดักชัน"
    echo "     ├─ SystemBuilder  - สร้างระบบ AI"
    echo "     └─ Subagents      - Agent ย่อย"
    echo ""
    
    echo -e "  ${YELLOW}2. 📚 Context${NC} (คู่มือการเขียนโค้ด)"
    echo "     ├─ core/          - มาตรฐานพื้นฐาน"
    echo "     ├─ ui/            - Pattern UI/Web"
    echo "     └─ project/       - ข้อมูลเฉพาะโปรเจค"
    echo ""
    
    echo -e "  ${YELLOW}3. ⚡ Commands${NC} (คำสั่งพิเศษ)"
    echo "     ├─ /add-context   - เพิ่ม pattern"
    echo "     ├─ /commit        - Commit ฉลาด"
    echo "     └─ /test          - รันการทดสอบ"
    echo ""
    
    echo -e "  ${YELLOW}4. 🧪 Evals${NC} (ระบบทดสอบ)"
    echo "     └─ evals/         - Test suite"
    echo ""
    
    echo -e "  ${YELLOW}5. 📦 Registry${NC} (ฐานข้อมูล)"
    echo "     └─ registry.json  - รายการ Agents"
    echo ""
    
    # Count files
    local agent_count=$(find .opencode/agent -name "*.md" 2>/dev/null | wc -l)
    local context_count=$(find .opencode/context -name "*.md" 2>/dev/null | wc -l)
    local command_count=$(find .opencode/command -name "*.md" 2>/dev/null | wc -l)
    
    echo -e "  ${BOLD}สถิติ:${NC}"
    echo "     Agents:    $agent_count files"
    echo "     Context:   $context_count files"
    echo "     Commands:  $command_count files"
    echo ""
    
    echo ""
    read -p "  กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==================== FUNCTION 7: HELP ====================
show_help() {
    clear_screen
    print_header
    echo -e "  ${BOLD}${CYAN}❓ Help & Guide${NC}"
    print_status
    echo ""
    
    echo -e "  ${BOLD}🎯 เริ่มต้นใช้งาน:${NC}"
    echo ""
    echo "  1. ติดตั้งระบบ: เลือกเมนู 1 (Setup)"
    echo "  2. เริ่มใช้ Agent: เลือกเมนู 2 (Start AI Agent)"
    echo "  3. ขอให้ Agent ทำงาน: พิมพ์คำสั่งของคุณ"
    echo ""
    
    echo -e "  ${BOLD}💡 ตัวอย่างคำสั่ง:${NC}"
    echo ""
    echo '     "Create a React todo list"'
    echo '     "Help me refactor this code"'
    echo '     "Create API endpoint for users"'
    echo '     "Review this pull request"'
    echo ""
    
    echo -e "  ${BOLD}📚 คำสั่งพิเศษใน OpenCode:${NC}"
    echo ""
    echo "     /add-context    - เพิ่ม pattern ของคุณ"
    echo "     /commit         - Commit โค้ดแบบฉลาด"
    echo "     /test           - รันการทดสอบ"
    echo "     /context        - จัดการ context"
    echo ""
    
    echo -e "  ${BOLD}🔧 การแก้ไขปัญหา:${NC}"
    echo ""
    echo "  - OpenCode CLI not found → ใช้เมนู 1 เพื่อติดตั้ง"
    echo "  - Tests failed → ใช้เมนู 4 เพื่อตรวจสอบระบบ"
    echo "  - Registry error → รัน: npm run validate:registry:fix"
    echo ""
    
    echo ""
    read -p "  กด Enter เพื่อกลับไปเมนูหลัก..."
}

# ==================== MAIN LOOP ====================
main() {
    while true; do
        show_main_menu
        
        read -p "  เลือกหมายเลข (0-7): " choice
        
        case $choice in
            1) run_setup ;;
            2) run_agent ;;
            3) run_tests ;;
            4) run_validate ;;
            5) run_dashboard ;;
            6) show_project_info ;;
            7) show_help ;;
            0)
                clear_screen
                echo -e "${CYAN}"
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║                                                            ║"
                echo "║              👋 Thank you for using OAC!                   ║"
                echo "║                                                            ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                echo -e "${NC}"
                exit 0
                ;;
            *)
                echo ""
                print_error "Invalid choice!"
                sleep 1
                ;;
        esac
    done
}

# Start the program
main
