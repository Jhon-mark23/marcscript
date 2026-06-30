#!/bin/bash
# MarcScript - Nginx Configuration for Xray

source /usr/local/marcscript/lib/common.sh

configure_nginx() {
    log_info "Configuring Nginx..."
    
    domain=$(get_domain)
    mkdir -p /home/vps/public_html
    
    cat > /etc/nginx/conf.d/xray.conf << NGINXCONF
server {
    listen 81;
    server_name _;
    root /home/vps/public_html;
    index index.html;
}

server {
    listen 80;
    listen [::]:80;
    server_name *.${domain};
    root /home/vps/public_html;

    location = /vmess {
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location = /vless {
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /trojan-ws {
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /ss-ws {
        proxy_pass http://127.0.0.1:30300;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name *.${domain};
    
    ssl_certificate /etc/xray/xray.crt;
    ssl_certificate_key /etc/xray/xray.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    root /home/vps/public_html;

    location = /vmess {
        proxy_pass http://127.0.0.1:23456;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /vless {
        proxy_pass http://127.0.0.1:14016;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /trojan-ws {
        proxy_pass http://127.0.0.1:25432;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location = /ss-ws {
        proxy_pass http://127.0.0.1:30300;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }

    location ^~ /vless-grpc {
        grpc_pass grpc://127.0.0.1:24456;
    }

    location ^~ /vmess-grpc {
        grpc_pass grpc://127.0.0.1:31234;
    }

    location ^~ /trojan-grpc {
        grpc_pass grpc://127.0.0.1:33456;
    }

    location ^~ /ss-grpc {
        grpc_pass grpc://127.0.0.1:30310;
    }

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
}
NGINXCONF

    nginx -t 2>/dev/null && systemctl restart nginx && systemctl enable nginx
    log_success "Nginx configured"
}
