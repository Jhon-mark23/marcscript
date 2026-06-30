#!/bin/bash
# ============================================================
# MARCSCRIPT VPN - Main Menu
# GitHub: https://github.com/Jhon-mark23/marcscript
# License: MIT
# ============================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# System info
MYIP=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)
DOMAIN=$(cat /etc/xray/domain 2>/dev/null || echo "$MYIP")

# Service status helper
svc_status() {
    if systemctl is-active --quiet $1 2>/dev/null; then
        echo -e "${GREEN}Active${NC}"
    else
        echo -e "${RED}Dead${NC}"
    fi
}

# ============================================================
# MAIN MENU
# ============================================================
main_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}🚀 MARCSCRIPT VPN MENU${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} SSH/OVPN Menu     ${CYAN}[5]${NC} System Info"
    echo -e "  ${CYAN}[2]${NC} Xray/V2Ray Menu   ${CYAN}[6]${NC} Restart Services"
    echo -e "  ${CYAN}[3]${NC} Service Status    ${CYAN}[7]${NC} Change Domain"
    echo -e "  ${CYAN}[4]${NC} Delete User       ${CYAN}[8]${NC} Update Script"
    echo ""
    echo -e "  ${RED}[0]${NC} Exit"
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo -e " IP    : ${GREEN}$MYIP${NC}"
    echo -e " Domain: ${GREEN}$DOMAIN${NC}"
    echo -e " Xray  : $(svc_status xray)  |  SSH : $(svc_status ssh)"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo ""
    read -p " Select menu : " opt
    
    case $opt in
        1) ssh_menu ;;
        2) xray_menu ;;
        3) service_status ; read -p "Press enter..." ; main_menu ;;
        4) delete_menu ;;
        5) system_info ; read -p "Press enter..." ; main_menu ;;
        6) 
            echo -e "\n${YELLOW}Restarting all services...${NC}"
            for svc in ssh stunnel4 nginx xray squid ws-proxy; do
                systemctl restart $svc 2>/dev/null
            done
            echo -e "${GREEN}✅ All services restarted${NC}"
            sleep 2 ; main_menu
            ;;
        7)
            read -p "Enter new domain : " d
            echo "$d" > /etc/xray/domain
            DOMAIN="$d"
            echo -e "${GREEN}✅ Domain updated to $d${NC}"
            sleep 2 ; main_menu
            ;;
        8)
            echo -e "${YELLOW}Updating MarcScript...${NC}"
            bash <(curl -s https://raw.githubusercontent.com/Jhon-mark23/marcscript/main/setup.sh)
            ;;
        0) clear ; exit 0 ;;
        *) main_menu ;;
    esac
}

