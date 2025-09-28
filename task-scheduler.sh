#!/data/data/com.termux/files/usr/bin/bash

# ========================================
# Termux Task Scheduler & Automation Script
# ========================================
# Description: Task scheduler and workflow automation
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
AUTOMATION_DIR="$HOME/.automation"
TASKS_DIR="$AUTOMATION_DIR/tasks"
LOGS_DIR="$AUTOMATION_DIR/logs"
CONFIG_FILE="$AUTOMATION_DIR/config"
CRON_FILE="$AUTOMATION_DIR/crontab"

# Functions
print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                TERMUX TASK SCHEDULER & AUTOMATION           ${CYAN}║${NC}"
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
    local task_name="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$LOGS_DIR/${task_name}.log"
    
    echo "[$timestamp] $message" >> "$log_file"
}

setup_automation() {
    print_colored "$BLUE" "🔧 Setting up task scheduler and automation..."
    
    # Create directories
    mkdir -p "$AUTOMATION_DIR" "$TASKS_DIR" "$LOGS_DIR"
    
    # Install required packages
    local packages=(
        "cron"
        "at"
        "termux-api"
    )
    
    for pkg in "${packages[@]}"; do
        if ! pkg list-installed 2>/dev/null | grep -q "^$pkg/"; then
            print_colored "$YELLOW" "Installing $pkg..."
            pkg install -y "$pkg" 2>/dev/null
        else
            print_colored "$GREEN" "$pkg already installed"
        fi
    done
    
    # Setup cron service
    if command -v crond &> /dev/null; then
        print_colored "$CYAN" "Starting cron daemon..."
        crond 2>/dev/null || true
        success_message "Cron daemon started"
    else
        warning_message "Cron not available. Some features may not work."
    fi
    
    # Create default config
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << 'EOF'
# Automation Configuration
NOTIFICATION_ENABLED=true
LOG_RETENTION_DAYS=30
MAX_PARALLEL_TASKS=5
EMAIL_NOTIFICATIONS=false
EMAIL_ADDRESS=""
EOF
        success_message "Default configuration created"
    fi
    
    success_message "Automation setup complete!"
}

create_task() {
    print_colored "$BLUE" "📝 Create New Task"
    echo
    
    echo -n "Task name: "
    read -r task_name
    
    if [ -z "$task_name" ]; then
        error_message "Task name cannot be empty"
        return 1
    fi
    
    # Sanitize task name
    task_name=$(echo "$task_name" | tr ' ' '_' | tr -cd '[:alnum:]_-')
    
    if [ -f "$TASKS_DIR/${task_name}.sh" ]; then
        echo -n "Task already exists. Overwrite? (y/N): "
        read -r overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            info_message "Task creation cancelled"
            return 0
        fi
    fi
    
    echo
    echo "Task types:"
    echo "1. Script execution"
    echo "2. System command"
    echo "3. Backup task"
    echo "4. Network monitoring"
    echo "5. Custom workflow"
    
    echo -n "Choose task type (1-5): "
    read -r task_type
    
    local task_content=""
    local task_description=""
    
    case $task_type in
        1)
            echo -n "Script path: "
            read -r script_path
            if [ ! -f "$script_path" ]; then
                error_message "Script file not found: $script_path"
                return 1
            fi
            task_content="bash '$script_path'"
            task_description="Execute script: $script_path"
            ;;
        2)
            echo -n "Command to execute: "
            read -r command
            task_content="$command"
            task_description="Execute command: $command"
            ;;
        3)
            echo -n "Backup source directory: "
            read -r backup_source
            echo -n "Backup destination: "
            read -r backup_dest
            task_content="tar -czf '$backup_dest/backup_\$(date +%Y%m%d_%H%M%S).tar.gz' '$backup_source'"
            task_description="Backup $backup_source to $backup_dest"
            ;;
        4)
            echo -n "Host to monitor: "
            read -r monitor_host
            task_content="ping -c 1 '$monitor_host' >/dev/null && echo 'Host $monitor_host is UP' || echo 'Host $monitor_host is DOWN'"
            task_description="Monitor host: $monitor_host"
            ;;
        5)
            echo "Enter your custom commands (one per line, empty line to finish):"
            task_content=""
            while true; do
                echo -n "> "
                read -r line
                [ -z "$line" ] && break
                task_content="$task_content$line\n"
            done
            task_description="Custom workflow"
            ;;
        *)
            error_message "Invalid task type"
            return 1
            ;;
    esac
    
    # Create task script
    cat > "$TASKS_DIR/${task_name}.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash

