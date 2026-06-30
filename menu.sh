#!/bin/bash
# ============================================================
# MARCSCRIPT - Main Menu
# ============================================================

MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "$MYIP")

clear
echo -e "\033[0;36m╔══════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[0;36m║\033[0m              \033[1;32m🚀 MARCSCRIPT VPN MENU\033[0m                           \033[0;36m║\033[0m"
echo -e "\033[0;36m╚══════════════════════════════════════════════════════════════╝\033[0m"
echo ""
echo -e " \033[1;33mMAIN MENU:\033[0m"
echo -e "  \033[1;36m[1]\033[0m SSH Menu          \033[1;36m[5]\033[0m System Info"
echo -e "  \033[1;36m[2]\033[0m Xray Menu         \033[1;36m[6]\033[0m Restart Services"
echo -e "  \033[1;36m[3]\033[0m Service Status    \033[1;36m[7]\033[0m Change Domain"
echo -e "  \033[1;36m[4]\033[0m Delete User       \033[1;36m[8]\033[0m Update Script"
echo ""
echo -e " \033[1;33mQUICK CREATE:\033[0m"
echo -e "  \033[1;36m[a]\033[0m SSH Account   \033[1;36m[c]\033[0m VLess Account"
echo -e "  \033[1;36m[b]\033[0m VMess Account \033[1;36m[d]\033[0m Trojan Account"
echo ""
echo -e " \033[1;31m[0]\033[0m Exit"
echo ""
echo -e "\033[0;36m──────────────────────────────────────────────────────────────\033[0m"
echo -e " IP    : \033[1;32m$MYIP\033[0m"
echo -e " Domain: \033[1;32m$DOMAIN\033[0m"
echo -e " OS    : \033[1;32m$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY | cut -d'"' -f2)\033[0m"
echo -e "\033[0;36m──────────────────────────────────────────────────────────────\033[0m"
echo ""
read -p "Select menu : " opt

case $opt in
    1)
        clear
        echo -e "\033[0;36m╔══════════════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[0;36m║\033[0m                     \033[1;33mSSH MENU\033[0m                               \033[0;36m║\033[0m"
        echo -e "\033[0;36m╚══════════════════════════════════════════════════════════════╝\033[0m"
        echo ""
        echo -e "  \033[1;36m[1]\033[0m Create SSH User"
        echo -e "  \033[1;36m[2]\033[0m Delete SSH User"
        echo -e "  \033[1;36m[3]\033[0m List SSH Users"
        echo -e "  \033[1;36m[4]\033[0m Check SSH Logins"
        echo -e "  \033[1;36m[5]\033[0m Change SSH Port"
        echo ""
        echo -e "  \033[1;31m[0]\033[0m Back"
        echo ""
        read -p "Select : " sshopt
        case $sshopt in
            1) add-ssh ;;
            2) del-user ssh ;;
            3) list-ssh 2>/dev/null || awk -F: '$3>=1000{print $1}' /etc/passwd ;;
            4) ss -tnp | grep sshd | grep ESTAB ;;
            5) 
                read -p "New SSH Port: " newport
                sed -i "s/Port 22/Port $newport/" /etc/ssh/sshd_config
                systemctl restart ssh
                echo "SSH port changed to $newport"
                ;;
            0) menu ;;
        esac
        ;;
    2)
        clear
        echo -e "\033[0;36m╔══════════════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[0;36m║\033[0m                    \033[1;33mXRAY MENU\033[0m                              \033[0;36m║\033[0m"
        echo -e "\033[0;36m╚══════════════════════════════════════════════════════════════╝\033[0m"
        echo ""
        echo -e "  \033[1;36m[1]\033[0m VMess Menu"
        echo -e "  \033[1;36m[2]\033[0m VLess Menu"
        echo -e "  \033[1;36m[3]\033[0m Trojan Menu"
        echo -e "  \033[1;36m[4]\033[0m Shadowsocks Menu"
        echo ""
        echo -e "  \033[1;31m[0]\033[0m Back"
        echo ""
        read -p "Select : " xopt
        case $xopt in
            1) xray_menu vmess ;;
            2) xray_menu vless ;;
            3) xray_menu trojan ;;
            4) xray_menu ss ;;
            0) menu ;;
        esac
        ;;
    3) check ; read -p "Press enter..." ; menu ;;
    4)
        clear
        echo -e "\033[0;36m╔══════════════════════════════════════════════════════════════╗\033[0m"
        echo -e "\033[0;36m║\033[0m                   \033[1;31mDELETE USER\033[0m                            \033[0;36m║\033[0m"
        echo -e "\033[0;36m╚══════════════════════════════════════════════════════════════╝\033[0m"
        echo ""
        echo -e "  \033[1;36m[1]\033[0m SSH    \033[1;36m[3]\033[0m VLess"
        echo -e "  \033[1;36m[2]\033[0m VMess  \033[1;36m[4]\033[0m Trojan"
        echo ""
        read -p "Select : " dopt
        case $dopt in
            1) del-user ssh ;;
            2) del-user vmess ;;
            3) del-user vless ;;
            4) del-user trojan ;;
        esac
        menu
        ;;
    5) 
        clear
        echo -e "═══════════════════════════════════════"
        echo -e "         SYSTEM INFORMATION"
        echo -e "═══════════════════════════════════════"
        echo -e "OS      : $(lsb_release -ds 2>/dev/null)"
        echo -e "Kernel  : $(uname -r)"
        echo -e "CPU     : $(nproc) cores"
        echo -e "Memory  : $(free -h | awk '/Mem/{print $2}')"
        echo -e "Disk    : $(df -h / | awk 'NR==2{print $2}')"
        echo -e "Uptime  : $(uptime -p)"
        echo -e "IP      : $MYIP"
        echo -e "═══════════════════════════════════════"
        read -p "Press enter..."
        menu
        ;;
    6) 
        systemctl restart ssh stunnel4 nginx xray squid ws-proxy 2>/dev/null
        echo -e "\033[1;32m✅ All services restarted\033[0m"
        sleep 2
        menu
        ;;
    7)
        read -p "Enter domain: " domain
        echo "$domain" > /etc/xray/domain
        echo -e "\033[1;32m✅ Domain changed to $domain\033[0m"
        sleep 2
        menu
        ;;
    8)
        echo "Updating MarcScript..."
        bash <(curl -s https://raw.githubusercontent.com/Jhon-mark23/marcscript/main/setup.sh)
        ;;
    a) add-ssh ; menu ;;
    b) add-vmess ; menu ;;
    c) add-vless ; menu ;;
    d) add-trojan ; menu ;;
    0) clear ; exit 0 ;;
    *) menu ;;
esac
