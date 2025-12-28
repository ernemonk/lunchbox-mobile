/// Smart Barcode Confirmation Dialog
/// Shows scanned product data and allows user to confirm/correct
/// Integrates with smart database system

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/theme/app_colors.dart';
import '../services/smart_barcode_service.dart';
import '../services/barcode_cache_service.dart';
import '../services/barcode_consensus_service.dart';
import '../services/ingredient_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SmartBarcodeConfirmationDialog extends StatefulWidget {
  final String barcode;
  final Map<String, dynamic> productData;
  final Function(Map<String, dynamic>) onSaveToInventory;
  final Function(String)? onError;

  const SmartBarcodeConfirmationDialog({
    super.key,
    required this.barcode,
    required this.productData,
    required this.onSaveToInventory,
    this.onError,
  });

  @override
  State<SmartBarcodeConfirmationDialog> createState() =>
      _SmartBarcodeConfirmationDialogState();
}

class _SmartBarcodeConfirmationDialogState
    extends State<SmartBarcodeConfirmationDialog> {
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _quantityController;
  late ScrollController _scrollController;
  final GlobalKey _editFieldsKey = GlobalKey();
  final GlobalKey _versionsKey = GlobalKey();
  String _selectedCategory = 'Other';
  String _selectedUnit = 'pieces';
  DateTime? _expiryDate;
  bool _isCorrect = true;
  bool _isSaving = false;
  bool _showEditFields = false;
  bool _isSubmitting = false;
  bool _showVersions = false;
  bool _isLoadingVersions = false;
  bool _isVoting = false;
  List<Map<String, dynamic>> _versions = [];
  int? _userVoteIndex;
  File? _uploadedImage;
  final BarcodeCacheService _cacheService = BarcodeCacheService();
  final BarcodeConsensusService _consensusService = BarcodeConsensusService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _nameController = TextEditingController(text: widget.productData['name'] ?? '');
    _brandController = TextEditingController(text: widget.productData['brand'] ?? '');
    _quantityController = TextEditingController(text: '1');
    _loadVersions(); // Load versions on init
    
    // Normalize category to match dropdown options
    final rawCategory = widget.productData['category'] ?? 'Other';
    _selectedCategory = _normalizeCategory(rawCategory);
    _selectedUnit = widget.productData['unit'] ?? 'pieces';
  }
  
  // Normalize category names to match IngredientService.getCategories()
  String _normalizeCategory(String category) {
    final validCategories = IngredientService.getCategories();
    if (validCategories.contains(category)) return category;
    
    // Map common variants to standard categories
    const categoryMap = {
      'Meat': 'Meat & Protein',
      'Protein': 'Meat & Protein',
      'Grains': 'Bread & Grains',
      'Bakery': 'Bread & Grains',
      'Bread': 'Bread & Grains',
      'Canned': 'Other',
      'Frozen': 'Other',
      'Spices': 'Other',
    };
    
    return categoryMap[category] ?? 'Other';
  }
  
  // Use IngredientService categories for consistency
  List<String> get _validCategories => IngredientService.getCategories();
  List<String> get _validUnits => IngredientService.getUnits();
  
  // Ensure category is always valid for dropdown
  String get _safeCategory => _validCategories.contains(_selectedCategory) ? _selectedCategory : 'Other';
  String get _safeUnit => _validUnits.contains(_selectedUnit) ? _selectedUnit : 'pieces';

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load existing versions for this barcode
  Future<void> _loadVersions() async {
    try {
      _isLoadingVersions = true;
      if (mounted) setState(() {});
      
      final versions = await _consensusService.getSubmissions(widget.barcode);
      final userVote = await _consensusService.getUserVote(widget.barcode);
      
      if (mounted) {
        setState(() {
          _versions = versions;
          _userVoteIndex = userVote;
          _isLoadingVersions = false;
        });
      }
    } catch (e) {
      print('[DIALOG] Error loading versions: $e');
      if (mounted) {
        setState(() {
          _isLoadingVersions = false;
        });
      }
    }
  }

  /// Vote for a specific version
  Future<void> _voteForVersion(int index) async {
    if (_isVoting) return;
    
    try {
      setState(() => _isVoting = true);
      
      await _consensusService.voteForSubmission(widget.barcode, index);
      
      // Reload versions to get updated vote counts
      await _loadVersions();
      
      if (mounted) {
        Fluttertoast.showToast(
          msg: '✅ Vote recorded!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error voting: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isVoting = false);
    }
  }
  
  void _scrollToEditFields() {
    // Small delay to allow widget to build first
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _editFieldsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _editFieldsKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _scrollToVersions() {
    // Small delay to allow widget to build first
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _versionsKey.currentContext != null) {
        Scrollable.ensureVisible(
          _versionsKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  Future<void> _submitEdit() async {
    // Validate input
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Please enter a product name',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }
      return;
    }

    // Prevent double submission
    if (_isSubmitting) return;

    // CRITICAL: Unfocus text fields BEFORE any async work to prevent mouse tracker freeze
    FocusScope.of(context).unfocus();
    
    // Small delay to let focus system settle
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    // Set loading state safely
    _isSubmitting = true;
    if (mounted) setState(() {});

    try {
      // Prepare data before async call
      final editedData = {
        'name': name,
        'brand': _brandController.text.trim(),
        'category': widget.productData['category'] ?? 'Other',
        'unit': widget.productData['unit'] ?? 'pieces',
        'image_url': widget.productData['image_url'],
        'ingredients': widget.productData['ingredients'],
        'allergens': widget.productData['allergens'],
        'nutrition': widget.productData['nutrition'],
      };

      // Submit to consensus service
      await _consensusService.submitProductData(
        widget.barcode,
        editedData,
        imageFile: _uploadedImage,
      );

      // Check mounted before any UI operations
      if (!mounted) return;
      
      // Reset state FIRST (fields already unfocused above)
      _isSubmitting = false;
      _showEditFields = false;
      
      // Show success AFTER state reset
      Fluttertoast.showToast(
        msg: '✅ Your correction has been submitted!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
      );
      
      // Trigger UI update last
      if (mounted) setState(() {});
      
    } catch (e) {
      // Reset state on error
      _isSubmitting = false;
      
      if (mounted) {
        setState(() {});
        Fluttertoast.showToast(
          msg: 'Error submitting: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 420),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header with barcode
            Row(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Add to Fridge',
                              style: Theme.of(context).textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.productData['user_verified'] == true) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_user, size: 11, color: Colors.green),
                                  SizedBox(width: 3),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (widget.productData['ai_enhanced'] == true) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 11, color: AppColors.primary),
                                  SizedBox(width: 3),
                                  Text(
                                    'AI Enhanced',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        'Barcode: ${widget.barcode}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Product image with upload/replace option
            Center(
              child: Column(
                children: [
                  InkWell(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _uploadedImage != null
                                ? Image.file(
                                    _uploadedImage!,
                                    fit: BoxFit.cover,
                                  )
                                : (widget.productData['image_url'] != null &&
                                        widget.productData['image_url'].toString().isNotEmpty)
                                    ? Image.network(
                                        widget.productData['image_url'],
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            color: AppColors.surface,
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppColors.surface,
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.image_not_supported,
                                                  size: 40, color: AppColors.textSecondary),
                                              SizedBox(height: 4),
                                              Text('Tap to add',
                                                  style: TextStyle(
                                                      fontSize: 10, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: AppColors.surface,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              size: 40,
                                              color: AppColors.primary.withValues(alpha: 0.6),
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'Add Photo',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                          ),
                        ),
                        // Overlay edit icon for existing images
                        if (_uploadedImage != null ||
                            (widget.productData['image_url'] != null &&
                                widget.productData['image_url'].toString().isNotEmpty))
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _uploadedImage != null
                        ? 'Tap to change photo'
                        : (widget.productData['image_url'] != null &&
                                widget.productData['image_url'].toString().isNotEmpty)
                            ? 'Tap to change photo'
                            : 'Tap to add photo',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Community Consensus Badge (if from consensus) - minimal display
            if (widget.productData['source'] == 'Community Consensus') ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 16, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      'Community Verified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Brand info (if available)
            if (widget.productData['brand'] != null && widget.productData['brand'].toString().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business, size: 18, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Brand',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            widget.productData['brand'].toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Allergens (if available)
            if (widget.productData['allergens'] != null && 
                (widget.productData['allergens'] as List).isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_outlined, size: 16, color: AppColors.error),
                        SizedBox(width: 6),
                        Text(
                          'Allergens',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: (widget.productData['allergens'] as List).map((allergen) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            allergen.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Ingredients (if available)
            if (widget.productData['ingredients'] != null && 
                widget.productData['ingredients'].toString().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.list_alt, size: 16, color: AppColors.secondary),
                        SizedBox(width: 6),
                        Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.productData['ingredients'].toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Product Information (Read-only display)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Row(
                    children: [
                      const Icon(Icons.inventory_2, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.productData['name']?.toString() ?? 'Unknown Product',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (widget.productData['brand'] != null && 
                      widget.productData['brand'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.business, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          widget.productData['brand'].toString(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      Text(
                        widget.productData['category']?.toString() ?? 'Other',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  
                  // Low confidence warning
                  if ((widget.productData['confidence'] ?? 0.0) < 0.8) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Low confidence data - please verify or suggest corrections',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Your Inventory Details
            Text(
              'Add to Your Fridge',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Quantity and Expiry
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectExpiryDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (optional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _expiryDate?.toString().split(' ')[0] ?? 'Not set',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Nutrition info (if available)
            if (widget.productData['nutrition'] != null && widget.productData['nutrition'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Nutrition (per 100g):',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...widget.productData['nutrition'].entries
                  .where((entry) => entry.value != null)
                  .take(4)
                  .map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _buildInfoRow(
                          entry.key.replaceAll('_', ' ').toUpperCase(),
                          '${entry.value}g',
                        ),
                      )),
            ],

            const SizedBox(height: 24),

            // PRIMARY ACTION: Add to Fridge (HERO BUTTON)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _confirmAndAddToInventory,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.kitchen, size: 24),
                label: Text(
                  _isSaving ? 'Adding...' : 'Add to Fridge',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // SECONDARY ACTIONS (smaller, less prominent)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show versions button
                    if (_versions.isNotEmpty && !_showVersions)
                      TextButton.icon(
                        onPressed: () {
                          _showVersions = true;
                          setState(() {});
                          _scrollToVersions();
                        },
                        icon: const Icon(Icons.people, size: 16),
                        label: Text(
                          _versions.length == 1 
                              ? '1 version' 
                              : '${_versions.length} versions', 
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                      ),
                    if (!_showEditFields)
                      TextButton.icon(
                        onPressed: () {
                          _showEditFields = true;
                          setState(() {});
                          _scrollToEditFields();
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Wrong info?', style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(foregroundColor: Colors.orange),
                      ),
                  ],
                ),
              ],
            ),

            // COMMUNITY VERSIONS - Vote for different versions
            if (_showVersions && _versions.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                key: _versionsKey,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.how_to_vote, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Community Versions (${_versions.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _showVersions = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Vote for the most accurate version:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ..._versions.asMap().entries.map((entry) {
                final index = entry.key;
                final version = entry.value;
                final isUserVote = _userVoteIndex == index;
                final votes = version['votes'] as int? ?? 0;
                final imageUrl = version['image_url']?.toString();
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isUserVote 
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUserVote 
                          ? AppColors.primary 
                          : AppColors.primary.withValues(alpha: 0.15),
                      width: isUserVote ? 2 : 1,
                    ),
                    boxShadow: isUserVote ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: InkWell(
                    onTap: _isVoting ? null : () => _voteForVersion(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          // Product image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(
                                  color: isUserVote 
                                      ? AppColors.primary.withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.inventory_2,
                                        size: 28,
                                        color: AppColors.textSecondary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.inventory_2,
                                      size: 28,
                                      color: AppColors.textSecondary,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Version details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  version['name']?.toString() ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isUserVote ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                if (version['brand'] != null && version['brand'].toString().isNotEmpty)
                                  Text(
                                    version['brand'].toString(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        version['category']?.toString() ?? 'Other',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Vote count and indicator (right side)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Vote button/indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isUserVote 
                                      ? AppColors.primary 
                                      : AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isUserVote ? Icons.thumb_up : Icons.thumb_up_outlined,
                                      size: 14,
                                      color: isUserVote ? Colors.white : AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$votes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isUserVote ? Colors.white : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUserVote) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Your vote',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // Edit fields (collapsed by default, only show when user clicks "Wrong info?")
            if (_showEditFields) ...[
              const Divider(height: 24),
              Text(
                key: _editFieldsKey,
                'Correct the Information',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit Correction'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      _expiryDate = date;
      setState(() {});
    }
  }

  Future<void> _confirmAndAddToInventory() async {
    if (_nameController.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please enter a product name',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    // SAFE setState pattern - direct assignment before async
    _isSaving = true;
    if (mounted) setState(() {});

    try {
      // Parse quantity
      final quantity = double.tryParse(_quantityController.text) ?? 1.0;

      // Upload image if user added one
      String? uploadedImageUrl;
      if (_uploadedImage != null) {
        uploadedImageUrl = await _cacheService.uploadProductImage(
          widget.barcode,
          _uploadedImage!,
        );
      }
      
      if (!mounted) return;

      // Prepare product data for caching with user corrections
      final hasUserCorrections = _nameController.text.trim() != (widget.productData['name'] ?? '') ||
          _selectedCategory != (widget.productData['category'] ?? 'Other') ||
          _selectedUnit != (widget.productData['unit'] ?? 'pieces') ||
          uploadedImageUrl != null;

      final productDataToCache = {
        ...widget.productData,
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'unit': _selectedUnit,
      };

      // ALWAYS cache user data - corrections are more valuable than raw API data
      // Even if user says "not correct", their edited version should be saved
      await _cacheService.cacheBarcode(
        widget.barcode,
        productDataToCache,
        uploadedImageUrl: uploadedImageUrl,
        userVerified: true,
        userCorrected: hasUserCorrections,
      );
      
      if (!mounted) return;

      // Prepare corrections if user made changes
      Map<String, dynamic>? corrections;
      if (!_isCorrect || 
          _nameController.text != widget.productData['name'] ||
          _selectedCategory != widget.productData['category'] ||
          _selectedUnit != widget.productData['unit']) {
        corrections = {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'unit': _selectedUnit,
        };
      }

      // Confirm and save to Firebase
      final success = await SmartBarcodeService.confirmAndSaveBarcodeData(
        barcode: widget.barcode,
        isCorrect: _isCorrect,
        corrections: corrections,
        customName: _nameController.text.trim(),
        customCategory: _selectedCategory,
        customUnit: _selectedUnit,
        quantity: quantity,
        expiryDate: _expiryDate,
      );
      
      if (!mounted) return;

      if (success) {
        // Prepare data before any UI operations
        final inventoryData = {
          'name': _nameController.text.trim(),
          'category': _selectedCategory,
          'unit': _selectedUnit,
          'quantity': quantity,
          'barcode': widget.barcode,
          'expiryDate': _expiryDate?.toIso8601String(),
          'added_by_scan': true,
          'image_url': uploadedImageUrl ?? widget.productData['image_url'],
        };
        
        // Reset state BEFORE navigation
        _isSaving = false;
        
        // Call callback
        widget.onSaveToInventory(inventoryData);

        // Navigate AFTER callback completes
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _isSaving = false;
        if (mounted) {
          setState(() {});
          widget.onError?.call('Failed to save product data');
        }
      }
    } catch (e) {
      _isSaving = false;
      if (mounted) {
        setState(() {});
        Fluttertoast.showToast(
          msg: '❌ Error: ${e.toString()}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        _uploadedImage = File(image.path);
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Error picking image: $e',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
}
