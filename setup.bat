@echo off
echo 🌦️  Setting up Weather MCP Server with Python 3.10 on Windows...

REM Check if Python 3.10 is available
python3.10 --version >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✅ Python 3.10 is available
    set PYTHON_CMD=python3.10
) else (
    python --version | findstr "3.10" >nul
    if %ERRORLEVEL% EQU 0 (
        echo ✅ Python 3.10 is available as 'python'
        set PYTHON_CMD=python
    ) else (
        echo ⚠️  Python 3.10 not found. Please install Python 3.10 from python.org
        echo    Download from: https://www.python.org/downloads/
        pause
        exit /b 1
    )
)

REM Check if UV is installed
where uv >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo 📦 Installing UV...
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    REM Refresh environment variables
    call refreshenv 2>nul || (
        echo ⚠️  Please restart your terminal or run: refreshenv
        echo    Or add UV to PATH manually
    )
) else (
    echo ✅ UV is already installed
)

REM Verify UV is available
where uv >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ UV not found after installation. Please restart terminal or add to PATH.
    pause
    exit /b 1
)

REM Create project directory
set PROJECT_DIR=weather-mcp
echo 📁 Creating project directory: %PROJECT_DIR%
mkdir %PROJECT_DIR% 2>nul
cd %PROJECT_DIR%

REM Configure UV to use Python 3.10
echo 🐍 Configuring UV to use Python 3.10...
uv python install 3.10
uv python pin 3.10

REM Initialize UV project with Python 3.10
echo 🚀 Initializing UV project with Python 3.10...
uv init --name weather-mcp --python 3.10

REM Verify Python version
echo 🔍 Verifying Python version...
uv run python --version

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
echo     except ssl.SSLError as e:
echo         print^(f"SSL error: {e}"^)
echo         return None
echo     except httpx.HTTPStatusError as e:
echo         print^(f"HTTP error {e.response.status_code}"^)
echo         return None
echo     except Exception as e:
echo         print^(f"Request failed: {e}"^)
echo         return None
echo.
echo @mcp.tool^(^)
echo async def get_current_weather^(latitude: float, longitude: float^) -^> str:
echo     """Get current weather for a location.
echo     
echo     Args:
echo         latitude: Latitude of the location
echo         longitude: Longitude of the location
echo         
echo     Returns:
echo         str: JSON string with current weather data
echo     """
echo     url = f"{api_base}/forecast?latitude={latitude}&longitude={longitude}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code"
echo     
echo     print^(f"Making weather request to: {url}"^)
echo     data = await make_openmeteo_request^(url^)
echo     if not data:
echo         return "Unable to fetch weather data."
echo     
echo     return json.dumps^(data, indent=2^)
echo.
echo @mcp.tool^(^)
echo async def get_forecast^(latitude: float, longitude: float^) -^> str:
echo     """Get weather forecast for a location.
echo     
echo     Args:
echo         latitude: Latitude of the location
echo         longitude: Longitude of the location
echo         
echo     Returns:
echo         str: Formatted weather forecast
echo     """
echo     url = f"{api_base}/forecast?latitude={latitude}&longitude={longitude}&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code&timezone=auto"
echo     
echo     print^(f"Making forecast request to: {url}"^)
echo     data = await make_openmeteo_request^(url^)
echo     if not data:
echo         return "Unable to fetch forecast data."
echo     
echo     # Format the data for readability
echo     daily = data.get^("daily", {}^)
echo     forecasts = []
echo     
echo     for i in range^(len^(daily.get^("time", []^)^)^):
echo         forecast = f"""Date: {daily['time'][i]}
echo Max Temperature: {daily['temperature_2m_max'][i]}°C
echo Min Temperature: {daily['temperature_2m_min'][i]}°C
echo Precipitation: {daily['precipitation_sum'][i]} mm"""
echo         forecasts.append^(forecast^)
echo     
echo     return "\n---\n".join^(forecasts^)
echo.
echo @mcp.tool^(^)
echo async def get_weather_by_city^(city_name: str^) -^> str:
echo     """Get current weather by city name ^(requires geocoding^).
echo     
echo     Args:
echo         city_name: Name of the city
echo         
echo     Returns:
echo         str: Weather information for the city
echo     """
echo     # Simple geocoding for major cities
echo     city_coordinates = {
echo         "bangkok": ^(13.7563, 100.5018^),
echo         "tokyo": ^(35.6762, 139.6503^),
echo         "new york": ^(40.7128, -74.0060^),
echo         "london": ^(51.5074, -0.1278^),
echo         "paris": ^(48.8566, 2.3522^),
echo         "singapore": ^(1.3521, 103.8198^),
echo         "sydney": ^(-33.8688, 151.2093^),
echo         "los angeles": ^(34.0522, -118.2437^)
echo     }
echo     
echo     city_lower = city_name.lower^(^)
echo     if city_lower in city_coordinates:
echo         lat, lon = city_coordinates[city_lower]
echo         return await get_current_weather^(lat, lon^)
echo     else:
echo         return f"Sorry, coordinates for '{city_name}' are not available. Please provide latitude and longitude coordinates."
echo.
echo @mcp.resource^("weather://popular-cities"^)
echo async def get_popular_cities^(^):
echo     """Get list of popular cities with weather support."""
echo     cities = [
echo         "Bangkok ^(13.7563, 100.5018^)",
echo         "Tokyo ^(35.6762, 139.6503^)", 
echo         "New York ^(40.7128, -74.0060^)",
echo         "London ^(51.5074, -0.1278^)",
echo         "Paris ^(48.8566, 2.3522^)",
echo         "Singapore ^(1.3521, 103.8198^)",
echo         "Sydney ^(-33.8688, 151.2093^)",
echo         "Los Angeles ^(34.0522, -118.2437^)"
echo     ]
echo     return "\n".join^(cities^)
echo.
echo if __name__ == "__main__":
echo     mcp.run^(transport='stdio'^)
) > weather_server.py

