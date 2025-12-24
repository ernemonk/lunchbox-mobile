import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_colors.dart';
import '../services/ingredient_service.dart';
import '../services/barcode_service.dart';
import '../services/smart_barcode_service.dart';
import '../services/ocr_service.dart';
import '../services/image_recognition_service.dart';
import '../widgets/ocr_review_dialog.dart';
import '../widgets/smart_barcode_confirmation_dialog.dart';

/// Fridge inventory management page.
/// 
/// Allows users to:
/// - View their fridge contents
/// - Add new items with quantities
/// - Edit existing items
/// - Delete items
/// 
/// Data is synced with Firebase Firestore.
class MyFridgePage extends StatefulWidget {
  const MyFridgePage({super.key});

  @override
  State<MyFridgePage> createState() => _MyFridgePageState();
}

class _MyFridgePageState extends State<MyFridgePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> fridgeItems = [];
  String? _selectedCategory; // null = All

  /// Get unique categories from fridge items
  List<String> get _categories {
    final categories = fridgeItems
        .map((item) => item['category'] as String? ?? 'Other')
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// Get filtered items based on selected category
  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == null) return fridgeItems;
    return fridgeItems
        .where((item) => (item['category'] ?? 'Other') == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchFridgeContents();
  }

  Future<void> _fetchFridgeContents() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['fridge'] != null) {
        setState(() {
          fridgeItems = List<Map<String, dynamic>>.from(data['fridge']);
        });
      }
    }
  }

void _showFridgeItemDialog({Map<String, dynamic>? item, int? index}) {
  if (item == null) {
    _showQuickAddDialog();
  } else {
    _showFullEditDialog(item: item, index: index!);
  }
}

