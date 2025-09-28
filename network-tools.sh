#!/data/data/com.termux/files/usr/bin/bash

# ========================================
# Termux Network Tools Script
# ========================================
# Description: Advanced networking utilities
# Author: Termux Scripts Collection
# Version: 1.0
# ========================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
NETWORK_TOOLS_DIR="$HOME/.network-tools"
LOG_FILE="$NETWORK_TOOLS_DIR/network.log"
SPEED_TEST_SERVERS="8.8.8.8 1.1.1.1 208.67.222.222"

# Functions
print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                   TERMUX NETWORK TOOLS                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
}

print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

success_message() {
    print_colored "$GREEN" "✅ $1"
}

error_message() {
    print_colored "$RED" "❌ Error: $1"
}

warning_message() {
    print_colored "$YELLOW" "⚠️  Warning: $1"
}

info_message() {
    print_colored "$BLUE" "ℹ️  $1"
}

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

setup_network_tools() {
    print_colored "$BLUE" "🔧 Setting up network tools..."
    
    mkdir -p "$NETWORK_TOOLS_DIR"
    
    # Install required packages
    local packages=(
        "nmap"
        "netcat-openbsd"
        "curl"
        "wget"
        "openssh"
        "net-tools"
        "iproute2"
        "dnsutils"
        "traceroute"
    )
    
    for pkg in "${packages[@]}"; do
        if ! pkg list-installed 2>/dev/null | grep -q "^$pkg/"; then
            print_colored "$YELLOW" "Installing $pkg..."
            pkg install -y "$pkg" 2>/dev/null
        else
            print_colored "$GREEN" "$pkg already installed"
        fi
    done
    
    success_message "Network tools setup complete!"
}

get_network_info() {
    print_colored "$WHITE" "🌐 Network Information"
    echo "────────────────────────────────────────────────────────────"
    
    # Get network interfaces
    print_colored "$CYAN" "Network Interfaces:"
    if command -v ip &> /dev/null; then
        ip addr show | grep -E "^[0-9]+:" | while read -r line; do
            local interface=$(echo "$line" | cut -d: -f2 | tr -d ' ')
            local status=$(echo "$line" | grep -o "state [A-Z]*" | cut -d' ' -f2)
            
            if [[ "$status" == "UP" ]]; then
                echo -e "  ${GREEN}$interface${NC} (${status})"
            else
                echo -e "  ${RED}$interface${NC} (${status})"
            fi
        done
    else
        ifconfig 2>/dev/null | grep -E "^[a-z]" | while read -r line; do
            echo "  $line"
        done
    fi
    
    echo
    
    # Get IP addresses
    print_colored "$CYAN" "IP Addresses:"
    
    # Internal IP
    local internal_ip=$(hostname -I 2>/dev/null | awk '{print $1}' || ip route get 1.1.1.1 2>/dev/null | grep -Po 'src \K\S+')
    if [ -n "$internal_ip" ]; then
        echo -e "  ${GREEN}Internal IP:${NC} $internal_ip"
    fi
    
    # External IP
    print_colored "$YELLOW" "Getting external IP..."
    local external_ip=$(curl -s -m 5 ifconfig.me 2>/dev/null || curl -s -m 5 ipinfo.io/ip 2>/dev/null || echo "Unable to get external IP")
    echo -e "  ${GREEN}External IP:${NC} $external_ip"
    
    echo
    
    # DNS servers
    print_colored "$CYAN" "DNS Servers:"
    if [ -f "/etc/resolv.conf" ]; then
        grep "nameserver" /etc/resolv.conf | while read -r line; do
            local dns=$(echo "$line" | awk '{print $2}')
            echo -e "  ${GREEN}DNS:${NC} $dns"
        done
    fi
    
    echo
    
    # Gateway
    print_colored "$CYAN" "Default Gateway:"
    local gateway=$(ip route | grep default | awk '{print $3}' 2>/dev/null || route -n | grep "^0.0.0.0" | awk '{print $2}' 2>/dev/null)
    if [ -n "$gateway" ]; then
        echo -e "  ${GREEN}Gateway:${NC} $gateway"
    fi
}

