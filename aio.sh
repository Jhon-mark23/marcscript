#!/bin/bash
# MarcScript All-in-One Installer
set -e

source /usr/local/marcscript/lib/common.sh
source /usr/local/marcscript/lib/safety.sh
source /usr/local/marcscript/lib/system.sh
source /usr/local/marcscript/lib/packages.sh
source /usr/local/marcscript/lib/firewall.sh
source /usr/local/marcscript/lib/management.sh
source /usr/local/marcscript/ssh/ssh-setup.sh
source /usr/local/marcscript/services/stunnel.sh
source /usr/local/marcscript/services/websocket.sh
source /usr/local/marcscript/services/squid.sh
source /usr/local/marcscript/services/api.sh
source /usr/local/marcscript/services/nginx.sh
source /usr/local/marcscript/xray/xray-core.sh
source /usr/local/marcscript/xray/xray-cert.sh
source /usr/local/marcscript/xray/xray-config.sh
source /usr/local/marcscript/xray/xray-scripts.sh

main() {
    clear
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;100;33m     MARCSCRIPT VPN INSTALLER     \E[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    
    safety_check
    get_system_info
    install_base_packages
    
    echo ""
    echo -e "Installing MarcScript VPN Services..."
    echo ""
    
    configure_ssh
    configure_stunnel
    configure_websocket
    configure_squid
    configure_api
    configure_firewall
    
    # Check if Xray should be installed
    echo ""
    read -p "Install Xray (VMess/VLess/Trojan/SS)? [y/N]: " install_xray
    if [[ "$install_xray" =~ ^[Yy]$ ]]; then
        install_xray
        setup_xray_cert
        generate_xray_config
        configure_nginx
        install_xray_scripts
        
        systemctl daemon-reload
        systemctl enable xray
        systemctl restart xray
        
        # Save domain
        if [ -f /root/domain ]; then
            cp /root/domain /etc/xray/domain
        elif [ ! -f /etc/xray/domain ]; then
            echo "$MYIP" > /etc/xray/domain
        fi
    fi
    
    create_management_scripts
    
    clear
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e "\E[0;100;33m  MARCSCRIPT INSTALLATION COMPLETE!  \E[0m"
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
    echo -e ""
    echo -e " Type \e[32mmenu\e[0m to access the control panel"
    echo -e ""
    echo -e " IP: \e[32m$MYIP\e[0m"
    echo -e " Domain: \e[32m$(cat /etc/xray/domain 2>/dev/null || echo 'Not Set')\e[0m"
    echo -e ""
    echo -e "\e[33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\033[0m"
}

trap 'rollback_on_error' ERR
main
