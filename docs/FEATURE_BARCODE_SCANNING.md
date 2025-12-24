# 📱 Feature: Barcode Scanning Integration

**Status:** Planned (P0 - Implement Second)  
**Date Created:** December 22, 2025  
**Priority:** Critical  
**Estimated Effort:** 4-5 days  
**Depends On:** Quick Add Mode (feature_quick_add_mode.md)

---

## 📋 Overview

**Goal:** Enable users to scan product barcodes to instantly populate fridge items with pre-filled name and category, eliminating manual data entry.

**Problem Solved:**
- Typing every grocery item is tedious → users skip fridge updates
- Barcode scanning is expected UX pattern (everyone's phone can do it)
- RFC requires "Pure utility" — scanning is the ultimate utility

**Success Metric:**
- 60%+ of grocery items scanned (not typed)
- Fridge update time drops to <2 seconds per item
- Barcode coverage reaches 85%+ of common items

---

## 🎯 User Flow

```
User taps FAB "Scan" button
    ↓
Camera permission check (first time)
    ↓
Camera opens in barcode scanner mode
    ↓
User points camera at product barcode
    ↓
Barcode detected & scanned
    ↓
Lookup barcode in database (OpenFoodFacts or local)
    ↓
Pre-fill item dialog:
    ├─ name: "Organic Eggs (12 count)" ✓ Pre-filled
    ├─ quantity: "1" (can edit)
    ├─ unit: "pieces" (auto-detected) ✓
    ├─ category: "Proteins" ✓ Auto-detected
    ↓
User reviews/edits and taps "Add"
    ↓
Item added to fridge instantly
    ↓
Toast: "Scanned 1 dozen eggs"
```

---

## 🛠️ Technical Implementation

### Architecture Options

**Option A: barcode_scan2 (Recommended)**
- Native iOS/Android barcode scanning
- Returns barcode value (EAN-13, UPC, etc.)
- Lightweight, fast, works offline

**Option B: mobile_scanner**
- More modern, better maintained
- Real-time scanning with preview
- Heavier dependency

**Recommendation:** `barcode_scan2` for simplicity + speed

---

### Phase 1: Add Dependencies

**File:** `pubspec.yaml`

```yaml
dependencies:
  barcode_scan2: ^4.3.0  # Barcode scanning
  http: ^1.1.0           # HTTP requests for OpenFoodFacts API
  shared_preferences: ^2.0.0  # Cache barcode lookups
```

**Command:**
```bash
flutter pub add barcode_scan2 http
```

---

### Phase 2: Create Barcode Service

**New File:** `lib/services/barcode_service.dart`

```dart
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeService {
  static const String _openFoodFactsAPI = 
    'https://world.openfoodfacts.org/api/v0/product';

  /// Scan barcode from camera
  static Future<String?> scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan(
        options: const ScanOptions(
          strings: {
            'cancel': 'Cancel',
            'flash_on': 'Flash on',
            'flash_off': 'Flash off',
          },
          restrictFormat: [BarcodeFormat.ean13, BarcodeFormat.upca],
          autoEnableFlash: false,
          android: AndroidOptions(
            aspectTolerance: 0.00,
            useAutoFocus: true,
          ),
        ),
      );

      if (result.isValid) {
        return result.rawContent; // Return barcode value
      }
    } catch (e) {
      print('[BARCODE] Scan error: $e');
    }
    return null;
  }

  /// Lookup product details from barcode
  static Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    try {
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('barcode_$barcode');
      if (cached != null) {
        return jsonDecode(cached);
      }

      // Query OpenFoodFacts API
      final response = await http.get(
        Uri.parse('$_openFoodFactsAPI/$barcode.json'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 1) {
          final product = data['product'];
          final result = {
            'name': product['product_name'] ?? 'Unknown Item',
            'barcode': barcode,
            'category': _categorizeProduct(product),
            'unit': _suggestUnit(product),
          };

          // Cache result for 30 days
          await prefs.setString(
            'barcode_$barcode',
            jsonEncode(result),
          );

          return result;
        }
      }
    } catch (e) {
      print('[BARCODE] Lookup error: $e');
    }

    // Fallback: return unknown product
    return {
      'name': 'Scanned Item',
      'barcode': barcode,
      'category': 'Other',
      'unit': 'pieces',
    };
  }

  /// Categorize product based on OpenFoodFacts category
  static String _categorizeProduct(Map<String, dynamic> product) {
    final categories = product['categories']?.toString().toLowerCase() ?? '';
    
    if (categories.contains('dairy')) return 'Dairy';
    if (categories.contains('meat') || categories.contains('protein')) return 'Proteins';
    if (categories.contains('fruit') || categories.contains('vegetable') || 
        categories.contains('produce')) return 'Produce';
    if (categories.contains('grain') || categories.contains('pasta') || 
        categories.contains('rice')) return 'Pantry';
    
    return 'Other';
  }

  /// Suggest unit based on product type
  static String _suggestUnit(Map<String, dynamic> product) {
    final quantity = product['quantity']?.toString().toLowerCase() ?? '';
    
    if (quantity.contains('ml') || quantity.contains('l')) return 'ml';
    if (quantity.contains('kg') || quantity.contains('g')) return 'g';
    if (quantity.contains('oz') || quantity.contains('lbs')) return 'lbs';
    if (quantity.contains('pieces') || quantity.contains('count')) return 'pieces';
    
    return 'pieces'; // default
  }
}
```

---

### Phase 3: iOS Configuration

**File:** `ios/Runner/Info.plist`

Add camera permission:
```xml
<key>NSCameraUsageDescription</key>
<string>Lunchbox needs camera access to scan product barcodes for your fridge inventory.</string>
```

---

### Phase 4: Android Configuration

**File:** `android/app/src/main/AndroidManifest.xml`

Add camera permission:
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

**File:** `android/app/build.gradle`

Ensure compileSdkVersion ≥ 31:
```gradle
android {
    compileSdkVersion 33
    ...
}
```

---

### Phase 5: Update Fridge Page UI

**File:** `lib/views/myfridge_page.dart`

Replace FAB with two-button option:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    // ... existing code ...
    
    floatingActionButton: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Scan button (on top)
        FloatingActionButton.extended(
          onPressed: _scanBarcode,
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Scan'),
          heroTag: 'scan_btn',
        ),
        const SizedBox(height: 16),
        // Quick Add button (below)
        FloatingActionButton.extended(
          onPressed: () => _showFridgeItemDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          heroTag: 'add_btn',
        ),
      ],
    ),
  );
}

