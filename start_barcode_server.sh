#!/bin/bash

# Lunchbox Barcode Server Startup Script
# This script starts the local barcode enrichment server

echo "🚀 Starting Lunchbox Barcode Server..."
echo "=================================================="

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
LOCAL_DEV_DIR="$SCRIPT_DIR/backend/local-dev"

echo "📁 Script location: $SCRIPT_DIR"
echo "📁 Local dev directory: $LOCAL_DEV_DIR"

# Check if the local-dev directory exists
if [ ! -d "$LOCAL_DEV_DIR" ]; then
    echo "❌ Error: Local dev directory not found!"
    echo "   Expected: $LOCAL_DEV_DIR"
    echo ""
    echo "💡 Tip: The backend has been reorganized."
    echo "   Use: cd backend/local-dev && ./start_server.sh"
    read -p "Press any key to exit..."
    exit 1
fi

# Check if server.py exists
if [ ! -f "$LOCAL_DEV_DIR/server.py" ]; then
    echo "❌ Error: server.py not found!"
    echo "   Expected: $LOCAL_DEV_DIR/server.py"
    read -p "Press any key to exit..."
    exit 1
fi

# Change to the local-dev directory
cd "$LOCAL_DEV_DIR"
echo "📂 Changed to directory: $(pwd)"

# Check if start script exists
if [ -f "start_server.sh" ]; then
    echo "✅ Found start_server.sh, delegating to local script..."
    echo "=================================================="
    exec ./start_server.sh
fi

# Fallback to manual start if script not found
echo "⚠️  start_server.sh not found, starting manually..."

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed or not in PATH"
    read -p "Press any key to exit..."
    exit 1
fi

# Check if Flask is available
if ! python3 -c "import flask" &> /dev/null; then
    echo "⚠️  Flask not found. Installing Flask..."
    pip3 install flask
    if [ $? -ne 0 ]; then
        echo "❌ Error: Failed to install Flask"
        read -p "Press any key to exit..."
        exit 1
    fi
fi

echo "✅ All dependencies checked"

# Check if port 8080 is in use and kill the process
PORT=8080
PID=$(lsof -ti:$PORT)
if [ ! -z "$PID" ]; then
    echo "⚠️  Port $PORT is already in use by process $PID"
    echo "🔪 Killing existing process..."
    kill -9 $PID
    sleep 1
    echo "✅ Port $PORT is now free"
fi

echo "=================================================="
echo "🌐 Starting server on http://localhost:8080"
echo "📡 Available endpoints:"
echo "   GET  /              - Health check"
echo "   POST /smart_lookup  - Barcode enrichment"
echo "   GET  /sources       - List data sources"
echo ""
echo "⚠️  To stop the server, press Ctrl+C"
echo "=================================================="

# Start the server
python3 server.py