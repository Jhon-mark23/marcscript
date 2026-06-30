#!/bin/bash
# MarcScript - SSH Menu

source /usr/local/marcscript/lib/common.sh

ssh_menu() {
    clear
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;100;33m      • SSH/OVPN MENU •        \E[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    echo -e " [\e[36m1\e[0m] Create SSH Account"
    echo -e " [\e[36m2\e[0m] Trial SSH Account"
    echo -e " [\e[36m3\e[0m] Delete SSH Account"
    echo -e " [\e[36m4\e[0m] List SSH Users"
    echo -e " [\e[36m5\e[0m] Check SSH Login"
    echo -e ""
    echo -e " [\e[31m0\e[0m] Back to Main Menu"
    echo -e ""
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    read -p "Select menu: " opt
    case $opt in
        1) add-ssh ;;
        2) trial-ssh ;;
        3) del-ssh ;;
        4) list-ssh ;;
        5) 
            clear
            echo -e "${CYAN}Active SSH Connections:${NC}"
            ss -tnp | grep sshd | grep ESTAB
            read -p "Press enter to continue..."
            ssh_menu
            ;;
        0) menu ;;
        *) ssh_menu ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ssh_menu
fi
