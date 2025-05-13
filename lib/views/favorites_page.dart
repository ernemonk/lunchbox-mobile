import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe.dart'; // Your viewer page

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late StreamSubscription<QuerySnapshot> _subscription;
  List<Map<String, dynamic>> userRecipes = [];

  @override
  void initState() {
    super.initState();
    _listenToUserRecipes();
  }

  void _listenToUserRecipes() {
    final user = _auth.currentUser;
    if (user != null) {
      _subscription = FirebaseFirestore.instance
          .collection('recipes')
          .where('user', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          userRecipes = snapshot.docs
              .map((doc) => {
                    ...doc.data() as Map<String, dynamic>,
                    'uid': doc.id,
                  })
              .toList();
        });
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userRecipes.isEmpty
          ? const Center(
              child: Text(
                'You haven’t added any recipes yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: userRecipes.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final recipe = userRecipes[index];
                final title = recipe['title'] ?? 'Untitled';

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeViewerPage(
                          recipe: recipe,
                          fromFavoritesPage: true,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.indigo.shade50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tap to view details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
