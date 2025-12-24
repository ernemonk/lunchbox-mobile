"""
Built-in Data Source Plugins for Barcode Enrichment

This module contains implementations of various barcode data sources
as plugins using the BarcodeDataSource interface.
"""

from typing import Dict, Any, Optional
import requests
from .barcode_data_sources import BarcodeDataSource, categorize_product, infer_unit_from_quantity


class OpenFoodFactsSource(BarcodeDataSource):
    """
    OpenFoodFacts data source - the best free barcode database.
    
    - Free, unlimited requests
    - Global coverage (1M+ products)
    - Complete nutrition data
    - Community-maintained
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        super().__init__(config)
        self.api_url = self.config.get("api_url", "https://world.openfoodfacts.org/api/v0/product")
        self.priority = 100  # Highest priority - best free option
    
    def is_configured(self) -> bool:
        """OpenFoodFacts requires no configuration."""
        return True
    
    def get_name(self) -> str:
        return "OpenFoodFacts"
    
    def fetch(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Fetch product data from OpenFoodFacts."""
        response = requests.get(f"{self.api_url}/{barcode}.json", timeout=5)
        
        if response.status_code != 200:
            return None
        
        data = response.json()
        if data.get("status") != 1:
            return None
        
        product = data.get("product", {})
        
        # Extract nutrition data
        nutriments = product.get("nutriments", {})
        nutrition = {
            "calories": nutriments.get("energy-kcal_100g"),
            "protein": nutriments.get("proteins_100g"),
            "carbs": nutriments.get("carbohydrates_100g"),
            "fat": nutriments.get("fat_100g"),
            "fiber": nutriments.get("fiber_100g"),
            "sugar": nutriments.get("sugars_100g"),
            "salt": nutriments.get("salt_100g"),
            "sodium": nutriments.get("sodium_100g"),
        }
        
        # Clean up nutrition data (remove None values)
        nutrition = {k: v for k, v in nutrition.items() if v is not None}
        
        return {
            "name": product.get("product_name_en") or product.get("product_name", "Unknown"),
            "category": categorize_product(product.get("categories", "")),
            "unit": infer_unit_from_quantity(product.get("quantity", "")),
            "brand": product.get("brands", ""),
            "image_url": product.get("image_url", ""),
            "nutrition": nutrition if nutrition else None,
            "allergens": product.get("allergens", "").split(",") if product.get("allergens") else [],
            "ingredients": product.get("ingredients_text_en") or product.get("ingredients_text", ""),
        }


class NutritionixSource(BarcodeDataSource):
    """
    Nutritionix data source - great for US products.
    
    - Free tier: 200 requests/day
    - Excellent US product coverage
    - Detailed nutrition data
    - Requires API keys
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        super().__init__(config)
        self.api_url = self.config.get("api_url", "https://trackapi.nutritionix.com/v2/search/item")
        self.app_id = self.config.get("app_id")
        self.app_key = self.config.get("app_key")
        self.priority = 80
    
    def is_configured(self) -> bool:
        """Check if API keys are configured."""
        return bool(self.app_id and self.app_key and 
                   self.app_id != "demo_id" and self.app_key != "demo_key")
    
    def get_name(self) -> str:
        return "Nutritionix"
    
    def fetch(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Fetch product data from Nutritionix."""
        if not self.is_configured():
            return None
        
        headers = {
            "x-app-id": self.app_id,
            "x-app-key": self.app_key,
        }
        
        response = requests.get(
            f"{self.api_url}?upc={barcode}",
            headers=headers,
            timeout=5
        )
        
        if response.status_code != 200:
            return None
        
        data = response.json()
        foods = data.get("foods", [])
        if not foods:
            return None
        
        food = foods[0]
        
        return {
            "name": food.get("food_name", "Unknown"),
            "brand": food.get("brand_name", ""),
            "nutrition": {
                "calories": food.get("nf_calories"),
                "protein": food.get("nf_protein"),
                "carbs": food.get("nf_total_carbohydrate"),
                "fat": food.get("nf_total_fat"),
                "fiber": food.get("nf_dietary_fiber"),
                "sugar": food.get("nf_sugars"),
                "sodium": food.get("nf_sodium"),
            }
        }


