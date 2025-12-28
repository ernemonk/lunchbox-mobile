import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ingredient_service.dart';

/// UI Widgets for MyFridge page.
/// 
/// Contains:
/// - Category filter chips
/// - Fridge item cards
/// - Empty state widgets
class MyFridgeWidgets {
  /// Build empty fridge state
  static Widget buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
    );
  }

  /// Build empty filtered state
  static Widget buildEmptyFilteredState(String? category) {
    return Center(
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
            'No items in $category',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Build category filter section
  static Widget buildCategoryFilter({
    required List<String> categories,
    required String? selectedCategory,
    required List<Map<String, dynamic>> fridgeItems,
    required List<Map<String, dynamic>> filteredItems,
    required void Function(String?) onCategorySelected,
  }) {
    return Container(
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
                const Text(
                  'Filter by Category',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (selectedCategory != null)
                  Text(
                    '${filteredItems.length} of ${fridgeItems.length} items',
                    style: const TextStyle(
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
                  emoji: '🍽️',
                  count: fridgeItems.length,
                  isSelected: selectedCategory == null,
                  onTap: () => onCategorySelected(null),
                ),
                const SizedBox(width: 8),
                // Category chips
                ...categories.map((category) {
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
                      isSelected: selectedCategory == category,
                      onTap: () => onCategorySelected(category),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a category filter chip
  static Widget _buildCategoryChip({
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

  /// Build fridge item card
  static Widget buildFridgeItemCard({
    required Map<String, dynamic> item,
    required int index,
    required VoidCallback onTap,
  }) {
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
        onTap: onTap,
      ),
    );
  }

  /// Build FAB column
  static Widget buildFABColumn({
    required VoidCallback onScan,
    required VoidCallback onPhoto,
    required VoidCallback onAdd,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Scan barcode button
        FloatingActionButton.extended(
          onPressed: onScan,
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Scan'),
          heroTag: 'scan_btn',
          backgroundColor: AppColors.primary,
        ),
        const SizedBox(height: 12),
        // Photo button - shows mode selection
        FloatingActionButton.extended(
          onPressed: onPhoto,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Photo'),
          heroTag: 'photo_btn',
          backgroundColor: AppColors.secondary,
        ),
        const SizedBox(height: 12),
        // Quick add button
        FloatingActionButton.extended(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          heroTag: 'add_btn',
          backgroundColor: AppColors.primary,
        ),
      ],
    );
  }
}
