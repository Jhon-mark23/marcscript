#!/bin/bash
# MarcScript - Xray Configuration

source /usr/local/marcscript/lib/common.sh

generate_xray_config() {
    log_info "Generating Xray configuration..."
    
    uuid=$(cat /proc/sys/kernel/random/uuid)
    echo "$uuid" > /etc/xray/uuid
    
    cat > /etc/xray/config.json << XRAYJSON
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
        "clients": [{"id": "${uuid}", "alterId": 0}]
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
        "clients": [{"id": "${uuid}"}]
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
        "clients": [{"password": "${uuid}"}]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/trojan-ws"}
      }
    },
    {
      "port": 30300,
      "listen": "127.0.0.1",
      "protocol": "shadowsocks",
      "settings": {
        "clients": [{"method": "aes-128-gcm", "password": "${uuid}"}]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {"path": "/ss-ws"}
      }
    },
    {
      "port": 24456,
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "decryption": "none",
        "clients": [{"id": "${uuid}"}]
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
        "clients": [{"id": "${uuid}", "alterId": 0}]
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
        "clients": [{"password": "${uuid}"}]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {"serviceName": "trojan-grpc"}
      }
    },
    {
      "port": 30310,
      "listen": "127.0.0.1",
      "protocol": "shadowsocks",
      "settings": {
        "clients": [{"method": "aes-128-gcm", "password": "${uuid}"}]
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {"serviceName": "ss-grpc"}
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
XRAYJSON

    log_success "Xray configuration generated"
}
