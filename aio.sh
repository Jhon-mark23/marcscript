#!/bin/bash
# ============================================================
# MARCSCRIPT VPN - One-Click Installer
# GitHub: https://github.com/Jhon-mark23/marcscript
# 
# Run: bash <(curl -s https://raw.githubusercontent.com/Jhon-mark23/marcscript/main/aio.sh)
# ============================================================

set -e

# Colors first (before any sourcing)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Get IP
MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)

clear
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}   🚀 MARCSCRIPT VPN INSTALLER${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root (sudo su)${NC}"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}❌ Cannot detect OS${NC}"
    exit 1
fi

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    echo -e "${RED}❌ This script only supports Ubuntu/Debian${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO]${NC} Detected OS: $OS"
echo -e "${GREEN}[INFO]${NC} IP Address: $MYIP"
echo ""

# ============================================================
# STEP 1: Create Directory Structure
# ============================================================
echo -e "${YELLOW}📁 Creating MarcScript directory structure...${NC}"

MARCSCRIPT_DIR="/usr/local/marcscript"
mkdir -p $MARCSCRIPT_DIR/{lib,ssh,services,xray,menu,utils}
mkdir -p /etc/xray /var/log/xray

echo -e "${GREEN}✅ Directories created${NC}"
echo ""

# ============================================================
# STEP 2: Download or Create All Files
# ============================================================
echo -e "${YELLOW}📥 Downloading MarcScript files...${NC}"

BASE_URL="https://raw.githubusercontent.com/Jhon-mark23/marcscript/main"

# Function to download file or create if fails
download_file() {
    local file_path="$1"
    local dest="$MARCSCRIPT_DIR/$file_path"
    local url="$BASE_URL/$file_path"
    
    mkdir -p "$(dirname "$dest")"
    
    if wget -q "$url" -O "$dest" 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Downloaded: $file_path"
        return 0
    else
        echo -e "  ${YELLOW}⚠${NC} Failed to download: $file_path (will create locally)"
        return 1
    fi
}

# Download core files
download_file "aio.sh" || true

# If download fails, create files locally
if [ ! -f "$MARCSCRIPT_DIR/lib/common.sh" ]; then
    echo -e "${YELLOW}Creating files locally...${NC}"
    
    # ============================================================
    # Create lib/common.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/lib/common.sh << 'COMMONEOF'
#!/bin/bash
# MarcScript - Common Functions

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)
LOG_FILE="/var/log/marcscript-install.log"
API_PORT=3021

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${BLUE}[SUCCESS]${NC} $1"; }

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

get_domain() {
    if [ -f /etc/xray/domain ]; then
        cat /etc/xray/domain
    elif [ -f /root/domain ]; then
        cat /root/domain
    else
        echo "$MYIP"
    fi
}
COMMONEOF

    # ============================================================
    # Create lib/packages.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/lib/packages.sh << 'PACKAGESEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

install_packages() {
    log_info "Installing required packages..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -y >/dev/null 2>&1
    
    PACKAGES="openssh-server stunnel4 squid nginx curl wget lsof net-tools jq openssl cron socat netcat-openbsd dnsutils screen xz-utils unzip"
    
    for pkg in $PACKAGES; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            apt install -y $pkg >/dev/null 2>&1
        fi
    done
    
    # Node.js
    if ! command -v node &>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
        apt install -y nodejs >/dev/null 2>&1
    fi
    
    log_success "Packages installed"
}
PACKAGESEOF

    # ============================================================
    # Create lib/firewall.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/lib/firewall.sh << 'FIREWALLEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

configure_firewall() {
    log_info "Configuring firewall..."
    
    if command -v ufw &>/dev/null; then
        ufw --force reset >/dev/null 2>&1
        for port in 22 80 81 443 3128 8000 8080 8082 8443 8888; do
            ufw allow $port/tcp >/dev/null 2>&1
        done
        echo "y" | ufw enable >/dev/null 2>&1
    fi
    
    log_success "Firewall configured"
}
FIREWALLEOF

    # ============================================================
    # Create ssh/ssh-setup.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/ssh/ssh-setup.sh << 'SSHEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

