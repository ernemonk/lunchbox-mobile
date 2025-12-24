#!/usr/bin/env python3
"""
Quick test script for Cloud Vision API
Analyzes an image and prints detected food items
"""

import sys
import base64
import json
from pathlib import Path

# Set credentials
import os
vision_key = Path(__file__).parent / "vision-key.json"
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = str(vision_key)

from google.cloud import vision

def analyze_image(image_path):
    """Analyze image and detect food items"""
    
    # Read and encode image
    with open(image_path, 'rb') as f:
        image_bytes = f.read()
    
    # Create Vision API client
    client = vision.ImageAnnotatorClient()
    image = vision.Image(content=image_bytes)
    
    print(f"\n🔍 Analyzing: {image_path}")
    print("=" * 60)
    
    # Label detection
    print("\n📋 Label Detection:")
    label_response = client.label_detection(image=image)
    for label in label_response.label_annotations[:10]:
        print(f"  • {label.description}: {label.score*100:.1f}%")
    
    # Object localization
    print("\n🎯 Object Localization:")
    object_response = client.object_localization(image=image)
    for obj in object_response.localized_object_annotations[:10]:
        print(f"  • {obj.name}: {obj.score*100:.1f}%")
    
    print("\n" + "=" * 60)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 test_vision_quick.py <image_path>")
        print("Example: python3 test_vision_quick.py ~/Downloads/apple.jpg")
        sys.exit(1)
    
    image_path = sys.argv[1]
    if not Path(image_path).exists():
        print(f"❌ File not found: {image_path}")
        sys.exit(1)
    
    try:
        analyze_image(image_path)
        print("✅ Success!")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
