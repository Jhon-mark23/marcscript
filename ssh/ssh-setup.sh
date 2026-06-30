#!/bin/bash
# ============================================================
# MARCSCRIPT - SSH Server Setup
# ============================================================

source /usr/local/marcscript/lib/common.sh

log "Configuring SSH Server..."

# Backup
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak 2>/dev/null

# Configure SSH
cat > /etc/ssh/sshd_config << EOF
Port 22
Port 80
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
Banner /etc/ssh/banner
ClientAliveInterval 60
ClientAliveCountMax 3
MaxAuthTries 6
MaxSessions 100
TCPKeepAlive yes
AllowTcpForwarding yes
GatewayPorts yes
X11Forwarding no
PrintMotd no
PrintLastLog yes
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# Banner
cat > /etc/ssh/banner << 'BANNER'
╔══════════════════════════════════════╗
║     🚀 MarcScript VPN Server        ║
║     Unauthorized access prohibited  ║
╚══════════════════════════════════════╝
BANNER

# Restart
systemctl restart ssh
systemctl enable ssh

log "SSH configured on ports 22, 80"
