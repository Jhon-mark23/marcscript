#!/bin/bash
# ============================================================
# MARCSCRIPT VPN - Universal Installer
# Compatible: Ubuntu 18.04+, Debian 10+
# License: MIT
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Get VPS IP
MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)

# Script directory
SCRIPT_DIR="/usr/local/marcscript"
GITHUB_RAW="https://raw.githubusercontent.com/Jhon-mark23/marcscript/main"

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}   ███╗   ███╗ █████╗ ██████╗  ██████╗███████╗${NC}            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}   ████╗ ████║██╔══██╗██╔══██╗██╔════╝██╔════╝${NC}            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}   ██╔████╔██║███████║██████╔╝██║     ███████╗${NC}            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}   ██║╚██╔╝██║██╔══██║██╔══██╗██║     ╚════██║${NC}            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}   ██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╗███████║${NC}            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝${NC}            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}     🚀 SSH • Xray • WebSocket • SSL • Proxy${NC}              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root (sudo su)${NC}"
    exit 1
fi

# ============================================================
# STEP 0: Cleanup Existing Services
# ============================================================
cleanup_services() {
    echo -e "${YELLOW}🧹 Cleaning up existing services...${NC}"
    echo ""
    
    # Stop all services
    echo -e "  Stopping services..."
    systemctl stop nginx 2>/dev/null || true
    systemctl stop stunnel4 2>/dev/null || true
    systemctl stop squid 2>/dev/null || true
    systemctl stop xray 2>/dev/null || true
    systemctl stop ws-proxy 2>/dev/null || true
    
    # Kill processes on ports (except SSH port 22)
    echo -e "  Freeing up ports (keeping SSH port 22)..."
    for port in 80 443 3128 8000 8080 8082 8443 8445 8446 8888; do
        fuser -k ${port}/tcp 2>/dev/null && echo -e "    Freed port ${port}" || true
    done
    
    # Remove old configs
    echo -e "  Cleaning old configurations..."
    rm -f /etc/nginx/conf.d/marcscript.conf 2>/dev/null
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null
    rm -f /etc/stunnel/stunnel.conf 2>/dev/null
    
    # Reset UFW but keep SSH
    if command -v ufw &>/dev/null; then
        echo -e "  Resetting firewall (keeping SSH)..."
        ufw --force reset >/dev/null 2>&1
        ufw allow 22/tcp >/dev/null 2>&1
        echo "y" | ufw enable >/dev/null 2>&1 || true
    fi
    
    sleep 2
    echo -e "${GREEN}✅ Cleanup complete${NC}"
    echo ""
}

# ============================================================
# Ensure SSH Password Authentication
# ============================================================
ensure_ssh_auth() {
    echo -e "${YELLOW}🔐 Ensuring SSH Password Authentication...${NC}"
    
    # Backup SSH config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak.$(date +%s) 2>/dev/null
    
    # Enable password authentication
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    
    # Enable root login with password
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    
    # Enable ChallengeResponse
    sed -i 's/^#*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    
    # Enable PubkeyAuthentication (keep both)
    sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    # Set KbdInteractiveAuthentication
    grep -q "^KbdInteractiveAuthentication" /etc/ssh/sshd_config || echo "KbdInteractiveAuthentication yes" >> /etc/ssh/sshd_config
    sed -i 's/^KbdInteractiveAuthentication no/KbdInteractiveAuthentication yes/' /etc/ssh/sshd_config
    
    # Set UsePAM
    grep -q "^UsePAM" /etc/ssh/sshd_config || echo "UsePAM yes" >> /etc/ssh/sshd_config
    sed -i 's/^UsePAM no/UsePAM yes/' /etc/ssh/sshd_config
    
    # Restart SSH
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
    
    # Verify SSH is still running
    sleep 2
    if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
        echo -e "${GREEN}✅ SSH Password Authentication enabled (Port 22)${NC}"
    else
        echo -e "${RED}❌ SSH failed to restart! Restoring backup...${NC}"
        cp /etc/ssh/sshd_config.bak.* /etc/ssh/sshd_config 2>/dev/null
        systemctl restart ssh 2>/dev/null
        echo -e "${YELLOW}⚠️  SSH restored. Check manually: nano /etc/ssh/sshd_config${NC}"
    fi
    echo ""
}

