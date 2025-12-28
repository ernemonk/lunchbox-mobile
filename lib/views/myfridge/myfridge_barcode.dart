import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../services/barcode_service.dart';
import '../../services/smart_barcode_service.dart';
import '../../services/barcode_consensus_service.dart';
import '../../services/image_recognition_service.dart';
import '../../widgets/smart_barcode_confirmation_dialog.dart';
import 'myfridge_dialogs.dart';
import 'myfridge_state.dart';

/// Mixin providing barcode scanning functionality for MyFridge page.
/// 
/// Handles:
/// - Barcode scanning
/// - Smart product lookup
/// - Auto-enhancement with image recognition
/// - Firebase consensus tracking
mixin MyFridgeBarcodesMixin<T extends StatefulWidget> on State<T>, MyFridgeStateMixin<T> {
  /// Scan barcode from camera using smart barcode system
  Future<void> scanBarcode() async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            backgroundColor: AppColors.surface,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  'Scanning barcode...',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        );
      }

      // Scan barcode
      final barcode = await BarcodeService.scanBarcode();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (barcode != null && barcode.isNotEmpty) {
        // Show smart lookup loading
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              backgroundColor: AppColors.surface,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Looking up product...',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          );
        }

        // Use smart barcode lookup
        final productData = await SmartBarcodeService.smartLookup(barcode);

        if (mounted) {
          Navigator.pop(context); // Close loading dialog

          if (productData != null) {
            // Check if product name is generic/unknown
            final name = productData['name']?.toString() ?? '';
            final brand = productData['brand']?.toString() ?? '';
            final imageUrl = productData['image_url']?.toString();
            final isGenericName = name.toLowerCase().contains('unknown') || 
                                  (name.toLowerCase().contains('product') && brand.isNotEmpty);
            
            // Auto-enhance with existing image if name is generic and image exists
            if (isGenericName && imageUrl != null && imageUrl.isNotEmpty) {
              _autoEnhanceBarcodeWithImage(barcode, productData, imageUrl);
            } else {
              // Show smart confirmation dialog
              _showSmartBarcodeConfirmation(barcode, productData);
            }
          } else {
            // Fallback to manual entry with barcode
            MyFridgeDialogs.showManualEntryDialog(
              context: context,
              barcode: barcode,
              onAdd: addItem,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Close any open dialogs
        Navigator.of(context, rootNavigator: true).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Auto-enhance barcode data using existing image URL (FREEMIUM FEATURE)
  Future<void> _autoEnhanceBarcodeWithImage(String barcode, Map<String, dynamic> productData, String imageUrl) async {
    try {
      print('[BARCODE_ENHANCE] 🖼️ Auto-enhancing with existing image: $imageUrl');
      
      // Show processing dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            backgroundColor: AppColors.surface,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text(
                  '✨ Enhancing product name...',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        );
      }

      // Download image from URL
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image: ${response.statusCode}');
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/barcode_$barcode.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);
      
      // Use image recognition to get better product name
      final enhancedData = await ImageRecognitionService.recognizeSingleItemForBarcode(
        imageFile: tempFile,
      );

      // Clean up temp file
      await tempFile.delete();

      if (mounted) {
        Navigator.pop(context); // Close processing dialog
      }

      if (enhancedData != null) {
        // Merge: use image recognition name, keep barcode metadata
        final enhancedProductData = Map<String, dynamic>.from(productData);
        enhancedProductData['name'] = enhancedData['name'];
        enhancedProductData['category'] = enhancedData['category'] ?? productData['category'];
        
        // Add source tracking
        final sources = List<String>.from(productData['sources'] ?? []);
        sources.add('Image Recognition (Barcode Enhancement)');
        enhancedProductData['sources'] = sources;
        enhancedProductData['ai_enhanced'] = true;
        enhancedProductData['ai_confidence'] = enhancedData['confidence'];

        print('[BARCODE_ENHANCE] ✨ Enhanced "${productData['name']}" → "${enhancedData['name']}"');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✨ Enhanced: ${enhancedData['name']}'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
            ),
          );
          _showSmartBarcodeConfirmation(barcode, enhancedProductData);
        }
      } else {
        // No enhancement available, use original data
        print('[BARCODE_ENHANCE] ⚠️ Could not enhance product name');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not identify product from photo'),
              backgroundColor: Colors.orange,
            ),
          );
          _showSmartBarcodeConfirmation(barcode, productData);
        }
      }
    } catch (e) {
      print('[BARCODE_ENHANCE] ❌ Error: $e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enhancing product: $e'),
            backgroundColor: Colors.red,
          ),
        );
        _showSmartBarcodeConfirmation(barcode, productData);
      }
    }
  }

  /// Show smart barcode confirmation dialog with Firebase integration
  void _showSmartBarcodeConfirmation(String barcode, Map<String, dynamic> productData) {
    showDialog(
      context: context,
      builder: (context) => SmartBarcodeConfirmationDialog(
        barcode: barcode,
        productData: productData,
        onSaveToInventory: (confirmedData) async {
          // Save to user's fridge inventory
          await addItemFromBarcode(confirmedData);
          
          // Track fridge addition for auto-verification (consensus already submitted by dialog)
          try {
            final user = auth.currentUser;
            if (user != null) {
              final consensusService = BarcodeConsensusService();
              await consensusService.trackFridgeAddition(barcode, user.uid);
              print('[MYFRIDGE] ✅ Tracked fridge addition');
            }
          } catch (e) {
            print('[MYFRIDGE] Error tracking fridge addition: $e');
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}
