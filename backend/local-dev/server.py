#!/usr/bin/env python3
"""
Local Development Server for Barcode Enrichment

This server provides a full-featured development environment with:
- Barcode lookup with multiple data sources
- Local database caching
- User confirmation/correction endpoints
- Statistics and monitoring
- Data source management API
"""

import os
import sys
from flask import Flask, request, jsonify
from datetime import datetime
from typing import Dict, Any, Optional

# Import shared modules
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'shared'))
from barcode_data_sources import DataSourceRegistry
from barcode_sources_plugins import (
    OpenFoodFactsSource,
    NutritionixSource,
    EdamamSource,
    UPCDatabaseSource,
    USDAFoodDataSource
)

# Initialize Flask app
app = Flask(__name__)

# Mock database for local testing (replace with Firebase in production)
local_database = {}
local_stats = {}
local_corrections = []

# Initialize the data source registry
data_source_registry = DataSourceRegistry()

# Register data sources
print("\n🔧 Initializing Barcode Data Sources...")
print("=" * 60)

# 1. OpenFoodFacts (highest priority, no config needed)
data_source_registry.register(OpenFoodFactsSource())

# 2. Nutritionix (configure with environment variables)
nutritionix_config = {
    "app_id": os.getenv("NUTRITIONIX_APP_ID", "demo_id"),
    "app_key": os.getenv("NUTRITIONIX_APP_KEY", "demo_key")
}
data_source_registry.register(NutritionixSource(nutritionix_config))

# 3. Edamam (configure with environment variables)
edamam_config = {
    "app_id": os.getenv("EDAMAM_APP_ID"),
    "app_key": os.getenv("EDAMAM_APP_KEY")
}
data_source_registry.register(EdamamSource(edamam_config))

# 4. UPC Database (trial, no config needed)
data_source_registry.register(UPCDatabaseSource())

# 5. USDA (disabled by default)
usda_config = {
    "api_key": os.getenv("USDA_API_KEY")
}
data_source_registry.register(USDAFoodDataSource(usda_config))

print("=" * 60)
print(f"✅ Registered {len(data_source_registry.get_all_sources())} data sources")
print(f"✅ Enabled: {len(data_source_registry.get_enabled_sources())} sources")
print("=" * 60 + "\n")


# ============================================================================
# Health & Info Endpoints
# ============================================================================

@app.route("/", methods=["GET"])
def health_check():
    """Health check endpoint with data source information"""
    enabled_sources = data_source_registry.get_enabled_sources()
    return jsonify({
        "status": "healthy",
        "service": "barcode-enrichment-local-dev",
        "version": "2.0.0",
        "timestamp": datetime.utcnow().isoformat(),
        "data_sources": {
            "total": len(data_source_registry.get_all_sources()),
            "enabled": len(enabled_sources),
            "sources": [s.get_name() for s in enabled_sources]
        },
        "local_database": {
            "products": len(local_database),
            "corrections": len(local_corrections)
        }
    })


@app.route("/sources", methods=["GET"])
def get_data_sources():
    """Get information about all registered data sources"""
    return jsonify(data_source_registry.get_registry_info())


@app.route("/sources/<source_name>/enable", methods=["POST"])
def enable_data_source(source_name: str):
    """Enable a specific data source"""
    if data_source_registry.enable_source(source_name):
        return jsonify({"success": True, "message": f"Enabled {source_name}"})
    return jsonify({"success": False, "error": "Source not found"}), 404


@app.route("/sources/<source_name>/disable", methods=["POST"])
def disable_data_source(source_name: str):
    """Disable a specific data source"""
    if data_source_registry.disable_source(source_name):
        return jsonify({"success": True, "message": f"Disabled {source_name}"})
    return jsonify({"success": False, "error": "Source not found"}), 404


@app.route("/sources/<source_name>/priority", methods=["POST"])
def set_source_priority(source_name: str):
    """Set priority for a data source"""
    request_data = request.get_json()
    priority = request_data.get("priority")
    
    if priority is None:
        return jsonify({"success": False, "error": "Missing priority value"}), 400
    
    if data_source_registry.set_priority(source_name, priority):
        return jsonify({"success": True, "message": f"Set priority for {source_name} to {priority}"})
    return jsonify({"success": False, "error": "Source not found"}), 404


