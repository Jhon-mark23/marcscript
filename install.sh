#!/bin/bash
# ============================================================
# MARCSCRIPT VPN - Universal Installer v2.1
# Compatible: Ubuntu 18.04+, Debian 10+
# License: MIT
# ============================================================
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)
SCRIPT_DIR="/usr/local/marcscript"
GITHUB_RAW="https://raw.githubusercontent.com/Jhon-mark23/marcscript/main"

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}  ${GREEN}🚀 MARCSCRIPT VPN - Universal Installer v2.1${NC}              ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

[ "$EUID" -ne 0 ] && { echo -e "${RED}❌ Run as root${NC}"; exit 1; }

# ============================================================
# STEP 0: Cleanup
# ============================================================
cleanup_services() {
    echo -e "${YELLOW}🧹 Cleaning up...${NC}"
    systemctl stop nginx stunnel4 squid xray ws-proxy 2>/dev/null || true
    for port in 80 443 3128 8080 8082 8443 8445 8446 8888; do fuser -k ${port}/tcp 2>/dev/null || true; done
    sleep 1
    echo -e "${GREEN}✅ Cleanup done${NC}"
}

# ============================================================
# STEP 0.5: Ensure SSH
# ============================================================
ensure_ssh_auth() {
    echo -e "${YELLOW}🔐 Enabling SSH password auth...${NC}"
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak 2>/dev/null
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
    echo -e "${GREEN}✅ SSH ready (Port 22)${NC}"
}

# ============================================================
# STEP 0.6: Domain Setup (BEFORE XRAY)
# ============================================================
setup_domain() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${YELLOW}🌐 DOMAIN SETUP${NC}                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if domain already exists
    if [ -f /root/domain ] || [ -f /etc/xray/domain ]; then
        DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null)
        echo -e " Domain found: ${GREEN}${DOMAIN}${NC}"
        echo ""
        read -p " Use this domain? [Y/n]: " use_existing
        if [[ ! "$use_existing" =~ ^[Nn]$ ]]; then
            echo "$DOMAIN" > /root/domain
            echo "$DOMAIN" > /etc/xray/domain
            echo -e "${GREEN}✅ Using existing domain: ${DOMAIN}${NC}"
            return
        fi
    fi
    
    echo -e " ${YELLOW}Enter your domain for Xray SSL/TLS:${NC}"
    echo -e " ${YELLOW}(If no domain, use VPS IP for self-signed cert)${NC}"
    echo ""
    read -p " Domain (or press Enter for IP): " DOMAIN
    
    if [ -z "$DOMAIN" ]; then
        DOMAIN="$MYIP"
        echo -e "${YELLOW}⚠ No domain entered, using IP: ${DOMAIN}${NC}"
        echo -e "${YELLOW}⚠ Xray will use self-signed certificate${NC}"
    else
        echo -e "${GREEN}✅ Domain set to: ${DOMAIN}${NC}"
    fi
    
    echo "$DOMAIN" > /root/domain
    echo "$DOMAIN" > /etc/xray/domain
    echo ""
}

# ============================================================
# OS Check
# ============================================================
check_os() {
    . /etc/os-release
    [[ "$ID" =~ ^(ubuntu|debian)$ ]] || { echo -e "${RED}❌ Unsupported${NC}"; exit 1; }
    echo -e "${GREEN}✅ OS: $PRETTY_NAME${NC}"
}

# ============================================================
# Directories & Downloads
# ============================================================
create_dirs() { 
    mkdir -p $SCRIPT_DIR/{lib,ssh,xray,services,tools} /etc/xray /var/log/xray /etc/marcscript /home/vps/public_html
}
download_files() {
    echo -e "${YELLOW}📥 Downloading files...${NC}"
    for f in menu.sh lib/common.sh lib/packages.sh lib/firewall.sh ssh/ssh-setup.sh xray/xray-install.sh xray/xray-config.sh services/stunnel.sh services/websocket.sh services/squid.sh services/nginx.sh tools/add-ssh.sh tools/add-vmess.sh tools/add-vless.sh tools/add-trojan.sh tools/del-user.sh tools/check.sh; do
        wget -q "$GITHUB_RAW/$f" -O "$SCRIPT_DIR/$f" 2>/dev/null && { chmod +x "$SCRIPT_DIR/$f"; echo -e "  ${GREEN}✓${NC} $f"; } || echo -e "  ${RED}✗${NC} $f"
    done
    for tool in add-ssh add-vmess add-vless add-trojan del-user check; do ln -sf "$SCRIPT_DIR/tools/$tool.sh" "/usr/local/bin/$tool" 2>/dev/null; done
    ln -sf "$SCRIPT_DIR/menu.sh" "/usr/local/bin/menu" 2>/dev/null
}

