import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../services/ocr_service.dart';
import '../../services/image_recognition_service.dart';
import '../../services/smart_inventory_service.dart';
import '../../widgets/ocr_review_dialog.dart';
import 'myfridge_dialogs.dart';
import 'myfridge_state.dart';

/// Mixin providing photo/OCR functionality for MyFridge page.
/// 
/// Handles:
/// - Photo capture from camera/gallery
/// - OCR text extraction
/// - Visual food recognition
/// - Receipt scanning
/// - Smart batch merge
mixin MyFridgePhotoMixin<T extends StatefulWidget> on State<T>, MyFridgeStateMixin<T> {
  /// Show dialog to choose photo mode (text OCR or visual recognition)
  Future<void> showPhotoModeDialog() async {
    final mode = await MyFridgeDialogs.showPhotoModeDialog(context);

    if (mode == 'receipt') {
      await scanReceipt();
    } else if (mode == 'text') {
      await captureFromPhoto();
    } else if (mode == 'visual') {
      await captureForVisualRecognition();
    }
  }

  /// Capture image from camera or gallery for OCR
  Future<void> captureFromPhoto() async {
    try {
      // Pick image (ImagePicker will handle permission request automatically)
      // iOS will show native permission dialog on first use
      final imageFile = await OCRService.pickImage(source: ImageSource.camera);

      if (imageFile != null) {
        // Show loading for OCR processing
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Extract text from image
        final ocrText = await OCRService.extractText(imageFile);

        if (mounted) {
          Navigator.pop(context); // Close loading dialog
        }

        if (ocrText.isNotEmpty) {
          // Parse ingredients from OCR text
          final ingredients = await OCRService.parseIngredients(ocrText);

          if (mounted && ingredients.isNotEmpty) {
            // Show review dialog
            showDialog(
              context: context,
              builder: (context) => OCRReviewDialog(
                detectedItems: ingredients,
                onCancel: () => Navigator.pop(context),
                onConfirm: (selectedItems) {
                  Navigator.pop(context);
                  addMultipleItems(selectedItems);
                },
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No ingredients detected in image'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close any open dialogs
      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
      
      // Show error message with action to open settings if permission denied
      if (mounted) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        final isPermissionError = errorMessage.contains('Settings');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: Duration(seconds: isPermissionError ? 6 : 3),
            action: isPermissionError
                ? SnackBarAction(
                    label: 'Open Settings',
                    onPressed: () async {
                      await openAppSettings();
                    },
                  )
                : null,
          ),
        );
      }
    }
  }

  /// Add multiple items at once (from OCR batch)
  /// Add multiple items from batch scanning (OCR/Vision) with smart duplicate detection
  Future<void> addMultipleItems(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;

    // Use smart inventory service to merge with existing items
    final mergeResult = SmartInventoryService.mergeWithExistingInventory(
      detectedItems: items,
      existingItems: fridgeItems,
      similarityThreshold: 0.75, // 75% similarity for merging
    );

    if (mergeResult.totalChanges == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All items already exist in fridge'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Show confirmation dialog with merge details
    final confirmed = await MyFridgeDialogs.showSmartMergeConfirmation(
      context,
      SmartMergeResult(
        itemsToAdd: mergeResult.itemsToAdd,
        itemsToUpdate: mergeResult.itemsToUpdate,
        duplicatesSkipped: mergeResult.duplicatesSkipped,
      ),
    );
    if (confirmed != true) return;

    final user = auth.currentUser;
    if (user == null) return;

    // Apply updates to existing items
    for (final update in mergeResult.itemsToUpdate) {
      final index = update['index'] as int;
      setState(() {
        fridgeItems[index] = update['item'] as Map<String, dynamic>;
      });
    }

    // Add new items
    for (final newItem in mergeResult.itemsToAdd) {
      setState(() {
        fridgeItems.add(newItem);
      });
    }

    // Save to Firestore
    await firestore.collection('users').doc(user.uid).update({
      'fridge': fridgeItems,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ ${mergeResult.getSummary()}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Capture and recognize food items visually
  Future<void> captureForVisualRecognition() async {
    try {
      // Check if user has premium access
      final canUse = await ImageRecognitionService.canUseImageRecognition();
      
      if (!canUse) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.stars, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text('Premium Feature'),
                ],
              ),
              content: const Text(
                'Image recognition is a premium feature. Upgrade to Premium or start your free trial to identify food items from photos.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/subscription');
                  },
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Pick image
      final imageFile = await OCRService.pickImage(source: ImageSource.camera);

      if (imageFile != null) {
        // Show loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('🧠 Analyzing image with Cloud Vision...'),
                ],
              ),
            ),
          );
        }

        // Recognize foods (always uses Cloud Vision API)
        final usePremiumMode = await ImageRecognitionService.isPremiumModeAvailable();
        final recognizedFoods = await ImageRecognitionService.recognizeFoods(
          imageFile: imageFile,
          usePremiumMode: usePremiumMode,
        );

        if (mounted) {
          Navigator.pop(context); // Close loading
        }

        if (recognizedFoods.isNotEmpty) {
          // Convert to format expected by OCR review dialog
          final items = recognizedFoods.map((food) {
            return {
              'name': food['name'],
              'quantity': food['quantity'] ?? '1',
              'unit': food['unit'] ?? 'pieces',
              'category': food['category'] ?? 'Other',
              'confidence': food['confidence'],
            };
          }).toList();

          if (mounted) {
            // Show review dialog
            showDialog(
              context: context,
              builder: (context) => OCRReviewDialog(
                detectedItems: items,
                onCancel: () => Navigator.pop(context),
                onConfirm: (selectedItems) {
                  Navigator.pop(context);
                  addMultipleItems(selectedItems);
                },
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No food items detected. Try a clearer photo or use Receipt/Text mode.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close any dialogs
      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Scan receipt for food items
  Future<void> scanReceipt() async {
    try {
      // Check if user has premium access
      final canUse = await ImageRecognitionService.canUseImageRecognition();
      
      if (!canUse) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.stars, color: AppColors.accent),
                  SizedBox(width: 8),
                  Text('Premium Feature'),
                ],
              ),
              content: const Text(
                'Receipt scanning is a premium feature. Upgrade to Premium or start your free trial to extract food items from receipts.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/subscription');
                  },
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Pick image (can be camera or gallery for receipts)
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Receipt Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('From Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      final imageFile = await OCRService.pickImage(source: source);

      if (imageFile != null) {
        // Show loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('🧾 Scanning receipt with Gemini...'),
                ],
              ),
            ),
          );
        }

        // Call receipt scanning API
        final recognizedFoods = await ImageRecognitionService.scanReceipt(
          imageFile: imageFile,
        );

        // Close loading dialog
        if (mounted) {
          Navigator.pop(context);
        }

        if (recognizedFoods.isNotEmpty) {
          // Convert to format expected by OCR review dialog
          final items = recognizedFoods.map((food) {
            return {
              'name': food['name'],
              'quantity': food['quantity'] ?? '1',
              'unit': food['unit'] ?? 'pieces',
              'category': food['category'] ?? 'Other',
              'confidence': food['confidence'],
            };
          }).toList();

          if (mounted) {
            // Show review dialog
            showDialog(
              context: context,
              builder: (context) => OCRReviewDialog(
                detectedItems: items,
                onCancel: () => Navigator.pop(context),
                onConfirm: (selectedItems) {
                  Navigator.pop(context);
                  addMultipleItems(selectedItems);
                },
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No food items found on receipt. Try a clearer photo.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Close any dialogs
      if (mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning receipt: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
