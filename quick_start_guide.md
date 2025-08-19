# 🚀 Quick Start Guide - Weather MCP Server

## One-Command Setup

### Linux/macOS
```bash
curl -sSL https://raw.githubusercontent.com/your-repo/weather-mcp/main/setup.sh | bash
```

### Windows
```cmd
curl -sSL https://raw.githubusercontent.com/your-repo/weather-mcp/main/setup.bat -o setup.bat && setup.bat
```

## Manual Setup (5 minutes)

### 1. Install UV
```bash
# Linux/macOS
curl -LsSf https://astral.sh/uv/install.sh | sh

# Windows PowerShell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### 2. Create Project
```bash
mkdir weather-mcp && cd weather-mcp
uv init --name weather-mcp
uv add mcp httpx
```

### 3. Download Server Code
Save this as `weather_server.py`:
```python
from mcp.server.fastmcp import FastMCP
import httpx
import json

mcp = FastMCP('weather')

@mcp.tool()
async def get_weather(latitude: float, longitude: float) -> str:
    """Get weather for coordinates"""
    url = f"https://api.open-meteo.com/v1/forecast?latitude={latitude}&longitude={longitude}&current=temperature_2m"
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        return json.dumps(response.json(), indent=2)

if __name__ == "__main__":
    mcp.run(transport='stdio')
```

### 4. Test
```bash
uv run python weather_server.py
```

### 5. Configure Claude Desktop

**File Location:**
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%/Claude/claude_desktop_config.json`

**Content:**
```json
{
  "mcpServers": {
    "weather": {
      "command": "uv",
      "args": ["run", "--directory", "/full/path/to/weather-mcp", "python", "weather_server.py"]
    }
  }
}
```

### 6. Use with Claude
1. Restart Claude Desktop
2. Ask: "What's the weather in Bangkok?"
3. Watch Claude use your MCP server! 🎉

## Troubleshooting

### Common Issues
- **Path Error**: Use absolute paths in config
- **SSL Error**: Add `"env": {"SSL_VERIFY": "false"}` to config
- **Import Error**: Run `uv sync` to install dependencies

### Test Commands
```bash
# Test dependencies
uv run python -c "import mcp, httpx; print('✅ OK')"

# Test API
uv run python -c "
import asyncio, httpx
async def test():
    async with httpx.AsyncClient() as client:
        r = await client.get('https://api.open-meteo.com/v1/forecast?latitude=0&longitude=0&current=temperature_2m')
        print(f'✅ API: {r.status_code}')
asyncio.run(test())
"
```

## Next Steps
- Add more weather features
- Try other MCP examples
- Read the full documentation

**Need help?** Check the README.md for detailed instructions!