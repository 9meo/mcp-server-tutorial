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

# SSL Configuration for corporate environments
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
    # Run the MCP server using stdio transport for Claude Desktop
    mcp.run(transport='stdio')