configure_ssh() {
    log_info "Configuring SSH..."
    
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak 2>/dev/null
    
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
    grep -q "^Port 80" /etc/ssh/sshd_config || echo "Port 80" >> /etc/ssh/sshd_config
    
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
    
    echo "MarcScript VPN Server" > /etc/ssh/banner
    grep -q "^Banner" /etc/ssh/sshd_config || echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
    
    systemctl restart ssh
    systemctl enable ssh
    
    log_success "SSH configured on ports 22, 80"
}
SSHEOF

    # ============================================================
    # Create services/stunnel.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/services/stunnel.sh << 'STUNNELEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

configure_stunnel() {
    log_info "Configuring Stunnel..."
    
    openssl req -new -x509 -days 3650 -nodes \
        -subj "/C=PH/ST=Manila/L=Manila/O=MarcScript/CN=MarcScript" \
        -out /etc/stunnel/stunnel.pem \
        -keyout /etc/stunnel/stunnel.pem 2>/dev/null
    
    cat > /etc/stunnel/stunnel.conf << 'EOF'
pid = /var/run/stunnel.pid
client = no
foreground = no

[ssh-ssl]
accept = 443
connect = 127.0.0.1:22
cert = /etc/stunnel/stunnel.pem

[ws-ssl]
accept = 8443
connect = 127.0.0.1:8080
cert = /etc/stunnel/stunnel.pem
EOF

    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null
    systemctl restart stunnel4 2>/dev/null || true
    systemctl enable stunnel4 2>/dev/null || true
    
    log_success "Stunnel configured"
}
STUNNELEOF

    # ============================================================
    # Create services/websocket.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/services/websocket.sh << 'WSEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

configure_websocket() {
    log_info "Configuring WebSocket proxy..."
    
    mkdir -p /opt/ws-proxy
    
    cat > /opt/ws-proxy/ws-proxy.js << 'WSPROXYEOF'
const net = require('net');
const http = require('http');

const server = http.createServer();

server.on('upgrade', (req, socket) => {
    const ssh = net.connect(22, '127.0.0.1', () => {
        socket.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n');
        ssh.pipe(socket);
        socket.pipe(ssh);
    });
    ssh.on('error', () => socket.destroy());
});

server.listen(8080, '0.0.0.0', () => console.log('WS Proxy on port 8080'));
WSPROXYEOF

    cat > /etc/systemd/system/ws-proxy.service << 'EOF'
[Unit]
Description=SSH WebSocket Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /opt/ws-proxy/ws-proxy.js
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ws-proxy
    systemctl start ws-proxy 2>/dev/null || true
    
    log_success "WebSocket configured on port 8080"
}
WSEOF

    # ============================================================
    # Create services/squid.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/services/squid.sh << 'SQUIDEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

configure_squid() {
    log_info "Configuring Squid..."
    
    cat > /etc/squid/squid.conf << 'EOF'
http_port 3128
http_port 8082
http_port 8888
acl all src 0.0.0.0/0
http_access allow all
visible_hostname MarcScript
forwarded_for off
EOF

    systemctl restart squid 2>/dev/null || true
    systemctl enable squid 2>/dev/null || true
    
    log_success "Squid configured"
}
SQUIDEOF

    # ============================================================
    # Create services/nginx.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/services/nginx.sh << 'NGINXEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

