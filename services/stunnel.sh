#!/bin/bash
# ============================================================
# MARCSCRIPT - Stunnel SSL Configuration
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || source $(dirname "$0")/../lib/common.sh

# ============================================================
# Generate SSL Certificate
# ============================================================
generate_certificate() {
    log "Generating SSL certificate..."
    
    mkdir -p /etc/stunnel
    
    openssl req -new -x509 -days 3650 -nodes \
        -subj "/C=PH/ST=Metro Manila/L=Manila/O=MarcScript/CN=MarcScript VPN" \
        -out /etc/stunnel/stunnel.pem \
        -keyout /etc/stunnel/stunnel.pem 2>/dev/null
    
    chmod 600 /etc/stunnel/stunnel.pem
    
    log "SSL certificate generated"
}

# ============================================================
# Configure Stunnel
# ============================================================
configure_stunnel() {
    log "Configuring Stunnel..."
    
    # Backup existing config
    if [ -f /etc/stunnel/stunnel.conf ]; then
        cp /etc/stunnel/stunnel.conf /etc/stunnel/stunnel.conf.bak
    fi
    
    # Generate certificate if not exists
    if [ ! -f /etc/stunnel/stunnel.pem ]; then
        generate_certificate
    fi
    
    # Create configuration
    cat > /etc/stunnel/stunnel.conf << 'EOF'
# Stunnel Configuration for MarcScript VPN
pid = /var/run/stunnel.pid
client = no
output = /var/log/stunnel.log
foreground = no
debug = 3
syslog = yes

# Socket options
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

# Compression
compression = zlib

# SSL/TLS Settings
sslVersionMin = TLSv1.2
options = NO_SSLv2
options = NO_SSLv3
options = NO_TLSv1
options = NO_TLSv1.1
ciphers = HIGH:!aNULL:!MD5:!DH
TIMEOUTclose = 0

# SSH SSL Tunnel (Port 443 -> SSH Port 22)
[ssh-ssl]
accept = 443
connect = 127.0.0.1:22
cert = /etc/stunnel/stunnel.pem
TIMEOUTclose = 0
TIMEOUTidle = 60

# SSH SSL Alternative (Port 444)
[ssh-ssl-alt]
accept = 444
connect = 127.0.0.1:22
cert = /etc/stunnel/stunnel.pem
TIMEOUTclose = 0

# WebSocket SSL (Port 8443 -> WebSocket Port 8080)
[ws-ssl]
accept = 8443
connect = 127.0.0.1:8080
cert = /etc/stunnel/stunnel.pem
TIMEOUTclose = 0
TIMEOUTidle = 60

# Dropbear SSL (Port 442 -> Dropbear if installed)
;[dropbear-ssl]
;accept = 442
;connect = 127.0.0.1:109
;cert = /etc/stunnel/stunnel.pem
EOF

    # Enable Stunnel
    if [ -f /etc/default/stunnel4 ]; then
        sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4
    else
        echo "ENABLED=1" > /etc/default/stunnel4
    fi
    
    # Create log file
    touch /var/log/stunnel.log
    chmod 644 /var/log/stunnel.log
    
    # Restart service
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable stunnel4 >/dev/null 2>&1
    systemctl restart stunnel4 >/dev/null 2>&1
    
    # Verify
    sleep 2
    if systemctl is-active --quiet stunnel4; then
        log "Stunnel configured on ports: 443, 444, 8443"
    else
        err "Stunnel failed to start"
        systemctl status stunnel4 --no-pager
    fi
}

# ============================================================
# Add Custom Stunnel Port
# ============================================================
add_stunnel_port() {
    local port=$1
    local target=$2
    local name=$3
    
    if [ -z "$port" ] || [ -z "$target" ]; then
        echo "Usage: add_stunnel_port <port> <target_ip:port> [name]"
        return 1
    fi
    
    [ -z "$name" ] && name="custom-${port}"
    
    cat >> /etc/stunnel/stunnel.conf << EOF

# Custom: ${name}
[${name}]
accept = ${port}
connect = ${target}
cert = /etc/stunnel/stunnel.pem
EOF

    systemctl restart stunnel4
    log "Stunnel port ${port} added -> ${target}"
}

# ============================================================
# Stunnel Status
# ============================================================
stunnel_status() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}STUNNEL STATUS${NC}                                ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "Status: $(systemctl is-active stunnel4)"
    echo -e "Ports listening:"
    netstat -tlnp 2>/dev/null | grep stunnel || ss -tlnp | grep stunnel
    echo ""
    
    if [ -f /var/log/stunnel.log ]; then
        echo -e "${YELLOW}Recent logs:${NC}"
        tail -5 /var/log/stunnel.log
    fi
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        install|setup)
            configure_stunnel
            ;;
        cert)
            generate_certificate
            ;;
        add)
            add_stunnel_port "$2" "$3" "$4"
            ;;
        status)
            stunnel_status
            ;;
        restart)
            systemctl restart stunnel4
            log "Stunnel restarted"
            ;;
        *)
            echo "Usage: $0 {install|cert|add|status|restart}"
            echo ""
            echo "  install  - Configure Stunnel"
            echo "  cert     - Generate new SSL certificate"
            echo "  add      - Add custom port (usage: $0 add <port> <target_ip:port> [name])"
            echo "  status   - Show Stunnel status"
            echo "  restart  - Restart Stunnel service"
            ;;
    esac
fi
