#!/bin/bash
# ============================================================
# MARCSCRIPT - Xray Config Generator
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || {
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
}

DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || echo "$(wget -qO- ipv4.icanhazip.com)")

log "Generating Xray config for: $DOMAIN"

# Generate UUID
UUID=$(cat /proc/sys/kernel/random/uuid)
echo "$UUID" > /etc/xray/uuid

# ============================================================
# Xray Config JSON
# ============================================================
cat > /etc/xray/config.json << XRAYEOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1", "port": 10085, "protocol": "dokodemo-door",
      "settings": {"address": "127.0.0.1"}, "tag": "api"
    },
    {
      "listen": "127.0.0.1", "port": 14016, "protocol": "vless",
      "settings": {"decryption": "none", "clients": [{"id": "${UUID}"}]},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vless"}}
    },
    {
      "listen": "127.0.0.1", "port": 23456, "protocol": "vmess",
      "settings": {"clients": [{"id": "${UUID}", "alterId": 0}]},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/vmess"}}
    },
    {
      "listen": "127.0.0.1", "port": 25432, "protocol": "trojan",
      "settings": {"decryption": "none", "clients": [{"password": "${UUID}"}], "udp": true},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/trojan-ws"}}
    },
    {
      "listen": "127.0.0.1", "port": 30300, "protocol": "shadowsocks",
      "settings": {"clients": [{"method": "aes-128-gcm", "password": "${UUID}"}], "network": "tcp,udp"},
      "streamSettings": {"network": "ws", "wsSettings": {"path": "/ss-ws"}}
    },
    {
      "listen": "127.0.0.1", "port": 24456, "protocol": "vless",
      "settings": {"decryption": "none", "clients": [{"id": "${UUID}"}]},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "vless-grpc"}}
    },
    {
      "listen": "127.0.0.1", "port": 31234, "protocol": "vmess",
      "settings": {"clients": [{"id": "${UUID}", "alterId": 0}]},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "vmess-grpc"}}
    },
    {
      "listen": "127.0.0.1", "port": 33456, "protocol": "trojan",
      "settings": {"decryption": "none", "clients": [{"password": "${UUID}"}]},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "trojan-grpc"}}
    },
    {
      "listen": "127.0.0.1", "port": 30310, "protocol": "shadowsocks",
      "settings": {"clients": [{"method": "aes-128-gcm", "password": "${UUID}"}], "network": "tcp,udp"},
      "streamSettings": {"network": "grpc", "grpcSettings": {"serviceName": "ss-grpc"}}
    }
  ],
  "outbounds": [
    {"protocol": "freedom", "settings": {}},
    {"protocol": "blackhole", "settings": {}, "tag": "blocked"}
  ],
  "routing": {
    "rules": [
      {"type": "field", "ip": ["0.0.0.0/8","10.0.0.0/8","100.64.0.0/10","169.254.0.0/16","172.16.0.0/12","192.0.0.0/24","192.0.2.0/24","192.168.0.0/16","198.18.0.0/15","198.51.100.0/24","203.0.113.0/24","::1/128","fc00::/7","fe80::/10"], "outboundTag": "blocked"},
      {"inboundTag": ["api"], "outboundTag": "api", "type": "field"},
      {"type": "field", "outboundTag": "blocked", "protocol": ["bittorrent"]}
    ]
  },
  "stats": {},
  "api": {"services": ["StatsService"], "tag": "api"},
  "policy": {
    "levels": {"0": {"statsUserDownlink": true, "statsUserUplink": true}},
    "system": {"statsInboundUplink": true, "statsInboundDownlink": true, "statsOutboundUplink": true, "statsOutboundDownlink": true}
  }
}
XRAYEOF

# ============================================================
# Xray Systemd Service
# ============================================================
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
LimitNPROC=500
LimitNOFILE=51200

[Install]
WantedBy=multi-user.target
EOF

# ============================================================
# Runn Service
# ============================================================
cat > /etc/systemd/system/runn.service << 'EOF'
[Unit]
Description=Xray Directory Helper
After=network.target

[Service]
Type=simple
ExecStartPre=-/usr/bin/mkdir -p /var/run/xray
ExecStart=/usr/bin/chown www-data:www-data /var/run/xray
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# ============================================================
# Enable & Start
# ============================================================
systemctl daemon-reload
systemctl enable xray 2>/dev/null
systemctl enable runn 2>/dev/null
systemctl restart xray 2>/dev/null
systemctl restart runn 2>/dev/null

# Create database files
touch /etc/xray/{vmess,vless,trojan,ss}.db

log "Xray config generated - UUID: $UUID"
log "✅ Xray configuration complete"