# ============================================================================
# Barcode Lookup Endpoints
# ============================================================================

@app.route("/enrich", methods=["POST"])
def enrich_barcode():
    """Legacy endpoint - redirects to smart lookup"""
    return smart_lookup()


@app.route("/smart_lookup", methods=["POST"])
def smart_lookup():
    """
    Main barcode enrichment endpoint
    
    Expected request:
    {
        "barcode": "1234567890123"
    }
    """
    try:
        # Get request data
        request_data = request.get_json()
        
        if not request_data or "barcode" not in request_data:
            return jsonify({
                "error": "Missing barcode in request"
            }), 400
        
        barcode = request_data["barcode"]
        
        # Validate barcode format (should be numeric)
        if not barcode.isdigit():
            return jsonify({
                "error": "Invalid barcode format"
            }), 400
        
        print(f"🔍 Looking up barcode: {barcode}")
        
        # Check our local database first
        our_data = _get_from_local_db(barcode)
        if our_data and our_data.get("confidence_score", 0) >= 0.7:
            print(f"✅ Found in local DB: {our_data.get('name')} (confidence: {our_data.get('confidence_score')})")
            return jsonify({
                "success": True,
                "source": "lunchbox_database",
                "data": our_data,
                "needs_confirmation": False
            })
        
        # Fallback to API lookup using the modular registry
        api_result = data_source_registry.lookup(barcode, merge_strategy="merge_all")
        
        if api_result:
            # Save to local database
            normalized_data = _normalize_for_database(api_result, barcode)
            _save_to_local_db(barcode, normalized_data)
            
            print(f"✅ Found via API: {normalized_data.get('name')} (confidence: {normalized_data.get('confidence_score')})")
            return jsonify({
                "success": True,
                "source": "external_api", 
                "data": normalized_data,
                "needs_confirmation": True
            })
        else:
            print(f"❌ No data found for barcode: {barcode}")
            return jsonify({
                "success": False,
                "message": "Product not found in any database"
            }), 404
    
    except Exception as e:
        print(f"❌ Error processing barcode: {e}")
        return jsonify({
            "error": f"Internal server error: {str(e)}"
        }), 500


# ============================================================================
# User Feedback Endpoints
# ============================================================================

@app.route("/confirm", methods=["POST"])
def confirm_barcode_data():
    """
    User confirmation endpoint - improves database quality
    
    Expected request:
    {
        "barcode": "1234567890123",
        "is_correct": true,
        "corrections": {"name": "Corrected Name"},
        "user_id": "user123"
    }
    """
    try:
        request_data = request.get_json()
        
        if not request_data:
            return jsonify({"error": "Missing request data"}), 400
        
        barcode = request_data.get("barcode")
        is_correct = request_data.get("is_correct", False)
        corrections = request_data.get("corrections", {})
        user_id = request_data.get("user_id", "anonymous")
        
        if not barcode:
            return jsonify({"error": "Missing barcode"}), 400
        
        # Get current data from local database
        current_data = local_database.get(barcode)
        if not current_data:
            return jsonify({"error": "Barcode not found in database"}), 404
        
        if is_correct:
            # User confirms data is correct
            current_data["user_confirmed"] = True
            current_data["confirmation_count"] = current_data.get("confirmation_count", 0) + 1
            current_data["confidence_score"] = min(current_data.get("confidence_score", 0) + 0.1, 1.0)
            print(f"✅ User confirmed barcode {barcode}")
        else:
            # User provided corrections
            current_data["correction_count"] = current_data.get("correction_count", 0) + 1
            
            # Apply corrections
            for field, new_value in corrections.items():
                if field in ["name", "brand", "category", "unit", "ingredients"]:
                    current_data[field] = new_value
                elif field == "allergens" and isinstance(new_value, list):
                    current_data[field] = new_value
                elif field == "nutrition" and isinstance(new_value, dict):
                    current_data.setdefault("nutrition", {}).update(new_value)
            
            current_data["user_confirmed"] = True
            current_data["confidence_score"] = 0.95  # High confidence for user-corrected data
            print(f"🔧 User corrected barcode {barcode}")
            
            # Log correction
            local_corrections.append({
                "barcode": barcode,
                "corrections": corrections,
                "user_id": user_id,
                "timestamp": datetime.utcnow().isoformat()
            })
        
        current_data["last_updated"] = datetime.utcnow().isoformat()
        local_database[barcode] = current_data
        
        return jsonify({
            "success": True,
            "message": "Thank you! Your feedback improves our database.",
            "updated_data": current_data
        })
    
    except Exception as e:
        print(f"❌ Error confirming barcode: {e}")
        return jsonify({"error": f"Internal server error: {str(e)}"}), 500


