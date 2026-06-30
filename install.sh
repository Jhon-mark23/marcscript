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
    echo -e "${CYAN}║${NC}              ${YELLOW}🌐 DOMAIN SETUP FOR XRAY${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if domain file exists and has a REAL domain (not IP)
    local existing_domain=""
    if [ -f /etc/xray/domain ]; then
        existing_domain=$(cat /etc/xray/domain)
    elif [ -f /root/domain ]; then
        existing_domain=$(cat /root/domain)
    fi
    
    # Check if existing domain is actually an IP address
    if [[ "$existing_domain" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e " ${RED}⚠ Existing domain file contains IP: ${existing_domain}${NC}"
        echo -e " ${YELLOW}This is NOT a real domain!${NC}"
        echo ""
        existing_domain=""
    fi
    
    # If real domain exists, ask to use it
    if [ -n "$existing_domain" ]; then
        echo -e " ${GREEN}✅ Found existing domain: ${existing_domain}${NC}"
        echo ""
        read -p " Use this domain? [Y/n]: " use_existing
        
        if [[ ! "$use_existing" =~ ^[Nn]$ ]]; then
            echo "$existing_domain" > /root/domain
            echo "$existing_domain" > /etc/xray/domain
            echo -e "${GREEN}✅ Using domain: ${existing_domain}${NC}"
            echo -e "${GREEN}✅ Let's Encrypt SSL will be used${NC}"
            echo ""
            sleep 2
            return
        fi
    fi
    
    # Ask for new domain
    echo -e " ${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e " ${YELLOW}║${NC}  Do you have a domain for Xray SSL/TLS?                    ${YELLOW}║${NC}"
    echo -e " ${YELLOW}║${NC}  Example: vpn.example.com                                 ${YELLOW}║${NC}"
    echo -e " ${YELLOW}║${NC}                                                          ${YELLOW}║${NC}"
    echo -e " ${YELLOW}║${NC}  [Y] Yes, I have a domain                                ${YELLOW}║${NC}"
    echo -e " ${YELLOW}║${NC}  [N] No, use VPS IP (self-signed cert)                   ${YELLOW}║${NC}"
    echo -e " ${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p " Do you have a domain? [y/N]: " has_domain
    
    if [[ "$has_domain" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e " ${YELLOW}Enter your domain (without http:// or https://):${NC}"
        echo -e " ${YELLOW}Example: vpn.yourdomain.com${NC}"
        echo ""
        read -p " Domain: " DOMAIN
        
        # Validate domain (must contain at least one dot)
        if [ -z "$DOMAIN" ]; then
            echo -e "${RED}❌ No domain entered, using IP instead${NC}"
            DOMAIN="$MYIP"
        elif [[ ! "$DOMAIN" =~ \. ]]; then
            echo -e "${RED}❌ Invalid domain format, using IP instead${NC}"
            DOMAIN="$MYIP"
        elif [[ "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo -e "${YELLOW}⚠ That looks like an IP address, not a domain${NC}"
            echo -e "${YELLOW}Using it anyway...${NC}"
        else
            echo -e "${GREEN}✅ Domain: $DOMAIN${NC}"
            echo -e "${GREEN}✅ Let's Encrypt SSL certificate will be used${NC}"
        fi
    else
        echo ""
        echo -e "${YELLOW}⚠ No domain - Using VPS IP: $MYIP${NC}"
        echo -e "${YELLOW}⚠ Xray will use self-signed SSL certificate${NC}"
        echo -e "${YELLOW}⚠ Clients may need to ignore certificate warnings${NC}"
        DOMAIN="$MYIP"
    fi
    
    # Save domain
    echo "$DOMAIN" > /root/domain
    echo "$DOMAIN" > /etc/xray/domain
    
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo -e " Domain set to: ${GREEN}$DOMAIN${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo ""
    sleep 2
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