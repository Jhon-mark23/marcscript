#!/bin/bash
# MarcScript - SSH Configuration

source /usr/local/marcscript/lib/common.sh

configure_ssh() {
    log_info "Configuring SSH..."
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak 2>/dev/null
    
    # Configure ports
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
    if ! grep -q "^Port 80" /etc/ssh/sshd_config; then
        echo "Port 80" >> /etc/ssh/sshd_config
    fi
    
    # Enable password auth
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
    
    # Banner
    echo "MarcScript VPN Server" > /etc/ssh/banner
    grep -q "^Banner" /etc/ssh/sshd_config || echo "Banner /etc/ssh/banner" >> /etc/ssh/sshd_config
    
    # Restart SSH
    systemctl restart ssh
    systemctl enable ssh
    
    log_success "SSH configured on ports 22, 80"
}