wifi_analyzer() {
    print_colored "$BLUE" "📶 WiFi Analyzer"
    echo
    
    if ! command -v termux-wifi-scaninfo &> /dev/null; then
        error_message "termux-api not installed. Install with: pkg install termux-api"
        return 1
    fi
    
    print_colored "$YELLOW" "Scanning for WiFi networks..."
    
    # Get WiFi scan results
    local wifi_json=$(termux-wifi-scaninfo 2>/dev/null)
    
    if [ $? -eq 0 ] && [ -n "$wifi_json" ]; then
        echo -e "${WHITE}Available Networks:${NC}"
        echo "────────────────────────────────────────────────────────────"
        printf "%-30s %-8s %-10s %-15s\n" "SSID" "Signal" "Frequency" "Security"
        echo "────────────────────────────────────────────────────────────"
        
        echo "$wifi_json" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for network in sorted(data, key=lambda x: x.get('rssi', -100), reverse=True):
        ssid = network.get('ssid', 'Hidden')[:29]
        rssi = network.get('rssi', 'N/A')
        freq = network.get('frequency', 'N/A')
        caps = network.get('capabilities', '')
        
        # Determine security
        if 'WPA' in caps:
            security = 'WPA/WPA2'
        elif 'WEP' in caps:
            security = 'WEP'
        elif caps:
            security = 'Other'
        else:
            security = 'Open'
        
        # Color code signal strength
        if isinstance(rssi, int):
            if rssi > -50:
                color = '\033[0;32m'  # Green
            elif rssi > -70:
                color = '\033[1;33m'  # Yellow
            else:
                color = '\033[0;31m'  # Red
            signal = f'{color}{rssi} dBm\033[0m'
        else:
            signal = str(rssi)
        
        print(f'{ssid:<30} {signal:<15} {freq:<10} {security:<15}')
except:
    print('Error parsing WiFi data')
"
    else
        error_message "Failed to scan WiFi networks"
    fi
}

port_scanner() {
    print_colored "$BLUE" "🔍 Port Scanner"
    echo
    
    echo -n "Enter target IP/hostname: "
    read -r target
    
    if [ -z "$target" ]; then
        error_message "Target cannot be empty"
        return 1
    fi
    
    echo -n "Scan type (1=Quick, 2=Common, 3=Full, 4=Custom): "
    read -r scan_type
    
    local ports=""
    case $scan_type in
        1)
            ports="21,22,23,25,53,80,110,443,993,995"
            print_colored "$CYAN" "Quick scan of common ports..."
            ;;
        2)
            ports="1-1000"
            print_colored "$CYAN" "Scanning ports 1-1000..."
            ;;
        3)
            ports="1-65535"
            print_colored "$CYAN" "Full port scan (this may take a while)..."
            warning_message "Full scan can be slow and may be detected"
            ;;
        4)
            echo -n "Enter port range (e.g., 80,443 or 1-1000): "
            read -r ports
            print_colored "$CYAN" "Custom port scan..."
            ;;
        *)
            error_message "Invalid scan type"
            return 1
            ;;
    esac
    
    if [ -z "$ports" ]; then
        error_message "No ports specified"
        return 1
    fi
    
    # Log scan
    log_message "Port scan started: $target ports $ports"
    
    print_colored "$YELLOW" "Scanning $target..."
    echo
    
    if command -v nmap &> /dev/null; then
        # Use nmap if available
        nmap -p "$ports" "$target" 2>/dev/null | grep -E "(open|closed|filtered)"
    else
        # Fallback to netcat
        print_colored "$YELLOW" "Using netcat (limited functionality)..."
        
        IFS=',' read -ra PORT_ARRAY <<< "$ports"
        for port_range in "${PORT_ARRAY[@]}"; do
            if [[ "$port_range" == *"-"* ]]; then
                local start_port=$(echo "$port_range" | cut -d'-' -f1)
                local end_port=$(echo "$port_range" | cut -d'-' -f2)
                
                for ((port=start_port; port<=end_port; port++)); do
                    if timeout 1 nc -z "$target" "$port" 2>/dev/null; then
                        echo -e "${GREEN}Port $port: Open${NC}"
                    fi
                done
            else
                if timeout 1 nc -z "$target" "$port_range" 2>/dev/null; then
                    echo -e "${GREEN}Port $port_range: Open${NC}"
                fi
            fi
        done
    fi
    
    success_message "Port scan completed"
    log_message "Port scan completed: $target"
}

