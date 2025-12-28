/// Smart Barcode Service with Local Server Fallback
/// Automatically uses local server when cloud functions are unavailable
/// Provides smart database with user confirmation system

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'barcode_cache_service.dart';
import 'barcode_consensus_service.dart';

class SmartBarcodeService {
  // Barcode cache service
  static final BarcodeCacheService _cacheService = BarcodeCacheService();
  
  // Consensus service
  static final BarcodeConsensusService _consensusService = BarcodeConsensusService();
  
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
      print('\n========== SMART BARCODE LOOKUP START ==========');
      print('[SMART_BARCODE] Looking up: $barcode');
      
      // 1. Check community consensus FIRST (highest priority)
      final consensusData = await _consensusService.getConsensusData(barcode);
      if (consensusData != null) {
        print('[SMART_BARCODE] ✅ Found in community consensus');
        await _consensusService.incrementScanCount(barcode);
        print('========== SMART BARCODE LOOKUP END (CONSENSUS) ==========\n');
        return consensusData;
      }
      
      // 2. Check cache second
      final cachedData = await _cacheService.getCachedBarcode(barcode);
      if (cachedData != null) {
        print('[SMART_BARCODE] ✅ Found in cache');
        await _cacheService.incrementScanCount(barcode);
        print('========== SMART BARCODE LOOKUP END (CACHE) ==========\n');
        return cachedData;
      }
      
      // 3. Try cloud functions (if configured)
      if (!_useLocalServer) {
        try {
          print('[SMART_BARCODE] Trying cloud function: $_smartLookupAPI');
          final cloudResponse = await http.post(
            Uri.parse(_smartLookupAPI),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'barcode': barcode}),
          ).timeout(const Duration(seconds: 8));
          
          print('[SMART_BARCODE] Cloud response status: ${cloudResponse.statusCode}');
          print('[SMART_BARCODE] Cloud response body:');
          print(cloudResponse.body);
          
          if (cloudResponse.statusCode == 200) {
            final data = jsonDecode(cloudResponse.body);
            print('[SMART_BARCODE] Parsed cloud response:');
            print(jsonEncode(data));
            
            if (data['success']) {
              print('[SMART_BARCODE] ✅ Found via cloud function');
              print('[SMART_BARCODE] Data payload:');
              print(jsonEncode(data['data']));
              print('========== SMART BARCODE LOOKUP END (CLOUD) ==========\n');
              return data['data'];
            } else {
              print('[SMART_BARCODE] ⚠️ Cloud function returned success=false');
            }
          }
        } catch (e) {
          print('[SMART_BARCODE] ❌ Cloud function failed, falling back to local: $e');
          _useLocalServer = true; // Auto-fallback
        }
      }
      
      // Fallback to local server
      try {
        print('[SMART_BARCODE] Trying local server: $_localSmartLookup');
        final localResponse = await http.post(
          Uri.parse(_localSmartLookup),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'barcode': barcode}),
        ).timeout(const Duration(seconds: 10));
        
        print('[SMART_BARCODE] Local response status: ${localResponse.statusCode}');
        print('[SMART_BARCODE] Local response body:');
        print(localResponse.body);
        
        if (localResponse.statusCode == 200) {
          final data = jsonDecode(localResponse.body);
          print('[SMART_BARCODE] Parsed local response:');
          print(jsonEncode(data));
          
          if (data['success']) {
            print('[SMART_BARCODE] ✅ Found via local server');
            print('[SMART_BARCODE] Data payload:');
            print(jsonEncode(data['data']));
            print('========== SMART BARCODE LOOKUP END (LOCAL) ==========\n');
            return data['data'];
          } else {
            print('[SMART_BARCODE] ⚠️ Local server returned success=false');
          }
        }
      } catch (e) {
        print('[SMART_BARCODE] ❌ Local server also failed: $e');
        print('========== SMART BARCODE LOOKUP END (FAILED) ==========\n');
        throw Exception('Both cloud function and local server are unavailable');
      }

      print('[SMART_BARCODE] ⚠️ No data found from any source');
      print('========== SMART BARCODE LOOKUP END (NO DATA) ==========\n');
      return null;
    } catch (e) {
      print('[SMART_BARCODE] ❌ Lookup error: $e');
      print('========== SMART BARCODE LOOKUP END (ERROR) ==========\n');
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
      
      // Step 2: Save to user's Firestore inventory (with merge logic)
      final fridgeRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fridge');
      
      final productName = customName ?? 'Unknown Product';
      final addQuantity = quantity ?? 1.0;
      
      // First, check if an item with the same barcode exists
      QueryDocumentSnapshot? existingDoc;
      
      if (barcode.isNotEmpty) {
        final barcodeQuery = await fridgeRef
            .where('barcode', isEqualTo: barcode)
            .limit(1)
            .get();
        
        if (barcodeQuery.docs.isNotEmpty) {
          existingDoc = barcodeQuery.docs.first;
          print('[SMART_BARCODE] Found existing item by barcode: $barcode');
        }
      }
      
      // If no barcode match, check for exact name match
      if (existingDoc == null) {
        final nameQuery = await fridgeRef
            .where('name', isEqualTo: productName)
            .limit(1)
            .get();
        
        if (nameQuery.docs.isNotEmpty) {
          existingDoc = nameQuery.docs.first;
          print('[SMART_BARCODE] Found existing item by name: $productName');
        }
      }
      
      if (existingDoc != null) {
        // Merge: Update existing item quantity
        final existingData = existingDoc.data() as Map<String, dynamic>;
        final existingQuantity = (existingData['quantity'] as num?)?.toDouble() ?? 1.0;
        final newQuantity = existingQuantity + addQuantity;
        
        await existingDoc.reference.update({
          'quantity': newQuantity,
          'updated_at': FieldValue.serverTimestamp(),
          // Update barcode if it was empty before
          if (barcode.isNotEmpty && (existingData['barcode'] == null || existingData['barcode'].toString().isEmpty))
            'barcode': barcode,
        });
        
        print('[SMART_BARCODE] ♻️ Merged with existing item: $productName ($existingQuantity + $addQuantity = $newQuantity)');
      } else {
        // No existing item found, create new
        final inventoryData = {
          // Product data
          'name': productName,
          'barcode': barcode,
          'category': customCategory ?? 'Other',
          'unit': customUnit ?? 'pieces',
          
          // User-specific data
          'quantity': addQuantity,
          'added_by_scan': true,
          'confirmed_by_user': true,
          'added_at': FieldValue.serverTimestamp(),
          'expiry_date': expiryDate?.toIso8601String(),
        };

        await fridgeRef.add(inventoryData);
        print('[SMART_BARCODE] ➕ Added new item to inventory: $productName');
      }
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