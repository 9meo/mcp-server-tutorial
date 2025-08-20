# Weather MCP Server

A Model Context Protocol (MCP) server that provides weather information using the OpenMeteo API. This server integrates with Claude Desktop to allow natural language weather queries.

## 🌦️ Features

- **Current Weather**: Get real-time weather data for any location with coordinates
- **Weather Forecast**: 7-day weather forecast with temperature and precipitation data
- **City Search**: Quick weather lookup for major cities (Bangkok, Tokyo, New York, etc.)
- **MCP Integration**: Seamless integration with Claude Desktop and other MCP clients
- **Error Handling**: Robust error handling for SSL, network, and API issues
- **Multiple Transports**: Support for stdio, HTTP, and SSE transports
- **Cross-Platform**: Works on Windows, macOS, Linux, and WSL

## 🚀 Quick Start

### Option 1: Automated Setup

**macOS:**
```bash
curl -sSL https://raw.githubusercontent.com/9meo/mcp-server-tutorial/main/setup_mac.sh | bash
```

**Linux/WSL:**
```bash
curl -sSL https://raw.githubusercontent.com/9meo/mcp-server-tutorial/main/setup.sh | bash
```

**Windows:**
```cmd
curl -sSL https://raw.githubusercontent.com/9meo/mcp-server-tutorial/main/setup.bat -o setup.bat && setup.bat
```

**WSL (Windows Subsystem for Linux):**
```bash
# Open WSL terminal and run:
curl -sSL https://raw.githubusercontent.com/9meo/mcp-server-tutorial/main/setup.sh | bash
```

### Option 2: Manual Setup

#### Prerequisites
- Python 3.8 or higher
- Internet connection for API access
- For WSL users: WSL 2 recommended

#### Step-by-Step Installation

1. **Install UV Package Manager**
   
   **Linux/macOS/WSL:**
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   source ~/.bashrc  # or restart terminal
   ```
   
   **Windows:**
   ```powershell
   powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
   ```

2. **Create Project Directory**
   ```bash
   mkdir weather-mcp && cd weather-mcp
   uv init --name weather-mcp
   ```

3. **Install Dependencies**
   ```bash
   uv add mcp httpx
   ```

4. **Download Server Code**
   
   Copy the `weather_server.py` file from this repository, or create it manually with the provided code.

5. **Test Installation**
   ```bash
   # Test dependencies
   uv run python -c "import mcp, httpx; print('✅ Dependencies installed successfully')"
   
   # Test the server
   uv run python weather_server.py
   ```

#### For WSL Users

WSL (Windows Subsystem for Linux) is fully supported and recommended for Windows users:

```bash
# 1. Open WSL terminal (Ubuntu/Debian recommended)
wsl

# 2. Update packages
sudo apt update && sudo apt install -y curl git

# 3. Follow Linux installation steps above
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## ⚙️ Configuration

### Claude Desktop Setup

1. **Locate Configuration File:**
   - **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
   - **Windows**: `%APPDATA%/Claude/claude_desktop_config.json`

2. **Choose Configuration Based on Your Setup:**

   **Standard Installation (Linux/macOS/Windows):**
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

   **WSL Configuration (Recommended for WSL users):**
   ```json
   {
     "mcpServers": {
       "weather": {
         "command": "wsl",
         "args": ["-e", "bash", "-c", "cd /home/[USERNAME]/weather-mcp && uv run python weather_server.py"],
         "env": {
           "SSL_VERIFY": "false"
         }
       }
     }
   }
   ```

   **WSL Alternative (Using Windows UNC paths):**
   ```json
   {
     "mcpServers": {
       "weather": {
         "command": "uv", 
         "args": ["run", "--directory", "\\\\wsl$\\Ubuntu\\home\\[USERNAME]\\weather-mcp", "python", "weather_server.py"],
         "env": {
           "SSL_VERIFY": "false"
         }
       }
     }
   }
   ```

3. **Important Notes:**
   - Replace `/absolute/path/to/weather-mcp` with your actual project path
   - Replace `[USERNAME]` with your actual username
   - Use forward slashes `/` for Unix paths, backslashes `\\` for Windows paths
   - Restart Claude Desktop after making changes

