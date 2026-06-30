#!/bin/bash
# ============================================================
# MARCSCRIPT - Shadowsocks Menu
# ============================================================

MYIP=$(wget -qO- ipv4.icanhazip.com)
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m   • SHADOWSOCKS MENU •      \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [\e[36m•1\e[0m] Create Account Shadowsocks"
echo -e " [\e[36m•2\e[0m] Trial Account Shadowsocks"
echo -e " [\e[36m•3\e[0m] Delete Account Shadowsocks"
echo -e " [\e[36m•4\e[0m] Check User Login Shadowsocks"
echo -e " [\e[36m•5\e[0m] User List Created Account"
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
    1) command -v add-ssws &>/dev/null && add-ssws || bash /usr/local/marcscript/xray/add-ssws.sh ;;
    2) command -v trialssws &>/dev/null && trialssws || bash /usr/local/marcscript/xray/trialssws.sh ;;
    3) command -v del-ssws &>/dev/null && del-ssws || bash /usr/local/marcscript/xray/del-ssws.sh ;;
    4) command -v cek-ssws &>/dev/null && cek-ssws || bash /usr/local/marcscript/xray/cek-ssws.sh ;;
    5) cat /etc/xray/ss.db 2>/dev/null | grep "^###" ; read -p "Press enter..." ;;
    0) menu 2>/dev/null || bash /usr/local/marcscript/menu.sh ;;
    x) exit ;;
    *) echo "Invalid" ; sleep 1 ; bash /usr/local/marcscript/menu/m-ssws.sh ;;
esac