network_speed_test() {
    print_colored "$BLUE" "🚀 Network Speed Test"
    echo
    
    # Test download speed
    print_colored "$CYAN" "Testing download speed..."
    
    local test_file_url="http://speedtest.ftp.otenet.gr/files/test1Mb.db"
    local start_time=$(date +%s.%N)
    
    if curl -o /dev/null -s -w "%{speed_download}" "$test_file_url" > /tmp/speed_test 2>/dev/null; then
        local end_time=$(date +%s.%N)
        local speed_bytes=$(cat /tmp/speed_test)
        local speed_mbps=$(echo "scale=2; $speed_bytes * 8 / 1000000" | bc)
        
        echo -e "${GREEN}Download Speed: ${speed_mbps} Mbps${NC}"
        rm -f /tmp/speed_test
    else
        warning_message "Download speed test failed"
    fi
    
    # Test latency to multiple servers
    print_colored "$CYAN" "Testing latency..."
    echo
    
    for server in $SPEED_TEST_SERVERS; do
        print_colored "$YELLOW" "Testing $server..."
        
        if command -v ping &> /dev/null; then
            local ping_result=$(ping -c 4 "$server" 2>/dev/null | tail -1 | awk -F '/' '{print $5}')
            if [ -n "$ping_result" ]; then
                echo -e "${GREEN}Average latency: ${ping_result} ms${NC}"
            else
                echo -e "${RED}Failed to ping $server${NC}"
            fi
        else
            warning_message "Ping command not available"
        fi
        echo
    done
}

connectivity_checker() {
    print_colored "$BLUE" "🔗 Connectivity Checker"
    echo
    
    local test_sites=(
        "8.8.8.8:53"
        "google.com:80"
        "github.com:443"
        "cloudflare.com:80"
    )
    
    print_colored "$CYAN" "Testing connectivity..."
    echo
    
    for site in "${test_sites[@]}"; do
        local host=$(echo "$site" | cut -d: -f1)
        local port=$(echo "$site" | cut -d: -f2)
        
        print_colored "$YELLOW" "Testing $host:$port..."
        
        if timeout 3 nc -z "$host" "$port" 2>/dev/null; then
            echo -e "${GREEN}✅ $host:$port - Connected${NC}"
        else
            echo -e "${RED}❌ $host:$port - Failed${NC}"
        fi
    done
    
    echo
    
    # DNS resolution test
    print_colored "$CYAN" "Testing DNS resolution..."
    
    local test_domains=("google.com" "github.com" "stackoverflow.com")
    
    for domain in "${test_domains[@]}"; do
        if nslookup "$domain" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ DNS resolve $domain - OK${NC}"
        else
            echo -e "${RED}❌ DNS resolve $domain - Failed${NC}"
        fi
    done
}

network_monitor() {
    print_colored "$BLUE" "📊 Network Monitor"
    echo
    
    print_colored "$CYAN" "Network traffic monitoring (Press Ctrl+C to stop)..."
    echo
    
    # Get initial values
    local interface="wlan0"
    if [ ! -f "/sys/class/net/$interface/statistics/rx_bytes" ]; then
        # Try to find active interface
        interface=$(ip route | grep default | awk '{print $5}' | head -1)
    fi
    
    if [ -z "$interface" ] || [ ! -f "/sys/class/net/$interface/statistics/rx_bytes" ]; then
        error_message "No active network interface found"
        return 1
    fi
    
    print_colored "$GREEN" "Monitoring interface: $interface"
    echo
    
    local prev_rx=$(cat "/sys/class/net/$interface/statistics/rx_bytes")
    local prev_tx=$(cat "/sys/class/net/$interface/statistics/tx_bytes")
    local prev_time=$(date +%s)
    
    while true; do
        sleep 2
        
        local curr_rx=$(cat "/sys/class/net/$interface/statistics/rx_bytes")
        local curr_tx=$(cat "/sys/class/net/$interface/statistics/tx_bytes")
        local curr_time=$(date +%s)
        
        local rx_diff=$((curr_rx - prev_rx))
        local tx_diff=$((curr_tx - prev_tx))
        local time_diff=$((curr_time - prev_time))
        
        if [ $time_diff -gt 0 ]; then
            local rx_speed=$((rx_diff / time_diff))
            local tx_speed=$((tx_diff / time_diff))
            
            # Convert to human readable
            local rx_human=$(numfmt --to=iec-i --suffix=B/s $rx_speed 2>/dev/null || echo "${rx_speed} B/s")
            local tx_human=$(numfmt --to=iec-i --suffix=B/s $tx_speed 2>/dev/null || echo "${tx_speed} B/s")
            
            printf "\r${CYAN}RX: ${GREEN}%-15s${CYAN} TX: ${GREEN}%-15s${NC}" "$rx_human" "$tx_human"
        fi
        
        prev_rx=$curr_rx
        prev_tx=$curr_tx
        prev_time=$curr_time
    done
}

