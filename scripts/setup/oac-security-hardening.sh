#!/bin/bash

# OpenAgents Control - Security Hardening Script
# นำแนวทางจาก OpenClaw Security Guide มาใช้กับ OAC
# รันบน VPS เท่านั้น ไม่ควรรันบนเครื่องหลัก

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

print_section() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# ==================== CHECK IF RUNNING AS ROOT ====================
if [ "$EUID" -ne 0 ]; then 
    print_error "This script must be run as root"
    print_info "Run: sudo bash oac-security-hardening.sh"
    exit 1
fi

# ==================== STEP 1: SYSTEM UPDATE ====================
step1_system_update() {
    print_section "Step 1/10: System Update"
    
    print_info "Updating system packages..."
    apt update && apt upgrade -y
    apt dist-upgrade -y
    
    print_success "System updated"
    echo ""
}

# ==================== STEP 2: CREATE DEDICATED USER ====================
step2_create_user() {
    print_section "Step 2/10: Create Dedicated OAC User"
    
    if id "oac" &>/dev/null; then
        print_info "User 'oac' already exists"
    else
        print_info "Creating user 'oac'..."
        adduser --disabled-password --gecos "" oac
        usermod -aG sudo oac
        print_success "User 'oac' created"
    fi
    
    echo ""
    print_warning "IMPORTANT: Set password for user 'oac'"
    echo "Run: sudo passwd oac"
    echo ""
}

# ==================== STEP 3: SSH HARDENING ====================
step3_ssh_hardening() {
    print_section "Step 3/10: SSH Hardening"
    
    print_info "Backing up SSH config..."
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
    
    print_info "Configuring SSH..."
    cat > /etc/ssh/sshd_config.d/oac-security.conf << 'EOF'
# OAC Security Settings
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
EOF
    
    # Test config
    if sshd -t; then
        systemctl reload sshd
        print_success "SSH hardened successfully"
    else
        print_error "SSH config test failed!"
        exit 1
    fi
    
    echo ""
    print_warning "Make sure you can SSH with key before disconnecting!"
    echo ""
}

# ==================== STEP 4: INSTALL FAIL2BAN ====================
step4_fail2ban() {
    print_section "Step 4/10: Install Fail2Ban"
    
    if command -v fail2ban-client &> /dev/null; then
        print_info "Fail2Ban already installed"
    else
        print_info "Installing Fail2Ban..."
        apt install fail2ban -y
        systemctl enable --now fail2ban
        print_success "Fail2Ban installed and enabled"
    fi
    
    # Configure for SSH
    cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF
    
    systemctl restart fail2ban
    print_success "Fail2Ban configured"
    echo ""
}

# ==================== STEP 5: CREATE SWAP FILE ====================
step5_swap() {
    print_section "Step 5/10: Create Swap File"
    
    if [ -f /swapfile ]; then
        print_info "Swap file already exists"
    else
        print_info "Creating 2GB swap file..."
        fallocate -l 2G /swapfile
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
        print_success "Swap file created"
    fi
    
    free -h | grep -i swap
    echo ""
}

# ==================== STEP 6: CONFIGURE UFW FIREWALL ====================
step6_ufw() {
    print_section "Step 6/10: Configure UFW Firewall"
    
    print_info "Installing UFW..."
    apt install ufw -y
    
    print_info "Configuring UFW..."
    ufw default deny incoming
    ufw default allow outgoing
    
    # Only allow SSH (will restrict further with Tailscale)
    ufw allow ssh
    
    # Enable firewall
    echo "y" | ufw enable
    
    print_success "UFW configured"
    ufw status verbose
    echo ""
}

# ==================== STEP 7: AUTO SECURITY UPDATES ====================
step7_auto_updates() {
    print_section "Step 7/10: Auto Security Updates"
    
    print_info "Installing unattended-upgrades..."
    apt install unattended-upgrades -y
    
    # Enable automatic updates
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF
    
    systemctl enable --now unattended-upgrades
    print_success "Auto-updates enabled"
    echo ""
}

# ==================== STEP 8: TIME SYNCHRONIZATION ====================
step8_ntp() {
    print_section "Step 8/10: Time Synchronization"
    
    print_info "Installing Chrony..."
    apt install chrony -y
    systemctl enable --now chrony
    
    print_success "Time sync enabled"
    chronyc tracking | head -5
    echo ""
}

