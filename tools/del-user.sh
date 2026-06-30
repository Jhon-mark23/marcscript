#!/bin/bash
# ============================================================
# MARCSCRIPT - Delete User
# ============================================================

source /usr/local/marcscript/lib/common.sh

TYPE=$1

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${RED}DELETE USER ACCOUNT${NC}                           ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ -z "$TYPE" ]; then
    echo -e "Select type:"
    echo -e "  ${GREEN}1${NC}) SSH"
    echo -e "  ${GREEN}2${NC}) VMess"
    echo -e "  ${GREEN}3${NC}) VLess"
    echo -e "  ${GREEN}4${NC}) Trojan"
    echo ""
    read -p "Select : " t
    case $t in
        1) TYPE="ssh" ;;
        2) TYPE="vmess" ;;
        3) TYPE="vless" ;;
        4) TYPE="trojan" ;;
        *) echo "Invalid" ; exit 1 ;;
    esac
fi

read -p "Username to delete : " user

case $TYPE in
    ssh)
        userdel -r "$user" 2>/dev/null
        echo -e "${GREEN}SSH user '$user' deleted${NC}"
        ;;
    vmess|vless|trojan)
        sed -i "/### ${user} /d" /etc/xray/${TYPE}.db 2>/dev/null
        systemctl restart xray 2>/dev/null
        echo -e "${GREEN}${TYPE^^} user '$user' deleted${NC}"
        ;;
    *)
        echo -e "${RED}Invalid type${NC}"
        ;;
esac
