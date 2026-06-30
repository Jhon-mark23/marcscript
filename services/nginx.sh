#!/bin/bash
# ============================================================
# MARCSCRIPT - Nginx Config for Xray
# ============================================================

source /usr/local/marcscript/lib/common.sh

log "Configuring Nginx for Xray..."

DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "$MYIP")
mkdir -p /home/vps/public_html

# Create nginx config
cat > /etc/nginx/conf.d/marcscript.conf << NGINXEOF
server {
    listen 80;
    server_name *.${DOMAIN};
    root /home/vps/public_html;
    index index.html;

    # Xray WebSocket paths
    location /vmess {
        if (\$http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /vless {
        if (\$http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /trojan-ws {
        if (\$http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    # WebSocket SSH
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}

server {
    listen 443 ssl http2;
    server_name *.${DOMAIN};
    
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    root /home/vps/public_html;

    location /vmess {
        if (\$http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /vless {
        if (\$http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    location /trojan-ws {
        if (\$http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }

    # gRPC
    location /vless-grpc {
        grpc_pass grpc://127.0.0.1:24456;
    }
    
    location /vmess-grpc {
        grpc_pass grpc://127.0.0.1:31234;
    }
    
    location /trojan-grpc {
        grpc_pass grpc://127.0.0.1:33456;
    }

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
NGINXEOF

# Remove default config
rm -f /etc/nginx/sites-enabled/default 2>/dev/null

# Test and restart
nginx -t 2>/dev/null && systemctl restart nginx && systemctl enable nginx

log "Nginx configured"