# ============================================================
# SSH MENU
# ============================================================
ssh_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                     ${GREEN}SSH MENU${NC}                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Create SSH Account"
    echo -e "  ${CYAN}[2]${NC} Trial SSH (1 Day)"
    echo -e "  ${CYAN}[3]${NC} Delete SSH User"
    echo -e "  ${CYAN}[4]${NC} List SSH Users"
    echo -e "  ${CYAN}[5]${NC} Check Online Users"
    echo -e "  ${CYAN}[6]${NC} Change Password"
    echo -e "  ${CYAN}[7]${NC} Renew SSH User"
    echo ""
    echo -e "  ${RED}[0]${NC} Back to Main Menu"
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo -e " Status: $(svc_status ssh) | Ports: 22, 80 | SSL: 8445"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo ""
    read -p " Select menu : " opt
    
    case $opt in
        1)
            clear
            echo -e "${GREEN}CREATE SSH ACCOUNT${NC}"
            echo ""
            read -p "Username : " user
            read -p "Password : " pass
            read -p "Duration (days) : " days
            
            if id "$user" &>/dev/null; then
                echo -e "${RED}❌ User already exists!${NC}"
            else
                useradd -m -s /bin/bash "$user" 2>/dev/null
                echo "$user:$pass" | chpasswd
                exp=$(date -d "+$days days" +"%Y-%m-%d")
                chage -E "$exp" "$user" 2>/dev/null
                
                clear
                echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║${NC}              ${GREEN}SSH ACCOUNT CREATED ✅${NC}                          ${CYAN}║${NC}"
                echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                echo -e " Username : ${GREEN}$user${NC}"
                echo -e " Password : ${GREEN}$pass${NC}"
                echo -e " Expired  : ${RED}$exp${NC}"
                echo -e " IP/Host  : ${GREEN}$MYIP${NC}"
                echo ""
                echo -e " Ports: SSH:22,80 | SSL:8445 | WS:8080 | WSS:8446"
                echo -e " Proxy: 3128, 8082, 8888"
            fi
            echo ""
            read -p "Press enter..." ; ssh_menu
            ;;
        2)
            user="trialssh$(date +%s | tail -c 5)"
            pass="12345"
            useradd -m -s /bin/bash "$user" 2>/dev/null
            echo "$user:$pass" | chpasswd
            chage -E "$(date -d '+1 days' +%Y-%m-%d)" "$user" 2>/dev/null
            
            clear
            echo -e "${YELLOW}TRIAL SSH ACCOUNT (1 Day)${NC}"
            echo -e " Username: ${GREEN}$user${NC}  Password: ${GREEN}$pass${NC}"
            echo -e " IP: ${GREEN}$MYIP${NC}"
            echo ""
            read -p "Press enter..." ; ssh_menu
            ;;
        3)
            clear
            echo -e "${RED}DELETE SSH USER${NC}"
            echo ""
            awk -F: '$3>=1000 && $7!="/usr/sbin/nologin" {print $1}' /etc/passwd
            echo ""
            read -p "Username to delete : " user
            userdel -r "$user" 2>/dev/null && echo -e "${GREEN}✅ Deleted${NC}" || echo -e "${RED}❌ Not found${NC}"
            sleep 2 ; ssh_menu
            ;;
        4)
            clear
            echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║${NC}              ${GREEN}SSH USERS LIST${NC}                                  ${CYAN}║${NC}"
            echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
            echo ""
            printf "  %-4s %-18s %-14s %s\n" "No." "Username" "Expired" "Status"
            echo "  ──── ────────────────── ────────────── ────────"
            count=0
            while IFS=: read -r user _ uid _ _ _ _ shell; do
                [ $uid -ge 1000 ] && [ "$shell" != "/usr/sbin/nologin" ] && {
                    count=$((count+1))
                    exp=$(chage -l "$user" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
                    [ -z "$exp" ] && exp="Never"
                    [ "$exp" != "Never" ] && [ $(date -d "$exp" +%s 2>/dev/null) -lt $(date +%s) ] && st="${RED}Expired${NC}" || st="${GREEN}Active${NC}"
                    printf "  %-4s %-18s %-14s %b\n" "$count" "$user" "$exp" "$st"
                }
            done < /etc/passwd
            echo ""
            read -p "Press enter..." ; ssh_menu
            ;;
        5)
            clear
            echo -e "${GREEN}ACTIVE SSH CONNECTIONS:${NC}"
            ss -tnp 2>/dev/null | grep sshd | grep ESTAB || echo "No active connections"
            echo ""
            read -p "Press enter..." ; ssh_menu
            ;;
        6)
            read -p "Username : " u
            read -p "New Password : " p
            echo "$u:$p" | chpasswd && echo -e "${GREEN}✅ Changed${NC}" || echo -e "${RED}❌ Failed${NC}"
            sleep 2 ; ssh_menu
            ;;
        7)
            read -p "Username : " u
            read -p "Add Days : " d
            exp=$(date -d "+$d days" +"%Y-%m-%d")
            chage -E "$exp" "$u" 2>/dev/null && echo -e "${GREEN}✅ Renewed until $exp${NC}" || echo -e "${RED}❌ Failed${NC}"
            sleep 2 ; ssh_menu
            ;;
        0) main_menu ;;
        *) ssh_menu ;;
    esac
}

# ============================================================
# XRAY MENU
# ============================================================
xray_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}XRAY MENU${NC}                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} VMess Menu        (WebSocket + gRPC)"
    echo -e "  ${CYAN}[2]${NC} VLess Menu        (WebSocket + gRPC)"
    echo -e "  ${CYAN}[3]${NC} Trojan Menu       (WebSocket + gRPC)"
    echo -e "  ${CYAN}[4]${NC} Shadowsocks Menu  (WebSocket + gRPC)"
    echo ""
    echo -e "  ${RED}[0]${NC} Back to Main Menu"
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo -e " Xray  : $(svc_status xray)"
    echo -e " Domain: ${GREEN}$DOMAIN${NC}"
    echo -e " TLS   : ${GREEN}443${NC}  |  NTLS : ${GREEN}80${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo ""
    read -p " Select menu : " opt
    
    case $opt in
        1)
            # Check if m-vmess.sh exists
            if [ -f /usr/local/marcscript/menu/m-vmess.sh ]; then
                bash /usr/local/marcscript/menu/m-vmess.sh
            elif [ -f /usr/local/bin/m-vmess ]; then
                m-vmess
            else
                vmess_menu_fallback
            fi
            ;;
        2)
            if [ -f /usr/local/marcscript/menu/m-vless.sh ]; then
                bash /usr/local/marcscript/menu/m-vless.sh
            elif [ -f /usr/local/bin/m-vless ]; then
                m-vless
            else
                vless_menu_fallback
            fi
            ;;
        3)
            if [ -f /usr/local/marcscript/menu/m-trojan.sh ]; then
                bash /usr/local/marcscript/menu/m-trojan.sh
            elif [ -f /usr/local/bin/m-trojan ]; then
                m-trojan
            else
                trojan_menu_fallback
            fi
            ;;
        4)
            if [ -f /usr/local/marcscript/menu/m-ssws.sh ]; then
                bash /usr/local/marcscript/menu/m-ssws.sh
            elif [ -f /usr/local/bin/m-ss ]; then
                m-ss
            else
                ss_menu_fallback
            fi
            ;;
        0) main_menu ;;
        *) xray_menu ;;
    esac
}

