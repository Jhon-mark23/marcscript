#!/bin/bash
# ============================================================
# MARCSCRIPT - VMess Menu
# ============================================================

MYIP=$(wget -qO- ipv4.icanhazip.com)
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m       • VMESS MENU •          \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [\e[36m•1\e[0m] Create Account Vmess"
echo -e " [\e[36m•2\e[0m] Trial Account Vmess"
echo -e " [\e[36m•3\e[0m] Extending Account Vmess"
echo -e " [\e[36m•4\e[0m] Delete Account Vmess"
echo -e " [\e[36m•5\e[0m] Check User Login Vmess"
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
    1) command -v add-ws &>/dev/null && add-ws || bash /usr/local/marcscript/xray/add-ws.sh ;;
    2) command -v trialvmess &>/dev/null && trialvmess || bash /usr/local/marcscript/xray/trialvmess.sh ;;
    3) command -v renew-ws &>/dev/null && renew-ws || bash /usr/local/marcscript/xray/renew-ws.sh ;;
    4) command -v del-ws &>/dev/null && del-ws || bash /usr/local/marcscript/xray/del-ws.sh ;;
    5) command -v cek-ws &>/dev/null && cek-ws || bash /usr/local/marcscript/xray/cek-ws.sh ;;
    6) cat /etc/xray/vmess.db 2>/dev/null | grep "^###" ; read -p "Press enter..." ;;
    0) menu 2>/dev/null || bash /usr/local/marcscript/menu.sh ;;
    x) exit ;;
    *) echo "Invalid" ; sleep 1 ; bash /usr/local/marcscript/menu/m-vmess.sh ;;
esac