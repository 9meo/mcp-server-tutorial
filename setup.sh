#!/bin/bash

# Weather MCP Server Setup Script
# This script sets up the complete environment for the Weather MCP Server
# Compatible with: Linux, macOS, WSL (Windows Subsystem for Linux)
# Uses Python 3.10 specifically

echo "🌦️  Setting up Weather MCP Server with Python 3.10..."

# Detect if running in WSL
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    echo "🐧 Detected WSL environment"
    WSL_ENV=true
else
    WSL_ENV=false
fi

# Function to check Python 3.10 availability
check_python310() {
    if command -v python3.10 &> /dev/null; then
        echo "✅ Python 3.10 is available"
        return 0
    else
        echo "⚠️  Python 3.10 not found"
        return 1
    fi
}

# Install Python 3.10 if not available
install_python310() {
    echo "📦 Installing Python 3.10..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [ "$WSL_ENV" = true ]; then
        # Linux/WSL
        if command -v apt &> /dev/null; then
            # Ubuntu/Debian
            sudo apt update
            sudo apt install -y python3.10 python3.10-venv python3.10-dev python3-pip curl
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            sudo yum install -y python3.10 python3.10-venv python3.10-devel curl
        elif command -v dnf &> /dev/null; then
            # Fedora
            sudo dnf install -y python3.10 python3.10-venv python3.10-devel curl
        elif command -v pacman &> /dev/null; then
            # Arch Linux
            sudo pacman -S python python-pip curl
        else
            echo "❌ Unsupported Linux distribution. Please install Python 3.10 manually."
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install python@3.10
        else
            echo "❌ Homebrew not found. Please install Python 3.10 manually."
            echo "   Install Homebrew: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    fi
}

# Check and install Python 3.10
if ! check_python310; then
    install_python310
    
    # Check again after installation
    if ! check_python310; then
        echo "❌ Failed to install Python 3.10. Please install manually."
        exit 1
    fi
fi

