# Termux Scripts Collection

This repository contains useful scripts for Termux on Android. Each script is designed to help with common tasks and automation.

## Scripts Overview

### System & Maintenance
- `system-info.sh` - Display detailed system information
- `cleanup.sh` - Clean up temporary files and caches
- `backup-termux.sh` - Backup Termux configuration and installed packages
- `update-all.sh` - Update all packages and clean up

### Development & Setup
- `dev-setup.sh` - Set up development environment (Python, Node.js, Git, etc.)
- `install-essentials.sh` - Install essential packages for Termux
- `ssh-setup.sh` - Set up SSH server and client

### Networking & Security
- `network-scan.sh` - Scan local network for devices
- `wifi-info.sh` - Display WiFi connection information
- `password-gen.sh` - Generate secure passwords
- `port-check.sh` - Check if specific ports are open

### File Management
- `file-organizer.sh` - Organize downloads and files by type
- `compress-files.sh` - Compress files and folders with different formats
- `sync-storage.sh` - Sync internal storage with Termux

### Utilities
- `weather.sh` - Get weather information for your location
- `qr-generator.sh` - Generate QR codes from text
- `battery-monitor.sh` - Monitor battery status and usage
- `quick-utils.sh` - Quick utility functions (compress, extract, backup, search)

### Media & Content
- `youtube-dl.sh` - Download YouTube videos and audio (like your yt-exc function)
- `media-converter.sh` - Convert audio, video, and images between formats
- `text-processor.sh` - Advanced text manipulation and processing

## Usage

Make scripts executable:
```bash
chmod +x script-name.sh
```

Run scripts:
```bash
./script-name.sh
```

Or add to PATH for global access:
```bash
cp script-name.sh $PREFIX/bin/script-name
```

## Requirements

Most scripts require basic Termux packages. Run `install-essentials.sh` first to set up your environment.