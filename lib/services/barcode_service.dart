/// Barcode scanning and product lookup service
/// Integrates with OpenFoodFacts API for product data
/// Provides intelligent barcode-to-ingredient detection

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeService {
  static const String _openFoodFactsAPI =
      'https://world.openfoodfacts.org/api/v0/product';

  static const Duration _cacheExpiry = Duration(days: 30);

  /// Scan barcode from device camera
  /// Returns barcode value (EAN-13, UPC-A, etc.) or null if cancelled
  ///
  /// Supported formats:
  /// - EAN-13 (most groceries)
  /// - Code128 (barcodes, validated by barcode_scan2)
  /// - EAN-8 (small items)
  static Future<String?> scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan(
        options: const ScanOptions(
          strings: {
            'cancel': 'Cancel',
            'flash_on': 'Flash on',
            'flash_off': 'Flash off',
          },
          restrictFormat: [
            BarcodeFormat.ean13,
            BarcodeFormat.code128,
            BarcodeFormat.ean8,
          ],
          autoEnableFlash: false,
          android: AndroidOptions(
            aspectTolerance: 0.00,
            useAutoFocus: true,
          ),
        ),
      );

      if (result.rawContent.isNotEmpty) {
        return result.rawContent;
      }
    } catch (e) {
      print('[BARCODE] Scan error: $e');
    }
    return null;
  }

  /// Lookup product details from barcode
  /// First checks local cache, then queries OpenFoodFacts API
  ///
  /// Returns:
  /// - name: Product name (pre-filled for dialog)
  /// - barcode: Original barcode scanned
  /// - category: Detected from product categories
  /// - unit: Suggested unit based on product type
  /// - brand: Product brand (optional)
  /// - quantity: Product quantity/size (optional)
  static Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    try {
      // Check cache first (30-day expiry)
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('barcode_$barcode');
      if (cached != null) {
        final cachedTime =
            prefs.getInt('barcode_${barcode}_time') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - cachedTime < _cacheExpiry.inMilliseconds) {
          return jsonDecode(cached);
        } else {
          // Cache expired, remove it
          await prefs.remove('barcode_$barcode');
          await prefs.remove('barcode_${barcode}_time');
        }
      }

      // Query OpenFoodFacts API
      print('\n========== BARCODE LOOKUP START ==========');
      print('[BARCODE] Looking up barcode: $barcode');
      print('[BARCODE] API URL: $_openFoodFactsAPI/$barcode.json');
      
      final response = await http
          .get(
            Uri.parse('$_openFoodFactsAPI/$barcode.json'),
          )
          .timeout(const Duration(seconds: 5));

      print('[BARCODE] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('[BARCODE] Full API Response:');
        print(jsonEncode(data));
        print('\n[BARCODE] Product status: ${data['status']}');

        if (data['status'] == 1) {
          final product = data['product'];
          
          print('\n[BARCODE] Raw Product Data:');
          print('  - product_name: ${product['product_name']}');
          print('  - brands: ${product['brands']}');
          print('  - quantity: ${product['quantity']}');
          print('  - categories: ${product['categories']}');
          print('  - categories_tags: ${product['categories_tags']}');
          
          final result = {
            'name': _extractProductName(product),
            'barcode': barcode,
            'category': _categorizeProduct(product),
            'unit': _suggestUnit(product),
            'brand': product['brands'] ?? '',
            'quantity': product['quantity'] ?? '',
          };
          
          print('\n[BARCODE] Processed Result:');
          print('  - name: ${result['name']}');
          print('  - category: ${result['category']}');
          print('  - unit: ${result['unit']}');
          print('  - brand: ${result['brand']}');
          print('  - quantity: ${result['quantity']}');
          print('========== BARCODE LOOKUP END ==========\n');

          // Cache result
          await prefs.setString(
            'barcode_$barcode',
            jsonEncode(result),
          );
          await prefs.setInt(
            'barcode_${barcode}_time',
            DateTime.now().millisecondsSinceEpoch,
          );

          return result;
        }
      }
    } catch (e) {
      print('[BARCODE] Lookup error: $e');
      print('========== BARCODE LOOKUP END (ERROR) ==========\n');
    }

    // Fallback: return unknown product
    print('[BARCODE] Using fallback data for unknown product');
    print('========== BARCODE LOOKUP END (FALLBACK) ==========\n');
    return {
      'name': 'Scanned Item',
      'barcode': barcode,
      'category': 'Other',
      'unit': 'pieces',
      'brand': '',
      'quantity': '',
    };
  }

  /// Extract clean product name from OpenFoodFacts data
  /// Removes redundant brand/quantity info for clarity
  static String _extractProductName(Map<String, dynamic> product) {
    // Try multiple name fields in order of preference
    var name = product['product_name'] ?? 
               product['product_name_en'] ?? 
               product['generic_name'] ?? 
               product['abbreviated_product_name'] ?? 
               '';

    // If still empty or "Unknown", try to construct from brand + generic name
    if (name.isEmpty || name.toLowerCase() == 'unknown' || name.toLowerCase() == 'unknown product') {
      final brand = product['brands'] ?? '';
      final genericName = product['generic_name'] ?? product['generic_name_en'] ?? '';
      
      if (brand.isNotEmpty && genericName.isNotEmpty) {
        name = '$brand $genericName';
      } else if (brand.isNotEmpty) {
        name = '$brand Product';
      } else if (genericName.isNotEmpty) {
        name = genericName;
      } else {
        name = 'Unknown Item';
      }
    }

    // Remove trailing quantity if present (will show separately)
    name = name.replaceAll(RegExp(r'\s*\(\d+[a-zA-Z]*\)\s*$'), '').trim();

    return name;
  }

  /// Categorize product based on OpenFoodFacts categories field
  /// Maps API categories to app's 5-category system
  ///
  /// Maps to:
  /// - Dairy: milk, cheese, yogurt, cream, butter
  /// - Proteins: meat, fish, poultry, eggs, beans, nuts
  /// - Produce: fruits, vegetables, produce
  /// - Pantry: grains, pasta, rice, cereals, staples
  /// - Other: unrecognized
  static String _categorizeProduct(Map<String, dynamic> product) {
    final categories = product['categories']?.toString().toLowerCase() ?? '';
    final labels = product['labels']?.toString().toLowerCase() ?? '';
    final combined = '$categories $labels';

    // Dairy check
    if (combined.contains('dairy') ||
        combined.contains('milk') ||
        combined.contains('cheese') ||
        combined.contains('yogurt') ||
        combined.contains('butter')) {
      return 'Dairy';
    }

    // Proteins check
    if (combined.contains('meat') ||
        combined.contains('protein') ||
        combined.contains('fish') ||
        combined.contains('poultry') ||
        combined.contains('egg') ||
        combined.contains('legume') ||
        combined.contains('nut')) {
      return 'Meat & Protein';
    }

    // Produce check
    if (combined.contains('fruit') ||
        combined.contains('vegetable') ||
        combined.contains('produce') ||
        combined.contains('plant') ||
        combined.contains('organic')) {
      return 'Vegetables';
    }

    // Pantry check
    if (combined.contains('grain') ||
        combined.contains('pasta') ||
        combined.contains('rice') ||
        combined.contains('cereal') ||
        combined.contains('bread') ||
        combined.contains('staple')) {
      return 'Bread & Grains';
    }

    return 'Other';
  }

  /// Suggest unit based on product quantity/type
  /// Infers from product quantity field or category
  static String _suggestUnit(Map<String, dynamic> product) {
    final quantity = product['quantity']?.toString().toLowerCase() ?? '';
    final categories = product['categories']?.toString().toLowerCase() ?? '';

    // Check quantity field
    if (quantity.contains('ml') || quantity.contains('l')) return 'ml';
    if (quantity.contains('kg') || quantity.contains('g')) return 'g';
    if (quantity.contains('oz') ||
        quantity.contains('lbs') ||
        quantity.contains('lb')) return 'lbs';
    if (quantity.contains('piece') ||
        quantity.contains('count') ||
        quantity.contains('dozen')) return 'pieces';

    // Infer from category
    if (categories.contains('liquid') || categories.contains('beverage')) {
      return 'ml';
    }

    // Default
    return 'pieces';
  }

  /// Clear barcode cache (useful for testing or user request)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith('barcode_')) {
        await prefs.remove(key);
      }
    }
    print('[BARCODE] Cache cleared');
  }

  /// Get cache statistics for debugging
  static Future<Map<String, int>> getCacheStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int validCount = 0;
    int expiredCount = 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final key in keys) {
      if (key.startsWith('barcode_') && key.endsWith('_time')) {
        final time = prefs.getInt(key) ?? 0;
        if (now - time < _cacheExpiry.inMilliseconds) {
          validCount++;
        } else {
          expiredCount++;
        }
      }
    }

    return {
      'valid': validCount,
      'expired': expiredCount,
      'total': validCount + expiredCount,
    };
  }
}
