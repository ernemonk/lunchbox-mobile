#!/bin/bash
# Local Development Server Startup Script

echo "🚀 Starting Local Barcode Development Server..."
echo "=================================================="

# Change to the local-dev directory
cd "$(dirname "$0")"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install/update dependencies
echo "📥 Installing dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt
pip install -q -r ../shared/requirements.txt

echo "=================================================="
echo "✅ Environment ready"

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

echo "🌐 Starting server on http://localhost:8080"
echo ""
echo "📡 Available endpoints:"
echo "   GET  /              - Health check"
echo "   GET  /sources       - List data sources"  
echo "   POST /smart_lookup  - Barcode lookup"
echo "   POST /confirm       - User confirmation"
echo "   GET  /stats         - Database statistics"
echo ""
echo "⚠️  Press Ctrl+C to stop the server"
echo "=================================================="
echo ""

# Start the server
python3 server.py
