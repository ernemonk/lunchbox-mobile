#!/usr/bin/env python3
"""
Lunchbox Barcode Server Launcher
Double-click this file to start the barcode enrichment server
"""

import os
import sys
import subprocess
import time
from pathlib import Path

def main():
    print("🚀 Lunchbox Barcode Server Launcher")
    print("=" * 50)
    
    # Get the directory where this script is located
    script_dir = Path(__file__).parent.absolute()
    cloud_functions_dir = script_dir / "backend" / "cloud-functions"
    local_server_path = cloud_functions_dir / "local_server.py"
    
    print(f"📁 Script location: {script_dir}")
    print(f"📁 Cloud functions directory: {cloud_functions_dir}")
    
    # Check if directories exist
    if not cloud_functions_dir.exists():
        print(f"❌ Error: Cloud functions directory not found!")
        print(f"   Expected: {cloud_functions_dir}")
        input("Press Enter to exit...")
        return 1
    
    if not local_server_path.exists():
        print(f"❌ Error: local_server.py not found!")
        print(f"   Expected: {local_server_path}")
        input("Press Enter to exit...")
        return 1
    
    # Check if Flask is available
    try:
        import flask
        print("✅ Flask is available")
    except ImportError:
        print("⚠️  Flask not found. Installing Flask...")
        try:
            subprocess.run([sys.executable, "-m", "pip", "install", "flask"], check=True)
            print("✅ Flask installed successfully")
        except subprocess.CalledProcessError:
            print("❌ Error: Failed to install Flask")
            input("Press Enter to exit...")
            return 1
    
    print("=" * 50)
    print("🌐 Starting server on http://localhost:8080")
    print("📡 Available endpoints:")
    print("   GET  /       - Health check")
    print("   POST /enrich - Barcode enrichment")
    print("")
    print("⚠️  To stop the server, close this window or press Ctrl+C")
    print("=" * 50)
    
    # Change to the cloud functions directory
    os.chdir(cloud_functions_dir)
    
    # Start the server
    try:
        subprocess.run([sys.executable, "local_server.py"])
    except KeyboardInterrupt:
        print("\n👋 Server stopped by user")
    except Exception as e:
        print(f"\n❌ Error starting server: {e}")
        input("Press Enter to exit...")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())