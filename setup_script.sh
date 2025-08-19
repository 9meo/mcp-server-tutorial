#!/bin/bash

# Weather MCP Server Setup Script
# This script sets up the complete environment for the Weather MCP Server

echo "🌦️  Setting up Weather MCP Server..."

# Check if UV is installed
if ! command -v uv &> /dev/null; then
    echo "📦 Installing UV..."
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows
        powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    else
        # macOS/Linux
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source ~/.bashrc
    fi
else
    echo "✅ UV is already installed"
fi

# Create project directory
PROJECT_DIR="weather-mcp"
echo "📁 Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Initialize UV project
echo "🚀 Initializing UV project..."
uv init --name weather-mcp

# Add dependencies
echo "📚 Installing dependencies..."
uv add mcp
uv add httpx
uv add "python>=3.8"

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
echo ""
echo "3. Restart Claude Desktop"
echo "4. Ask Claude: 'What's the weather in Bangkok?'"