configure_nginx() {
    log_info "Configuring Nginx..."
    
    domain=$(get_domain)
    mkdir -p /home/vps/public_html
    
    cat > /etc/nginx/conf.d/xray.conf << NGINXCONF
server {
    listen 80;
    server_name *.${domain};
    root /home/vps/public_html;

    location = /vmess {
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /vless {
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /trojan-ws {
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}

server {
    listen 443 ssl http2;
    server_name *.${domain};
    
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    root /home/vps/public_html;

    location = /vmess {
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /vless {
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /trojan-ws {
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}
NGINXCONF

    nginx -t 2>/dev/null && systemctl restart nginx && systemctl enable nginx
    log_success "Nginx configured"
}
NGINXEOF

    # ============================================================
    # Create xray/xray-core.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/xray/xray-core.sh << 'XRAYCOREEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

install_xray() {
    log_info "Installing Xray core..."
    
    mkdir -p /etc/xray /var/log/xray
    touch /var/log/xray/access.log /var/log/xray/error.log
    
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data 2>/dev/null
    
    cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
After=network.target

[Service]
User=www-data
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    log_success "Xray installed"
}
XRAYCOREEOF

    # ============================================================
    # Create xray/xray-cert.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/xray/xray-cert.sh << 'XRAYCERTEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

setup_xray_cert() {
    log_info "Setting up SSL certificate..."
    
    domain=$(get_domain)
    
    # Self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/xray/xray.key \
        -out /etc/xray/xray.crt \
        -subj "/C=PH/ST=Manila/L=Manila/O=MarcScript/CN=${domain}" 2>/dev/null
    
    chmod 600 /etc/xray/xray.crt /etc/xray/xray.key 2>/dev/null
    
    # Try Let's Encrypt if domain is real
    if [[ "$domain" != *"."* ]]; then
        log_warn "Using self-signed certificate (no domain)"
    else
        log_info "Domain detected, you can install Let's Encrypt later with: certbot"
    fi
    
    log_success "Certificate created"
}
XRAYCERTEOF

    # ============================================================
    # Create xray/xray-config.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/xray/xray-config.sh << 'XRAYCONFIGEOF'
#!/bin/bash
source /usr/local/marcscript/lib/common.sh

generate_xray_config() {
    log_info "Generating Xray configuration..."
    
    uuid=$(cat /proc/sys/kernel/random/uuid)
    echo "$uuid" > /etc/xray/uuid
    
    cat > /etc/xray/config.json << XRAYJSON
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {
      "port": 23456, "listen": "127.0.0.1", "protocol": "vmess",
      "settings": {"clients": [{"id": "${uuid}", "alterId": 0}]},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vmess"}}
    },
    {
      "port": 14016, "listen": "127.0.0.1", "protocol": "vless",
      "settings": {"decryption": "none", "clients": [{"id": "${uuid}"}]},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vless"}}
    },
    {
      "port": 25432, "listen": "127.0.0.1", "protocol": "trojan",
      "settings": {"clients": [{"password": "${uuid}"}]},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/trojan-ws"}}
    }
  ],
  "outbounds": [{"protocol": "freedom", "settings": {}}]
}
XRAYJSON

    log_success "Xray config generated"
}
XRAYCONFIGEOF

    # ============================================================
    # Create menu/menu.sh
    # ============================================================
    cat > $MARCSCRIPT_DIR/menu/menu.sh << 'MENUEOF'
#!/bin/bash
# MarcScript Main Menu

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m          • MARCSCRIPT VPN MENU •           \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [\e[36m1\e[0m] SSH Menu"
echo -e " [\e[36m2\e[0m] V2Ray/Xray Menu"
echo -e " [\e[36m3\e[0m] Service Status"
echo -e " [\e[36m4\e[0m] Create SSH Account"
echo -e " [\e[36m5\e[0m] Create VMess Account"
echo -e " [\e[36m6\e[0m] Create VLess Account"
echo -e " [\e[36m7\e[0m] Create Trojan Account"
echo -e " [\e[36m8\e[0m] Delete Users"
echo -e ""
echo -e " [\e[31m0\e[0m] Exit"
echo -e ""
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " IP: \e[32m$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)\e[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
read -p "Select menu: " opt
case $opt in
    1) 
        clear
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\E[0;100;33m      • SSH MENU •        \E[0m"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "1. Create SSH User"
        echo -e "2. Delete SSH User"
        echo -e "3. List SSH Users"
        echo -e "0. Back"
        read -p "Select: " sshopt
        case $sshopt in
            1) add-ssh ;;
            2) del-ssh ;;
            3) list-ssh ;;
            0) menu ;;
        esac
        ;;
    2)
        clear
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\E[0;100;33m    • V2RAY/XRAY MENU •    \E[0m"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "1. VMess Menu"
        echo -e "2. VLess Menu"
        echo -e "3. Trojan Menu"
        echo -e "0. Back"
        read -p "Select: " xrayopt
        case $xrayopt in
            1) m-vmess ;;
            2) m-vless ;;
            3) m-trojan ;;
            0) menu ;;
        esac
        ;;
    3) vpn-status ; read -p "Press enter..." ; menu ;;
    4) add-ssh ; menu ;;
    5) add-ws ; menu ;;
    6) add-vless ; menu ;;
    7) add-tr ; menu ;;
    8) 
        clear
        echo -e "Delete User"
        echo -e "1. SSH  2. VMess  3. VLess  4. Trojan  0. Back"
        read -p "Select: " delopt
        case $delopt in
            1) del-ssh ;;
            2) del-ws ;;
            3) del-vless ;;
            4) del-tr ;;
            0) menu ;;
        esac
        menu
        ;;
    0) clear ; exit 0 ;;
    *) menu ;;