class EdamamSource(BarcodeDataSource):
    """
    Edamam data source - good nutrition database.
    
    - Free tier: 100 requests/month
    - Good nutrition data
    - Recipe analysis capabilities
    - Requires API keys
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        super().__init__(config)
        self.api_url = self.config.get("api_url", "https://api.edamam.com/api/food-database/v2/parser")
        self.app_id = self.config.get("app_id")
        self.app_key = self.config.get("app_key")
        self.priority = 70
    
    def is_configured(self) -> bool:
        """Check if API keys are configured."""
        return bool(self.app_id and self.app_key)
    
    def get_name(self) -> str:
        return "Edamam"
    
    def fetch(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Fetch product data from Edamam."""
        if not self.is_configured():
            return None
        
        params = {
            "app_id": self.app_id,
            "app_key": self.app_key,
            "upc": barcode,
        }
        
        response = requests.get(self.api_url, params=params, timeout=5)
        
        if response.status_code != 200:
            return None
        
        data = response.json()
        hints = data.get("hints", [])
        if not hints:
            return None
        
        food = hints[0].get("food", {})
        nutrients = food.get("nutrients", {})
        
        return {
            "name": food.get("label", "Unknown"),
            "category": categorize_product(food.get("category", "")),
            "nutrition": {
                "calories": nutrients.get("ENERC_KCAL"),
                "protein": nutrients.get("PROCNT"),
                "carbs": nutrients.get("CHOCDF"),
                "fat": nutrients.get("FAT"),
                "fiber": nutrients.get("FIBTG"),
            }
        }


class UPCDatabaseSource(BarcodeDataSource):
    """
    UPC Database source - basic product information.
    
    - Free (trial account)
    - Basic product info only
    - Good as last resort
    - No API key required for trial
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        super().__init__(config)
        self.api_url = self.config.get("api_url", "https://api.upcitemdb.com/prod/trial/lookup")
        self.priority = 30  # Low priority - basic info only
    
    def is_configured(self) -> bool:
        """UPC Database trial requires no configuration."""
        return True
    
    def get_name(self) -> str:
        return "UPC Database"
    
    def fetch(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Fetch product data from UPC Database."""
        response = requests.get(f"{self.api_url}?upc={barcode}", timeout=5)
        
        if response.status_code != 200:
            return None
        
        data = response.json()
        items = data.get("items", [])
        if not items:
            return None
        
        item = items[0]
        
        return {
            "name": item.get("title", "Unknown"),
            "brand": item.get("brand", ""),
            "category": categorize_product(item.get("category", "")),
            "unit": "pieces",  # UPC Database doesn't provide detailed unit info
        }


class USDAFoodDataSource(BarcodeDataSource):
    """
    USDA FoodData Central source - US government nutrition database.
    
    - Free, unlimited
    - Excellent nutrition data
    - US-focused
    - Does not support direct barcode lookup (name search only)
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        super().__init__(config)
        self.api_url = self.config.get("api_url", "https://api.nal.usda.gov/fdc/v1")
        self.api_key = self.config.get("api_key")
        self.priority = 60
        self._enabled = False  # Disabled by default (no barcode support)
    
    def is_configured(self) -> bool:
        """Check if API key is configured."""
        return bool(self.api_key)
    
    def get_name(self) -> str:
        return "USDA FoodData Central"
    
    def fetch(self, barcode: str) -> Optional[Dict[str, Any]]:
        """
        USDA doesn't support direct barcode lookup.
        This is a placeholder for potential future enhancement.
        """
        # USDA FoodData Central doesn't support UPC/barcode search
        # It's better used for name-based nutrition lookups
        return None


# Custom data source example - shows how users can add their own
class CustomAPISource(BarcodeDataSource):
    """
    Template for creating custom data source plugins.
    
    Copy this class and modify to add your own barcode API.
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        super().__init__(config)
        self.api_url = self.config.get("api_url", "https://api.example.com/barcode")
        self.api_key = self.config.get("api_key")
        self.priority = self.config.get("priority", 50)
    
    def is_configured(self) -> bool:
        """Check if required configuration is present."""
        return bool(self.api_url and self.api_key)
    
    def get_name(self) -> str:
        return "Custom API"
    
    def fetch(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Fetch product data from your custom API."""
        if not self.is_configured():
            return None
        
        # Implement your custom API logic here
        headers = {"Authorization": f"Bearer {self.api_key}"}
        
        try:
            response = requests.get(
                f"{self.api_url}/{barcode}",
                headers=headers,
                timeout=5
            )
            
            if response.status_code != 200:
                return None
            
            data = response.json()
            
            # Transform your API response to standard format
            return {
                "name": data.get("product_name", "Unknown"),
                "brand": data.get("brand", ""),
                "category": data.get("category", "Other"),
                # Add more fields as needed
            }
            
        except Exception as e:
            print(f"Custom API error: {e}")
            return None
