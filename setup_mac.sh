#!/bin/bash

# Weather MCP Server Setup Script - macOS Optimized
# This script sets up the complete environment for the Weather MCP Server
# Optimized for macOS with better error handling and path management

echo "🌦️  Setting up Weather MCP Server for macOS..."

# Detect macOS version
if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS_VERSION=$(sw_vers -productVersion)
    echo "✅ Detected macOS $MACOS_VERSION"
else
    echo "❌ This script is optimized for macOS only"
    exit 1
fi

# Function to check if Homebrew is installed
check_homebrew() {
    if command -v brew &> /dev/null; then
        echo "✅ Homebrew is available"
        return 0
    else
        echo "⚠️  Homebrew not found"
        return 1
    fi
}

# Install Homebrew if not available
install_homebrew() {
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    source ~/.zshrc 2>/dev/null || true
}

# Function to check Python 3.10+ availability
check_python() {
    # Check for Python 3.10 or higher
    for python_cmd in python3.12 python3.11 python3.10 python3; do
        if command -v $python_cmd &> /dev/null; then
            PYTHON_VERSION=$($python_cmd --version 2>&1 | cut -d' ' -f2)
            PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
            PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
            
            if [[ $PYTHON_MAJOR -eq 3 && $PYTHON_MINOR -ge 10 ]]; then
                PYTHON_CMD=$python_cmd
                echo "✅ Found Python $PYTHON_VERSION at $(which $python_cmd)"
                return 0
            fi
        fi
    done
    
    echo "⚠️  Python 3.10+ not found"
    return 1
}

# Install Python using Homebrew
install_python() {
    echo "📦 Installing Python via Homebrew..."
    
    if ! check_homebrew; then
        install_homebrew
        if ! check_homebrew; then
            echo "❌ Failed to install Homebrew"
            exit 1
        fi
    fi
    
    # Install latest Python (usually 3.12)
    brew install python@3.12
    
    # Update PATH
    if [[ $(uname -m) == "arm64" ]]; then
        PYTHON_PATH="/opt/homebrew/bin"
    else
        PYTHON_PATH="/usr/local/bin"
    fi
    
    export PATH="$PYTHON_PATH:$PATH"
    echo "export PATH=\"$PYTHON_PATH:\$PATH\"" >> ~/.zshrc
}

# Check and install Python
if ! check_python; then
    install_python
    
    # Check again after installation
    if ! check_python; then
        echo "❌ Failed to install Python 3.10+. Please install manually."
        exit 1
    fi
fi

# Function to check UV installation
check_uv() {
    if command -v uv &> /dev/null; then
        UV_PATH=$(which uv)
        UV_VERSION=$(uv --version 2>/dev/null || echo "unknown")
        echo "✅ UV is available at $UV_PATH ($UV_VERSION)"
        return 0
    else
        # Check common macOS locations
        local uv_locations=(
            "$HOME/.local/bin/uv"
            "$HOME/.cargo/bin/uv"
            "/opt/homebrew/bin/uv"
            "/usr/local/bin/uv"
        )
        
        for location in "${uv_locations[@]}"; do
            if [[ -f "$location" ]]; then
                echo "✅ Found UV at $location"
                export PATH="$(dirname $location):$PATH"
                return 0
            fi
        done
        
        echo "⚠️  UV not found"
        return 1
    fi
}

# Install UV
install_uv() {
    echo "📦 Installing UV..."
    
    # Method 1: Try official installer
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Add UV to PATH - check both possible locations
    local uv_paths=(
        "$HOME/.local/bin"
        "$HOME/.cargo/bin"
    )
    
    for uv_path in "${uv_paths[@]}"; do
        if [[ -f "$uv_path/uv" ]]; then
            export PATH="$uv_path:$PATH"
            echo "export PATH=\"$uv_path:\$PATH\"" >> ~/.zshrc
            break
        fi
    done
    
    # Method 2: If official installer fails, try Homebrew
    if ! command -v uv &> /dev/null; then
        echo "🔄 Trying Homebrew installation..."
        if check_homebrew; then
            brew install uv
        fi
    fi
    
    # Method 3: If still not found, try pipx
    if ! command -v uv &> /dev/null; then
        echo "🔄 Trying pipx installation..."
        $PYTHON_CMD -m pip install --user pipx
        $PYTHON_CMD -m pipx install uv
        
        # Add pipx bin to PATH
        export PATH="$HOME/.local/bin:$PATH"
        echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> ~/.zshrc
    fi
}