### Getting Your Project Path

**Linux/macOS/WSL:**
```bash
cd weather-mcp && pwd
```

**Windows:**
```cmd
cd weather-mcp && echo %cd%
```

### Environment Variables

- `SSL_VERIFY`: Set to `"false"` to disable SSL verification (useful in corporate environments with proxy servers)

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
├── weather_server.py          # Main MCP server implementation
├── test_server.py             # Comprehensive test suite
├── pyproject.toml             # Project configuration and dependencies
├── Makefile                   # Development commands
├── Dockerfile                 # Container deployment
├── setup.sh                   # Linux/macOS setup script
├── setup.bat                  # Windows setup script
├── README.md                  # This documentation
├── QUICK_START.md             # Quick setup guide
├── .github/workflows/test.yml # CI/CD pipeline
├── .vscode/                   # VS Code configuration
│   ├── settings.json          # Editor settings
│   └── launch.json            # Debug configuration
├── .gitignore                 # Git ignore rules
└── .venv/                     # Virtual environment (created by UV)
```

### Development Commands

Using Make (Linux/macOS/WSL):
```bash
# Install dependencies
make install

# Run tests
make test

# Start server
make run

# Format code
make format

# Run linting
make lint

# Run all checks
make check

# Start MCP Inspector
make inspector

# Quick development setup
make dev-install
```

Using UV directly:
```bash
# Install dependencies
uv sync

# Add development dependencies
uv add --dev pytest pytest-asyncio black isort mypy

# Run tests
uv run python test_server.py

# Start server
uv run python weather_server.py

# Format code
uv run black weather_server.py test_server.py
uv run isort weather_server.py test_server.py

# Type checking
uv run mypy weather_server.py test_server.py
```

### Running Tests

**Comprehensive Test Suite:**
```bash
# Run all tests
uv run python test_server.py

# Expected output:
# 🧪 Weather MCP Server Test Suite
# ✅ Import tests passed
# ✅ API connectivity working
# ✅ Current weather function working
# ✅ Weather forecast function working
# ✅ City weather function working
# ✅ Error handling working
# 🎉 All tests passed!
```

**Individual Tests:**
```bash
# Test dependencies only
uv run python -c "import mcp; import httpx; print('✅ Dependencies OK')"

# Test API connectivity only
uv run python -c "
import asyncio, httpx
async def test():
    async with httpx.AsyncClient() as client:
        response = await client.get('https://api.open-meteo.com/v1/forecast?latitude=13.7563&longitude=100.5018&current=temperature_2m')
        print('✅ API connectivity OK' if response.status_code == 200 else '❌ API error')
asyncio.run(test())
"
```

### Docker Development

**Build and Run:**
```bash
# Build image
docker build -t weather-mcp .

# Run container
docker run -it --rm weather-mcp

# Development with volume mount
docker run -it --rm -v $(pwd):/app weather-mcp bash
```

### VS Code Setup

The project includes VS Code configuration for optimal development experience:

1. **Install recommended extensions** (Python, WSL if applicable)
2. **Open project in VS Code:**
   ```bash
   code weather-mcp
   ```
3. **Select Python interpreter:** Choose the UV virtual environment
4. **Use debugging:** F5 to start with breakpoints

### Code Quality

**Formatting:**
- **Black**: Code formatting
- **isort**: Import sorting

**Linting:**
- **mypy**: Static type checking
- **VS Code**: Real-time error detection

**Testing:**
- **pytest**: Unit testing framework
- **Custom test suite**: Integration testing

## 🐛 Troubleshooting

### Common Issues

#### 1. SSL Certificate Errors
**Symptoms:** `certificate verify failed` or SSL connection errors
**Solutions:**
```bash
# Option 1: Disable SSL verification (development only)
export SSL_VERIFY=false

# Option 2: Use corporate CA bundle
export SSL_CERT_FILE=/path/to/corporate-ca-bundle.crt

# Option 3: Update certificates
# Ubuntu/Debian
sudo apt update && sudo apt install ca-certificates

# macOS
brew install ca-certificates
```

#### 2. Module Not Found Errors
**Symptoms:** `ModuleNotFoundError: No module named 'mcp'` or similar
**Solutions:**
```bash
# Ensure virtual environment is activated and dependencies installed
uv sync

