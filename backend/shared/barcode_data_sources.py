"""
Modular Data Source Plugin System for Barcode Enrichment

This module provides a plugin architecture for adding barcode data sources.
Each data source is a self-contained class that can be easily added or removed.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional, List
from datetime import datetime
import requests


class BarcodeDataSource(ABC):
    """
    Abstract base class for barcode data sources.
    
    All data source plugins must inherit from this class and implement
    the required methods.
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize the data source with optional configuration.
        
        Args:
            config: Dictionary containing API keys, URLs, or other settings
        """
        self.config = config or {}
        self.name = self.__class__.__name__
        self._enabled = True
        self._priority = 50  # Default priority (higher = tried first)
    
    @property
    def enabled(self) -> bool:
        """Check if this data source is enabled."""
        return self._enabled and self.is_configured()
    
    @enabled.setter
    def enabled(self, value: bool):
        """Enable or disable this data source."""
        self._enabled = value
    
    @property
    def priority(self) -> int:
        """Get the priority of this data source (higher = tried first)."""
        return self._priority
    
    @priority.setter
    def priority(self, value: int):
        """Set the priority of this data source."""
        self._priority = value
    
    @abstractmethod
    def is_configured(self) -> bool:
        """
        Check if the data source has all required configuration.
        
        Returns:
            True if properly configured, False otherwise
        """
        pass
    
    @abstractmethod
    def fetch(self, barcode: str) -> Optional[Dict[str, Any]]:
        """
        Fetch product data for the given barcode.
        
        Args:
            barcode: The product barcode to lookup
            
        Returns:
            Dictionary with product data, or None if not found
            
        Expected return format:
        {
            "name": str,
            "brand": str (optional),
            "category": str (optional),
            "unit": str (optional),
            "image_url": str (optional),
            "nutrition": dict (optional),
            "allergens": list (optional),
            "ingredients": str (optional),
        }
        """
        pass
    
    @abstractmethod
    def get_name(self) -> str:
        """Get the human-readable name of this data source."""
        pass
    
    def get_info(self) -> Dict[str, Any]:
        """
        Get information about this data source.
        
        Returns:
            Dictionary with metadata about the source
        """
        return {
            "name": self.get_name(),
            "enabled": self.enabled,
            "configured": self.is_configured(),
            "priority": self.priority,
            "class": self.__class__.__name__
        }


class DataSourceRegistry:
    """
    Registry for managing barcode data sources.
    
    Provides methods to register, enable/disable, and query data sources
    in priority order.
    """
    
    def __init__(self):
        """Initialize the registry."""
        self._sources: List[BarcodeDataSource] = []
    
    def register(self, source: BarcodeDataSource) -> None:
        """
        Register a new data source.
        
        Args:
            source: Instance of a BarcodeDataSource subclass
        """
        if not isinstance(source, BarcodeDataSource):
            raise TypeError(f"Source must be a BarcodeDataSource instance, got {type(source)}")
        
        # Remove existing source with same class name
        self._sources = [s for s in self._sources if s.__class__.__name__ != source.__class__.__name__]
        
        # Add new source
        self._sources.append(source)
        
        # Sort by priority (highest first)
        self._sources.sort(key=lambda s: s.priority, reverse=True)
        
        print(f"✅ Registered data source: {source.get_name()} (priority: {source.priority})")
    
    def unregister(self, source_name: str) -> bool:
        """
        Unregister a data source by class name.
        
        Args:
            source_name: The class name of the source to remove
            
        Returns:
            True if removed, False if not found
        """
        original_count = len(self._sources)
        self._sources = [s for s in self._sources if s.__class__.__name__ != source_name]
        
        removed = len(self._sources) < original_count
        if removed:
            print(f"🗑️  Unregistered data source: {source_name}")
        
        return removed
    
    def get_enabled_sources(self) -> List[BarcodeDataSource]:
        """
        Get all enabled and configured data sources in priority order.
        
        Returns:
            List of enabled BarcodeDataSource instances
        """
        return [s for s in self._sources if s.enabled]
    
    def get_all_sources(self) -> List[BarcodeDataSource]:
        """
        Get all registered data sources.
        
        Returns:
            List of all BarcodeDataSource instances
        """
        return self._sources.copy()
    
    def enable_source(self, source_name: str) -> bool:
        """Enable a data source by class name."""
        for source in self._sources:
            if source.__class__.__name__ == source_name:
                source.enabled = True
                print(f"✅ Enabled: {source.get_name()}")
                return True
        return False
    
    def disable_source(self, source_name: str) -> bool:
        """Disable a data source by class name."""
        for source in self._sources:
            if source.__class__.__name__ == source_name:
                source.enabled = False
                print(f"⏸️  Disabled: {source.get_name()}")
                return True
        return False
    
    def set_priority(self, source_name: str, priority: int) -> bool:
        """
        Set the priority of a data source.
        
        Args:
            source_name: The class name of the source
            priority: New priority value (higher = tried first)
            
        Returns:
            True if updated, False if source not found
        """
        for source in self._sources:
            if source.__class__.__name__ == source_name:
                source.priority = priority
                # Re-sort by priority
                self._sources.sort(key=lambda s: s.priority, reverse=True)
                print(f"🔄 Updated priority for {source.get_name()}: {priority}")
                return True
        return False
    
    def lookup(self, barcode: str, merge_strategy: str = "first_wins") -> Optional[Dict[str, Any]]:
        """
        Lookup barcode across all enabled data sources.
        
        Args:
            barcode: The barcode to lookup
            merge_strategy: How to merge data from multiple sources
                - "first_wins": Use first source that returns data
                - "merge_all": Merge data from all sources (fills gaps)
                - "best_quality": Choose source with most complete data
                
        Returns:
            Combined product data or None if not found
        """
        enabled_sources = self.get_enabled_sources()
        
        if not enabled_sources:
            print("⚠️  No enabled data sources available")
            return None
        
        print(f"🔍 Looking up barcode {barcode} across {len(enabled_sources)} sources...")
        
        if merge_strategy == "first_wins":
            return self._lookup_first_wins(barcode, enabled_sources)
        elif merge_strategy == "merge_all":
            return self._lookup_merge_all(barcode, enabled_sources)
        elif merge_strategy == "best_quality":
            return self._lookup_best_quality(barcode, enabled_sources)
        else:
            raise ValueError(f"Unknown merge strategy: {merge_strategy}")
    
    def _lookup_first_wins(self, barcode: str, sources: List[BarcodeDataSource]) -> Optional[Dict[str, Any]]:
        """Use the first source that returns data."""
        for source in sources:
            try:
                print(f"  → Trying {source.get_name()}...")
                data = source.fetch(barcode)
                if data:
                    print(f"  ✅ Found in {source.get_name()}")
                    data["_source"] = source.get_name()
                    data["_sources"] = [source.get_name()]
                    return data
            except Exception as e:
                print(f"  ❌ {source.get_name()} error: {e}")
        
        return None
    
    def _lookup_merge_all(self, barcode: str, sources: List[BarcodeDataSource]) -> Optional[Dict[str, Any]]:
        """Merge data from all sources that return results."""
        combined_data = {
            "barcode": barcode,
            "name": "Unknown Product",
            "category": "Other",
            "unit": "pieces",
            "_sources": [],
            "_merged_at": datetime.utcnow().isoformat()
        }
        
        found_any = False
        
        for source in sources:
            try:
                print(f"  → Trying {source.get_name()}...")
                data = source.fetch(barcode)
                if data:
                    print(f"  ✅ Found in {source.get_name()}")
                    found_any = True
                    combined_data["_sources"].append(source.get_name())
                    
                    # Merge data (only add if not already present)
                    for key, value in data.items():
                        if key == "nutrition":
                            # Merge nutrition data
                            if "nutrition" not in combined_data:
                                combined_data["nutrition"] = {}
                            for nut_key, nut_value in value.items():
                                if nut_value is not None and (
                                    nut_key not in combined_data["nutrition"] or 
                                    combined_data["nutrition"][nut_key] is None
                                ):
                                    combined_data["nutrition"][nut_key] = nut_value
                        elif value and (key not in combined_data or not combined_data.get(key)):
                            combined_data[key] = value
                            
            except Exception as e:
                print(f"  ❌ {source.get_name()} error: {e}")
        
        return combined_data if found_any else None
    
    def _lookup_best_quality(self, barcode: str, sources: List[BarcodeDataSource]) -> Optional[Dict[str, Any]]:
        """Choose the source with the most complete data."""
        results = []
        
        for source in sources:
            try:
                print(f"  → Trying {source.get_name()}...")
                data = source.fetch(barcode)
                if data:
                    print(f"  ✅ Found in {source.get_name()}")
                    data["_source"] = source.get_name()
                    data["_sources"] = [source.get_name()]
                    
                    # Calculate data quality score
                    score = self._calculate_quality_score(data)
                    results.append((score, data))
                    
            except Exception as e:
                print(f"  ❌ {source.get_name()} error: {e}")
        
        if not results:
            return None
        
        # Return the result with highest quality score
        results.sort(key=lambda x: x[0], reverse=True)
        best_data = results[0][1]
        print(f"  🏆 Best quality: {best_data['_source']} (score: {results[0][0]})")
        
        return best_data
    
    def _calculate_quality_score(self, data: Dict[str, Any]) -> int:
        """Calculate a quality score for product data."""
        score = 0
        
        # Basic fields
        if data.get("name") and data.get("name") != "Unknown Product":
            score += 10
        if data.get("brand"):
            score += 5
        if data.get("category") and data.get("category") != "Other":
            score += 5
        if data.get("image_url"):
            score += 3
        if data.get("ingredients"):
            score += 5
        if data.get("allergens"):
            score += 3
        
        # Nutrition data
        nutrition = data.get("nutrition", {})
        if nutrition:
            score += 10
            # Bonus for complete nutrition data
            nut_fields = ["calories", "protein", "carbs", "fat"]
            complete_fields = sum(1 for f in nut_fields if nutrition.get(f) is not None)
            score += complete_fields * 2
        
        return score
    
    def get_registry_info(self) -> Dict[str, Any]:
        """Get information about all registered sources."""
        return {
            "total_sources": len(self._sources),
            "enabled_sources": len(self.get_enabled_sources()),
            "sources": [s.get_info() for s in self._sources]
        }


# Utility functions for common operations
def merge_nutrition_data(target: Dict[str, Any], source: Dict[str, Any]) -> None:
    """Merge nutrition data from source into target."""
    if "nutrition" not in target:
        target["nutrition"] = {}
    
    source_nutrition = source.get("nutrition", {})
    for key, value in source_nutrition.items():
        if value is not None and (
            key not in target["nutrition"] or 
            target["nutrition"][key] is None
        ):
            target["nutrition"][key] = value


def categorize_product(categories: str) -> str:
    """Categorize product based on categories string."""
    if not categories:
        return "Other"
    
    categories = categories.lower()
    if any(word in categories for word in ["dairy", "milk", "cheese", "yogurt", "yoghurt", "butter", "cream"]):
        return "Dairy"
    if any(word in categories for word in ["meat", "chicken", "beef", "pork", "fish", "seafood", "protein"]):
        return "Proteins"
    if any(word in categories for word in ["fruit", "vegetable", "produce", "salad", "lettuce"]):
        return "Produce"
    if any(word in categories for word in ["beverage", "drink", "juice", "soda", "water", "beer", "wine"]):
        return "Beverages"
    if any(word in categories for word in ["grain", "bread", "pasta", "rice", "cereal", "flour"]):
        return "Pantry"
    if any(word in categories for word in ["snack", "chip", "cookie", "cracker", "candy"]):
        return "Snacks"
    if any(word in categories for word in ["sauce", "condiment", "dressing", "oil", "spice"]):
        return "Condiments"
    
    return "Other"


def infer_unit_from_quantity(quantity: str) -> str:
    """Infer unit from product quantity string."""
    if not quantity:
        return "pieces"
    
    quantity = quantity.lower()
    if any(unit in quantity for unit in ["ml", "liter", "litre", "l"]):
        return "ml"
    if any(unit in quantity for unit in ["kg", "gram", "g"]):
        return "g"
    if any(unit in quantity for unit in ["oz", "lb", "pound"]):
        return "oz"
    if any(unit in quantity for unit in ["count", "piece", "ct"]):
        return "pieces"
    
    return "pieces"
