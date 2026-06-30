#!/bin/bash
# ============================================================
# MARCSCRIPT - Package Installer
# Compatible: Ubuntu 18.04+, Debian 10+
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh

# ============================================================
# System Update
# ============================================================
system_update() {
    log "Updating system packages..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    # Update package lists
    apt update -y >/dev/null 2>&1 || {
        wrn "Package update had warnings, continuing..."
    }
    
    # Upgrade existing packages
    apt upgrade -y >/dev/null 2>&1 || {
        wrn "Package upgrade had warnings, continuing..."
    }
    
    # Fix broken dependencies
    apt --fix-broken install -y >/dev/null 2>&1
    
    log "System updated"
}

# ============================================================
# Install Essential Packages
# ============================================================
install_essentials() {
    log "Installing essential packages..."
    
    local packages=(
        # System tools
        curl
        wget
        git
        unzip
        tar
        gzip
        
        # Network tools
        net-tools
        dnsutils
        netcat-openbsd
        lsof
        screen
        socat
        
        # Security
        openssl
        ca-certificates
        gnupg
        gnupg2
        
        # Utilities
        cron
        jq
        xz-utils
        bzip2
        pwgen
        lsb-release
        
        # Build tools
        build-essential
        make
        gcc
        
        # Others
        software-properties-common
        apt-transport-https
        bash-completion
        iptables
        iptables-persistent
    )
    
    for pkg in "${packages[@]}"; do
        if ! dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
            echo -e "  ${GREEN}→${NC} Installing $pkg..."
            apt install -y "$pkg" >/dev/null 2>&1 || {
                wrn "Failed to install $pkg, skipping..."
            }
        fi
    done
    
    log "Essential packages installed"
}

# ============================================================
# Install SSH Server
# ============================================================
install_ssh() {
    log "Installing OpenSSH Server..."
    
    if ! dpkg -l | grep -q "^ii  openssh-server "; then
        apt install -y openssh-server >/dev/null 2>&1
    fi
    
    # Ensure SSH is running
    systemctl enable ssh >/dev/null 2>&1
    systemctl start ssh >/dev/null 2>&1
    
    log "OpenSSH Server installed"
}

# ============================================================
# Install Stunnel (SSL Tunnel)
# ============================================================
install_stunnel() {
    log "Installing Stunnel..."
    
    if ! dpkg -l | grep -q "^ii  stunnel4 "; then
        apt install -y stunnel4 >/dev/null 2>&1
    fi
    
    # Enable Stunnel service
    systemctl enable stunnel4 >/dev/null 2>&1 || true
    
    log "Stunnel installed"
}

# ============================================================
# Install Squid Proxy
# ============================================================
install_squid() {
    log "Installing Squid Proxy..."
    
    if ! dpkg -l | grep -q "^ii  squid "; then
        apt install -y squid >/dev/null 2>&1
    fi
    
    # Backup original config
    if [ -f /etc/squid/squid.conf ]; then
        cp /etc/squid/squid.conf /etc/squid/squid.conf.bak 2>/dev/null
    fi
    
    # Create cache directories
    mkdir -p /var/spool/squid
    chown -R proxy:proxy /var/spool/squid 2>/dev/null || true
    
    systemctl enable squid >/dev/null 2>&1 || true
    
    log "Squid Proxy installed"
}

# ============================================================
# Install Nginx Web Server
# ============================================================
install_nginx() {
    log "Installing Nginx..."
    
    if ! dpkg -l | grep -q "^ii  nginx "; then
        apt install -y nginx >/dev/null 2>&1
    fi
    
    # Create web directory
    mkdir -p /home/vps/public_html
    
    # Create index page
    cat > /home/vps/public_html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MarcScript VPN</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            padding: 40px;
            background: rgba(255,255,255,0.1);
            border-radius: 20px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 3em; margin: 0; }
        p { font-size: 1.2em; opacity: 0.9; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 MarcScript VPN</h1>
        <p>Secure • Fast • Reliable</p>
        <p>Server is running!</p>
    </div>
</body>
</html>
EOF
    
    # Remove default nginx config
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null
    rm -f /etc/nginx/sites-available/default 2>/dev/null
    
    systemctl enable nginx >/dev/null 2>&1
    
    log "Nginx installed"
}

# ============================================================
# Install Node.js
# ============================================================
install_nodejs() {
    log "Installing Node.js..."
    
    if ! command -v node &>/dev/null; then
        # Try NodeSource first
        if curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1; then
            apt install -y nodejs >/dev/null 2>&1
        else
            # Fallback to distribution package
            apt install -y nodejs npm >/dev/null 2>&1
        fi
    fi
    
    # Verify installation
    if command -v node &>/dev/null; then
        log "Node.js $(node -v) installed"
    else
        wrn "Node.js installation failed, some features may not work"
    fi
}

