#!/bin/bash
# MarcScript - Management API

source /usr/local/marcscript/lib/common.sh

configure_api() {
    log_info "Configuring Management API..."
    
    mkdir -p /opt/marcscript-api
    
    cat > /opt/marcscript-api/api.js << 'APIJSEOF'
const http = require('http');
const fs = require('fs');

const API_PORT = 3021;

const server = http.createServer((req, res) => {
    if (req.url === '/status') {
        res.writeHead(200, {'Content-Type': 'application/json'});
        const status = {
            ssh: 'running',
            xray: 'running',
            nginx: 'running'
        };
        res.end(JSON.stringify(status, null, 2));
    } else if (req.url === '/ping') {
        res.writeHead(200);
        res.end('pong');
    } else {
        res.writeHead(200, {'Content-Type': 'text/html'});
        res.end('<h1>MarcScript API</h1><p>Port: 3021</p>');
    }
});

server.listen(API_PORT, '127.0.0.1', () => {
    console.log(`API running on port ${API_PORT}`);
});
APIJSEOF

    cat > /etc/systemd/system/marcscript-api.service << 'EOF'
[Unit]
Description=MarcScript Management API
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /opt/marcscript-api/api.js
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable marcscript-api
    systemctl start marcscript-api
    
    log_success "API configured on port 3021"
}
