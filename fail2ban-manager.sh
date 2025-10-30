#!/bin/bash

# Fail2Ban Management Script for Yelp API
# This script helps manage fail2ban security monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_fail2ban_status() {
    print_status "Checking fail2ban status..."
    
    if systemctl is-active --quiet fail2ban; then
        print_status "✓ Fail2ban is running"
        
        # Show active jails
        print_info "Active jails:"
        sudo fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr ',' '\n' | sed 's/^[ \t]*/  - /'
        
        # Show current bans
        local total_banned=0
        for jail in $(sudo fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr ',' ' '); do
            local banned=$(sudo fail2ban-client status "$jail" | grep "Currently banned" | cut -d: -f2 | tr -d ' ')
            total_banned=$((total_banned + banned))
        done
        
        if [ $total_banned -gt 0 ]; then
            print_warning "Currently banned IPs: $total_banned"
        else
            print_status "✓ No IPs currently banned"
        fi
        
    else
        print_error "✗ Fail2ban is not running"
        return 1
    fi
}

show_jail_status() {
    local jail="$1"
    
    if [ -z "$jail" ]; then
        print_info "Available jails:"
        sudo fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr ',' '\n' | sed 's/^[ \t]*/  - /'
        return
    fi
    
    print_status "Status for jail: $jail"
    sudo fail2ban-client status "$jail"
}

show_banned_ips() {
    print_status "Currently banned IPs across all jails:"
    
    local found_bans=false
    for jail in $(sudo fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr ',' ' '); do
        local banned_ips=$(sudo fail2ban-client status "$jail" | grep "Banned IP list" | cut -d: -f2)
        if [ -n "$banned_ips" ] && [ "$banned_ips" != " " ]; then
            print_info "Jail: $jail"
            echo "  IPs: $banned_ips"
            found_bans=true
        fi
    done
    
    if [ "$found_bans" = false ]; then
        print_status "✓ No IPs currently banned"
    fi
}

unban_ip() {
    local ip="$1"
    
    if [ -z "$ip" ]; then
        print_error "IP address required"
        return 1
    fi
    
    print_status "Unbanning IP: $ip"
    
    local unbanned=false
    for jail in $(sudo fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr ',' ' '); do
        if sudo fail2ban-client status "$jail" | grep -q "$ip"; then
            sudo fail2ban-client unban "$ip"
            print_status "✓ Unbanned $ip from jail: $jail"
            unbanned=true
        fi
    done
    
    if [ "$unbanned" = false ]; then
        print_warning "IP $ip was not found in any jail"
    fi
}

ban_ip() {
    local ip="$1"
    local jail="${2:-nginx-dos}"
    
    if [ -z "$ip" ]; then
        print_error "IP address required"
        return 1
    fi
    
    print_status "Manually banning IP: $ip in jail: $jail"
    sudo fail2ban-client set "$jail" banip "$ip"
    print_status "✓ Banned $ip"
}

show_logs() {
    local lines="${1:-50}"
    
    print_status "Recent fail2ban activity (last $lines lines):"
    sudo tail -n "$lines" /var/log/fail2ban.log | grep -E "(NOTICE|WARNING|ERROR)" | tail -20
}

show_attack_summary() {
    print_status "Attack summary from fail2ban logs:"
    
    print_info "Top attacking IPs (last 24 hours):"
    sudo grep "$(date --date='1 day ago' '+%Y-%m-%d')" /var/log/fail2ban.log 2>/dev/null | \
        grep "Ban" | awk '{print $8}' | sort | uniq -c | sort -nr | head -10 | \
        while read count ip; do
            echo "  $ip: $count attacks"
        done
    
    print_info "Attack types:"
    sudo grep "$(date '+%Y-%m-%d')" /var/log/fail2ban.log 2>/dev/null | \
        grep "Ban" | awk '{print $6}' | sort | uniq -c | sort -nr | \
        while read count jail; do
            jail=$(echo $jail | sed 's/\[//' | sed 's/\]//')
            echo "  $jail: $count bans today"
        done
}

