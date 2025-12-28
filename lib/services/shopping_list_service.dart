import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for managing shopping list items in Firestore.
///
/// Stores shopping list items per user in: `users/{uid}/shoppingList/{itemId}`
class ShoppingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the current user's shopping list collection reference
  CollectionReference? _getShoppingListCollection() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid).collection('shoppingList');
  }

  /// Add a new item to the shopping list
  Future<void> addItem({
    required String name,
    String? quantity,
    bool checked = false,
  }) async {
    final collection = _getShoppingListCollection();
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    await collection.add({
      'name': name,
      'quantity': quantity ?? '',
      'checked': checked,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add multiple items from a recipe's ingredients
  Future<void> addItemsFromRecipe({
    required List<String> ingredients,
    required List<String> fridgeItems,
  }) async {
    final collection = _getShoppingListCollection();
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    // Filter out ingredients that are already in the fridge
    final missingIngredients = ingredients.where((ingredient) {
      return !fridgeItems.any((fridgeItem) =>
          fridgeItem.toLowerCase().contains(ingredient.toLowerCase()) ||
          ingredient.toLowerCase().contains(fridgeItem.toLowerCase()));
    }).toList();

    // Add each missing ingredient to the shopping list
    final batch = _firestore.batch();
    for (final ingredient in missingIngredients) {
      final docRef = collection.doc();
      batch.set(docRef, {
        'name': ingredient,
        'quantity': '',
        'checked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Toggle the checked status of an item
  Future<void> toggleItemChecked(String itemId, bool checked) async {
    final collection = _getShoppingListCollection();
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    await collection.doc(itemId).update({'checked': checked});
  }

  /// Update an item's details
  Future<void> updateItem({
    required String itemId,
    String? name,
    String? quantity,
  }) async {
    final collection = _getShoppingListCollection();
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (quantity != null) updates['quantity'] = quantity;

    if (updates.isNotEmpty) {
      await collection.doc(itemId).update(updates);
    }
  }

  /// Delete an item from the shopping list
  Future<void> deleteItem(String itemId) async {
    final collection = _getShoppingListCollection();
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    await collection.doc(itemId).delete();
  }

  /// Delete all checked items
  Future<void> deleteCheckedItems() async {
    final collection = _getShoppingListCollection();
    if (collection == null) {
      throw Exception('User not authenticated');
    }

    final snapshot = await collection.where('checked', isEqualTo: true).get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Stream of shopping list items
  Stream<List<Map<String, dynamic>>> getShoppingListStream() {
    final collection = _getShoppingListCollection();
    if (collection == null) {
      return Stream.value([]);
    }

    return collection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get the user's fridge items for comparison
  Future<List<String>> getFridgeItems() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return [];

    final fridge = data['fridge'] as List<dynamic>? ?? [];
    return fridge.map((item) {
      if (item is Map<String, dynamic>) {
        return item['name']?.toString() ?? '';
      }
      return item.toString();
    }).toList();
  }
}
