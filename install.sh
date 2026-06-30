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
NC='\033[0m'

# Get VPS IP
MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)

# Script directory
SCRIPT_DIR="/usr/local/marcscript"
GITHUB_RAW="https://raw.githubusercontent.com/Jhon-mark23/marcscript/main"

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}🚀 MARCSCRIPT VPN - Universal Installer${NC}                   ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}SSH • Xray • WebSocket • SSL • Proxy${NC}                     ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root (sudo su)${NC}"
    exit 1
fi

# Check OS compatibility
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

# Create directory structure
create_directories() {
    echo -e "${YELLOW}📁 Creating MarcScript directories...${NC}"
    mkdir -p $SCRIPT_DIR/{lib,ssh,xray,services,tools}
    mkdir -p /etc/xray /var/log/xray /etc/marcscript
    echo -e "${GREEN}✅ Directories created${NC}"
}

# Download file from GitHub
download_file() {
    local file=$1
    local dest=$2
    
    if [ -z "$dest" ]; then
        dest="$SCRIPT_DIR/$file"
    fi
    
    mkdir -p "$(dirname "$dest")"
    
    if wget -q --show-progress "$GITHUB_RAW/$file" -O "$dest" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $file"
        chmod +x "$dest" 2>/dev/null
        return 0
    else
        echo -e "  ${RED}✗${NC} Failed: $file"
        return 1
    fi
}

# Download all required files
download_files() {
    echo -e "${YELLOW}📥 Downloading MarcScript files from GitHub...${NC}"
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
}

# Source common functions
source_common() {
    if [ -f "$SCRIPT_DIR/lib/common.sh" ]; then
        source "$SCRIPT_DIR/lib/common.sh"
    fi
}

# Install packages
install_base_packages() {
    echo -e "${YELLOW}📦 Installing required packages...${NC}"
    
    export DEBIAN_FRONTEND=noninteractive
    apt update -y >/dev/null 2>&1
    
    PACKAGES="openssh-server stunnel4 squid nginx curl wget lsof net-tools jq openssl cron socat netcat-openbsd dnsutils screen xz-utils unzip tar"
    
    for pkg in $PACKAGES; do
        if ! dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
            echo -e "  Installing $pkg..."
            apt install -y $pkg >/dev/null 2>&1
        fi
    done
    
    # Install Node.js
    if ! command -v node &>/dev/null; then
        echo -e "  Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
        apt install -y nodejs >/dev/null 2>&1
    fi
    
    echo -e "${GREEN}✅ Packages installed${NC}"
}

# Install all services
install_services() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}📦 INSTALLING MARCSCRIPT SERVICES${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # SSH
    echo -e "${YELLOW}[1/7] Configuring SSH...${NC}"
    if [ -f "$SCRIPT_DIR/ssh/ssh-setup.sh" ]; then
        bash "$SCRIPT_DIR/ssh/ssh-setup.sh"
    fi
    
    # Stunnel
    echo -e "${YELLOW}[2/7] Configuring Stunnel SSL...${NC}"
    if [ -f "$SCRIPT_DIR/services/stunnel.sh" ]; then
        bash "$SCRIPT_DIR/services/stunnel.sh"
    fi
    
    # WebSocket
    echo -e "${YELLOW}[3/7] Configuring WebSocket Proxy...${NC}"
    if [ -f "$SCRIPT_DIR/services/websocket.sh" ]; then
        bash "$SCRIPT_DIR/services/websocket.sh"
    fi
    
    # Squid
    echo -e "${YELLOW}[4/7] Configuring Squid Proxy...${NC}"
    if [ -f "$SCRIPT_DIR/services/squid.sh" ]; then
        bash "$SCRIPT_DIR/services/squid.sh"
    fi
    
    # Firewall
    echo -e "${YELLOW}[5/7] Configuring Firewall...${NC}"
    if [ -f "$SCRIPT_DIR/lib/firewall.sh" ]; then
        bash "$SCRIPT_DIR/lib/firewall.sh"
    fi
    
    # Xray (optional)
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}  Xray provides: VMess, VLess, Trojan, Shadowsocks          ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    read -p "Install Xray? [Y/n]: " install_xray
    
    if [[ ! "$install_xray" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}[6/7] Installing Xray Core...${NC}"
        if [ -f "$SCRIPT_DIR/xray/xray-install.sh" ]; then
            bash "$SCRIPT_DIR/xray/xray-install.sh"
        fi
        
        echo -e "${YELLOW}[7/7] Configuring Xray...${NC}"
        if [ -f "$SCRIPT_DIR/xray/xray-config.sh" ]; then
            bash "$SCRIPT_DIR/xray/xray-config.sh"
        fi
        
        # Save domain
        if [ -f /root/domain ]; then
            cp /root/domain /etc/xray/domain
        else
            echo "$MYIP" > /etc/xray/domain
        fi
        
        # Nginx for Xray
        if [ -f "$SCRIPT_DIR/services/nginx.sh" ]; then
            bash "$SCRIPT_DIR/services/nginx.sh"
        fi
    else
        echo -e "${YELLOW}[6/7] Skipping Xray...${NC}"
        echo -e "${YELLOW}[7/7] Configuring Nginx...${NC}"
        if [ -f "$SCRIPT_DIR/services/nginx.sh" ]; then
            bash "$SCRIPT_DIR/services/nginx.sh"
        fi
    fi
    
    # Save installation info
    cat > /etc/marcscript/install.conf << EOF
INSTALL_DATE=$(date)
VPS_IP=$MYIP
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo 'Not Set')
XRAY_INSTALLED=$([ -f /usr/local/bin/xray ] && echo "Yes" || echo "No")
EOF
}

# Add menu to bashrc
add_menu_to_bashrc() {
    if ! grep -q "menu" /root/.bashrc 2>/dev/null; then
        echo '' >> /root/.bashrc
        echo '# MarcScript VPN Menu' >> /root/.bashrc
        echo 'if [ -f /usr/local/marcscript/menu.sh ]; then' >> /root/.bashrc
        echo '    /usr/local/marcscript/menu.sh' >> /root/.bashrc
        echo 'fi' >> /root/.bashrc
    fi
}

# Final message
show_completion() {
    clear
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}           ${GREEN}✅ INSTALLATION COMPLETE!${NC}                          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e " ${GREEN}🚀 MarcScript VPN is ready!${NC}"
    echo ""
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
    echo -e " ${CYAN}╚══════════════╩════════════════════════════════╝${NC}"
    echo ""
    echo -e " ${CYAN}IP:${NC} ${GREEN}$MYIP${NC}"
    echo -e " ${CYAN}Domain:${NC} ${GREEN}$(cat /etc/xray/domain 2>/dev/null || echo 'Not Set')${NC}"
    echo ""
    echo -e " ${CYAN}Service Ports:${NC}"
    echo -e "   SSH      : 22, 80"
    echo -e "   SSL      : 443 (Stunnel)"
    echo -e "   WS       : 8080"
    echo -e "   Squid    : 3128, 8082, 8888"
    echo -e "   Nginx    : 80, 443"
    echo -e "   Xray     : Via Nginx (80/443)"
    echo ""
    echo -e " ${YELLOW}Type 'menu' to access the control panel${NC}"
    echo ""
}

# Main execution
main() {
    check_os
    create_directories
    download_files
    source_common
    install_base_packages
    install_services
    add_menu_to_bashrc
    show_completion
}

# Run
main
