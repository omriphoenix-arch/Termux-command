#!/data/data/com.termux/files/usr/bin/bash
# Script Manager - Easy access to all Termux scripts

echo "🚀 TERMUX SCRIPT MANAGER"
echo "========================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to make script executable
make_executable() {
    local script="$1"
    if [ -f "$script" ] && [ ! -x "$script" ]; then
        chmod +x "$script"
        echo "✅ Made executable: $(basename "$script")"
    fi
}

# Function to run script with error handling
run_script() {
    local script="$1"
    local script_path="$SCRIPT_DIR/$script"
    
    if [ -f "$script_path" ]; then
        make_executable "$script_path"
        echo ""
        echo "🚀 Running: $script"
        echo "===================="
        bash "$script_path"
        echo ""
        echo "✅ Script completed: $script"
        read -p "Press Enter to continue..."
    else
        echo "❌ Script not found: $script"
    fi
}

# Function to show script info
show_script_info() {
    local script="$1"
    local script_path="$SCRIPT_DIR/$script"
    
    if [ -f "$script_path" ]; then
        echo ""
        echo "📋 Script Information: $script"
        echo "================================"
        
        # Extract description from script comments
        grep -m 3 "^# " "$script_path" | sed 's/^# //'
        
        echo ""
        echo "📁 Location: $script_path"
        echo "📏 Size: $(ls -lh "$script_path" | awk '{print $5}')"
        echo "📅 Modified: $(ls -l "$script_path" | awk '{print $6, $7, $8}')"
        echo "🔐 Permissions: $(ls -l "$script_path" | awk '{print $1}')"
        
        echo ""
        read -p "📖 View script content? (y/n): " view_content
        if [[ $view_content =~ ^[Yy]$ ]]; then
            less "$script_path"
        fi
    else
        echo "❌ Script not found: $script"
    fi
}

