#!/bin/bash
# MarcScript - Stunnel Configuration

source /usr/local/marcscript/lib/common.sh

configure_stunnel() {
    log_info "Configuring Stunnel SSL..."
    
    # Generate certificate
    openssl req -new -x509 -days 3650 -nodes \
        -subj "/C=PH/ST=Manila/L=Manila/O=MarcScript/CN=MarcScript" \
        -out /etc/stunnel/stunnel.pem \
        -keyout /etc/stunnel/stunnel.pem 2>/dev/null
    
    # Configuration
    cat > /etc/stunnel/stunnel.conf << 'EOF'
pid = /var/run/stunnel.pid
client = no
output = /var/log/stunnel.log
foreground = no
debug = 3

[ssh-ssl]
accept = 443
connect = 127.0.0.1:22
cert = /etc/stunnel/stunnel.pem
TIMEOUTclose = 0

[ws-ssl]
accept = 8443
connect = 127.0.0.1:8080
cert = /etc/stunnel/stunnel.pem
TIMEOUTclose = 0
EOF

    sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4 2>/dev/null
    systemctl restart stunnel4
    systemctl enable stunnel4
    
    log_success "Stunnel configured on ports 443, 8443"
}
