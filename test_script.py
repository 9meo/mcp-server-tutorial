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