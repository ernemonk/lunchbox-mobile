import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ingredient_service.dart';
import '../../services/smart_inventory_service.dart' show SmartMergeResult;

/// Dialog utilities for MyFridge page.
/// 
/// Contains:
/// - Quick add dialog
/// - Full edit dialog  
/// - Manual entry dialog
/// - Scanned product dialog
class MyFridgeDialogs {
  /// Quick Add Mode: Streamlined dialog for rapid fridge inventory entry.
  /// Goal: Add item in <5 seconds with auto-detection of category and unit.
  static void showQuickAddDialog({
    required BuildContext context,
    required Future<void> Function(String name, String quantity, {String category, String unit}) onAdd,
  }) {
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
                const Text(
                  'Add Item',
                  style: TextStyle(
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
                    onAdd(
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
  static void showFullEditDialog({
    required BuildContext context,
    required Map<String, dynamic> item,
    required int index,
    required Future<void> Function(int index, String name, String quantity, {String category, String unit}) onEdit,
    required Future<void> Function(int index) onDelete,
  }) {
    final TextEditingController itemController = TextEditingController(text: item['name'] ?? '');
    final TextEditingController quantityController = TextEditingController(text: item['quantity']?.toString() ?? '');
    String? selectedUnit = item['unit'] ?? 'pieces';
    String? selectedCategory = IngredientService.migrateCategory(item['category'] ?? 'Other');

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
                const Text(
                  'Edit Item',
                  style: TextStyle(
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
                  onDelete(index);
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
                    onEdit(
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

  /// Show manual entry dialog for unknown barcodes
  static void showManualEntryDialog({
    required BuildContext context,
    String? barcode,
    required Future<void> Function(String name, String quantity, {String category, String unit}) onAdd,
  }) {
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
                    onAdd(
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
  static void showScannedProductDialog({
    required BuildContext context,
    required Map<String, dynamic> product,
    required Future<void> Function(String name, String quantity, {String category, String unit}) onAdd,
  }) {
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
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text(
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
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (product['brand'] != null && product['brand'].toString().isNotEmpty ||
                    product['quantity'] != null && product['quantity'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text(
                              'Product Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (product['brand'] != null && product['brand'].toString().isNotEmpty)
                          Text(
                            'Brand: ${product['brand']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (product['quantity'] != null && product['quantity'].toString().isNotEmpty)
                          Text(
                            'Size: ${product['quantity']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
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
                      flex: 3,
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit ?? 'pieces',
                        isDense: true,
                        isExpanded: true,
                        items: IngredientService.getUnits()
                          .map((unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(
                              unit,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ))
                          .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedUnit = val ?? 'pieces';
                          });
                        },
                        selectedItemBuilder: (BuildContext context) {
                          return IngredientService.getUnits().map<Widget>((String unit) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                unit,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList();
                        },
                        decoration: InputDecoration(
                          labelText: 'Unit',
                          labelStyle:
                              const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
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
                    onAdd(
                      name,
                      quantityController.text.trim(),
                      category: category,
                      unit: selectedUnit ?? 'pieces',
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Add to Fridge',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show photo mode selection dialog
  static Future<String?> showPhotoModeDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📸 Photo Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields, size: 40),
              title: const Text('Local Receipt/Label Scanner'),
              subtitle: const Text('Free • Scan text from receipts & labels locally'),
              onTap: () => Navigator.pop(context, 'text'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.receipt_long, size: 40, color: AppColors.accent),
              title: const Text('Smart Receipt Scanner'),
              subtitle: const Text('Premium • AI extracts food items from receipts'),
              onTap: () => Navigator.pop(context, 'receipt'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.fastfood, size: 40, color: AppColors.accent),
              title: const Text('Visual Recognition'),
              subtitle: const Text('Premium • Identify food items by appearance'),
              onTap: () => Navigator.pop(context, 'visual'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show smart merge confirmation dialog
  static Future<bool?> showSmartMergeConfirmation(
    BuildContext context,
    SmartMergeResult mergeResult,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.accent, size: 28),
            SizedBox(width: 12),
            Text('Smart Merge', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mergeResult.itemsToAdd.isNotEmpty) ...[
                Text(
                  '🆕 New Items (${mergeResult.itemsToAdd.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...mergeResult.itemsToAdd.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 4),
                  child: Text(
                    '• ${item['name']} (${item['quantity']} ${item['unit']})',
                    style: const TextStyle(color: Colors.green),
                  ),
                )),
                const SizedBox(height: 16),
              ],
              if (mergeResult.itemsToUpdate.isNotEmpty) ...[
                Text(
                  '🔄 Quantity Updates (${mergeResult.itemsToUpdate.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...mergeResult.itemsToUpdate.map((update) {
                  final item = update['item'] as Map<String, dynamic>;
                  final addedCount = update['addedCount'] as int;
                  final originalQty = int.parse(item['quantity']) - addedCount;
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text(
                      '• ${item['name']}: $originalQty → ${item['quantity']} (+$addedCount)',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
