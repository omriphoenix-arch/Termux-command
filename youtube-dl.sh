#!/data/data/com.termux/files/usr/bin/bash
# YouTube Downloader - Download videos and audio from YouTube

echo "📺 YOUTUBE DOWNLOADER"
echo "===================="

# Check if yt-dlp is installed
if ! command -v yt-dlp >/dev/null 2>&1; then
    echo "📦 yt-dlp not found. Installing..."
    pip install --user yt-dlp
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install yt-dlp"
        echo "💡 Try: pip install yt-dlp"
        exit 1
    fi
    echo "✅ yt-dlp installed successfully!"
fi

# Setup directories
DOWNLOAD_DIR="/storage/emulated/0/Download"
MUSIC_DIR="/storage/emulated/0/Music"
VIDEO_DIR="/storage/emulated/0/Videos"

mkdir -p "$MUSIC_DIR" "$VIDEO_DIR"

# Function to download audio only (like your yt-exc)
yt_audio() {
    local url="$1"
    local output_dir="$2"
    
    if [ -z "$url" ]; then
        echo "❌ Error: Please provide a YouTube link."
        echo "Usage: yt_audio \"<link>\" [output_directory]"
        return 1
    fi
    
    output_dir=${output_dir:-"$MUSIC_DIR"}
    
    echo "🎵 Downloading audio from: $url"
    echo "📁 Output directory: $output_dir"
    
    yt-dlp -x \
        --audio-format mp3 \
        --audio-quality 0 \
        --add-metadata \
        --embed-thumbnail \
        -o "$output_dir/%(playlist)s/%(title)s.%(ext)s" \
        "$url"
    
    if [ $? -eq 0 ]; then
        echo "✅ Audio download completed!"
    else
        echo "❌ Download failed!"
        return 1
    fi
}

# Function to download video
yt_video() {
    local url="$1"
    local quality="$2"
    local output_dir="$3"
    
    if [ -z "$url" ]; then
        echo "❌ Error: Please provide a YouTube link."
        echo "Usage: yt_video \"<link>\" [quality] [output_directory]"
        return 1
    fi
    
    quality=${quality:-"best"}
    output_dir=${output_dir:-"$VIDEO_DIR"}
    
    echo "📹 Downloading video from: $url"
    echo "🎯 Quality: $quality"
    echo "📁 Output directory: $output_dir"
    
    yt-dlp -f "$quality" \
        --add-metadata \
        --embed-thumbnail \
        --embed-subs \
        -o "$output_dir/%(playlist)s/%(title)s.%(ext)s" \
        "$url"
    
    if [ $? -eq 0 ]; then
        echo "✅ Video download completed!"
    else
        echo "❌ Download failed!"
        return 1
    fi
}

# Function to download playlist
yt_playlist() {
    local url="$1"
    local type="$2"
    local output_dir="$3"
    
    if [ -z "$url" ]; then
        echo "❌ Error: Please provide a YouTube playlist link."
        echo "Usage: yt_playlist \"<link>\" [audio|video] [output_directory]"
        return 1
    fi
    
    type=${type:-"audio"}
    
    if [ "$type" = "audio" ]; then
        output_dir=${output_dir:-"$MUSIC_DIR"}
        echo "🎵 Downloading playlist audio from: $url"
        
        yt-dlp -x \
            --audio-format mp3 \
            --audio-quality 0 \
            --add-metadata \
            --embed-thumbnail \
            --yes-playlist \
            -o "$output_dir/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s" \
            "$url"
    else
        output_dir=${output_dir:-"$VIDEO_DIR"}
        echo "📹 Downloading playlist videos from: $url"
        
        yt-dlp -f "best" \
            --add-metadata \
            --embed-thumbnail \
            --embed-subs \
            --yes-playlist \
            -o "$output_dir/%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s" \
            "$url"
    fi
    
    if [ $? -eq 0 ]; then
        echo "✅ Playlist download completed!"
    else
        echo "❌ Download failed!"
        return 1
    fi
}

# Function to get video info
yt_info() {
    local url="$1"
    
    if [ -z "$url" ]; then
        echo "❌ Error: Please provide a YouTube link."
        echo "Usage: yt_info \"<link>\""
        return 1
    fi
    
    echo "ℹ️ Getting video information..."
    
    yt-dlp --dump-json "$url" | jq -r '
        "📺 Title: " + .title,
        "👤 Channel: " + .uploader,
        "⏱️ Duration: " + (.duration | tostring) + " seconds",
        "📅 Upload Date: " + .upload_date,
        "👀 Views: " + (.view_count | tostring),
        "👍 Likes: " + (.like_count | tostring // "N/A"),
        "📝 Description: " + (.description | split("\n")[0])
    ' 2>/dev/null || {
        echo "📋 Basic info (jq not available):"
        yt-dlp --get-title --get-uploader --get-duration --get-upload-date "$url"
    }
}

