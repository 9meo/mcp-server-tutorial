# Weather MCP Server Makefile
# Provides convenient commands for development and testing

.PHONY: help install test run clean format lint check inspector

# Default target
help:
	@echo "Weather MCP Server - Available Commands:"
	@echo ""
	@echo "Setup Commands:"
	@echo "  install     - Install all dependencies"
	@echo "  clean       - Clean virtual environment and cache"
	@echo ""
	@echo "Development Commands:"
	@echo "  test        - Run all tests"
	@echo "  run         - Run the MCP server"
	@echo "  format      - Format code with black and isort"
	@echo "  lint        - Run linting with mypy"
	@echo "  check       - Run format + lint + test"
	@echo ""
	@echo "Tools:"
	@echo "  inspector   - Run MCP Inspector for testing"
	@echo ""
	@echo "Examples:"
	@echo "  make install && make test && make run"

# Install dependencies
install:
	@echo "📦 Installing dependencies..."
	uv sync
	@echo "✅ Dependencies installed"

# Clean up
clean:
	@echo "🧹 Cleaning up..."
	rm -rf .venv
	rm -rf __pycache__
	rm -rf *.pyc
	rm -rf .pytest_cache
	rm -rf .mypy_cache
	@echo "✅ Cleaned up"

# Run tests
test:
	@echo "🧪 Running tests..."
	uv run python test_server.py

# Run the server
run:
	@echo "🚀 Starting Weather MCP Server..."
	@echo "Press Ctrl+C to stop"
	uv run python weather_server.py

# Format code
format:
	@echo "✨ Formatting code..."
	uv run black weather_server.py test_server.py
	uv run isort weather_server.py test_server.py
	@echo "✅ Code formatted"

# Run linting
lint:
	@echo "🔍 Running linting..."
	uv run mypy weather_server.py test_server.py

# Run all checks
check: format lint test
	@echo "✅ All checks passed"

# Run MCP Inspector
inspector:
	@echo "🔍 Starting MCP Inspector..."
	@echo "This will open a web interface for testing your MCP server"
	npx @modelcontextprotocol/inspector uv run python weather_server.py

# Development setup
dev-install: install
	@echo "🛠️  Installing development dependencies..."
	uv add --dev pytest pytest-asyncio black isort mypy
	@echo "✅ Development environment ready"

# Quick start for new users
quick-start: install test
	@echo ""
	@echo "🎉 Quick start complete!"
	@echo ""
	@echo "Next steps:"
	@echo "1. Configure Claude Desktop:"
	@echo "   - Edit: ~/Library/Application Support/Claude/claude_desktop_config.json"
	@echo "   - Add the configuration from README.md"
	@echo "2. Restart Claude Desktop"
	@echo "3. Test with: 'What's the weather in Bangkok?'"

# Check if UV is installed
check-uv:
	@which uv > /dev/null || (echo "❌ UV not found. Please install: curl -LsSf https://astral.sh/uv/install.sh | sh" && exit 1)
	@echo "✅ UV is installed"

# Show project status
status:
	@echo "📊 Project Status:"
	@echo "  UV Version: $$(uv --version)"
	@echo "  Python Version: $$(uv run python --version)"
	@echo "  Project Directory: $$(pwd)"
	@echo "  Dependencies:"
	@uv tree 2>/dev/null || echo "    Run 'make install' to see dependencies"