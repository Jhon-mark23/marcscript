#!/bin/bash
# ============================================================
# MARCSCRIPT - Service Status Checker
# ============================================================

source /usr/local/marcscript/lib/common.sh

clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}              ${GREEN}MARCSCRIPT SERVICE STATUS${NC}                     ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e " SSH         : $(service_status ssh)"
echo -e " Stunnel     : $(service_status stunnel4)"
echo -e " Nginx       : $(service_status nginx)"
echo -e " Xray        : $(service_status xray)"
echo -e " Squid       : $(service_status squid)"
echo -e " WS Proxy    : $(service_status ws-proxy)"
echo ""

echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
echo -e " IP    : ${GREEN}$MYIP${NC}"
echo -e " Domain: ${GREEN}$DOMAIN${NC}"
echo -e "${CYAN}──────────────────────────────────────────────────────────────${NC}"
echo ""

# Check Xray users
if [ -f /usr/local/bin/xray ]; then
    echo -e "${YELLOW}Xray Users:${NC}"
    echo -e "  VMess  : $(grep -c '###' /etc/xray/vmess.db 2>/dev/null || echo 0) users"
    echo -e "  VLess  : $(grep -c '###' /etc/xray/vless.db 2>/dev/null || echo 0) users"
    echo -e "  Trojan : $(grep -c '###' /etc/xray/trojan.db 2>/dev/null || echo 0) users"
fi