# ============================================================
# Check OS Compatibility
# ============================================================
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    else
        echo -e "${RED}❌ Cannot detect OS${NC}"
        exit 1
    fi
    
    case $OS in
        ubuntu|debian)
            echo -e "${GREEN}✅ OS: $OS $VER (Supported)${NC}"
            ;;
        *)
            echo -e "${RED}❌ Unsupported OS: $OS${NC}"
            echo -e "${YELLOW}This script supports Ubuntu 18.04+ and Debian 10+${NC}"
            exit 1
            ;;
    esac
}

# ============================================================
# Create Directory Structure
# ============================================================
create_directories() {
    echo -e "${YELLOW}📁 Creating MarcScript directories...${NC}"
    mkdir -p $SCRIPT_DIR/{lib,ssh,xray,services,tools,menu}
    mkdir -p /etc/xray /var/log/xray /etc/marcscript
    mkdir -p /home/vps/public_html
    echo -e "${GREEN}✅ Directories created${NC}"
    echo ""
}

# ============================================================
# Download File from GitHub
# ============================================================
download_file() {
    local file=$1
    local dest=$2
    
    if [ -z "$dest" ]; then
        dest="$SCRIPT_DIR/$file"
    fi
    
    mkdir -p "$(dirname "$dest")"
    
    if wget -q "$GITHUB_RAW/$file" -O "$dest" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $file"
        chmod +x "$dest" 2>/dev/null
        return 0
    else
        echo -e "  ${YELLOW}⚠${NC} Failed to download: $file"
        return 1
    fi
}

# ============================================================
# Download All Required Files
# ============================================================
download_files() {
    echo -e "${YELLOW}📥 Downloading MarcScript files...${NC}"
    echo ""
    
    # Core files
    download_file "menu.sh"
    download_file "lib/common.sh"
    download_file "lib/packages.sh"
    download_file "lib/firewall.sh"
    download_file "lib/banner.sh"
    
    # SSH module
    download_file "ssh/ssh-setup.sh"
    download_file "ssh/ssh-user.sh"
    
    # Xray module
    download_file "xray/xray-install.sh"
    download_file "xray/xray-config.sh"
    download_file "xray/xray-user.sh"
    
    # Services module
    download_file "services/stunnel.sh"
    download_file "services/websocket.sh"
    download_file "services/squid.sh"
    download_file "services/nginx.sh"
    
    # Tools
    download_file "tools/add-ssh.sh"
    download_file "tools/add-vmess.sh"
    download_file "tools/add-vless.sh"
    download_file "tools/add-trojan.sh"
    download_file "tools/del-user.sh"
    download_file "tools/check.sh"
    
    echo ""
    
    # Create symlinks for tools
    for tool in add-ssh add-vmess add-vless add-trojan del-user check; do
        if [ -f "$SCRIPT_DIR/tools/$tool.sh" ]; then
            ln -sf "$SCRIPT_DIR/tools/$tool.sh" "/usr/local/bin/$tool" 2>/dev/null
        fi
    done
    
    # Menu symlink
    if [ -f "$SCRIPT_DIR/menu.sh" ]; then
        ln -sf "$SCRIPT_DIR/menu.sh" "/usr/local/bin/menu" 2>/dev/null
    fi
    
    # Also create menu command from ssh-user.sh
    if [ -f "$SCRIPT_DIR/ssh/ssh-user.sh" ]; then
        ln -sf "$SCRIPT_DIR/ssh/ssh-user.sh" "/usr/local/bin/ssh-manage" 2>/dev/null
    fi
    
    echo -e "${GREEN}✅ Files downloaded${NC}"
    echo ""
}

