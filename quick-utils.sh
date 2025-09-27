#!/data/data/com.termux/files/usr/bin/bash
# Quick Utility Functions - Fast access to common tasks

# Function to compress files/directories
compress() {
    if [ -z "$1" ]; then
        echo "❌ Error: Please provide a file or directory to compress."
        echo "Usage: compress <file/directory> [output_name]"
        return 1
    fi
    
    local input="$1"
    local output="$2"
    
    if [ ! -e "$input" ]; then
        echo "❌ Error: '$input' not found."
        return 1
    fi
    
    # Auto-generate output name if not provided
    if [ -z "$output" ]; then
        output="${input%/}.tar.gz"
    fi
    
    echo "📦 Compressing '$input' to '$output'..."
    
    if [ -d "$input" ]; then
        tar -czf "$output" -C "$(dirname "$input")" "$(basename "$input")"
    else
        tar -czf "$output" "$input"
    fi
    
    if [ $? -eq 0 ]; then
        local original_size=$(du -sh "$input" | cut -f1)
        local compressed_size=$(du -sh "$output" | cut -f1)
        echo "✅ Compression completed!"
        echo "📊 Original: $original_size → Compressed: $compressed_size"
    else
        echo "❌ Compression failed!"
        return 1
    fi
}

# Function to extract archives
extract() {
    if [ -z "$1" ]; then
        echo "❌ Error: Please provide an archive to extract."
        echo "Usage: extract <archive_file> [output_directory]"
        return 1
    fi
    
    local archive="$1"
    local output_dir="$2"
    
    if [ ! -f "$archive" ]; then
        echo "❌ Error: Archive '$archive' not found."
        return 1
    fi
    
    # Create output directory if specified
    if [ -n "$output_dir" ]; then
        mkdir -p "$output_dir"
        cd "$output_dir"
    fi
    
    echo "📂 Extracting '$archive'..."
    
    case "$archive" in
        *.tar.bz2) tar xjf "$archive" ;;
        *.tar.gz|*.tgz) tar xzf "$archive" ;;
        *.tar.xz) tar xJf "$archive" ;;
        *.tar) tar xf "$archive" ;;
        *.bz2) bunzip2 "$archive" ;;
        *.rar) unrar x "$archive" ;;
        *.gz) gunzip "$archive" ;;
        *.zip) unzip "$archive" ;;
        *.Z) uncompress "$archive" ;;
        *.7z) 7z x "$archive" ;;
        *) echo "❌ Unsupported archive format: $archive" && return 1 ;;
    esac
    
    if [ $? -eq 0 ]; then
        echo "✅ Extraction completed!"
    else
        echo "❌ Extraction failed!"
        return 1
    fi
}

# Function to quick backup
backup() {
    if [ -z "$1" ]; then
        echo "❌ Error: Please provide a file or directory to backup."
        echo "Usage: backup <file/directory> [backup_location]"
        return 1
    fi
    
    local source="$1"
    local backup_dir="$2"
    
    if [ ! -e "$source" ]; then
        echo "❌ Error: '$source' not found."
        return 1
    fi
    
    # Default backup location
    backup_dir=${backup_dir:-"/storage/emulated/0/Backups"}
    mkdir -p "$backup_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="$(basename "$source")_backup_$timestamp.tar.gz"
    local backup_path="$backup_dir/$backup_name"
    
    echo "💾 Creating backup of '$source'..."
    echo "📁 Backup location: $backup_path"
    
    if [ -d "$source" ]; then
        tar -czf "$backup_path" -C "$(dirname "$source")" "$(basename "$source")"
    else
        tar -czf "$backup_path" "$source"
    fi
    
    if [ $? -eq 0 ]; then
        local size=$(du -sh "$backup_path" | cut -f1)
        echo "✅ Backup created successfully!"
        echo "📦 Size: $size"
        echo "📍 Location: $backup_path"
    else
        echo "❌ Backup failed!"
        return 1
    fi
}

# Function to quick search
search() {
    if [ -z "$1" ]; then
        echo "❌ Error: Please provide a search term."
        echo "Usage: search <term> [directory] [file_type]"
        return 1
    fi
    
    local term="$1"
    local search_dir="$2"
    local file_type="$3"
    
    search_dir=${search_dir:-"."}
    
    echo "🔍 Searching for '$term' in '$search_dir'..."
    
    if [ -n "$file_type" ]; then
        find "$search_dir" -name "*.$file_type" -exec grep -l "$term" {} \; 2>/dev/null
    else
        find "$search_dir" -type f -exec grep -l "$term" {} \; 2>/dev/null
    fi
}

