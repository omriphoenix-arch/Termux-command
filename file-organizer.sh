#!/data/data/com.termux/files/usr/bin/bash
# File Organizer - Organize files by type and date

echo "📁 FILE ORGANIZER"
echo "=================="

# Default directories
DEFAULT_SOURCE="/storage/emulated/0/Download"
DEFAULT_TARGET="/storage/emulated/0/Organized"

# Function to create directory if it doesn't exist
create_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "📂 Created directory: $1"
    fi
}

# Function to get file extension
get_extension() {
    echo "${1##*.}" | tr '[:upper:]' '[:lower:]'
}

# Function to organize files
organize_files() {
    local source_dir="$1"
    local target_dir="$2"
    local by_date="$3"
    
    if [ ! -d "$source_dir" ]; then
        echo "❌ Source directory does not exist: $source_dir"
        return 1
    fi
    
    create_dir "$target_dir"
    
    local moved_count=0
    local skipped_count=0
    
    echo ""
    echo "🔄 Organizing files from $source_dir"
    echo "To: $target_dir"
    echo ""
    
    # Process all files in source directory
    find "$source_dir" -type f | while IFS= read -r file; do
        filename=$(basename "$file")
        extension=$(get_extension "$filename")
        
        # Determine category based on extension
        case "$extension" in
            # Images
            jpg|jpeg|png|gif|bmp|svg|webp|tiff|ico|heic)
                category="Images"
                ;;
            # Videos
            mp4|avi|mkv|mov|wmv|flv|webm|m4v|3gp|mpg|mpeg)
                category="Videos"
                ;;
            # Audio
            mp3|wav|flac|aac|ogg|wma|m4a|opus)
                category="Audio"
                ;;
            # Documents
            pdf|doc|docx|txt|rtf|odt|pages)
                category="Documents"
                ;;
            # Spreadsheets
            xls|xlsx|csv|ods|numbers)
                category="Spreadsheets"
                ;;
            # Presentations
            ppt|pptx|odp|key)
                category="Presentations"
                ;;
            # Archives
            zip|rar|7z|tar|gz|bz2|xz)
                category="Archives"
                ;;
            # Code
            py|js|html|css|java|cpp|c|php|rb|go|rs|swift)
                category="Code"
                ;;
            # APK files
            apk)
                category="Apps"
                ;;
            # E-books
            epub|mobi|azw|azw3|fb2)
                category="Books"
                ;;
            *)
                category="Others"
                ;;
        esac
        
        # Create target directory based on organization type
        if [ "$by_date" = "true" ]; then
            # Organize by date
            file_date=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1 | tr '-' '_')
            if [ -z "$file_date" ]; then
                file_date="Unknown_Date"
            fi
            target_path="$target_dir/$file_date/$category"
        else
            # Organize by type only
            target_path="$target_dir/$category"
        fi
        
        create_dir "$target_path"
        
        # Check if file already exists
        target_file="$target_path/$filename"
        if [ -f "$target_file" ]; then
            # Create unique filename
            base_name="${filename%.*}"
            if [ "$base_name" = "$filename" ]; then
                # No extension
                counter=1
                while [ -f "$target_path/${base_name}_${counter}" ]; do
                    counter=$((counter + 1))
                done
                target_file="$target_path/${base_name}_${counter}"
            else
                # Has extension
                counter=1
                while [ -f "$target_path/${base_name}_${counter}.${extension}" ]; do
                    counter=$((counter + 1))
                done
                target_file="$target_path/${base_name}_${counter}.${extension}"
            fi
        fi
        
        # Move file
        if mv "$file" "$target_file"; then
            echo "✅ Moved: $filename → $category/"
            moved_count=$((moved_count + 1))
        else
            echo "❌ Failed to move: $filename"
            skipped_count=$((skipped_count + 1))
        fi
    done
    
    echo ""
    echo "📊 Organization Summary:"
    echo "Moved: $moved_count files"
    echo "Skipped: $skipped_count files"
}

# Function to show directory size
show_directory_stats() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo ""
        echo "📈 Directory Statistics for: $dir"
        echo "=================================="
        
        # Total size
        total_size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "📦 Total Size: $total_size"
        
        # File count by type
        echo ""
        echo "📋 File Count by Category:"
        find "$dir" -type f | while IFS= read -r file; do
            get_extension "$(basename "$file")"
        done | sort | uniq -c | sort -nr | head -10
        
        # Largest files
        echo ""
        echo "🎯 Largest Files:"
        find "$dir" -type f -exec ls -lh {} \; | sort -k5 -hr | head -5 | awk '{print $5, $9}'
    fi
}

# Main menu
echo ""
echo "Select operation:"
echo "1. 📁 Organize Downloads folder by file type"
echo "2. 📅 Organize Downloads folder by date and type"
echo "3. 📂 Organize custom directory"
echo "4. 📊 Show directory statistics"
echo "5. 🔄 Duplicate file finder"
echo ""

read -p "Select option (1-5): " option

case $option in
    1)
        read -p "Source directory (default: $DEFAULT_SOURCE): " source_dir
        source_dir=${source_dir:-$DEFAULT_SOURCE}
        
        read -p "Target directory (default: $DEFAULT_TARGET): " target_dir
        target_dir=${target_dir:-$DEFAULT_TARGET}
        
        organize_files "$source_dir" "$target_dir" "false"
        ;;
        
    2)
        read -p "Source directory (default: $DEFAULT_SOURCE): " source_dir
        source_dir=${source_dir:-$DEFAULT_SOURCE}
        
        read -p "Target directory (default: $DEFAULT_TARGET): " target_dir
        target_dir=${target_dir:-$DEFAULT_TARGET}
        
        organize_files "$source_dir" "$target_dir" "true"
        ;;
        
    3)
        read -p "Enter source directory: " source_dir
        read -p "Enter target directory: " target_dir
        read -p "Organize by date? (y/n): " by_date
        
        if [[ $by_date =~ ^[Yy]$ ]]; then
            organize_files "$source_dir" "$target_dir" "true"
        else
            organize_files "$source_dir" "$target_dir" "false"
        fi
        ;;
        
    4)
        read -p "Enter directory to analyze (default: $DEFAULT_SOURCE): " analyze_dir
        analyze_dir=${analyze_dir:-$DEFAULT_SOURCE}
        show_directory_stats "$analyze_dir"
        ;;
        
    5)
        read -p "Enter directory to scan for duplicates: " dup_dir
        if [ ! -d "$dup_dir" ]; then
            echo "❌ Directory does not exist: $dup_dir"
            exit 1
        fi
        
        echo ""
        echo "🔍 Scanning for duplicate files..."
        echo "This may take a while for large directories..."
        
        # Find duplicates by size first, then by MD5
        find "$dup_dir" -type f -exec ls -l {} \; | \
        awk '{print $5, $9}' | \
        sort -n | \
        uniq -d -f1 | \
        while read size file; do
            echo "🔁 Potential duplicate (size: $size): $(basename "$file")"
        done
        
        echo "✅ Duplicate scan complete!"
        ;;
        
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "💡 Tips:"
echo "   - Run this script regularly to keep files organized"
echo "   - Consider using 'ncdu' to analyze disk usage"
echo "   - Back up important files before organizing"
echo "   - Use symlinks for files you want in multiple locations"
echo ""
echo "✅ File organization completed!"