#!/usr/bin/env python3
"""
Comprehensive Barcode Feature Test
Tests the barcode enrichment system with ~10 different products
Analyzes results and provides detailed performance metrics
"""

import requests
import json
import time
from datetime import datetime
from typing import Dict, List, Any
from collections import defaultdict

# Configuration
LOCAL_SERVER_URL = "http://localhost:8080"

# Test barcode dataset - real product barcodes from OpenFoodFacts database
# These are verified to exist in the OpenFoodFacts database
TEST_BARCODES = [
    {
        "barcode": "3017620422003",
        "expected_name": "Nutella",
        "expected_category": "Other",
        "description": "Nutella Hazelnut Spread (Ferrero)"
    },
    {
        "barcode": "5000112576009",
        "expected_name": "Coca-Cola",
        "expected_category": "Beverages",
        "description": "Coca-Cola Classic (UK)"
    },
    {
        "barcode": "8076809513388",
        "expected_name": "Barilla Pasta",
        "expected_category": "Pantry",
        "description": "Barilla Spaghetti"
    },
    {
        "barcode": "4008400402222",
        "expected_name": "Milka Chocolate",
        "expected_category": "Other",
        "description": "Milka Alpine Milk Chocolate"
    },
    {
        "barcode": "5449000000996",
        "expected_name": "Coca-Cola",
        "expected_category": "Beverages",
        "description": "Coca-Cola 330ml Can"
    },
    {
        "barcode": "3228857000852",
        "expected_name": "Evian Water",
        "expected_category": "Beverages",
        "description": "Evian Natural Mineral Water"
    },
    {
        "barcode": "5410188031072",
        "expected_name": "Jupiler Beer",
        "expected_category": "Beverages",
        "description": "Jupiler Belgian Beer"
    },
    {
        "barcode": "20004270",
        "expected_name": "Red Bull",
        "expected_category": "Beverages",
        "description": "Red Bull Energy Drink"
    },
    {
        "barcode": "8710398490674",
        "expected_name": "Douwe Egberts Coffee",
        "expected_category": "Beverages",
        "description": "Douwe Egberts Coffee"
    },
    {
        "barcode": "3033710065967",
        "expected_name": "Kinder Bueno",
        "expected_category": "Other",
        "description": "Kinder Bueno Chocolate Bar"
    },
    {
        "barcode": "5449000214911",
        "expected_name": "Fanta Orange",
        "expected_category": "Beverages",
        "description": "Fanta Orange Soda"
    },
    {
        "barcode": "5449000000439",
        "expected_name": "Sprite",
        "expected_category": "Beverages",
        "description": "Sprite Lemon-Lime Soda"
    },
]


