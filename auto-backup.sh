#!/data/data/com.termux/files/usr/bin/bash

# ========================================
# Termux Auto Backup Script
# ========================================
# Description: Automated backup solution for Termux
# Author: Termux Scripts Collection
# Version: 1.0
# Date: $(date +%Y-%m-%d)
# ========================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
BACKUP_BASE_DIR="$HOME/storage/shared/Backups"
BACKUP_NAME="termux-backup-$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$BACKUP_BASE_DIR/backup.log"
CONFIG_FILE="$HOME/.backup_config"

# Default directories to backup
DEFAULT_BACKUP_DIRS=(
    "$HOME"
    "$PREFIX/etc"
    "$HOME/.termux"
    "$HOME/storage/shared/Documents"
    "$HOME/storage/shared/Download"
)

# Files to exclude from backup
EXCLUDE_PATTERNS=(
    "*.tmp"
    "*.cache"
    "*/cache/*"
    "*/tmp/*"
    "*.log"
    "*/node_modules/*"
    "*/.git/*"
    "*/venv/*"
    "*/env/*"
    "__pycache__"
)

# Functions
print_banner() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${WHITE}    Termux Auto Backup Script v1.0     ${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo
}

print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $message"
}

error_exit() {
    local message="$1"
    log_message "ERROR: $message"
    print_colored "$RED" "❌ Error: $message"
    exit 1
}

success_message() {
    local message="$1"
    log_message "SUCCESS: $message"
    print_colored "$GREEN" "✅ $message"
}

warning_message() {
    local message="$1"
    log_message "WARNING: $message"
    print_colored "$YELLOW" "⚠️  Warning: $message"
}

check_dependencies() {
    print_colored "$BLUE" "🔍 Checking dependencies..."
    
    local dependencies=("tar" "gzip" "find")
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error_exit "Required dependency '$dep' is not installed"
        fi
    done
    
    success_message "All dependencies are installed"
}

setup_storage_permission() {
    print_colored "$BLUE" "📁 Setting up storage permissions..."
    
    if [ ! -d "$HOME/storage" ]; then
        print_colored "$YELLOW" "Storage permission not granted. Please grant storage permission."
        termux-setup-storage
        sleep 3
    fi
    
    if [ ! -d "$HOME/storage/shared" ]; then
        error_exit "Storage permission not granted or storage not accessible"
    fi
    
    success_message "Storage permissions are set up"
}

create_backup_directory() {
    print_colored "$BLUE" "📂 Creating backup directory..."
    
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        mkdir -p "$BACKUP_BASE_DIR" || error_exit "Failed to create backup directory"
    fi
    
    BACKUP_DIR="$BACKUP_BASE_DIR/$BACKUP_NAME"
    mkdir -p "$BACKUP_DIR" || error_exit "Failed to create backup subdirectory"
    
    success_message "Backup directory created: $BACKUP_DIR"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        print_colored "$GREEN" "📄 Configuration loaded from $CONFIG_FILE"
    else
        print_colored "$YELLOW" "📄 No config file found, using defaults"
        BACKUP_DIRS=("${DEFAULT_BACKUP_DIRS[@]}")
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
# Termux Backup Configuration
# Edit this file to customize your backup settings

# Directories to backup (space-separated)
BACKUP_DIRS=(
$(printf '    "%s"\n' "${BACKUP_DIRS[@]}")
)

# Compression level (1-9, where 9 is maximum compression)
COMPRESSION_LEVEL=6

# Keep backups for this many days
RETENTION_DAYS=30

# Enable email notifications (requires termux-api)
EMAIL_NOTIFICATIONS=false
EMAIL_ADDRESS=""
EOF
    
    success_message "Configuration saved to $CONFIG_FILE"
}

