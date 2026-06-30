#!/bin/bash
# ============================================================
# MARCSCRIPT - Add VMess Account
# ============================================================

source /usr/local/marcscript/lib/common.sh

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${GREEN}CREATE VMESS ACCOUNT${NC}                           ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Username : " user
read -p "Duration (days) : " days

exp=$(date -d "$days days" +"%Y-%m-%d")
uuid=$(cat /etc/xray/uuid 2>/dev/null || echo "auto")
domain=$(cat /etc/xray/domain 2>/dev/null || echo "$MYIP")

# Save to database
echo "### ${user} ${exp}" >> /etc/xray/vmess.db

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${GREEN}VMESS ACCOUNT DETAILS${NC}                         ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e " ${YELLOW}Protocol${NC}   : VMess WebSocket"
echo -e " ${YELLOW}Domain${NC}     : ${domain}"
echo -e " ${YELLOW}Port TLS${NC}   : 443"
echo -e " ${YELLOW}Port NTLS${NC}  : 80"
echo -e " ${YELLOW}UUID${NC}       : ${uuid}"
echo -e " ${YELLOW}AlterID${NC}    : 0"
echo -e " ${YELLOW}Path${NC}       : /vmess"
echo -e " ${YELLOW}Username${NC}   : ${user}"
echo -e " ${YELLOW}Expired${NC}    : ${exp}"
echo ""
echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
echo -e " ${GREEN}VMess Link:${NC}"
echo -e " vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"\",\"tls\":\"tls\"}" | base64 -w 0)"
echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
echo ""
