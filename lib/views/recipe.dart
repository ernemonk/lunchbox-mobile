import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RecipeViewerPage extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final bool fromFavoritesPage;

  const RecipeViewerPage({
    super.key,
    required this.recipe,
    this.fromFavoritesPage = false, // default is false
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
      };

      await newDoc.set(recipeWithIDs);

      setState(() {
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved to Firestore!')),
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
      await docRef.delete();

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

  return Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // Custom Title and Back Button
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    size: 32.0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Save to Favorites Section (conditionally hidden)
            if (!widget.fromFavoritesPage)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Love this recipe?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: _isSaved
                          ? const Text(
                              '⭐ Added to Favorites',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.star, color: Colors.white),
                              label: const Text(
                                'Add to Favorites',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              onPressed: () => saveRecipeToFirestore(context),
                            ),
                    ),
                  ],
                ),
              ),
if (widget.fromFavoritesPage)
        Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  children: [
                   
                    Center(
                      child: _isSaved
                          ? const Text(
                              '⭐ Added to Favorites',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            )
                          : ElevatedButton.icon(
                              icon: const Icon(Icons.star, color: Colors.white),
                              label: const Text(
                                'Remove from Favorites',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[800],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                textStyle: const TextStyle(fontSize: 16),
                              ),
                              onPressed: () => removeRecipeFromFavorites(context,widget.recipe['uid']),
                            ),
                    ),
                  ],
                ),
              ),
            const Text(
              'Ingredients:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...ingredients.map((item) => Text('• $item')).toList(),

            const SizedBox(height: 20),

            const Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ...instructions.asMap().entries.map((entry) {
              return Text('${entry.key + 1}. ${entry.value}');
            }).toList(),
          ],
        ),
      ),
    ),
  );
}

}
