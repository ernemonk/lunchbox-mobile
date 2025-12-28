"""
Cloud Function: Barcode Enrichment
Deployable to Google Cloud Functions

This function provides barcode lookup and enrichment using multiple data sources.
"""

import os
import sys
from datetime import datetime
from typing import Dict, Any, Optional

# Import shared modules
from shared.barcode_data_sources import DataSourceRegistry
from shared.barcode_sources_plugins import (
    OpenFoodFactsSource,
    NutritionixSource,
    EdamamSource,
    UPCDatabaseSource
)

# Initialize the data source registry
data_source_registry = DataSourceRegistry()

# Register data sources with Cloud Function environment variables
print("🔧 Initializing Barcode Data Sources for Cloud Function...")

# 1. OpenFoodFacts (always enabled, no config needed)
data_source_registry.register(OpenFoodFactsSource())

# 2. Nutritionix (optional - configure with environment variables)
nutritionix_config = {
    "app_id": os.environ.get("NUTRITIONIX_APP_ID"),
    "app_key": os.environ.get("NUTRITIONIX_APP_KEY")
}
if nutritionix_config["app_id"] and nutritionix_config["app_key"]:
    data_source_registry.register(NutritionixSource(nutritionix_config))

# 3. Edamam (optional - configure with environment variables)
edamam_config = {
    "app_id": os.environ.get("EDAMAM_APP_ID"),
    "app_key": os.environ.get("EDAMAM_APP_KEY")
}
if edamam_config["app_id"] and edamam_config["app_key"]:
    data_source_registry.register(EdamamSource(edamam_config))

# 4. UPC Database (trial, always enabled)
data_source_registry.register(UPCDatabaseSource())

print(f"✅ Initialized {len(data_source_registry.get_enabled_sources())} enabled data sources")


def barcode_enrichment(request):
    """
    Cloud Function entry point for barcode enrichment.
    
    HTTP Cloud Function that accepts POST requests with barcode data.
    
    Request JSON:
    {
        "barcode": "1234567890123"
    }
    
    Response JSON:
    {
        "success": true,
        "data": {
            "name": "Product Name",
            "brand": "Brand Name",
            "category": "Category",
            ...
        }
    }
    """
    
    # Set CORS headers for all responses
    headers = {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
        'Content-Type': 'application/json'
    }
    
    # Handle preflight OPTIONS request
    if request.method == 'OPTIONS':
        return ('', 204, headers)
    
    # Only accept POST requests
    if request.method != 'POST':
        return ({
            'success': False,
            'error': 'Method not allowed. Use POST.'
        }, 405, headers)
    
    try:
        # Get request data
        request_json = request.get_json(silent=True)
        
        if not request_json or 'barcode' not in request_json:
            return ({
                'success': False,
                'error': 'Missing barcode in request'
            }, 400, headers)
        
        barcode = request_json['barcode']
        
        # Validate barcode format
        if not barcode or not str(barcode).replace('-', '').replace(' ', '').isdigit():
            return ({
                'success': False,
                'error': 'Invalid barcode format'
            }, 400, headers)
        
        # Clean barcode (remove dashes and spaces)
        barcode = str(barcode).replace('-', '').replace(' ', '')
        
        print(f"🔍 Looking up barcode: {barcode}")
        
        # Lookup using the registry
        result = data_source_registry.lookup(barcode, merge_strategy="merge_all")
        
        if result:
            # Add metadata
            response_data = {
                'success': True,
                'data': {
                    'barcode': barcode,
                    'name': result.get('name', 'Unknown Product'),
                    'brand': result.get('brand', ''),
                    'category': result.get('category', 'Other'),
                    'unit': result.get('unit', 'pieces'),
                    'image_url': result.get('image_url', ''),
                    'nutrition': result.get('nutrition', {}),
                    'allergens': result.get('allergens', []),
                    'ingredients': result.get('ingredients', ''),
                    'sources': result.get('_sources', []),
                    'enriched_at': datetime.utcnow().isoformat()
                }
            }
            
            print(f"✅ Found: {result.get('name')} from {result.get('_sources', [])}")
            return (response_data, 200, headers)
        else:
            print(f"❌ No data found for barcode: {barcode}")
            return ({
                'success': False,
                'error': 'Product not found in any database'
            }, 404, headers)
    
    except Exception as e:
        print(f"❌ Error processing barcode: {e}")
        import traceback
        traceback.print_exc()
        
        return ({
            'success': False,
            'error': f'Internal server error: {str(e)}'
        }, 500, headers)


# For local testing with functions-framework
if __name__ == '__main__':
    import functions_framework
    functions_framework.run(barcode_enrichment, port=8080)
