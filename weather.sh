#!/data/data/com.termux/files/usr/bin/bash
# Weather Information Script

echo "🌤️ WEATHER INFORMATION"
echo "======================="

# Check if curl is available
if ! command -v curl >/dev/null 2>&1; then
    echo "❌ curl not found. Please install it first:"
    echo "pkg install curl"
    exit 1
fi

# Function to get weather by location name
get_weather_by_name() {
    local location="$1"
    echo "🔍 Getting weather for: $location"
    echo ""
    
    # Using wttr.in service (no API key required)
    curl -s "wttr.in/$location?format=3" 2>/dev/null
    echo ""
    
    # Detailed weather
    echo "📋 Detailed Weather:"
    curl -s "wttr.in/$location?0&q&T" 2>/dev/null | head -20
}

# Function to get weather by coordinates
get_weather_by_coords() {
    local lat="$1"
    local lon="$2"
    echo "🌍 Getting weather for coordinates: $lat, $lon"
    echo ""
    
    curl -s "wttr.in/$lat,$lon?format=3" 2>/dev/null
    echo ""
    
    # Detailed weather
    echo "📋 Detailed Weather:"
    curl -s "wttr.in/$lat,$lon?0&q&T" 2>/dev/null | head -20
}

# Function to get current location (if termux-api is available)
get_current_location() {
    if command -v termux-location >/dev/null 2>&1; then
        echo "📍 Getting current location..."
        location_data=$(timeout 10 termux-location -p network 2>/dev/null)
        
        if [ $? -eq 0 ] && [ -n "$location_data" ]; then
            lat=$(echo "$location_data" | grep -o '"latitude":[^,]*' | cut -d':' -f2)
            lon=$(echo "$location_data" | grep -o '"longitude":[^,]*' | cut -d':' -f2)
            
            if [ -n "$lat" ] && [ -n "$lon" ]; then
                echo "📍 Current location: $lat, $lon"
                get_weather_by_coords "$lat" "$lon"
                return 0
            fi
        fi
    fi
    
    echo "❌ Could not get current location"
    echo "💡 Install termux-api for location features: pkg install termux-api"
    return 1
}

# Function to show weather forecast
show_forecast() {
    local location="$1"
    echo ""
    echo "📅 7-Day Forecast for: $location"
    echo "================================"
    
    curl -s "wttr.in/$location?format=%l:+%C+%t+%h+%w+%p\n" 2>/dev/null
    echo ""
    
    # Detailed 3-day forecast
    curl -s "wttr.in/$location?3&q&T" 2>/dev/null
}

# Function to show weather in different formats
show_weather_formats() {
    local location="$1"
    
    echo ""
    echo "🎨 Weather Display Options:"
    echo "==========================="
    
    echo ""
    echo "1️⃣ Compact Format:"
    curl -s "wttr.in/$location?format=1" 2>/dev/null
    
    echo ""
    echo "2️⃣ Detailed Format:"
    curl -s "wttr.in/$location?format=2" 2>/dev/null
    
    echo ""
    echo "3️⃣ Standard Format:"
    curl -s "wttr.in/$location?format=3" 2>/dev/null
    
    echo ""
    echo "4️⃣ Custom Format:"
    curl -s "wttr.in/$location?format=%l:+%C+%t+(feels+like+%f)+%h+humidity,+%w+wind,+%p+pressure" 2>/dev/null
}

# Function to check air quality (if available)
check_air_quality() {
    local location="$1"
    echo ""
    echo "🌬️ Air Quality Information:"
    echo "==========================="
    
    # Try to get air quality data from wttr.in
    curl -s "wttr.in/$location?format=%l:+AQI+not+available+via+this+service" 2>/dev/null
    echo ""
    echo "💡 For detailed air quality, visit: https://www.airnow.gov/"
}

# Function to save weather to file
save_weather() {
    local location="$1"
    local filename="weather_$(echo "$location" | tr ' ' '_')_$(date +%Y%m%d_%H%M).txt"
    
    {
        echo "Weather Report for $location"
        echo "Generated on: $(date)"
        echo "================================"
        echo ""
        get_weather_by_name "$location"
        echo ""
        show_forecast "$location"
    } > "$filename"
    
    echo "💾 Weather report saved to: $filename"
}

# Main menu
echo ""
echo "Choose weather option:"
echo "1. 🌍 Current location weather (GPS)"
echo "2. 🏙️ Weather by city name"
echo "3. 🗺️ Weather by coordinates"
echo "4. 📅 7-day forecast"
echo "5. 🎨 Multiple weather formats"
echo "6. 🌬️ Air quality check"
echo "7. 💾 Save weather report"
echo ""

read -p "Select option (1-7): " option

case $option in
    1)
        echo ""
        if ! get_current_location; then
            echo ""
            echo "🏙️ Falling back to manual city entry..."
            read -p "Enter your city name: " city
            get_weather_by_name "$city"
        fi
        ;;
        
    2)
        echo ""
        read -p "Enter city name (e.g., London, New York, Tokyo): " city
        if [ -n "$city" ]; then
            get_weather_by_name "$city"
        else
            echo "❌ No city name provided"
        fi
        ;;
        
    3)
        echo ""
        read -p "Enter latitude: " lat
        read -p "Enter longitude: " lon
        if [ -n "$lat" ] && [ -n "$lon" ]; then
            get_weather_by_coords "$lat" "$lon"
        else
            echo "❌ Invalid coordinates"
        fi
        ;;
        
    4)
        echo ""
        read -p "Enter city name for forecast: " city
        if [ -n "$city" ]; then
            show_forecast "$city"
        else
            echo "❌ No city name provided"
        fi
        ;;
        
    5)
        echo ""
        read -p "Enter city name: " city
        if [ -n "$city" ]; then
            show_weather_formats "$city"
        else
            echo "❌ No city name provided"
        fi
        ;;
        
    6)
        echo ""
        read -p "Enter city name: " city
        if [ -n "$city" ]; then
            check_air_quality "$city"
        else
            echo "❌ No city name provided"
        fi
        ;;
        
    7)
        echo ""
        read -p "Enter city name: " city
        if [ -n "$city" ]; then
            save_weather "$city"
        else
            echo "❌ No city name provided"
        fi
        ;;
        
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "🌤️ Weather Information Complete!"
echo ""
echo "💡 Weather Tips:"
echo "   - Weather data provided by wttr.in"
echo "   - For more detailed weather, visit: https://wttr.in/YourCity"
echo "   - Install termux-api for GPS location: pkg install termux-api"
echo "   - You can bookmark: curl wttr.in/YourCity for quick access"
echo ""
echo "🌈 Have a great day!"