# ============================================================
# Packages
# ============================================================
install_packages() {
    echo -e "${YELLOW}📦 Installing packages...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    apt update -y >/dev/null
    for pkg in openssh-server stunnel4 squid nginx curl wget lsof net-tools jq openssl cron socat netcat-openbsd dnsutils screen xz-utils unzip tar ufw apache2-utils iptables; do
        dpkg -l | grep -q "^ii  $pkg" || apt install -y $pkg >/dev/null 2>&1
    done
    command -v node &>/dev/null || { curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1; apt install -y nodejs >/dev/null 2>&1; }
    echo -e "${GREEN}✅ Packages done${NC}"
}

# ============================================================
# Install Services
# ============================================================
install_services() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}📦 INSTALLING SERVICES${NC}                                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"

    # 1. SSH
    echo -e "${YELLOW}[1/7] SSH Server (Port 22, 80)${NC}"
    [ -f "$SCRIPT_DIR/ssh/ssh-setup.sh" ] && bash "$SCRIPT_DIR/ssh/ssh-setup.sh"
    
    # 2. WebSocket
    echo -e "${YELLOW}[2/7] WebSocket Proxy (Port 8080)${NC}"
    [ -f "$SCRIPT_DIR/services/websocket.sh" ] && bash "$SCRIPT_DIR/services/websocket.sh"
    
    # 3. Squid
    echo -e "${YELLOW}[3/7] Squid Proxy (3128,8082,8888)${NC}"
    [ -f "$SCRIPT_DIR/services/squid.sh" ] && bash "$SCRIPT_DIR/services/squid.sh"

    # 4. XRAY - Ask user
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}  XRAY provides: VMess, VLess, Trojan, Shadowsocks          ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  Ports: TLS 443 | Non-TLS 80 | gRPC 443                   ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  Domain: ${GREEN}$(cat /root/domain 2>/dev/null || echo $MYIP)${NC}                         ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    read -p " Install Xray? [y/N]: " install_xray
    
    if [[ "$install_xray" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[4/7] Installing Xray Core...${NC}"
        [ -f "$SCRIPT_DIR/xray/xray-install.sh" ] && bash "$SCRIPT_DIR/xray/xray-install.sh"
        
        echo -e "${YELLOW}[5/7] Configuring Xray...${NC}"
        [ -f "$SCRIPT_DIR/xray/xray-config.sh" ] && bash "$SCRIPT_DIR/xray/xray-config.sh"
    else
        echo -e "${YELLOW}[4/7] Skipping Xray${NC}"
        echo -e "${YELLOW}[5/7] Skipping Xray config${NC}"
    fi

    # 6. Nginx
    echo -e "${YELLOW}[6/7] Nginx (Port 80, 443)${NC}"
    [ -f "$SCRIPT_DIR/services/nginx.sh" ] && bash "$SCRIPT_DIR/services/nginx.sh"
    
    # 7. Stunnel
    echo -e "${YELLOW}[7/7] Stunnel SSL (8445, 8446)${NC}"
    [ -f "$SCRIPT_DIR/services/stunnel.sh" ] && bash "$SCRIPT_DIR/services/stunnel.sh"

    # Firewall
    [ -f "$SCRIPT_DIR/lib/firewall.sh" ] && bash "$SCRIPT_DIR/lib/firewall.sh"

    # Save config
    cat > /etc/marcscript/install.conf << EOF
INSTALL_DATE=$(date)
VPS_IP=$MYIP
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo 'Not Set')
XRAY_INSTALLED=$([ -f /usr/local/bin/xray ] && echo "Yes" || echo "No")
EOF
}

# ============================================================
# Final
# ============================================================
add_menu() { grep -q "MarcScript" /root/.bashrc || echo -e "\n# MarcScript Menu\n[ -f /usr/local/marcscript/menu.sh ] && /usr/local/marcscript/menu.sh" >> /root/.bashrc; }

verify_svc() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}SERVICE STATUS${NC}                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    for svc in ssh nginx stunnel4 ws-proxy squid xray; do
        s=$(systemctl is-active $svc 2>/dev/null || echo "Dead")
        [ "$s" = "active" ] && echo -e " ${GREEN}✅${NC} $svc" || echo -e " ${RED}❌${NC} $svc"
    done
}

show_done() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}           ${GREEN}✅ MARCSCRIPT INSTALLED!${NC}                             ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n Type ${GREEN}menu${NC} for control panel\n"
    echo -e " IP: ${GREEN}$MYIP${NC} | Domain: ${GREEN}$(cat /etc/xray/domain 2>/dev/null || echo 'Not Set')${NC}"
    echo -e " Ports: SSH:22,80 | WS:8080 | SSL:8445,8446 | Squid:3128,8082,8888 | Nginx:80,443"
}

# ============================================================
# MAIN
# ============================================================
main() {
    check_os
    cleanup_services
    ensure_ssh_auth
    setup_domain          # ASK DOMAIN BEFORE XRAY
    create_dirs
    download_files
    install_packages
    install_services
    add_menu
    verify_svc
    show_done
}
main