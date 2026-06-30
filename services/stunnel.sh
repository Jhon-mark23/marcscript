#!/bin/bash
# ============================================================
# MARCSCRIPT - Stunnel SSL Configuration
# Ports: 8445 (SSH SSL), 8446 (WS SSL)
# Nginx uses: 443 for Xray
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || source $(dirname "$0")/../lib/common.sh

configure_stunnel() {
    log "Configuring Stunnel SSL on ports 8445, 8446..."
    
    # Generate certificate if needed
    if [ ! -f /etc/stunnel/stunnel.pem ]; then
        log "Generating SSL certificate..."
        openssl req -new -x509 -days 3650 -nodes \
            -subj "/C=PH/ST=Metro Manila/L=Manila/O=MarcScript/CN=MarcScript VPN" \
            -out /etc/stunnel/stunnel.pem \
            -keyout /etc/stunnel/stunnel.pem 2>/dev/null
        chmod 600 /etc/stunnel/stunnel.pem
    fi
    
    # Backup existing config
    [ -f /etc/stunnel/stunnel.conf ] && cp /etc/stunnel/stunnel.conf /etc/stunnel/stunnel.conf.bak
    
    # Create Stunnel config with ports 8445, 8446
    cat > /etc/stunnel/stunnel.conf << 'EOF'
pid = /var/run/stunnel.pid
client = no
output = /var/log/stunnel.log
foreground = no
debug = 3
syslog = yes

socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1
compression = zlib

sslVersionMin = TLSv1.2
options = NO_SSLv2
options = NO_SSLv3
ciphers = HIGH:!aNULL:!MD5:!DH
TIMEOUTclose = 0

[ssh-ssl]
accept = 8445
connect = 127.0.0.1:22
cert = /etc/stunnel/stunnel.pem
TIMEOUTclose = 0
TIMEOUTidle = 60

[ws-ssl]
accept = 8446
connect = 127.0.0.1:8080
cert = /etc/stunnel/stunnel.pem
TIMEOUTclose = 0
TIMEOUTidle = 60
EOF

    # Enable Stunnel
    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null || echo "ENABLED=1" > /etc/default/stunnel4
    
    # Create log file
    touch /var/log/stunnel.log
    chmod 644 /var/log/stunnel.log
    
    # Start service
    systemctl daemon-reload
    systemctl enable stunnel4 2>/dev/null
    systemctl restart stunnel4 2>/dev/null
    
    sleep 2
    
    if systemctl is-active --quiet stunnel4; then
        log "Stunnel running on ports 8445 (SSH SSL), 8446 (WS SSL)"
    else
        wrn "Stunnel failed to start, check: systemctl status stunnel4"
    fi
}