import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Service class for generating AI-powered recipes.
/// 
/// This service communicates with a Cloud Run endpoint to generate
/// personalized recipes based on user preferences and fridge contents.
class RecipeService {
  /// The API endpoint for recipe generation
  static const String _apiUrl =
      'https://generate-recipes-268643218431.us-central1.run.app';
  
  /// The streaming API endpoint for recipe generation (same endpoint, stream param controls mode)
  static const String _streamingApiUrl =
      'https://generate-recipes-268643218431.us-central1.run.app';

  /// Fetches user data and prompt template in parallel.
  /// 
  /// Returns a record containing the formatted ingredients and raw prompt,
  /// or null values if the data couldn't be fetched.
  static Future<({String? ingredients, String? prompt})> _fetchDataParallel({
    required String userId,
    required String promptTitle,
  }) async {
    print('[INFO] Fetching user data and prompt template in parallel...');
    
    // Execute both Firestore queries in parallel
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('users').doc(userId).get(),
      FirebaseFirestore.instance
          .collection('prompts')
          .where('promptTitle', isEqualTo: promptTitle)
          .limit(1)
          .get(),
    ]);

    final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final promptQuery = results[1] as QuerySnapshot<Map<String, dynamic>>;

    // Process user data
    final userData = userDoc.data();
    if (userData == null) {
      print('[ERROR] No user data found in Firestore.');
      return (ingredients: null, prompt: null);
    }

    final ingredientsList = userData['fridge'] as List<dynamic>? ?? [];
    print('[INFO] Retrieved ingredients: $ingredientsList');
    String formattedIngredients = ingredientsList.toString();

    // Process prompt data
    if (promptQuery.docs.isEmpty) {
      print('[ERROR] Prompt not found for title: "$promptTitle"');
      return (ingredients: formattedIngredients, prompt: null);
    }

    String rawPrompt = promptQuery.docs.first['prompt'];
    print('[INFO] Data fetched successfully in parallel');

    return (ingredients: formattedIngredients, prompt: rawPrompt);
  }

  /// Builds the final prompt by replacing placeholders.
  static String _buildPrompt({
    required String rawPrompt,
    required String diet,
    required int recipeCount,
    required bool hasAllergies,
    required String allergies,
    required String additionalInstructions,
    required bool useOnlyFridgeItems,
    required String formattedIngredients,
  }) {
    return rawPrompt
        .replaceAll(r'$diet', diet)
        .replaceAll(r'$recipeCount', recipeCount.toString())
        .replaceAll(r'$allergies', hasAllergies ? allergies : 'None')
        .replaceAll(r'$additionalInstructions', additionalInstructions)
        .replaceAll(r'$useOnlyFridgeItems', useOnlyFridgeItems ? 'Yes' : 'No')
        .replaceAll(r'$ingredients', formattedIngredients);
  }

  /// Generates recipes based on user preferences using streaming.
  /// 
  /// This method streams partial results as they arrive from the API,
  /// providing a faster perceived response time.
  /// 
  /// Parameters:
  /// - [diet]: The user's diet type (e.g., 'Keto', 'Vegan')
  /// - [recipeCount]: Number of recipes to generate
  /// - [hasAllergies]: Whether the user has any allergies
  /// - [allergies]: List of allergies (if any)
  /// - [additionalInstructions]: Custom instructions for recipe generation
  /// - [useOnlyFridgeItems]: Whether to use only ingredients from the fridge
  /// - [promptTitle]: The title of the prompt template to use
  /// - [onPartialResult]: Callback for partial streaming results
  /// 
  /// Returns a Stream of recipe chunks as they arrive.
  static Stream<String> generateRecipesStream({
    required String diet,
    required int recipeCount,
    required bool hasAllergies,
    required String allergies,
    required String additionalInstructions,
    required bool useOnlyFridgeItems,
    required String promptTitle,
  }) async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[ERROR] No user logged in.');
      yield '';
      return;
    }

    try {
      // Fetch data in parallel
      final data = await _fetchDataParallel(
        userId: user.uid,
        promptTitle: promptTitle,
      );

      if (data.ingredients == null || data.prompt == null) {
        yield '';
        return;
      }

      // Build final prompt
      final finalPrompt = _buildPrompt(
        rawPrompt: data.prompt!,
        diet: diet,
        recipeCount: recipeCount,
        hasAllergies: hasAllergies,
        allergies: allergies,
        additionalInstructions: additionalInstructions,
        useOnlyFridgeItems: useOnlyFridgeItems,
        formattedIngredients: data.ingredients!,
      );

      print('[INFO] Sending streaming request to API...');
      
      // Create streaming request
      final request = http.Request('POST', Uri.parse(_streamingApiUrl));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'prompt': finalPrompt, 'stream': true});

      final client = http.Client();
      try {
        final streamedResponse = await client.send(request);
        
        if (streamedResponse.statusCode == 200) {
          await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
            yield chunk;
          }
        } else {
          print('[ERROR] Streaming API request failed with status ${streamedResponse.statusCode}');
          // Fall back to non-streaming
          final fallbackResult = await generateRecipes(
            diet: diet,
            recipeCount: recipeCount,
            hasAllergies: hasAllergies,
            allergies: allergies,
            additionalInstructions: additionalInstructions,
            useOnlyFridgeItems: useOnlyFridgeItems,
            promptTitle: promptTitle,
          );
          yield jsonEncode(fallbackResult);
        }
      } finally {
        client.close();
      }
    } catch (e, stack) {
      print('[EXCEPTION] $e');
      print('[STACKTRACE] $stack');
      yield '';
    }
  }

  /// Generates recipes based on user preferences.
  /// 
  /// Parameters:
  /// - [diet]: The user's diet type (e.g., 'Keto', 'Vegan')
  /// - [recipeCount]: Number of recipes to generate
  /// - [hasAllergies]: Whether the user has any allergies
  /// - [allergies]: List of allergies (if any)
  /// - [additionalInstructions]: Custom instructions for recipe generation
  /// - [useOnlyFridgeItems]: Whether to use only ingredients from the fridge
  /// - [promptTitle]: The title of the prompt template to use
  /// 
  /// Returns a dynamic result containing the generated recipes.
  static Future<dynamic> generateRecipes({
    required String diet,
    required int recipeCount,
    required bool hasAllergies,
    required String allergies,
    required String additionalInstructions,
    required bool useOnlyFridgeItems,
    required String promptTitle,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[ERROR] No user logged in.');
      return {};
    }

    try {
      // Fetch data in parallel (user data + prompt template)
      final data = await _fetchDataParallel(
        userId: user.uid,
        promptTitle: promptTitle,
      );

      if (data.ingredients == null || data.prompt == null) {
        return {};
      }

      print('[INFO] Raw prompt template: \n${data.prompt}');

      // Build final prompt
      String finalPrompt = _buildPrompt(
        rawPrompt: data.prompt!,
        diet: diet,
        recipeCount: recipeCount,
        hasAllergies: hasAllergies,
        allergies: allergies,
        additionalInstructions: additionalInstructions,
        useOnlyFridgeItems: useOnlyFridgeItems,
        formattedIngredients: data.ingredients!,
      );

      print('[INFO] Final prompt after replacement: \n$finalPrompt');

      // Make the POST request to the API
      print('[INFO] Sending request to API...');
      http.Response response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': finalPrompt}),
      );

      print('[INFO] API Response Status: ${response.statusCode}');
      print('[INFO] API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final result = decoded['response'];
        print('[SUCCESS] Generated recipes: $result');
        return result;
      } else {
        print('[ERROR] API request failed with status ${response.statusCode}');
        return {};
      }
    } catch (e, stack) {
      print('[EXCEPTION] $e');
      print('[STACKTRACE] $stack');
      return {};
    }
  }
}

