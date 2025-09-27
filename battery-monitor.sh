#!/data/data/com.termux/files/usr/bin/bash
# Battery Monitor Script

echo "🔋 BATTERY MONITOR"
echo "=================="

# Check if termux-api is available
if ! command -v termux-battery-status >/dev/null 2>&1; then
    echo "📱 termux-api not found. Installing..."
    pkg install -y termux-api
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install termux-api"
        echo "💡 Try: pkg install termux-api"
        echo "🔔 Also install Termux:API app from Google Play Store"
        exit 1
    fi
    echo "✅ termux-api installed!"
    echo "🔔 Make sure to install Termux:API app from Google Play Store"
fi

# Function to get battery info
get_battery_info() {
    local battery_info
    battery_info=$(termux-battery-status 2>/dev/null)
    
    if [ $? -ne 0 ] || [ -z "$battery_info" ]; then
        echo "❌ Could not get battery information"
        echo "💡 Make sure Termux:API app is installed and permissions are granted"
        return 1
    fi
    
    echo "$battery_info"
}

# Function to parse and display battery info
display_battery_info() {
    local battery_json="$1"
    
    if [ -z "$battery_json" ]; then
        return 1
    fi
    
    # Parse JSON (basic parsing without jq dependency)
    local percentage health status temperature plugged
    
    percentage=$(echo "$battery_json" | grep -o '"percentage":[^,]*' | cut -d':' -f2 | tr -d ' ')
    health=$(echo "$battery_json" | grep -o '"health":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    status=$(echo "$battery_json" | grep -o '"status":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    temperature=$(echo "$battery_json" | grep -o '"temperature":[^,]*' | cut -d':' -f2 | tr -d ' ')
    plugged=$(echo "$battery_json" | grep -o '"plugged":"[^"]*"' | cut -d':' -f2 | tr -d '"')
    
    # Display information
    echo "🔋 BATTERY STATUS"
    echo "=================="
    
    # Battery percentage with visual indicator
    echo "⚡ Charge Level: $percentage%"
    
    # Create visual battery indicator
    local bars=$((percentage / 10))
    local battery_visual="["
    for ((i=1; i<=10; i++)); do
        if [ $i -le $bars ]; then
            battery_visual+="█"
        else
            battery_visual+="░"
        fi
    done
    battery_visual+="]"
    
    # Color coding based on percentage
    if [ "$percentage" -ge 80 ]; then
        echo "🟢 $battery_visual $percentage% - Excellent"
    elif [ "$percentage" -ge 60 ]; then
        echo "🟡 $battery_visual $percentage% - Good"
    elif [ "$percentage" -ge 40 ]; then
        echo "🟠 $battery_visual $percentage% - Fair"
    elif [ "$percentage" -ge 20 ]; then
        echo "🔴 $battery_visual $percentage% - Low"
    else
        echo "🚨 $battery_visual $percentage% - Critical"
    fi
    
    echo ""
    echo "📊 Detailed Information:"
    echo "Status: $status"
    echo "Health: $health"
    echo "Plugged: $plugged"
    
    # Temperature (convert from celsius * 10)
    if [ -n "$temperature" ] && [ "$temperature" != "null" ]; then
        local temp_celsius=$((temperature / 10))
        local temp_fahrenheit=$((temp_celsius * 9 / 5 + 32))
        echo "🌡️ Temperature: ${temp_celsius}°C (${temp_fahrenheit}°F)"
        
        # Temperature warnings
        if [ "$temp_celsius" -gt 45 ]; then
            echo "🔥 WARNING: Battery is very hot!"
        elif [ "$temp_celsius" -gt 40 ]; then
            echo "⚠️ CAUTION: Battery is warm"
        fi
    fi
    
    # Charging status and recommendations
    echo ""
    case "$status" in
        "CHARGING")
            echo "🔌 Battery is charging..."
            if [ "$percentage" -ge 80 ]; then
                echo "💡 Consider unplugging soon to preserve battery health"
            fi
            ;;
        "FULL")
            echo "✅ Battery is fully charged"
            echo "💡 Unplug charger to preserve battery health"
            ;;
        "DISCHARGING")
            echo "📱 Battery is discharging"
            if [ "$percentage" -le 20 ]; then
                echo "⚠️ Consider charging soon"
            elif [ "$percentage" -le 10 ]; then
                echo "🚨 Battery critically low! Charge immediately"
            fi
            ;;
        "NOT_CHARGING")
            echo "⏸️ Battery is not charging (plugged but not charging)"
            ;;
    esac
    
    # Battery health assessment
    echo ""
    echo "🏥 Battery Health Assessment:"
    case "$health" in
        "GOOD")
            echo "✅ Battery health is good"
            ;;
        "OVERHEAT")
            echo "🔥 Battery is overheating!"
            ;;
        "DEAD")
            echo "💀 Battery is dead"
            ;;
        "OVER_VOLTAGE")
            echo "⚡ Battery over voltage detected"
            ;;
        "UNSPECIFIED_FAILURE")
            echo "❌ Battery failure detected"
            ;;
        "COLD")
            echo "🧊 Battery is too cold"
            ;;
        *)
            echo "ℹ️ Battery health: $health"
            ;;
    esac
}

