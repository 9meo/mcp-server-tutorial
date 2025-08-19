@echo off
echo 🌦️  Setting up Weather MCP Server on Windows...

REM Check if UV is installed
where uv >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 📦 Installing UV...
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    REM Refresh environment variables
    call refreshenv
) else (
    echo ✅ UV is already installed
)

REM Create project directory
set PROJECT_DIR=weather-mcp
echo 📁 Creating project directory: %PROJECT_DIR%
mkdir %PROJECT_DIR%
cd %PROJECT_DIR%

REM Initialize UV project
echo 🚀 Initializing UV project...
uv init --name weather-mcp

REM Add dependencies
echo 📚 Installing dependencies...
uv add mcp
uv add httpx

REM Create the main server file
echo 📝 Creating weather_server.py...
(
echo from typing import Any
echo import httpx
echo import json
echo import ssl
echo import os
echo from mcp.server.fastmcp import FastMCP
echo.
echo print^("Starting weather service..."^)
echo mcp = FastMCP^('weather'^)
echo.
echo # Configuration
echo api_base = 'https://api.open-meteo.com/v1'
echo user_agent = 'weather-app/1.0'
echo.
echo # SSL Configuration
echo SSL_CONFIG = True
echo if os.getenv^('SSL_VERIFY', ''^).lower^(^) == 'false':
echo     SSL_CONFIG = False
echo.
echo async def make_openmeteo_request^(url: str^) -^> dict[str, Any] ^| None:
echo     """Make request with proper error handling."""
echo     headers = {
echo         "User-Agent": user_agent,
echo         "Accept": "application/json"
echo     }
echo     
echo     try:
echo         async with httpx.AsyncClient^(verify=SSL_CONFIG, timeout=30.0^) as client:
echo             response = await client.get^(url, headers=headers^)
echo             response.raise_for_status^(^)
echo             return response.json^(^)
echo     except Exception as e:
echo         print^(f"Request failed: {e}"^)
echo         return None
echo.
echo @mcp.tool^(^)
echo async def get_current_weather^(latitude: float, longitude: float^) -^> str:
echo     """Get current weather for a location."""
echo     url = f"{api_base}/forecast?latitude={latitude}&longitude={longitude}&current=temperature_2m,relative_humidity_2m,precipitation"
echo     data = await make_openmeteo_request^(url^)
echo     if not data:
echo         return "Unable to fetch weather data."
echo     return json.dumps^(data, indent=2^)
echo.
echo @mcp.tool^(^)
echo async def get_forecast^(latitude: float, longitude: float^) -^> str:
echo     """Get weather forecast for a location."""
echo     url = f"{api_base}/forecast?latitude={latitude}&longitude={longitude}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto"
echo     data = await make_openmeteo_request^(url^)
echo     if not data:
echo         return "Unable to fetch forecast data."
echo     
echo     daily = data.get^("daily", {}^)
echo     forecasts = []
echo     for i in range^(len^(daily.get^("time", []^)^)^):
echo         forecast = f"Date: {daily['time'][i]}\nMax: {daily['temperature_2m_max'][i]}°C\nMin: {daily['temperature_2m_min'][i]}°C"
echo         forecasts.append^(forecast^)
echo     return "\n---\n".join^(forecasts^)
echo.
echo if __name__ == "__main__":
echo     mcp.run^(transport='stdio'^)
) > weather_server.py

REM Test the installation
echo 🧪 Testing installation...
uv run python -c "import mcp; import httpx; print('✅ All dependencies installed successfully')"

REM Get current directory
set CURRENT_DIR=%CD%

echo.
echo 🎉 Setup complete!
echo.
echo 📋 Next steps:
echo 1. Test the server:
echo    uv run python weather_server.py
echo.
echo 2. Add to Claude Desktop config:
echo    Path: %%APPDATA%%/Claude/claude_desktop_config.json
echo.
echo    Config content:
echo    {
echo      "mcpServers": {
echo        "weather": {
echo          "command": "uv",
echo          "args": ["run", "--directory", "%CURRENT_DIR%", "python", "weather_server.py"],
echo          "env": {"SSL_VERIFY": "false"}
echo        }
echo      }
echo    }
echo.
echo 3. Restart Claude Desktop
echo 4. Ask Claude: 'What's the weather in Bangkok?'

pause