# ============================================================
# Install Xray Core
# ============================================================
install_xray() {
    log "Installing Xray Core..."
    
    # Create directories
    mkdir -p /etc/xray
    mkdir -p /var/log/xray
    mkdir -p /run/xray
    
    # Download official installer
    if curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh -o /tmp/xray-install.sh 2>/dev/null; then
        bash /tmp/xray-install.sh @ install -u www-data >/dev/null 2>&1 || {
            wrn "Xray official install failed, trying manual..."
            install_xray_manual
        }
        rm -f /tmp/xray-install.sh
    else
        wrn "Cannot download Xray installer, trying manual..."
        install_xray_manual
    fi
    
    # Set permissions
    chown www-data:www-data /run/xray 2>/dev/null || true
    chown www-data:www-data /var/log/xray 2>/dev/null || true
    
    # Create log files
    touch /var/log/xray/access.log /var/log/xray/error.log
    chown www-data:www-data /var/log/xray/*.log 2>/dev/null || true
    
    # Create systemd service
    cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

    # Create runn service helper
    cat > /etc/systemd/system/runn.service << 'EOF'
[Unit]
Description=Xray Directory Setup
After=network.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/mkdir -p /var/run/xray
ExecStart=/usr/bin/chown www-data:www-data /var/run/xray
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable xray runn 2>/dev/null || true
    
    log "Xray Core installed"
}

# ============================================================
# Manual Xray Installation (Fallback)
# ============================================================
install_xray_manual() {
    log "Installing Xray manually..."
    
    # Detect architecture
    local arch=""
    case $(uname -m) in
        x86_64) arch="64" ;;
        aarch64) arch="arm64-v8a" ;;
        armv7l) arch="arm32-v7a" ;;
        *) 
            err "Unsupported architecture: $(uname -m)"
            return 1
            ;;
    esac
    
    # Download latest Xray
    local xray_url="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${arch}.zip"
    
    wget -q "$xray_url" -O /tmp/xray.zip 2>/dev/null || {
        err "Failed to download Xray"
        return 1
    }
    
    # Extract
    unzip -o /tmp/xray.zip -d /usr/local/bin/ >/dev/null 2>&1
    chmod +x /usr/local/bin/xray
    
    # Cleanup
    rm -f /tmp/xray.zip
    
    log "Xray installed manually"
}

# ============================================================
# Install All Core Packages
# ============================================================
install_core_packages() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}📦 INSTALLING CORE PACKAGES${NC}                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    system_update
    install_essentials
    install_ssh
    install_stunnel
    install_squid
    install_nginx
    install_nodejs
    
    log "All core packages installed"
}

# ============================================================
# Check Package Status
# ============================================================
check_packages() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}PACKAGE INSTALLATION STATUS${NC}                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local packages=(
        "openssh-server"
        "stunnel4"
        "nginx"
        "squid"
        "nodejs"
        "curl"
        "wget"
        "jq"
        "net-tools"
    )
    
    for pkg in "${packages[@]}"; do
        if dpkg -l 2>/dev/null | grep -q "^ii  $pkg "; then
            echo -e "  ${GREEN}✓${NC} $pkg"
        else
            echo -e "  ${RED}✗${NC} $pkg"
        fi
    done
    
    # Check Xray
    if [ -f /usr/local/bin/xray ]; then
        echo -e "  ${GREEN}✓${NC} xray ($(/usr/local/bin/xray version 2>/dev/null | head -1))"
    else
        echo -e "  ${RED}✗${NC} xray"
    fi
    
    echo ""
}

# ============================================================
# Remove Packages (For uninstall)
# ============================================================
remove_packages() {
    log "Removing MarcScript packages..."
    
    local packages=(
        "openssh-server"
        "stunnel4"
        "nginx"
        "squid"
        "nodejs"
    )
    
    for pkg in "${packages[@]}"; do
        echo -e "  ${YELLOW}→${NC} Removing $pkg..."
        apt remove -y "$pkg" >/dev/null 2>&1 || true
    done
    
    # Remove Xray
    if [ -f /usr/local/bin/xray ]; then
        systemctl stop xray 2>/dev/null || true
        systemctl disable xray 2>/dev/null || true
        rm -f /usr/local/bin/xray
        rm -f /usr/local/bin/xray_*
    fi
    
    # Cleanup
    apt autoremove -y >/dev/null 2>&1
    
    log "Packages removed"
}

# ============================================================
# Main (if run directly)
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        install|"")
            install_core_packages
            ;;
        xray)
            install_xray
            ;;
        check)
            check_packages
            ;;
        remove|uninstall)
            remove_packages
            ;;
        *)
            echo "Usage: $0 {install|xray|check|remove}"
            echo ""
            echo "  install   - Install all core packages (default)"
            echo "  xray      - Install Xray core only"
            echo "  check     - Check package status"
            echo "  remove    - Remove all packages"
            ;;
    esac
fi
