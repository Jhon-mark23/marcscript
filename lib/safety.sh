#!/bin/bash
# MarcScript - Safety Checks

source /usr/local/marcscript/lib/common.sh

safety_check() {
    log_info "Running safety checks..."
    
    check_root
    
    # Check SSH
    if ! systemctl is-active --quiet ssh; then
        systemctl start ssh
        sleep 2
    fi
    
    # Check required commands
    for cmd in curl wget lsof ss systemctl; do
        if ! command -v "$cmd" &>/dev/null; then
            apt install -y $cmd >/dev/null 2>&1
        fi
    done
    
    # Backup creation
    mkdir -p "$BACKUP_DIR"
    
    # Backup existing configs
    [ -f /etc/ssh/sshd_config ] && cp /etc/ssh/sshd_config "$BACKUP_DIR/"
    [ -f /etc/stunnel/stunnel.conf ] && cp /etc/stunnel/stunnel.conf "$BACKUP_DIR/"
    [ -f /etc/squid/squid.conf ] && cp /etc/squid/squid.conf "$BACKUP_DIR/"
    [ -f /etc/xray/config.json ] && cp /etc/xray/config.json "$BACKUP_DIR/"
    
    log_success "Safety checks completed"
}

rollback_on_error() {
    log_error "Installation failed! Rolling back..."
    if [ -f "$BACKUP_DIR/sshd_config" ]; then
        cp "$BACKUP_DIR/sshd_config" /etc/ssh/
        systemctl restart ssh
    fi
    exit 1
}