# Function to monitor battery continuously
monitor_battery() {
    local interval="$1"
    local log_file="battery_log_$(date +%Y%m%d_%H%M).txt"
    
    echo "📊 Starting continuous battery monitoring..."
    echo "Interval: $interval seconds"
    echo "Log file: $log_file"
    echo "Press Ctrl+C to stop"
    echo ""
    
    # Create log file header
    echo "Battery Monitor Log - $(date)" > "$log_file"
    echo "Time,Percentage,Status,Temperature,Health" >> "$log_file"
    
    local count=0
    while true; do
        clear
        echo "🔋 CONTINUOUS BATTERY MONITOR (Reading #$((++count)))"
        echo "======================================================"
        echo "📅 $(date)"
        echo ""
        
        battery_info=$(get_battery_info)
        if [ $? -eq 0 ]; then
            display_battery_info "$battery_info"
            
            # Log data
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            percentage=$(echo "$battery_info" | grep -o '"percentage":[^,]*' | cut -d':' -f2 | tr -d ' ')
            status=$(echo "$battery_info" | grep -o '"status":"[^"]*"' | cut -d':' -f2 | tr -d '"')
            temperature=$(echo "$battery_info" | grep -o '"temperature":[^,]*' | cut -d':' -f2 | tr -d ' ')
            health=$(echo "$battery_info" | grep -o '"health":"[^"]*"' | cut -d':' -f2 | tr -d '"')
            
            echo "$timestamp,$percentage,$status,$temperature,$health" >> "$log_file"
        else
            echo "❌ Failed to get battery information"
        fi
        
        echo ""
        echo "⏰ Next update in $interval seconds... (Ctrl+C to stop)"
        sleep "$interval"
    done
}

