#!/bin/bash
# ============================================================
# MARCSCRIPT - Nginx Configuration
# Ports: 80 (HTTP), 443 (HTTPS for Xray)
# Stunnel uses: 8445, 8446
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || source $(dirname "$0")/../lib/common.sh

configure_nginx() {
    log "Configuring Nginx for Xray on port 443..."
    
    DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "$MYIP")
    mkdir -p /home/vps/public_html
    
    # Free up ports first
    log "Checking and freeing ports..."
    fuser -k 443/tcp 2>/dev/null || true
    fuser -k 8443/tcp 2>/dev/null || true
    sleep 1
    
    # Stop services that might conflict
    systemctl stop nginx 2>/dev/null || true
    
    cat > /etc/nginx/conf.d/marcscript.conf << 'NGINXEOF'
# HTTP (Port 80)
server {
    listen 80;
    listen [::]:80;
    server_name _;
    root /home/vps/public_html;
    index index.html;

    # Xray WS paths (Non-TLS)
    location /vmess {
        if ($http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }

    location /vless {
        if ($http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400;
    }

    location /trojan-ws {
        if ($http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400;
    }

    location /ss-ws {
        if ($http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:30300;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400;
    }
}

# HTTPS (Port 443) - Main SSL for Xray
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name _;
    
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    root /home/vps/public_html;

    # Xray WS paths (TLS)
    location /vmess {
        if ($http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }

    location /vless {
        if ($http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400;
    }

    location /trojan-ws {
        if ($http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400;
    }

    location /ss-ws {
        if ($http_upgrade != "websocket") { return 404; }
        proxy_pass http://127.0.0.1:30300;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }

    # gRPC paths
    location /vless-grpc {
        if ($content_type !~ "application/grpc") { return 404; }
        grpc_pass grpc://127.0.0.1:24456;
        grpc_set_header X-Real-IP $remote_addr;
        grpc_set_header Host $host;
    }
    
    location /vmess-grpc {
        if ($content_type !~ "application/grpc") { return 404; }
        grpc_pass grpc://127.0.0.1:31234;
        grpc_set_header X-Real-IP $remote_addr;
        grpc_set_header Host $host;
    }
    
    location /trojan-grpc {
        if ($content_type !~ "application/grpc") { return 404; }
        grpc_pass grpc://127.0.0.1:33456;
        grpc_set_header X-Real-IP $remote_addr;
        grpc_set_header Host $host;
    }

    location /ss-grpc {
        if ($content_type !~ "application/grpc") { return 404; }
        grpc_pass grpc://127.0.0.1:30310;
        grpc_set_header X-Real-IP $remote_addr;
        grpc_set_header Host $host;
    }

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400;
    }
}
NGINXEOF

    # Remove default config
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null
    rm -f /etc/nginx/sites-available/default 2>/dev/null
    
    # Test and start
    nginx -t 2>/dev/null
    
    if [ $? -eq 0 ]; then
        systemctl restart nginx
        systemctl enable nginx
        sleep 2
        
        if systemctl is-active --quiet nginx; then
            log "Nginx running on ports 80, 443"
        else
            err "Nginx failed to start"
        fi
    else
        err "Nginx config test failed"
    fi
}