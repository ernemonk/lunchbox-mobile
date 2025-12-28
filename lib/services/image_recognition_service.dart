/// Image Recognition Service for Food Detection
/// Uses Google Cloud Vision API for accurate food recognition

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart';

class ImageRecognitionService {
  // Cloud Vision API endpoint (deployed Cloud Function)
  static const String _cloudVisionAPI = 'https://image-recognition-ronynpjena-uc.a.run.app';

  /// Recognize food items from image using Cloud Vision API
  /// 
  /// [imageFile] - Image to analyze
  /// [usePremiumMode] - Ignored, always uses Cloud Vision
  /// 
  /// Returns list of detected foods with confidence scores
  static Future<List<Map<String, dynamic>>> recognizeFoods({
    required File imageFile,
    bool usePremiumMode = false,
  }) async {
    return await _recognizeWithCloudVision(imageFile, mode: 'food');
  }

  /// Scan receipt/grocery list for food items
  /// 
  /// [imageFile] - Receipt image to analyze
  /// 
  /// Returns list of food items from receipt with prices if available
  static Future<List<Map<String, dynamic>>> scanReceipt({
    required File imageFile,
  }) async {
    return await _recognizeWithCloudVision(imageFile, mode: 'receipt');
  }

  /// Recognize a single food item for barcode enhancement (FREEMIUM FEATURE)
  /// 
  /// This is a limited version of image recognition available to ALL users
  /// to enhance barcode lookup when the API returns "Unknown Product".
  /// 
  /// [imageFile] - Image of the product to analyze
  /// 
  /// Returns single best match with confidence, or null if no match
  static Future<Map<String, dynamic>?> recognizeSingleItemForBarcode({
    required File imageFile,
  }) async {
    print('[ImageRecog] 🆓 FREEMIUM: Barcode enhancement mode');
    
    // Use same Cloud Vision API but only return top result
    final results = await _recognizeWithCloudVision(imageFile, mode: 'food');
    
    if (results.isEmpty) {
      print('[ImageRecog] ℹ️  No items detected for barcode enhancement');
      return null;
    }
    
    // Return only the highest confidence match
    final topResult = results.first;
    print('[ImageRecog] ✨ Barcode enhanced with: ${topResult['name']} (${topResult['confidence']})');
    
    return topResult;
  }

  /// Recognize using Cloud Vision API (premium)
  static Future<List<Map<String, dynamic>>> _recognizeWithCloudVision(
    File imageFile, {
    String mode = 'food',
  }) async {
    print('[ImageRecog] ☁️  Analyzing with Cloud Vision API (mode: $mode)...');
    print('[ImageRecog] 📤 API endpoint: $_cloudVisionAPI');
    
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    print('[ImageRecog] 📦 Image size: ${imageBytes.length} bytes, base64 length: ${base64Image.length}');
    
    try {
      final response = await http.post(
        Uri.parse(_cloudVisionAPI),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'mode': mode,
        }),
      ).timeout(const Duration(seconds: 30));
      
      print('[ImageRecog] 📥 Response status: ${response.statusCode}');
      print('[ImageRecog] 📥 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[ImageRecog] 🔍 Parsed data: $data');
        
        if (data['success'] == true) {
          // API returns 'foods' not 'detections'
          final foods = data['foods'] as List?;
          
          if (foods == null || foods.isEmpty) {
            print('[ImageRecog] ⚠️  No foods detected in image');
            return [];
          }
          
          print('[ImageRecog] ✅ Cloud Vision detected ${foods.length} items');
          print('[ImageRecog] 📋 Foods: $foods');
          
          return foods.map((item) => {
            'name': item['name'] as String,
            'confidence': item['confidence'] as String,
            'category': item['category'] as String?,
            'quantity': item['quantity'] as String?,
            'unit': item['unit'] as String?,
            'source': 'cloud_vision',
          }).toList();
        } else {
          print('[ImageRecog] ❌ API returned success=false: ${data['error'] ?? 'unknown error'}');
          throw Exception('Cloud Vision API error: ${data['error'] ?? 'unknown'}');
        }
      }
      
      print('[ImageRecog] ❌ HTTP error ${response.statusCode}: ${response.body}');
      throw Exception('Cloud Vision API returned error: ${response.statusCode}');
    } catch (e) {
      print('[ImageRecog] 💥 Exception caught: $e');
      print('[ImageRecog] 💥 Exception type: ${e.runtimeType}');
      rethrow;
    }
  }

  /// Check if user can access image recognition feature (premium only)
  static Future<bool> canUseImageRecognition() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data();
      if (userData == null) return false;
      
      final subscription = UserSubscription.fromMap(userData['subscription']);
      
      // Only premium or trial users can use image recognition
      return subscription.isPremium || subscription.isTrial;
    } catch (e) {
      print('[ImageRecog] ⚠️  Access check failed: $e');
      return false;
    }
  }

  /// Check if premium mode is available
  /// 
  /// Always returns true - Cloud Vision API is default
  /// Feature access control is handled at UI level
  static Future<bool> isPremiumModeAvailable() async {
    return true; // Always use Cloud Vision API
  }

  /// Get service information
  static Map<String, dynamic> getServiceInfo() {
    return {
      'mode': 'cloud_vision',
      'description': 'Google Cloud Vision API',
      'accuracy': '90-95%',
      'cost': 'Premium subscription required',
      'note': 'High accuracy food recognition powered by Google AI',
    };
  }
}
