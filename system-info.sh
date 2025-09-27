#!/data/data/com.termux/files/usr/bin/bash
# System Information Display Script

echo "📱 TERMUX SYSTEM INFORMATION"
echo "============================"

# Device Information
echo ""
echo "🔧 DEVICE INFO:"
echo "---------------"
echo "Device Model: $(getprop ro.product.model 2>/dev/null || echo 'Unknown')"
echo "Android Version: $(getprop ro.build.version.release 2>/dev/null || echo 'Unknown')"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"

# Termux Information
echo ""
echo "📦 TERMUX INFO:"
echo "---------------"
echo "Termux Version: $(termux-info | grep 'Termux version' | cut -d':' -f2 | xargs || echo 'Unknown')"
echo "Prefix Path: $PREFIX"
echo "Home Path: $HOME"

# System Resources
echo ""
echo "💾 SYSTEM RESOURCES:"
echo "--------------------"

# Memory Information
if command -v free >/dev/null 2>&1; then
    echo "Memory Usage:"
    free -h | grep -E "(Mem|Swap)"
else
    echo "Memory info: free command not available"
fi

# Disk Usage
echo ""
echo "Disk Usage:"
df -h $PREFIX 2>/dev/null || echo "Disk info: df command failed"

# CPU Information  
echo ""
echo "🖥️ CPU INFO:"
echo "-------------"
if [ -f /proc/cpuinfo ]; then
    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
    cpu_cores=$(grep "processor" /proc/cpuinfo | wc -l)
    echo "CPU Model: ${cpu_model:-Unknown}"
    echo "CPU Cores: $cpu_cores"
else
    echo "CPU info: /proc/cpuinfo not accessible"
fi

# Network Information
echo ""
echo "🌐 NETWORK INFO:"
echo "----------------"
if command -v ip >/dev/null 2>&1; then
    ip_addr=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' | head -1)
    echo "Local IP: ${ip_addr:-Not connected}"
else
    echo "Network info: ip command not available"
fi

# Check internet connectivity
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "Internet: Connected ✅"
else
    echo "Internet: Not connected ❌"
fi

# Storage Information
echo ""
echo "📁 STORAGE INFO:"
echo "----------------"
if [ -d /storage/emulated/0 ]; then
    echo "Internal Storage: Available"
    du -sh /storage/emulated/0 2>/dev/null | cut -f1 | xargs -I {} echo "Usage: {}"
else
    echo "Internal Storage: Not accessible (run termux-setup-storage)"
fi

# Package Information
echo ""
echo "📦 INSTALLED PACKAGES:"
echo "----------------------"
pkg_count=$(pkg list-installed 2>/dev/null | wc -l)
echo "Total packages: $pkg_count"

# Show top 10 largest packages
echo ""
echo "Largest packages:"
pkg list-installed 2>/dev/null | head -10

# Uptime
echo ""
echo "⏰ SYSTEM UPTIME:"
echo "-----------------"
if [ -f /proc/uptime ]; then
    uptime_seconds=$(cat /proc/uptime | cut -d' ' -f1 | cut -d'.' -f1)
    uptime_days=$((uptime_seconds / 86400))
    uptime_hours=$(((uptime_seconds % 86400) / 3600))
    uptime_minutes=$(((uptime_seconds % 3600) / 60))
    echo "Uptime: ${uptime_days}d ${uptime_hours}h ${uptime_minutes}m"
else
    echo "Uptime: Unknown"
fi

echo ""
echo "✅ System information collection complete!"