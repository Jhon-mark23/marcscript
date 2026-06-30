#!/bin/bash
# ============================================================
# MARCSCRIPT - Trojan Menu
# ============================================================

MYIP=$(wget -qO- ipv4.icanhazip.com)
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m      • TROJAN MENU •         \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [\e[36m•1\e[0m] Create Account Trojan"
echo -e " [\e[36m•2\e[0m] Trial Account Trojan"
echo -e " [\e[36m•3\e[0m] Extending Account Trojan"
echo -e " [\e[36m•4\e[0m] Delete Account Trojan"
echo -e " [\e[36m•5\e[0m] Check User Login Trojan"
echo -e " [\e[36m•6\e[0m] User List Created Account"
echo -e ""
echo -e " [\e[31m•0\e[0m] \e[31mBACK TO MENU\033[0m"
echo -e ""
echo -e "Press x or [ Ctrl+C ] • To-Exit"
echo ""
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
read -p " Select menu : " opt
echo -e ""
case $opt in
    1) command -v add-tr &>/dev/null && add-tr || bash /usr/local/marcscript/xray/add-tr.sh ;;
    2) command -v trialtrojan &>/dev/null && trialtrojan || bash /usr/local/marcscript/xray/trialtrojan.sh ;;
    3) command -v renew-tr &>/dev/null && renew-tr || bash /usr/local/marcscript/xray/renew-tr.sh ;;
    4) command -v del-tr &>/dev/null && del-tr || bash /usr/local/marcscript/xray/del-tr.sh ;;
    5) command -v cek-tr &>/dev/null && cek-tr || bash /usr/local/marcscript/xray/cek-tr.sh ;;
    6) cat /etc/xray/trojan.db 2>/dev/null | grep "^###" ; read -p "Press enter..." ;;
    0) menu 2>/dev/null || bash /usr/local/marcscript/menu.sh ;;
    x) exit ;;
    *) echo "Invalid" ; sleep 1 ; bash /usr/local/marcscript/menu/m-trojan.sh ;;
esac