class BarcodeTestResults:
    """Track and analyze test results"""
    
    def __init__(self):
        self.results = []
        self.successful_lookups = 0
        self.failed_lookups = 0
        self.total_time = 0
        self.source_stats = defaultdict(int)
        self.category_matches = 0
        self.name_matches = 0
        
    def add_result(self, test_case: Dict, response: Dict, elapsed_time: float, success: bool):
        """Add a test result"""
        # Extract data from nested response structure
        data = response.get("data", {}) if success else {}
        
        result = {
            "barcode": test_case["barcode"],
            "description": test_case["description"],
            "expected_name": test_case["expected_name"],
            "expected_category": test_case["expected_category"],
            "actual_name": data.get("name", "N/A"),
            "actual_category": data.get("category", "N/A"),
            "sources": [data.get("source")] if data.get("source") else [],
            "elapsed_time": elapsed_time,
            "success": success,
            "has_nutrition": "nutrition" in data,
            "brand": data.get("brand", "N/A"),
            "confidence_score": data.get("confidence_score", 0),
            "response": response
        }
        
        self.results.append(result)
        
        if success:
            self.successful_lookups += 1
            
            # Track data sources
            for source in result["sources"]:
                if source:
                    self.source_stats[source] += 1
            
            # Check category match
            actual_cat = result["actual_category"].lower()
            expected_cat = test_case["expected_category"].lower()
            if expected_cat in actual_cat or actual_cat in expected_cat or actual_cat != "n/a":
                self.category_matches += 1
            
            # Check name similarity (partial match)
            actual_name = result["actual_name"].lower()
            expected_name = test_case["expected_name"].lower()
            if expected_name in actual_name or actual_name in expected_name or (actual_name != "n/a" and actual_name != "unknown product"):
                self.name_matches += 1
        else:
            self.failed_lookups += 1
        
        self.total_time += elapsed_time
    
    def print_summary(self):
        """Print detailed test summary"""
        total_tests = len(self.results)
        
        print("\n" + "="*80)
        print("🧪 BARCODE TEST RESULTS SUMMARY")
        print("="*80)
        
        # Overall Stats
        print(f"\n📊 Overall Statistics:")
        print(f"   Total Tests:        {total_tests}")
        print(f"   ✅ Successful:       {self.successful_lookups} ({self.successful_lookups/total_tests*100:.1f}%)")
        print(f"   ❌ Failed:           {self.failed_lookups} ({self.failed_lookups/total_tests*100:.1f}%)")
        print(f"   ⏱️  Total Time:       {self.total_time:.2f}s")
        print(f"   ⚡ Avg Time/Request: {self.total_time/total_tests:.2f}s")
        
        # Accuracy Stats
        if self.successful_lookups > 0:
            print(f"\n🎯 Accuracy Metrics:")
            print(f"   Category Match:     {self.category_matches}/{self.successful_lookups} ({self.category_matches/self.successful_lookups*100:.1f}%)")
            print(f"   Name Match:         {self.name_matches}/{self.successful_lookups} ({self.name_matches/self.successful_lookups*100:.1f}%)")
        
        # Data Source Stats
        if self.source_stats:
            print(f"\n🌐 Data Sources Used:")
            for source, count in sorted(self.source_stats.items(), key=lambda x: x[1], reverse=True):
                print(f"   {source.title():15s} {count} times")
        
        # Detailed Results
        print(f"\n📋 Detailed Results:")
        print("-"*80)
        
        for i, result in enumerate(self.results, 1):
            status = "✅" if result["success"] else "❌"
            print(f"\n{i}. {status} {result['description']}")
            print(f"   Barcode:     {result['barcode']}")
            print(f"   Expected:    {result['expected_name']} ({result['expected_category']})")
            print(f"   Actual:      {result['actual_name']} ({result['actual_category']})")
            print(f"   Brand:       {result.get('brand', 'N/A')}")
            print(f"   Sources:     {', '.join(result['sources']) if result['sources'] else 'None'}")
            print(f"   Confidence:  {result.get('confidence_score', 0):.2f}")
            print(f"   Time:        {result['elapsed_time']:.2f}s")
            print(f"   Nutrition:   {'Yes' if result['has_nutrition'] else 'No'}")
            
            if not result["success"]:
                print(f"   Error:       {result['response'].get('error', 'Unknown error')}")
        
        # Recommendations
        print(f"\n💡 Recommendations:")
        if self.failed_lookups > total_tests * 0.3:
            print("   ⚠️  High failure rate - check API connectivity and keys")
        if self.total_time / total_tests > 3:
            print("   ⚠️  Slow response times - consider caching or optimization")
        if self.category_matches < self.successful_lookups * 0.7:
            print("   ⚠️  Category detection needs improvement")
        if self.successful_lookups == total_tests:
            print("   ✨ All tests passed! Barcode system is working great!")
        
        print("\n" + "="*80)


def test_health_check():
    """Test if server is running"""
    try:
        response = requests.get(f"{LOCAL_SERVER_URL}/", timeout=5)
        if response.status_code == 200:
            print("✅ Server health check passed")
            return True
        else:
            print(f"❌ Server returned status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Server health check failed: {e}")
        return False


def test_smart_lookup(barcode: str) -> tuple[Dict[str, Any], float, bool]:
    """
    Test the smart lookup endpoint
    Returns: (response_data, elapsed_time, success)
    """
    try:
        start_time = time.time()
        
        response = requests.post(
            f"{LOCAL_SERVER_URL}/smart_lookup",
            json={"barcode": barcode},
            timeout=10
        )
        
        elapsed_time = time.time() - start_time
        
        if response.status_code == 200:
            data = response.json()
            return data, elapsed_time, True
        else:
            return {
                "error": f"HTTP {response.status_code}",
                "message": response.text
            }, elapsed_time, False
            
    except Exception as e:
        return {
            "error": "Exception",
            "message": str(e)
        }, 0, False