# Task: $task_name
# Description: $task_description  
# Created: $(date)

# Setup logging
TASK_NAME="$task_name"
LOG_FILE="$LOGS_DIR/\${TASK_NAME}.log"

log_message() {
    local timestamp=\$(date '+%Y-%m-%d %H:%M:%S')
    echo "[\$timestamp] \$1" >> "\$LOG_FILE"
    echo "\$1"
}

# Send notification if enabled
send_notification() {
    local title="\$1"
    local message="\$2"
    
    if command -v termux-notification &> /dev/null; then
        termux-notification --title "\$title" --content "\$message"
    fi
}

# Task execution
log_message "Task started: $task_name"
send_notification "Task Started" "$task_name execution started"

# Execute task content
$(echo -e "$task_content")

TASK_EXIT_CODE=\$?

if [ \$TASK_EXIT_CODE -eq 0 ]; then
    log_message "Task completed successfully: $task_name"
    send_notification "Task Completed" "$task_name completed successfully"
else
    log_message "Task failed with exit code \$TASK_EXIT_CODE: $task_name"
    send_notification "Task Failed" "$task_name failed with exit code \$TASK_EXIT_CODE"
fi

exit \$TASK_EXIT_CODE
EOF
    
    chmod +x "$TASKS_DIR/${task_name}.sh"
    
    success_message "Task '$task_name' created successfully"
    info_message "Task file: $TASKS_DIR/${task_name}.sh"
    
    # Ask to schedule the task
    echo -n "Schedule this task? (y/N): "
    read -r schedule_task
    
    if [[ "$schedule_task" =~ ^[Yy]$ ]]; then
        schedule_task_function "$task_name"
    fi
}

schedule_task_function() {
    local task_name="$1"
    
    if [ -z "$task_name" ]; then
        echo -n "Enter task name to schedule: "
        read -r task_name
    fi
    
    if [ ! -f "$TASKS_DIR/${task_name}.sh" ]; then
        error_message "Task '$task_name' not found"
        return 1
    fi
    
    print_colored "$BLUE" "📅 Schedule Task: $task_name"
    echo
    
    echo "Schedule options:"
    echo "1. Every minute"
    echo "2. Every hour"  
    echo "3. Daily"
    echo "4. Weekly"
    echo "5. Monthly"
    echo "6. Custom cron expression"
    echo "7. One-time (at specific time)"
    
    echo -n "Choose schedule type (1-7): "
    read -r schedule_type
    
    local cron_expression=""
    
    case $schedule_type in
        1)
            cron_expression="* * * * *"
            ;;
        2)
            cron_expression="0 * * * *"
            ;;
        3)
            echo -n "At what time (HH:MM, 24-hour format): "
            read -r daily_time
            if [[ ! "$daily_time" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
                error_message "Invalid time format. Use HH:MM"
                return 1
            fi
            local hour=$(echo "$daily_time" | cut -d: -f1)
            local minute=$(echo "$daily_time" | cut -d: -f2)
            cron_expression="$minute $hour * * *"
            ;;
        4)
            echo -n "Day of week (0=Sunday, 1=Monday, ..., 6=Saturday): "
            read -r day_of_week
            echo -n "At what time (HH:MM): "
            read -r weekly_time
            local hour=$(echo "$weekly_time" | cut -d: -f1)
            local minute=$(echo "$weekly_time" | cut -d: -f2)
            cron_expression="$minute $hour * * $day_of_week"
            ;;
        5)
            echo -n "Day of month (1-31): "
            read -r day_of_month
            echo -n "At what time (HH:MM): "
            read -r monthly_time
            local hour=$(echo "$monthly_time" | cut -d: -f1)
            local minute=$(echo "$monthly_time" | cut -d: -f2)
            cron_expression="$minute $hour $day_of_month * *"
            ;;
        6)
            echo -n "Enter cron expression (minute hour day month weekday): "
            read -r cron_expression
            ;;
        7)
            echo -n "Enter date and time (YYYY-MM-DD HH:MM): "
            read -r at_time
            
            if command -v at &> /dev/null; then
                echo "$TASKS_DIR/${task_name}.sh" | at "$at_time" 2>/dev/null
                if [ $? -eq 0 ]; then
                    success_message "One-time task scheduled for $at_time"
                else
                    error_message "Failed to schedule one-time task"
                fi
            else
                error_message "'at' command not available"
            fi
            return 0
            ;;
        *)
            error_message "Invalid schedule type"
            return 1
            ;;
    esac
    
    # Add to crontab
    if [ -n "$cron_expression" ]; then
        # Get current crontab
        crontab -l 2>/dev/null > "$CRON_FILE" || touch "$CRON_FILE"
        
        # Remove existing entry for this task
        grep -v "$TASKS_DIR/${task_name}.sh" "$CRON_FILE" > "$CRON_FILE.tmp" || true
        mv "$CRON_FILE.tmp" "$CRON_FILE"
        
        # Add new entry
        echo "$cron_expression $TASKS_DIR/${task_name}.sh" >> "$CRON_FILE"
        
        # Install new crontab
        crontab "$CRON_FILE"
        
        success_message "Task '$task_name' scheduled with cron expression: $cron_expression"
    fi
}

