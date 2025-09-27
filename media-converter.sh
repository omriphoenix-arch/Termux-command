#!/data/data/com.termux/files/usr/bin/bash
# Media Converter - Convert audio, video, and images

echo "🎬 MEDIA CONVERTER"
echo "=================="

# Check for ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "📦 ffmpeg not found. Installing..."
    pkg install -y ffmpeg
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install ffmpeg"
        echo "💡 Try: pkg install ffmpeg"
        exit 1
    fi
    echo "✅ ffmpeg installed successfully!"
fi

# Function to convert audio
audio_convert() {
    local input="$1"
    local output_format="$2"
    local quality="$3"
    
    if [ -z "$input" ] || [ -z "$output_format" ]; then
        echo "❌ Error: Please provide input file and output format."
        echo "Usage: audio_convert <input> <format> [quality]"
        echo "Formats: mp3, wav, flac, aac, ogg, m4a"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    local output="${input%.*}.$output_format"
    quality=${quality:-"192k"}
    
    echo "🎵 Converting '$input' to '$output'..."
    echo "🎯 Quality: $quality"
    
    case "$output_format" in
        mp3)
            ffmpeg -i "$input" -b:a "$quality" "$output" -y
            ;;
        wav)
            ffmpeg -i "$input" -acodec pcm_s16le "$output" -y
            ;;
        flac)
            ffmpeg -i "$input" -acodec flac "$output" -y
            ;;
        aac)
            ffmpeg -i "$input" -c:a aac -b:a "$quality" "$output" -y
            ;;
        ogg)
            ffmpeg -i "$input" -c:a libvorbis -b:a "$quality" "$output" -y
            ;;
        m4a)
            ffmpeg -i "$input" -c:a aac -b:a "$quality" "$output" -y
            ;;
        *)
            echo "❌ Unsupported format: $output_format"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        local original_size=$(du -sh "$input" | cut -f1)
        local converted_size=$(du -sh "$output" | cut -f1)
        echo "✅ Audio conversion completed!"
        echo "📊 Original: $original_size → Converted: $converted_size"
    else
        echo "❌ Conversion failed!"
        return 1
    fi
}

# Function to convert video
video_convert() {
    local input="$1"
    local output_format="$2"
    local quality="$3"
    local resolution="$4"
    
    if [ -z "$input" ] || [ -z "$output_format" ]; then
        echo "❌ Error: Please provide input file and output format."
        echo "Usage: video_convert <input> <format> [quality] [resolution]"
        echo "Formats: mp4, avi, mkv, webm, mov"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    local output="${input%.*}.$output_format"
    quality=${quality:-"medium"}
    
    echo "📹 Converting '$input' to '$output'..."
    echo "🎯 Quality: $quality"
    
    local ffmpeg_opts=""
    
    # Set quality presets
    case "$quality" in
        low) ffmpeg_opts="-crf 28" ;;
        medium) ffmpeg_opts="-crf 23" ;;
        high) ffmpeg_opts="-crf 18" ;;
        *) ffmpeg_opts="-crf 23" ;;
    esac
    
    # Add resolution if specified
    if [ -n "$resolution" ]; then
        ffmpeg_opts+=" -vf scale=$resolution"
    fi
    
    case "$output_format" in
        mp4)
            ffmpeg -i "$input" -c:v libx264 -c:a aac $ffmpeg_opts "$output" -y
            ;;
        avi)
            ffmpeg -i "$input" -c:v libx264 -c:a mp3 $ffmpeg_opts "$output" -y
            ;;
        mkv)
            ffmpeg -i "$input" -c:v libx264 -c:a aac $ffmpeg_opts "$output" -y
            ;;
        webm)
            ffmpeg -i "$input" -c:v libvpx-vp9 -c:a libopus $ffmpeg_opts "$output" -y
            ;;
        mov)
            ffmpeg -i "$input" -c:v libx264 -c:a aac $ffmpeg_opts "$output" -y
            ;;
        *)
            echo "❌ Unsupported format: $output_format"
            return 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        local original_size=$(du -sh "$input" | cut -f1)
        local converted_size=$(du -sh "$output" | cut -f1)
        echo "✅ Video conversion completed!"
        echo "📊 Original: $original_size → Converted: $converted_size"
    else
        echo "❌ Conversion failed!"
        return 1
    fi
}

# Function to extract audio from video
extract_audio() {
    local input="$1"
    local output_format="$2"
    local quality="$3"
    
    if [ -z "$input" ]; then
        echo "❌ Error: Please provide input video file."
        echo "Usage: extract_audio <video> [format] [quality]"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    output_format=${output_format:-"mp3"}
    quality=${quality:-"192k"}
    
    local output="${input%.*}.$output_format"
    
    echo "🎵 Extracting audio from '$input'..."
    echo "🎯 Format: $output_format, Quality: $quality"
    
    ffmpeg -i "$input" -vn -c:a libmp3lame -b:a "$quality" "$output" -y
    
    if [ $? -eq 0 ]; then
        local size=$(du -sh "$output" | cut -f1)
        echo "✅ Audio extraction completed!"
        echo "📦 Audio file: $output ($size)"
    else
        echo "❌ Extraction failed!"
        return 1
    fi
}

