import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

Future<dynamic> generateRecipes({
  required String diet,
  required bool hasAllergies,
  required String allergies,
  required String additionalInstructions,
  required bool useOnlyFridgeItems,
  required String promptTitle,
}) async {
  const String apiUrl = 'https://generate-recipes-268643218431.us-central1.run.app';
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('[ERROR] No user logged in.');
    return {};
  }

  try {
    print('[INFO] Fetching user ingredients...');
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();
    if (userData == null) {
      print('[ERROR] No user data found in Firestore.');
      return {};
    }

    final ingredientsList = userData['ingredients'] as List<dynamic>? ?? [];
    print('[INFO] Retrieved ingredients: $ingredientsList');

    // Format ingredients
    String formattedIngredients = ingredientsList.map((item) {
      final ingredient = item['ingredient'] ?? '';
      final quantity = item['quantity'] ?? '';
      return '$quantity of $ingredient';
    }).join(', ');
    print('[INFO] Formatted ingredients: $formattedIngredients');

    // Fetch the prompt template
    print('[INFO] Fetching prompt with title: "$promptTitle"...');
    final promptQuery = await FirebaseFirestore.instance
        .collection('prompts')
        .where('promptTitle', isEqualTo: promptTitle)
        .limit(1)
        .get();

    if (promptQuery.docs.isEmpty) {
      print('[ERROR] Prompt not found for title: "$promptTitle"');
      return {};
    }

    String rawPrompt = promptQuery.docs.first['prompt'];
    print('[INFO] Raw prompt template: \n$rawPrompt');

    // Replace placeholders
    String finalPrompt = rawPrompt
        .replaceAll(r'$diet', diet)
        .replaceAll(r'$allergies', hasAllergies ? allergies : 'None')
        .replaceAll(r'$additionalInstructions', additionalInstructions)
        .replaceAll(r'$useOnlyFridgeItems', useOnlyFridgeItems ? 'Yes' : 'No')
        .replaceAll(r'$ingredients', formattedIngredients);

    print('[INFO] Final prompt after replacement: \n$finalPrompt');

    // Make the POST request
    print('[INFO] Sending request to API...');
    http.Response response = await http.post(
      Uri.parse(apiUrl),
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
