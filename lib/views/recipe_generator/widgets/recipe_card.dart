import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final int index;
  final int totalRecipes;
  final VoidCallback onTap;
  final Function(bool) onFeedback;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.index,
    required this.totalRecipes,
    required this.onTap,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              AppColors.surface.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe['title'] ?? 'Untitled Recipe',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Tags row
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (recipe['cookingTime'] != null && recipe['cookingTime'].toString().isNotEmpty)
                              _buildTag(
                                icon: Icons.schedule_outlined,
                                label: recipe['cookingTime'].toString(),
                                color: AppColors.primary,
                              ),
                            if (recipe['difficulty'] != null && recipe['difficulty'].toString().isNotEmpty)
                              _buildTag(
                                icon: Icons.signal_cellular_alt,
                                label: recipe['difficulty'].toString(),
                                color: _getDifficultyColor(recipe['difficulty'].toString()),
                              ),
                            if (recipe['servings'] != null && recipe['servings'].toString().isNotEmpty)
                              _buildTag(
                                icon: Icons.restaurant_outlined,
                                label: recipe['servings'].toString(),
                                color: AppColors.secondary,
                              ),
                            if (recipe['cuisine'] != null && recipe['cuisine'].toString().isNotEmpty)
                              _buildTag(
                                icon: Icons.public_outlined,
                                label: recipe['cuisine'].toString(),
                                color: AppColors.accent,
                              ),
                          ],
                        ),
                        if (recipe['description'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            recipe['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary.withValues(alpha: 0.85),
                              height: 1.5,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Feedback buttons with better styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onFeedback(true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                Icons.thumb_up_outlined,
                                color: AppColors.success.withValues(alpha: 0.9),
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onFeedback(false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                Icons.thumb_down_outlined,
                                color: AppColors.error.withValues(alpha: 0.8),
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: color.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    final lower = difficulty.toLowerCase();
    if (lower.contains('easy') || lower.contains('simple') || lower.contains('beginner')) {
      return AppColors.success;
    } else if (lower.contains('hard') || lower.contains('advanced') || lower.contains('expert')) {
      return AppColors.error;
    } else if (lower.contains('medium') || lower.contains('intermediate') || lower.contains('moderate')) {
      return const Color(0xFFF59E0B); // Amber/Orange
    }
    return AppColors.secondary;
  }
}