# ============================================================
# Install Packages
# ============================================================
install_base_packages() {
    echo -e "${YELLOW}📦 Installing required packages...${NC}"
    echo ""
    
    export DEBIAN_FRONTEND=noninteractive
    apt update -y >/dev/null 2>&1
    
    PACKAGES="openssh-server stunnel4 squid nginx curl wget lsof net-tools jq openssl cron socat netcat-openbsd dnsutils screen xz-utils unzip tar ufw apache2-utils"
    
    for pkg in $PACKAGES; do
        if ! dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
            echo -e "  ${GREEN}→${NC} Installing $pkg..."
            apt install -y $pkg >/dev/null 2>&1 || echo -e "  ${YELLOW}⚠${NC} Failed: $pkg"
        else
            echo -e "  ${GREEN}✓${NC} $pkg (already installed)"
        fi
    done
    
    # Install Node.js
    if ! command -v node &>/dev/null; then
        echo -e "  ${GREEN}→${NC} Installing Node.js 20..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
        apt install -y nodejs >/dev/null 2>&1
    else
        echo -e "  ${GREEN}✓${NC} Node.js $(node -v) (already installed)"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Packages installed${NC}"
    echo ""
}

# ============================================================
# Install All Services
# ============================================================
install_services() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}📦 INSTALLING MARCSCRIPT SERVICES${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # 1. SSH Configuration
    echo -e "${YELLOW}[1/8] Configuring SSH Server (Ports 22, 80)...${NC}"
    if [ -f "$SCRIPT_DIR/ssh/ssh-setup.sh" ]; then
        bash "$SCRIPT_DIR/ssh/ssh-setup.sh"
    fi
    echo ""
    
    # 2. WebSocket Proxy
    echo -e "${YELLOW}[2/8] Configuring WebSocket Proxy (Port 8080)...${NC}"
    if [ -f "$SCRIPT_DIR/services/websocket.sh" ]; then
        bash "$SCRIPT_DIR/services/websocket.sh"
    fi
    echo ""
    
    # 3. Squid Proxy
    echo -e "${YELLOW}[3/8] Configuring Squid Proxy (Ports 3128, 8082, 8888)...${NC}"
    if [ -f "$SCRIPT_DIR/services/squid.sh" ]; then
        bash "$SCRIPT_DIR/services/squid.sh"
    fi
    echo ""
    
    # 4. Xray (Optional)
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}  Xray provides: VMess, VLess, Trojan, Shadowsocks          ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  Paths: /vmess, /vless, /trojan-ws, /ss-ws                ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  gRPC: vless-grpc, vmess-grpc, trojan-grpc                ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Install Xray? [Y/n]: " install_xray
    
    if [[ ! "$install_xray" =~ ^[Nn]$ ]]; then
        echo ""
        echo -e "${YELLOW}[4/8] Installing Xray Core...${NC}"
        if [ -f "$SCRIPT_DIR/xray/xray-install.sh" ]; then
            bash "$SCRIPT_DIR/xray/xray-install.sh"
        fi
        echo ""
        
        echo -e "${YELLOW}[5/8] Generating Xray Configuration...${NC}"
        if [ -f "$SCRIPT_DIR/xray/xray-config.sh" ]; then
            bash "$SCRIPT_DIR/xray/xray-config.sh"
        fi
        
        # Save domain
        if [ -f /root/domain ]; then
            cp /root/domain /etc/xray/domain
        elif [ ! -f /etc/xray/domain ]; then
            echo "$MYIP" > /etc/xray/domain
        fi
        echo ""
    else
        echo -e "${YELLOW}[4/8] Skipping Xray Core...${NC}"
        echo -e "${YELLOW}[5/8] Skipping Xray Config...${NC}"
        echo "$MYIP" > /etc/xray/domain 2>/dev/null
        echo ""
    fi
    
    # 6. Nginx (Ports 80, 443)
    echo -e "${YELLOW}[6/8] Configuring Nginx (Ports 80, 443)...${NC}"
    if [ -f "$SCRIPT_DIR/services/nginx.sh" ]; then
        bash "$SCRIPT_DIR/services/nginx.sh"
    fi
    echo ""
    
    # 7. Stunnel (Ports 8445, 8446 - avoids conflict with Nginx 443)
    echo -e "${YELLOW}[7/8] Configuring Stunnel SSL (Ports 8445, 8446)...${NC}"
    if [ -f "$SCRIPT_DIR/services/stunnel.sh" ]; then
        bash "$SCRIPT_DIR/services/stunnel.sh"
    fi
    echo ""
    
    # 8. Firewall
    echo -e "${YELLOW}[8/8] Configuring Firewall...${NC}"
    if [ -f "$SCRIPT_DIR/lib/firewall.sh" ]; then
        bash "$SCRIPT_DIR/lib/firewall.sh"
    fi
    echo ""
    
    # Save installation info
    cat > /etc/marcscript/install.conf << EOF
