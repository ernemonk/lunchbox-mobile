import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Recipe viewer page for displaying recipe details.
/// 
/// Shows:
/// - Recipe title
/// - Ingredients list
/// - Step-by-step instructions
/// 
/// Allows users to save recipes to favorites or remove them.
class RecipeViewerPage extends StatefulWidget {
  /// The recipe data to display
  final Map<String, dynamic> recipe;
  
  /// Whether this page was opened from the favorites page
  final bool fromFavoritesPage;

  const RecipeViewerPage({
    super.key,
    required this.recipe,
    this.fromFavoritesPage = false,
  });

  @override
  State<RecipeViewerPage> createState() => _RecipeViewerPageState();
}

class _RecipeViewerPageState extends State<RecipeViewerPage> {
  bool _isSaved = false;

  Future<void> saveRecipeToFirestore(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      final collection = FirebaseFirestore.instance.collection('recipes');
      final newDoc = collection.doc();

      final recipeWithIDs = {
        ...widget.recipe,
        'uid': newDoc.id,
        'user': user.uid,
        'createdAt': Timestamp.now(),
        'generationId': widget.recipe['generationId'], // Link to generation
      };

      await newDoc.set(recipeWithIDs);

      // Phase 1: Track favorite interaction for AI learning
      try {
        await FirebaseFirestore.instance
          .collection('user_analytics')
          .doc(user.uid)
          .collection('interactions')
          .add({
            'recipeId': newDoc.id,
            'recipeTitle': widget.recipe['title'] ?? 'Untitled',
            'action': 'favorited',
            'timestamp': FieldValue.serverTimestamp(),
            'cuisine': widget.recipe['cuisine'] ?? 'Unknown',
            'difficulty': widget.recipe['difficulty'] ?? 'Unknown',
            'cookingTime': widget.recipe['cookingTime'] ?? 'Unknown',
            'servings': widget.recipe['servings'] ?? 'Unknown',
            'generationId': widget.recipe['generationId'], // Link to generation
          });
        print('[ANALYTICS] Tracked favorite interaction');
      } catch (e) {
        print('[ANALYTICS] Failed to track interaction: $e');
        // Don't block user experience if analytics fail
      }

      setState(() {
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving recipe: $e')),
      );
    }
  }
Future<void> removeRecipeFromFavorites(BuildContext context, String recipeId) async {
  Navigator.pop(context);
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    final docRef = FirebaseFirestore.instance.collection('recipes').doc(recipeId);

    final docSnapshot = await docRef.get();
    if (docSnapshot.exists && docSnapshot.data()?['user'] == user.uid) {
      final recipeData = docSnapshot.data();
      await docRef.delete();

      // Phase 1: Track removal interaction
      try {
        await FirebaseFirestore.instance
          .collection('user_analytics')
          .doc(user.uid)
          .collection('interactions')
          .add({
            'recipeId': recipeId,
            'recipeTitle': recipeData?['title'] ?? 'Untitled',
            'action': 'removed',
            'timestamp': FieldValue.serverTimestamp(),
            'cuisine': recipeData?['cuisine'] ?? 'Unknown',
            'difficulty': recipeData?['difficulty'] ?? 'Unknown',
          });
        print('[ANALYTICS] Tracked removal interaction');
      } catch (e) {
        print('[ANALYTICS] Failed to track removal: $e');
      }

      setState(() {
        _isSaved = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe removed from favorites.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe not found or not owned by user.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error removing recipe: $e')),
    );
  }
}

 @override
Widget build(BuildContext context) {
  final title = widget.recipe['title'] ?? 'Untitled';
  final ingredients = widget.recipe['ingredients'] as List<dynamic>? ?? [];
  final instructions = widget.recipe['instructions'] as List<dynamic>? ?? [];
  final cookingTime = widget.recipe['cookingTime'] ?? '';
  final difficulty = widget.recipe['difficulty'] ?? '';
  final servings = widget.recipe['servings'] ?? '';
  final cuisine = widget.recipe['cuisine'] ?? '';
    final macros = widget.recipe['macros'] as List<dynamic>? ?? [];
    final recipeId = widget.recipe['uid'] as String?;
    final isFavoriteMode = widget.fromFavoritesPage;
    final actionLabel = isFavoriteMode
      ? 'Remove from favorites'
      : (_isSaved ? 'Saved in collection' : 'Save to collection');
    final actionIcon = isFavoriteMode
      ? Icons.favorite
      : (_isSaved
          ? Icons.favorite
          : Icons.favorite_border);
    final actionGradient = isFavoriteMode
      ? const LinearGradient(
        colors: [AppColors.error, Color(0xFFFF5B5B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      )
      : AppColors.primaryGradient;
    final actionCallback = isFavoriteMode
      ? (recipeId != null
        ? () => removeRecipeFromFavorites(context, recipeId)
        : null)
      : (_isSaved ? null : () => saveRecipeToFirestore(context));

  return Scaffold(
    backgroundColor: AppColors.background,
    body: CustomScrollView(
      slivers: [
        // Floating App Bar - Minimal, iOS-style
        SliverAppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          floating: true,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Save row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 0),
                    Expanded(
                      flex: 1,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: widget.fromFavoritesPage
                            ? _TrashButton(
                                recipeId: recipeId,
                                onRemove: () => removeRecipeFromFavorites(
                                    context, recipeId ?? ''),
                              )
                            : _HeartButton(
                                isSaved: _isSaved,
                                onTap: actionCallback,
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Metadata Row - Quick glance info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (cookingTime.isNotEmpty)
                        _MetadataItem(
                          icon: Icons.schedule_rounded,
                          label: cookingTime,
                          sublabel: 'Time',
                        ),
                      if (difficulty.isNotEmpty)
                        _MetadataItem(
                          icon: Icons.signal_cellular_alt_rounded,
                          label: difficulty,
                          sublabel: 'Level',
                        ),
                      if (servings.isNotEmpty)
                        _MetadataItem(
                          icon: Icons.restaurant_rounded,
                          label: servings,
                          sublabel: 'Servings',
                        ),
                      if (cuisine.isNotEmpty)
                        _MetadataItem(
                          icon: Icons.language_rounded,
                          label: cuisine,
                          sublabel: 'Cuisine',
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Ingredients Section
                _SectionHeader(title: 'Ingredients', count: ingredients.length),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: ingredients.asMap().entries.map((entry) {
                      final isLast = entry.key == ingredients.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.accent,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    entry.value.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLast)
                            Divider(
                              color: AppColors.textLight.withOpacity(0.2),
                              height: 1,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 36),

                // Instructions Section
                _SectionHeader(title: 'Instructions', count: instructions.length),
                const SizedBox(height: 16),
                ...instructions.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.accent,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.6,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Nutrition Section
                if (macros.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(title: 'Nutrition', count: null),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: macros.map((macro) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.secondary.withOpacity(0.1),
                                AppColors.secondary.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            macro.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

}

// Section header with count badge
class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Metadata item for the info card
class _MetadataItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;

  const _MetadataItem({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _HeartButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback? onTap;

  const _HeartButton({
    required this.isSaved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isSaved
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          isSaved ? Icons.favorite : Icons.favorite_border,
          size: 28,
          color: isSaved ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _TrashButton extends StatelessWidget {
  final String? recipeId;
  final VoidCallback onRemove;

  const _TrashButton({
    required this.recipeId,
    required this.onRemove,
  });

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Remove from favorites?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This recipe will be removed from your collection.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onRemove();
            },
            child: const Text(
              'Remove',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showConfirmationDialog(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          size: 28,
          color: AppColors.error,
        ),
      ),
    );
  }
}


class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double? width;

  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return Opacity(
      opacity: isDisabled ? 0.65 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 0),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 0),
            child: width != null
                ? SizedBox(
                    width: width,
                    child: _buildButtonContainer(padding, gradient),
                  )
                : _buildButtonContainer(padding, gradient),
          ),
        ),
      ),
    );
  }

    Widget _buildButtonContainer(
        EdgeInsetsGeometry padding, Gradient gradient) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
}
