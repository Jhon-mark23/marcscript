#!/bin/bash
# MarcScript - Firewall Configuration

source /usr/local/marcscript/lib/common.sh

configure_firewall() {
    log_info "Configuring firewall..."
    
    if command -v ufw &>/dev/null; then
        ufw --force reset >/dev/null 2>&1
        
        # Common ports
        for port in 22 80 81 443 3128 8000 8080 8082 8443 8888; do
            ufw allow $port/tcp >/dev/null 2>&1
        done
        
        # UDP ports for Xray
        for port in 10000 20000 30000; do
            ufw allow $port/udp >/dev/null 2>&1
        done
        
        # API port
        ufw allow from 127.0.0.1 to any port 3021 >/dev/null 2>&1
        
        echo "y" | ufw enable >/dev/null 2>&1
    fi
    
    log_success "Firewall configured"
}