# Check and install UV
if ! check_uv; then
    install_uv
    
    # Reload shell environment
    source ~/.zshrc 2>/dev/null || true
    
    # Final check
    if ! check_uv; then
        echo "❌ Failed to install UV. Please install manually:"
        echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo "   source ~/.zshrc"
        exit 1
    fi
fi

# Get the final UV path for configuration
UV_FINAL_PATH=$(which uv)
echo "✅ UV is ready at: $UV_FINAL_PATH"

# Create project directory
PROJECT_DIR="weather-mcp"
echo "📁 Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Set UV to use the detected Python version
echo "🐍 Configuring UV to use $PYTHON_CMD..."
PYTHON_VERSION_SHORT=$(echo $PYTHON_VERSION | cut -d'.' -f1,2)
uv python install $PYTHON_VERSION_SHORT 2>/dev/null || true
uv python pin $PYTHON_VERSION_SHORT

# Initialize UV project
echo "🚀 Initializing UV project..."
uv init --name weather-mcp --python $PYTHON_VERSION_SHORT

# Verify Python version
echo "🔍 Verifying Python version..."
uv run python --version

# Install dependencies
echo "📚 Installing dependencies..."
uv add mcp
uv add httpx

# Create the main server file (same as original)
echo "📝 Creating weather_server.py..."
cat > weather_server.py << 'EOF'
from typing import Any
import httpx
import json
import ssl
import os
from mcp.server.fastmcp import FastMCP

print("Starting weather service...")
mcp = FastMCP('weather')

# Configuration
api_base = 'https://api.open-meteo.com/v1'
user_agent = 'weather-app/1.0'

# SSL Configuration
SSL_CONFIG = True
if os.getenv('SSL_VERIFY', '').lower() == 'false':
    SSL_CONFIG = False

async def make_openmeteo_request(url: str) -> dict[str, Any] | None:
    """Make request with proper error handling."""
    headers = {
        "User-Agent": user_agent,
        "Accept": "application/json"
    }
    
    try:
        async with httpx.AsyncClient(verify=SSL_CONFIG, timeout=30.0) as client:
            response = await client.get(url, headers=headers)
            response.raise_for_status()
            return response.json()
    except ssl.SSLError as e:
        print(f"SSL error: {e}")
        return None
    except httpx.HTTPStatusError as e:
        print(f"HTTP error {e.response.status_code}")
        return None
    except Exception as e:
        print(f"Request failed: {e}")
        return None

@mcp.tool()
async def get_current_weather(latitude: float, longitude: float) -> str:
    """Get current weather for a location.
    
    Args:
        latitude: Latitude of the location
        longitude: Longitude of the location
        
    Returns:
        str: JSON string with current weather data
    """
    url = f"{api_base}/forecast?latitude={latitude}&longitude={longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code"
    
    print(f"Making weather request to: {url}")
    data = await make_openmeteo_request(url)
    if not data:
        return "Unable to fetch weather data."
    
    return json.dumps(data, indent=2)

@mcp.tool()
async def get_forecast(latitude: float, longitude: float) -> str:
    """Get weather forecast for a location.
    
    Args:
        latitude: Latitude of the location
        longitude: Longitude of the location
        
    Returns:
        str: Formatted weather forecast
    """
    url = f"{api_base}/forecast?latitude={latitude}&longitude={longitude}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code&timezone=auto"
    
    print(f"Making forecast request to: {url}")
    data = await make_openmeteo_request(url)
    if not data:
        return "Unable to fetch forecast data."
    
    # Format the data for readability
    daily = data.get("daily", {})
    forecasts = []
    
    for i in range(len(daily.get("time", []))):
        forecast = f"""Date: {daily['time'][i]}
Max Temperature: {daily['temperature_2m_max'][i]}°C
Min Temperature: {daily['temperature_2m_min'][i]}°C
Precipitation: {daily['precipitation_sum'][i]} mm"""
        forecasts.append(forecast)
    
    return "\n---\n".join(forecasts)

