#!/bin/bash
# ============================================================
# MARCSCRIPT - Add SSH Account
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${GREEN}CREATE SSH ACCOUNT${NC}                             ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Username        : " user
read -p "Password        : " pass
read -p "Duration (days) : " days

# Validate
if [ -z "$user" ] || [ -z "$pass" ]; then
    echo -e "${RED}❌ Username and password required${NC}"
    exit 1
fi

if id "$user" &>/dev/null; then
    echo -e "${RED}❌ User already exists${NC}"
    exit 1
fi

# Create user
useradd -m -s /bin/bash "$user" 2>/dev/null
echo "$user:$pass" | chpasswd

# Set expiry
if [ ! -z "$days" ] && [ "$days" -gt 0 ]; then
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$user" 2>/dev/null
else
    exp_date="Never"
fi

# Get IP
IP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "$IP")

# Display
clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${GREEN}SSH ACCOUNT CREATED ✅${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e " ${YELLOW}Username${NC}   : ${GREEN}$user${NC}"
echo -e " ${YELLOW}Password${NC}   : ${GREEN}$pass${NC}"
echo -e " ${YELLOW}Expired${NC}    : ${RED}$exp_date${NC}"
echo -e " ${YELLOW}IP/Domain${NC}  : ${GREEN}$DOMAIN${NC}"
echo ""
echo -e " ${CYAN}════════════ CONNECTION PORTS ════════════${NC}"
echo -e " ${CYAN}║${NC} SSH Direct    : ${GREEN}$IP:22${NC}"
echo -e " ${CYAN}║${NC} SSH HTTP      : ${GREEN}$IP:80${NC}"
echo -e " ${CYAN}║${NC} SSH SSL       : ${GREEN}$IP:8445${NC} (Stunnel)"
echo -e " ${CYAN}║${NC} WebSocket     : ${GREEN}$IP:8080${NC}"
echo -e " ${CYAN}║${NC} WS SSL        : ${GREEN}$IP:8446${NC} (Stunnel)"
echo -e " ${CYAN}║${NC} Xray TLS      : ${GREEN}$DOMAIN:443${NC}"
echo -e " ${CYAN}║${NC} Xray Non-TLS  : ${GREEN}$DOMAIN:80${NC}"
echo -e " ${CYAN}║${NC} Squid Proxy   : ${GREEN}$IP:3128,8082,8888${NC}"
echo -e " ${CYAN}╚══════════════════════════════════════════${NC}"
echo ""