/// Voting State Manager
/// Handles all state and business logic for voting dialog
/// Keeps the widget code clean and testable

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/barcode_consensus_service.dart';
import '../../services/ingredient_service.dart';

class VotingState {
  final String barcode;
  final Map<String, dynamic> currentData;
  final VoidCallback onStateChanged;
  
  final BarcodeConsensusService _consensusService = BarcodeConsensusService();
  final ImagePicker _picker = ImagePicker();
  
  // Controllers
  late final TextEditingController nameController;
  late final TextEditingController brandController;
  
  // State
  List<Map<String, dynamic>> submissions = [];
  int? userVote;
  bool loading = true;
  bool isEditMode = false;
  bool isSubmitting = false;
  String selectedCategory = 'Other';
  String selectedUnit = 'pieces';
  File? uploadedImage;

  VotingState({
    required this.barcode,
    required this.currentData,
    required this.onStateChanged,
  }) {
    nameController = TextEditingController(text: currentData['name'] ?? '');
    brandController = TextEditingController(text: currentData['brand'] ?? '');
    selectedCategory = _normalizeCategory(currentData['category']);
    selectedUnit = _normalizeUnit(currentData['unit']);
  }

  void dispose() {
    nameController.dispose();
    brandController.dispose();
  }

  // === Category/Unit Normalization ===
  
  String _normalizeCategory(String? category) {
    if (category == null) return 'Other';
    final categories = IngredientService.getCategories();
    if (categories.contains(category)) return category;
    
    const categoryMap = {
      'Meat': 'Meat & Protein',
      'Protein': 'Meat & Protein',
      'Grains': 'Bread & Grains',
      'Bakery': 'Bread & Grains',
      'Bread': 'Bread & Grains',
    };
    return categoryMap[category] ?? 'Other';
  }

  String _normalizeUnit(String? unit) {
    if (unit == null) return 'pieces';
    final units = IngredientService.getUnits();
    if (units.contains(unit)) return unit;
    return 'pieces';
  }

  // === State Actions ===

  Future<void> loadSubmissions() async {
    print('[VOTING_STATE] Loading submissions for $barcode');
    loading = true;
    onStateChanged();

    try {
      submissions = await _consensusService.getSubmissions(barcode);
      userVote = await _consensusService.getUserVote(barcode);
      print('[VOTING_STATE] Loaded ${submissions.length} submissions, userVote: $userVote');
    } catch (e) {
      print('[VOTING_STATE] Error loading: $e');
      submissions = [];
      userVote = null;
    }

    loading = false;
    onStateChanged();
  }

  Future<void> vote(int index) async {
    print('[VOTING_STATE] Voting for index $index');
    await _consensusService.voteForSubmission(barcode, index);
    await loadSubmissions();
  }

  void enterEditMode() {
    print('[VOTING_STATE] Entering edit mode');
    isEditMode = true;
    nameController.text = currentData['name'] ?? '';
    brandController.text = currentData['brand'] ?? '';
    selectedCategory = _normalizeCategory(currentData['category']);
    selectedUnit = _normalizeUnit(currentData['unit']);
    uploadedImage = null;
    onStateChanged();
  }

  void exitEditMode() {
    print('[VOTING_STATE] Exiting edit mode');
    isEditMode = false;
    uploadedImage = null;
    onStateChanged();
  }

  void setCategory(String category) {
    selectedCategory = category;
    onStateChanged();
  }

  void setUnit(String unit) {
    selectedUnit = unit;
    onStateChanged();
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    
    if (image != null) {
      uploadedImage = File(image.path);
      onStateChanged();
    }
  }

  Future<void> submitEdit() async {
    if (isSubmitting) {
      print('[VOTING_STATE] Already submitting, ignoring');
      return;
    }

    print('[VOTING_STATE] ========== SUBMIT START ==========');
    print('[VOTING_STATE] Barcode: $barcode');
    print('[VOTING_STATE] Name: ${nameController.text.trim()}');
    print('[VOTING_STATE] Brand: ${brandController.text.trim()}');
    print('[VOTING_STATE] Category: $selectedCategory');
    print('[VOTING_STATE] Unit: $selectedUnit');

    isSubmitting = true;
    onStateChanged();

    try {
      final editedData = {
        'name': nameController.text.trim(),
        'brand': brandController.text.trim(),
        'category': selectedCategory,
        'unit': selectedUnit,
        'image_url': currentData['image_url'],
        'ingredients': currentData['ingredients'],
        'allergens': currentData['allergens'],
        'nutrition': currentData['nutrition'],
      };

      print('[VOTING_STATE] Calling consensus service...');
      await _consensusService.submitProductData(
        barcode,
        editedData,
        imageFile: uploadedImage,
      );
      print('[VOTING_STATE] ✅ Submission successful!');

      // Reset state on success
      isSubmitting = false;
      isEditMode = false;
      uploadedImage = null;
      onStateChanged();

      // Reload to show new submission
      await loadSubmissions();
      print('[VOTING_STATE] ========== SUBMIT COMPLETE ==========');
    } catch (e) {
      print('[VOTING_STATE] ❌ Submit error: $e');
      isSubmitting = false;
      onStateChanged();
      rethrow;
    }
  }
}
