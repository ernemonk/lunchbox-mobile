#!/usr/bin/env python3
"""
Test script for streaming recipe generation endpoint.
Tests both regular and streaming modes.
"""

import requests
import json
import sys

# Your Cloud Function endpoint
ENDPOINT = "https://generate-recipes-268643218431.us-central1.run.app"

def test_regular():
    """Test regular (non-streaming) mode."""
    print("🧪 Testing REGULAR mode...")
    response = requests.post(
        ENDPOINT,
        headers={"Content-Type": "application/json"},
        json={
            "prompt": "Generate a simple keto breakfast recipe as JSON with title, ingredients, and instructions"
        }
    )
    
    if response.status_code == 200:
        print("✅ Regular mode SUCCESS")
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2)[:200]}...")
    else:
        print(f"❌ Regular mode FAILED: {response.status_code}")
        print(response.text)
    print()


def test_streaming():
    """Test streaming mode with Server-Sent Events."""
    print("🧪 Testing STREAMING mode...")
    response = requests.post(
        ENDPOINT,
        headers={"Content-Type": "application/json"},
        json={
            "prompt": "Generate a simple keto breakfast recipe as JSON with title, ingredients, and instructions",
            "stream": True
        },
        stream=True
    )
    
    if response.status_code == 200:
        print("✅ Streaming mode connected")
        chunks_received = 0
        
        for line in response.iter_lines():
            if line:
                line = line.decode('utf-8')
                if line.startswith('data: '):
                    data = json.loads(line[6:])  # Remove 'data: ' prefix
                    chunks_received += 1
                    
                    if data.get('done'):
                        print(f"\n✅ Stream complete! Received {chunks_received} chunks")
                        print(f"Final response: {json.dumps(data.get('response'), indent=2)[:200]}...")
                        if data.get('warning'):
                            print(f"⚠️  Warning: {data['warning']}")
                        break
                    else:
                        # Print chunk indicator
                        sys.stdout.write('.')
                        sys.stdout.flush()
        
        if chunks_received == 0:
            print("❌ No chunks received")
    else:
        print(f"❌ Streaming mode FAILED: {response.status_code}")
        print(response.text)
    print()


if __name__ == "__main__":
    print("=" * 60)
    print("Testing Recipe Generation Endpoint")
    print("=" * 60)
    print()
    
    test_regular()
    test_streaming()
    
    print("=" * 60)
    print("Tests complete!")
    print("=" * 60)