# Make all scripts executable on first run
echo "🔧 Setting up scripts..."
for script in "$SCRIPT_DIR"/*.sh; do
    if [ -f "$script" ] && [ "$(basename "$script")" != "$(basename "${BASH_SOURCE[0]}")" ]; then
        make_executable "$script"
    fi
done

# Main menu loop
while true; do
    clear
    echo "🚀 TERMUX SCRIPT MANAGER"
    echo "========================"
    echo "📅 $(date)"
    echo "📁 Script Directory: $SCRIPT_DIR"
    echo ""
    
    echo "🔧 SYSTEM & MAINTENANCE:"
    echo "1.  📊 system-info.sh      - Show detailed system information"
    echo "2.  🧹 cleanup.sh          - Clean temporary files and caches"
    echo "3.  📦 update-all.sh       - Update all packages and dependencies"
    echo "4.  🔋 battery-monitor.sh  - Monitor battery status and usage"
    echo ""
    
    echo "⚙️ SETUP & CONFIGURATION:"
    echo "5.  🚀 install-essentials.sh - Install essential packages"
    echo "6.  💻 dev-setup.sh         - Set up development environment"
    echo ""
    
    echo "🌐 NETWORKING & SECURITY:"
    echo "7.  🌐 network-scan.sh      - Scan local network for devices"
    echo "8.  🔐 password-gen.sh      - Generate secure passwords"
    echo "9.  🌤️ weather.sh           - Get weather information"
    echo ""
    
    echo "📁 UTILITIES:"
    echo "10. 📁 file-organizer.sh    - Organize files by type and date"
    echo "11. 📱 qr-generator.sh      - Generate QR codes for various purposes"
    echo "12. ⚡ quick-utils.sh       - Quick utility functions (compress, extract, backup)"
    echo ""
    
    echo "🎬 MEDIA & CONTENT:"
    echo "13. 📺 youtube-dl.sh        - Download YouTube videos and audio"
    echo "14. 🎬 media-converter.sh   - Convert audio, video, and images"
    echo "15. 📝 text-processor.sh    - Advanced text manipulation and processing"
    echo ""
    
    echo "🛠️ MANAGER OPTIONS:"
    echo "16. ℹ️  Show script information"
    echo "17. 🔄 Reload script manager"
    echo "18. 📝 Edit scripts directory in editor"
    echo "19. 🏠 Open scripts directory"
    echo "20. 📋 Create new script template"
    echo ""
    echo "0.  🚪 Exit"
    echo ""
    
    read -p "Select option (0-16): " choice
    
    case $choice in
        1) run_script "system-info.sh" ;;
        2) run_script "cleanup.sh" ;;
        3) run_script "update-all.sh" ;;
        4) run_script "battery-monitor.sh" ;;
        5) run_script "install-essentials.sh" ;;
        6) run_script "dev-setup.sh" ;;
        7) run_script "network-scan.sh" ;;
        8) run_script "password-gen.sh" ;;
        9) run_script "weather.sh" ;;
        10) run_script "file-organizer.sh" ;;
        11) run_script "qr-generator.sh" ;;
        12) run_script "quick-utils.sh" ;;
        13) run_script "youtube-dl.sh" ;;
        14) run_script "media-converter.sh" ;;
        15) run_script "text-processor.sh" ;;
        
        16)
            echo ""
            echo "📋 Available Scripts:"
            echo "===================="
            ls -1 "$SCRIPT_DIR"/*.sh | while read script; do
                echo "  $(basename "$script")"
            done
            echo ""
            read -p "Enter script name to view info: " script_name
            if [[ "$script_name" != *.sh ]]; then
                script_name="$script_name.sh"
            fi
            show_script_info "$script_name"
            ;;
            
        17)
            echo "🔄 Reloading script manager..."
            exec "$0"
            ;;
            
        18)
            if command -v vim >/dev/null 2>&1; then
                vim "$SCRIPT_DIR"
            elif command -v nano >/dev/null 2>&1; then
                nano "$SCRIPT_DIR"
            else
                echo "📝 No text editor found. Install vim or nano:"
                echo "pkg install vim nano"
            fi
            ;;
            
        19)
            echo "📁 Opening scripts directory..."
            cd "$SCRIPT_DIR" && pwd && ls -la
            echo ""
            echo "🎯 You are now in the scripts directory"
            echo "   Use 'ls' to list files, 'cd' to navigate"
            bash
            ;;
            
        20)
            echo ""
            read -p "📝 Enter new script name (without .sh): " new_script
            if [ -n "$new_script" ]; then
                new_script_path="$SCRIPT_DIR/$new_script.sh"
                cat > "$new_script_path" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# New Script Template

echo "🚀 NEW SCRIPT"
echo "============="

# Your script code here
echo "Hello from $new_script!"

# Add your functions and logic below
main() {
    echo "🎯 Main function executed"
}

# Run main function
main "$@"

echo "✅ Script completed successfully!"
EOF
                chmod +x "$new_script_path"
                echo "✅ Created new script: $new_script_path"
                
                read -p "📝 Edit now? (y/n): " edit_now
                if [[ $edit_now =~ ^[Yy]$ ]]; then
                    ${EDITOR:-nano} "$new_script_path"
                fi
            else
                echo "❌ No script name provided"
            fi
            ;;
            
        0)
            echo ""
            echo "👋 Thank you for using Termux Script Manager!"
            echo "🎯 All scripts are available in: $SCRIPT_DIR"
            echo "💡 You can run them individually or use this manager"
            echo ""
            echo "📝 Quick Access Tips:"
            echo "   - Add scripts directory to PATH for global access"
            echo "   - Create aliases for frequently used scripts"
            echo "   - Use 'find' to locate scripts: find ~ -name '*.sh'"
            echo ""
            echo "✨ Happy scripting!"
            exit 0
            ;;
            
        *)
            echo "❌ Invalid option. Please select 0-20."
            read -p "Press Enter to continue..."
            ;;
    esac
done