# ==================== STEP 9: OAC PERMISSIONS ====================
step9_oac_permissions() {
    print_section "Step 9/10: Configure OAC Permissions"
    
    OAC_DIR="/root/OpenAgentsControl"
    
    if [ -d "$OAC_DIR" ]; then
        print_info "Setting up OAC permissions..."
        
        # Create oac config directory for user
        mkdir -p /home/oac/.opencode
        chown -R oac:oac /home/oac/.opencode
        
        # Copy OAC to user
        cp -r "$OAC_DIR" /home/oac/
        chown -R oac:oac /home/oac/OpenAgentsControl
        
        # Set proper permissions
        chmod -R 755 /home/oac/OpenAgentsControl
        chmod +x /home/oac/OpenAgentsControl/*.sh
        
        print_success "OAC configured for user 'oac'"
        print_info "OAC location: /home/oac/OpenAgentsControl/"
    else
        print_warning "OAC directory not found at $OAC_DIR"
    fi
    
    echo ""
}

# ==================== STEP 10: SECURITY AUDIT ====================
step10_audit() {
    print_section "Step 10/10: Security Audit"
    
    print_info "Running security checks..."
    
    # Check if root login is disabled
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config.d/oac-security.conf; then
        print_success "Root login disabled"
    else
        print_error "Root login not disabled!"
    fi
    
    # Check if password auth is disabled
    if grep -q "PasswordAuthentication no" /etc/ssh/sshd_config.d/oac-security.conf; then
        print_success "Password authentication disabled"
    else
        print_error "Password authentication not disabled!"
    fi
    
    # Check fail2ban
    if systemctl is-active --quiet fail2ban; then
        print_success "Fail2Ban is running"
    else
        print_error "Fail2Ban is not running!"
    fi
    
    # Check UFW
    if ufw status | grep -q "Status: active"; then
        print_success "UFW is active"
    else
        print_error "UFW is not active!"
    fi
    
    echo ""
}

# ==================== TAILSCALE SETUP GUIDE ====================
show_tailscale_guide() {
    print_section "📡 Tailscale Setup (Recommended)"
    
    echo -e "${YELLOW}Tailscale ช่วยให้เข้าถึง VPS ได้อย่างปลอดภัยโดยไม่ต้อง expose สู่ public${NC}"
    echo ""
    
    echo "ติดตั้ง Tailscale:"
    echo "  curl -fsSL https://tailscale.com/install.sh | sh"
    echo "  sudo tailscale up"
    echo ""
    
    echo "บนเครื่องของคุณ (client):"
    echo "  1. ติดตั้ง Tailscale"
    echo "  2. เปิด shields-up: sudo tailscale set --shields-up=true"
    echo "  3. SSH ผ่าน Tailscale IP แทน public IP"
    echo ""
    
    echo "เปลี่ยน UFW ให้รับเฉพาะ Tailscale:"
    echo "  sudo ufw allow in on tailscale0"
    echo "  sudo ufw delete allow ssh"
    echo ""
}

# ==================== DAILY SECURITY CHECK ====================
create_security_check_script() {
    print_section "Creating Daily Security Check"
    
    cat > /usr/local/bin/oac-security-check << 'EOF'
#!/bin/bash
# Daily security check for OAC

echo "=== OAC Security Check - $(date) ==="
echo ""

# Check disk usage
echo "Disk Usage:"
df -h / | tail -1

# Check memory
echo ""
echo "Memory:"
free -h | grep Mem

# Check services
echo ""
echo "Services Status:"
systemctl is-active sshd > /dev/null && echo "✓ SSH: Running" || echo "✗ SSH: Down"
systemctl is-active fail2ban > /dev/null && echo "✓ Fail2Ban: Running" || echo "✗ Fail2Ban: Down"

# Check failed logins
echo ""
echo "Failed SSH Attempts (24h):"
grep "Failed password" /var/log/auth.log 2>/dev/null | wc -l | xargs -I {} echo "  {} attempts"

echo ""
echo "==============================="
EOF

    chmod +x /usr/local/bin/oac-security-check
    
    # Add to cron
    echo "0 9 * * * root /usr/local/bin/oac-security-check" > /etc/cron.d/oac-security
    
    print_success "Security check script created"
    print_info "Run: /usr/local/bin/oac-security-check"
    echo ""
}

# ==================== COMPLETION ====================
show_completion() {
    print_section "✅ Security Hardening Complete!"
    
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║           🛡️  OAC VPS is now hardened!                    ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "สิ่งที่ทำไป:"
    echo "  ✓ System updated"
    echo "  ✓ Dedicated user 'oac' created"
    echo "  ✓ SSH hardened (no root, no password)"
    echo "  ✓ Fail2Ban installed"
    echo "  ✓ Swap file created"
    echo "  ✓ UFW firewall configured"
    echo "  ✓ Auto security updates enabled"
    echo "  ✓ Time synchronization enabled"
    echo "  ✓ OAC permissions configured"
    echo "  ✓ Security audit passed"
    echo ""
    
    print_warning "⚠️  IMPORTANT SECURITY NOTES:"
    echo ""
    echo "1. อย่าลืมตั้งค่า Tailscale (ดูคำแนะนำด้านบน)"
    echo "2. ทดสอบ SSH ด้วย key ก่อนปิดเซสชันนี้"
    echo "3. รัน 'sudo passwd oac' เพื่อตั้งรหัสผ่าน"
    echo "4. ใช้ user 'oac' แทน root ในการทำงาน"
    echo "5. ตรวจสอบ logs ด้วย: /usr/local/bin/oac-security-check"
    echo ""
    
    echo "คำสั่งที่ใช้บ่อย:"
    echo "  su - oac                          # เปลี่ยนเป็น user oac"
    echo "  /home/oac/OpenAgentsControl/start-agent.sh  # เริ่ม OAC"
    echo "  ufw status                        # ดูสถานะ firewall"
    echo "  fail2ban-client status            # ดูสถานะ fail2ban"
    echo ""
}

# ==================== MAIN ====================
main() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║     🛡️  OAC Security Hardening for VPS                    ║"
    echo "║     Based on OpenClaw Security Guide                       ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "⚠️  คำเตือน: สคริปต์นี้จะ:"
    echo "   - ปิด root login"
    echo "   - ปิด password authentication"
    echo "   - ติดตั้ง firewall"
    echo ""
    read -p "ดำเนินการต่อ? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "ยกเลิก"
        exit 0
    fi
    
    step1_system_update
    step2_create_user
    step3_ssh_hardening
    step4_fail2ban
    step5_swap
    step6_ufw
    step7_auto_updates
    step8_ntp
    step9_oac_permissions
    step10_audit
    show_tailscale_guide
    create_security_check_script
    show_completion
}

main
