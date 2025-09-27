#!/data/data/com.termux/files/usr/bin/bash
# Network Scanner - Scan local network for devices

echo "🌐 NETWORK SCANNER"
echo "=================="

# Check if nmap is installed, if not use ping
if ! command -v nmap >/dev/null 2>&1; then
    echo "⚠️ nmap not found. Installing for better scanning..."
    read -p "Install nmap? (y/n): " install_nmap
    if [[ $install_nmap =~ ^[Yy]$ ]]; then
        pkg install -y nmap
    else
        echo "Using basic ping scan instead..."
        USE_PING=true
    fi
fi

# Get network interface information
echo ""
echo "🔍 Detecting network information..."

# Get local IP and network
if command -v ip >/dev/null 2>&1; then
    LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    INTERFACE=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'dev \K\S+' | head -1)
else
    LOCAL_IP=$(hostname -I | cut -d' ' -f1 2>/dev/null)
fi

if [ -z "$LOCAL_IP" ]; then
    echo "❌ Could not determine local IP address"
    echo "Make sure you're connected to WiFi"
    exit 1
fi

# Calculate network range
NETWORK=$(echo $LOCAL_IP | cut -d. -f1-3)
echo "📍 Local IP: $LOCAL_IP"
echo "🌐 Scanning network: $NETWORK.0/24"

# Function to scan with nmap
scan_with_nmap() {
    echo ""
    echo "🚀 Starting nmap scan..."
    echo "This may take a few minutes..."
    
    nmap -sn "$NETWORK.0/24" | grep -E "Nmap scan report|MAC Address" | while read line; do
        if echo "$line" | grep -q "Nmap scan report"; then
            ip=$(echo "$line" | grep -oP '\d+\.\d+\.\d+\.\d+')
            hostname=$(echo "$line" | sed 's/.*for \(.*\) (.*/\1/' | sed 's/.*(\(.*\))/\1/')
            echo "📱 Found: $ip ($hostname)"
        elif echo "$line" | grep -q "MAC Address"; then
            mac=$(echo "$line" | grep -oP '([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})')
            vendor=$(echo "$line" | sed 's/.*(\(.*\))/\1/')
            echo "   MAC: $mac ($vendor)"
        fi
    done
}

# Function to scan with ping
scan_with_ping() {
    echo ""
    echo "🚀 Starting ping scan..."
    echo "Scanning $NETWORK.1-254..."
    
    active_hosts=()
    
    for i in {1..254}; do
        ip="$NETWORK.$i"
        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            active_hosts+=("$ip")
            echo "📱 Found: $ip"
        fi
        
        # Progress indicator
        if (( i % 50 == 0 )); then
            echo "   Scanned: $i/254"
        fi
    done
    
    echo ""
    echo "📊 Scan complete! Found ${#active_hosts[@]} active hosts"
}

# Port scanning function
port_scan() {
    local target_ip=$1
    echo ""
    echo "🔍 Scanning common ports on $target_ip..."
    
    common_ports=(22 23 53 80 135 139 443 445 993 995 1723 3389 5900 8080)
    
    for port in "${common_ports[@]}"; do
        if timeout 3 bash -c "</dev/tcp/$target_ip/$port" 2>/dev/null; then
            case $port in
                22) service="SSH" ;;
                23) service="Telnet" ;;
                53) service="DNS" ;;
                80) service="HTTP" ;;
                135) service="RPC" ;;
                139) service="NetBIOS" ;;
                443) service="HTTPS" ;;
                445) service="SMB" ;;
                993) service="IMAPS" ;;
                995) service="POP3S" ;;
                1723) service="PPTP" ;;
                3389) service="RDP" ;;
                5900) service="VNC" ;;
                8080) service="HTTP-Alt" ;;
                *) service="Unknown" ;;
            esac
            echo "   ✅ Port $port ($service) - OPEN"
        fi
    done
}

# Main scanning
if [ "$USE_PING" = "true" ]; then
    scan_with_ping
else
    scan_with_nmap
fi

# Additional scans
echo ""
read -p "🔍 Perform port scan on specific host? (y/n): " do_port_scan
if [[ $do_port_scan =~ ^[Yy]$ ]]; then
    read -p "Enter IP address to scan: " target_ip
    if [[ $target_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        port_scan "$target_ip"
    else
        echo "❌ Invalid IP address format"
    fi
fi

# Network information
echo ""
echo "📊 NETWORK SUMMARY"
echo "=================="
echo "🏠 Router/Gateway: $(ip route | grep default | grep -oP 'via \K\S+' 2>/dev/null || echo 'Unknown')"
echo "🌐 DNS Servers: $(grep nameserver /etc/resolv.conf 2>/dev/null | cut -d' ' -f2 | tr '\n' ' ' || echo 'Unknown')"

# WiFi information (if available)
if command -v termux-wifi-connectioninfo >/dev/null 2>&1; then
    echo ""
    echo "📶 WiFi Information:"
    termux-wifi-connectioninfo 2>/dev/null | jq -r '
        "SSID: " + (.ssid // "Unknown"),
        "Signal: " + (.rssi // "Unknown") + " dBm",
        "Speed: " + (.link_speed // "Unknown") + " Mbps"
    ' 2>/dev/null || echo "WiFi info not available"
fi

echo ""
echo "✅ Network scan completed!"
echo ""
echo "💡 Tips:"
echo "   - Install 'nmap' for more detailed scans: pkg install nmap"
echo "   - Use 'termux-api' for WiFi information: pkg install termux-api"
echo "   - Run with sudo for more detailed host discovery"