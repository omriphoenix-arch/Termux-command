#!/data/data/com.termux/files/usr/bin/bash
# Termux Cleanup Script - Clean temporary files and caches

echo "🧹 TERMUX CLEANUP UTILITY"
echo "========================="

cleanup_size=0

# Function to calculate size and add to total
calculate_size() {
    if [ -d "$1" ] || [ -f "$1" ]; then
        size=$(du -sb "$1" 2>/dev/null | cut -f1)
        if [ -n "$size" ]; then
            cleanup_size=$((cleanup_size + size))
            echo "  📁 $1: $(numfmt --to=iec $size)"
        fi
    fi
}

# Function to safely remove files/directories
safe_remove() {
    if [ -e "$1" ]; then
        calculate_size "$1"
        rm -rf "$1" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "  ✅ Cleaned: $1"
        else
            echo "  ❌ Failed to clean: $1"
        fi
    fi
}

echo ""
echo "🔍 Scanning for files to clean..."

# Package manager cache
echo ""
echo "📦 Cleaning package cache..."
safe_remove "$PREFIX/var/cache/apt/archives/*.deb"
safe_remove "$PREFIX/var/lib/apt/lists/*"

# Temporary files
echo ""
echo "🗂️ Cleaning temporary files..."
safe_remove "/tmp/*"
safe_remove "$HOME/.cache"
safe_remove "$PREFIX/tmp/*"

# Python cache (if Python is installed)
if command -v python >/dev/null 2>&1; then
    echo ""
    echo "🐍 Cleaning Python cache..."
    find "$HOME" -name "*.pyc" -type f -delete 2>/dev/null
    find "$HOME" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null
    safe_remove "$HOME/.pip/cache"
fi

# Node.js cache (if Node.js is installed)
if command -v npm >/dev/null 2>&1; then
    echo ""
    echo "📦 Cleaning Node.js cache..."
    npm cache clean --force 2>/dev/null
    safe_remove "$HOME/.npm/_cacache"
fi

# Log files
echo ""
echo "📋 Cleaning log files..."
safe_remove "$PREFIX/var/log/*.log"
safe_remove "$HOME/.bash_history.bak"

# Vim/Nano backup files
echo ""
echo "📝 Cleaning editor backup files..."
find "$HOME" -name "*~" -type f -delete 2>/dev/null
find "$HOME" -name "*.swp" -type f -delete 2>/dev/null
find "$HOME" -name ".*.swp" -type f -delete 2>/dev/null

# Downloads cleanup (optional)
echo ""
read -p "🗂️ Clean Downloads folder? (y/n): " clean_downloads
if [[ $clean_downloads =~ ^[Yy]$ ]]; then
    if [ -d "/storage/emulated/0/Download" ]; then
        echo "Listing files in Downloads older than 30 days:"
        find "/storage/emulated/0/Download" -type f -mtime +30 -ls 2>/dev/null
        read -p "Delete these old files? (y/n): " confirm_delete
        if [[ $confirm_delete =~ ^[Yy]$ ]]; then
            find "/storage/emulated/0/Download" -type f -mtime +30 -delete 2>/dev/null
            echo "✅ Old download files cleaned"
        fi
    else
        echo "Downloads folder not accessible"
    fi
fi

# Git repositories cleanup
echo ""
echo "🔄 Cleaning Git repositories..."
find "$HOME" -name ".git" -type d -exec bash -c 'cd "{}" && git gc --prune=now' \; 2>/dev/null

# Cleanup broken symbolic links
echo ""
echo "🔗 Removing broken symbolic links..."
find "$HOME" -xtype l -delete 2>/dev/null

# Package manager cleanup
echo ""
echo "📦 Running package manager cleanup..."
pkg autoclean 2>/dev/null
pkg autoremove -y 2>/dev/null

# Update package lists
echo ""
echo "🔄 Updating package lists..."
pkg update -y >/dev/null 2>&1

# Show final statistics
echo ""
echo "📊 CLEANUP SUMMARY"
echo "=================="
if [ $cleanup_size -gt 0 ]; then
    echo "💾 Space freed: $(numfmt --to=iec $cleanup_size)"
else
    echo "💾 Space freed: Minimal (cached files cleaned)"
fi

echo ""
echo "📁 Current disk usage:"
df -h "$PREFIX" | tail -1

echo ""
echo "✅ Cleanup completed successfully!"
echo ""
echo "💡 Tips:"
echo "   - Run this script weekly to keep your system clean"
echo "   - Use 'pkg autoclean' regularly to clean package cache"
echo "   - Consider using 'ncdu' to find large files: ncdu $HOME"