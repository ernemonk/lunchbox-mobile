#!/usr/bin/env python3
"""
Quick test script for Image Recognition function
Sends a test image to the local server and displays the results.
"""

import base64
import json
import sys
from pathlib import Path

try:
    import requests
except ImportError:
    print("❌ requests library not found. Install it:")
    print("   pip install requests")
    sys.exit(1)


def test_local_vision(image_path: str, url: str = "http://localhost:8081"):
    """Test the local image recognition server with an image file."""
    
    # Read and encode the image
    try:
        with open(image_path, "rb") as f:
            image_bytes = f.read()
            image_base64 = base64.b64encode(image_bytes).decode("utf-8")
    except FileNotFoundError:
        print(f"❌ Image file not found: {image_path}")
        return
    
    # Send request
    print(f"📸 Testing with image: {image_path}")
    print(f"🌐 Server: {url}")
    print("⏳ Sending request...\n")
    
    payload = {"image": image_base64}
    
    try:
        response = requests.post(url, json=payload, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            
            print("✅ Detection Results:")
            print("=" * 50)
            
            if "items" in result and result["items"]:
                print(f"\n🍎 Detected {len(result['items'])} food items:\n")
                for i, item in enumerate(result["items"], 1):
                    conf = item.get("confidence", 0) * 100
                    print(f"  {i}. {item['name']} ({conf:.1f}%)")
            else:
                print("\n⚠️  No food items detected")
            
            # Show raw response for debugging
            print(f"\n📊 Full response:")
            print(json.dumps(result, indent=2))
            
        else:
            print(f"❌ Error: HTTP {response.status_code}")
            print(response.text)
            
    except requests.exceptions.ConnectionError:
        print(f"❌ Connection failed. Is the server running on {url}?")
        print("   Start it with: ./start_local.sh")
    except Exception as e:
        print(f"❌ Error: {e}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_vision.py <image_path> [server_url]")
        print()
        print("Example:")
        print("  python test_vision.py test_image.jpg")
        print("  python test_vision.py test_image.jpg http://localhost:8081")
        sys.exit(1)
    
    image_path = sys.argv[1]
    server_url = sys.argv[2] if len(sys.argv) > 2 else "http://localhost:8081"
    
    test_local_vision(image_path, server_url)
