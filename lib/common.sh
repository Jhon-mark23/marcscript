#!/bin/bash
# ============================================================
# MARCSCRIPT - Common Functions
# ============================================================

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export PURPLE='\033[0;35m'
export NC='\033[0m'

# System info
export MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)
export DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "$MYIP")
export MARCSCRIPT_DIR="/usr/local/marcscript"

# Logging
log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }
wrn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        err "Please run as root"
        exit 1
    fi
}

# Get random
random_str() { cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-10} | head -n 1; }

# Check service
service_status() {
    if systemctl is-active --quiet $1 2>/dev/null; then
        echo -e "${GREEN}Active${NC}"
    else
        echo -e "${RED}Dead${NC}"
    fi
}

# Xray submenu
xray_menu() {
    local proto=$1
    clear
    echo -e "\033[0;36m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[0;36m║\033[0m                  \033[1;33m${proto^^} MENU\033[0m                            \033[0;36m║\033[0m"
    echo -e "\033[0;36m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "  \033[1;36m[1]\033[0m Create Account"
    echo -e "  \033[1;36m[2]\033[0m Delete Account"
    echo -e "  \033[1;36m[3]\033[0m Renew Account"
    echo -e "  \033[1;36m[4]\033[0m List Users"
    echo ""
    echo -e "  \033[1;31m[0]\033[0m Back"
    echo ""
    read -p "Select : " opt
    case $opt in
        1) 
            case $proto in
                vmess) add-vmess ;;
                vless) add-vless ;;
                trojan) add-trojan ;;
                ss) add-ss ;;
            esac
            ;;
        2) del-user $proto ;;
        3) 
            read -p "Username: " user
            read -p "Days: " days
            exp=$(date -d "$days days" +"%Y-%m-%d")
            sed -i "s/### ${user} .*/### ${user} ${exp}/" /etc/xray/${proto}.db 2>/dev/null
            echo -e "${GREEN}Account $user renewed until $exp${NC}"
            sleep 2
            ;;
        4) cat /etc/xray/${proto}.db 2>/dev/null | grep -v "^#" | grep -v "^$" || echo "No users" ;;
        0) menu ;;
    esac
}