list_tasks() {
    print_colored "$BLUE" "📋 Task List"
    echo
    
    if [ ! -d "$TASKS_DIR" ] || [ -z "$(ls -A "$TASKS_DIR" 2>/dev/null)" ]; then
        warning_message "No tasks found"
        return 0
    fi
    
    echo -e "${WHITE}Available Tasks:${NC}"
    echo "────────────────────────────────────────────────────────────"
    
    local task_num=1
    for task_file in "$TASKS_DIR"/*.sh; do
        if [ -f "$task_file" ]; then
            local task_name=$(basename "$task_file" .sh)
            local task_desc=$(grep "^# Description:" "$task_file" | cut -d: -f2- | xargs)
            local last_run=""
            
            if [ -f "$LOGS_DIR/${task_name}.log" ]; then
                last_run=$(tail -1 "$LOGS_DIR/${task_name}.log" 2>/dev/null | grep -o '\[.*\]' | tr -d '[]')
            fi
            
            echo -e "${CYAN}$task_num.${NC} ${GREEN}$task_name${NC}"
            [ -n "$task_desc" ] && echo -e "   Description: $task_desc"
            [ -n "$last_run" ] && echo -e "   Last run: $last_run"
            echo
            
            ((task_num++))
        fi
    done
    
    # Show scheduled tasks
    print_colored "$CYAN" "Scheduled Tasks:"
    echo "────────────────────────────────────────────────────────────"
    
    if command -v crontab &> /dev/null; then
        crontab -l 2>/dev/null | grep "$TASKS_DIR" | while read -r cron_line; do
            local cron_expr=$(echo "$cron_line" | cut -d' ' -f1-5)
            local task_path=$(echo "$cron_line" | cut -d' ' -f6-)
            local task_name=$(basename "$task_path" .sh)
            
            echo -e "${YELLOW}$cron_expr${NC} → ${GREEN}$task_name${NC}"
        done
    fi
    
    # Show one-time tasks
    if command -v atq &> /dev/null; then
        local at_jobs=$(atq 2>/dev/null)
        if [ -n "$at_jobs" ]; then
            echo
            print_colored "$CYAN" "One-time Tasks:"
            echo "────────────────────────────────────────────────────────────"
            echo "$at_jobs"
        fi
    fi
}

run_task() {
    print_colored "$BLUE" "▶️  Run Task"
    echo
    
    if [ -z "$1" ]; then
        list_tasks
        echo -n "Enter task name to run: "
        read -r task_name
    else
        task_name="$1"
    fi
    
    if [ ! -f "$TASKS_DIR/${task_name}.sh" ]; then
        error_message "Task '$task_name' not found"
        return 1
    fi
    
    print_colored "$YELLOW" "Running task: $task_name"
    echo
    
    # Run task and capture output
    if bash "$TASKS_DIR/${task_name}.sh"; then
        success_message "Task '$task_name' completed successfully"
    else
        error_message "Task '$task_name' failed"
    fi
}

delete_task() {
    print_colored "$BLUE" "🗑️  Delete Task"
    echo
    
    list_tasks
    echo -n "Enter task name to delete: "
    read -r task_name
    
    if [ ! -f "$TASKS_DIR/${task_name}.sh" ]; then
        error_message "Task '$task_name' not found"
        return 1
    fi
    
    echo -n "Are you sure you want to delete task '$task_name'? (y/N): "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Remove from crontab
        if command -v crontab &> /dev/null; then
            crontab -l 2>/dev/null | grep -v "$TASKS_DIR/${task_name}.sh" | crontab - 2>/dev/null || true
        fi
        
        # Delete task file
        rm -f "$TASKS_DIR/${task_name}.sh"
        
        # Ask to delete logs
        if [ -f "$LOGS_DIR/${task_name}.log" ]; then
            echo -n "Delete task logs? (y/N): "
            read -r delete_logs
            if [[ "$delete_logs" =~ ^[Yy]$ ]]; then
                rm -f "$LOGS_DIR/${task_name}.log"
            fi
        fi
        
        success_message "Task '$task_name' deleted"
    else
        info_message "Task deletion cancelled"
    fi
}

view_logs() {
    print_colored "$BLUE" "📄 View Task Logs"
    echo
    
    if [ -z "$(ls -A "$LOGS_DIR" 2>/dev/null)" ]; then
        warning_message "No logs found"
        return 0
    fi
    
    echo "Available log files:"
    local log_num=1
    for log_file in "$LOGS_DIR"/*.log; do
        if [ -f "$log_file" ]; then
            local task_name=$(basename "$log_file" .log)
            local log_size=$(du -h "$log_file" | cut -f1)
            local last_modified=$(stat -c %y "$log_file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
            
            echo -e "${CYAN}$log_num.${NC} ${GREEN}$task_name${NC} (${log_size}, $last_modified)"
            ((log_num++))
        fi
    done
    
    echo -n "Enter task name to view logs: "
    read -r task_name
    
    local log_file="$LOGS_DIR/${task_name}.log"
    
    if [ ! -f "$log_file" ]; then
        error_message "Log file for task '$task_name' not found"
        return 1
    fi
    
    echo
    print_colored "$CYAN" "Log file: $log_file"
    echo "────────────────────────────────────────────────────────────"
    
    # Show last 50 lines by default
    echo -n "Show (a)ll logs or (l)ast 50 lines? (a/L): "
    read -r log_view
    
    if [[ "$log_view" =~ ^[Aa]$ ]]; then
        cat "$log_file"
    else
        tail -50 "$log_file"
    fi
}

automation_wizard() {
    print_colored "$BLUE" "🧙 Automation Wizard"
    echo
    
    echo "Common automation templates:"
    echo "1. Daily backup"
    echo "2. System monitoring"
    echo "3. Network check"
    echo "4. Log cleanup"
    echo "5. Custom workflow"
    
    echo -n "Choose template (1-5): "
    read -r template_choice
    
    case $template_choice in
        1)
            # Daily backup wizard
            echo -n "Source directory to backup: "
            read -r backup_source
            echo -n "Backup destination: "
            read -r backup_dest
            echo -n "Backup time (HH:MM): "
            read -r backup_time
            
            local task_name="daily_backup_$(date +%s)"
            
            cat > "$TASKS_DIR/${task_name}.sh" << EOF
#!/data/data/com.termux/files/usr/bin/bash
# Daily Backup Task
BACKUP_SOURCE="$backup_source"
BACKUP_DEST="$backup_dest"
BACKUP_FILE="\$BACKUP_DEST/backup_\$(date +%Y%m%d_%H%M%S).tar.gz"

echo "Starting backup..."
tar -czf "\$BACKUP_FILE" "\$BACKUP_SOURCE" && echo "Backup completed: \$BACKUP_FILE" || echo "Backup failed"
EOF
            
            chmod +x "$TASKS_DIR/${task_name}.sh"
            
            # Schedule daily
            local hour=$(echo "$backup_time" | cut -d: -f1)
            local minute=$(echo "$backup_time" | cut -d: -f2)
            
            crontab -l 2>/dev/null > "$CRON_FILE" || touch "$CRON_FILE"
            echo "$minute $hour * * * $TASKS_DIR/${task_name}.sh" >> "$CRON_FILE"
            crontab "$CRON_FILE"
            
            success_message "Daily backup automation created and scheduled"
            ;;
        2)
            # System monitoring wizard
            local task_name="system_monitor_$(date +%s)"
            
            cat > "$TASKS_DIR/${task_name}.sh" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# System Monitoring Task

# Check CPU usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

# Check memory usage  
MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')

# Check disk usage
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')

echo "System Status Report - $(date)"
echo "CPU Usage: $CPU_USAGE%"
echo "Memory Usage: $MEM_USAGE%"
echo "Disk Usage: $DISK_USAGE%"

# Alert if usage is high
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    termux-notification --title "High CPU Usage" --content "CPU usage is ${CPU_USAGE}%"
fi

if (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
    termux-notification --title "High Memory Usage" --content "Memory usage is ${MEM_USAGE}%"
fi

if [ "$DISK_USAGE" -gt 80 ]; then
    termux-notification --title "High Disk Usage" --content "Disk usage is ${DISK_USAGE}%"
fi
EOF
            
            chmod +x "$TASKS_DIR/${task_name}.sh"
            
            # Schedule every 30 minutes
            crontab -l 2>/dev/null > "$CRON_FILE" || touch "$CRON_FILE"
            echo "*/30 * * * * $TASKS_DIR/${task_name}.sh" >> "$CRON_FILE"
            crontab "$CRON_FILE"
            
            success_message "System monitoring automation created"
            ;;
        *)
            warning_message "Template not implemented yet"
            ;;
    esac
}

