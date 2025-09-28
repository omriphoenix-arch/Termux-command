#!/data/data/com.termux/files/usr/bin/bash

# ========================================
# Termux Scripts Auto-Installer
# ========================================
# Description: One-command installer for all Termux scripts
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
GITHUB_REPO="omriphoenix-arch/Termux-command"
INSTALL_DIR="$HOME/termux-command"
SCRIPTS_DIR="$INSTALL_DIR"
BIN_DIR="$HOME/.local/bin"

# Functions
print_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}              TERMUX SCRIPTS AUTO-INSTALLER                  ${CYAN}║${NC}"
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
    exit 1
}

warning_message() {
    print_colored "$YELLOW" "⚠️  Warning: $1"
}

info_message() {
    print_colored "$BLUE" "ℹ️  $1"
}

step_message() {
    print_colored "$CYAN" "🔄 $1"
}

check_requirements() {
    step_message "Checking requirements..."
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        warning_message "Git not found. Installing git..."
        pkg update && pkg install -y git || error_message "Failed to install git"
    fi
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        warning_message "Curl not found. Installing curl..."
        pkg install -y curl || error_message "Failed to install curl"
    fi
    
    success_message "Requirements check completed"
}

download_scripts() {
    step_message "Downloading Termux Scripts from GitHub..."
    
    # Remove existing installation if present
    if [ -d "$INSTALL_DIR" ]; then
        warning_message "Existing installation found. Backing up..."
        mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%s)"
    fi
    
    # Clone the repository
    if git clone "https://github.com/$GITHUB_REPO.git" "$INSTALL_DIR" 2>/dev/null; then
        success_message "Scripts downloaded successfully"
    else
        # Fallback to direct download if git clone fails
        warning_message "Git clone failed. Trying direct download..."
        
        mkdir -p "$INSTALL_DIR"
        cd "$INSTALL_DIR" || error_message "Failed to create install directory"
        
        # Download individual scripts (you'll need to update this list)
        local scripts=(
            "auto-backup.sh"
            "battery-monitor.sh" 
            "cleanup.sh"
            "dev-setup.sh"
            "dev-tools.sh"
            "file-organizer.sh"
            "install-essentials.sh"
            "media-converter.sh"
            "network-scan.sh"
            "network-tools.sh"
            "password-gen.sh"
            "qr-generator.sh"
            "quick-utils.sh"
            "script-manager.sh"
            "system-info.sh"
            "system-monitor.sh"
            "task-scheduler.sh"
            "text-processor.sh"
            "update-all.sh"
            "weather.sh"
            "youtube-dl.sh"
            "COMMANDS.txt"
            "README.md"
        )
        
        for script in "${scripts[@]}"; do
            print_colored "$YELLOW" "Downloading $script..."
            if curl -sL "https://raw.githubusercontent.com/$GITHUB_REPO/main/$script" -o "$script"; then
                print_colored "$GREEN" "✓ $script downloaded"
            else
                warning_message "Failed to download $script"
            fi
        done
    fi
}

make_executable() {
    step_message "Making scripts executable..."
    
    cd "$SCRIPTS_DIR" || error_message "Failed to access scripts directory"
    
    # Make all .sh files executable
    chmod +x *.sh 2>/dev/null
    
    success_message "Scripts made executable"
}

create_symlinks() {
    step_message "Creating command shortcuts..."
    
    # Create bin directory if it doesn't exist
    mkdir -p "$BIN_DIR"
    
    # Add bin directory to PATH if not already there
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$BIN_DIR:$PATH"
        info_message "Added $BIN_DIR to PATH"
    fi
    
    cd "$SCRIPTS_DIR" || error_message "Failed to access scripts directory"
    
    # Create symlinks for easy access
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
        "file-organizer.sh:termux-organize"
        "password-gen.sh:termux-password"
        "weather.sh:termux-weather"
        "youtube-dl.sh:termux-youtube"
        "media-converter.sh:termux-convert"
        "text-processor.sh:termux-text"
        "qr-generator.sh:termux-qr"
        "quick-utils.sh:termux-utils"
        "network-scan.sh:termux-scan"
        "install-essentials.sh:termux-essentials"
        "dev-setup.sh:termux-dev-setup"
    )
    
    for cmd in "${commands[@]}"; do
        local script_name="${cmd%:*}"
        local command_name="${cmd#*:}"
        
        if [ -f "$script_name" ]; then
            ln -sf "$SCRIPTS_DIR/$script_name" "$BIN_DIR/$command_name" 2>/dev/null
            print_colored "$GREEN" "✓ Created command: $command_name"
        fi
    done
    
    success_message "Command shortcuts created"
}

