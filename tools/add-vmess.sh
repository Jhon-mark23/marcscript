#!/bin/bash
# ============================================================
# MARCSCRIPT - Add VMess Account
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${GREEN}CREATE VMESS ACCOUNT${NC}                           ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Username        : " user
read -p "Duration (days) : " days

exp=$(date -d "+$days days" +"%Y-%m-%d")
uuid=$(cat /etc/xray/uuid 2>/dev/null || echo "auto")
domain=$(cat /etc/xray/domain 2>/dev/null || wget -qO- ipv4.icanhazip.com)

echo "### ${user} ${exp}" >> /etc/xray/vmess.db

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${GREEN}VMESS ACCOUNT CREATED ✅${NC}                        ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e " ${YELLOW}Protocol${NC}   : VMess WebSocket + gRPC"
echo -e " ${YELLOW}Domain${NC}     : ${GREEN}${domain}${NC}"
echo -e " ${YELLOW}Port TLS${NC}   : ${GREEN}443${NC}"
echo -e " ${YELLOW}Port NTLS${NC}  : ${GREEN}80${NC}"
echo -e " ${YELLOW}UUID${NC}       : ${GREEN}${uuid}${NC}"
echo -e " ${YELLOW}AlterID${NC}    : ${GREEN}0${NC}"
echo -e " ${YELLOW}Path WS${NC}    : ${GREEN}/vmess${NC}"
echo -e " ${YELLOW}Path gRPC${NC}  : ${GREEN}vmess-grpc${NC}"
echo -e " ${YELLOW}Username${NC}   : ${GREEN}${user}${NC}"
echo -e " ${YELLOW}Expired${NC}    : ${RED}${exp}${NC}"
echo ""
echo -e " ${CYAN}──────────────────────────────────────────────${NC}"
echo -e " ${GREEN}VMess TLS Link:${NC}"
echo -e " vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"${user}\",\"add\":\"${domain}\",\"port\":\"443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"\",\"tls\":\"tls\"}" | base64 -w 0)"
echo ""
echo -e " ${GREEN}VMess Non-TLS Link:${NC}"
echo -e " vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"${user}-ntls\",\"add\":\"${domain}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vmess\",\"type\":\"none\",\"host\":\"\",\"tls\":\"\"}" | base64 -w 0)"
echo -e " ${CYAN}──────────────────────────────────────────────${NC}"
echo ""