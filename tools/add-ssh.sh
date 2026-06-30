#!/bin/bash
# ============================================================
# MARCSCRIPT - Add SSH Account
# ============================================================

source /usr/local/marcscript/lib/common.sh

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${GREEN}CREATE SSH ACCOUNT${NC}                             ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

read -p "Username : " user
read -p "Password : " pass
read -p "Duration (days) : " days

# Create user
useradd -m -s /bin/bash "$user" 2>/dev/null
echo "$user:$pass" | chpasswd
exp=$(date -d "$days days" +"%Y-%m-%d")
chage -E "$exp" "$user" 2>/dev/null

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${GREEN}SSH ACCOUNT DETAILS${NC}                            ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e " ${YELLOW}Username${NC}   : ${user}"
echo -e " ${YELLOW}Password${NC}   : ${pass}"
echo -e " ${YELLOW}Expired${NC}    : ${exp}"
echo -e " ${YELLOW}IP${NC}         : ${MYIP}"
echo ""
echo -e " ${YELLOW}Ports:${NC}"
echo -e "   SSH      : 22, 80"
echo -e "   SSL      : 443 (Stunnel)"
echo -e "   WS       : 8080"
echo -e "   Squid    : 3128, 8082, 8888"
echo ""
