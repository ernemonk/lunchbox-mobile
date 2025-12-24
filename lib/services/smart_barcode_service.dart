/// Smart Barcode Service with Local Server Fallback
/// Automatically uses local server when cloud functions are unavailable
/// Provides smart database with user confirmation system

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SmartBarcodeService {
  // Firebase collections
  static const String _barcodeCollection = 'barcode_database';
  static const String _scanHistoryCollection = 'barcode_scan_history';
  static const String _userInventoryCollection = 'user_inventory';
  
  // Firebase instances
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cloud Function endpoints
  static const String _smartLookupAPI = 
      'https://barcode-enrichment-ronynpjena-uc.a.run.app';
  static const String _confirmDataAPI = 
      'https://barcode-enrichment-ronynpjena-uc.a.run.app';

  // Local development server (for testing)
  static const String _localBaseURL = 'http://localhost:8080';
  static const String _localSmartLookup = '$_localBaseURL/barcode';
  static const String _localConfirmData = '$_localBaseURL/confirm';
  static const String _localDatabaseStats = '$_localBaseURL/stats';
  
  // Start with cloud functions (will fallback to local if needed)
  static bool _useLocalServer = false;

  static const Duration _cacheExpiry = Duration(days: 7);

  /// Smart lookup with automatic fallback
  static Future<Map<String, dynamic>?> smartLookup(String barcode) async {
    try {
      print('[SMART_BARCODE] Looking up: $barcode');
      
      // Try cloud functions first (if configured)
      if (!_useLocalServer) {
        try {
          final cloudResponse = await http.post(
            Uri.parse(_smartLookupAPI),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'barcode': barcode}),
          ).timeout(const Duration(seconds: 8));
          
          if (cloudResponse.statusCode == 200) {
            final data = jsonDecode(cloudResponse.body);
            if (data['success']) {
              print('[SMART_BARCODE] Found via cloud function');
              return data['data'];
            }
          }
        } catch (e) {
          print('[SMART_BARCODE] Cloud function failed, falling back to local: $e');
          _useLocalServer = true; // Auto-fallback
        }
      }
      
      // Fallback to local server
      try {
        final localResponse = await http.post(
          Uri.parse(_localSmartLookup),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'barcode': barcode}),
        ).timeout(const Duration(seconds: 10));
        
        if (localResponse.statusCode == 200) {
          final data = jsonDecode(localResponse.body);
          if (data['success']) {
            print('[SMART_BARCODE] Found via local server');
            return data['data'];
          }
        }
      } catch (e) {
        print('[SMART_BARCODE] Local server also failed: $e');
        throw Exception('Both cloud function and local server are unavailable');
      }

      return null;
    } catch (e) {
      print('[SMART_BARCODE] Lookup error: $e');
      return null;
    }
  }

  /// Confirm barcode data with automatic fallback
  static Future<bool> confirmAndSaveBarcodeData({
    required String barcode,
    required bool isCorrect,
    Map<String, dynamic>? corrections,
    String? customName,
    String? customCategory,
    String? customUnit,
    double? quantity,
    DateTime? expiryDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('[SMART_BARCODE] User not authenticated');
        return false;
      }

      print('[SMART_BARCODE] Confirming and saving barcode: $barcode');
      
      // Step 1: Send confirmation to improve database
      await _confirmBarcodeData(
        barcode: barcode,
        isCorrect: isCorrect,
        corrections: corrections,
        userId: user.uid,
      );
      
      // Step 2: Save to user's Firestore inventory
      final inventoryData = {
        // Product data
        'name': customName ?? 'Unknown Product',
        'barcode': barcode,
        'category': customCategory ?? 'Other',
        'unit': customUnit ?? 'pieces',
        
        // User-specific data
        'quantity': quantity ?? 1.0,
        'added_by_scan': true,
        'confirmed_by_user': true,
        'added_at': FieldValue.serverTimestamp(),
        'expiry_date': expiryDate?.toIso8601String(),
      };

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fridge')
          .add(inventoryData);

      print('[SMART_BARCODE] Saved to user inventory: ${customName ?? barcode}');
      return true;
    } catch (e) {
      print('[SMART_BARCODE] Save error: $e');
      return false;
    }
  }

  /// Send confirmation with automatic fallback
  static Future<bool> _confirmBarcodeData({
    required String barcode,
    required bool isCorrect,
    Map<String, dynamic>? corrections,
    String? userId,
  }) async {
    try {
      bool success = false;
      
      // Try cloud function first (if configured)
      if (!_useLocalServer && !_confirmDataAPI.contains('your-region')) {
        try {
          final cloudResponse = await http.post(
            Uri.parse(_confirmDataAPI),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'barcode': barcode,
              'is_correct': isCorrect,
              'corrections': corrections ?? {},
              'user_id': userId ?? 'anonymous',
            }),
          ).timeout(const Duration(seconds: 5));

          if (cloudResponse.statusCode == 200) {
            final data = jsonDecode(cloudResponse.body);
            success = data['success'] ?? false;
            print('[SMART_BARCODE] Cloud function confirmation sent for $barcode');
          }
        } catch (e) {
          print('[SMART_BARCODE] Cloud function confirm failed, trying local: $e');
        }
      }
      
      // Fallback to local server
      if (!success) {
        try {
          final localResponse = await http.post(
            Uri.parse(_localConfirmData),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'barcode': barcode,
              'is_correct': isCorrect,
              'corrections': corrections ?? {},
              'user_id': userId ?? 'anonymous',
            }),
          ).timeout(const Duration(seconds: 5));

          if (localResponse.statusCode == 200) {
            final data = jsonDecode(localResponse.body);
            success = data['success'] ?? false;
            print('[SMART_BARCODE] Local server confirmation sent for $barcode');
          }
        } catch (e) {
          print('[SMART_BARCODE] Local server confirm also failed: $e');
        }
      }

      return success;
    } catch (e) {
      print('[SMART_BARCODE] Confirm error: $e');
      return false;
    }
  }
}