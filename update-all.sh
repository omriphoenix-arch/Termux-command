#!/data/data/com.termux/files/usr/bin/bash
# Update All Packages Script

echo "🔄 TERMUX UPDATE ALL"
echo "===================="

echo "📦 Starting comprehensive system update..."
echo ""

# Function to run command with error handling
run_command() {
    local cmd="$1"
    local description="$2"
    
    echo "🔄 $description..."
    if eval "$cmd"; then
        echo "✅ $description completed successfully"
    else
        echo "❌ $description failed"
        return 1
    fi
    echo ""
}

# Update package lists
run_command "pkg update" "Updating package lists"

# Upgrade all packages
run_command "pkg upgrade -y" "Upgrading all packages"

# Clean package cache
run_command "pkg autoclean" "Cleaning package cache"

# Remove orphaned packages
run_command "pkg autoremove -y" "Removing orphaned packages"

# Update Python packages (if Python is installed)
if command -v pip >/dev/null 2>&1; then
    echo "🐍 Updating Python packages..."
    pip list --outdated --format=freeze 2>/dev/null | cut -d'=' -f1 | xargs -I {} pip install --user --upgrade {} 2>/dev/null || echo "No Python packages to update"
    echo ""
fi

# Update Node.js packages (if npm is installed)
if command -v npm >/dev/null 2>&1; then
    echo "📦 Updating global Node.js packages..."
    npm update -g 2>/dev/null || echo "No global npm packages to update"
    echo ""
fi

# Update Go packages (if Go is installed and GOPATH exists)
if command -v go >/dev/null 2>&1 && [ -d "$HOME/go" ]; then
    echo "🐹 Updating Go packages..."
    go clean -modcache 2>/dev/null || echo "Go module cache cleaned"
    echo ""
fi

# Show final status
echo "📊 UPDATE SUMMARY"
echo "================="

# Show disk usage
echo "💾 Disk usage after update:"
df -h "$PREFIX" | tail -1

# Show package count
pkg_count=$(pkg list-installed 2>/dev/null | wc -l)
echo "📦 Total packages installed: $pkg_count"

# Check for remaining issues
echo ""
echo "🔍 System health check:"

# Check for broken packages
broken=$(pkg list-installed 2>&1 | grep -i "error\|broken" | wc -l)
if [ "$broken" -eq 0 ]; then
    echo "✅ No broken packages found"
else
    echo "⚠️ $broken potential issues found"
fi

# Check available space
available_space=$(df "$PREFIX" | tail -1 | awk '{print $4}')
if [ "$available_space" -lt 100000 ]; then  # Less than ~100MB
    echo "⚠️ Low disk space: $(df -h "$PREFIX" | tail -1 | awk '{print $4}') available"
    echo "   Consider running cleanup.sh"
else
    echo "✅ Sufficient disk space available"
fi

echo ""
echo "🎉 System update completed successfully!"
echo ""
echo "💡 Recommendations:"
echo "   - Restart Termux to ensure all changes take effect"
echo "   - Run 'cleanup.sh' if you need more disk space"
echo "   - Check for app updates in Google Play Store"
echo "   - Consider running this script weekly"
echo ""
echo "✨ Your Termux is now up to date!"