/// Convenience function to generate recipes.
/// 
/// This is a wrapper around [RecipeService.generateRecipes] for backward
/// compatibility with existing code.
Future<dynamic> generateRecipes({
  required String diet,
  required int recipeCount,
  required bool hasAllergies,
  required String allergies,
  required String additionalInstructions,
  required bool useOnlyFridgeItems,
  required String promptTitle,
}) {
  return RecipeService.generateRecipes(
    diet: diet,
    recipeCount: recipeCount,
    hasAllergies: hasAllergies,
    allergies: allergies,
    additionalInstructions: additionalInstructions,
    useOnlyFridgeItems: useOnlyFridgeItems,
    promptTitle: promptTitle,
  );
}

/// Convenience function to generate recipes with streaming.
/// 
/// This is a wrapper around [RecipeService.generateRecipesStream] for
/// backward compatibility with existing code.
Stream<String> generateRecipesStream({
  required String diet,
  required int recipeCount,
  required bool hasAllergies,
  required String allergies,
  required String additionalInstructions,
  required bool useOnlyFridgeItems,
  required String promptTitle,
}) {
  return RecipeService.generateRecipesStream(
    diet: diet,
    recipeCount: recipeCount,
    hasAllergies: hasAllergies,
    allergies: allergies,
    additionalInstructions: additionalInstructions,
    useOnlyFridgeItems: useOnlyFridgeItems,
    promptTitle: promptTitle,
  );
}
