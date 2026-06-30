#!/bin/bash
# MarcScript - Xray Core Installation

source /usr/local/marcscript/lib/common.sh

install_xray() {
    log_info "Installing Xray core..."
    
    mkdir -p /etc/xray /var/log/xray /run/xray
    chown www-data:www-data /run/xray /var/log/xray 2>/dev/null || true
    
    # Install Xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data 2>/dev/null
    
    # Create systemd service
    cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
After=network.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    log_success "Xray core installed"
}