esac
MENUEOF

    # ============================================================
    # Create management scripts
    # ============================================================
    
    # add-ssh
    cat > /usr/local/bin/add-ssh << 'ADDSSHEOF'
#!/bin/bash
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m     • CREATE SSH ACCOUNT •      \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username : " USER
read -p "Password : " PASS
read -p "Expire (days) : " DAYS

useradd -m -s /bin/bash "$USER" 2>/dev/null
echo "$USER:$PASS" | chpasswd
EXPIRE_DATE=$(date -d "$DAYS days" +"%Y-%m-%d")
chage -E "$EXPIRE_DATE" "$USER" 2>/dev/null

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m    • ACCOUNT CREATED •        \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Username   : $USER"
echo -e "Password   : $PASS"
echo -e "Expired    : $EXPIRE_DATE"
echo -e "IP         : $(wget -qO- ipv4.icanhazip.com)"
echo -e "SSH Port   : 22, 80"
echo -e "SSL Port   : 443"
echo -e "WS Port    : 8080"
echo -e "Squid      : 3128, 8082, 8888"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
ADDSSHEOF
    chmod +x /usr/local/bin/add-ssh
    
    # del-ssh
    cat > /usr/local/bin/del-ssh << 'DELSSHEOF'
#!/bin/bash
clear
read -p "Username to delete: " USER
userdel -r "$USER" 2>/dev/null && echo "User $USER deleted" || echo "User not found"
DELSSHEOF
    chmod +x /usr/local/bin/del-ssh
    
    # list-ssh
    cat > /usr/local/bin/list-ssh << 'LISTSSHEOF'
#!/bin/bash
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m     • SSH USERS LIST •        \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "USERNAME          EXPIRED"
echo -e "----------------  -----------"
while IFS=: read -r user _ uid _; do
    if [ $uid -ge 1000 ]; then
        exp=$(chage -l "$user" 2>/dev/null | grep "Account expires" | cut -d: -f2)
        printf "%-16s %s\n" "$user" "${exp:-Never}"
    fi
done < /etc/passwd
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
LISTSSHEOF
    chmod +x /usr/local/bin/list-ssh
    
    # vpn-status
    cat > /usr/local/bin/vpn-status << 'STATUSEOF'
#!/bin/bash
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m   • MARCSCRIPT VPN STATUS •   \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
echo -e "SSH         : $(systemctl is-active ssh 2>/dev/null || echo 'dead')"
echo -e "Stunnel     : $(systemctl is-active stunnel4 2>/dev/null || echo 'dead')"
echo -e "Nginx       : $(systemctl is-active nginx 2>/dev/null || echo 'dead')"
echo -e "Xray        : $(systemctl is-active xray 2>/dev/null || echo 'dead')"
echo -e "Squid       : $(systemctl is-active squid 2>/dev/null || echo 'dead')"
echo -e "WS Proxy    : $(systemctl is-active ws-proxy 2>/dev/null || echo 'dead')"
echo ""
echo -e "IP : $(wget -qO- ipv4.icanhazip.com)"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
STATUSEOF
    chmod +x /usr/local/bin/vpn-status
    
    # Xray management scripts
    # add-ws (VMess)
    cat > /usr/local/bin/add-ws << 'ADDWSEOF'
#!/bin/bash
clear
domain=$(cat /etc/xray/domain 2>/dev/null || wget -qO- ipv4.icanhazip.com)
uuid=$(cat /etc/xray/uuid 2>/dev/null || echo "auto")

echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m   • CREATE VMESS ACCOUNT •   \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username : " user
read -p "Expired (days): " days

exp=$(date -d "$days days" +"%Y-%m-%d")
echo "### ${user} ${exp}" >> /etc/xray/vmess.db

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m  • VMESS ACCOUNT CREATED •  \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Protocol   : VMess WS"
echo -e "Domain     : ${domain}"
echo -e "Port TLS   : 443"
echo -e "Port NTLS  : 80"
echo -e "UUID       : ${uuid}"
echo -e "AlterID    : 0"
echo -e "Path       : /vmess"
echo -e "Expired    : ${exp}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
ADDWSEOF
    chmod +x /usr/local/bin/add-ws
    
    # add-vless
    cat > /usr/local/bin/add-vless << 'ADDVLESSEOF'
#!/bin/bash
clear
domain=$(cat /etc/xray/domain 2>/dev/null || wget -qO- ipv4.icanhazip.com)
uuid=$(cat /etc/xray/uuid 2>/dev/null || echo "auto")

echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m   • CREATE VLESS ACCOUNT •   \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username : " user
read -p "Expired (days): " days

exp=$(date -d "$days days" +"%Y-%m-%d")
echo "### ${user} ${exp}" >> /etc/xray/vless.db

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m  • VLESS ACCOUNT CREATED •  \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Protocol   : VLess WS"
echo -e "Domain     : ${domain}"
echo -e "Port TLS   : 443"
echo -e "Port NTLS  : 80"
echo -e "UUID       : ${uuid}"
echo -e "Path       : /vless"
echo -e "Expired    : ${exp}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
ADDVLESSEOF
    chmod +x /usr/local/bin/add-vless
    
    # add-tr (Trojan)
    cat > /usr/local/bin/add-tr << 'ADDTREOF'
#!/bin/bash
clear
domain=$(cat /etc/xray/domain 2>/dev/null || wget -qO- ipv4.icanhazip.com)
uuid=$(cat /etc/xray/uuid 2>/dev/null || echo "auto")

echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m  • CREATE TROJAN ACCOUNT •  \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username : " user
read -p "Expired (days): " days

exp=$(date -d "$days days" +"%Y-%m-%d")
echo "### ${user} ${exp}" >> /etc/xray/trojan.db

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m • TROJAN ACCOUNT CREATED • \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Protocol   : Trojan WS"
echo -e "Domain     : ${domain}"
echo -e "Port TLS   : 443"
echo -e "Port NTLS  : 80"
echo -e "Password   : ${uuid}"
echo -e "Path       : /trojan-ws"
echo -e "Expired    : ${exp}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
ADDTREOF
    chmod +x /usr/local/bin/add-tr
    
    # Delete scripts for Xray
    for proto in ws vless tr; do
        cat > /usr/local/bin/del-${proto} << DELEOF
#!/bin/bash
clear
read -p "Username to delete: " user
sed -i "/\${user}/d" /etc/xray/${proto}.db 2>/dev/null
echo "User \${user} deleted"
systemctl restart xray 2>/dev/null
DELEOF
        chmod +x /usr/local/bin/del-${proto}
    done
    
    # VMess/VLess/Trojan menu scripts
    for proto in vmess vless trojan; do
        cat > /usr/local/bin/m-${proto} << MENUEOF
#!/bin/bash
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m       • ${proto^^} MENU •         \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [1] Create Account"
echo -e " [2] Delete Account"
echo -e " [3] Renew Account"
echo -e ""
echo -e " [0] Back to Menu"
echo -e ""
read -p "Select: " opt
case \$opt in
    1) add-${proto%ss} ;;
    2) del-${proto%ss} ;;
    3) 
        read -p "Username: " user
        read -p "Days: " days
        exp=\$(date -d "\$days days" +"%Y-%m-%d")
        sed -i "s/### \${user} .*/### \${user} \${exp}/" /etc/xray/${proto%ss}.db 2>/dev/null
        echo "Account \$user renewed until \$exp"
        sleep 2
        ;;
    0) menu ;;
