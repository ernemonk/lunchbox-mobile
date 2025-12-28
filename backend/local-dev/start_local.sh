#!/bin/bash
# Start local development server with both APIs

cd "$(dirname "$0")"

echo "🔧 Setting up environment..."
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/vision-key.json"

echo "🚀 Starting combined local server..."
echo ""
venv/bin/python local_server.py
