#!/bin/bash
# ============================================================
# MARCSCRIPT - Squid Proxy Configuration
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || source $(dirname "$0")/../lib/common.sh

# ============================================================
# Configure Squid Proxy
# ============================================================
configure_squid() {
    log "Configuring Squid Proxy..."
    
    # Backup existing config
    if [ -f /etc/squid/squid.conf ]; then
        cp /etc/squid/squid.conf /etc/squid/squid.conf.bak
    fi
    
    # Create configuration
    cat > /etc/squid/squid.conf << 'EOF'
# MarcScript Squid Proxy Configuration
# Ports: 3128, 8082, 8888

# Listening ports
http_port 3128
http_port 8082
http_port 8888

# Access control
acl all src 0.0.0.0/0
acl localhost src 127.0.0.1/32
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT

# Allow rules
http_access allow all
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports

# Cache settings
cache_dir ufs /var/spool/squid 100 16 256
cache_mem 128 MB
maximum_object_size_in_memory 512 KB
maximum_object_size 4096 MB
minimum_object_size 0 KB

# Performance
cache_swap_low 90
cache_swap_high 95

# Logs
access_log /var/log/squid/access.log
cache_log /var/log/squid/cache.log

# Privacy
forwarded_for off
request_header_access X-Forwarded-For deny all
request_header_access Via deny all
request_header_access Cache-Control deny all

# General
visible_hostname MarcScript-Proxy
dns_nameservers 8.8.8.8 8.8.4.4 1.1.1.1
dns_v4_first on

# Timeouts
connect_timeout 30 seconds
peer_connect_timeout 30 seconds
read_timeout 5 minutes
request_timeout 5 minutes
shutdown_lifetime 10 seconds

# Memory
memory_pools off
EOF

    # Create cache directories
    mkdir -p /var/spool/squid
    chown -R proxy:proxy /var/spool/squid 2>/dev/null || true
    squid -z >/dev/null 2>&1 || true
    
    # Restart service
    systemctl enable squid >/dev/null 2>&1
    systemctl restart squid >/dev/null 2>&1
    
    # Verify
    sleep 2
    if systemctl is-active --quiet squid; then
        log "Squid proxy configured on ports: 3128, 8082, 8888"
    else
        err "Squid failed to start"
        systemctl status squid --no-pager
    fi
}

# ============================================================
# Add Squid User
# ============================================================
add_squid_user() {
    local user=$1
    local pass=$2
    
    if [ -z "$user" ] || [ -z "$pass" ]; then
        echo "Usage: add_squid_user <username> <password>"
        return 1
    fi
    
    # Install htpasswd if needed
    if ! command -v htpasswd &>/dev/null; then
        apt install -y apache2-utils >/dev/null 2>&1
    fi
    
    mkdir -p /etc/squid
    touch /etc/squid/passwd
    
    htpasswd -b /etc/squid/passwd "$user" "$pass" 2>/dev/null
    
    # Add auth config if not present
    if ! grep -q "auth_param" /etc/squid/squid.conf; then
        cat >> /etc/squid/squid.conf << 'EOF'

# Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic realm MarcScript Proxy
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
EOF
    fi
    
    systemctl reload squid
    log "Squid user $user added"
}

# ============================================================
# Squid Status
# ============================================================
squid_status() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}SQUID PROXY STATUS${NC}                             ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "Service: $(systemctl is-active squid)"
    echo -e "Ports: 3128, 8082, 8888"
    echo ""
    
    if systemctl is-active --quiet squid; then
        echo -e "${YELLOW}Active connections:${NC}"
        netstat -tnp 2>/dev/null | grep squid | head -10 || ss -tnp | grep squid | head -10
    fi
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        install|setup)
            configure_squid
            ;;
        adduser)
            add_squid_user "$2" "$3"
            ;;
        status)
            squid_status
            ;;
        restart)
            systemctl restart squid
            log "Squid restarted"
            ;;
        logs)
            tail -f /var/log/squid/access.log
            ;;
        *)
            echo "Usage: $0 {install|adduser|status|restart|logs}"
            ;;
    esac
fi
