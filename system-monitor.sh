#!/data/data/com.termux/files/usr/bin/bash

# ========================================
# Termux System Monitor Script
# ========================================
# Description: Real-time system monitoring dashboard
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
REFRESH_INTERVAL=2
LOG_FILE="$HOME/.system_monitor.log"
ALERT_CPU_THRESHOLD=80
ALERT_MEMORY_THRESHOLD=90
ALERT_STORAGE_THRESHOLD=85

# Functions
print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                    TERMUX SYSTEM MONITOR                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${BLUE}Press 'q' to quit, 'r' to refresh, 's' to save report${NC}"
    echo
}

get_cpu_usage() {
    local cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    if [[ -z "$cpu_idle" ]]; then
        # Alternative method using /proc/stat
        local cpu_line=($(head -n1 /proc/stat))
        local idle=${cpu_line[4]}
        local total=0
        for value in "${cpu_line[@]:1}"; do
            total=$((total + value))
        done
        cpu_idle=$(echo "scale=1; ($total - $idle) * 100 / $total" | bc 2>/dev/null || echo "0")
    fi
    echo "$cpu_idle"
}

get_memory_info() {
    local mem_info=$(cat /proc/meminfo)
    local mem_total=$(echo "$mem_info" | grep MemTotal | awk '{print $2}')
    local mem_available=$(echo "$mem_info" | grep MemAvailable | awk '{print $2}')
    local mem_used=$((mem_total - mem_available))
    local mem_percent=$(echo "scale=1; $mem_used * 100 / $mem_total" | bc)
    
    echo "$mem_used $mem_total $mem_percent"
}

get_storage_info() {
    local storage_info=$(df -h / | tail -1)
    local used=$(echo "$storage_info" | awk '{print $3}')
    local total=$(echo "$storage_info" | awk '{print $2}')
    local percent=$(echo "$storage_info" | awk '{print $5}' | sed 's/%//')
    
    echo "$used $total $percent"
}

get_network_info() {
    local rx_bytes=$(cat /sys/class/net/wlan0/statistics/rx_bytes 2>/dev/null || echo "0")
    local tx_bytes=$(cat /sys/class/net/wlan0/statistics/tx_bytes 2>/dev/null || echo "0")
    
    # Convert to MB
    local rx_mb=$(echo "scale=2; $rx_bytes / 1048576" | bc)
    local tx_mb=$(echo "scale=2; $tx_bytes / 1048576" | bc)
    
    echo "$rx_mb $tx_mb"
}