# Check installation
uv show mcp
uv show httpx

# Reinstall if needed
uv add --force mcp httpx
```

#### 3. Claude Desktop Can't See Tools
**Symptoms:** Claude doesn't respond to weather queries or can't find tools
**Solutions:**
- ✅ Verify absolute paths in `claude_desktop_config.json`
- ✅ Check JSON syntax is valid (use online JSON validator)
- ✅ Restart Claude Desktop after configuration changes
- ✅ Test server independently: `uv run python weather_server.py`

#### 4. WSL-Specific Issues
**Symptoms:** Commands not found or path issues in WSL
**Solutions:**
```bash
# Check WSL version
wsl --version

# Update WSL
wsl --update

# Check if UV is in PATH
which uv
echo $PATH

# Reinstall UV if needed
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
```

#### 5. API Request Failures
**Symptoms:** "Unable to fetch weather data" messages
**Solutions:**
```bash
# Test API connectivity directly
curl "https://api.open-meteo.com/v1/forecast?latitude=13.75&longitude=100.5&current=temperature_2m"

# Check firewall/proxy settings
ping api.open-meteo.com

# Test with timeout
curl --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=0&longitude=0&current=temperature_2m"
```

#### 6. Permission Issues (Linux/macOS/WSL)
**Symptoms:** Permission denied errors
**Solutions:**
```bash
# Make script executable
chmod +x weather_server.py

# Check directory permissions
ls -la weather_server.py

# Fix ownership if needed
sudo chown $USER:$USER weather_server.py
```

### Debug Mode & Logging

**Enable Debug Logging:**
```python
# Add to weather_server.py
import logging
logging.basicConfig(level=logging.DEBUG)
```

**Check Logs:**
- **Claude Desktop Logs:**
  - macOS: `~/Library/Logs/Claude/`
  - Windows: `%APPDATA%/Claude/logs/`
- **Server Output:** Check terminal where you ran the server

**Test Server Independently:**
```bash
# Run server and test tools manually
uv run python test_server.py

# Use MCP Inspector for GUI testing
npx @modelcontextprotocol/inspector uv run python weather_server.py
```

### Getting Help

1. **Check this README** for common solutions
2. **Review Claude Desktop logs** for specific errors
3. **Test server independently** to isolate issues
4. **Verify API connectivity** with curl commands
5. **Check GitHub Issues** for similar problems

If you're still having issues:
- 🐛 **Open an issue** with detailed error information
- 📋 **Include your OS, Python version, and error logs**
- 🔍 **Mention if you're using WSL or corporate network**

## 🤝 Usage Examples

Once configured with Claude Desktop, you can interact using natural language:

### Basic Weather Queries
- **"What's the weather in Bangkok?"**
- **"Show me the current temperature in Tokyo"**
- **"How's the weather at coordinates 40.7128, -74.0060?"** (New York)

### Forecast Queries  
- **"Can you get the 7-day forecast for London?"**
- **"What will the weather be like in Singapore this week?"**
- **"Show me the forecast for Paris for the next few days"**

### Supported Cities (via `get_weather_by_city` tool)
- Bangkok, Tokyo, New York, London, Paris, Singapore, Sydney, Los Angeles

### Advanced Queries
- **"Compare the weather between Bangkok and Tokyo"**
- **"What's the humidity in New York right now?"**
- **"Will it rain in London this week?"**

### Example Interaction
```
User: "What's the weather like in Bangkok right now?"

Claude: I'll check the current weather in Bangkok for you.

[Claude calls get_current_weather(13.7563, 100.5018)]

Based on the current weather data for Bangkok:

🌡️ **Temperature**: 32°C
💧 **Humidity**: 65%
🌦️ **Conditions**: Partly cloudy
💧 **Precipitation**: 0mm

