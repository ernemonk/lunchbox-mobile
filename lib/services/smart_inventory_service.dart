/// Smart Inventory Management Service
/// Handles intelligent duplicate detection, merging, and quantity management
/// for fridge items from Cloud Vision API

class SmartInventoryService {
  /// Calculate similarity between two food names (0.0 to 1.0)
  /// Uses normalized Levenshtein distance and semantic matching
  static double calculateSimilarity(String name1, String name2) {
    final n1 = name1.toLowerCase().trim();
    final n2 = name2.toLowerCase().trim();
    
    // Exact match
    if (n1 == n2) return 1.0;
    
    // One contains the other (e.g., "Apple" and "Green Apple")
    if (n1.contains(n2) || n2.contains(n1)) return 0.85;
    
    // Check for common food variations
    if (_areVariations(n1, n2)) return 0.75;
    
    // Levenshtein distance similarity
    final distance = _levenshteinDistance(n1, n2);
    final maxLength = n1.length > n2.length ? n1.length : n2.length;
    final similarity = 1.0 - (distance / maxLength);
    
    return similarity;
  }
  
  /// Check if two names are known variations of the same food
  static bool _areVariations(String n1, String n2) {
    final variations = [
      {'milk', 'whole milk', 'skim milk', 'almond milk', 'oat milk', 'soy milk'},
      {'cheese', 'cheddar', 'mozzarella', 'swiss', 'parmesan', 'feta'},
      {'apple', 'apples', 'gala apple', 'red apple', 'green apple'},
      {'orange', 'oranges', 'orange fruit'},
      {'banana', 'bananas'},
      {'tomato', 'tomatoes'},
      {'onion', 'onions'},
      {'carrot', 'carrots'},
      {'pepper', 'peppers', 'bell pepper', 'green pepper', 'red pepper'},
      {'chicken', 'raw chicken', 'cooked chicken'},
      {'egg', 'eggs'},
      {'bread', 'bread loaf', 'sliced bread'},
      {'yogurt', 'greek yogurt'},
      {'butter', 'margarine'},
      {'potato', 'potatoes', 'sweet potato'},
    ];
    
    for (final group in variations) {
      if (group.contains(n1) && group.contains(n2)) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;
    
    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );
    
    for (var i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }
    
    for (var i = 1; i <= len1; i++) {
      for (var j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[len1][len2];
  }
  
  /// Smart merge detected items with existing fridge inventory
  /// Returns list of merged items and action summary
  static SmartMergeResult mergeWithExistingInventory({
    required List<Map<String, dynamic>> detectedItems,
    required List<Map<String, dynamic>> existingItems,
    double similarityThreshold = 0.75,
  }) {
    final List<Map<String, dynamic>> itemsToAdd = [];
    final List<Map<String, dynamic>> itemsToUpdate = [];
    final List<String> duplicatesSkipped = [];
    
    // Group detected items by name to count duplicates
    final Map<String, List<Map<String, dynamic>>> groupedDetections = {};
    for (final detected in detectedItems) {
      final name = (detected['name'] as String).toLowerCase().trim();
      groupedDetections.putIfAbsent(name, () => []).add(detected);
    }
    
    // Process each unique detected item
    for (final entry in groupedDetections.entries) {
      final detectedName = entry.key;
      final detections = entry.value;
      final count = detections.length;
      
      // Get the best detection (highest confidence)
      final bestDetection = detections.reduce((a, b) {
        final confA = double.tryParse(a['confidence']?.toString() ?? '0') ?? 0;
        final confB = double.tryParse(b['confidence']?.toString() ?? '0') ?? 0;
        return confA > confB ? a : b;
      });
      
      // Check if similar item exists in inventory
      Map<String, dynamic>? matchingItem;
      int? matchingIndex;
      double bestSimilarity = 0.0;
      
      for (var i = 0; i < existingItems.length; i++) {
        final existing = existingItems[i];
        final existingName = (existing['name'] as String).toLowerCase().trim();
        final similarity = calculateSimilarity(detectedName, existingName);
        
        if (similarity >= similarityThreshold && similarity > bestSimilarity) {
          bestSimilarity = similarity;
          matchingItem = existing;
          matchingIndex = i;
        }
      }
      
      if (matchingItem != null && matchingIndex != null) {
        // Similar item exists - update quantity
        final existingQty = int.tryParse(matchingItem['quantity']?.toString() ?? '1') ?? 1;
        final newQty = existingQty + count;
        
        itemsToUpdate.add({
          'index': matchingIndex,
          'item': {
            ...matchingItem,
            'quantity': newQty.toString(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          'addedCount': count,
          'originalName': matchingItem['name'],
          'detectedName': bestDetection['name'],
          'similarity': bestSimilarity,
        });
      } else {
        // New item - add to inventory
        itemsToAdd.add({
          'name': bestDetection['name'],
          'quantity': count.toString(),
          'unit': bestDetection['unit'] ?? 'pieces',
          'category': _autoDetectCategory(bestDetection['name']),
          'confidence': bestDetection['confidence'],
          'addedAt': DateTime.now().toIso8601String(),
        });
      }
    }
    
    return SmartMergeResult(
      itemsToAdd: itemsToAdd,
      itemsToUpdate: itemsToUpdate,
      duplicatesSkipped: duplicatesSkipped,
    );
  }
  
  /// Auto-detect category based on food name
  static String _autoDetectCategory(String name) {
    final n = name.toLowerCase();
    
    // Fruits
    if (RegExp(r'\b(apple|banana|orange|grape|berry|strawberry|blueberry|lemon|lime|pear|peach|plum|avocado|mango|pineapple|melon|watermelon|cherry|kiwi|pomegranate|fig|date|fruit)\b').hasMatch(n)) {
      return 'Fruits';
    }
    
    // Vegetables
    if (RegExp(r'\b(lettuce|salad|spinach|kale|tomato|onion|garlic|carrot|celery|broccoli|cauliflower|cucumber|pepper|zucchini|squash|eggplant|potato|mushroom|asparagus|vegetable)\b').hasMatch(n)) {
      return 'Vegetables';
    }
    
    // Dairy
    if (RegExp(r'\b(milk|cheese|butter|yogurt|cream|egg|dairy|cheddar|mozzarella|parmesan|feta)\b').hasMatch(n)) {
      return 'Dairy';
    }
    
    // Meat & Protein
    if (RegExp(r'\b(chicken|beef|pork|turkey|fish|salmon|tuna|seafood|shrimp|meat|bacon|ham|sausage|protein|tofu|tempeh)\b').hasMatch(n)) {
      return 'Meat & Protein';
    }
    
    // Beverages
    if (RegExp(r'\b(juice|water|soda|beer|wine|tea|coffee|drink|beverage|smoothie|shake|milk)\b').hasMatch(n)) {
      return 'Beverages';
    }
    
    // Condiments
    if (RegExp(r'\b(sauce|ketchup|mustard|mayo|ranch|salsa|jam|jelly|honey|syrup|pickle|condiment|dressing)\b').hasMatch(n)) {
      return 'Condiments';
    }
    
    // Bread & Grains
    if (RegExp(r'\b(bread|bagel|bun|roll|tortilla|rice|pasta|noodles|cereal|grain)\b').hasMatch(n)) {
      return 'Bread & Grains';
    }
    
    return 'Other';
  }
}

/// Result of smart merge operation
class SmartMergeResult {
  final List<Map<String, dynamic>> itemsToAdd;
  final List<Map<String, dynamic>> itemsToUpdate;
  final List<String> duplicatesSkipped;
  
  SmartMergeResult({
    required this.itemsToAdd,
    required this.itemsToUpdate,
    required this.duplicatesSkipped,
  });
  
  int get totalChanges => itemsToAdd.length + itemsToUpdate.length;
  
  String getSummary() {
    final parts = <String>[];
    if (itemsToAdd.isNotEmpty) {
      parts.add('${itemsToAdd.length} new');
    }
    if (itemsToUpdate.isNotEmpty) {
      parts.add('${itemsToUpdate.length} updated');
    }
    if (duplicatesSkipped.isNotEmpty) {
      parts.add('${duplicatesSkipped.length} duplicates');
    }
    return parts.join(', ');
  }
}