get_battery_info() {
    if command -v termux-battery-status &> /dev/null; then
        local battery_json=$(termux-battery-status 2>/dev/null)
        local battery_level=$(echo "$battery_json" | grep -o '"percentage":[0-9]*' | cut -d':' -f2)
        local battery_status=$(echo "$battery_json" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        echo "$battery_level $battery_status"
    else
        echo "N/A N/A"
    fi
}

get_top_processes() {
    echo -e "${YELLOW}Top Processes:${NC}"
    printf "%-8s %-8s %-8s %-30s\n" "PID" "CPU%" "MEM%" "COMMAND"
    echo "────────────────────────────────────────────────────────────"
    
    ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head -6 | tail -5 | while read pid cpu mem cmd; do
        if (( $(echo "$cpu > 10" | bc -l) )); then
            printf "${RED}%-8s %-8s %-8s %-30s${NC}\n" "$pid" "$cpu" "$mem" "$cmd"
        elif (( $(echo "$cpu > 5" | bc -l) )); then
            printf "${YELLOW}%-8s %-8s %-8s %-30s${NC}\n" "$pid" "$cpu" "$mem" "$cmd"
        else
            printf "%-8s %-8s %-8s %-30s\n" "$pid" "$cpu" "$mem" "$cmd"
        fi
    done
}

draw_progress_bar() {
    local percentage=$1
    local width=30
    local color=$2
    
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    printf "${color}["
    for ((i=0; i<filled; i++)); do printf "█"; done
    for ((i=0; i<empty; i++)); do printf "░"; done
    printf "]${NC} %3s%%" "$percentage"
}

check_alerts() {
    local cpu_usage=$1
    local mem_percent=$2
    local storage_percent=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if (( $(echo "$cpu_usage > $ALERT_CPU_THRESHOLD" | bc -l) )); then
        echo "[$timestamp] ALERT: High CPU usage: ${cpu_usage}%" >> "$LOG_FILE"
        echo -e "${RED}⚠️  HIGH CPU USAGE ALERT: ${cpu_usage}%${NC}"
    fi
    
    if (( $(echo "$mem_percent > $ALERT_MEMORY_THRESHOLD" | bc -l) )); then
        echo "[$timestamp] ALERT: High memory usage: ${mem_percent}%" >> "$LOG_FILE"
        echo -e "${RED}⚠️  HIGH MEMORY USAGE ALERT: ${mem_percent}%${NC}"
    fi
    
    if [[ "$storage_percent" -gt "$ALERT_STORAGE_THRESHOLD" ]]; then
        echo "[$timestamp] ALERT: High storage usage: ${storage_percent}%" >> "$LOG_FILE"
        echo -e "${RED}⚠️  HIGH STORAGE USAGE ALERT: ${storage_percent}%${NC}"
    fi
}

display_system_info() {
    # Get system information
    local cpu_usage=$(get_cpu_usage)
    local mem_info=($(get_memory_info))
    local storage_info=($(get_storage_info))
    local network_info=($(get_network_info))
    local battery_info=($(get_battery_info))
    
    # Extract values
    local mem_used_kb=${mem_info[0]}
    local mem_total_kb=${mem_info[1]}
    local mem_percent=${mem_info[2]}
    
    local storage_used=${storage_info[0]}
    local storage_total=${storage_info[1]}
    local storage_percent=${storage_info[2]}
    
    local rx_mb=${network_info[0]}
    local tx_mb=${network_info[1]}
    
    local battery_level=${battery_info[0]}
    local battery_status=${battery_info[1]}
    
    # Convert memory to MB
    local mem_used_mb=$(echo "scale=1; $mem_used_kb / 1024" | bc)
    local mem_total_mb=$(echo "scale=1; $mem_total_kb / 1024" | bc)
    
    # Display information
    echo -e "${WHITE}System Information:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo -e "${CYAN}Hostname:${NC} $(hostname)"
    echo -e "${CYAN}Uptime:${NC}   $(uptime -p 2>/dev/null || echo "N/A")"
    echo -e "${CYAN}Date:${NC}     $(date '+%Y-%m-%d %H:%M:%S')"
    echo
    
    echo -e "${WHITE}Resource Usage:${NC}"
    echo "────────────────────────────────────────────────────────────"
    
    # CPU Usage
    local cpu_color=$GREEN
    if (( $(echo "$cpu_usage > 70" | bc -l) )); then cpu_color=$RED
    elif (( $(echo "$cpu_usage > 50" | bc -l) )); then cpu_color=$YELLOW; fi
    
    echo -n -e "${CYAN}CPU Usage:${NC}    "
    draw_progress_bar "${cpu_usage%.*}" "$cpu_color"
    echo
    
    # Memory Usage
    local mem_color=$GREEN
    if (( $(echo "$mem_percent > 80" | bc -l) )); then mem_color=$RED
    elif (( $(echo "$mem_percent > 60" | bc -l) )); then mem_color=$YELLOW; fi
    
    echo -n -e "${CYAN}Memory:${NC}       "
    draw_progress_bar "${mem_percent%.*}" "$mem_color"
    echo -e " (${mem_used_mb}MB / ${mem_total_mb}MB)"
    
    # Storage Usage
    local storage_color=$GREEN
    if [[ "$storage_percent" -gt 80 ]]; then storage_color=$RED
    elif [[ "$storage_percent" -gt 60 ]]; then storage_color=$YELLOW; fi
    
    echo -n -e "${CYAN}Storage:${NC}      "
    draw_progress_bar "$storage_percent" "$storage_color"
    echo -e " (${storage_used} / ${storage_total})"
    
    # Battery (if available)
    if [[ "$battery_level" != "N/A" ]]; then
        local battery_color=$GREEN
        if [[ "$battery_level" -lt 20 ]]; then battery_color=$RED
        elif [[ "$battery_level" -lt 50 ]]; then battery_color=$YELLOW; fi
        
        echo -n -e "${CYAN}Battery:${NC}      "
        draw_progress_bar "$battery_level" "$battery_color"
        echo -e " (${battery_status})"
    fi
    
    echo
    
    # Network Information
    echo -e "${WHITE}Network Statistics:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo -e "${CYAN}Downloaded:${NC}   ${rx_mb} MB"
    echo -e "${CYAN}Uploaded:${NC}     ${tx_mb} MB"
    echo
    
    # Top Processes
    get_top_processes
    echo
    
    # Check for alerts
    check_alerts "$cpu_usage" "$mem_percent" "$storage_percent"
}

save_report() {
    local report_file="$HOME/system_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "========================================="
        echo "TERMUX SYSTEM REPORT"
        echo "Generated: $(date)"
        echo "========================================="
        echo
        
        # Redirect display_system_info output without colors
        display_system_info | sed 's/\x1b\[[0-9;]*m//g'
        
        echo
        echo "========================================="
        echo "Additional System Information:"
        echo "========================================="
        echo
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(uname -m)"
        echo "Shell: $SHELL"
        echo "Terminal: $TERM"
        echo
        echo "Installed packages:"
        pkg list-installed 2>/dev/null | head -10
        echo "... (showing first 10 packages)"
        
    } > "$report_file"
    
    echo -e "${GREEN}✅ Report saved to: $report_file${NC}"
}

