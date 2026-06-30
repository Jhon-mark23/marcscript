#!/bin/bash
# MarcScript - Xray SSL Certificate

source /usr/local/marcscript/lib/common.sh

setup_xray_cert() {
    log_info "Setting up SSL certificate for Xray..."
    
    domain=$(get_domain)
    
    # Install acme.sh
    curl -s https://get.acme.sh | sh -s email=admin@${domain} 2>/dev/null
    
    # Issue certificate
    systemctl stop nginx 2>/dev/null
    /root/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256 2>/dev/null
    
    if [ -f /root/.acme.sh/${domain}_ecc/${domain}.cer ]; then
        /root/.acme.sh/acme.sh --installcert -d ${domain} \
            --fullchainpath /etc/xray/xray.crt \
            --keypath /etc/xray/xray.key \
            --ecc 2>/dev/null
        log_success "SSL certificate installed"
    else
        # Self-signed fallback
        log_warn "Using self-signed certificate"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/xray/xray.key \
            -out /etc/xray/xray.crt \
            -subj "/C=PH/ST=Manila/L=Manila/O=MarcScript/CN=${domain}" 2>/dev/null
    fi
    
    chmod 600 /etc/xray/xray.crt /etc/xray/xray.key 2>/dev/null
    chown www-data:www-data /etc/xray/xray.crt /etc/xray/xray.key 2>/dev/null
}