Future<void> _scanBarcode() async {
  final barcode = await BarcodeService.scanBarcode();
  
  if (barcode != null && barcode.isNotEmpty) {
    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Lookup product details
    final product = await BarcodeService.lookupBarcode(barcode);
    
    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      
      if (product != null) {
        // Show pre-filled add dialog
        _showScannedProductDialog(product);
      }
    }
  }
}

void _showScannedProductDialog(Map<String, dynamic> product) {
  TextEditingController itemController =
      TextEditingController(text: product['name'] ?? '');
  TextEditingController quantityController =
      TextEditingController(text: '1');
  String? selectedUnit = product['unit'] ?? 'pieces';
  final String category = product['category'] ?? 'Other';

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.secondary),
          const SizedBox(width: 8),
          const Text('Scanned Product'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category: $category',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: itemController,
            decoration: InputDecoration(
              labelText: 'Product name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedUnit,
                  items: ['pieces', 'kg', 'g', 'lbs', 'cups', 'ml', 'l']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                  onChanged: (val) => selectedUnit = val,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _addItem(
              itemController.text.trim(),
              quantityController.text.trim(),
              category: category,
              unit: selectedUnit ?? 'pieces',
            );
            Navigator.pop(context);
          },
          child: const Text('Add Scanned Item'),
        ),
      ],
    ),
  );
}
```

---

## 🔗 Barcode Database Integration

**Why OpenFoodFacts?**
- Free, open-source, community maintained
- 2+ million products in database
- Covers 150+ countries
- No API key required for basic lookups

**Coverage:**
- Grocery items: 95%+
- Fresh produce: 20% (no barcode in store)
- Restaurant items: <5%

**Fallback Strategy:**
- If barcode not found in API → return generic "Scanned Item"
- User can edit name manually
- Still saves category auto-detection if found

---

## 🗄️ Firestore Update

```dart
fridge: [
  {
    name: "Organic Eggs (12 count)",
    quantity: "1",
    unit: "pieces",
    category: "Proteins",
    barcode: "5410228103109",  // NEW
    expiryDate: null,
    addedAt: "2025-12-22T10:30:00Z"
  }
]
```

---

## ✅ Testing Checklist

- [ ] Camera permission prompt shows on first scan
- [ ] Barcode successfully scans (test with real products)
- [ ] OpenFoodFacts API returns product name correctly
- [ ] Category auto-detected for scanned items
- [ ] Unknown barcodes fall back gracefully
- [ ] Scanned item dialog pre-fills all fields
- [ ] Quantity defaults to 1, user can edit
- [ ] Barcode cached in SharedPreferences (offline lookups)
- [ ] Rapid scans don't cause API rate limiting
- [ ] Works on iOS 12+ and Android 6+

---

## 📊 Edge Cases

| Scenario | Behavior |
|----------|----------|
| Barcode not in database | Show "Scanned Item" with category "Other" |
| No internet connection | Use cached results if available, fallback to generic item |
| Invalid barcode | Show error, allow retry |
| User denies camera permission | Show friendly message, link to settings |
| Barcode already in fridge | Allow duplicate (user might have multiple) |

---

## 🚀 Next Steps

1. Add `barcode_scan2` and `http` packages
2. Create `lib/services/barcode_service.dart`
3. Update iOS Info.plist for camera permission
4. Update Android manifest for camera permission
5. Update fridge page with scan button
6. Test with 10+ real products
7. Proceed to OCR Detection feature

---

## 📊 Success Criteria

- User can scan barcode in <3 seconds
- 90%+ of scanned items found in OpenFoodFacts
- Category correctly auto-detected for 85%+ items
- No crashes or permission issues