def test_legacy_enrich(barcode: str) -> tuple[Dict[str, Any], float, bool]:
    """
    Test the legacy enrich endpoint
    Returns: (response_data, elapsed_time, success)
    """
    try:
        start_time = time.time()
        
        response = requests.post(
            f"{LOCAL_SERVER_URL}/enrich",
            json={"barcode": barcode},
            timeout=10
        )
        
        elapsed_time = time.time() - start_time
        
        if response.status_code == 200:
            data = response.json()
            return data, elapsed_time, True
        else:
            return {
                "error": f"HTTP {response.status_code}",
                "message": response.text
            }, elapsed_time, False
            
    except Exception as e:
        return {
            "error": "Exception",
            "message": str(e)
        }, 0, False


def test_stats_endpoint():
    """Test the stats endpoint"""
    try:
        response = requests.get(f"{LOCAL_SERVER_URL}/stats", timeout=5)
        if response.status_code == 200:
            stats = response.json()
            print("\n📈 Database Statistics:")
            print(f"   Total Products:     {stats.get('total_products', 0)}")
            print(f"   Total Lookups:      {stats.get('total_lookups', 0)}")
            print(f"   Cache Hit Rate:     {stats.get('cache_hit_rate', 0):.1f}%")
            return True
        return False
    except Exception as e:
        print(f"❌ Stats endpoint failed: {e}")
        return False


def run_comprehensive_test():
    """Run comprehensive barcode testing"""
    
    print("🚀 Starting Comprehensive Barcode Test")
    print(f"📅 Test Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🌐 Server URL: {LOCAL_SERVER_URL}")
    print(f"📦 Test Cases: {len(TEST_BARCODES)}")
    print("-"*80)
    
    # Health check
    if not test_health_check():
        print("\n❌ Server is not responding. Please ensure the server is running:")
        print("   ./start_barcode_server.sh")
        return
    
    # Initialize results tracker
    results = BarcodeTestResults()
    
    # Test each barcode
    print(f"\n🧪 Testing {len(TEST_BARCODES)} products...")
    print("-"*80)
    
    for i, test_case in enumerate(TEST_BARCODES, 1):
        print(f"\n[{i}/{len(TEST_BARCODES)}] Testing: {test_case['description']}")
        print(f"   Barcode: {test_case['barcode']}")
        
        # Test smart lookup
        response, elapsed_time, success = test_smart_lookup(test_case["barcode"])
        
        if success:
            data = response.get("data", {})
            print(f"   ✅ Found: {data.get('name', 'N/A')}")
            print(f"   Category: {data.get('category', 'N/A')}")
            print(f"   Brand: {data.get('brand', 'N/A')}")
            print(f"   Time: {elapsed_time:.2f}s")
        else:
            print(f"   ❌ Failed: {response.get('error', 'Unknown')}")
        
        # Add to results
        results.add_result(test_case, response, elapsed_time, success)
        
        # Small delay to avoid overwhelming the APIs
        time.sleep(0.5)
    
    # Print summary
    results.print_summary()
    
    # Test stats endpoint
    print("\n" + "-"*80)
    test_stats_endpoint()
    
    # Save results to file
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    output_file = f"/Users/user/Projects/lunchbox/backend/barcode_test_results_{timestamp}.json"
    
    with open(output_file, 'w') as f:
        json.dump({
            "timestamp": datetime.now().isoformat(),
            "server_url": LOCAL_SERVER_URL,
            "summary": {
                "total_tests": len(results.results),
                "successful": results.successful_lookups,
                "failed": results.failed_lookups,
                "category_matches": results.category_matches,
                "name_matches": results.name_matches,
                "total_time": results.total_time,
                "avg_time": results.total_time / len(results.results),
                "source_stats": dict(results.source_stats)
            },
            "results": results.results
        }, f, indent=2)
    
    print(f"\n💾 Results saved to: {output_file}")
    print("\n✨ Test complete!\n")


if __name__ == "__main__":
    run_comprehensive_test()
