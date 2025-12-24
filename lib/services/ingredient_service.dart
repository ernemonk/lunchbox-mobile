/// Ingredient detection and categorization service
/// Provides intelligent auto-detection of food categories and units
/// enabling quick, frictionless fridge inventory management
///
/// Philosophy: Minimize user input, maximize data quality through
/// intelligent inference. Based on RFC principle of "Pure utility."

class IngredientService {
  /// Comprehensive ingredient-to-category mapping
  /// Covers ~200 common grocery items across 5 categories
  static const Map<String, String> categoryMap = {
    // PROTEINS
    'eggs': 'Proteins',
    'egg': 'Proteins',
    'chicken': 'Proteins',
    'beef': 'Proteins',
    'steak': 'Proteins',
    'ground beef': 'Proteins',
    'pork': 'Proteins',
    'ham': 'Proteins',
    'bacon': 'Proteins',
    'fish': 'Proteins',
    'salmon': 'Proteins',
    'tuna': 'Proteins',
    'shrimp': 'Proteins',
    'turkey': 'Proteins',
    'tofu': 'Proteins',
    'tempeh': 'Proteins',
    'beans': 'Proteins',
    'lentils': 'Proteins',
    'chickpea': 'Proteins',
    'almonds': 'Proteins',
    'nuts': 'Proteins',
    'peanuts': 'Proteins',
    'cashews': 'Proteins',
    'hummus': 'Proteins',
    'protein powder': 'Proteins',
    'greek yogurt': 'Dairy',
    'cottage cheese': 'Dairy',
    
    // DAIRY
    'milk': 'Dairy',
    'cheese': 'Dairy',
    'cheddar': 'Dairy',
    'mozzarella': 'Dairy',
    'feta': 'Dairy',
    'parmesan': 'Dairy',
    'cream cheese': 'Dairy',
    'sour cream': 'Dairy',
    'butter': 'Dairy',
    'yogurt': 'Dairy',
    'kefir': 'Dairy',
    'whipped cream': 'Dairy',
    'ice cream': 'Dairy',
    'whey': 'Dairy',
    'lactose': 'Dairy',
    'condensed milk': 'Dairy',
    
    // PRODUCE
    'apple': 'Produce',
    'apples': 'Produce',
    'banana': 'Produce',
    'bananas': 'Produce',
    'orange': 'Produce',
    'oranges': 'Produce',
    'lemon': 'Produce',
    'lemons': 'Produce',
    'lime': 'Produce',
    'limes': 'Produce',
    'grape': 'Produce',
    'grapes': 'Produce',
    'berry': 'Produce',
    'berries': 'Produce',
    'blueberry': 'Produce',
    'strawberry': 'Produce',
    'raspberry': 'Produce',
    'blackberry': 'Produce',
    'watermelon': 'Produce',
    'melon': 'Produce',
    'pineapple': 'Produce',
    'mango': 'Produce',
    'avocado': 'Produce',
    'kiwi': 'Produce',
    'peach': 'Produce',
    'pear': 'Produce',
    'plum': 'Produce',
    'cherry': 'Produce',
    'coconut': 'Produce',
    'tomato': 'Produce',
    'tomatoes': 'Produce',
    'carrot': 'Produce',
    'carrots': 'Produce',
    'broccoli': 'Produce',
    'cauliflower': 'Produce',
    'spinach': 'Produce',
    'kale': 'Produce',
    'lettuce': 'Produce',
    'cabbage': 'Produce',
    'cucumber': 'Produce',
    'cucumbers': 'Produce',
    'zucchini': 'Produce',
    'bell pepper': 'Produce',
    'pepper': 'Produce',
    'onion': 'Produce',
    'onions': 'Produce',
    'garlic': 'Produce',
    'ginger': 'Produce',
    'potato': 'Produce',
    'potatoes': 'Produce',
    'sweet potato': 'Produce',
    'corn': 'Produce',
    'peas': 'Produce',
    'celery': 'Produce',
    'mushroom': 'Produce',
    'mushrooms': 'Produce',
    'bean': 'Produce',
    'green bean': 'Produce',
    'asparagus': 'Produce',
    'artichoke': 'Produce',
    'radish': 'Produce',
    'beet': 'Produce',
    'squash': 'Produce',
    'eggplant': 'Produce',
    'parsnip': 'Produce',
    'turnip': 'Produce',
    'leek': 'Produce',
    'arugula': 'Produce',
    'parsley': 'Produce',
    'cilantro': 'Produce',
    'basil': 'Produce',
    'rosemary': 'Produce',
    'thyme': 'Produce',
    'mint': 'Produce',
    
    // PANTRY
    'rice': 'Pantry',
    'pasta': 'Pantry',
    'noodles': 'Pantry',
    'ramen': 'Pantry',
    'bread': 'Pantry',
    'cereal': 'Pantry',
    'granola': 'Pantry',
    'oats': 'Pantry',
    'oatmeal': 'Pantry',
    'flour': 'Pantry',
    'sugar': 'Pantry',
    'salt': 'Pantry',
    'spice': 'Pantry',
    'black pepper': 'Pantry',
    'cinnamon': 'Pantry',
    'paprika': 'Pantry',
    'cumin': 'Pantry',
    'oregano': 'Pantry',
    'oil': 'Pantry',
    'olive oil': 'Pantry',
    'coconut oil': 'Pantry',
    'vinegar': 'Pantry',
    'soy sauce': 'Pantry',
    'hot sauce': 'Pantry',
    'salsa': 'Pantry',
    'peanut butter': 'Pantry',
    'almond butter': 'Pantry',
    'jam': 'Pantry',
    'jelly': 'Pantry',
    'honey': 'Pantry',
    'maple syrup': 'Pantry',
    'pasta sauce': 'Pantry',
    'tomato sauce': 'Pantry',
    'sauce': 'Pantry',
    'broth': 'Pantry',
    'stock': 'Pantry',
    'chicken broth': 'Pantry',
    'beef broth': 'Pantry',
    'vegetable broth': 'Pantry',
    'canned tomato': 'Pantry',
    'beans canned': 'Pantry',
    'chickpea canned': 'Pantry',
    'tuna canned': 'Pantry',
    'salmon canned': 'Pantry',
    'peanut': 'Pantry',
    'chocolate': 'Pantry',
    'cocoa powder': 'Pantry',
    'coffee': 'Pantry',
    'tea': 'Pantry',
    'baking powder': 'Pantry',
    'baking soda': 'Pantry',
    'vanilla extract': 'Pantry',
    'leavening': 'Pantry',
    'quinoa': 'Pantry',
    'couscous': 'Pantry',
    'polenta': 'Pantry',
    'cornmeal': 'Pantry',
    'buckwheat': 'Pantry',
    'millet': 'Pantry',
    'barley': 'Pantry',
    'lentil': 'Pantry',
  };