# ============================================================
# FALLBACK MENUS (if m-*.sh files don't exist)
# ============================================================
vmess_menu_fallback() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}VMESS MENU${NC}                                ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Create VMess     ${CYAN}[4]${NC} Delete VMess"
    echo -e "  ${CYAN}[2]${NC} Trial VMess      ${CYAN}[5]${NC} Check Logins"
    echo -e "  ${CYAN}[3]${NC} Renew VMess      ${CYAN}[6]${NC} User List"
    echo ""
    echo -e "  ${RED}[0]${NC} Back"
    echo ""
    read -p " Select : " opt
    case $opt in
        1) add-ws 2>/dev/null || bash /usr/local/marcscript/xray/add-ws.sh ;;
        2) trialvmess 2>/dev/null || bash /usr/local/marcscript/xray/trialvmess.sh ;;
        3) renew-ws 2>/dev/null || bash /usr/local/marcscript/xray/renew-ws.sh ;;
        4) del-ws 2>/dev/null || bash /usr/local/marcscript/xray/del-ws.sh ;;
        5) cek-ws 2>/dev/null || bash /usr/local/marcscript/xray/cek-ws.sh ;;
        6) cat /etc/xray/vmess.db 2>/dev/null | grep "^###" || echo "No users" ; read -p "Press enter..." ;;
        0) xray_menu ;;
    esac
}

vless_menu_fallback() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}VLESS MENU${NC}                                ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Create VLess     ${CYAN}[4]${NC} Delete VLess"
    echo -e "  ${CYAN}[2]${NC} Trial VLess      ${CYAN}[5]${NC} Check Logins"
    echo -e "  ${CYAN}[3]${NC} Renew VLess      ${CYAN}[6]${NC} User List"
    echo ""
    echo -e "  ${RED}[0]${NC} Back"
    echo ""
    read -p " Select : " opt
    case $opt in
        1) add-vless 2>/dev/null || bash /usr/local/marcscript/xray/add-vless.sh ;;
        2) trialvless 2>/dev/null || bash /usr/local/marcscript/xray/trialvless.sh ;;
        3) renew-vless 2>/dev/null || bash /usr/local/marcscript/xray/renew-vless.sh ;;
        4) del-vless 2>/dev/null || bash /usr/local/marcscript/xray/del-vless.sh ;;
        5) cek-vless 2>/dev/null || bash /usr/local/marcscript/xray/cek-vless.sh ;;
        6) cat /etc/xray/vless.db 2>/dev/null | grep "^###" || echo "No users" ; read -p "Press enter..." ;;
        0) xray_menu ;;
    esac
}

trojan_menu_fallback() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${GREEN}TROJAN MENU${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Create Trojan    ${CYAN}[4]${NC} Delete Trojan"
    echo -e "  ${CYAN}[2]${NC} Trial Trojan     ${CYAN}[5]${NC} Check Logins"
    echo -e "  ${CYAN}[3]${NC} Renew Trojan     ${CYAN}[6]${NC} User List"
    echo ""
    echo -e "  ${RED}[0]${NC} Back"
    echo ""
    read -p " Select : " opt
    case $opt in
        1) add-tr 2>/dev/null || bash /usr/local/marcscript/xray/add-tr.sh ;;
        2) trialtrojan 2>/dev/null || bash /usr/local/marcscript/xray/trialtrojan.sh ;;
        3) renew-tr 2>/dev/null || bash /usr/local/marcscript/xray/renew-tr.sh ;;
        4) del-tr 2>/dev/null || bash /usr/local/marcscript/xray/del-tr.sh ;;
        5) cek-tr 2>/dev/null || bash /usr/local/marcscript/xray/cek-tr.sh ;;
        6) cat /etc/xray/trojan.db 2>/dev/null | grep "^###" || echo "No users" ; read -p "Press enter..." ;;
        0) xray_menu ;;
    esac
}