esac
MENUEOF
        chmod +x /usr/local/bin/m-${proto}
    done
    
    # Create Xray database files
    touch /etc/xray/{vmess,vless,trojan}.db
    
    # Create menu symlink
    ln -sf /usr/local/marcscript/menu/menu.sh /usr/local/bin/menu 2>/dev/null
    
    echo -e "${GREEN}✅ All files created locally${NC}"
fi

# ============================================================
# STEP 3: Set Permissions
# ============================================================
echo ""
echo -e "${YELLOW}🔧 Setting permissions...${NC}"

find /usr/local/marcscript -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null
chmod +x /usr/local/bin/{add-ssh,del-ssh,list-ssh,add-ws,add-vless,add-tr,vpn-status,menu} 2>/dev/null
chmod +x /usr/local/bin/{del-ws,del-vless,del-tr,m-vmess,m-vless,m-trojan} 2>/dev/null

echo -e "${GREEN}✅ Permissions set${NC}"
echo ""

# ============================================================
# STEP 4: Install Services
# ============================================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}   📦 INSTALLING MARCSCRIPT SERVICES${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Source common functions
source /usr/local/marcscript/lib/common.sh
source /usr/local/marcscript/lib/packages.sh
source /usr/local/marcscript/lib/firewall.sh
source /usr/local/marcscript/ssh/ssh-setup.sh
source /usr/local/marcscript/services/stunnel.sh
source /usr/local/marcscript/services/websocket.sh
source /usr/local/marcscript/services/squid.sh
source /usr/local/marcscript/services/nginx.sh
source /usr/local/marcscript/xray/xray-core.sh
source /usr/local/marcscript/xray/xray-cert.sh
source /usr/local/marcscript/xray/xray-config.sh

# Run installations
install_packages
configure_ssh
configure_stunnel
configure_websocket
configure_squid
configure_firewall

# Ask for Xray
echo ""
read -p "Install Xray (VMess/VLess/Trojan)? [Y/n]: " install_xray
if [[ ! "$install_xray" =~ ^[Nn]$ ]]; then
    install_xray
    setup_xray_cert
    generate_xray_config
    configure_nginx
    
    systemctl daemon-reload
    systemctl enable xray 2>/dev/null
    systemctl restart xray 2>/dev/null
    
    # Save domain
    if [ -f /root/domain ]; then
        cp /root/domain /etc/xray/domain
    elif [ ! -f /etc/xray/domain ]; then
        echo "$MYIP" > /etc/xray/domain
    fi
    
    echo -e "${GREEN}✅ Xray installed${NC}"
fi

# Add menu to .bashrc
if ! grep -q "menu" /root/.bashrc 2>/dev/null; then
    echo '' >> /root/.bashrc
    echo '# MarcScript Menu' >> /root/.bashrc
    echo 'if [ -f /usr/local/marcscript/menu/menu.sh ]; then' >> /root/.bashrc
    echo '    /usr/local/marcscript/menu/menu.sh' >> /root/.bashrc
    echo 'fi' >> /root/.bashrc
fi

# ============================================================
# DONE
# ============================================================
clear
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${PURPLE}   ✅ MARCSCRIPT INSTALLATION COMPLETE!${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e " Type ${GREEN}menu${NC} to access the control panel"
echo ""
echo -e " ${CYAN}IP:${NC} ${GREEN}$MYIP${NC}"
echo -e " ${CYAN}Domain:${NC} ${GREEN}$(cat /etc/xray/domain 2>/dev/null || echo 'Not Set')${NC}"
echo ""
echo -e " ${CYAN}Ports:${NC}"
echo -e "   SSH      : 22, 80"
echo -e "   SSL      : 443, 8443"
echo -e "   WS       : 8080"
echo -e "   Squid    : 3128, 8082, 8888"
echo -e "   Nginx    : 80, 443"
echo ""
echo -e " ${CYAN}Commands:${NC}"
echo -e "   menu       - Main menu"
echo -e "   add-ssh    - Create SSH user"
echo -e "   add-ws     - Create VMess"
echo -e "   add-vless  - Create VLess"
echo -e "   add-tr     - Create Trojan"
echo -e "   vpn-status - Service status"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