show_help() {
    cat << EOF
Termux Task Scheduler & Automation v1.0

Usage: $0 [COMMAND] [ARGS]

COMMANDS:
    setup               Setup automation environment
    create              Create new task
    list                List all tasks
    run TASK_NAME       Run specific task
    schedule TASK_NAME  Schedule a task
    delete              Delete a task
    logs                View task logs
    wizard              Automation wizard
    
Examples:
    $0 setup            # Setup automation
    $0 create           # Create new task
    $0 run backup       # Run backup task
    $0 schedule backup  # Schedule backup task

EOF
}

main_menu() {
    print_banner
    
    echo -e "${WHITE}Task Scheduler & Automation Menu:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo -e "${CYAN}1.${NC} Setup Automation"
    echo -e "${CYAN}2.${NC} Create Task"
    echo -e "${CYAN}3.${NC} List Tasks"
    echo -e "${CYAN}4.${NC} Run Task"
    echo -e "${CYAN}5.${NC} Schedule Task"
    echo -e "${CYAN}6.${NC} Delete Task"
    echo -e "${CYAN}7.${NC} View Logs"
    echo -e "${CYAN}8.${NC} Automation Wizard"
    echo -e "${CYAN}9.${NC} Exit"
    echo
    
    echo -n "Choose option (1-9): "
    read -r choice
    
    case $choice in
        1) setup_automation ;;
        2) create_task ;;
        3) list_tasks ;;
        4) run_task ;;
        5) schedule_task_function ;;
        6) delete_task ;;
        7) view_logs ;;
        8) automation_wizard ;;
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
    setup) setup_automation ;;
    create) create_task ;;
    list) list_tasks ;;
    run) run_task "$2" ;;
    schedule) schedule_task_function "$2" ;;
    delete) delete_task ;;
    logs) view_logs ;;
    wizard) automation_wizard ;;
    -h|--help) show_help ;;
    *) main_menu ;;
esac