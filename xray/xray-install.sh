#!/bin/bash
# ============================================================
# MARCSCRIPT - Xray Core Installer
# Uses domain from /root/domain or /etc/xray/domain
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || {
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
    err() { echo -e "${RED}[ERROR]${NC} $1"; }
}

# Get domain
MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || cat /root/domain 2>/dev/null || echo "$MYIP")

log "Installing Xray Core for domain: $DOMAIN"
echo ""

# ============================================================
# 1. Install dependencies
# ============================================================
log "Installing dependencies..."
export DEBIAN_FRONTEND=noninteractive
apt update -y >/dev/null 2>&1

PACKAGES="iptables iptables-persistent net-tools screen curl socat xz-utils wget apt-transport-https gnupg dnsutils lsb-release bash-completion cron openssl zip pwgen netcat-openbsd"
for pkg in $PACKAGES; do
    dpkg -l | grep -q "^ii  $pkg" || apt install -y $pkg >/dev/null 2>&1
done

# Set timezone
timedatectl set-timezone Asia/Manila 2>/dev/null || true
timedatectl set-ntp true 2>/dev/null || true

# ============================================================
# 2. Create directories
# ============================================================
log "Creating Xray directories..."
mkdir -p /run/xray /var/log/xray /etc/xray
chown www-data:www-data /run/xray 2>/dev/null || true
chown www-data:www-data /var/log/xray 2>/dev/null || true
chmod 755 /var/log/xray

touch /var/log/xray/{access.log,error.log,access2.log,error2.log}
chown www-data:www-data /var/log/xray/*.log 2>/dev/null || true

# ============================================================
# 3. Install Xray core
# ============================================================
log "Downloading & installing Xray core..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data 2>/dev/null || {
    err "Xray installation failed"
    exit 1
}
log "Xray core installed"

# ============================================================
# 4. SSL Certificate
# ============================================================
log "Setting up SSL certificate for $DOMAIN..."

systemctl stop nginx 2>/dev/null || true
mkdir -p /root/.acme.sh

# Install acme.sh
if [ ! -f /root/.acme.sh/acme.sh ]; then
    curl -s https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
fi

/root/.acme.sh/acme.sh --upgrade --auto-upgrade 2>/dev/null
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt 2>/dev/null

# Issue certificate (only if real domain, not IP)
if [[ "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$DOMAIN" == "$MYIP" ]]; then
    log "Using IP address - creating self-signed certificate..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/xray/xray.key \
        -out /etc/xray/xray.crt \
        -subj "/C=PH/ST=Manila/L=Manila/O=MarcScript/CN=$DOMAIN" 2>/dev/null
else
    log "Issuing Let's Encrypt certificate for $DOMAIN..."
    /root/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone -k ec-256 2>&1 | grep -v "Skip" | grep -v "Already" || true
    
    if [ -f "/root/.acme.sh/${DOMAIN}_ecc/${DOMAIN}.cer" ]; then
        ~/.acme.sh/acme.sh --installcert -d "$DOMAIN" \
            --fullchainpath /etc/xray/xray.crt \
            --keypath /etc/xray/xray.key \
            --ecc 2>/dev/null
        log "Let's Encrypt certificate installed"
    else
        log "Falling back to self-signed certificate..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout /etc/xray/xray.key \
            -out /etc/xray/xray.crt \
            -subj "/C=PH/ST=Manila/L=Manila/O=MarcScript/CN=$DOMAIN" 2>/dev/null
    fi
fi

chmod 600 /etc/xray/xray.crt /etc/xray/xray.key 2>/dev/null
chown www-data:www-data /etc/xray/xray.crt /etc/xray/xray.key 2>/dev/null || true

# ============================================================
# 5. SSL Renew Script
# ============================================================
cat > /usr/local/bin/ssl_renew.sh << 'EOF'
#!/bin/bash
systemctl stop nginx 2>/dev/null
"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" &> /root/renew_ssl.log
systemctl start nginx 2>/dev/null
EOF
chmod +x /usr/local/bin/ssl_renew.sh

if ! grep -q 'ssl_renew.sh' /var/spool/cron/crontabs/root 2>/dev/null; then
    (crontab -l 2>/dev/null; echo "15 03 */3 * * /usr/local/bin/ssl_renew.sh") | crontab - 2>/dev/null
fi

mkdir -p /home/vps/public_html

# ============================================================
# 6. Save domain
# ============================================================
echo "$DOMAIN" > /etc/xray/domain
log "Domain saved: $DOMAIN"
log "✅ Xray installation complete"