INSTALL_DATE=$(date '+%Y-%m-%d %H:%M:%S')
VPS_IP=$MYIP
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo 'Not Set')
XRAY_INSTALLED=$([ -f /usr/local/bin/xray ] && echo "Yes" || echo "No")
SSH_PORT=22
EOF
    
    echo -e "${GREEN}✅ All services installed${NC}"
}

# ============================================================
# Add Menu to .bashrc
# ============================================================
add_menu_to_bashrc() {
    if ! grep -q "MarcScript VPN Menu" /root/.bashrc 2>/dev/null; then
        echo '' >> /root/.bashrc
        echo '# ===================================' >> /root/.bashrc
        echo '# MarcScript VPN Menu' >> /root/.bashrc
        echo '# ===================================' >> /root/.bashrc
        echo 'if [ -f /usr/local/marcscript/menu.sh ] && [ -z "$MARCSCRIPT_MENU_SHOWN" ]; then' >> /root/.bashrc
        echo '    export MARCSCRIPT_MENU_SHOWN=1' >> /root/.bashrc
        echo '    /usr/local/marcscript/menu.sh' >> /root/.bashrc
        echo 'fi' >> /root/.bashrc
    fi
}

# ============================================================
# Verify Services
# ============================================================
verify_services() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}VERIFYING SERVICES${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local all_ok=true
    
    check_svc() {
        local svc=$1
        local name=$2
        if systemctl is-active --quiet $svc 2>/dev/null; then
            echo -e "  ${GREEN}✅${NC} $name"
        else
            echo -e "  ${RED}❌${NC} $name (not running)"
            all_ok=false
        fi
    }
    
    check_svc ssh "SSH Server"
    check_svc nginx "Nginx Web Server"
    check_svc stunnel4 "Stunnel SSL"
    check_svc ws-proxy "WebSocket Proxy"
    check_svc squid "Squid Proxy"
    
    if [ -f /usr/local/bin/xray ]; then
        check_svc xray "Xray Core"
    else
        echo -e "  ${YELLOW}⚠${NC} Xray (not installed)"
    fi
    
    echo ""
    
    if [ "$all_ok" = true ]; then
        echo -e "${GREEN}✅ All core services are running${NC}"
    else
        echo -e "${YELLOW}⚠ Some services need attention${NC}"
    fi
}