# ============================================================================
# Statistics & Monitoring
# ============================================================================

@app.route("/stats", methods=["GET"])
def get_database_stats():
    """Get statistics about database quality"""
    try:
        total_products = len(local_database)
        confirmed_products = sum(1 for data in local_database.values() if data.get("user_confirmed"))
        
        if total_products > 0:
            confirmation_rate = confirmed_products / total_products
            avg_confidence = sum(data.get("confidence_score", 0) for data in local_database.values()) / total_products
        else:
            confirmation_rate = 0
            avg_confidence = 0
        
        quality_level = "High" if avg_confidence > 0.8 else "Medium" if avg_confidence > 0.6 else "Improving"
        
        return jsonify({
            "success": True,
            "stats": {
                "total_products": total_products,
                "user_confirmed": confirmed_products,
                "confirmation_rate": confirmation_rate,
                "average_confidence": avg_confidence,
                "database_quality": quality_level,
                "total_corrections": len(local_corrections)
            }
        })
    
    except Exception as e:
        return jsonify({"error": f"Error getting stats: {str(e)}"}), 500


# ============================================================================
# Helper Functions
# ============================================================================

def _get_from_local_db(barcode: str) -> Optional[Dict[str, Any]]:
    """Get barcode data from local mock database"""
    return local_database.get(barcode)


def _save_to_local_db(barcode: str, data: Dict[str, Any]):
    """Save data to local mock database"""
    local_database[barcode] = data
    print(f"💾 Saved barcode {barcode} to local database")


def _normalize_for_database(api_data: Dict[str, Any], barcode: str) -> Dict[str, Any]:
    """Normalize API data for our database schema"""
    return {
        "barcode": barcode,
        "name": api_data.get("name", "Unknown Product"),
        "brand": api_data.get("brand", ""),
        "category": api_data.get("category", "Other"),
        "unit": api_data.get("unit", "pieces"),
        "image_url": api_data.get("image_url", ""),
        "ingredients": api_data.get("ingredients", ""),
        "allergens": api_data.get("allergens", []),
        "nutrition": api_data.get("nutrition", {}),
        
        # Metadata
        "source": api_data.get("_sources", ["unknown"])[0] if api_data.get("_sources") else "unknown",
        "all_sources": api_data.get("_sources", []),
        "confidence_score": _calculate_confidence_score(api_data),
        "created_at": datetime.utcnow().isoformat(),
        "last_updated": datetime.utcnow().isoformat(),
        "user_confirmed": False,
        "confirmation_count": 0,
        "correction_count": 0,
    }


def _calculate_confidence_score(data: Dict[str, Any]) -> float:
    """Calculate confidence score based on data completeness and source"""
    score = 0.5  # Base score
    
    # Source reliability
    sources = data.get("_sources", [])
    if "OpenFoodFacts" in sources:
        score += 0.3
    
    # Data completeness
    if data.get("name") and data.get("name") != "Unknown Product":
        score += 0.1
    if data.get("brand"):
        score += 0.05
    if data.get("ingredients"):
        score += 0.05
    if data.get("nutrition"):
        score += 0.05
    
    return min(score, 1.0)


# ============================================================================
# Main Entry Point
# ============================================================================

if __name__ == "__main__":
    print("🚀 Starting Local Development Barcode Server...")
    print("📡 Available endpoints:")
    print("   GET  /              - Health check")
    print("   GET  /sources       - List data sources")
    print("   POST /smart_lookup  - Barcode lookup")
    print("   POST /confirm       - User confirmation")
    print("   GET  /stats         - Database statistics")
    print("🌐 Server running on http://localhost:8080\n")
    
    app.run(host="0.0.0.0", port=8080, debug=True)