ss_menu_fallback() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                ${GREEN}SHADOWSOCKS MENU${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Create SS        ${CYAN}[3]${NC} Delete SS"
    echo -e "  ${CYAN}[2]${NC} Trial SS         ${CYAN}[4]${NC} User List"
    echo ""
    echo -e "  ${RED}[0]${NC} Back"
    echo ""
    read -p " Select : " opt
    case $opt in
        1) add-ssws 2>/dev/null || bash /usr/local/marcscript/xray/add-ssws.sh ;;
        2) trialssws 2>/dev/null || bash /usr/local/marcscript/xray/trialssws.sh ;;
        3) del-ssws 2>/dev/null || bash /usr/local/marcscript/xray/del-ssws.sh ;;
        4) cat /etc/xray/ss.db 2>/dev/null | grep "^###" || echo "No users" ; read -p "Press enter..." ;;
        0) xray_menu ;;
    esac
}

# ============================================================
# DELETE USER MENU
# ============================================================
delete_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                   ${RED}DELETE USER MENU${NC}                           ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${CYAN}[1]${NC} Delete SSH User"
    echo -e "  ${CYAN}[2]${NC} Delete VMess User"
    echo -e "  ${CYAN}[3]${NC} Delete VLess User"
    echo -e "  ${CYAN}[4]${NC} Delete Trojan User"
    echo -e "  ${CYAN}[5]${NC} Delete SS User"
    echo ""
    echo -e "  ${RED}[0]${NC} Back"
    echo ""
    read -p " Select : " opt
    case $opt in
        1) 
            read -p "Username: " u
            userdel -r "$u" 2>/dev/null && echo -e "${GREEN}✅ Deleted${NC}" || echo -e "${RED}❌ Not found${NC}"
            sleep 2 ; delete_menu
            ;;
        2) del-ws 2>/dev/null || bash /usr/local/marcscript/xray/del-ws.sh ; delete_menu ;;
        3) del-vless 2>/dev/null || bash /usr/local/marcscript/xray/del-vless.sh ; delete_menu ;;
        4) del-tr 2>/dev/null || bash /usr/local/marcscript/xray/del-tr.sh ; delete_menu ;;
        5) del-ssws 2>/dev/null || bash /usr/local/marcscript/xray/del-ssws.sh ; delete_menu ;;
        0) main_menu ;;
        *) delete_menu ;;
    esac
}

# ============================================================
# SERVICE STATUS
# ============================================================
service_status() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}MARCSCRIPT SERVICE STATUS${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e " SSH         : $(svc_status ssh)      (Port 22, 80)"
    echo -e " Stunnel     : $(svc_status stunnel4) (Port 8445, 8446)"
    echo -e " Nginx       : $(svc_status nginx)    (Port 80, 443)"
    echo -e " Xray        : $(svc_status xray)     (TLS:443 / NTLS:80)"
    echo -e " Squid       : $(svc_status squid)    (3128, 8082, 8888)"
    echo -e " WS Proxy    : $(svc_status ws-proxy) (Port 8080)"
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo -e " IP    : ${GREEN}$MYIP${NC}"
    echo -e " Domain: ${GREEN}$DOMAIN${NC}"
    echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
    echo ""
    if [ -f /usr/local/bin/xray ]; then
        echo -e "${YELLOW}Xray Users:${NC}"
        echo -e "  VMess  : $(grep -c '###' /etc/xray/vmess.db 2>/dev/null || echo 0) users"
        echo -e "  VLess  : $(grep -c '###' /etc/xray/vless.db 2>/dev/null || echo 0) users"
        echo -e "  Trojan : $(grep -c '###' /etc/xray/trojan.db 2>/dev/null || echo 0) users"
        echo -e "  SS     : $(grep -c '###' /etc/xray/ss.db 2>/dev/null || echo 0) users"
    fi
    echo ""
}

# ============================================================
# SYSTEM INFO
# ============================================================
system_info() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         SYSTEM INFORMATION           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    echo -e " OS      : $(lsb_release -ds 2>/dev/null || cat /etc/os-release | head -1)"
    echo -e " Kernel  : $(uname -r)"
    echo -e " CPU     : $(nproc) cores"
    echo -e " Memory  : $(free -h | awk '/Mem/{print $2}')"
    echo -e " Disk    : $(df -h / | awk 'NR==2{print $2}')"
    echo -e " Uptime  : $(uptime -p)"
    echo -e " IP      : $MYIP"
    echo -e " Domain  : $DOMAIN"
    echo -e " Xray    : $(svc_status xray)"
    echo ""
}

# ============================================================
# INIT
# ============================================================
# Create database files if missing
touch /etc/xray/{vmess,vless,trojan,ss}.db 2>/dev/null

# Create menu symlinks if they don't exist
mkdir -p /usr/local/marcscript/menu
for m in m-vmess m-vless m-trojan m-ssws; do
    if [ ! -f /usr/local/bin/$m ] && [ -f /usr/local/marcscript/menu/${m}.sh ]; then
        ln -sf /usr/local/marcscript/menu/${m}.sh /usr/local/bin/$m 2>/dev/null
    fi
done

# Run main menu
main_menu