ssl_checker() {
    print_colored "$BLUE" "🔐 SSL Certificate Checker"
    echo
    
    echo -n "Enter hostname (e.g., google.com): "
    read -r hostname
    
    if [ -z "$hostname" ]; then
        error_message "Hostname cannot be empty"
        return 1
    fi
    
    echo -n "Enter port (default 443): "
    read -r port
    port=${port:-443}
    
    print_colored "$YELLOW" "Checking SSL certificate for $hostname:$port..."
    echo
    
    if command -v openssl &> /dev/null; then
        local cert_info=$(echo | openssl s_client -servername "$hostname" -connect "$hostname:$port" 2>/dev/null | openssl x509 -noout -text 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            # Extract certificate details
            local subject=$(echo "$cert_info" | grep "Subject:" | sed 's/.*Subject: //')
            local issuer=$(echo "$cert_info" | grep "Issuer:" | sed 's/.*Issuer: //')
            local not_before=$(echo "$cert_info" | grep "Not Before:" | sed 's/.*Not Before: //')
            local not_after=$(echo "$cert_info" | grep "Not After:" | sed 's/.*Not After: //')
            
            print_colored "$GREEN" "✅ SSL Certificate Information:"
            echo "────────────────────────────────────────────────────────────"
            echo -e "${CYAN}Subject:${NC}    $subject"
            echo -e "${CYAN}Issuer:${NC}     $issuer"
            echo -e "${CYAN}Valid From:${NC} $not_before"
            echo -e "${CYAN}Valid To:${NC}   $not_after"
            
            # Check expiration
            local exp_date=$(date -d "$not_after" +%s 2>/dev/null)
            local current_date=$(date +%s)
            
            if [ -n "$exp_date" ]; then
                local days_left=$(( (exp_date - current_date) / 86400 ))
                
                if [ $days_left -lt 0 ]; then
                    echo -e "${RED}⚠️  Certificate EXPIRED $((days_left * -1)) days ago${NC}"
                elif [ $days_left -lt 30 ]; then
                    echo -e "${YELLOW}⚠️  Certificate expires in $days_left days${NC}"
                else
                    echo -e "${GREEN}✅ Certificate valid for $days_left days${NC}"
                fi
            fi
        else
            error_message "Failed to retrieve certificate information"
        fi
    else
        error_message "OpenSSL not available"
    fi
}

show_help() {
    cat << EOF
Termux Network Tools v1.0

Usage: $0 [COMMAND]

COMMANDS:
    setup               Setup network tools
    info                Show network information
    wifi                WiFi analyzer
    scan                Port scanner
    speed               Network speed test
    check               Connectivity checker
    monitor             Network traffic monitor
    ssl                 SSL certificate checker
    
Examples:
    $0 setup            # Setup network tools
    $0 info             # Show network info
    $0 scan             # Port scanner
    $0 speed            # Speed test

EOF
}

main_menu() {
    print_banner
    
    echo -e "${WHITE}Network Tools Menu:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo -e "${CYAN}1.${NC} Setup Network Tools"
    echo -e "${CYAN}2.${NC} Network Information"
    echo -e "${CYAN}3.${NC} WiFi Analyzer"
    echo -e "${CYAN}4.${NC} Port Scanner"
    echo -e "${CYAN}5.${NC} Network Speed Test"
    echo -e "${CYAN}6.${NC} Connectivity Checker"
    echo -e "${CYAN}7.${NC} Network Monitor"
    echo -e "${CYAN}8.${NC} SSL Certificate Checker"
    echo -e "${CYAN}9.${NC} Exit"
    echo
    
    echo -n "Choose option (1-9): "
    read -r choice
    
    case $choice in
        1) setup_network_tools ;;
        2) get_network_info ;;
        3) wifi_analyzer ;;
        4) port_scanner ;;
        5) network_speed_test ;;
        6) connectivity_checker ;;
        7) network_monitor ;;
        8) ssl_checker ;;
        9) 
            print_colored "$YELLOW" "👋 Goodbye!"
            exit 0
            ;;
        *)
            error_message "Invalid option"
            ;;
    esac
    
    echo
    print_colored "$CYAN" "Press any key to continue..."
    read -n 1 -s
    main_menu
}

# Main script logic
case "${1:-}" in
    setup) setup_network_tools ;;
    info) get_network_info ;;
    wifi) wifi_analyzer ;;
    scan) port_scanner ;;
    speed) network_speed_test ;;
    check) connectivity_checker ;;
    monitor) network_monitor ;;
    ssl) ssl_checker ;;
    -h|--help) show_help ;;
    *) main_menu ;;
esac