  /// Comprehensive unit-to-item-type mapping
  /// Suggests appropriate unit based on item characteristics
  static const Map<String, String> unitMap = {
    // Count-based items (pieces, individual units)
    'egg': 'pieces',
    'eggs': 'pieces',
    'apple': 'pieces',
    'banana': 'pieces',
    'orange': 'pieces',
    'tomato': 'pieces',
    'potato': 'pieces',
    'onion': 'pieces',
    'carrot': 'pieces',
    'bread': 'pieces',
    'roll': 'pieces',
    'bun': 'pieces',
    'bagel': 'pieces',
    'cookie': 'pieces',
    'donut': 'pieces',
    'pizza': 'pieces',

    // Liquid items (ml, l)
    'milk': 'ml',
    'water': 'ml',
    'juice': 'ml',
    'oil': 'ml',
    'vinegar': 'ml',
    'sauce': 'ml',
    'soup': 'ml',
    'broth': 'ml',
    'stock': 'ml',
    'cream': 'ml',
    'yogurt': 'ml',
    'kefir': 'ml',
    'honey': 'ml',
    'maple syrup': 'ml',
    'vanilla extract': 'ml',
    'soy sauce': 'ml',
    'hot sauce': 'ml',
    'salsa': 'ml',

    // Weight-based items (g, kg)
    'flour': 'g',
    'sugar': 'g',
    'salt': 'g',
    'rice': 'g',
    'pasta': 'g',
    'lentils': 'g',
    'nuts': 'g',
    'chocolate': 'g',
    'cheese': 'g',
    'butter': 'g',
    'meat': 'g',
    'beef': 'g',
    'pork': 'g',
    'fish': 'g',
    'shrimp': 'g',
    'spinach': 'g',
    'broccoli': 'g',
    'asparagus': 'g',
    'mushroom': 'g',
    'coffee': 'g',
    'cocoa powder': 'g',
  };

