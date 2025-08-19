#!/bin/bash

# Weather MCP Server Setup Script
# This script sets up the complete environment for the Weather MCP Server
# Compatible with: Linux, macOS, WSL (Windows Subsystem for Linux)

echo "🌦️  Setting up Weather MCP Server..."

# Detect if running in WSL
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
    echo "🐧 Detected WSL environment"
    WSL_ENV=true
else
    WSL_ENV=false
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
        
        # Add to shell profile
        if [ -f ~/.bashrc ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        fi
        if [ -f ~/.zshrc ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        fi
    fi
else
    echo "✅ UV is already installed"
fi

# Verify UV is available
if ! command -v uv &> /dev/null; then
    echo "⚠️  UV not found in PATH. Trying to source shell profile..."
    source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null || true
fi

# Create project directory
PROJECT_DIR="weather-mcp"
echo "📁 Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Initialize UV project
echo "🚀 Initializing UV project..."
uv init --name weather-mcp

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
    except Exception as e:
        print(f"Request failed: {e}")
        return None

@mcp.tool()
async def get_current_weather(latitude: float, longitude: float) -> str:
    """Get current weather for a location."""
    url = f"{api_base}/forecast?latitude={latitude}&longitude={longitude}&current=temperature_2m,relative_humidity_2m,precipitation"
    data = await make_openmeteo_request(url)
    if not data:
        return "Unable to fetch weather data."
    return json.dumps(data, indent=2)

@mcp.tool()
async def get_forecast(latitude: float, longitude: float) -> str:
    """Get weather forecast for a location."""
    url = f"{api_base}/forecast?latitude={latitude}&longitude={longitude}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto"
    data = await make_openmeteo_request(url)
    if not data:
        return "Unable to fetch forecast data."
    
    daily = data.get("daily", {})
    forecasts = []
    for i in range(len(daily.get("time", []))):
        forecast = f"Date: {daily['time'][i]}\nMax: {daily['temperature_2m_max'][i]}°C\nMin: {daily['temperature_2m_min'][i]}°C"
        forecasts.append(forecast)
    return "\n---\n".join(forecasts)

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

if [ "$WSL_ENV" = true ]; then
    echo "🐧 WSL Configuration for Claude Desktop:"
    echo "   Add to: %APPDATA%/Claude/claude_desktop_config.json (Windows path)"
    echo "   Or: ~/AppData/Roaming/Claude/claude_desktop_config.json (from WSL)"
    echo ""
    echo "   WSL Config (Recommended):"
    echo '   {'
    echo '     "mcpServers": {'
    echo '       "weather": {'
    echo '         "command": "wsl",'
    echo "         \"args\": [\"-e\", \"bash\", \"-c\", \"cd $CURRENT_DIR && uv run python weather_server.py\"],"
    echo '         "env": {"SSL_VERIFY": "false"}'
    echo '       }'
    echo '     }'
    echo '   }'
    echo ""
    echo "   Alternative (Windows UNC path):"
    WSL_DISTRO=$(cat /proc/version | grep -oE 'Microsoft|WSL' | head -1)
    if [ -n "$WSL_DISTRO" ]; then
        # Try to detect WSL distribution name
        WSL_NAME=$(wsl.exe -l | grep -E '\*|\(Default\)' | sed 's/.*\s\([A-Za-z]*\).*/\1/' 2>/dev/null || echo "Ubuntu")
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
    echo "   • WSL typically has better performance than Windows native"
fi

echo "🔧 Troubleshooting:"
echo "   • Run 'uv run python test_server.py' to test"
echo "   • Check PATH if UV not found: source ~/.bashrc"
echo "   • Use absolute paths in Claude config"