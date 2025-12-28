/// Product Edit Dialog
/// Allows users to edit product information before submitting to consensus system

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/ingredient_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProductEditDialog extends StatefulWidget {
  final String barcode;
  final Map<String, dynamic> initialData;

  const ProductEditDialog({
    super.key,
    required this.barcode,
    required this.initialData,
  });

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  String _selectedCategory = 'Other';
  String _selectedUnit = 'pieces';
  File? _uploadedImage;
  final ImagePicker _picker = ImagePicker();

  // Safe getters to ensure dropdown values are always valid
  String get _safeCategory => IngredientService.getCategories().contains(_selectedCategory) 
      ? _selectedCategory 
      : 'Other';
  String get _safeUnit => IngredientService.getUnits().contains(_selectedUnit) 
      ? _selectedUnit 
      : 'pieces';

  // Normalize category names to match IngredientService.getCategories()
  String _normalizeCategory(String category) {
    final validCategories = IngredientService.getCategories();
    if (validCategories.contains(category)) return category;
    
    // Map common variants to standard categories
    const categoryMap = {
      'Meat': 'Meat & Protein',
      'Protein': 'Meat & Protein',
      'Grains': 'Bread & Grains',
      'Bakery': 'Bread & Grains',
      'Bread': 'Bread & Grains',
      'Canned': 'Other',
      'Frozen': 'Other',
      'Spices': 'Other',
    };
    
    return categoryMap[category] ?? 'Other';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['name'] ?? '');
    _brandController = TextEditingController(text: widget.initialData['brand'] ?? '');
    _selectedCategory = _normalizeCategory(widget.initialData['category'] ?? 'Other');
    _selectedUnit = widget.initialData['unit'] ?? 'pieces';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _uploadedImage = File(image.path);
      });
    }
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a product name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final editedData = {
      'name': _nameController.text.trim(),
      'brand': _brandController.text.trim(),
      'category': _selectedCategory,
      'unit': _selectedUnit,
      'image_url': widget.initialData['image_url'],
      'ingredients': widget.initialData['ingredients'],
      'allergens': widget.initialData['allergens'],
      'nutrition': widget.initialData['nutrition'],
    };

    Navigator.pop(context, {
      'data': editedData,
      'image': _uploadedImage,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Edit Product Info',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Barcode: ${widget.barcode}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    Center(
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _pickImage,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                ),
                              ),
                              child: _uploadedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _uploadedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : widget.initialData['image_url'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            widget.initialData['image_url'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.image, size: 40),
                                          ),
                                        )
                                      : const Icon(Icons.image, size: 40),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.add_photo_alternate, size: 16),
                            label: Text(
                              _uploadedImage != null ? 'Change Image' : 'Add Image',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2, size: 20),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),

                    // Brand
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business, size: 20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category and Unit
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _safeCategory,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: IngredientService.getCategories().map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(
                                  category,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            selectedItemBuilder: (BuildContext context) {
                              return IngredientService.getCategories().map<Widget>((String category) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    category,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList();
                            },
                            onChanged: (value) {
                              setState(() => _selectedCategory = value!);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _safeUnit,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.scale, size: 20),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: IngredientService.getUnits().map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(
                                  unit,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
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
                            onChanged: (value) {
                              setState(() => _selectedUnit = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