# Function to quick download
download() {
    if [ -z "$1" ]; then
        echo "❌ Error: Please provide a URL to download."
        echo "Usage: download <url> [output_file]"
        return 1
    fi
    
    local url="$1"
    local output="$2"
    local download_dir="/storage/emulated/0/Download"
    
    mkdir -p "$download_dir"
    
    if [ -z "$output" ]; then
        # Auto-generate filename from URL
        output="$download_dir/$(basename "$url")"
    elif [[ "$output" != /* ]]; then
        # Relative path, prepend download directory
        output="$download_dir/$output"
    fi
    
    echo "⬇️ Downloading from: $url"
    echo "📁 Saving to: $output"
    
    if command -v curl >/dev/null 2>&1; then
        curl -L -o "$output" "$url" --progress-bar
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$output" "$url"
    else
        echo "❌ Neither curl nor wget found!"
        echo "Install with: pkg install curl"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        local size=$(du -sh "$output" | cut -f1)
        echo "✅ Download completed!"
        echo "📦 Size: $size"
        echo "📍 Location: $output"
    else
        echo "❌ Download failed!"
        return 1
    fi
}

# Function to quick sync
sync_dirs() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "❌ Error: Please provide source and destination directories."
        echo "Usage: sync_dirs <source> <destination>"
        return 1
    fi
    
    local source="$1"
    local dest="$2"
    
    if [ ! -d "$source" ]; then
        echo "❌ Error: Source directory '$source' not found."
        return 1
    fi
    
    mkdir -p "$dest"
    
    echo "🔄 Syncing '$source' to '$dest'..."
    
    if command -v rsync >/dev/null 2>&1; then
        rsync -av --progress "$source/" "$dest/"
    else
        cp -r "$source/." "$dest/"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ Sync completed!"
    else
        echo "❌ Sync failed!"
        return 1
    fi
}

# Function to quick convert images
convert_img() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "❌ Error: Please provide input file and output format."
        echo "Usage: convert_img <input_image> <output_format> [quality]"
        echo "Formats: jpg, png, webp, gif"
        return 1
    fi
    
    local input="$1"
    local format="$2"
    local quality="$3"
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Image '$input' not found."
        return 1
    fi
    
    # Check if ImageMagick is available
    if ! command -v convert >/dev/null 2>&1; then
        echo "📦 ImageMagick not found. Installing..."
        pkg install -y imagemagick
    fi
    
    local output="${input%.*}.$format"
    quality=${quality:-85}
    
    echo "🖼️ Converting '$input' to '$output'..."
    
    if [ "$format" = "jpg" ] || [ "$format" = "jpeg" ]; then
        convert "$input" -quality "$quality" "$output"
    else
        convert "$input" "$output"
    fi
    
    if [ $? -eq 0 ]; then
        local original_size=$(du -sh "$input" | cut -f1)
        local converted_size=$(du -sh "$output" | cut -f1)
        echo "✅ Conversion completed!"
        echo "📊 Original: $original_size → Converted: $converted_size"
    else
        echo "❌ Conversion failed!"
        return 1
    fi
}

# Function to quick text processing
process_text() {
    if [ -z "$1" ]; then
        echo "❌ Error: Please provide operation and file."
        echo "Usage: process_text <operation> <file> [options]"
        echo "Operations: upper, lower, count, unique, sort, reverse"
        return 1
    fi
    
    local operation="$1"
    local file="$2"
    
    if [ ! -f "$file" ]; then
        echo "❌ Error: File '$file' not found."
        return 1
    fi
    
    echo "📝 Processing text file: $file"
    
    case "$operation" in
        upper)
            tr '[:lower:]' '[:upper:]' < "$file"
            ;;
        lower)
            tr '[:upper:]' '[:lower:]' < "$file"
            ;;
        count)
            echo "Lines: $(wc -l < "$file")"
            echo "Words: $(wc -w < "$file")"
            echo "Characters: $(wc -c < "$file")"
            ;;
        unique)
            sort "$file" | uniq
            ;;
        sort)
            sort "$file"
            ;;
        reverse)
            tac "$file"
            ;;
        *)
            echo "❌ Unknown operation: $operation"
            return 1
            ;;
    esac
}

# Main menu
echo "⚡ QUICK UTILITIES"
echo "=================="
echo ""
echo "Available functions:"
echo "1. 📦 compress <file/dir> [output]    - Compress files/directories"
echo "2. 📂 extract <archive> [output_dir]  - Extract various archives"
echo "3. 💾 backup <file/dir> [backup_dir]  - Quick backup with timestamp"
echo "4. 🔍 search <term> [dir] [filetype]  - Search for text in files"
echo "5. ⬇️ download <url> [output]         - Download files from URLs"
echo "6. 🔄 sync_dirs <source> <dest>       - Sync directories"
echo "7. 🖼️ convert_img <img> <format>      - Convert image formats"
echo "8. 📝 process_text <op> <file>        - Text processing operations"
echo ""

read -p "Enter function name to run: " func_name

case "$func_name" in
    compress)
        read -p "File/directory to compress: " input
        read -p "Output name (optional): " output
        compress "$input" "$output"
        ;;
    extract)
        read -p "Archive to extract: " archive
        read -p "Output directory (optional): " output_dir
        extract "$archive" "$output_dir"
        ;;
    backup)
        read -p "File/directory to backup: " source
        read -p "Backup location (optional): " backup_dir
        backup "$source" "$backup_dir"
        ;;
    search)
        read -p "Search term: " term
        read -p "Directory (default: current): " search_dir
        read -p "File type (optional): " file_type
        search "$term" "$search_dir" "$file_type"
        ;;
    download)
        read -p "URL to download: " url
        read -p "Output filename (optional): " output
        download "$url" "$output"
        ;;
    sync_dirs)
        read -p "Source directory: " source
        read -p "Destination directory: " dest
        sync_dirs "$source" "$dest"
        ;;
    convert_img)
        read -p "Input image: " input
        read -p "Output format (jpg/png/webp/gif): " format
        read -p "Quality (1-100, default: 85): " quality
        convert_img "$input" "$format" "$quality"
        ;;
    process_text)
        read -p "Operation (upper/lower/count/unique/sort/reverse): " operation
        read -p "Text file: " file
        process_text "$operation" "$file"
        ;;
    *)
        echo "💡 You can also call functions directly:"
        echo "   ./quick-utils.sh"
        echo "   Then use: compress myfile.txt"
        ;;
esac

echo ""
echo "⚡ Quick utility completed!"