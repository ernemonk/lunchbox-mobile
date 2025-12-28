/// Voting Edit Form Widget
/// Form for editing/submitting product information

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ingredient_service.dart';
import 'voting_state.dart';

class VotingEditForm extends StatelessWidget {
  final VotingState state;
  final VoidCallback onSubmit;

  const VotingEditForm({
    super.key,
    required this.state,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final categories = IngredientService.getCategories();
    final units = IngredientService.getUnits();

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            _buildImageSection(),
            const SizedBox(height: 16),

            // Product name
            TextFormField(
              controller: state.nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name*',
                prefixIcon: Icon(Icons.shopping_bag),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Brand
            TextFormField(
              controller: state.brandController,
              decoration: const InputDecoration(
                labelText: 'Brand (optional)',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Category and Unit dropdowns
            Row(
              children: [
                Expanded(
                  child: _buildCategoryDropdown(categories),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUnitDropdown(units),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: state.pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: _buildImageContent(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: state.pickImage,
            icon: const Icon(Icons.add_photo_alternate, size: 18),
            label: Text(
              state.uploadedImage != null || state.currentData['image_url'] != null
                  ? 'Change Image'
                  : 'Add Image',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (state.uploadedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(state.uploadedImage!, fit: BoxFit.cover),
      );
    } else if (state.currentData['image_url'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          state.currentData['image_url'],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.image,
            size: 48,
            color: AppColors.textSecondary,
          ),
        ),
      );
    } else {
      return const Icon(
        Icons.image,
        size: 48,
        color: AppColors.textSecondary,
      );
    }
  }

  Widget _buildCategoryDropdown(List<String> categories) {
    return DropdownButtonFormField<String>(
      value: state.selectedCategory,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: categories.map((cat) {
        return DropdownMenuItem(value: cat, child: Text(cat));
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return categories.map<Widget>((String category) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              category,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (value) {
        if (value != null) state.setCategory(value);
      },
    );
  }

  Widget _buildUnitDropdown(List<String> units) {
    return DropdownButtonFormField<String>(
      value: state.selectedUnit,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Unit',
        border: OutlineInputBorder(),
      ),
      items: units.map((unit) {
        return DropdownMenuItem(value: unit, child: Text(unit));
      }).toList(),
      selectedItemBuilder: (BuildContext context) {
        return units.map<Widget>((String unit) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              unit,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        }).toList();
      },
      onChanged: (value) {
        if (value != null) state.setUnit(value);
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: state.isSubmitting ? null : onSubmit,
        icon: state.isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check),
        label: Text(state.isSubmitting ? 'Submitting...' : 'Submit My Version'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
