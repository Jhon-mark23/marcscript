#!/bin/bash
# MarcScript - Management Scripts

source /usr/local/marcscript/lib/common.sh

create_management_scripts() {
    log_info "Creating management scripts..."
    
    # SSH User Creator
    cat > /usr/local/bin/add-ssh << 'EOF'
#!/bin/bash
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m     • CREATE SSH ACCOUNT •      \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username : " USER
read -p "Password : " PASS
read -p "Expire (days) : " DAYS

if id "$USER" &>/dev/null; then
    echo "User already exists!"
    exit 1
fi

useradd -m -s /bin/bash "$USER"
echo "$USER:$PASS" | chpasswd
EXPIRE_DATE=$(date -d "$DAYS days" +"%Y-%m-%d")
chage -E "$EXPIRE_DATE" "$USER"

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m    • ACCOUNT CREATED •        \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Username   : $USER"
echo -e "Password   : $PASS"
echo -e "Expired    : $EXPIRE_DATE"
echo -e "IP         : $(wget -qO- ipv4.icanhazip.com)"
echo -e "SSH Port   : 22, 80"
echo -e "SSL Port   : 443"
echo -e "WS Port    : 8080"
echo -e "Squid      : 3128, 8082, 8888"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
EOF
    chmod +x /usr/local/bin/add-ssh
    
    # Trial SSH
    cat > /usr/local/bin/trial-ssh << 'EOF'
#!/bin/bash
clear
USER="trial$(date +%s | tail -c 5)"
PASS="12345"
DAYS=1

useradd -m -s /bin/bash "$USER" 2>/dev/null
echo "$USER:$PASS" | chpasswd
EXPIRE_DATE=$(date -d "$DAYS days" +"%Y-%m-%d")
chage -E "$EXPIRE_DATE" "$USER" 2>/dev/null

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m    • TRIAL SSH ACCOUNT •      \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Username   : $USER"
echo -e "Password   : $PASS"
echo -e "Expired    : $EXPIRE_DATE"
echo -e "IP         : $(wget -qO- ipv4.icanhazip.com)"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
EOF
    chmod +x /usr/local/bin/trial-ssh
    
    # Delete SSH User
    cat > /usr/local/bin/del-ssh << 'EOF'
#!/bin/bash
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m    • DELETE SSH USER •        \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username to delete: " USER

if id "$USER" &>/dev/null; then
    userdel -r "$USER" 2>/dev/null
    echo -e "${GREEN}User $USER deleted successfully${NC}"
else
    echo -e "${RED}User $USER not found${NC}"
fi
EOF
    chmod +x /usr/local/bin/del-ssh
    
    # List SSH Users
    cat > /usr/local/bin/list-ssh << 'EOF'
#!/bin/bash
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m     • SSH USERS LIST •        \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "USERNAME          EXPIRED"
echo -e "----------------  -----------"
while IFS=: read -r user _ uid _ _ _ _; do
    if [ $uid -ge 1000 ]; then
        exp=$(chage -l "$user" 2>/dev/null | grep "Account expires" | cut -d: -f2)
        printf "%-16s %s\n" "$user" "${exp:-Never}"
    fi
done < /etc/passwd
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
EOF
    chmod +x /usr/local/bin/list-ssh
    
    # Service Status
    cat > /usr/local/bin/vpn-status << 'EOF'
#!/bin/bash
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m   • MARCSCRIPT VPN STATUS •   \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo ""
echo -e "SSH         : $(systemctl is-active ssh 2>/dev/null || echo 'dead')"
echo -e "Stunnel     : $(systemctl is-active stunnel4 2>/dev/null || echo 'dead')"
echo -e "Nginx       : $(systemctl is-active nginx 2>/dev/null || echo 'dead')"
echo -e "Xray        : $(systemctl is-active xray 2>/dev/null || echo 'dead')"
echo -e "Squid       : $(systemctl is-active squid 2>/dev/null || echo 'dead')"
echo -e "WS Proxy    : $(systemctl is-active ws-proxy 2>/dev/null || echo 'dead')"
echo -e "API         : $(systemctl is-active marcscript-api 2>/dev/null || echo 'dead')"
echo ""
echo -e "IP : $(wget -qO- ipv4.icanhazip.com)"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
EOF
    chmod +x /usr/local/bin/vpn-status
    
    # Global menu command
    ln -sf /usr/local/marcscript/menu/menu.sh /usr/local/bin/menu 2>/dev/null
    chmod +x /usr/local/bin/menu 2>/dev/null
    
    log_success "Management scripts created"
}
