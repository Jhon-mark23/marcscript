#!/bin/bash
# ============================================================
# MARCSCRIPT - Quick Setup
# Usage: bash <(curl -s https://raw.githubusercontent.com/Jhon-mark23/marcscript/main/setup.sh)
# ============================================================

clear
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           🚀 MARCSCRIPT VPN - Quick Setup                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root (sudo su)"
    exit 1
fi

# Update system
echo "📦 Updating system..."
apt update -y >/dev/null 2>&1
apt install -y wget curl >/dev/null 2>&1

# Download and run installer
echo "📥 Downloading MarcScript installer..."
wget -q https://raw.githubusercontent.com/Jhon-mark23/marcscript/main/install.sh -O /tmp/marcscript-install.sh
chmod +x /tmp/marcscript-install.sh

echo "🚀 Running installer..."
bash /tmp/marcscript-install.sh

# Cleanup
rm -f /tmp/marcscript-install.sh
