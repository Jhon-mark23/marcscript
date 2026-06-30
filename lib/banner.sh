#!/bin/bash
# ============================================================
# MARCSCRIPT - Banner & Display Functions
# License: MIT
# ============================================================

source /usr/local/marcscript/lib/common.sh 2>/dev/null || source $(dirname "$0")/common.sh

# ============================================================
# Show Main Banner
# ============================================================
show_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}   ███╗   ███╗ █████╗ ██████╗  ██████╗███████╗${NC}            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}   ████╗ ████║██╔══██╗██╔══██╗██╔════╝██╔════╝${NC}            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}   ██╔████╔██║███████║██████╔╝██║     ███████╗${NC}            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}   ██║╚██╔╝██║██╔══██║██╔══██╗██║     ╚════██║${NC}            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}   ██║ ╚═╝ ██║██║  ██║██║  ██║╚██████╗███████║${NC}            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝${NC}            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ${YELLOW}        🚀 SSH • Xray • WebSocket • SSL • Proxy${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# ============================================================
# Show Small Banner
# ============================================================
show_small_banner() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}🚀 MARCSCRIPT VPN${NC}   |   ${YELLOW}SSH • Xray • WS • SSL${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
}

# ============================================================
# Show Section Header
# ============================================================
section_header() {
    local title="$1"
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${GREEN}${title}${NC}              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================================
# Show Info Box
# ============================================================
show_info() {
    local title="$1"
    local message="$2"
    
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│${NC} ${YELLOW}${title}${NC}"
    echo -e "${BLUE}├─────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BLUE}│${NC} ${message}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────┘${NC}"
}

# ============================================================
# Show Success Message
# ============================================================
show_success() {
    local message="$1"
    echo -e "${GREEN}✅ ${message}${NC}"
}

# ============================================================
# Show Error Message
# ============================================================
show_error() {
    local message="$1"
    echo -e "${RED}❌ ${message}${NC}"
}

# ============================================================
# Show Warning Message
# ============================================================
show_warning() {
    local message="$1"
    echo -e "${YELLOW}⚠️  ${message}${NC}"
}

# ============================================================
# Show Loading Animation
# ============================================================
show_loading() {
    local message="$1"
    local pid=$!
    local delay=0.1
    local spin='-\|/'
    
    while kill -0 $pid 2>/dev/null; do
        local temp=${spin#?}
        printf " [%c] %s  " "$spin" "$message"
        local spin=$temp${spin%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "    \r"
}

# ============================================================
# Show Progress Bar
# ============================================================
show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${GREEN}["
    for ((i=0; i<filled; i++)); do printf "="; done
    for ((i=0; i<empty; i++)); do printf " "; done
    printf "]${NC} %d%%" $percent
}

# ============================================================
# Show Table
# ============================================================
show_table() {
    local header="$1"
    shift
    local rows=("$@")
    
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${YELLOW}${header}${NC}"
    echo -e "${CYAN}├─────────────────────────────────────────────────────────────┤${NC}"
    for row in "${rows[@]}"; do
        echo -e "${CYAN}│${NC} ${row}"
    done
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
}

# ============================================================
# Show Completion Screen
# ============================================================
show_completion() {
    clear
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}         ${GREEN}✅ INSTALLATION COMPLETE!${NC}                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}         ${YELLOW}Type 'menu' to access control panel${NC}                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    show_system_info
}

# ============================================================
# Show System Info
# ============================================================
show_system_info() {
    local ip=$(wget -qO- ipv4.icanhazip.com 2>/dev/null || curl -s ifconfig.me)
    local domain=$(cat /etc/xray/domain 2>/dev/null || echo "$ip")
    
    echo -e " ${CYAN}╔══════════════╦════════════════════════════════╗${NC}"
    echo -e " ${CYAN}║${NC} IP           ${CYAN}║${NC} ${GREEN}${ip}${NC} ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} Domain       ${CYAN}║${NC} ${GREEN}${domain}${NC} ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} OS           ${CYAN}║${NC} $(lsb_release -ds 2>/dev/null || echo 'Linux') ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} RAM          ${CYAN}║${NC} $(free -h | awk '/Mem/{print $2}') ${CYAN}║${NC}"
    echo -e " ${CYAN}║${NC} CPU          ${CYAN}║${NC} $(nproc) cores ${CYAN}║${NC}"
    echo -e " ${CYAN}╚══════════════╩════════════════════════════════╝${NC}"
    echo ""
}

# ============================================================
# Countdown Timer
# ============================================================
countdown() {
    local seconds=$1
    local message="${2:-Waiting...}"
    
    for ((i=seconds; i>0; i--)); do
        printf "\r${YELLOW}⏳ %s %d seconds...${NC}" "$message" "$i"
        sleep 1
    done
    printf "\r${GREEN}✅ Done!                    ${NC}\n"
}
