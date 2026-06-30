#!/bin/bash
# ============================================================
# MARCSCRIPT - VLess Menu
# ============================================================

MYIP=$(wget -qO- ipv4.icanhazip.com)
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m       • VLESS MENU •         \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e ""
echo -e " [\e[36m•1\e[0m] Create Account Vless"
echo -e " [\e[36m•2\e[0m] Trial Account Vless"
echo -e " [\e[36m•3\e[0m] Extending Account Vless"
echo -e " [\e[36m•4\e[0m] Delete Account Vless"
echo -e " [\e[36m•5\e[0m] Check User Login Vless"
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
    1) 
        clear
        # Try multiple paths for add-vless
        if command -v add-vless &>/dev/null; then
            add-vless
        elif [ -f /usr/local/marcscript/xray/add-vless.sh ]; then
            bash /usr/local/marcscript/xray/add-vless.sh
        else
            echo "add-vless script not found!"
            sleep 2
            bash /usr/local/marcscript/menu/m-vless.sh
        fi
        ;;
    2) 
        clear
        if command -v trialvless &>/dev/null; then
            trialvless
        elif [ -f /usr/local/marcscript/xray/trialvless.sh ]; then
            bash /usr/local/marcscript/xray/trialvless.sh
        else
            # Fallback trial
            user="trialvl$(date +%s | tail -c 5)"
            exp=$(date -d "+1 days" +"%Y-%m-%d")
            echo "### ${user} ${exp}" >> /etc/xray/vless.db
            echo -e "\033[1;32mTrial VLess: $user | Exp: $exp\033[0m"
            read -p "Press enter..."
        fi
        ;;
    3) 
        clear
        if command -v renew-vless &>/dev/null; then
            renew-vless
        elif [ -f /usr/local/marcscript/xray/renew-vless.sh ]; then
            bash /usr/local/marcscript/xray/renew-vless.sh
        else
            read -p "Username: " u
            read -p "Add Days: " d
            exp=$(date -d "+$d days" +"%Y-%m-%d")
            sed -i "s/^### ${u} .*/### ${u} ${exp}/" /etc/xray/vless.db 2>/dev/null
            echo -e "\033[1;32mRenewed $u until $exp\033[0m"
            sleep 2
        fi
        ;;
    4) 
        clear
        if command -v del-vless &>/dev/null; then
            del-vless
        elif [ -f /usr/local/marcscript/xray/del-vless.sh ]; then
            bash /usr/local/marcscript/xray/del-vless.sh
        else
            read -p "Username to delete: " u
            sed -i "/^### ${u} /d" /etc/xray/vless.db 2>/dev/null
            systemctl restart xray 2>/dev/null
            echo -e "\033[1;32mDeleted $u\033[0m"
            sleep 2
        fi
        ;;
    5) 
        clear
        if command -v cek-vless &>/dev/null; then
            cek-vless
        elif [ -f /usr/local/marcscript/xray/cek-vless.sh ]; then
            bash /usr/local/marcscript/xray/cek-vless.sh
        else
            echo -e "\033[1;33mVLess Online:\033[0m"
            grep -i vless /var/log/xray/access.log 2>/dev/null | tail -20 || echo "No connections"
            read -p "Press enter..."
        fi
        ;;
    6) 
        clear
        cat /etc/xray/vless.db 2>/dev/null | grep "^###" | while read line; do
            u=$(echo "$line" | awk '{print $2}')
            e=$(echo "$line" | awk '{print $3}')
            echo -e "  \033[36m$u\033[0m - Exp: $e"
        done
        echo ""
        read -p "Press enter..." 
        ;;
    0) 
        clear
        menu 2>/dev/null || bash /usr/local/marcscript/menu.sh
        ;;
    x) exit ;;
    *) 
        echo "Invalid option" 
        sleep 1 
        bash /usr/local/marcscript/menu/m-vless.sh
        ;;
esac