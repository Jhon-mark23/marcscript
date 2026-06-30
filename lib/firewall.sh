#!/bin/bash
# ============================================================
# MARCSCRIPT - Firewall Configuration
# Compatible: Ubuntu 18.04+, Debian 10+
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || source $(dirname "$0")/common.sh

# ============================================================
# Configure UFW Firewall
# ============================================================
configure_ufw() {
    log "Configuring UFW Firewall..."
    
    # Reset UFW
    ufw --force reset >/dev/null 2>&1
    
    # Default policies
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    
    # SSH ports
    ufw allow 22/tcp >/dev/null 2>&1
    ufw allow 80/tcp >/dev/null 2>&1
    
    # Web Server
    ufw allow 81/tcp >/dev/null 2>&1
    ufw allow 443/tcp >/dev/null 2>&1
    
    # WebSocket
    ufw allow 8080/tcp >/dev/null 2>&1
    ufw allow 8443/tcp >/dev/null 2>&1
    
    # Squid Proxy
    ufw allow 3128/tcp >/dev/null 2>&1
    ufw allow 8082/tcp >/dev/null 2>&1
    ufw allow 8888/tcp >/dev/null 2>&1
    
    # Xray ports (if needed directly)
    ufw allow 10000:20000/tcp >/dev/null 2>&1
    ufw allow 10000:20000/udp >/dev/null 2>&1
    
    # Enable UFW
    echo "y" | ufw enable >/dev/null 2>&1
    
    # Reload rules
    ufw reload >/dev/null 2>&1
    
    log "UFW configured successfully"
    
    # Show status
    echo ""
    echo -e "${CYAN}Firewall Rules:${NC}"
    ufw status numbered | grep -v "Status" | head -15
    echo ""
}

# ============================================================
# Configure IPTables (Fallback if UFW not available)
# ============================================================
configure_iptables() {
    log "Configuring IPTables..."
    
    # Flush existing rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    
    # Default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # SSH
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    
    # Web
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    iptables -A INPUT -p tcp --dport 81 -j ACCEPT
    
    # WebSocket
    iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8443 -j ACCEPT
    
    # Squid
    iptables -A INPUT -p tcp --dport 3128 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8082 -j ACCEPT
    iptables -A INPUT -p tcp --dport 8888 -j ACCEPT
    
    # Save rules
    if command -v iptables-save &>/dev/null; then
        iptables-save > /etc/iptables.rules 2>/dev/null
    fi
    
    # Install iptables-persistent for auto-load
    if ! dpkg -l | grep -q "iptables-persistent"; then
        echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections 2>/dev/null
        echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections 2>/dev/null
        apt install -y iptables-persistent >/dev/null 2>&1
    fi
    
    log "IPTables configured"
}

# ============================================================
# Main Firewall Configuration
# ============================================================
setup_firewall() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}🔒 CONFIGURING FIREWALL${NC}                         ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if command -v ufw &>/dev/null; then
        configure_ufw
    else
        log "UFW not found, installing..."
        apt install -y ufw >/dev/null 2>&1
        if command -v ufw &>/dev/null; then
            configure_ufw
        else
            configure_iptables
        fi
    fi
    
    log "Firewall configuration complete"
}

# ============================================================
# Open Specific Port
# ============================================================
open_port() {
    local port=$1
    local proto=${2:-tcp}
    
    if [ -z "$port" ]; then
        echo "Usage: open_port <port> [tcp|udp]"
        return 1
    fi
    
    if command -v ufw &>/dev/null; then
        ufw allow $port/$proto >/dev/null 2>&1
        log "Port $port/$proto opened via UFW"
    else
        iptables -A INPUT -p $proto --dport $port -j ACCEPT
        log "Port $port/$proto opened via IPTables"
    fi
}

# ============================================================
# Close Specific Port
# ============================================================
close_port() {
    local port=$1
    local proto=${2:-tcp}
    
    if [ -z "$port" ]; then
        echo "Usage: close_port <port> [tcp|udp]"
        return 1
    fi
    
    if command -v ufw &>/dev/null; then
        ufw deny $port/$proto >/dev/null 2>&1
        log "Port $port/$proto closed via UFW"
    else
        iptables -D INPUT -p $proto --dport $port -j ACCEPT 2>/dev/null
        log "Port $port/$proto closed via IPTables"
    fi
}

# ============================================================
# Show Firewall Status
# ============================================================
firewall_status() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}FIREWALL STATUS${NC}                               ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if command -v ufw &>/dev/null; then
        ufw status verbose
    else
        iptables -L INPUT -n --line-numbers
    fi
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        setup|install)
            setup_firewall
            ;;
        open)
            open_port "$2" "$3"
            ;;
        close)
            close_port "$2" "$3"
            ;;
        status)
            firewall_status
            ;;
        *)
            echo "Usage: $0 {setup|open|close|status}"
            echo ""
            echo "  setup   - Configure firewall with default rules"
            echo "  open    - Open a port (usage: $0 open <port> [tcp|udp])"
            echo "  close   - Close a port (usage: $0 close <port> [tcp|udp])"
            echo "  status  - Show firewall status"
            ;;
    esac
fi