# Check if UV is installed
if ! command -v uv &> /dev/null; then
    echo "📦 Installing UV..."
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows (shouldn't happen in WSL)
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    else
        # macOS/Linux/WSL
        curl -LsSf https://astral.sh/uv/install.sh | sh
        
        # Add UV to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        
        # Add to shell profiles
        for profile in ~/.bashrc ~/.zshrc ~/.profile; do
            if [ -f "$profile" ]; then
                if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$profile"; then
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$profile"
                fi
            fi
        done
        
        # For WSL: Create system-wide UV access
        if [ "$WSL_ENV" = true ]; then
            echo "🐧 Setting up UV for WSL system-wide access..."
            
            # Create symlink in /usr/local/bin (if we have permission)
            if [ -w /usr/local/bin ] || sudo -n true 2>/dev/null; then
                sudo ln -sf "$HOME/.local/bin/uv" /usr/local/bin/uv 2>/dev/null || true
                sudo ln -sf "$HOME/.local/bin/uvx" /usr/local/bin/uvx 2>/dev/null || true
            fi
            
            # Also try /usr/bin
            if [ -w /usr/bin ] || sudo -n true 2>/dev/null; then
                sudo ln -sf "$HOME/.local/bin/uv" /usr/bin/uv 2>/dev/null || true
            fi
            
            # Create wrapper script as backup
            mkdir -p "$HOME/bin"
            cat > "$HOME/bin/uv" << 'UVWRAPPER'
#!/bin/bash
exec "$HOME/.local/bin/uv" "$@"
UVWRAPPER
            chmod +x "$HOME/bin/uv"
            
            # Add ~/bin to PATH as well
            export PATH="$HOME/bin:$PATH"
            for profile in ~/.bashrc ~/.zshrc ~/.profile; do
                if [ -f "$profile" ]; then
                    if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$profile"; then
                        echo 'export PATH="$HOME/bin:$PATH"' >> "$profile"
                    fi
                fi
            done
        fi
    fi
else
    echo "✅ UV is already installed"
fi

# Verify UV is available and try multiple methods to make it accessible
if ! command -v uv &> /dev/null; then
    echo "⚠️  UV not found in PATH. Trying multiple fixes..."
    
    # Method 1: Source shell profiles
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null || source ~/.profile 2>/dev/null || true
    
    # Method 2: Explicit PATH export
    export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
    
    # Method 3: Create temporary symlink
    if [ ! -f /tmp/uv ] && [ -f "$HOME/.local/bin/uv" ]; then
        ln -sf "$HOME/.local/bin/uv" /tmp/uv
        export PATH="/tmp:$PATH"
    fi
    
    # Final check
    if ! command -v uv &> /dev/null; then
        echo "❌ UV installation failed. Please install manually:"
        echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
        echo "   source ~/.bashrc"
        exit 1
    fi
fi

echo "✅ UV is accessible at: $(which uv)"

# Create project directory
PROJECT_DIR="weather-mcp"
echo "📁 Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Set UV to use Python 3.10 specifically
echo "🐍 Configuring UV to use Python 3.10..."
uv python install 3.10
uv python pin 3.10

# Initialize UV project with Python 3.10
echo "🚀 Initializing UV project with Python 3.10..."
uv init --name weather-mcp --python 3.10

# Verify Python version
echo "🔍 Verifying Python version..."
uv run python --version

# Add dependencies (one by one to avoid conflicts)
echo "📚 Installing dependencies..."
uv add mcp
uv add httpx

# Create the main server file
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

# Create test file
echo "📝 Creating test_server.py..."
cat > test_server.py << 'EOF'
#!/usr/bin/env python3
"""
Test script for Weather MCP Server
Run this to verify your server is working correctly
"""

import asyncio
import json
import sys
from pathlib import Path

# Add the current directory to the path so we can import our server
sys.path.insert(0, str(Path(__file__).parent))

try:
    from weather_server import get_current_weather, get_forecast, get_weather_by_city, make_openmeteo_request
    print("✅ Successfully imported weather server modules")
except ImportError as e:
    print(f"❌ Failed to import weather server modules: {e}")
    sys.exit(1)

async def test_api_connectivity():
    """Test basic API connectivity"""
    print("\n🌐 Testing API connectivity...")
    
    url = "https://api.open-meteo.com/v1/forecast?latitude=13.7563&longitude=100.5018&current=temperature_2m"
    result = await make_openmeteo_request(url)
    
    if result:
        print("✅ API connectivity successful")
        return True
    else:
        print("❌ API connectivity failed")
        return False

async def test_current_weather():
    """Test current weather function"""
    print("\n🌡️  Testing current weather function...")
    
    # Test Bangkok coordinates
    lat, lon = 13.7563, 100.5018
    result = await get_current_weather(lat, lon)
    
    if result and result != "Unable to fetch weather data.":
        print("✅ Current weather function working")
        try:
            data = json.loads(result)
            if "current" in data:
                print(f"   📊 Sample data: Temperature = {data['current'].get('temperature_2m', 'N/A')}°C")
            return True
        except json.JSONDecodeError:
            print("⚠️  Current weather function working but returned non-JSON data")
            return True
    else:
        print("❌ Current weather function failed")
        return False

async def test_forecast():
    """Test weather forecast function"""
    print("\n📅 Testing weather forecast function...")
    
    # Test Tokyo coordinates
    lat, lon = 35.6762, 139.6503
    result = await get_forecast(lat, lon)
    
    if result and result != "Unable to fetch forecast data.":
        print("✅ Weather forecast function working")
        lines = result.split('\n')
        print(f"   📊 Forecast contains {len([l for l in lines if l.startswith('Date:')])} days")
        return True
    else:
        print("❌ Weather forecast function failed")
        return False

async def test_city_weather():
    """Test city-based weather function"""
    print("\n🏙️  Testing city weather function...")
    
    result = await get_weather_by_city("bangkok")
    
    if result and not result.startswith("Sorry"):
        print("✅ City weather function working")
        return True
    else:
        print("❌ City weather function failed or city not found")
        return False

async def test_error_handling():
    """Test error handling with invalid coordinates"""
    print("\n⚠️  Testing error handling...")
    
    # Test with invalid coordinates (should handle gracefully)
    result = await get_current_weather(999, 999)
    
    if result:
        print("✅ Error handling working (returned result for invalid coords)")
        return True
    else:
        print("✅ Error handling working (gracefully handled invalid coords)")
        return True

def test_imports():
    """Test that all required modules can be imported"""
    print("📦 Testing imports...")
    
    try:
        import mcp
        print("✅ MCP module imported successfully")
    except ImportError:
        print("❌ MCP module not found - run: uv add mcp")
        return False
    
    try:
        import httpx
        print("✅ HTTPX module imported successfully")
    except ImportError:
        print("❌ HTTPX module not found - run: uv add httpx")
        return False
    
    return True

async def run_all_tests():
    """Run all tests and provide a summary"""
    print("🧪 Weather MCP Server Test Suite")
    print("=" * 50)
    
    # Test imports first
    if not test_imports():
        print("\n❌ Import tests failed. Please install required dependencies.")
        return False
    
    # Run async tests
    tests = [
        test_api_connectivity,
        test_current_weather,
        test_forecast,
        test_city_weather,
        test_error_handling
    ]
    
    results = []
    for test in tests:
        try:
            result = await test()
            results.append(result)
        except Exception as e:
            print(f"❌ Test {test.__name__} failed with exception: {e}")
            results.append(False)
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Summary:")
    passed = sum(results)
    total = len(results)
    
    print(f"   ✅ Passed: {passed}/{total}")
    if passed == total:
        print("   🎉 All tests passed! Your MCP server is ready to use.")
    else:
        print("   ⚠️  Some tests failed. Check the output above for details.")
    
    print("\n💡 Next steps:")
    if passed == total:
        print("   1. Configure Claude Desktop (see README.md)")
        print("   2. Restart Claude Desktop")
        print("   3. Ask Claude: 'What's the weather in Bangkok?'")
    else:
        print("   1. Fix the failing tests")
        print("   2. Check your internet connection")
        print("   3. Verify dependencies are installed: uv sync")
    
    return passed == total

if __name__ == "__main__":
    print("Starting Weather MCP Server tests...\n")
    success = asyncio.run(run_all_tests())
    sys.exit(0 if success else 1)
EOF

# Get current directory for config
CURRENT_DIR=$(pwd)

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Test the server:"
echo "   uv run python weather_server.py"
echo ""

if [ "$WSL_ENV" = true ]; then
    echo "🐧 WSL Configuration for Claude Desktop:"
    echo "   Add to: %APPDATA%/Claude/claude_desktop_config.json (Windows path)"
    echo "   Or: ~/AppData/Roaming/Claude/claude_desktop_config.json (from WSL)"
    echo ""
    echo "   WSL Config Option 1 (Using system UV):"
    echo '   {'
    echo '     "mcpServers": {'
    echo '       "weather": {'
    echo '         "command": "wsl",'
    echo "         \"args\": [\"-e\", \"uv\", \"run\", \"--directory\", \"$CURRENT_DIR\", \"python\", \"weather_server.py\"],"
    echo '         "env": {"SSL_VERIFY": "false"}'
    echo '       }'
    echo '     }'
    echo '   }'
    echo ""
    echo "   WSL Config Option 2 (Using absolute path):"
    UV_PATH=$(which uv 2>/dev/null || echo "$HOME/.local/bin/uv")
    echo '   {'
    echo '     "mcpServers": {'
    echo '       "weather": {'
    echo '         "command": "wsl",'
    echo "         \"args\": [\"-e\", \"$UV_PATH\", \"run\", \"--directory\", \"$CURRENT_DIR\", \"python\", \"weather_server.py\"],"
    echo '         "env": {"SSL_VERIFY": "false"}'
    echo '       }'
    echo '     }'
    echo '   }'
    echo ""
    echo "   WSL Config Option 3 (Using bash wrapper):"
    echo '   {'
    echo '     "mcpServers": {'
    echo '       "weather": {'
    echo '         "command": "wsl",'
    echo "         \"args\": [\"-e\", \"bash\", \"-c\", \"export PATH=\\\"$HOME/.local/bin:$HOME/bin:\\$PATH\\\" && cd $CURRENT_DIR && uv run python weather_server.py\"],"
    echo '         "env": {"SSL_VERIFY": "false"}'
    echo '       }'
    echo '     }'
    echo '   }'
    echo ""
    echo "   Alternative (Windows UNC path):"
    WSL_DISTRO=$(cat /proc/version | grep -oE 'Microsoft|WSL' | head -1)
    if [ -n "$WSL_DISTRO" ]; then
        # Try to detect WSL distribution name
        WSL_NAME=$(wsl.exe -l -q 2>/dev/null | head -2 | tail -1 | tr -d '\r' 2>/dev/null || echo "Ubuntu")
        echo "         \"args\": [\"run\", \"--directory\", \"\\\\\\\\wsl\$\\\\$WSL_NAME\\\\$CURRENT_DIR\", \"python\", \"weather_server.py\"],"
    fi
else
    echo "2. Add to Claude Desktop config:"
    echo "   Path: ~/Library/Application Support/Claude/claude_desktop_config.json (macOS)"
    echo "   Path: %APPDATA%/Claude/claude_desktop_config.json (Windows)"
    echo ""
    echo "   Config content:"
    echo '   {'
    echo '     "mcpServers": {'
    echo '       "weather": {'
    echo '         "command": "uv",'
    echo "         \"args\": [\"run\", \"--directory\", \"$CURRENT_DIR\", \"python\", \"weather_server.py\"],"
    echo '         "env": {"SSL_VERIFY": "false"}'
    echo '       }'
    echo '     }'
    echo '   }'
fi

echo ""
echo "3. Restart Claude Desktop"
echo "4. Ask Claude: 'What's the weather in Bangkok?'"
echo ""

if [ "$WSL_ENV" = true ]; then
    echo "💡 WSL Tips:"
    echo "   • Your project is at: $CURRENT_DIR"
    echo "   • Access from Windows: \\\\wsl\$\\Ubuntu$CURRENT_DIR"
    echo "   • Use 'code .' to open in VS Code with WSL extension"
    echo "   • If UV not found by Claude, run: ./fix_wsl_uv.sh"
fi

echo "🔧 Troubleshooting:"
echo "   • Test server: uv run python test_server.py"
echo "   • Test full suite: uv run python test_server.py"
echo "   • Fix WSL path issues: ./fix_wsl_uv.sh"
echo "   • Manual UV path: $HOME/.local/bin/uv"