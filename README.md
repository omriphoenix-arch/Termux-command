# Termux Scripts Collection

A comprehensive collection of 21+ powerful scripts for Termux on Android. Automate your workflow, monitor your system, manage development environments, and much more!

## 🚀 Quick Installation

**One-command installation:**
```bash
curl -sL https://raw.githubusercontent.com/omriphoenix-arch/Termux-command/main/install.sh | bash
```

**Alternative installation:**
```bash
curl -sL https://raw.githubusercontent.com/omriphoenix-arch/Termux-command/main/quick-install.sh | bash
```

This will:
- ✅ Download all scripts automatically
- ✅ Install required dependencies  
- ✅ Create global command shortcuts
- ✅ Set up convenient aliases
- ✅ Configure storage permissions

## 📋 Available Commands After Installation

Once installed, you can use these commands from anywhere in Termux:

### 🎯 Quick Access Commands
```bash
termux-scripts      # Main script manager (recommended)
termux-monitor      # Real-time system monitoring
termux-backup       # Automated backup solution
termux-dev          # Development tools & Git helper
termux-network      # Advanced networking utilities
termux-schedule     # Task scheduler & automation
```

### 📱 Short Aliases
```bash
tsscripts          # Script manager
tsmon              # System monitor  
tsbackup           # Auto backup
tsdev              # Development tools
tsnet              # Network tools
tssched            # Task scheduler
tsclean            # System cleanup
tsupdate           # System update
```

## 📖 Complete Script Collection (21 Scripts)

### 🔧 System & Maintenance
- `system-info.sh` - Display detailed system information
- `system-monitor.sh` - **NEW!** Real-time monitoring dashboard with alerts
- `cleanup.sh` - Clean up temporary files and caches
- `update-all.sh` - Update all packages and clean up
- `auto-backup.sh` - **NEW!** Automated backup solution with compression
- `battery-monitor.sh` - Monitor battery status and usage

### 💻 Development & Setup  
- `install-essentials.sh` - Install essential packages for Termux
- `dev-setup.sh` - Set up development environment (Python, Node.js, Git, etc.)
- `dev-tools.sh` - **NEW!** Advanced Git helper with project templates

### 🌐 Networking & Security
- `network-scan.sh` - Scan local network for devices
- `network-tools.sh` - **NEW!** Advanced networking utilities (WiFi analyzer, port scanner, SSL checker)
- `password-gen.sh` - Generate secure passwords
- `weather.sh` - Get weather information for your location

### 🤖 Automation & Scheduling
- `task-scheduler.sh` - **NEW!** Complete automation system with cron management

### 📁 File Management & Utilities
- `file-organizer.sh` - Organize downloads and files by type
- `quick-utils.sh` - Quick utility functions (compress, extract, backup, search)
- `qr-generator.sh` - Generate QR codes from text

### 🎵 Media & Content
- `youtube-dl.sh` - Download YouTube videos and audio
- `media-converter.sh` - Convert audio, video, and images between formats
- `text-processor.sh` - Advanced text manipulation and processing

### 🎛️ Management
- `script-manager.sh` - Central hub for all scripts

## 💡 Usage Examples

### After Installation - No Setup Required!
```bash
# System monitoring
termux-monitor              # Interactive dashboard
termux-monitor -c           # Continuous monitoring

# Development workflow  
termux-dev setup            # Setup dev environment
termux-dev init             # Create new project
termux-dev status           # Enhanced git status

# Network analysis
termux-network info         # Network information
termux-network wifi         # WiFi analyzer
termux-network scan         # Port scanner

# Automated backups
termux-backup               # Interactive backup
termux-backup --auto        # Automated backup

# Task automation
termux-schedule create      # Create scheduled task
termux-schedule wizard      # Automation templates
```

## 🔧 Manual Installation (Alternative)

If you prefer manual installation:

```bash
# Clone repository
git clone https://github.com/omriphoenix-arch/Termux-command.git
cd Termux-command

# Make scripts executable
chmod +x *.sh

# Run essentials installer
./install-essentials.sh

# Use script manager
./script-manager.sh
```

## 📚 Documentation

- **[COMMANDS.txt](COMMANDS.txt)** - Complete command reference with detailed usage examples
- **Individual script help** - Run any script with `-h` or `--help` flag
- **Built-in help** - Use `tshelp` command after installation

## 🔄 Updates

Update your installation anytime:
```bash
curl -sL https://raw.githubusercontent.com/omriphoenix-arch/Termux-command/main/install.sh | bash -s -- --update
```

Or manually:
```bash
cd ~/termux-scripts && git pull
```

## 🗑️ Uninstall

Remove the installation completely:
```bash
curl -sL https://raw.githubusercontent.com/omriphoenix-arch/Termux-command/main/install.sh | bash -s -- --remove
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Termux community for inspiration
- Contributors and testers
- Everyone who uses and improves these scripts

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/omriphoenix-arch/Termux-command/issues)
- **Discussions**: [GitHub Discussions](https://github.com/omriphoenix-arch/Termux-command/discussions)

---

⭐ **Star this repository if you find it helpful!** ⭐

Or add to PATH for global access:
```bash
cp script-name.sh $PREFIX/bin/script-name
```

## Requirements

Most scripts require basic Termux packages. Run `install-essentials.sh` first to set up your environment.