# ============================================================
# Final Message
# ============================================================
show_completion() {
    clear
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}           ${GREEN}✅ MARCSCRIPT INSTALLATION COMPLETE!${NC}                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e " ${GREEN}🚀 MarcScript VPN is ready!${NC}"
    echo ""
    
    # Port table
    echo -e " ${CYAN}╔═══════════╦══════════════════════════════════════╗${NC}"
    echo -e " ${CYAN}║${NC} ${YELLOW}Port${NC}      ${CYAN}║${NC} ${YELLOW}Service${NC}                               ${CYAN}║${NC}"
    echo -e " ${CYAN}╠═══════════╬══════════════════════════════════════╣${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}22${NC}         ${CYAN}║${NC} SSH Direct (Password Auth)             ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}80${NC}         ${CYAN}║${NC} SSH HTTP + Xray Non-TLS               ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}443${NC}        ${CYAN}║${NC} Nginx HTTPS (Xray TLS)                ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}3128${NC}       ${CYAN}║${NC} Squid Proxy                            ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}8000${NC}       ${CYAN}║${NC} WebSocket SSH                          ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}8080${NC}       ${CYAN}║${NC} WebSocket SSH (Alt)                    ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}8082${NC}       ${CYAN}║${NC} Squid Proxy (Alt)                      ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}8445${NC}       ${CYAN}║${NC} Stunnel SSH SSL                        ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}8446${NC}       ${CYAN}║${NC} Stunnel WebSocket SSL                  ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ${GREEN}8888${NC}       ${CYAN}║${NC} Squid Proxy (Alt 2)                    ${CYAN}║${NC}"
    echo -e " ${CYAN}╚═══════════╩══════════════════════════════════════╝${NC}"
    echo ""
    
    # Commands
    echo -e " ${CYAN}╔══════════════╦════════════════════════════════╗${NC}"
    echo -e " ${CYAN}║${NC} Command      ${CYAN}║${NC} Description                     ${CYAN}║${NC}"
    echo -e " ${CYAN}╠══════════════╬════════════════════════════════╣${NC}"
    echo -e " ${CYAN}║${NC} menu         ${CYAN}║${NC} Main control panel              ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} add-ssh      ${CYAN}║${NC} Create SSH account              ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} add-vmess    ${CYAN}║${NC} Create VMess account            ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} add-vless    ${CYAN}║${NC} Create VLess account            ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} add-trojan   ${CYAN}║${NC} Create Trojan account           ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} del-user     ${CYAN}║${NC} Delete user account             ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} check        ${CYAN}║${NC} Check services status           ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} ssh-manage   ${CYAN}║${NC} SSH user management             ${CYAN}║${NC}"
    echo -e " ${CYAN}╚══════════════╩════════════════════════════════╝${NC}"
    echo ""
    
    # Xray paths
    if [ -f /usr/local/bin/xray ]; then
        echo -e " ${YELLOW}Xray Paths:${NC}"
        echo -e "   WS TLS (443):  /vmess, /vless, /trojan-ws, /ss-ws"
        echo -e "   WS NTLS (80):  /vmess, /vless, /trojan-ws, /ss-ws"
        echo -e "   gRPC (443):    vless-grpc, vmess-grpc, trojan-grpc, ss-grpc"
        echo ""
    fi
    
    echo -e " ${CYAN}IP:${NC} ${GREEN}$MYIP${NC}"
    echo -e " ${CYAN}Domain:${NC} ${GREEN}$(cat /etc/xray/domain 2>/dev/null || echo 'Not Set')${NC}"
    echo ""
    echo -e " ${YELLOW}Type 'menu' to access the control panel${NC}"
    echo ""
    echo -e " ${PURPLE}⚠️  IMPORTANT: Keep your SSH session open!${NC}"
    echo -e " ${PURPLE}   Test login in a new terminal before closing.${NC}"
    echo ""
}

# ============================================================
# Main Execution
# ============================================================
main() {
    check_os
    echo ""
    
    # Step 0: Cleanup first
    cleanup_services
    
    # Step 0.5: Ensure SSH password auth
    ensure_ssh_auth
    
    # Step 1: Create directories
    create_directories
    
    # Step 2: Download files
    download_files
    
    # Step 3: Install packages
    install_base_packages
    
    # Step 4: Install services
    install_services
    
    # Step 5: Add menu to bashrc
    add_menu_to_bashrc
    
    # Step 6: Verify services
    verify_services
    
    # Step 7: Show completion
    show_completion
    
    # Log installation
    echo "$(date) - MarcScript installed on $MYIP - OS: $OS $VER" >> /var/log/marcscript-install.log 2>/dev/null
}

# Run
main