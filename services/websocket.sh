#!/bin/bash
# MarcScript - WebSocket Proxy

source /usr/local/marcscript/lib/common.sh

configure_websocket() {
    log_info "Configuring WebSocket proxy..."
    
    mkdir -p /opt/ws-proxy
    
    cat > /opt/ws-proxy/ws-proxy.js << 'WSPROXYEOF'
const net = require('net');
const http = require('http');
const fs = require('fs');

const WS_PORT = 8080;
const SSH_PORT = 22;
const LOG = '/var/log/ws-proxy.log';

function log(msg) {
    const line = `[${new Date().toISOString()}] ${msg}\n`;
    fs.appendFileSync(LOG, line);
}

const server = http.createServer();

server.on('connect', (req, socket) => {
    const ssh = net.connect(SSH_PORT, '127.0.0.1', () => {
        socket.write('HTTP/1.1 200 OK\r\n\r\n');
        ssh.pipe(socket);
        socket.pipe(ssh);
    });
    ssh.on('error', () => socket.destroy());
});

server.on('upgrade', (req, socket) => {
    const ssh = net.connect(SSH_PORT, '127.0.0.1', () => {
        socket.write('HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n');
        ssh.pipe(socket);
        socket.pipe(ssh);
    });
    ssh.on('error', () => socket.destroy());
});

server.listen(WS_PORT, '0.0.0.0', () => log(`WS Proxy running on port ${WS_PORT}`));
WSPROXYEOF

    # Systemd service
    cat > /etc/systemd/system/ws-proxy.service << 'EOF'
[Unit]
Description=SSH WebSocket Proxy
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/node /opt/ws-proxy/ws-proxy.js
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable ws-proxy
    systemctl start ws-proxy
    
    log_success "WebSocket proxy configured on port 8080"
}
