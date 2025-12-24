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
    return await _recognizeWithCloudVision(imageFile);
  }

  /// Recognize using Cloud Vision API (premium)
  static Future<List<Map<String, dynamic>>> _recognizeWithCloudVision(File imageFile) async {
    print('[ImageRecog] ☁️  Analyzing with Cloud Vision API...');
    
    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    
    final response = await http.post(
      Uri.parse(_cloudVisionAPI),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image': base64Image}),
    ).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final detections = data['detections'] as List;
        print('[ImageRecog] ✅ Cloud Vision detected ${detections.length} items');
        
        return detections.map((item) => {
          'name': item['name'] as String,
          'confidence': item['confidence'] as String,
          'source': 'cloud_vision',
        }).toList();
      }
    }
    
    throw Exception('Cloud Vision API returned error: ${response.statusCode}');
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