The weather in Bangkok is warm and humid with partly cloudy skies.
```

## 📚 Technical Details

### API Integration
- **Data Source**: [OpenMeteo API](https://open-meteo.com/) - Free weather API with no API key required
- **Update Frequency**: Real-time data with hourly updates
- **Coverage**: Global weather data for any coordinates
- **Rate Limits**: Fair use policy, no authentication required

### MCP Protocol Features
- **Transport**: stdio (for Claude Desktop), HTTP and SSE also supported
- **Tools**: 3 weather-related tools exposed to Claude
- **Resources**: Popular cities list for reference
- **Error Handling**: Graceful fallbacks and informative error messages

### Performance & Reliability
- **Timeout**: 30-second request timeout
- **Retry Logic**: Built-in error handling for network issues
- **SSL Support**: Configurable SSL verification
- **Async**: Non-blocking async/await implementation

## 🌟 Platform-Specific Notes

### Windows Users
- **Recommended**: Use WSL for better performance and compatibility
- **Alternative**: Native Windows installation works but may have SSL issues in corporate environments
- **Path Format**: Use backslashes `\` or double backslashes `\\` in config files

### macOS Users
- **Homebrew**: Can install UV via `brew install uv`
- **Path Format**: Use forward slashes `/` in config files
- **Permissions**: May need to allow terminal access in System Preferences

### Linux Users
- **Package Managers**: UV available in most package repositories
- **Dependencies**: May need to install `curl`, `git`, and `build-essential`
- **Permissions**: Ensure proper file permissions with `chmod +x`

### WSL Users (Recommended for Windows)
- **Performance**: Better than native Windows for Python development
- **Compatibility**: Full Linux compatibility
- **Integration**: Easy VS Code integration with WSL extension
- **Configuration**: Use either WSL commands or UNC paths in Claude config

## 🚀 Quick Commands Reference

### Setup
```bash
# One-line setup (Linux/macOS/WSL)
curl -sSL https://raw.githubusercontent.com/your-repo/weather-mcp/main/setup.sh | bash

# Manual setup
mkdir weather-mcp && cd weather-mcp
uv init && uv add mcp httpx
# Copy weather_server.py and configure Claude Desktop
```

### Testing
```bash
# Test everything
make test  # or: uv run python test_server.py

# Test specific components
uv run python -c "import mcp, httpx; print('✅ OK')"
make inspector  # GUI testing tool
```

### Running
```bash
# Start server
make run  # or: uv run python weather_server.py

# Debug mode
DEBUG=true uv run python weather_server.py
```

### Development
```bash
# Format code
make format  # or: uv run black . && uv run isort .

# Type checking
make lint  # or: uv run mypy weather_server.py

# All checks
make check
```

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Links

- 📖 **[Model Context Protocol Documentation](https://modelcontextprotocol.io/)** - Official MCP docs
- 🐍 **[MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk)** - Python implementation
- 🌤️ **[OpenMeteo API](https://open-meteo.com/)** - Weather data source
- ⚡ **[UV Package Manager](https://github.com/astral-sh/uv)** - Fast Python package manager
- 🪟 **[WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)** - Windows Subsystem for Linux
- 🤖 **[Claude Desktop](https://claude.ai/desktop)** - AI assistant with MCP support

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork the repository** on GitHub
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes** and add tests if applicable
4. **Run the test suite**: `make check` or `uv run python test_server.py`
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to your branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request** with a clear description

### Development Guidelines
- Follow existing code style (use `make format`)
- Add tests for new functionality
- Update documentation as needed
- Ensure all tests pass (`make test`)

## 📞 Support & Community

### Getting Help
1. 📖 **Check this README** for comprehensive documentation
2. 🐛 **Search existing issues** on GitHub
3. 💬 **Open a new issue** with detailed information including:
   - Operating system and version
   - Python version (`python --version`)
   - UV version (`uv --version`)
   - Complete error messages and logs
   - Steps to reproduce the issue

### Community
- 💬 **GitHub Discussions** - Ask questions and share ideas
- 🐛 **GitHub Issues** - Report bugs and request features
- 📖 **MCP Community** - Join the broader MCP ecosystem discussions

### Reporting Issues
When reporting issues, please include:
- **Environment**: OS, Python version, WSL if applicable
- **Installation method**: Automatic script vs manual
- **Error logs**: Complete error messages
- **Steps to reproduce**: What you did before the error occurred
- **Expected behavior**: What should have happened

---

**Made with ❤️ for the MCP community**

*Star ⭐ this repository if you find it helpful!*