  /// Detect category from item name using fuzzy matching
  /// Returns matched category or 'Other' if no match found
  ///
  /// Algorithm:
  /// 1. Exact match (ignoring case, trimmed)
  /// 2. Partial/substring match
  /// 3. Word boundary match
  /// 4. Default to 'Other'
  static String detectCategory(String itemName) {
    if (itemName.isEmpty) return 'Other';

    final normalized = itemName.toLowerCase().trim();

    // Exact match
    if (categoryMap.containsKey(normalized)) {
      return categoryMap[normalized]!;
    }

    // Partial match (substring anywhere)
    for (final entry in categoryMap.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    // Word boundary match (check first/last word)
    final words = normalized.split(RegExp(r'\s+'));
    for (final word in words) {
      if (categoryMap.containsKey(word)) {
        return categoryMap[word]!;
      }
    }

    return 'Other';
  }

  /// Suggest unit based on item name and type
  /// Returns suggested unit or 'pieces' as default
  ///
  /// Priority:
  /// 1. Exact match from unitMap
  /// 2. Partial/substring match
  /// 3. Infer from category (liquids → ml, weights → g)
  /// 4. Default to 'pieces'
  static String suggestUnit(String itemName) {
    if (itemName.isEmpty) return 'pieces';

    final normalized = itemName.toLowerCase().trim();

    // Exact match
    if (unitMap.containsKey(normalized)) {
      return unitMap[normalized]!;
    }

    // Partial match
    for (final entry in unitMap.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        return entry.value;
      }
    }

    // Infer from category
    final category = detectCategory(itemName);
    switch (category) {
      case 'Dairy':
        // Dairy can be liquid or weight
        if (normalized.contains('milk') || 
            normalized.contains('cream') || 
            normalized.contains('yogurt')) {
          return 'ml';
        }
        return 'g'; // cheese, butter
      case 'Produce':
        // Most produce is counted or by weight
        if (normalized.contains('juice') || 
            normalized.contains('sauce') ||
            normalized.contains('oil')) {
          return 'ml';
        }
        return 'pieces'; // most produce by count
      case 'Pantry':
        // Pantry is mostly weight or volume
        if (normalized.contains('oil') || 
            normalized.contains('sauce') ||
            normalized.contains('juice') ||
            normalized.contains('milk')) {
          return 'ml';
        }
        return 'g'; // flour, rice, pasta, etc.
      case 'Proteins':
        return 'pieces'; // proteins typically counted
      default:
        return 'pieces';
    }
  }

  /// Get list of all available categories
  static List<String> getCategories() {
    return ['Produce', 'Proteins', 'Dairy', 'Pantry', 'Other'];
  }

  /// Get list of all available units
  static List<String> getUnits() {
    return ['pieces', 'kg', 'g', 'lbs', 'oz', 'cups', 'tbsp', 'tsp', 'ml', 'l', 'bag', 'bunch', 'head'];
  }

  /// Get category color (for future visual categorization)
  /// Returns hex color string
  static String getCategoryColor(String category) {
    const colors = {
      'Produce': '#51CF66',    // Green
      'Proteins': '#FF6B6B',   // Red
      'Dairy': '#FFD43B',      // Yellow
      'Pantry': '#748DD8',     // Blue
      'Other': '#A8A8A8',      // Gray
    };
    return colors[category] ?? colors['Other']!;
  }

  /// Get category icon emoji
  static String getCategoryEmoji(String category) {
    const emojis = {
      'Produce': '🥬',
      'Proteins': '🍗',
      'Dairy': '🧈',
      'Pantry': '🍝',
      'Other': '📦',
    };
    return emojis[category] ?? emojis['Other']!;
  }
}
