#!/bin/bash
# MarcScript - Package Installation

source /usr/local/marcscript/lib/common.sh

install_base_packages() {
    log_info "Installing base packages..."
    
    export DEBIAN_FRONTEND=noninteractive
    apt update -y >/dev/null 2>&1
    
    PACKAGES="openssh-server stunnel4 squid ufw nginx curl wget lsof net-tools jq
    openssl cron socat netcat-openbsd dnsutils screen xz-utils"
    
    for pkg in $PACKAGES; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            apt install -y $pkg >/dev/null 2>&1
        fi
    done
    
    # Install Node.js if not present
    if ! command -v node &>/dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
        apt install -y nodejs >/dev/null 2>&1
    fi
    
    log_success "Base packages installed"
}
