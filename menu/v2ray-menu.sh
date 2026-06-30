#!/bin/bash
# MarcScript - V2Ray/Xray Menu

v2ray_menu() {
    clear
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;100;33m      • V2RAY/XRAY MENU •      \E[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    echo -e " [\e[36m1\e[0m] VMess Menu"
    echo -e " [\e[36m2\e[0m] VLess Menu"
    echo -e " [\e[36m3\e[0m] Trojan Menu"
    echo -e " [\e[36m4\e[0m] Shadowsocks Menu"
    echo -e ""
    echo -e " [\e[31m0\e[0m] Back to Main Menu"
    echo -e ""
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    read -p "Select menu: " opt
    case $opt in
        1) m-vmess ;;
        2) m-vless ;;
        3) m-trojan ;;
        4) m-ss ;;
        0) menu ;;
        *) v2ray_menu ;;
    esac
}
