import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';
import '../services/recipe_service.dart';
import 'recipe.dart';

class UserPreferencesPage extends StatefulWidget {
  const UserPreferencesPage({super.key});

  @override
  State<UserPreferencesPage> createState() => _UserPreferencesPageState();
}

class _UserPreferencesPageState extends State<UserPreferencesPage> {
  String? selectedDiet = 'Any';
  int recipeCount = 5;
  bool hasAllergies = false;
  bool useOnlyFridgeItems = false;
  TextEditingController allergiesController = TextEditingController();
  TextEditingController instructionsController = TextEditingController();

  final List<String> dietOptions = [
    'Any',
    'Keto',
    'Carnivore',
    'Vegetarian',
    'Vegan',
    'Pescetarian',
    'Raw Vegan',
    'Ayurvedic'
  ];
  final List<int> recipeCountOptions = [3, 5, 10, 15];

  List<Map<String, dynamic>> generatedRecipes = [];
  bool isLoading = false;
  String streamingText = '';
  String? errorMessage;
  int retryCount = 0;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initHive();
    await _loadSavedRecipes();
    await _loadPreferences();
  }

  Future<void> _initHive() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox('recipes');
      print('[HIVE] Initialized successfully');
    } catch (e) {
      print('[HIVE] Initialization failed: $e');
    }
  }

  Future<void> _loadSavedRecipes() async {
    try {
      final box = Hive.box('recipes');
      final cachedRecipes = box.get('cachedRecipes');
      if (cachedRecipes != null && cachedRecipes is List) {
        setState(() {
          generatedRecipes = cachedRecipes.cast<Map<String, dynamic>>();
        });
        print('[CACHE] Loaded ${generatedRecipes.length} recipes from Hive');
        return;
      }
    } catch (e) {
      print('[CACHE] Hive load failed: $e, falling back to SharedPreferences');
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('savedRecipes');
    if (saved != null) {
      try {
        final List decoded = jsonDecode(saved);
        setState(() {
          generatedRecipes = decoded.cast<Map<String, dynamic>>();
        });
      } catch (e) {
        print("Failed to decode saved recipes: $e");
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedDiet = prefs.getString('selectedDiet') ?? 'Any';
      hasAllergies = prefs.getBool('hasAllergies') ?? false;
      useOnlyFridgeItems = prefs.getBool('useOnlyFridgeItems') ?? false;
      allergiesController.text = prefs.getString('allergies') ?? '';
      instructionsController.text = prefs.getString('instructions') ?? '';
    });
  }

  Future<void> _saveRecipes(List<Map<String, dynamic>> recipes) async {
    try {
      final box = Hive.box('recipes');
      await box.put('cachedRecipes', recipes);
      print('[CACHE] Saved ${recipes.length} recipes to Hive');
    } catch (e) {
      print('[CACHE] Hive save failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedRecipes', jsonEncode(recipes));
  }

  void _openPreferencesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text('Select Your Diet:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedDiet,
                      onChanged: (String? newValue) {
                        setModalState(() => selectedDiet = newValue);
                      },
                      items: dietOptions
                          .map((value) => DropdownMenuItem(
                              value: value, child: Text(value)))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Do you have any allergies?',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio(
                          value: true,
                          groupValue: hasAllergies,
                          onChanged: (val) =>
                              setModalState(() => hasAllergies = true),
                        ),
                        const Text('Yes'),
                        Radio(
                          value: false,
                          groupValue: hasAllergies,
                          onChanged: (val) =>
                              setModalState(() => hasAllergies = false),
                        ),
                        const Text('No'),
                      ],
                    ),
                    if (hasAllergies)
                      TextField(
                        controller: allergiesController,
                        decoration: const InputDecoration(
                          hintText: 'Enter allergies (e.g., nuts, gluten)',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      ),
                    const SizedBox(height: 20),
                    const Text('Additional Instructions:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    TextField(
                      controller: instructionsController,
                      decoration: const InputDecoration(
                        hintText: 'Enter any other instructions here',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Use only my fridge items:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio(
                          value: true,
                          groupValue: useOnlyFridgeItems,
                          onChanged: (val) =>
                              setModalState(() => useOnlyFridgeItems = true),
                        ),
                        const Text('Yes'),
                        Radio(
                          value: false,
                          groupValue: useOnlyFridgeItems,
                          onChanged: (val) =>
                              setModalState(() => useOnlyFridgeItems = false),
                        ),
                        const Text('No'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _generateRecipes();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Generate Recipes'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generateRecipes() async {
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      generatedRecipes = [];
      errorMessage = null;
      retryCount = 0;
    });

    await _attemptGeneration();
  }

  Future<void> _generateQuickMeal(String mealType, String diet) async {
    setState(() {
      selectedDiet = diet;
      instructionsController.text = 'Quick $mealType meal';
    });
    await _generateRecipes();
  }

  Future<void> _attemptGeneration() async {
    String diet = selectedDiet ?? 'Any';
    String allergies = hasAllergies ? allergiesController.text : 'None';
    String instructions = instructionsController.text;

    print('[RECIPE_UI] ════════════════════════════════════════════════════════');
    print('[RECIPE_UI] 🚀 Starting recipe generation...');
    print('[RECIPE_UI]    • Diet: $diet');
    print('[RECIPE_UI]    • Recipe Count: $recipeCount');
    print('[RECIPE_UI]    • Has Allergies: $hasAllergies → "$allergies"');
    print('[RECIPE_UI]    • Instructions: "$instructions"');
    print('[RECIPE_UI]    • Use Only Fridge Items: $useOnlyFridgeItems');
    if (useOnlyFridgeItems) {
      print('[RECIPE_UI]    🔒 STRICT MODE - Only using ingredients from user\'s fridge');
    } else {
      print('[RECIPE_UI]    🔓 FLEXIBLE MODE - AI can suggest any ingredients');
    }
    print('[RECIPE_UI] ════════════════════════════════════════════════════════');

    try {
      final result = await generateRecipes(
        promptTitle: "New",
        diet: diet,
        recipeCount: recipeCount,
        hasAllergies: hasAllergies,
        allergies: allergies,
        additionalInstructions: instructions,
        useOnlyFridgeItems: useOnlyFridgeItems,
      );

      setState(() {
        if (result is List) {
          generatedRecipes = result.map<Map<String, dynamic>>((item) {
            if (item is Map<String, dynamic>) return item;
            if (item is String) {
              try {
                return Map<String, dynamic>.from(jsonDecode(item));
              } catch (_) {
                return {'text': item};
              }
            }
            return {'text': item.toString()};
          }).toList();
        } else if (result is String) {
          try {
            final parsed = jsonDecode(result);
            if (parsed is List) {
              generatedRecipes = parsed.map<Map<String, dynamic>>((item) {
                if (item is Map<String, dynamic>) return item;
                return {'text': item.toString()};
              }).toList();
            } else if (parsed is Map) {
              generatedRecipes = [Map<String, dynamic>.from(parsed)];
            } else {
              generatedRecipes = [
                {'text': parsed.toString()}
              ];
            }
          } catch (_) {
            generatedRecipes = [
              {'text': result}
            ];
          }
        } else {
          generatedRecipes = [
            {'text': 'Unexpected result format'}
          ];
        }
        isLoading = false;
        errorMessage = null;
        retryCount = 0;
      });

      await _saveRecipes(generatedRecipes);
    } catch (e) {
      print('[ERROR] Recipe generation failed: $e');
      if (retryCount < maxRetries) {
        retryCount++;
        final delay = Duration(seconds: retryCount * 2);
        setState(() {
          errorMessage =
              'Connection issue. Retrying in ${delay.inSeconds}s... (Attempt $retryCount/$maxRetries)';
        });
        await Future.delayed(delay);
        await _attemptGeneration();
      } else {
        setState(() {
          isLoading = false;
          errorMessage =
              'Failed to generate recipes after $maxRetries attempts. Please check your connection and try again.';
        });
      }
    }
  }

  String _getSuggestedMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Breakfast';
    if (hour < 15) return 'Lunch';
    if (hour < 20) return 'Dinner';
    return 'Snack';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Quick Meal Buttons
                  if (!isLoading &&
                      generatedRecipes.isEmpty &&
                      errorMessage == null) ...[
                    const Text(
                      'Quick Meal Ideas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickMealButton(
                            icon: Icons.wb_sunny_outlined,
                            label: '🍳 ${_getSuggestedMealType()}',
                            onTap: () => _generateQuickMeal(
                                _getSuggestedMealType(), selectedDiet ?? 'Any'),
                            isPrimary: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickMealButton(
                            icon: Icons.kitchen,
                            label: '🧊 Use Fridge',
                            onTap: () {
                              setState(() => useOnlyFridgeItems = true);
                              _generateRecipes();
                            },
                            isPrimary: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickMealButton(
                            icon: Icons.flash_on,
                            label: '⚡ Surprise Me',
                            onTap: () => _generateRecipes(),
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickMealButton(
                            icon: Icons.tune,
                            label: '⚙️ Customize',
                            onTap: _openPreferencesSheet,
                            isPrimary: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Shimmer loading state
                  if (isLoading) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      height: constraints.maxHeight * 0.7,
                      child: ListView.builder(
                        itemCount: 3,
                        itemBuilder: (context, index) => _buildShimmerCard(),
                      ),
                    ),
                  ],
                  // Error state
                  if (!isLoading && errorMessage != null) ...[
                    SizedBox(
                      height: constraints.maxHeight * 0.6,
                      child: _buildErrorState(),
                    ),
                  ],
                  // Recipe cards with PageView
                  if (!isLoading &&
                      errorMessage == null &&
                      generatedRecipes.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Recipes',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${generatedRecipes.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: constraints.maxHeight * 0.65,
                      child: PageView.builder(
                        itemCount: generatedRecipes.length,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (context, index) {
                          final recipe = generatedRecipes[index];
                          return _buildRecipeCard(recipe, index);
                        },
                      ),
                    ),
                  ],
                  // Empty state
                  if (!isLoading &&
                      errorMessage == null &&
                      generatedRecipes.isEmpty) ...[
                    const Spacer(),
                    _buildEmptyState(),
                    const Spacer(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickMealButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPrimary ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary
              ? null
              : Border.all(
                  color: AppColors.primary.withOpacity(0.3), width: 1.5),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            errorMessage ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                errorMessage = null;
                retryCount = 0;
              });
              _generateRecipes();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Map<String, dynamic> recipe, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeViewerPage(recipe: recipe)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              AppColors.primaryLight.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recipe['title'] ?? 'Untitled Recipe',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.thumb_up_outlined,
                                color: AppColors.success),
                            onPressed: () => _submitFeedback(recipe, true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.thumb_down_outlined,
                                color: AppColors.error),
                            onPressed: () => _submitFeedback(recipe, false),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (recipe['description'] != null)
                    Text(
                      recipe['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            if (index < generatedRecipes.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary.withOpacity(0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Swipe for next recipe',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryLight.withOpacity(0.15),
                AppColors.accentLight.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 72,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Your Personal Chef Awaits',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Get personalized recipes based on your diet, allergies, and what\'s in your fridge',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback(
      Map<String, dynamic> recipe, bool isPositive) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('recipe_feedback').add({
        'userId': user.uid,
        'recipeTitle': recipe['title'],
        'isPositive': isPositive,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPositive ? '👍 Thanks for the feedback!' : '👎 We\'ll do better!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('[FEEDBACK] Error: $e');
    }
  }
}
