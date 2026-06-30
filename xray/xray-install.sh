#!/bin/bash
# ============================================================
# MARCSCRIPT - Xray Core Installer
# ============================================================

source /usr/local/marcscript/lib/common.sh

log "Installing Xray Core..."

# Create directories
mkdir -p /etc/xray /var/log/xray /run/xray
chown www-data:www-data /run/xray 2>/dev/null || true

# Install Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data 2>/dev/null

# Create service
cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

# Create runn service
cat > /etc/systemd/system/runn.service << 'EOF'
[Unit]
Description=Xray Directory Setup
After=network.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/mkdir -p /var/run/xray
ExecStart=/usr/bin/chown www-data:www-data /var/run/xray
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable xray runn 2>/dev/null

# SSL Certificate
log "Setting up SSL certificate..."
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "$MYIP")

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/xray/xray.key \
    -out /etc/xray/xray.crt \
    -subj "/C=PH/ST=Manila/L=Manila/O=MarcScript/CN=${DOMAIN}" 2>/dev/null

chmod 600 /etc/xray/xray.crt /etc/xray/xray.key 2>/dev/null
chown www-data:www-data /etc/xray/xray.crt /etc/xray/xray.key 2>/dev/null

log "Xray installed successfully"
