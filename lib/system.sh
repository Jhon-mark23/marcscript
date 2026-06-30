#!/bin/bash
# MarcScript - System Information

source /usr/local/marcscript/lib/common.sh

get_system_info() {
    log_info "Gathering system information..."
    
    ARCH=$(uname -m)
    OS=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Debian/Ubuntu")
    KERNEL=$(uname -r)
    
    log_info "OS: $OS | Arch: $ARCH | IP: $MYIP"
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    fi
}
