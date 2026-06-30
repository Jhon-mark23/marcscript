#!/bin/bash
# ============================================================
# MARCSCRIPT - Add Trojan Account
# ============================================================

source /usr/local/marcscript/lib/common.sh

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}             ${GREEN}CREATE TROJAN ACCOUNT${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Username : " user
read -p "Duration (days) : " days

exp=$(date -d "$days days" +"%Y-%m-%d")
uuid=$(cat /etc/xray/uuid 2>/dev/null || echo "auto")
domain=$(cat /etc/xray/domain 2>/dev/null || echo "$MYIP")

# Save to database
echo "### ${user} ${exp}" >> /etc/xray/trojan.db

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}             ${GREEN}TROJAN ACCOUNT DETAILS${NC}                         ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e " ${YELLOW}Protocol${NC}   : Trojan WebSocket"
echo -e " ${YELLOW}Domain${NC}     : ${domain}"
echo -e " ${YELLOW}Port TLS${NC}   : 443"
echo -e " ${YELLOW}Port NTLS${NC}  : 80"
echo -e " ${YELLOW}Password${NC}   : ${uuid}"
echo -e " ${YELLOW}Path${NC}       : /trojan-ws"
echo -e " ${YELLOW}Username${NC}   : ${user}"
echo -e " ${YELLOW}Expired${NC}    : ${exp}"
echo ""
echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
echo -e " ${GREEN}Trojan Link:${NC}"
echo -e " trojan://${uuid}@${domain}:443?path=/trojan-ws&security=tls&type=ws#${user}"
echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
echo ""
