import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/ingredient_service.dart';
import '../../core/theme/app_colors.dart';

/// Mixin providing fridge state management functionality.
/// 
/// Handles:
/// - Firebase data fetching and syncing
/// - CRUD operations for fridge items
/// - Category filtering
mixin MyFridgeStateMixin<T extends StatefulWidget> on State<T> {
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  List<Map<String, dynamic>> fridgeItems = [];
  String? selectedCategory; // null = All

  /// Get unique categories from fridge items
  List<String> get categories {
    final cats = fridgeItems
        .map((item) => item['category'] as String? ?? 'Other')
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }

  /// Get filtered items based on selected category
  List<Map<String, dynamic>> get filteredItems {
    if (selectedCategory == null) return fridgeItems;
    return fridgeItems
        .where((item) => (item['category'] ?? 'Other') == selectedCategory)
        .toList();
  }

  /// Fetch fridge contents from Firestore
  Future<void> fetchFridgeContents() async {
    final user = auth.currentUser;
    if (user != null) {
      final doc = await firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['fridge'] != null) {
        setState(() {
          fridgeItems = List<Map<String, dynamic>>.from(data['fridge']).map((item) {
            // Migrate old category names to new ones
            if (item['category'] != null) {
              item['category'] = IngredientService.migrateCategory(item['category']);
            }
            return item;
          }).toList();
        });
      }
    }
  }

  /// Add a new item to the fridge
  Future<void> addItem(
    String name,
    String quantity, {
    String category = 'Other',
    String unit = 'pieces',
    DateTime? expiryDate,
  }) async {
    final user = auth.currentUser;
    if (user != null) {
      final newItem = {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'category': category,
        'expiryDate': expiryDate?.toIso8601String(),
        'addedAt': DateTime.now().toIso8601String(),
      };
      
      setState(() {
        fridgeItems.add(newItem);
      });

      await firestore.collection('users').doc(user.uid).update({
        'fridge': fridgeItems,
      });

      // Toast confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added $quantity $unit of $name to $category',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Edit an existing item
  Future<void> editItem(
    int index,
    String name,
    String quantity, {
    String category = 'Other',
    String unit = 'pieces',
    DateTime? expiryDate,
  }) async {
    final user = auth.currentUser;
    if (user != null) {
      setState(() {
        fridgeItems[index] = {
          'name': name,
          'quantity': quantity,
          'unit': unit,
          'category': category,
          'expiryDate': expiryDate?.toIso8601String(),
          'addedAt': fridgeItems[index]['addedAt'] ?? DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };
      });
      await firestore.collection('users').doc(user.uid).update({
        'fridge': fridgeItems,
      });

      // Toast confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Item updated',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  /// Delete an item
  Future<void> deleteItem(int index) async {
    final user = auth.currentUser;
    if (user != null) {
      setState(() {
        fridgeItems.removeAt(index);
      });
      await firestore.collection('users').doc(user.uid).update({
        'fridge': fridgeItems,
      });
    }
  }

  /// Add item from barcode scan data
  Future<void> addItemFromBarcode(Map<String, dynamic> itemData) async {
    await addItem(
      itemData['name'] ?? 'Unknown Product',
      itemData['quantity']?.toString() ?? '1',
      category: itemData['category'] ?? 'Other',
      unit: itemData['unit'] ?? 'pieces',
      expiryDate: itemData['expiryDate'] != null ? DateTime.parse(itemData['expiryDate']) : null,
    );
  }

  /// Set the selected category filter
  void setSelectedCategory(String? category) {
    setState(() {
      selectedCategory = category;
    });
  }
}
