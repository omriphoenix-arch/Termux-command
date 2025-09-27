#!/data/data/com.termux/files/usr/bin/bash
# QR Code Generator Script

echo "📱 QR CODE GENERATOR"
echo "===================="

# Check if qrencode is installed
if ! command -v qrencode >/dev/null 2>&1; then
    echo "📦 qrencode not found. Installing..."
    pkg install -y qrencode
    
    if [ $? -ne 0 ]; then
        echo "❌ Failed to install qrencode"
        echo "💡 Try: pkg install qrencode"
        exit 1
    fi
    echo "✅ qrencode installed successfully!"
fi

# Function to generate QR code
generate_qr() {
    local text="$1"
    local output_file="$2"
    local size="$3"
    local error_level="$4"
    
    echo ""
    echo "🔄 Generating QR code..."
    
    if [ -n "$output_file" ]; then
        # Generate to file
        if qrencode -s "$size" -l "$error_level" -o "$output_file" "$text"; then
            echo "✅ QR code saved to: $output_file"
            
            # Show file info
            if [ -f "$output_file" ]; then
                file_size=$(ls -lh "$output_file" | awk '{print $5}')
                echo "📏 File size: $file_size"
            fi
        else
            echo "❌ Failed to generate QR code"
            return 1
        fi
    else
        # Generate to terminal (ASCII)
        echo "📱 QR Code (ASCII):"
        echo "==================="
        qrencode -t ASCII "$text"
        
        echo ""
        echo "📱 QR Code (UTF8):"
        echo "=================="
        qrencode -t UTF8 "$text"
    fi
}

# Function to generate WiFi QR code
generate_wifi_qr() {
    echo ""
    echo "📶 WiFi QR Code Generator"
    echo "========================="
    
    read -p "Network name (SSID): " ssid
    if [ -z "$ssid" ]; then
        echo "❌ SSID cannot be empty"
        return 1
    fi
    
    echo "Security type:"
    echo "1. WPA/WPA2"
    echo "2. WEP"
    echo "3. None (Open)"
    read -p "Select (1-3): " security_type
    
    case $security_type in
        1) security="WPA" ;;
        2) security="WEP" ;;
        3) security="nopass" ;;
        *) security="WPA" ;;
    esac
    
    if [ "$security" != "nopass" ]; then
        read -p "Password: " -s password
        echo ""
        if [ -z "$password" ]; then
            echo "❌ Password cannot be empty for secured networks"
            return 1
        fi
    else
        password=""
    fi
    
    read -p "Hidden network? (y/n): " hidden
    if [[ $hidden =~ ^[Yy]$ ]]; then
        hidden="true"
    else
        hidden="false"
    fi
    
    # Create WiFi QR code string
    if [ "$security" = "nopass" ]; then
        wifi_string="WIFI:T:;S:$ssid;P:;H:$hidden;"
    else
        wifi_string="WIFI:T:$security;S:$ssid;P:$password;H:$hidden;"
    fi
    
    echo ""
    echo "📱 WiFi QR Code:"
    echo "================"
    generate_qr "$wifi_string" "" 3 "M"
    
    echo ""
    read -p "💾 Save to file? (y/n): " save_file
    if [[ $save_file =~ ^[Yy]$ ]]; then
        filename="wifi_${ssid//[^a-zA-Z0-9]/_}_$(date +%Y%m%d_%H%M).png"
        generate_qr "$wifi_string" "$filename" 8 "M"
    fi
}

