#!/data/data/com.termux/files/usr/bin/bash

# ========================================
# Termux Scripts Auto-Installer (Silent)
# ========================================
# Description: Completely automatic installer with no prompts
# Author: Termux Scripts Collection
# Version: 1.0
# ========================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
GITHUB_REPO="omriphoenix-arch/Termux-command"
INSTALL_DIR="$HOME/termux-command"
SCRIPTS_DIR="$INSTALL_DIR"
BIN_DIR="$HOME/.local/bin"

# Functions
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
    exit 1
}

step_message() {
    print_colored "$CYAN" "🔄 $1"
}

# Main installation (completely silent)
main() {
    print_colored "$WHITE" "🚀 Termux Scripts Auto-Installer (Silent Mode)"
    print_colored "$CYAN" "Installing automatically without prompts..."
    echo
    
    # Check requirements
    step_message "Checking requirements..."
    if ! command -v git &> /dev/null; then
        pkg update >/dev/null 2>&1 && pkg install -y git >/dev/null 2>&1 || error_message "Failed to install git"
    fi
    if ! command -v curl &> /dev/null; then
        pkg install -y curl >/dev/null 2>&1 || error_message "Failed to install curl"
    fi
    success_message "Requirements ready"
    
    # Download scripts
    step_message "Downloading scripts..."
    if [ -d "$INSTALL_DIR" ]; then
        mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%s)" 2>/dev/null
    fi
    
    if git clone "https://github.com/$GITHUB_REPO.git" "$INSTALL_DIR" >/dev/null 2>&1; then
        success_message "Scripts downloaded"
    else
        error_message "Failed to download scripts"
    fi
    
    # Make executable
    step_message "Setting up scripts..."
    cd "$SCRIPTS_DIR" || error_message "Failed to access scripts directory"
    chmod +x *.sh 2>/dev/null
    success_message "Scripts configured"
    
    # Create symlinks
    step_message "Creating global commands..."
    mkdir -p "$BIN_DIR"
    
    # Add bin directory to PATH
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$BIN_DIR:$PATH"
    fi
    
    # Create command shortcuts
    local commands=(
        "auto-backup.sh:termux-backup"
        "system-monitor.sh:termux-monitor"
        "dev-tools.sh:termux-dev"
        "network-tools.sh:termux-network"
        "task-scheduler.sh:termux-schedule"
        "script-manager.sh:termux-scripts"
        "cleanup.sh:termux-clean"
        "update-all.sh:termux-update"
        "system-info.sh:termux-info"
        "battery-monitor.sh:termux-battery"
    )
    
    for cmd in "${commands[@]}"; do
        local script_name="${cmd%:*}"
        local command_name="${cmd#*:}"
        if [ -f "$script_name" ]; then
            ln -sf "$SCRIPTS_DIR/$script_name" "$BIN_DIR/$command_name" 2>/dev/null
        fi
    done
    success_message "Global commands created"
    
    # Create aliases
    step_message "Setting up aliases..."
    cat >> "$HOME/.bashrc" << 'EOF'

# Termux Scripts Aliases
alias tsscripts='termux-scripts'
alias tsmon='termux-monitor'
alias tsbackup='termux-backup'
alias tsdev='termux-dev'
alias tsnet='termux-network'
alias tscd='cd ~/termux-command'
alias tshelp='cat ~/termux-command/COMMANDS.txt | less'
EOF
    success_message "Aliases configured"
    
    # Install basic dependencies
    step_message "Installing dependencies..."
    pkg update >/dev/null 2>&1
    pkg install -y curl wget git vim nano openssh rsync zip unzip tar bc >/dev/null 2>&1
    success_message "Dependencies installed"
    
    # Final setup
    mkdir -p "$HOME/.automation" "$HOME/.dev-tools" "$HOME/.network-tools" 2>/dev/null
    
    echo
    print_colored "$GREEN" "🎉 Installation completed successfully!"
    echo
    print_colored "$WHITE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_colored "$CYAN" "📋 Available commands:"
    print_colored "$GREEN" "  termux-scripts     # Main script manager"
    print_colored "$GREEN" "  termux-monitor     # System monitoring"
    print_colored "$GREEN" "  termux-backup      # Automated backup"
    print_colored "$GREEN" "  termux-dev         # Development tools"
    print_colored "$GREEN" "  termux-network     # Network utilities"
    echo
    print_colored "$CYAN" "📋 Short aliases:"
    print_colored "$GREEN" "  tsscripts, tsmon, tsbackup, tsdev, tsnet"
    echo
    print_colored "$YELLOW" "⚠️  IMPORTANT: Restart your terminal or run:"
    print_colored "$WHITE" "    source ~/.bashrc"
    echo
    print_colored "$YELLOW" "📱 For full functionality, also run:"
    print_colored "$WHITE" "    termux-setup-storage"
    print_colored "$WHITE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    print_colored "$CYAN" "🚀 Get started: termux-scripts"
}

main