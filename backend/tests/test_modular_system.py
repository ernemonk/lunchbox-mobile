#!/usr/bin/env python3
"""
Quick test of the modular barcode system
"""
import requests
import json

BASE_URL = "http://localhost:8080"

print("🧪 Testing Modular Barcode System\n")
print("="*60)

# Test 1: Health check with data source info
print("\n1️⃣  Testing Health Check...")
response = requests.get(f"{BASE_URL}/")
if response.status_code == 200:
    data = response.json()
    print(f"✅ Status: {data['status']}")
    print(f"✅ Service: {data['service']}")
    print(f"✅ Total Sources: {data['data_sources']['total']}")
    print(f"✅ Enabled Sources: {data['data_sources']['enabled']}")
    print(f"✅ Active: {', '.join(data['data_sources']['sources'])}")
else:
    print(f"❌ Health check failed: {response.status_code}")

# Test 2: Get all data sources
print("\n2️⃣  Getting All Data Sources...")
response = requests.get(f"{BASE_URL}/sources")
if response.status_code == 200:
    data = response.json()
    print(f"✅ Total: {data['total_sources']}")
    print(f"✅ Enabled: {data['enabled_sources']}")
    print("\n📋 Source Details:")
    for source in data['sources']:
        status = "✅" if source['enabled'] else "⏸️ "
        config = "✅" if source['configured'] else "❌"
        print(f"   {status} {source['name']:<25} Priority: {source['priority']:3d}  Configured: {config}")
else:
    print(f"❌ Failed: {response.status_code}")

# Test 3: Lookup a barcode
print("\n3️⃣  Testing Barcode Lookup (Nutella)...")
response = requests.post(f"{BASE_URL}/smart_lookup", json={"barcode": "3017620422003"})
if response.status_code == 200:
    result = response.json()
    data = result['data']
    print(f"✅ Success: {result['success']}")
    print(f"✅ Product: {data['name']}")
    print(f"✅ Brand: {data['brand']}")
    print(f"✅ Category: {data['category']}")
    print(f"✅ Source: {data['source']}")
    print(f"✅ Confidence: {data['confidence_score']}")
    if data.get('nutrition'):
        print(f"✅ Nutrition: {len(data['nutrition'])} fields")
else:
    print(f"❌ Lookup failed: {response.status_code}")

# Test 4: Test enabling/disabling a source
print("\n4️⃣  Testing Source Management...")
print("   Enabling UPC Database...")
response = requests.post(f"{BASE_URL}/sources/UPCDatabaseSource/enable")
if response.status_code == 200:
    print(f"   ✅ {response.json()['message']}")
else:
    print(f"   ❌ Failed")

print("   Checking enabled sources...")
response = requests.get(f"{BASE_URL}/sources")
if response.status_code == 200:
    data = response.json()
    print(f"   ✅ Now enabled: {data['enabled_sources']} sources")
else:
    print(f"   ❌ Failed")

print("\n" + "="*60)
print("✨ Modular System Test Complete!\n")
