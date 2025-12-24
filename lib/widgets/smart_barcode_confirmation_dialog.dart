/// Smart Barcode Confirmation Dialog
/// Shows scanned product data and allows user to confirm/correct
/// Integrates with smart database system

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/smart_barcode_service.dart';
import '../services/ingredient_service.dart';

class SmartBarcodeConfirmationDialog extends StatefulWidget {
  final String barcode;
  final Map<String, dynamic> productData;
  final Function(Map<String, dynamic>) onSaveToInventory;
  final Function(String)? onError;

  const SmartBarcodeConfirmationDialog({
    super.key,
    required this.barcode,
    required this.productData,
    required this.onSaveToInventory,
    this.onError,
  });

  @override
  State<SmartBarcodeConfirmationDialog> createState() =>
      _SmartBarcodeConfirmationDialogState();
}

class _SmartBarcodeConfirmationDialogState
    extends State<SmartBarcodeConfirmationDialog> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  String _selectedCategory = 'Other';
  String _selectedUnit = 'pieces';
  DateTime? _expiryDate;
  bool _isCorrect = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productData['name'] ?? '');
    _quantityController = TextEditingController(text: '1');
    _selectedCategory = widget.productData['category'] ?? 'Other';
    _selectedUnit = widget.productData['unit'] ?? 'pieces';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with confidence indicator
            Row(
              children: [
                Icon(
                  (widget.productData['confidence'] ?? 0.0) < 0.8
                      ? Icons.help_outline
                      : Icons.verified,
                  color: (widget.productData['confidence'] ?? 0.0) < 0.8
                      ? Colors.orange
                      : Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scanned Product',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Confidence: ${((widget.productData['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}% '
                        '| Barcode: ${widget.barcode} '
                        '(${widget.productData['source'] ?? 'Smart DB'})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: (widget.productData['confidence'] ?? 0.0) < 0.8
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Product image (if available)
            if (widget.productData['imageUrl'] != null && widget.productData['imageUrl'].isNotEmpty) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.productData['imageUrl'],
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported, size: 80),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Confirmation question (for uncertain data)
            if ((widget.productData['confidence'] ?? 0.0) < 0.8) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Is this information correct?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _isCorrect,
                          onChanged: (value) => setState(() => _isCorrect = value!),
                        ),
                        const Text('Yes, it\'s correct'),
                        const SizedBox(width: 16),
                        Radio<bool>(
                          value: false,
                          groupValue: _isCorrect,
                          onChanged: (value) => setState(() => _isCorrect = value!),
                        ),
                        const Text('No, let me fix it'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Product name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Category and Unit
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: IngredientService.getCategories().map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value!);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: IngredientService.getUnits().map((unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedUnit = value!);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Quantity and Expiry
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _selectExpiryDate,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Expiry Date (optional)',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                _expiryDate?.toString().split(' ')[0] ?? 'Not set',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Additional product info (read-only)
                    if (widget.productData['brand'] != null && widget.productData['brand'].isNotEmpty) ...[
                      _buildInfoRow('Brand', widget.productData['brand']),
                      const SizedBox(height: 4),
                    ],
                    _buildInfoRow('Barcode', widget.barcode),

                    // Nutrition info (if available)
                    if (widget.productData['nutrition'] != null && widget.productData['nutrition'].isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Nutrition (per 100g):',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      ...widget.productData['nutrition'].entries
                          .where((entry) => entry.value != null)
                          .take(4)
                          .map((entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: _buildInfoRow(
                                  entry.key.replaceAll('_', ' ').toUpperCase(),
                                  '${entry.value}g',
                                ),
                              )),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _confirmAndAddToInventory,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Add to Fridge'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _expiryDate = date);
    }
  }

  Future<void> _confirmAndAddToInventory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a product name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Parse quantity
      final quantity = double.tryParse(_quantityController.text) ?? 1.0;

      // Prepare corrections if user made changes
      Map<String, dynamic>? corrections;
      if (!_isCorrect || 
          _nameController.text != widget.productData['name'] ||
          _selectedCategory != widget.productData['category'] ||
          _selectedUnit != widget.productData['unit']) {
        corrections = {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'unit': _selectedUnit,
        };
      }

      // Confirm and save to Firebase
      final success = await SmartBarcodeService.confirmAndSaveBarcodeData(
        barcode: widget.barcode,
        isCorrect: _isCorrect,
        corrections: corrections,
        customName: _nameController.text.trim(),
        customCategory: _selectedCategory,
        customUnit: _selectedUnit,
        quantity: quantity,
        expiryDate: _expiryDate,
      );

      if (success) {
        // Call the callback to save to inventory
        widget.onSaveToInventory({
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'unit': _selectedUnit,
          'quantity': quantity,
          'barcode': widget.barcode,
          'expiryDate': _expiryDate?.toIso8601String(),
          'added_by_scan': true,
        });

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          widget.onError?.call('Failed to save product data');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}