interactive_mode() {
    print_banner
    
    while true; do
        display_system_info
        
        echo -e "${BLUE}Options: [q]uit [r]efresh [s]ave report [c]onfig${NC}"
        
        # Read user input with timeout
        read -t $REFRESH_INTERVAL -n 1 -s input
        
        case "$input" in
            'q'|'Q')
                echo -e "${YELLOW}Exiting system monitor...${NC}"
                break
                ;;
            'r'|'R')
                print_banner
                continue
                ;;
            's'|'S')
                save_report
                echo -e "${CYAN}Press any key to continue...${NC}"
                read -n 1 -s
                print_banner
                continue
                ;;
            'c'|'C')
                echo -e "${CYAN}Current Configuration:${NC}"
                echo "Refresh Interval: $REFRESH_INTERVAL seconds"
                echo "CPU Alert Threshold: $ALERT_CPU_THRESHOLD%"
                echo "Memory Alert Threshold: $ALERT_MEMORY_THRESHOLD%"
                echo "Storage Alert Threshold: $ALERT_STORAGE_THRESHOLD%"
                echo -e "${CYAN}Press any key to continue...${NC}"
                read -n 1 -s
                print_banner
                continue
                ;;
        esac
        
        print_banner
    done
}

continuous_mode() {
    echo -e "${BLUE}🔄 Running in continuous mode (Ctrl+C to stop)${NC}"
    echo
    
    while true; do
        clear
        print_banner
        display_system_info
        sleep $REFRESH_INTERVAL
    done
}

show_help() {
    cat << EOF
Termux System Monitor v1.0

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -c, --continuous    Run in continuous mode
    -i, --interval SEC  Set refresh interval (default: 2 seconds)
    -r, --report        Generate and save system report
    -l, --log          Show alert log
    
Examples:
    $0                  # Interactive mode
    $0 -c               # Continuous monitoring
    $0 -i 5             # 5-second refresh interval
    $0 -r               # Generate report only

EOF
}

# Main script logic
case "${1:-}" in
    -h|--help)
        show_help
        ;;
    -c|--continuous)
        continuous_mode
        ;;
    -i|--interval)
        REFRESH_INTERVAL=${2:-2}
        interactive_mode
        ;;
    -r|--report)
        save_report
        ;;
    -l|--log)
        if [[ -f "$LOG_FILE" ]]; then
            echo -e "${CYAN}Alert Log:${NC}"
            cat "$LOG_FILE"
        else
            echo -e "${YELLOW}No alert log found${NC}"
        fi
        ;;
    *)
        interactive_mode
        ;;
esac