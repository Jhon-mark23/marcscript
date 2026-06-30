#!/bin/bash
# MarcScript - Xray Management Scripts

source /usr/local/marcscript/lib/common.sh

install_xray_scripts() {
    log_info "Installing Xray management scripts..."
    
    domain=$(get_domain)
    uuid=$(cat /etc/xray/uuid 2>/dev/null || echo "auto")
    
    # Vmess Account Creator
    cat > /usr/local/bin/add-ws << VMESSADD
#!/bin/bash
clear
domain=\$(cat /etc/xray/domain 2>/dev/null || echo "$domain")
uuid=\$(cat /etc/xray/uuid)

echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m   • CREATE VMESS ACCOUNT •   \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username : " user
read -p "Expired (days): " masaaktif

exp=\$(date -d "\$masaaktif days" +"%Y-%m-%d")

echo "### \${user} \${exp}" >> /etc/xray/vmess.db

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m  • VMESS ACCOUNT CREATED •  \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Protocol   : VMess WS TLS"
echo -e "IP/Domain  : \${domain}"
echo -e "Port       : 443"
echo -e "UUID       : \${uuid}"
echo -e "AlterID    : 0"
echo -e "Path       : /vmess"
echo -e "TLS        : Yes"
echo -e "Expired    : \${exp}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "VMess Link: vmess://\$(echo -n '{"v":"2","ps":"\${user}","add":"\${domain}","port":"443","id":"\${uuid}","aid":"0","net":"ws","path":"/vmess","type":"none","host":"","tls":"tls"}' | base64 -w 0)"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
VMESSADD
    chmod +x /usr/local/bin/add-ws
    
    # Vless Account Creator
    cat > /usr/local/bin/add-vless << VLESSADD
#!/bin/bash
clear
domain=\$(cat /etc/xray/domain 2>/dev/null || echo "$domain")
uuid=\$(cat /etc/xray/uuid)

echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m   • CREATE VLESS ACCOUNT •   \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username : " user
read -p "Expired (days): " masaaktif

exp=\$(date -d "\$masaaktif days" +"%Y-%m-%d")

echo "### \${user} \${exp}" >> /etc/xray/vless.db

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m  • VLESS ACCOUNT CREATED •  \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Protocol   : VLess WS TLS"
echo -e "IP/Domain  : \${domain}"
echo -e "Port       : 443"
echo -e "UUID       : \${uuid}"
echo -e "Path       : /vless"
echo -e "TLS        : Yes"
echo -e "Expired    : \${exp}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
VLESSADD
    chmod +x /usr/local/bin/add-vless
    
    # Trojan Account Creator
    cat > /usr/local/bin/add-tr << TROJANADD
#!/bin/bash
clear
domain=\$(cat /etc/xray/domain 2>/dev/null || echo "$domain")
uuid=\$(cat /etc/xray/uuid)

echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m  • CREATE TROJAN ACCOUNT •  \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
read -p "Username : " user
read -p "Expired (days): " masaaktif

exp=\$(date -d "\$masaaktif days" +"%Y-%m-%d")

echo "### \${user} \${exp}" >> /etc/xray/trojan.db

clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "\E[0;100;33m • TROJAN ACCOUNT CREATED • \E[0m"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "Protocol   : Trojan WS TLS"
echo -e "IP/Domain  : \${domain}"
echo -e "Port       : 443"
echo -e "Password   : \${uuid}"
echo -e "Path       : /trojan-ws"
echo -e "TLS        : Yes"
echo -e "Expired    : \${exp}"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
TROJANADD
    chmod +x /usr/local/bin/add-tr
    
    # Trial scripts
    for proto in ws vless tr; do
        cat > /usr/local/bin/trial${proto} << TRIALEOF
#!/bin/bash
# Trial ${proto} account
echo "Trial ${proto} - 1 day"
TRIALEOF
        chmod +x /usr/local/bin/trial${proto}
    done
    
    # Delete scripts
    for proto in ws vless tr; do
        cat > /usr/local/bin/del-${proto} << DELEOF
#!/bin/bash
clear
echo -e "Delete ${proto} account"
read -p "Username: " user
sed -i "/\${user}/d" /etc/xray/${proto}.db 2>/dev/null
echo "User \${user} deleted"
systemctl restart xray
DELEOF
        chmod +x /usr/local/bin/del-${proto}
    done
    
    # Check login scripts
    for proto in ws vless tr; do
        cat > /usr/local/bin/cek-${proto} << CEKEOF
#!/bin/bash
clear
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
echo -e "   ${proto} Online Users"
echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
cat /var/log/xray/access.log 2>/dev/null | grep -i ${proto} | tail -20
CEKEOF
        chmod +x /usr/local/bin/cek-${proto}
    done
    
    # Touch database files
    touch /etc/xray/{vmess,vless,trojan}.db
    
    log_success "Xray management scripts installed"
}
