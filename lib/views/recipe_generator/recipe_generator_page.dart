import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../services/recipe_service.dart';
import '../recipe.dart';
import 'widgets/quick_meal_button.dart';
import 'widgets/shimmer_card.dart';
import 'widgets/error_state.dart';
import 'widgets/recipe_card.dart';
import 'widgets/empty_state.dart';

class RecipeGeneratorPage extends StatefulWidget {
  const RecipeGeneratorPage({super.key});

  @override
  State<RecipeGeneratorPage> createState() => _RecipeGeneratorPageState();
}

class _RecipeGeneratorPageState extends State<RecipeGeneratorPage> {
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

  List<Map<String, dynamic>> generatedRecipes = [];
  bool isLoading = false;
  String? errorMessage;
  int retryCount = 0;
  static const int maxRetries = 3;
  String? selectedQuickMeal;

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
      debugPrint('[HIVE] Initialized successfully');
    } catch (e) {
      debugPrint('[HIVE] Initialization failed: $e');
    }
  }

  Future<void> _loadSavedRecipes() async {
    try {
      final box = Hive.box('recipes');
      final cachedRecipes = box.get('cachedRecipes');
      if (cachedRecipes != null && cachedRecipes is List) {
        setState(() {
          generatedRecipes = cachedRecipes
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
        });
        debugPrint('[CACHE] Loaded ${generatedRecipes.length} recipes from Hive');
        return;
      }
    } catch (e) {
      debugPrint('[CACHE] Hive load failed: $e, falling back to SharedPreferences');
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
        debugPrint("Failed to decode saved recipes: $e");
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
      debugPrint('[CACHE] Saved ${recipes.length} recipes to Hive');
    } catch (e) {
      debugPrint('[CACHE] Hive save failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedRecipes', jsonEncode(recipes));
  }

  void _openPreferencesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: AppColors.background,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const Text(
                              '⚙️ Customize Your Recipes',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Personalize your meal preferences',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Diet Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Dietary Preference',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: selectedDiet,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                                  onChanged: (String? newValue) {
                                    setModalState(() => selectedDiet = newValue);
                                  },
                                  items: dietOptions
                                      .map((value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value, style: const TextStyle(fontSize: 15))))
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Allergies Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Allergies',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setModalState(() => hasAllergies = false),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !hasAllergies ? AppColors.primary : Colors.transparent,
                                          border: Border.all(
                                            color: !hasAllergies ? AppColors.primary : AppColors.textLight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'No',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: !hasAllergies ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setModalState(() => hasAllergies = true),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: hasAllergies ? AppColors.primary : Colors.transparent,
                                          border: Border.all(
                                            color: hasAllergies ? AppColors.primary : AppColors.textLight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Yes',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: hasAllergies ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (hasAllergies) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: allergiesController,
                                  decoration: InputDecoration(
                                    hintText: 'e.g., nuts, gluten, dairy',
                                    hintStyle: TextStyle(color: AppColors.textLight),
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Fridge Items Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.info.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.kitchen, color: AppColors.info, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Fridge Items Only',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setModalState(() => useOnlyFridgeItems = false),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !useOnlyFridgeItems ? AppColors.primary : Colors.transparent,
                                          border: Border.all(
                                            color: !useOnlyFridgeItems ? AppColors.primary : AppColors.textLight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'No',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: !useOnlyFridgeItems ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => setModalState(() => useOnlyFridgeItems = true),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: useOnlyFridgeItems ? AppColors.primary : Colors.transparent,
                                          border: Border.all(
                                            color: useOnlyFridgeItems ? AppColors.primary : AppColors.textLight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Yes',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: useOnlyFridgeItems ? Colors.white : AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Additional Instructions Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.edit_note, color: AppColors.secondary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Special Instructions',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: instructionsController,
                                decoration: InputDecoration(
                                  hintText: 'e.g., low sodium, kid-friendly, under 30 minutes',
                                  hintStyle: TextStyle(color: AppColors.textLight),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                maxLines: 3,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Generate Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                Navigator.pop(context);
                                await _generateRecipes();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      'Generate Recipes',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
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
    String instruction;
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        instruction = 'Quick breakfast meal. Make it energizing and perfect for starting the day. Think fresh, light, and nutritious!';
        break;
      case 'lunch':
        instruction = 'Quick lunch meal. Make it satisfying and balanced for midday energy. Keep it flavorful and filling!';
        break;
      case 'dinner':
        instruction = 'Quick dinner meal. Make it comforting and delicious for the evening. Think hearty, warm, and satisfying!';
        break;
      case 'snack':
        instruction = 'Quick snack. Make it tasty, easy to grab, and perfect for a quick bite. Be creative with fun flavors!';
        break;
      default:
        instruction = 'Quick $mealType meal';
    }
    
    setState(() {
      selectedDiet = diet;
      instructionsController.text = instruction;
      useOnlyFridgeItems = false; // Reset fridge setting
    });
    await _generateRecipes();
  }

  Future<void> _generateFridgeMeal() async {
    setState(() {
      useOnlyFridgeItems = true;
      instructionsController.text = 'Use only ingredients from my fridge. Be creative and go all out with unique combinations and flavor pairings!';
    });
    await _generateRecipes();
  }

  Future<void> _generateSurpriseMeal() async {
    setState(() {
      useOnlyFridgeItems = false;
      instructionsController.text = 'Surprise me! Be absolutely creative and go wild with any cuisine, ingredients, or flavor combinations. Think outside the box!';
    });
    await _generateRecipes();
  }

  Future<void> _attemptGeneration() async {
    String diet = selectedDiet ?? 'Any';
    String allergies = hasAllergies ? allergiesController.text : 'None';
    String instructions = instructionsController.text;

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
      debugPrint('[ERROR] Recipe generation failed: $e');
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPositive ? '👍 Thanks for the feedback!' : '👎 We\'ll do better!',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('[FEEDBACK] Error: $e');
    }
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
                  const SizedBox(height: 16),
                  // Quick Meal Buttons - Always visible
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
                        child: QuickMealButton(
                          icon: Icons.wb_sunny_outlined,
                          label: _getSuggestedMealType(),
                          onTap: () {
                            setState(() => selectedQuickMeal = _getSuggestedMealType());
                            _generateQuickMeal(
                                _getSuggestedMealType(), selectedDiet ?? 'Any');
                          },
                          isPrimary: selectedQuickMeal == _getSuggestedMealType(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickMealButton(
                          icon: Icons.kitchen_outlined,
                          label: 'Use Fridge',
                          onTap: () {
                            setState(() => selectedQuickMeal = 'fridge');
                            _generateFridgeMeal();
                          },
                          isPrimary: selectedQuickMeal == 'fridge',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: QuickMealButton(
                          icon: Icons.auto_awesome_outlined,
                          label: 'Surprise Me',
                            onTap: () {
                              setState(() => selectedQuickMeal = 'surprise');
                              _generateSurpriseMeal();
                            },
                            isPrimary: selectedQuickMeal == 'surprise',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickMealButton(
                          icon: Icons.tune,
                          label: 'Customize',
                            onTap: () {
                              setState(() => selectedQuickMeal = 'customize');
                              _openPreferencesSheet();
                            },
                            isPrimary: selectedQuickMeal == 'customize',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Shimmer loading state
                  if (isLoading)
                    Expanded(
                      child: ListView.builder(
                        itemCount: 3,
                        itemBuilder: (context, index) => const ShimmerCard(),
                      ),
                    ),
                  // Error state
                  if (!isLoading && errorMessage != null)
                    Expanded(
                      child: ErrorState(
                        errorMessage: errorMessage,
                        onRetry: () {
                          setState(() {
                            errorMessage = null;
                            retryCount = 0;
                          });
                          _generateRecipes();
                        },
                      ),
                    ),
                  // Recipe cards list
                  if (!isLoading &&
                      errorMessage == null &&
                      generatedRecipes.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Recipes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${generatedRecipes.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: generatedRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = generatedRecipes[index];
                          return RecipeCard(
                            recipe: recipe,
                            index: index,
                            totalRecipes: generatedRecipes.length,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        RecipeViewerPage(recipe: recipe)),
                              );
                            },
                            onFeedback: (isPositive) =>
                                _submitFeedback(recipe, isPositive),
                          );
                        },
                      ),
                    ),
                  ],
                  // Empty state
                  if (!isLoading &&
                      errorMessage == null &&
                      generatedRecipes.isEmpty)
                    const Expanded(
                      child: Center(
                        child: EmptyState(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