# Function to show battery history
show_battery_history() {
    echo "📈 Battery Log History"
    echo "====================="
    
    # Find recent log files
    log_files=$(find . -name "battery_log_*.txt" -mtime -7 2>/dev/null | sort -r)
    
    if [ -z "$log_files" ]; then
        echo "📝 No recent battery log files found"
        echo "💡 Run continuous monitoring to create logs"
        return
    fi
    
    echo "Recent log files:"
    echo "$log_files" | head -5
    echo ""
    
    read -p "📁 Enter log file to analyze: " selected_file
    
    if [ ! -f "$selected_file" ]; then
        echo "❌ File not found: $selected_file"
        return
    fi
    
    echo ""
    echo "📊 Battery Statistics from $selected_file:"
    echo "==========================================="
    
    # Basic statistics
    local total_readings avg_percentage min_percentage max_percentage
    total_readings=$(tail -n +3 "$selected_file" | wc -l)
    
    if [ "$total_readings" -gt 0 ]; then
        echo "📈 Total readings: $total_readings"
        
        # Extract percentages and calculate stats
        tail -n +3 "$selected_file" | cut -d',' -f2 > /tmp/percentages.tmp
        
        avg_percentage=$(awk '{sum+=$1} END {print int(sum/NR)}' /tmp/percentages.tmp)
        min_percentage=$(sort -n /tmp/percentages.tmp | head -1)
        max_percentage=$(sort -n /tmp/percentages.tmp | tail -1)
        
        echo "📊 Average charge: $avg_percentage%"
        echo "📉 Minimum charge: $min_percentage%"
        echo "📈 Maximum charge: $max_percentage%"
        
        # Show trend
        first_reading=$(tail -n +3 "$selected_file" | head -1 | cut -d',' -f2)
        last_reading=$(tail -1 "$selected_file" | cut -d',' -f2)
        trend=$((last_reading - first_reading))
        
        if [ "$trend" -gt 0 ]; then
            echo "📈 Trend: +$trend% (charging overall)"
        elif [ "$trend" -lt 0 ]; then
            echo "📉 Trend: $trend% (discharging overall)"
        else
            echo "➡️ Trend: No change"
        fi
        
        rm -f /tmp/percentages.tmp
    fi
}

# Main menu
echo ""
battery_info=$(get_battery_info)
if [ $? -eq 0 ]; then
    display_battery_info "$battery_info"
fi

echo ""
echo ""
echo "🔋 Battery Monitor Options:"
echo "1. 🔄 Refresh battery status"
echo "2. 📊 Continuous monitoring"
echo "3. 📈 View battery history"
echo "4. ⚡ Power saving tips"
echo "5. 🚨 Battery alerts setup"
echo ""

read -p "Select option (1-5, or press Enter to exit): " option

case $option in
    1)
        echo ""
        battery_info=$(get_battery_info)
        if [ $? -eq 0 ]; then
            display_battery_info "$battery_info"
        fi
        ;;
        
    2)
        echo ""
        read -p "⏰ Monitor interval in seconds (default: 30): " interval
        interval=${interval:-30}
        
        if ! [[ "$interval" =~ ^[0-9]+$ ]] || [ "$interval" -lt 5 ]; then
            echo "❌ Invalid interval. Using 30 seconds."
            interval=30
        fi
        
        monitor_battery "$interval"
        ;;
        
    3)
        show_battery_history
        ;;
        
    4)
        echo ""
        echo "⚡ POWER SAVING TIPS"
        echo "==================="
        echo "🔅 Reduce screen brightness"
        echo "📶 Turn off WiFi/Bluetooth when not needed"
        echo "🔕 Disable unnecessary notifications"
        echo "🚫 Close unused apps"
        echo "🌙 Use dark mode"
        echo "📍 Turn off location services for unused apps"
        echo "🔄 Disable auto-sync for non-essential apps"
        echo "✈️ Use airplane mode in low signal areas"
        echo "🔋 Enable battery saver mode"
        echo "📱 Avoid extreme temperatures"
        ;;
        
    5)
        echo ""
        echo "🚨 Battery Alert Setup"
        echo "====================="
        echo "💡 This would create a background script to monitor battery"
        echo "   and send notifications at specific levels."
        echo ""
        echo "🔧 Feature coming in next version!"
        echo "   For now, use continuous monitoring option."
        ;;
        
    "")
        echo "👋 Goodbye!"
        ;;
        
    *)
        echo "❌ Invalid option selected"
        ;;
esac

echo ""
echo "🔋 Battery monitoring complete!"
echo ""
echo "💡 Tips:"
echo "   - Monitor battery regularly to understand usage patterns"
echo "   - Charge between 20-80% for optimal battery health"
echo "   - Avoid extreme temperatures"
echo "   - Use original or high-quality chargers"