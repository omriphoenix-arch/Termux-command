#!/data/data/com.termux/files/usr/bin/bash
# Essential packages installer for Termux
# Run this first to set up your Termux environment

echo "🚀 Installing essential Termux packages..."
echo "========================================"

# Update package lists
echo "📦 Updating package lists..."
pkg update -y

# Install essential packages
echo "🔧 Installing essential tools..."
packages=(
    "curl"          # Download files from internet
    "wget"          # Alternative download tool
    "git"           # Version control
    "vim"           # Text editor
    "nano"          # Simple text editor
    "openssh"       # SSH client/server
    "rsync"         # File synchronization
    "zip"           # Compression utility
    "unzip"         # Extract zip files
    "tar"           # Archive utility
    "grep"          # Text search
    "sed"           # Stream editor
    "awk"           # Text processing
    "jq"            # JSON processor
    "tree"          # Directory tree viewer
    "htop"          # System monitor
    "ncdu"          # Disk usage analyzer
    "termux-tools"  # Termux utilities
    "termux-api"    # Android API access
)

for package in "${packages[@]}"; do
    echo "Installing $package..."
    pkg install -y "$package"
done

# Install programming languages (optional)
echo "🐍 Installing programming languages..."
read -p "Install Python? (y/n): " install_python
if [[ $install_python =~ ^[Yy]$ ]]; then
    pkg install -y python python-pip
    pip install --upgrade pip
    echo "Python installed successfully!"
fi

read -p "Install Node.js? (y/n): " install_node
if [[ $install_node =~ ^[Yy]$ ]]; then
    pkg install -y nodejs npm
    echo "Node.js installed successfully!"
fi

read -p "Install Golang? (y/n): " install_go
if [[ $install_go =~ ^[Yy]$ ]]; then
    pkg install -y golang
    echo "Golang installed successfully!"
fi

# Setup storage access
echo "📱 Setting up storage access..."
termux-setup-storage

echo ""
echo "✅ Essential packages installed successfully!"
echo "📝 Next steps:"
echo "   - Run 'termux-setup-storage' to access Android storage"
echo "   - Check other scripts in this collection"
echo "   - Consider running 'dev-setup.sh' for development tools"
echo ""
echo "🎉 Your Termux environment is ready!"