# Function to list available formats
yt_formats() {
    local url="$1"
    
    if [ -z "$url" ]; then
        echo "❌ Error: Please provide a YouTube link."
        echo "Usage: yt_formats \"<link>\""
        return 1
    fi
    
    echo "📋 Available formats for: $url"
    echo "================================="
    
    yt-dlp -F "$url"
}

# Function to download with custom format
yt_custom() {
    local url="$1"
    local format="$2"
    local output_dir="$3"
    
    if [ -z "$url" ] || [ -z "$format" ]; then
        echo "❌ Error: Please provide URL and format."
        echo "Usage: yt_custom \"<link>\" \"<format_id>\" [output_directory]"
        echo "💡 Use yt_formats to see available formats"
        return 1
    fi
    
    output_dir=${output_dir:-"$DOWNLOAD_DIR"}
    
    echo "🎯 Downloading with format: $format"
    echo "📁 Output directory: $output_dir"
    
    yt-dlp -f "$format" \
        --add-metadata \
        -o "$output_dir/%(title)s.%(ext)s" \
        "$url"
    
    if [ $? -eq 0 ]; then
        echo "✅ Custom format download completed!"
    else
        echo "❌ Download failed!"
        return 1
    fi
}

# Main menu
echo ""
echo "Choose download option:"
echo "1. 🎵 Audio only (MP3) - like your yt-exc"
echo "2. 📹 Video (best quality)"
echo "3. 📋 Playlist (audio)"
echo "4. 📋 Playlist (video)"
echo "5. ℹ️ Video information"
echo "6. 📊 Available formats"
echo "7. 🎯 Custom format download"
echo "8. 🔗 Batch download from file"
echo ""

read -p "Select option (1-8): " option

case $option in
    1)
        echo ""
        read -p "📺 Enter YouTube URL: " url
        read -p "📁 Output directory (default: $MUSIC_DIR): " output_dir
        yt_audio "$url" "$output_dir"
        ;;
        
    2)
        echo ""
        read -p "📺 Enter YouTube URL: " url
        echo "Quality options: best, worst, 720p, 480p, 360p"
        read -p "🎯 Quality (default: best): " quality
        read -p "📁 Output directory (default: $VIDEO_DIR): " output_dir
        yt_video "$url" "$quality" "$output_dir"
        ;;
        
    3)
        echo ""
        read -p "📋 Enter YouTube playlist URL: " url
        read -p "📁 Output directory (default: $MUSIC_DIR): " output_dir
        yt_playlist "$url" "audio" "$output_dir"
        ;;
        
    4)
        echo ""
        read -p "📋 Enter YouTube playlist URL: " url
        read -p "📁 Output directory (default: $VIDEO_DIR): " output_dir
        yt_playlist "$url" "video" "$output_dir"
        ;;
        
    5)
        echo ""
        read -p "📺 Enter YouTube URL: " url
        yt_info "$url"
        ;;
        
    6)
        echo ""
        read -p "📺 Enter YouTube URL: " url
        yt_formats "$url"
        ;;
        
    7)
        echo ""
        read -p "📺 Enter YouTube URL: " url
        echo "💡 First, let's see available formats:"
        yt_formats "$url"
        echo ""
        read -p "🎯 Enter format ID: " format
        read -p "📁 Output directory (default: $DOWNLOAD_DIR): " output_dir
        yt_custom "$url" "$format" "$output_dir"
        ;;
        
    8)
        echo ""
        read -p "📁 Enter file with URLs (one per line): " url_file
        if [ ! -f "$url_file" ]; then
            echo "❌ File not found: $url_file"
            exit 1
        fi
        
        echo "Download type:"
        echo "1. Audio only"
        echo "2. Video"
        read -p "Select (1-2): " batch_type
        
        line_num=1
        while IFS= read -r url; do
            if [ -n "$url" ] && [[ "$url" != \#* ]]; then
                echo ""
                echo "📥 Processing $line_num: $url"
                if [ "$batch_type" = "1" ]; then
                    yt_audio "$url"
                else
                    yt_video "$url"
                fi
                line_num=$((line_num + 1))
            fi
        done < "$url_file"
        
        echo "✅ Batch download completed!"
        ;;
        
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "📺 YouTube Download Complete!"
echo ""
echo "💡 Tips:"
echo "   - Use audio option for music (smaller files)"
echo "   - Check available formats for best quality"
echo "   - Playlist downloads preserve order"
echo "   - Files are organized by playlist name"
echo ""
echo "🎵 Enjoy your downloads!"