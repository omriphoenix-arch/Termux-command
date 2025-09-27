#!/data/data/com.termux/files/usr/bin/bash
# Password Generator - Generate secure passwords

echo "🔐 SECURE PASSWORD GENERATOR"
echo "============================="

# Default settings
DEFAULT_LENGTH=16
DEFAULT_COUNT=5

# Character sets
LOWERCASE="abcdefghijklmnopqrstuvwxyz"
UPPERCASE="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
NUMBERS="0123456789"
SYMBOLS="!@#$%^&*()_+-=[]{}|;:,.<>?"
SAFE_SYMBOLS="!@#$%^&*()_+-="

# Function to generate password
generate_password() {
    local length=$1
    local charset=$2
    local count=$3
    
    echo ""
    echo "🎲 Generated passwords:"
    echo "----------------------"
    
    for ((i=1; i<=count; i++)); do
        password=""
        for ((j=1; j<=length; j++)); do
            password+="${charset:$((RANDOM % ${#charset})):1}"
        done
        echo "$i. $password"
    done
}

# Function to check password strength
check_strength() {
    local password=$1
    local score=0
    local feedback=""
    
    # Length check
    if [ ${#password} -ge 12 ]; then
        score=$((score + 2))
    elif [ ${#password} -ge 8 ]; then
        score=$((score + 1))
    else
        feedback+="❌ Too short (minimum 8 characters)\n"
    fi
    
    # Character diversity checks
    if [[ $password =~ [a-z] ]]; then
        score=$((score + 1))
    else
        feedback+="❌ Missing lowercase letters\n"
    fi
    
    if [[ $password =~ [A-Z] ]]; then
        score=$((score + 1))
    else
        feedback+="❌ Missing uppercase letters\n"
    fi
    
    if [[ $password =~ [0-9] ]]; then
        score=$((score + 1))
    else
        feedback+="❌ Missing numbers\n"
    fi
    
    if [[ $password =~ [^a-zA-Z0-9] ]]; then
        score=$((score + 1))
    else
        feedback+="❌ Missing special characters\n"
    fi
    
    # Strength rating
    echo ""
    echo "🎯 Password Strength Analysis:"
    echo "------------------------------"
    echo "Password: $password"
    echo "Length: ${#password} characters"
    
    if [ $score -ge 5 ]; then
        echo "Strength: 🟢 STRONG ($score/6)"
    elif [ $score -ge 3 ]; then
        echo "Strength: 🟡 MEDIUM ($score/6)"
    else
        echo "Strength: 🔴 WEAK ($score/6)"
    fi
    
    if [ -n "$feedback" ]; then
        echo ""
        echo "Recommendations:"
        echo -e "$feedback"
    fi
}

# Function to generate memorable password
generate_memorable() {
    local words=("apple" "bridge" "castle" "dragon" "eagle" "forest" "guitar" "house" "island" "jungle" "kitchen" "laptop" "mountain" "ocean" "piano" "queen" "river" "sunset" "tiger" "umbrella" "valley" "window" "xenon" "yacht" "zebra")
    
    local word1=${words[$RANDOM % ${#words[@]}]}
    local word2=${words[$RANDOM % ${#words[@]}]}
    local number=$((RANDOM % 9999 + 1000))
    local symbol=${SAFE_SYMBOLS:$((RANDOM % ${#SAFE_SYMBOLS})):1}
    
    # Capitalize first letters
    word1=$(echo "$word1" | sed 's/./\U&/')
    word2=$(echo "$word2" | sed 's/./\U&/')
    
    echo "$word1$symbol$word2$number"
}

# Function to generate PIN
generate_pin() {
    local length=$1
    echo $((10**($length-1) + RANDOM % (10**$length - 10**($length-1))))
}

# Main menu
echo ""
echo "Choose password type:"
echo "1. 🔤 Random password (letters, numbers, symbols)"
echo "2. 🔒 Alphanumeric only (letters and numbers)"
echo "3. 📝 Memorable password (words + numbers + symbols)"
echo "4. 🔢 PIN number"
echo "5. 🎯 Check existing password strength"
echo ""

read -p "Select option (1-5): " option

case $option in
    1)
        echo ""
        read -p "Password length (default: $DEFAULT_LENGTH): " length
        length=${length:-$DEFAULT_LENGTH}
        read -p "Number of passwords (default: $DEFAULT_COUNT): " count
        count=${count:-$DEFAULT_COUNT}
        
        charset="$LOWERCASE$UPPERCASE$NUMBERS$SYMBOLS"
        generate_password $length "$charset" $count
        ;;
        
    2)
        echo ""
        read -p "Password length (default: $DEFAULT_LENGTH): " length
        length=${length:-$DEFAULT_LENGTH}
        read -p "Number of passwords (default: $DEFAULT_COUNT): " count
        count=${count:-$DEFAULT_COUNT}
        
        charset="$LOWERCASE$UPPERCASE$NUMBERS"
        generate_password $length "$charset" $count
        ;;
        
    3)
        echo ""
        read -p "Number of passwords (default: $DEFAULT_COUNT): " count
        count=${count:-$DEFAULT_COUNT}
        
        echo ""
        echo "🎲 Generated memorable passwords:"
        echo "--------------------------------"
        for ((i=1; i<=count; i++)); do
            password=$(generate_memorable)
            echo "$i. $password"
        done
        ;;
        
    4)
        echo ""
        read -p "PIN length (4-8 digits, default: 4): " length
        length=${length:-4}
        
        if [ $length -lt 4 ] || [ $length -gt 8 ]; then
            echo "❌ PIN length must be between 4 and 8 digits"
            exit 1
        fi
        
        read -p "Number of PINs (default: $DEFAULT_COUNT): " count
        count=${count:-$DEFAULT_COUNT}
        
        echo ""
        echo "🎲 Generated PINs:"
        echo "------------------"
        for ((i=1; i<=count; i++)); do
            pin=$(generate_pin $length)
            echo "$i. $pin"
        done
        ;;
        
    5)
        echo ""
        read -p "Enter password to check: " -s password
        check_strength "$password"
        ;;
        
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "🔐 SECURITY TIPS:"
echo "================="
echo "✅ Use different passwords for different accounts"
echo "✅ Enable two-factor authentication when possible"
echo "✅ Store passwords in a reputable password manager"
echo "✅ Change passwords regularly for sensitive accounts"
echo "❌ Never share passwords or write them down plainly"
echo "❌ Don't use personal information in passwords"
echo ""
echo "🎯 Password generation complete!"

# Option to save to file
echo ""
read -p "💾 Save passwords to file? (y/n): " save_file
if [[ $save_file =~ ^[Yy]$ ]]; then
    timestamp=$(date +"%Y%m%d_%H%M%S")
    filename="passwords_$timestamp.txt"
    
    echo "# Generated passwords - $(date)" > "$filename"
    echo "# Generated by Termux Password Generator" >> "$filename"
    echo "# Keep this file secure!" >> "$filename"
    echo "" >> "$filename"
    
    # Re-run generation and save to file
    case $option in
        1|2)
            generate_password $length "$charset" $count >> "$filename"
            ;;
        3)
            for ((i=1; i<=count; i++)); do
                echo "$i. $(generate_memorable)" >> "$filename"
            done
            ;;
        4)
            for ((i=1; i<=count; i++)); do
                echo "$i. $(generate_pin $length)" >> "$filename"
            done
            ;;
    esac
    
    echo "✅ Passwords saved to: $filename"
    echo "⚠️ Remember to delete this file after use!"
fi