create_aliases() {
    step_message "Creating convenient aliases..."
    
    # Create aliases file
    cat >> "$HOME/.bashrc" << 'EOF'

# ========================================
# Termux Scripts Aliases
# ========================================
alias tsmon='termux-monitor'        # System monitor
alias tsbackup='termux-backup'      # Auto backup
alias tsdev='termux-dev'            # Development tools
alias tsnet='termux-network'        # Network tools
alias tssched='termux-schedule'     # Task scheduler
alias tsscripts='termux-scripts'    # Script manager
alias tsclean='termux-clean'        # System cleanup
alias tsupdate='termux-update'      # System update
alias tsinfo='termux-info'          # System info
alias tsbat='termux-battery'        # Battery monitor
alias tsorg='termux-organize'       # File organizer
alias tspass='termux-password'      # Password generator
alias tsweather='termux-weather'    # Weather info
alias tsyt='termux-youtube'         # YouTube downloader
alias tsconv='termux-convert'       # Media converter
alias tstext='termux-text'          # Text processor
alias tsqr='termux-qr'              # QR generator
alias tsutils='termux-utils'        # Quick utilities
alias tsscan='termux-scan'          # Network scan

# Quick access to script directory
alias tscd='cd ~/termux-command'
alias tshelp='cat ~/termux-command/COMMANDS.txt | less'
EOF
    
    success_message "Aliases added to ~/.bashrc"
}

install_dependencies() {
    step_message "Installing essential dependencies..."
    
    # Run the essentials installer if it exists
    if [ -f "$SCRIPTS_DIR/install-essentials.sh" ]; then
        print_colored "$CYAN" "Running essentials installer..."
        bash "$SCRIPTS_DIR/install-essentials.sh"
    else
        # Install basic packages manually
        local packages=(
            "curl" "wget" "git" "vim" "nano"
            "openssh" "rsync" "zip" "unzip" "tar"
            "grep" "sed" "awk" "jq" "tree" "htop"
            "termux-api" "bc" "cron"
        )
        
        pkg update
        for package in "${packages[@]}"; do
            print_colored "$YELLOW" "Installing $package..."
            pkg install -y "$package" 2>/dev/null || warning_message "Failed to install $package"
        done
    fi
    
    success_message "Dependencies installation completed"
}

setup_storage() {
    step_message "Setting up storage access..."
    
    if [ ! -d "$HOME/storage" ]; then
        print_colored "$YELLOW" "Storage permission required for some scripts to work properly."
        print_colored "$CYAN" "Please grant storage permission when prompted..."
        termux-setup-storage
        
        # Wait for storage setup
        sleep 3
        
        if [ -d "$HOME/storage" ]; then
            success_message "Storage access configured"
        else
            warning_message "Storage access not configured. Some features may not work."
        fi
    else
        success_message "Storage access already configured"
    fi
}

post_install_setup() {
    step_message "Running post-installation setup..."
    
    # Create directories that scripts might need
    mkdir -p "$HOME/.automation" "$HOME/.dev-tools" "$HOME/.network-tools"
    mkdir -p "$HOME/storage/shared/Backups" 2>/dev/null
    
    # Setup cron if available
    if command -v crond &> /dev/null; then
        crond 2>/dev/null || true
        success_message "Cron daemon started"
    fi
    
    success_message "Post-installation setup completed"
}

