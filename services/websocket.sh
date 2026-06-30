#!/bin/bash
# ============================================================
# MARCSCRIPT - WebSocket Proxy Configuration
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || source $(dirname "$0")/../lib/common.sh

# ============================================================
# Install WebSocket Proxy
# ============================================================
configure_websocket() {
    log "Configuring WebSocket Proxy..."
    
    # Create directory
    mkdir -p /opt/ws-proxy
    
    # Create WebSocket proxy using Node.js
    cat > /opt/ws-proxy/ws-proxy.js << 'WSEOF'
#!/usr/bin/env node
// MarcScript WebSocket Proxy
// Forwards WebSocket connections to SSH

const net = require('net');
const http = require('http');
const fs = require('fs');

// Configuration
const CONFIG = {
    sshHost: '127.0.0.1',
    sshPort: 22,
    wsPort: 8080,
    logFile: '/var/log/ws-proxy.log'
};

// Logger
function log(level, msg) {
    const timestamp = new Date().toISOString();
    const line = `[${timestamp}] [${level}] ${msg}`;
    console.log(line);
    try {
        fs.appendFileSync(CONFIG.logFile, line + '\n');
    } catch(e) {}
}

// Create HTTP server
const server = http.createServer();

// Handle CONNECT method (HTTP proxy)
server.on('connect', (req, clientSocket, head) => {
    log('INFO', `CONNECT: ${req.url} from ${clientSocket.remoteAddress}`);
    
    const sshSocket = net.connect(CONFIG.sshPort, CONFIG.sshHost, () => {
        clientSocket.write('HTTP/1.1 200 Connection Established\r\n');
        clientSocket.write('Proxy-Agent: MarcScript-WS\r\n\r\n');
        sshSocket.write(head);
        sshSocket.pipe(clientSocket);
        clientSocket.pipe(sshSocket);
    });
    
    sshSocket.on('error', (err) => {
        log('ERROR', `SSH connection error: ${err.message}`);
        clientSocket.destroy();
    });
    
    clientSocket.on('error', (err) => {
        log('ERROR', `Client socket error: ${err.message}`);
        sshSocket.destroy();
    });
});

// Handle WebSocket upgrade
server.on('upgrade', (req, socket, head) => {
    log('INFO', `WebSocket upgrade: ${req.headers.host}${req.url}`);
    
    const sshSocket = net.connect(CONFIG.sshPort, CONFIG.sshHost, () => {
        socket.write(
            'HTTP/1.1 101 Switching Protocols\r\n' +
            'Upgrade: websocket\r\n' +
            'Connection: Upgrade\r\n' +
            'Sec-WebSocket-Accept: ' + require('crypto')
                .createHash('sha1')
                .update(req.headers['sec-websocket-key'] + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11')
                .digest('base64') + '\r\n\r\n'
        );
        sshSocket.write(head);
        sshSocket.pipe(socket);
        socket.pipe(sshSocket);
    });
    
    sshSocket.on('error', (err) => {
        log('ERROR', `SSH WS error: ${err.message}`);
        socket.destroy();
    });
    
    socket.on('error', (err) => {
        log('ERROR', `WS socket error: ${err.message}`);
        sshSocket.destroy();
    });
});

// Handle HTTP requests (status page)
server.on('request', (req, res) => {
    const uptime = Math.floor(process.uptime());
    
    if (req.url === '/status' || req.url === '/') {
        res.writeHead(200, {'Content-Type': 'text/html'});
        res.end(`
<!DOCTYPE html>
<html>
<head>
    <title>MarcScript WS Proxy</title>
    <style>
        body { font-family: Arial; background: #1a1a2e; color: #eee; 
               display: flex; justify-content: center; align-items: center; 
               height: 100vh; margin: 0; }
        .box { background: #16213e; padding: 30px; border-radius: 15px; 
               text-align: center; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
        h1 { color: #0f3460; }
        .green { color: #00ff88; }
    </style>
</head>
<body>
    <div class="box">
        <h1>🚀 MarcScript WS Proxy</h1>
        <p>Status: <span class="green">Running</span></p>
        <p>Port: ${CONFIG.wsPort}</p>
        <p>Uptime: ${uptime}s</p>
        <p>SSH: ${CONFIG.sshHost}:${CONFIG.sshPort}</p>
    </div>
</body>
</html>`);
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

// Start server
server.listen(CONFIG.wsPort, '0.0.0.0', () => {
    log('INFO', `WebSocket proxy started on port ${CONFIG.wsPort}`);
});

// Handle shutdown
process.on('SIGTERM', () => {
    log('INFO', 'Received SIGTERM, shutting down...');
    server.close(() => process.exit(0));
});

process.on('SIGINT', () => {
    log('INFO', 'Received SIGINT, shutting down...');
    server.close(() => process.exit(0));
});

process.on('uncaughtException', (err) => {
    log('ERROR', `Uncaught: ${err.message}`);
});
WSEOF

    chmod +x /opt/ws-proxy/ws-proxy.js
    
    # Create systemd service
    cat > /etc/systemd/system/ws-proxy.service << 'EOF'
[Unit]
Description=MarcScript SSH WebSocket Proxy
Documentation=https://github.com/Jhon-mark23/marcscript
After=network.target ssh.service

[Service]
Type=simple
ExecStart=/usr/bin/node /opt/ws-proxy/ws-proxy.js
Restart=always
RestartSec=5
User=root
StandardOutput=journal
StandardError=journal
Environment=NODE_ENV=production

# Security
NoNewPrivileges=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF

    # Create log file
    touch /var/log/ws-proxy.log
    chmod 644 /var/log/ws-proxy.log
    
    # Start service
    systemctl daemon-reload
    systemctl enable ws-proxy >/dev/null 2>&1
    systemctl start ws-proxy >/dev/null 2>&1
    
    # Verify
    sleep 2
    if systemctl is-active --quiet ws-proxy; then
        log "WebSocket proxy configured on port 8080"
    else
        err "WebSocket proxy failed to start"
        systemctl status ws-proxy --no-pager
    fi
}

# ============================================================
# WebSocket Status
# ============================================================
ws_status() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}WEBSOCKET PROXY STATUS${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "Service: $(systemctl is-active ws-proxy)"
    echo -e "Port: 8080"
    echo ""
    
    if systemctl is-active --quiet ws-proxy; then
        curl -s http://localhost:8080/status 2>/dev/null | grep -o "Running\|Uptime.*" || echo "Status page accessible"
    fi
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        install|setup)
            configure_websocket
            ;;
        status)
            ws_status
            ;;
        restart)
            systemctl restart ws-proxy
            log "WebSocket proxy restarted"
            ;;
        stop)
            systemctl stop ws-proxy
            log "WebSocket proxy stopped"
            ;;
        logs)
            journalctl -u ws-proxy -f
            ;;
        *)
            echo "Usage: $0 {install|status|restart|stop|logs}"
            ;;
    esac
fi