get_backup_dirs() {
    print_colored "$BLUE" "📋 Select directories to backup:"
    echo
    
    local selected_dirs=()
    
    echo "Available directories:"
    for i in "${!DEFAULT_BACKUP_DIRS[@]}"; do
        local dir="${DEFAULT_BACKUP_DIRS[$i]}"
        if [ -d "$dir" ]; then
            echo "  $((i+1)). $dir"
        fi
    done
    
    echo
    print_colored "$CYAN" "Enter directory numbers to backup (e.g., 1 2 3) or 'a' for all:"
    read -r selection
    
    if [[ "$selection" == "a" || "$selection" == "A" ]]; then
        for dir in "${DEFAULT_BACKUP_DIRS[@]}"; do
            if [ -d "$dir" ]; then
                selected_dirs+=("$dir")
            fi
        done
    else
        for num in $selection; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#DEFAULT_BACKUP_DIRS[@]}" ]; then
                local dir="${DEFAULT_BACKUP_DIRS[$((num-1))]}"
                if [ -d "$dir" ]; then
                    selected_dirs+=("$dir")
                fi
            fi
        done
    fi
    
    if [ ${#selected_dirs[@]} -eq 0 ]; then
        error_exit "No valid directories selected for backup"
    fi
    
    BACKUP_DIRS=("${selected_dirs[@]}")
    
    echo
    print_colored "$GREEN" "Selected directories for backup:"
    for dir in "${BACKUP_DIRS[@]}"; do
        echo "  ✅ $dir"
    done
}

calculate_size() {
    local total_size=0
    print_colored "$BLUE" "📏 Calculating backup size..."
    
    for dir in "${BACKUP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            local size=$(du -sb "$dir" 2>/dev/null | cut -f1)
            total_size=$((total_size + size))
        fi
    done
    
    # Convert bytes to human readable format
    if [ $total_size -gt 1073741824 ]; then
        local size_gb=$(echo "scale=2; $total_size / 1073741824" | bc)
        print_colored "$CYAN" "📊 Estimated backup size: ${size_gb} GB"
    elif [ $total_size -gt 1048576 ]; then
        local size_mb=$(echo "scale=2; $total_size / 1048576" | bc)
        print_colored "$CYAN" "📊 Estimated backup size: ${size_mb} MB"
    else
        local size_kb=$(echo "scale=2; $total_size / 1024" | bc)
        print_colored "$CYAN" "📊 Estimated backup size: ${size_kb} KB"
    fi
}

create_backup() {
    print_colored "$BLUE" "🔄 Starting backup process..."
    
    local backup_file="$BACKUP_DIR/backup.tar.gz"
    local exclude_args=""
    
    # Build exclude arguments
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        exclude_args="$exclude_args --exclude='$pattern'"
    done
    
    # Create the backup
    log_message "Creating backup archive: $backup_file"
    
    {
        echo "Backup created on: $(date)"
        echo "Hostname: $(hostname)"
        echo "Termux version: $(termux-info | grep -i version || echo 'Unknown')"
        echo "Directories backed up:"
        printf '  %s\n' "${BACKUP_DIRS[@]}"
        echo
    } > "$BACKUP_DIR/backup_info.txt"
    
    # Create tar archive with progress
    print_colored "$YELLOW" "📦 Creating compressed archive..."
    
    if tar -czf "$backup_file" \
        --exclude-from=<(printf '%s\n' "${EXCLUDE_PATTERNS[@]}") \
        -C / \
        "${BACKUP_DIRS[@]/#/}" \
        "$BACKUP_DIR/backup_info.txt" 2>&1 | tee -a "$LOG_FILE"; then
        
        success_message "Backup archive created successfully"
        
        # Get final backup size
        local backup_size=$(du -h "$backup_file" | cut -f1)
        print_colored "$GREEN" "📁 Final backup size: $backup_size"
        
        # Generate checksum
        print_colored "$BLUE" "🔐 Generating checksum..."
        local checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
        echo "$checksum  $(basename "$backup_file")" > "$BACKUP_DIR/checksum.sha256"
        success_message "Checksum generated: ${checksum:0:16}..."
        
    else
        error_exit "Failed to create backup archive"
    fi
}

cleanup_old_backups() {
    print_colored "$BLUE" "🧹 Cleaning up old backups..."
    
    local retention_days=${RETENTION_DAYS:-30}
    local deleted_count=0
    
    find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "termux-backup-*" -mtime +$retention_days | while read -r old_backup; do
        if [ -d "$old_backup" ]; then
            rm -rf "$old_backup"
            log_message "Deleted old backup: $(basename "$old_backup")"
            ((deleted_count++))
        fi
    done
    
    if [ $deleted_count -gt 0 ]; then
        success_message "Cleaned up $deleted_count old backups"
    else
        print_colored "$CYAN" "ℹ️  No old backups to clean up"
    fi
}

send_notification() {
    if command -v termux-notification &> /dev/null; then
        termux-notification \
            --title "Backup Complete" \
            --content "Termux backup completed successfully at $(date '+%H:%M')" \
            --priority high
    fi
    
    if [[ "$EMAIL_NOTIFICATIONS" == "true" ]] && [[ -n "$EMAIL_ADDRESS" ]] && command -v termux-share &> /dev/null; then
        echo "Termux backup completed successfully on $(date)" | termux-share -a send -c text/plain
    fi
}

interactive_mode() {
    print_banner
    
    print_colored "$CYAN" "🚀 Welcome to Termux Auto Backup!"
    echo
    
    # Setup
    check_dependencies
    setup_storage_permission
    load_config
    
    # Get user preferences
    get_backup_dirs
    echo
    
    # Confirm backup
    print_colored "$YELLOW" "❓ Ready to start backup? (y/N):"
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_colored "$YELLOW" "🚪 Backup cancelled by user"
        exit 0
    fi
    
    # Perform backup
    create_backup_directory
    calculate_size
    create_backup
    cleanup_old_backups
    send_notification
    
    # Save configuration
    save_config
    
    echo
    success_message "🎉 Backup completed successfully!"
    print_colored "$GREEN" "📁 Backup location: $BACKUP_DIR"
    print_colored "$CYAN" "📄 Log file: $LOG_FILE"
}

automated_mode() {
    print_colored "$BLUE" "🤖 Running in automated mode..."
    
    check_dependencies
    setup_storage_permission
    load_config
    
    if [ ${#BACKUP_DIRS[@]} -eq 0 ]; then
        BACKUP_DIRS=("${DEFAULT_BACKUP_DIRS[@]}")
    fi
    
    create_backup_directory
    create_backup
    cleanup_old_backups
    send_notification
    
    success_message "Automated backup completed"
}

show_help() {
    cat << EOF
Termux Auto Backup Script v1.0

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -a, --auto          Run in automated mode (no interaction)
    -c, --config        Edit configuration file
    -l, --list          List existing backups
    -r, --restore       Restore from backup (interactive)
    -d, --delete        Delete old backups
    
Examples:
    $0                  # Interactive mode
    $0 --auto           # Automated backup
    $0 --list           # Show existing backups
    
Configuration file: $CONFIG_FILE
Backup directory: $BACKUP_BASE_DIR

EOF
}

list_backups() {
    print_colored "$BLUE" "📋 Existing backups:"
    echo
    
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        print_colored "$YELLOW" "❌ No backup directory found"
        return
    fi
    
    local backup_count=0
    for backup in "$BACKUP_BASE_DIR"/termux-backup-*; do
        if [ -d "$backup" ]; then
            ((backup_count++))
            local backup_name=$(basename "$backup")
            local backup_date=$(echo "$backup_name" | sed 's/termux-backup-//' | sed 's/_/ /')
            local backup_size=$(du -sh "$backup" 2>/dev/null | cut -f1)
            
            print_colored "$GREEN" "  $backup_count. $backup_date ($backup_size)"
        fi
    done
    
    if [ $backup_count -eq 0 ]; then
        print_colored "$YELLOW" "❌ No backups found"
    else
        print_colored "$CYAN" "📊 Total backups: $backup_count"
    fi
}

# Main script logic
case "${1:-}" in
    -h|--help)
        show_help
        ;;
    -a|--auto)
        automated_mode
        ;;
    -c|--config)
        ${EDITOR:-nano} "$CONFIG_FILE"
        ;;
    -l|--list)
        list_backups
        ;;
    -r|--restore)
        print_colored "$YELLOW" "🚧 Restore functionality coming soon!"
        ;;
    -d|--delete)
        cleanup_old_backups
        ;;
    *)
        interactive_mode
        ;;
esac