/// Quick Add Mode: Streamlined dialog for rapid fridge inventory entry.
/// Goal: Add item in <5 seconds with auto-detection of category and unit.
void _showQuickAddDialog() {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(text: '1');
  String? selectedUnit = 'pieces';
  String? detectedCategory = 'Other';

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          titlePadding: const EdgeInsets.only(top: 16, left: 24, right: 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Item',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Cancel',
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Item name field with auto-detection feedback
              TextField(
                controller: itemController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g., eggs, milk, spinach',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    detectedCategory = IngredientService.detectCategory(value);
                    selectedUnit = IngredientService.suggestUnit(value);
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Quantity and Unit row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Qty',
                        hintText: '1',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit ?? 'pieces',
                      items: IngredientService.getUnits()
                        .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        ))
                        .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedUnit = val ?? 'pieces';
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Category detection feedback
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      IngredientService.getCategoryEmoji(detectedCategory ?? 'Other'),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Category',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            detectedCategory ?? 'Other',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final name = itemController.text.trim();
                if (name.isNotEmpty) {
                  _addItem(
                    name,
                    quantityController.text.trim(),
                    category: detectedCategory ?? 'Other',
                    unit: selectedUnit ?? 'pieces',
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(
                'Add to ${detectedCategory ?? "Other"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Full Edit Mode: Complete dialog for editing existing items.
/// Shows all fields including optional expiry date.
void _showFullEditDialog({required Map<String, dynamic> item, required int index}) {
  final TextEditingController itemController = TextEditingController(text: item['name'] ?? '');
  final TextEditingController quantityController = TextEditingController(text: item['quantity']?.toString() ?? '');
  String? selectedUnit = item['unit'] ?? 'pieces';
  String? selectedCategory = item['category'] ?? 'Other';

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          titlePadding: const EdgeInsets.only(top: 16, left: 24, right: 8),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Item',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Cancel',
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: itemController,
                decoration: InputDecoration(
                  labelText: 'Fridge Item',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Qty',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: selectedUnit ?? 'pieces',
                      items: IngredientService.getUnits()
                        .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        ))
                        .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedUnit = val ?? 'pieces';
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory ?? 'Other',
                items: IngredientService.getCategories()
                  .map((cat) => DropdownMenuItem(
                    value: cat,
                    child: Text('${IngredientService.getCategoryEmoji(cat)} $cat'),
                  ))
                  .toList(),
                onChanged: (val) {
                  setState(() {
                    selectedCategory = val ?? 'Other';
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _deleteItem(index);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final name = itemController.text.trim();
                if (name.isNotEmpty) {
                  _editItem(
                    index,
                    name,
                    quantityController.text.trim(),
                    category: selectedCategory ?? 'Other',
                    unit: selectedUnit ?? 'pieces',
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    },
  );
}


  Future<void> _addItem(
    String name,
    String quantity, {
    String category = 'Other',
    String unit = 'pieces',
    DateTime? expiryDate,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      final newItem = {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category,
        'expiryDate': expiryDate?.toIso8601String(),
        'addedAt': DateTime.now().toIso8601String(),
      };
      
      setState(() {
        fridgeItems.add(newItem);
      });

      await _firestore.collection('users').doc(user.uid).update({
        'fridge': fridgeItems,
      });

      // Toast confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added $quantity $unit of $name to ${category}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editItem(
    int index,
    String name,
    String quantity, {
    String category = 'Other',
    String unit = 'pieces',
    DateTime? expiryDate,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        fridgeItems[index] = {
          'name': name,
          'quantity': quantity,
          'unit': unit,
          'category': category,
          'expiryDate': expiryDate?.toIso8601String(),
          'addedAt': fridgeItems[index]['addedAt'] ?? DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
      });
      await _firestore.collection('users').doc(user.uid).update({
        'fridge': fridgeItems,
      });

      // Toast confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Item updated',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(int index) async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        fridgeItems.removeAt(index);
      });
      await _firestore.collection('users').doc(user.uid).update({
        'fridge': fridgeItems,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
   
      body: fridgeItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.kitchen_outlined, size: 80, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Your fridge is empty!',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap + to add ingredients',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Category filter chips
                if (_categories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.filter_list,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Filter by Category',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              if (_selectedCategory != null)
                                Text(
                                  '${_filteredItems.length} of ${fridgeItems.length} items',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              // "All" chip
                              _buildCategoryChip(
                                label: 'All',
                                emoji: '📦',
                                count: fridgeItems.length,
                                isSelected: _selectedCategory == null,
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = null;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              // Category chips
                              ..._categories.map((category) {
                                final count = fridgeItems
                                    .where((item) =>
                                        (item['category'] ?? 'Other') == category)
                                    .length;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildCategoryChip(
                                    label: category,
                                    emoji: IngredientService.getCategoryEmoji(category),
                                    count: count,
                                    isSelected: _selectedCategory == category,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = category;
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Items list
                Expanded(
                  child: _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_alt_off,
                                size: 60,
                                color: AppColors.textSecondary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No items in $_selectedCategory',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            final actualIndex = fridgeItems.indexOf(item);
                final category = item['category'] ?? 'Other';
                final unit = item['unit'] ?? 'pieces';
                final emoji = IngredientService.getCategoryEmoji(category);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [AppColors.cardShadow],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    title: Text(
                      item['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${item['quantity']} $unit',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          category,
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                            trailing: const Icon(Icons.edit, color: AppColors.primary),
                            onTap: () =>
                                _showFridgeItemDialog(item: item, index: actualIndex),
                          ),
                        );
                      },
                    ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Scan barcode button
          FloatingActionButton.extended(
            onPressed: _scanBarcode,
            icon: const Icon(Icons.qr_code_2),
            label: const Text('Scan'),
            heroTag: 'scan_btn',
            backgroundColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          // Photo button - shows mode selection
          FloatingActionButton.extended(
            onPressed: _showPhotoModeDialog,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Photo'),
            heroTag: 'photo_btn',
            backgroundColor: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          // Quick add button
          FloatingActionButton.extended(
            onPressed: () => _showFridgeItemDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            heroTag: 'add_btn',
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  /// Build a category filter chip
  Widget _buildCategoryChip({
    required String label,
    required String emoji,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? AppColors.primaryGradient
              : LinearGradient(
                  colors: [
                    AppColors.surface,
                    AppColors.surface.withOpacity(0.95),
                  ],
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Scan barcode from camera using smart barcode system
  Future<void> _scanBarcode() async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            backgroundColor: AppColors.surface,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Scanning barcode...',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        );
      }

      // Scan barcode
      final barcode = await BarcodeService.scanBarcode();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (barcode != null && barcode.isNotEmpty) {
        // Show smart lookup loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              backgroundColor: AppColors.surface,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Looking up product...',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          );
        }

        // Use smart barcode lookup
        final productData = await SmartBarcodeService.smartLookup(barcode);

        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          if (productData != null) {
            // Show smart confirmation dialog
            _showSmartBarcodeConfirmation(barcode, productData);
          } else {
            // Fallback to manual entry with barcode
            _showManualEntryDialog(barcode: barcode);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Close any open dialogs
        Navigator.of(context, rootNavigator: true).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show smart barcode confirmation dialog with Firebase integration
  void _showSmartBarcodeConfirmation(String barcode, Map<String, dynamic> productData) {
    showDialog(
      context: context,
      builder: (context) => SmartBarcodeConfirmationDialog(
        barcode: barcode,
        productData: productData,
        onSaveToInventory: (confirmedData) async {
          // Save to user's fridge inventory
          await _addItemFromBarcode(confirmedData);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${confirmedData['name']} added to your fridge!'),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  /// Add item from smart barcode confirmation
  Future<void> _addItemFromBarcode(Map<String, dynamic> itemData) async {
    await _addItem(
      itemData['name'] ?? 'Unknown Product',
      itemData['quantity']?.toString() ?? '1',
      category: itemData['category'] ?? 'Other',
      unit: itemData['unit'] ?? 'pieces',
      expiryDate: itemData['expiryDate'] != null ? DateTime.parse(itemData['expiryDate']) : null,
    );
  }

  /// Show manual entry dialog for unknown barcodes
  void _showManualEntryDialog({String? barcode}) {
    final TextEditingController itemController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: '1');
    String selectedCategory = 'Other';
    String selectedUnit = 'pieces';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: AppColors.surface,
            titlePadding: const EdgeInsets.only(top: 16, left: 24, right: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      barcode != null ? 'Unknown Product' : 'Add Item',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (barcode != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_outlined, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Product not found',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Barcode: $barcode',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: itemController,
                  decoration: InputDecoration(
                    labelText: 'Product name',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: IngredientService.getCategories()
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Text(IngredientService.getCategoryEmoji(category)),
                                const SizedBox(width: 8),
                                Text(category),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedCategory = val ?? 'Other';
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        items: IngredientService.getUnits()
                            .map((unit) => DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedUnit = val ?? 'pieces';
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final name = itemController.text.trim();
                  if (name.isNotEmpty) {
                    _addItem(
                      name,
                      quantityController.text.trim(),
                      category: selectedCategory,
                      unit: selectedUnit,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Add Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show dialog with pre-filled barcode scan results
  void _showScannedProductDialog(Map<String, dynamic> product) {
    final TextEditingController itemController =
        TextEditingController(text: product['name'] ?? '');
    final TextEditingController quantityController =
        TextEditingController(text: '1');
    String? selectedUnit = product['unit'] ?? 'pieces';
    final String category = product['category'] ?? 'Other';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: AppColors.surface,
            titlePadding: const EdgeInsets.only(top: 16, left: 24, right: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.secondary),
                    const SizedBox(width: 8),
                    const Text(
                      'Scanned Product',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        IngredientService.getCategoryEmoji(category),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Category',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: itemController,
                  decoration: InputDecoration(
                    labelText: 'Product name',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qty',
                          labelStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit ?? 'pieces',
                        items: IngredientService.getUnits()
                          .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ))
                          .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedUnit = val ?? 'pieces';
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle:
                              const TextStyle(color: AppColors.textSecondary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: AppColors.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
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
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final name = itemController.text.trim();
                  if (name.isNotEmpty) {
                    _addItem(
                      name,
                      quantityController.text.trim(),
                      category: category,
                      unit: selectedUnit ?? 'pieces',
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Add Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Capture image from camera or gallery for OCR
  Future<void> _captureFromPhoto() async {
    try {
      // Pick image (ImagePicker will handle permission request automatically)
      // iOS will show native permission dialog on first use
      final imageFile = await OCRService.pickImage(source: ImageSource.camera);

      if (imageFile != null) {
        // Show loading for OCR processing
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Extract text from image
        final ocrText = await OCRService.extractText(imageFile);

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
        }

        if (ocrText.isNotEmpty) {
          // Parse ingredients from OCR text
          final ingredients = await OCRService.parseIngredients(ocrText);

          if (mounted && ingredients.isNotEmpty) {
            // Show review dialog
            showDialog(
              context: context,
              builder: (context) => OCRReviewDialog(
                detectedItems: ingredients,
                onCancel: () => Navigator.pop(context),
                onConfirm: (selectedItems) {
                  Navigator.pop(context);
                  _addMultipleItems(selectedItems);
                },
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No ingredients detected in image'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close any open dialogs
      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
      
      // Show error message with action to open settings if permission denied
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        final isPermissionError = errorMessage.contains('Settings');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: Duration(seconds: isPermissionError ? 6 : 3),
            action: isPermissionError
                ? SnackBarAction(
                    label: 'Open Settings',
                    onPressed: () async {
                      await openAppSettings();
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  /// Add multiple items at once (from OCR batch)
  Future<void> _addMultipleItems(
      List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;

    for (final item in items) {
      await _addItem(
        item['name'] ?? 'Unknown',
        item['quantity']?.toString() ?? '1',
        category: item['category'] ?? 'Other',
        unit: item['unit'] ?? 'pieces',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${items.length} items to fridge'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Show dialog to choose photo mode (text OCR or visual recognition)
  Future<void> _showPhotoModeDialog() async {
    final mode = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📸 Photo Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields, size: 40),
              title: const Text('Receipt/Text'),
              subtitle: const Text('Extract text from receipts or labels'),
              onTap: () => Navigator.pop(context, 'text'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.fastfood, size: 40),
              title: const Text('Visual Recognition'),
              subtitle: const Text('Identify food items by appearance (Free)'),
              onTap: () => Navigator.pop(context, 'visual'),
            ),
          ],
        ),
      ),
    );

    if (mode == 'text') {
      await _captureFromPhoto();
    } else if (mode == 'visual') {
      await _captureForVisualRecognition();
    }
  }

  /// Capture and recognize food items visually
  Future<void> _captureForVisualRecognition() async {
    try {
      // Check if user has premium access
      final canUse = await ImageRecognitionService.canUseImageRecognition();
      
      if (!canUse) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.stars, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text('Premium Feature'),
                ],
              ),
              content: const Text(
                'Image recognition is a premium feature. Upgrade to Premium or start your free trial to identify food items from photos.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/subscription');
                  },
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Pick image
      final imageFile = await OCRService.pickImage(source: ImageSource.camera);

      if (imageFile != null) {
        // Show loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('🧠 Analyzing image with Cloud Vision...'),
                ],
              ),
            ),
          );
        }

        // Recognize foods (always uses Cloud Vision API)
        final usePremiumMode = await ImageRecognitionService.isPremiumModeAvailable();
        final recognizedFoods = await ImageRecognitionService.recognizeFoods(
          imageFile: imageFile,
          usePremiumMode: usePremiumMode,
        );

        if (mounted) {
          Navigator.pop(context); // Close loading
        }

        if (recognizedFoods.isNotEmpty) {
          // Convert to format expected by OCR review dialog
          final items = recognizedFoods.map((food) {
            return {
              'name': food['name'],
              'quantity': '1',
              'unit': 'pieces',
              'category': 'Other',
              'confidence': food['confidence'],
            };
          }).toList();

          if (mounted) {
            // Show review dialog
            showDialog(
              context: context,
              builder: (context) => OCRReviewDialog(
                detectedItems: items,
                onCancel: () => Navigator.pop(context),
                onConfirm: (selectedItems) {
                  Navigator.pop(context);
                  _addMultipleItems(selectedItems);
                },
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No food items detected. Try a clearer photo or use Receipt/Text mode.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close any dialogs
      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