# Function to batch convert
batch_convert() {
    local input_dir="$1"
    local output_format="$2"
    local media_type="$3"
    
    if [ -z "$input_dir" ] || [ -z "$output_format" ] || [ -z "$media_type" ]; then
        echo "❌ Error: Please provide all parameters."
        echo "Usage: batch_convert <input_directory> <output_format> <media_type>"
        echo "Media types: audio, video"
        return 1
    fi
    
    if [ ! -d "$input_dir" ]; then
        echo "❌ Error: Directory '$input_dir' not found."
        return 1
    fi
    
    echo "🔄 Starting batch conversion..."
    echo "📁 Input directory: $input_dir"
    echo "🎯 Output format: $output_format"
    echo "📹 Media type: $media_type"
    
    local count=0
    local success=0
    
    if [ "$media_type" = "audio" ]; then
        for file in "$input_dir"/*.{mp3,wav,flac,aac,ogg,m4a} 2>/dev/null; do
            if [ -f "$file" ]; then
                echo ""
                echo "Processing $((++count)): $(basename "$file")"
                if audio_convert "$file" "$output_format"; then
                    success=$((success + 1))
                fi
            fi
        done
    elif [ "$media_type" = "video" ]; then
        for file in "$input_dir"/*.{mp4,avi,mkv,mov,wmv,flv} 2>/dev/null; do
            if [ -f "$file" ]; then
                echo ""
                echo "Processing $((++count)): $(basename "$file")"
                if video_convert "$file" "$output_format"; then
                    success=$((success + 1))
                fi
            fi
        done
    fi
    
    echo ""
    echo "📊 Batch conversion summary:"
    echo "Total files processed: $count"
    echo "Successful conversions: $success"
    echo "Failed conversions: $((count - success))"
}

# Function to compress video
compress_video() {
    local input="$1"
    local compression_level="$2"
    
    if [ -z "$input" ]; then
        echo "❌ Error: Please provide input video file."
        echo "Usage: compress_video <video> [compression_level]"
        echo "Compression levels: light, medium, heavy"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    compression_level=${compression_level:-"medium"}
    local output="${input%.*}_compressed.${input##*.}"
    
    echo "🗜️ Compressing video: $input"
    echo "🎯 Compression level: $compression_level"
    
    local crf_value
    case "$compression_level" in
        light) crf_value=20 ;;
        medium) crf_value=28 ;;
        heavy) crf_value=35 ;;
        *) crf_value=28 ;;
    esac
    
    ffmpeg -i "$input" -c:v libx264 -crf "$crf_value" -c:a aac -b:a 128k "$output" -y
    
    if [ $? -eq 0 ]; then
        local original_size=$(du -sh "$input" | cut -f1)
        local compressed_size=$(du -sh "$output" | cut -f1)
        echo "✅ Video compression completed!"
        echo "📊 Original: $original_size → Compressed: $compressed_size"
        
        # Calculate compression ratio
        local original_bytes=$(stat -c%s "$input")
        local compressed_bytes=$(stat -c%s "$output")
        local ratio=$((100 - (compressed_bytes * 100 / original_bytes)))
        echo "📈 Space saved: $ratio%"
    else
        echo "❌ Compression failed!"
        return 1
    fi
}

# Main menu
echo ""
echo "Choose conversion option:"
echo "1. 🎵 Convert audio format"
echo "2. 📹 Convert video format"
echo "3. 🎤 Extract audio from video"
echo "4. 🔄 Batch convert files"
echo "5. 🗜️ Compress video file"
echo "6. ℹ️ Get media info"
echo ""

read -p "Select option (1-6): " option

case $option in
    1)
        echo ""
        read -p "🎵 Input audio file: " input
        echo "Available formats: mp3, wav, flac, aac, ogg, m4a"
        read -p "🎯 Output format: " format
        read -p "🔊 Quality (e.g., 192k, 320k): " quality
        audio_convert "$input" "$format" "$quality"
        ;;
        
    2)
        echo ""
        read -p "📹 Input video file: " input
        echo "Available formats: mp4, avi, mkv, webm, mov"
        read -p "🎯 Output format: " format
        echo "Quality options: low, medium, high"
        read -p "🔧 Quality: " quality
        read -p "📺 Resolution (e.g., 1920:1080, leave empty to keep original): " resolution
        video_convert "$input" "$format" "$quality" "$resolution"
        ;;
        
    3)
        echo ""
        read -p "📹 Input video file: " input
        echo "Audio formats: mp3, wav, flac, aac"
        read -p "🎯 Audio format (default: mp3): " format
        read -p "🔊 Quality (default: 192k): " quality
        extract_audio "$input" "$format" "$quality"
        ;;
        
    4)
        echo ""
        read -p "📁 Input directory: " input_dir
        echo "Media types: audio, video"
        read -p "📹 Media type: " media_type
        read -p "🎯 Output format: " format
        batch_convert "$input_dir" "$format" "$media_type"
        ;;
        
    5)
        echo ""
        read -p "📹 Input video file: " input
        echo "Compression levels: light, medium, heavy"
        read -p "🗜️ Compression level (default: medium): " level
        compress_video "$input" "$level"
        ;;
        
    6)
        echo ""
        read -p "📁 Media file: " input
        if [ -f "$input" ]; then
            echo "ℹ️ Media Information:"
            echo "===================="
            ffprobe -v quiet -print_format json -show_format -show_streams "$input" 2>/dev/null || \
            ffmpeg -i "$input" 2>&1 | grep -E "(Duration|Stream|Video|Audio)"
        else
            echo "❌ File not found: $input"
        fi
        ;;
        
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "🎬 Media conversion completed!"
echo ""
echo "💡 Tips:"
echo "   - Higher quality = larger file size"
echo "   - Use batch convert for multiple files"
echo "   - Compress videos to save space"
echo "   - Extract audio for music from videos"