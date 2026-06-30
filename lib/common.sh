#!/bin/bash
# MarcScript - Common Variables and Functions

# Global settings
BACKUP_DIR="/root/marcscript-backup-$(date +%Y%m%d_%H%M%S)"
LOG_FILE="/var/log/marcscript-install.log"
JSON_FILE="/etc/marcscript-config.json"
INSTALL_ID=$(date +%Y%m%d_%H%M%S)
API_PORT=3021

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Get IP
MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${BLUE}[SUCCESS]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_FILE"
}

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

# Get domain
get_domain() {
    if [ -f /etc/xray/domain ]; then
        cat /etc/xray/domain
    elif [ -f /root/domain ]; then
        cat /root/domain
    else
        echo "$MYIP"
    fi
}
