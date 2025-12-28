/// OCR Review Dialog Widget
/// Displays detected ingredients from receipt/ingredient photo
/// Allows user to select/deselect items before adding to fridge

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/ingredient_service.dart';

class OCRReviewDialog extends StatefulWidget {
  final List<Map<String, dynamic>> detectedItems;
  final VoidCallback onCancel;
  final Function(List<Map<String, dynamic>>) onConfirm;

  const OCRReviewDialog({
    super.key,
    required this.detectedItems,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<OCRReviewDialog> createState() => _OCRReviewDialogState();
}

class _OCRReviewDialogState extends State<OCRReviewDialog> {
  late List<Map<String, dynamic>> items;
  late Map<int, bool> selectedItems;

  @override
  void initState() {
    super.initState();
    // Enrich detected items with categories
    items = widget.detectedItems.map((item) {
      if (!item.containsKey('category') || item['category'] == null) {
        item['category'] =
            IngredientService.detectCategory(item['name'] ?? '');
      }
      if (!item.containsKey('unit') || item['unit'].isEmpty) {
        item['unit'] =
            IngredientService.suggestUnit(item['name'] ?? '');
      }
      return item;
    }).toList();

    // All items unselected by default (user chooses what to add)
    selectedItems = {for (int i = 0; i < items.length; i++) i: false};
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        selectedItems.values.where((v) => v == true).length;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.only(top: 16, left: 24, right: 8),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detected Ingredients',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${items.length} items found ($selectedCount selected)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            onPressed: widget.onCancel,
            tooltip: 'Cancel',
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No ingredients detected',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final category = item['category'] ?? 'Other';
                  final emoji =
                      IngredientService.getCategoryEmoji(category);
                  final isSelected = selectedItems[index] ?? true;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.05)
                          : AppColors.textSecondary.withOpacity(0.05),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.3)
                            : AppColors.textSecondary.withOpacity(0.2),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          selectedItems[index] = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      title: Row(
                        children: [
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? 'Unknown Item',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.secondary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if ((item['quantity'] as String?)?.isNotEmpty ??
                                        false)
                                      Text(
                                        '${item['quantity']} ${item['unit'] ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
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
          onPressed: selectedCount == 0
              ? null
              : () {
                  // Get selected items
                  final selected = <Map<String, dynamic>>[];
                  for (int i = 0; i < items.length; i++) {
                    if (selectedItems[i] == true) {
                      selected.add(items[i]);
                    }
                  }
                  widget.onConfirm(selected);
                },
          child: Text(
            'Add $selectedCount item${selectedCount == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
