#!/bin/bash
# MarcScript Main Menu

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m          • MARCSCRIPT VPN MENU •           \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [\e[36m1\e[0m] SSH/OVPN Menu"
echo -e " [\e[36m2\e[0m] V2Ray/Xray Menu"
echo -e " [\e[36m3\e[0m] Service Status"
echo -e " [\e[36m4\e[0m] Delete User Menu"
echo -e " [\e[36m5\e[0m] System Info"
echo -e " [\e[36m6\e[0m] Restart All Services"
echo -e ""
echo -e " [\e[31m0\e[0m] Exit"
echo -e ""
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e " IP: \e[32m$(wget -qO- ipv4.icanhazip.com)\e[0m"
echo -e " Domain: \e[32m$(cat /etc/xray/domain 2>/dev/null || echo 'Not Set')\e[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
read -p "Select menu: " opt
case $opt in
    1) 
        source /usr/local/marcscript/ssh/ssh-menu.sh
        ssh_menu
        ;;
    2)
        source /usr/local/marcscript/menu/v2ray-menu.sh
        v2ray_menu
        ;;
    3) vpn-status ; menu ;;
    4) 
        clear
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\E[0;100;33m   • DELETE USER MENU •      \E[0m"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e ""
        echo -e " [\e[36m1\e[0m] Delete SSH User"
        echo -e " [\e[36m2\e[0m] Delete VMess User"
        echo -e " [\e[36m3\e[0m] Delete VLess User"
        echo -e " [\e[36m4\e[0m] Delete Trojan User"
        echo -e ""
        echo -e " [\e[31m0\e[0m] Back"
        echo -e ""
        read -p "Select: " delopt
        case $delopt in
            1) del-ssh ; menu ;;
            2) del-ws ; menu ;;
            3) del-vless ; menu ;;
            4) del-tr ; menu ;;
            0) menu ;;
            *) menu ;;
        esac
        ;;
    5) 
        clear
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "\E[0;100;33m    • SYSTEM INFO •          \E[0m"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        echo -e "OS       : $(lsb_release -d 2>/dev/null | cut -f2)"
        echo -e "Kernel   : $(uname -r)"
        echo -e "CPU      : $(nproc) cores"
        echo -e "Memory   : $(free -h | awk 'NR==2{print $2}')"
        echo -e "Disk     : $(df -h / | awk 'NR==2{print $2}')"
        echo -e "Uptime   : $(uptime -p)"
        echo -e "IP       : $(wget -qO- ipv4.icanhazip.com)"
        echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
        read -p "Press enter to continue..."
        menu
        ;;
    6) 
        systemctl restart ssh stunnel4 nginx xray squid ws-proxy 2>/dev/null
        echo -e "${GREEN}All services restarted${NC}"
        sleep 2
        menu
        ;;
    0) clear ; exit 0 ;;
    *) menu ;;
esac
