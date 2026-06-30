#!/bin/bash
# ============================================================
# MARCSCRIPT - Xray Config Generator
# ============================================================

source /usr/local/marcscript/lib/common.sh

log "Generating Xray configuration..."

UUID=$(cat /proc/sys/kernel/random/uuid)
echo "$UUID" > /etc/xray/uuid

cat > /etc/xray/config.json << XRAYCONF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 23456,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [{"id": "${UUID}", "alterId": 0}]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vmess"}
      }
    },
    {
      "port": 14016,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [{"id": "${UUID}"}]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/vless"}
      }
    },
    {
      "port": 25432,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [{"password": "${UUID}"}]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/trojan-ws"}
      }
    },
    {
      "port": 24456,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [{"id": "${UUID}"}]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {"serviceName": "vless-grpc"}
      }
    },
    {
      "port": 31234,
      "listen": "127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [{"id": "${UUID}", "alterId": 0}]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {"serviceName": "vmess-grpc"}
      }
    },
    {
      "port": 33456,
      "listen": "127.0.0.1",
      "protocol": "trojan",
      "settings": {
        "clients": [{"password": "${UUID}"}]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {"serviceName": "trojan-grpc"}
      }
    }
  ],
  "outbounds": [
    {"protocol": "freedom", "settings": {}},
    {"protocol": "blackhole", "settings": {}, "tag": "blocked"}
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": ["0.0.0.0/8", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"],
        "outboundTag": "blocked"
      }
    ]
  }
}
XRAYCONF

# Create database files
touch /etc/xray/{vmess,vless,trojan,ss}.db

systemctl restart xray 2>/dev/null
log "Xray configuration complete"