@mcp.tool()
async def get_weather_by_city(city_name: str) -> str:
    """Get current weather by city name (requires geocoding).
    
    Args:
        city_name: Name of the city
        
    Returns:
        str: Weather information for the city
    """
    # Simple geocoding for major cities
    city_coordinates = {
        "bangkok": (13.7563, 100.5018),
        "tokyo": (35.6762, 139.6503),
        "new york": (40.7128, -74.0060),
        "london": (51.5074, -0.1278),
        "paris": (48.8566, 2.3522),
        "singapore": (1.3521, 103.8198),
        "sydney": (-33.8688, 151.2093),
        "los angeles": (34.0522, -118.2437)
    }
    
    city_lower = city_name.lower()
    if city_lower in city_coordinates:
        lat, lon = city_coordinates[city_lower]
        return await get_current_weather(lat, lon)
    else:
        return f"Sorry, coordinates for '{city_name}' are not available. Please provide latitude and longitude coordinates."

@mcp.resource("weather://popular-cities")
async def get_popular_cities():
    """Get list of popular cities with weather support."""
    cities = [
        "Bangkok (13.7563, 100.5018)",
        "Tokyo (35.6762, 139.6503)", 
        "New York (40.7128, -74.0060)",
        "London (51.5074, -0.1278)",
        "Paris (48.8566, 2.3522)",
        "Singapore (1.3521, 103.8198)",
        "Sydney (-33.8688, 151.2093)",
        "Los Angeles (34.0522, -118.2437)"
    ]
    return "\n".join(cities)

if __name__ == "__main__":
    mcp.run(transport='stdio')
EOF

# Test the installation
echo "🧪 Testing installation..."
uv run python -c "import mcp; import httpx; print('✅ All dependencies installed successfully')"

# Get current directory for config
CURRENT_DIR=$(pwd)

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Test the server:"
echo "   uv run python weather_server.py"
echo ""
echo "2. Add to Claude Desktop config:"
echo "   Path: ~/Library/Application Support/Claude/claude_desktop_config.json"
echo ""
echo "   Config content (Option 1 - Using UV in PATH):"
echo '   {'
echo '     "mcpServers": {'
echo '       "weather": {'
echo '         "command": "uv",'
echo "         \"args\": [\"run\", \"--directory\", \"$CURRENT_DIR\", \"python\", \"weather_server.py\"]"
echo '       }'
echo '     }'
echo '   }'
echo ""
echo "   Config content (Option 2 - Using absolute UV path):"
echo '   {'
echo '     "mcpServers": {'
echo '       "weather": {'
echo "         \"command\": \"$UV_FINAL_PATH\","
echo "         \"args\": [\"run\", \"--directory\", \"$CURRENT_DIR\", \"python\", \"weather_server.py\"]"
echo '       }'
echo '     }'
echo '   }'
echo ""
echo "3. Restart Claude Desktop"
echo "4. Ask Claude: 'What's the weather in Bangkok?'"
echo ""
echo "🔧 Troubleshooting:"
echo "   • Manual UV path: $UV_FINAL_PATH"
echo "   • Python version: $PYTHON_VERSION"
echo "   • Project directory: $CURRENT_DIR"
echo "   • If UV not found, add to PATH: export PATH=\"$(dirname $UV_FINAL_PATH):\$PATH\""
echo ""
echo "💡 macOS Tips:"
echo "   • Use Command+Shift+. to show hidden files in Finder"
echo "   • Config file location: ~/Library/Application Support/Claude/"
echo "   • Check logs in Console.app if Claude Desktop has issues"
echo "   • Restart Terminal after installation to refresh PATH"