import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../core/theme/app_colors.dart';
import '../services/recipe_service.dart';
import '../services/subscription_service.dart';
import '../services/recipe_log_service.dart';
import 'recipe.dart';
import 'subscription_page.dart';

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
      if (!Hive.isBoxOpen('recipes')) {
        await Hive.openBox('recipes');
      }
      print('[HIVE] Initialized successfully');
    } catch (e) {
      print('[HIVE] Initialization failed: $e');
    }
  }

  Future<void> _loadSavedRecipes() async {
    try {
      if (!Hive.isBoxOpen('recipes')) {
        print('[CACHE] Hive box not yet open, skipping Hive cache');
        throw Exception('Box not open');
      }
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
      if (Hive.isBoxOpen('recipes')) {
        final box = Hive.box('recipes');
        await box.put('cachedRecipes', recipes);
        print('[CACHE] Saved ${recipes.length} recipes to Hive');
      }
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
                    const Text('Select Your Diet:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedDiet,
                      onChanged: (String? newValue) {
                        setModalState(() => selectedDiet = newValue);
                      },
                      items: dietOptions
                          .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Do you have any allergies?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio(
                          value: true,
                          groupValue: hasAllergies,
                          onChanged: (val) => setModalState(() => hasAllergies = true),
                        ),
                        const Text('Yes'),
                        Radio(
                          value: false,
                          groupValue: hasAllergies,
                          onChanged: (val) => setModalState(() => hasAllergies = false),
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
                    const Text('Additional Instructions:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    const Text('Use only my fridge items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Radio(
                          value: true,
                          groupValue: useOnlyFridgeItems,
                          onChanged: (val) => setModalState(() => useOnlyFridgeItems = true),
                        ),
                        const Text('Yes'),
                        Radio(
                          value: false,
                          groupValue: useOnlyFridgeItems,
                          onChanged: (val) => setModalState(() => useOnlyFridgeItems = false),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
              generatedRecipes = [{'text': parsed.toString()}];
            }
          } catch (_) {
            generatedRecipes = [{'text': result}];
          }
        } else {
          generatedRecipes = [{'text': 'Unexpected result format'}];
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
          errorMessage = 'Connection issue. Retrying in ${delay.inSeconds}s... (Attempt $retryCount/$maxRetries)';
        });
        await Future.delayed(delay);
        await _attemptGeneration();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to generate recipes after $maxRetries attempts. Please check your connection and try again.';
        });
      }
    }
  }

      // Save recipes locally
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('savedRecipes', jsonEncode(generatedRecipes));
    } catch (e, stacktrace) {
      print('Error: $e\n$stacktrace');
      setState(() {
        generatedRecipes = [{'text': 'Error generating recipes.'}];
        isLoading = false;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: ElevatedButton(
                onPressed: isLoading ? null : _openPreferencesSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text('Set Preferences'),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading) const BouncingImageOverlay(),
            if (!isLoading && generatedRecipes.isNotEmpty) ...[
              const Text('Generated Recipes:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: generatedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = generatedRecipes[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RecipeViewerPage(recipe: recipe)),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.restaurant_menu, color: Colors.indigo, size: 32),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe['title'] ?? 'Untitled',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: -8,
                                        children: (recipe['ingredients'] as List? ?? [])
                                            .map<Widget>((ingredient) => Chip(
                                                  label: Text(
                                                    ingredient,
                                                    style: const TextStyle(fontSize: 12, color: Colors.white),
                                                  ),
                                                  backgroundColor: Colors.indigo.shade300,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ))
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            if (!isLoading && generatedRecipes.isEmpty)
              const Text('No recipes generated yet.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