test_filters() {
    print_status "Testing fail2ban filters..."
    
    # Test log files exist
    local error=false
    
    if [ ! -f /var/log/nginx/access.log ]; then
        print_error "Nginx access log not found: /var/log/nginx/access.log"
        error=true
    fi
    
    if [ ! -f /var/log/nginx/error.log ]; then
        print_error "Nginx error log not found: /var/log/nginx/error.log"
        error=true
    fi
    
    if [ ! -f /var/log/auth.log ]; then
        print_error "Auth log not found: /var/log/auth.log"
        error=true
    fi
    
    if [ "$error" = true ]; then
        print_warning "Some log files are missing. This may affect fail2ban functionality."
        return 1
    fi
    
    # Test filter syntax
    print_info "Testing custom filters:"
    for filter in fastapi-auth nginx-dos nginx-botsearch; do
        if sudo fail2ban-regex /dev/null /etc/fail2ban/filter.d/$filter.conf &>/dev/null; then
            print_status "✓ Filter $filter: OK"
        else
            print_error "✗ Filter $filter: FAILED"
        fi
    done
}

whitelist_ip() {
    local ip="$1"
    
    if [ -z "$ip" ]; then
        print_error "IP address required"
        return 1
    fi
    
    print_status "Adding $ip to fail2ban whitelist..."
    
    # Add to jail.local ignoreip
    if grep -q "ignoreip.*$ip" /etc/fail2ban/jail.local; then
        print_warning "IP $ip is already whitelisted"
    else
        sudo sed -i "/ignoreip.*=/s/$/ $ip/" /etc/fail2ban/jail.local
        print_status "Added $ip to whitelist"
        print_warning "Restart fail2ban to apply: sudo systemctl restart fail2ban"
    fi
}

show_config() {
    print_status "Current fail2ban configuration:"
    print_info "Jail configuration: /etc/fail2ban/jail.local"
    echo "---"
    sudo cat /etc/fail2ban/jail.local | head -20
    echo "..."
    
    print_info "Active jails and their settings:"
    for jail in $(sudo fail2ban-client status | grep "Jail list" | cut -d: -f2 | tr ',' ' '); do
        echo
        print_info "Jail: $jail"
        sudo fail2ban-client get "$jail" bantime findtime maxretry 2>/dev/null | \
            paste - - - | awk '{print "  Ban time: " $1 "s, Find time: " $2 "s, Max retry: " $3}'
    done
}

monitor_live() {
    print_status "Live monitoring fail2ban activity (Ctrl+C to stop)..."
    sudo tail -f /var/log/fail2ban.log | while read line; do
        if echo "$line" | grep -q "NOTICE"; then
            echo -e "${GREEN}$line${NC}"
        elif echo "$line" | grep -q "WARNING"; then
            echo -e "${YELLOW}$line${NC}"
        elif echo "$line" | grep -q "ERROR"; then
            echo -e "${RED}$line${NC}"
        else
            echo "$line"
        fi
    done
}

case "${1:-status}" in
    "status")
        check_fail2ban_status
        ;;
    "jail")
        show_jail_status "$2"
        ;;
    "banned")
        show_banned_ips
        ;;
    "unban")
        unban_ip "$2"
        ;;
    "ban")
        ban_ip "$2" "$3"
        ;;
    "logs")
        show_logs "$2"
        ;;
    "attacks")
        show_attack_summary
        ;;
    "test")
        test_filters
        ;;
    "whitelist")
        whitelist_ip "$2"
        ;;
    "config")
        show_config
        ;;
    "monitor")
        monitor_live
        ;;
    *)
        echo "Fail2Ban Management for Yelp API"
        echo
        echo "Usage: $0 <command> [options]"
        echo
        echo "Commands:"
        echo "  status              - Show fail2ban status and active jails"
        echo "  jail [name]         - Show specific jail status (or list all)"
        echo "  banned              - Show currently banned IPs"
        echo "  unban <ip>          - Unban an IP address"
        echo "  ban <ip> [jail]     - Manually ban an IP (default: nginx-dos)"
        echo "  logs [lines]        - Show recent fail2ban logs (default: 50)"
        echo "  attacks             - Show attack summary and statistics"
        echo "  test                - Test filter configurations"
        echo "  whitelist <ip>      - Add IP to permanent whitelist"
        echo "  config              - Show current configuration"
        echo "  monitor             - Live monitoring of fail2ban activity"
        echo
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 jail sshd"
        echo "  $0 unban 192.168.1.100"
        echo "  $0 whitelist 192.168.1.100"
        echo "  $0 attacks"
        exit 1
        ;;
esac