# Function to generate contact QR code
generate_contact_qr() {
    echo ""
    echo "👤 Contact QR Code Generator"
    echo "==========================="
    
    read -p "Full name: " name
    read -p "Phone number: " phone
    read -p "Email: " email
    read -p "Organization: " org
    read -p "Website: " website
    
    # Create vCard format
    vcard="BEGIN:VCARD
VERSION:3.0"
    
    [ -n "$name" ] && vcard+="\nFN:$name"
    [ -n "$phone" ] && vcard+="\nTEL:$phone"
    [ -n "$email" ] && vcard+="\nEMAIL:$email"
    [ -n "$org" ] && vcard+="\nORG:$org"
    [ -n "$website" ] && vcard+="\nURL:$website"
    
    vcard+="\nEND:VCARD"
    
    echo ""
    echo "👤 Contact QR Code:"
    echo "=================="
    generate_qr "$vcard" "" 3 "M"
    
    echo ""
    read -p "💾 Save to file? (y/n): " save_file
    if [[ $save_file =~ ^[Yy]$ ]]; then
        filename="contact_${name//[^a-zA-Z0-9]/_}_$(date +%Y%m%d_%H%M).png"
        generate_qr "$vcard" "$filename" 8 "M"
    fi
}

# Function to batch generate QR codes
batch_generate() {
    echo ""
    echo "📋 Batch QR Code Generation"
    echo "==========================="
    
    read -p "Input file (one text per line): " input_file
    if [ ! -f "$input_file" ]; then
        echo "❌ File not found: $input_file"
        return 1
    fi
    
    read -p "Output directory (default: qr_codes): " output_dir
    output_dir=${output_dir:-"qr_codes"}
    
    mkdir -p "$output_dir"
    
    line_num=1
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            filename="$output_dir/qr_$(printf "%03d" $line_num).png"
            echo "Generating QR $line_num: ${line:0:50}..."
            generate_qr "$line" "$filename" 6 "M" >/dev/null
            line_num=$((line_num + 1))
        fi
    done < "$input_file"
    
    echo "✅ Generated $((line_num - 1)) QR codes in $output_dir/"
}

# Main menu
echo ""
echo "Choose QR code type:"
echo "1. 📝 Text/URL QR code"
echo "2. 📶 WiFi QR code"
echo "3. 👤 Contact (vCard) QR code"
echo "4. 📋 Batch generation from file"
echo "5. 🎨 Custom options"
echo ""

read -p "Select option (1-5): " option

case $option in
    1)
        echo ""
        read -p "Enter text or URL: " text
        if [ -z "$text" ]; then
            echo "❌ Text cannot be empty"
            exit 1
        fi
        
        generate_qr "$text" "" 3 "M"
        
        echo ""
        read -p "💾 Save to file? (y/n): " save_file
        if [[ $save_file =~ ^[Yy]$ ]]; then
            filename="qr_$(date +%Y%m%d_%H%M%S).png"
            generate_qr "$text" "$filename" 8 "M"
        fi
        ;;
        
    2)
        generate_wifi_qr
        ;;
        
    3)
        generate_contact_qr
        ;;
        
    4)
        batch_generate
        ;;
        
    5)
        echo ""
        read -p "Enter text: " text
        if [ -z "$text" ]; then
            echo "❌ Text cannot be empty"
            exit 1
        fi
        
        echo ""
        echo "Size options:"
        echo "1. Small (3x3)"
        echo "2. Medium (6x6)"
        echo "3. Large (10x10)"
        read -p "Select size (1-3): " size_option
        
        case $size_option in
            1) size=3 ;;
            2) size=6 ;;
            3) size=10 ;;
            *) size=6 ;;
        esac
        
        echo ""
        echo "Error correction level:"
        echo "1. Low (L)"
        echo "2. Medium (M)"
        echo "3. Quality (Q)"
        echo "4. High (H)"
        read -p "Select level (1-4): " error_option
        
        case $error_option in
            1) error_level="L" ;;
            2) error_level="M" ;;
            3) error_level="Q" ;;
            4) error_level="H" ;;
            *) error_level="M" ;;
        esac
        
        read -p "Output filename (leave empty for terminal): " filename
        
        generate_qr "$text" "$filename" "$size" "$error_level"
        ;;
        
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "📱 QR Code Generation Complete!"
echo ""
echo "💡 Tips:"
echo "   - QR codes are saved as PNG images"
echo "   - Use QR scanner apps to test your codes"
echo "   - Higher error correction = more robust but larger codes"
echo "   - WiFi QR codes can be scanned to auto-connect"
echo ""
echo "✨ Scan away!"