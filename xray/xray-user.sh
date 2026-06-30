#!/bin/bash
# ============================================================
# MARCSCRIPT - Xray User Management
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || source $(dirname "$0")/../lib/common.sh

# ============================================================
# List Xray Users
# ============================================================
list_xray_users() {
    local proto=$1
    
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}${proto^^} USERS LIST${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local db_file="/etc/xray/${proto}.db"
    
    if [ ! -f "$db_file" ] || [ ! -s "$db_file" ]; then
        echo -e "  ${YELLOW}No ${proto^^} users found${NC}"
        return
    fi
    
    printf "  %-4s %-18s %-14s %s\n" "No." "Username" "Expired" "Status"
    echo "  ──── ────────────────── ────────────── ────────"
    
    local count=0
    while read -r line; do
        if [[ "$line" =~ ^###[[:space:]]+([^[:space:]]+)[[:space:]]+(.+)$ ]]; then
            count=$((count + 1))
            local user="${BASH_REMATCH[1]}"
            local exp="${BASH_REMATCH[2]}"
            
            if [ $(date -d "$exp" +%s 2>/dev/null) -lt $(date +%s) ]; then
                local status="${RED}Expired${NC}"
            else
                local status="${GREEN}Active${NC}"
            fi
            
            printf "  %-4s %-18s %-14s %b\n" "$count" "$user" "$exp" "$status"
        fi
    done < "$db_file"
    
    echo ""
    echo -e "  ${CYAN}Total: $count users${NC}"
}

# ============================================================
# Renew Xray User
# ============================================================
renew_xray_user() {
    local proto=$1
    
    clear
    echo -e "              ${GREEN}RENEW ${proto^^} ACCOUNT${NC}"
    echo ""
    
    read -p "Username: " user
    read -p "Additional days: " days
    
    local db_file="/etc/xray/${proto}.db"
    local exp=$(date -d "+$days days" +"%Y-%m-%d")
    
    if grep -q "^### ${user} " "$db_file" 2>/dev/null; then
        sed -i "s/^### ${user} .*/### ${user} ${exp}/" "$db_file"
        show_success "User '$user' renewed until $exp"
    else
        show_error "User '$user' not found"
    fi
}

# ============================================================
# Check Xray Logins
# ============================================================
check_xray_logins() {
    local proto=$1
    
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}${proto^^} ONLINE USERS${NC}                            ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ -f /var/log/xray/access.log ]; then
        echo -e "${YELLOW}Recent connections:${NC}"
        grep -i "${proto}" /var/log/xray/access.log 2>/dev/null | tail -20 || echo "No recent connections"
    else
        echo -e "${YELLOW}No access log found${NC}"
    fi
}

# ============================================================
# Delete Xray User
# ============================================================
delete_xray_user() {
    local proto=$1
    
    clear
    echo -e "              ${RED}DELETE ${proto^^} ACCOUNT${NC}"
    echo ""
    
    # Show current users
    list_xray_users "$proto" | head -20
    echo ""
    
    read -p "Username to delete: " user
    
    local db_file="/etc/xray/${proto}.db"
    
    if grep -q "^### ${user} " "$db_file" 2>/dev/null; then
        sed -i "/^### ${user} /d" "$db_file"
        systemctl restart xray 2>/dev/null
        show_success "User '$user' deleted"
    else
        show_error "User '$user' not found"
    fi
}

# ============================================================
# Main
# ============================================================
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        list)
            list_xray_users "$2"
            ;;
        renew)
            renew_xray_user "$2"
            ;;
        check)
            check_xray_logins "$2"
            ;;
        delete|del)
            delete_xray_user "$2"
            ;;
        *)
            echo "Xray User Management"
            echo ""
            echo "Usage: $0 {list|renew|check|delete} <vmess|vless|trojan>"
            ;;
    esac
fi
