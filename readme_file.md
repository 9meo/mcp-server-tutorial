# Weather MCP Server

A Model Context Protocol (MCP) server that provides weather information using the OpenMeteo API. This server integrates with Claude Desktop to allow natural language weather queries.

## 🌦️ Features

- **Current Weather**: Get real-time weather data for any location
- **Weather Forecast**: 7-day weather forecast with temperature and precipitation
- **City Search**: Search weather by city name for major cities
- **MCP Integration**: Seamless integration with Claude Desktop
- **Error Handling**: Robust error handling for network and API issues

## 🚀 Quick Start

### Option 1: Automated Setup

**Linux/macOS:**
```bash
curl -sSL https://raw.githubusercontent.com/your-repo/weather-mcp/main/setup.sh | bash
```

**Windows:**
```cmd
curl -sSL https://raw.githubusercontent.com/your-repo/weather-mcp/main/setup.bat -o setup.bat && setup.bat
```

### Option 2: Manual Setup

1. **Install UV (if not already installed)**
   ```bash
   # Linux/macOS
   curl -LsSf https://astral.sh/uv/install.sh | sh
   
   # Windows
   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```

2. **Create Project**
   ```bash
   mkdir weather-mcp && cd weather-mcp
   uv init --name weather-mcp
   ```

3. **Install Dependencies**
   ```bash
   uv add mcp httpx
   ```

4. **Copy the weather_server.py file** (from artifacts above)

5. **Test the Server**
   ```bash
   uv run python weather_server.py
   ```

## ⚙️ Configuration

### Claude Desktop Setup

1. **Locate Configuration File:**
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows**: `%APPDATA%/Claude/claude_desktop_config.json`

2. **Add Configuration:**
   ```json
   {
     "mcpServers": {
       "weather": {
         "command": "uv",
         "args": ["run", "--directory", "/absolute/path/to/weather-mcp", "python", "weather_server.py"],
         "env": {
           "SSL_VERIFY": "false"
         }
       }
     }
   }
   ```

3. **Restart Claude Desktop**

### Environment Variables

- `SSL_VERIFY`: Set to `"false"` to disable SSL verification (useful in corporate environments)

## 🛠️ Available Tools

### `get_current_weather(latitude, longitude)`
Get current weather conditions for specified coordinates.

**Parameters:**
- `latitude` (float): Latitude of the location
- `longitude` (float): Longitude of the location

**Example:**
```python
await get_current_weather(13.7563, 100.5018)  # Bangkok
```

### `get_forecast(latitude, longitude)`
Get 7-day weather forecast for specified coordinates.

**Parameters:**
- `latitude` (float): Latitude of the location
- `longitude` (float): Longitude of the location

### `get_weather_by_city(city_name)`
Get current weather by city name (supports major cities).

**Parameters:**
- `city_name` (str): Name of the city

**Supported Cities:**
- Bangkok, Tokyo, New York, London, Paris, Singapore, Sydney, Los Angeles

## 📚 Resources

### `weather://popular-cities`
Returns a list of popular cities with their coordinates that are supported by the `get_weather_by_city` tool.

## 🔧 Development

### Project Structure
```
weather-mcp/
├── weather_server.py      # Main MCP server
├── pyproject.toml         # Project configuration
├── README.md             # This file
└── .venv/               # Virtual environment (created by UV)
```

### Running Tests
```bash
# Test dependencies
uv run python -c "import mcp; import httpx; print('✅ Dependencies OK')"

# Test API connectivity
uv run python -c "
import asyncio
import httpx

async def test():
    async with httpx.AsyncClient() as client:
        response = await client.get('https://api.open-meteo.com/v1/forecast?latitude=13.7563&longitude=100.5018&current=temperature_2m')
        print('✅ API connectivity OK' if response.status_code == 200 else '❌ API error')

asyncio.run(test())
"
```

### Development Dependencies
```bash
uv add --dev pytest pytest-asyncio black isort mypy
```

## 🐛 Troubleshooting

### Common Issues

1. **SSL Certificate Errors**
   - Set `SSL_VERIFY=false` in environment variables
   - Common in corporate environments with proxy servers

2. **Module Not Found**
   - Ensure all dependencies are installed: `uv sync`
   - Check virtual environment is activated

3. **Claude Can't See Tools**
   - Verify absolute paths in `claude_desktop_config.json`
   - Check JSON syntax is valid
   - Restart Claude Desktop after configuration changes

4. **API Request Failures**
   - Check internet connectivity
   - Verify OpenMeteo API is accessible
   - Check if corporate firewall is blocking requests

### Debug Mode
Add debug logging to see what's happening:

```python
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Log Files
- **Claude Desktop Logs:**
  - macOS: `~/Library/Logs/Claude/`
  - Windows: `%APPDATA%/Claude/logs/`

## 🤝 Usage Examples

Once configured with Claude Desktop, you can ask natural language questions:

- "What's the weather in Bangkok?"
- "Can you get the forecast for New York for the next week?"
- "How's the weather at coordinates 35.6762, 139.6503?"
- "Show me the temperature in Tokyo"

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Links

- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)
- [OpenMeteo API](https://open-meteo.com/)
- [UV Package Manager](https://github.com/astral-sh/uv)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Claude Desktop logs
3. Test the server independently
4. Open an issue with detailed error information