show_completion_message() {
    echo
    print_colored "$GREEN" "🎉 Installation completed successfully!"
    echo
    print_colored "$WHITE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_colored "$CYAN" "📋 How to use your new Termux Scripts:"
    echo
    print_colored "$YELLOW" "Method 1 - Direct commands (recommended):"
    print_colored "$GREEN" "  termux-scripts     # Access all scripts via menu"
    print_colored "$GREEN" "  termux-monitor     # System monitoring"
    print_colored "$GREEN" "  termux-backup      # Automated backup"
    print_colored "$GREEN" "  termux-dev         # Development tools"
    print_colored "$GREEN" "  termux-network     # Network utilities"
    print_colored "$GREEN" "  termux-schedule    # Task scheduler"
    echo
    print_colored "$YELLOW" "Method 2 - Short aliases:"
    print_colored "$GREEN" "  tsscripts          # Script manager"
    print_colored "$GREEN" "  tsmon              # System monitor"
    print_colored "$GREEN" "  tsbackup           # Auto backup"
    print_colored "$GREEN" "  tsdev              # Development tools"
    print_colored "$GREEN" "  tsnet              # Network tools"
    echo
    print_colored "$YELLOW" "Method 3 - Traditional way:"
    print_colored "$GREEN" "  cd ~/termux-command && ./script-manager.sh"
    echo
    print_colored "$WHITE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_colored "$CYAN" "📖 Documentation:"
    print_colored "$GREEN" "  tshelp             # View complete command reference"
    print_colored "$GREEN" "  cat ~/termux-scripts/README.md"
    echo
    print_colored "$CYAN" "📁 Script location: ~/termux-command/"
    print_colored "$CYAN" "🔗 Commands available globally via ~/.local/bin/"
    echo
    print_colored "$YELLOW" "⚠️  Important: Restart your terminal or run 'source ~/.bashrc' to activate aliases"
    print_colored "$WHITE" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    print_colored "$PURPLE" "🚀 Quick start: Run 'termux-scripts' to get started!"
}

# Main installation process
main() {
    print_banner
    
    print_colored "$WHITE" "This installer will:"
    echo "  • Download all Termux scripts from GitHub"
    echo "  • Install required dependencies"
    echo "  • Create global command shortcuts"
    echo "  • Set up convenient aliases"
    echo "  • Configure storage permissions"
    echo
    
    echo -n "Proceed with installation? (y/N): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_colored "$YELLOW" "Installation cancelled"
        exit 0
    fi
    
    echo
    step_message "Starting installation..."
    
    check_requirements
    download_scripts
    make_executable
    create_symlinks
    create_aliases
    install_dependencies
    setup_storage
    post_install_setup
    
    show_completion_message
}

# Show help
show_help() {
    cat << EOF
Termux Scripts Auto-Installer

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -u, --update        Update existing installation
    -r, --remove        Remove installation
    --no-deps           Skip dependency installation
    --no-storage        Skip storage setup

Examples:
    $0                  # Full installation
    $0 --update         # Update scripts only
    $0 --remove         # Uninstall everything

EOF
}

update_installation() {
    print_colored "$BLUE" "🔄 Updating Termux Scripts..."
    
    if [ ! -d "$INSTALL_DIR" ]; then
        error_message "Installation not found. Run installer without --update flag."
    fi
    
    cd "$INSTALL_DIR" || error_message "Failed to access installation directory"
    
    if [ -d ".git" ]; then
        git pull origin main || error_message "Failed to update via git"
    else
        warning_message "Not a git installation. Re-downloading..."
        cd .. && rm -rf "$INSTALL_DIR"
        download_scripts
    fi
    
    make_executable
    success_message "Update completed"
}

remove_installation() {
    print_colored "$YELLOW" "🗑️  Removing Termux Scripts installation..."
    
    echo -n "Are you sure you want to remove the installation? (y/N): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_colored "$YELLOW" "Removal cancelled"
        exit 0
    fi
    
    # Remove installation directory
    rm -rf "$INSTALL_DIR"
    
    # Remove symlinks
    rm -f "$BIN_DIR"/termux-*
    
    # Remove aliases from bashrc
    if [ -f "$HOME/.bashrc" ]; then
        sed -i '/# ========================================/,/alias tsscan=/d' "$HOME/.bashrc" 2>/dev/null
    fi
    
    success_message "Installation removed"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -u|--update)
        update_installation
        exit 0
        ;;
    -r|--remove)
        remove_installation
        exit 0
        ;;
    --no-deps)
        SKIP_DEPS=true
        main
        ;;
    --no-storage)
        SKIP_STORAGE=true
        main
        ;;
    *)
        main
        ;;
esac