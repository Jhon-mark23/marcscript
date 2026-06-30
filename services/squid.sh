#!/bin/bash
# MarcScript - Squid Proxy

source /usr/local/marcscript/lib/common.sh

configure_squid() {
    log_info "Configuring Squid proxy..."
    
    cat > /etc/squid/squid.conf << 'EOF'
http_port 3128
http_port 8082
http_port 8888

acl all src 0.0.0.0/0
http_access allow all

cache_dir ufs /var/spool/squid 100 16 256
cache_mem 64 MB
visible_hostname MarcScript

forwarded_for off
request_header_access X-Forwarded-For deny all
EOF

    systemctl restart squid
    systemctl enable squid
    
    log_success "Squid configured on ports 3128, 8082, 8888"
}