REM Test the installation
echo 🧪 Testing installation...
uv run python -c "import mcp; import httpx; print('✅ All dependencies installed successfully')"

REM Create test file
echo 📝 Creating test_server.py...
(
echo #!/usr/bin/env python3
echo """
echo Test script for Weather MCP Server
echo Run this to verify your server is working correctly
echo """
echo.
echo import asyncio
echo import json
echo import sys
echo from pathlib import Path
echo.
echo # Add the current directory to the path so we can import our server
echo sys.path.insert^(0, str^(Path^(__file__^).parent^)^)
echo.
echo try:
echo     from weather_server import get_current_weather, get_forecast, get_weather_by_city, make_openmeteo_request
echo     print^("✅ Successfully imported weather server modules"^)
echo except ImportError as e:
echo     print^(f"❌ Failed to import weather server modules: {e}"^)
echo     sys.exit^(1^)
echo.
echo async def test_api_connectivity^(^):
echo     """Test basic API connectivity"""
echo     print^("\n🌐 Testing API connectivity..."^)
echo     
echo     url = "https://api.open-meteo.com/v1/forecast?latitude=13.7563&longitude=100.5018&current=temperature_2m"
echo     result = await make_openmeteo_request^(url^)
echo     
echo     if result:
echo         print^("✅ API connectivity successful"^)
echo         return True
echo     else:
echo         print^("❌ API connectivity failed"^)
echo         return False
echo.
echo async def test_current_weather^(^):
echo     """Test current weather function"""
echo     print^("\n🌡️  Testing current weather function..."^)
echo     
echo     # Test Bangkok coordinates
echo     lat, lon = 13.7563, 100.5018
echo     result = await get_current_weather^(lat, lon^)
echo     
echo     if result and result != "Unable to fetch weather data.":
echo         print^("✅ Current weather function working"^)
echo         try:
echo             data = json.loads^(result^)
echo             if "current" in data:
echo                 print^(f"   📊 Sample data: Temperature = {data['current'].get^('temperature_2m', 'N/A'^)}°C"^)
echo             return True
echo         except json.JSONDecodeError:
echo             print^("⚠️  Current weather function working but returned non-JSON data"^)
echo             return True
echo     else:
echo         print^("❌ Current weather function failed"^)
echo         return False
echo.
echo async def run_all_tests^(^):
echo     """Run all tests and provide a summary"""
echo     print^("🧪 Weather MCP Server Test Suite"^)
echo     print^("=" * 50^)
echo     
echo     # Test imports first
echo     print^("📦 Testing imports..."^)
echo     
echo     try:
echo         import mcp
echo         print^("✅ MCP module imported successfully"^)
echo     except ImportError:
echo         print^("❌ MCP module not found"^)
echo         return False
echo     
echo     try:
echo         import httpx
echo         print^("✅ HTTPX module imported successfully"^)
echo     except ImportError:
echo         print^("❌ HTTPX module not found"^)
echo         return False
echo     
echo     # Run async tests
echo     tests = [test_api_connectivity, test_current_weather]
echo     results = []
echo     
echo     for test in tests:
echo         try:
echo             result = await test^(^)
echo             results.append^(result^)
echo         except Exception as e:
echo             print^(f"❌ Test {test.__name__} failed with exception: {e}"^)
echo             results.append^(False^)
echo     
echo     # Summary
echo     print^("\n" + "=" * 50^)
echo     print^("📊 Test Summary:"^)
echo     passed = sum^(results^)
echo     total = len^(results^)
echo     
echo     print^(f"   ✅ Passed: {passed}/{total}"^)
echo     if passed == total:
echo         print^("   🎉 All tests passed! Your MCP server is ready to use."^)
echo     else:
echo         print^("   ⚠️  Some tests failed. Check the output above for details."^)
echo     
echo     return passed == total
echo.
echo if __name__ == "__main__":
echo     success = asyncio.run^(run_all_tests^(^)^)
echo     sys.exit^(0 if success else 1^)
) > test_server.py

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
echo.
echo 💡 Windows Tips:
echo    • Your project is at: %CURRENT_DIR%
echo    • Use 'code .' to open in VS Code
echo    • Test with: uv run python test_server.py
echo.
echo 🔧 Troubleshooting:
echo    • Test dependencies: uv run python -c "import mcp, httpx; print('OK')"
echo    • Check UV: uv --version
echo    • Use full paths in Claude config if needed

pause