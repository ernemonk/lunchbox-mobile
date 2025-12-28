/// Barcode Cache Service
/// Manages Firestore-based caching for barcode lookups
/// Stores confirmed product data for faster lookups and offline access

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BarcodeCacheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get cached barcode data from Firestore
  Future<Map<String, dynamic>?> getCachedBarcode(String barcode) async {
    try {
      print('[BARCODE_CACHE] Looking up cached barcode: $barcode');
      
      final doc = await _firestore
          .collection('barcodes')
          .doc(barcode)
          .get();

      if (doc.exists) {
        print('[BARCODE_CACHE] ✅ Found cached data');
        final data = doc.data()!;
        data['source'] = 'Cache';
        
        // Indicate if this is user-verified or user-corrected data (high quality!)
        if (data['user_verified'] == true) {
          print('[BARCODE_CACHE] 👤 This is user-verified data');
        }
        if (data['user_corrected'] == true) {
          print('[BARCODE_CACHE] ✏️ This data was corrected by user');
        }
        
        return data;
      }

      print('[BARCODE_CACHE] ❌ No cached data found');
      return null;
    } catch (e) {
      print('[BARCODE_CACHE] Error getting cached barcode: $e');
      return null;
    }
  }

  /// Save confirmed barcode data to Firestore
  Future<void> cacheBarcode(
    String barcode,
    Map<String, dynamic> productData, {
    String? uploadedImageUrl,
    bool userVerified = false,
    bool userCorrected = false,
  }) async {
    try {
      print('[BARCODE_CACHE] Saving barcode to cache: $barcode');
      print('[BARCODE_CACHE] User verified: $userVerified, User corrected: $userCorrected');

      final cacheData = {
        'barcode': barcode,
        'name': productData['name'],
        'brand': productData['brand'],
        'category': productData['category'],
        'image_url': uploadedImageUrl ?? productData['image_url'],
        'ingredients': productData['ingredients'] ?? '',
        'allergens': productData['allergens'] ?? [],
        'nutrition': productData['nutrition'] ?? {},
        'sources': productData['sources'] ?? [],
        'unit': productData['unit'] ?? 'pieces',
        'lastUpdated': FieldValue.serverTimestamp(),
        'scanCount': FieldValue.increment(1),
        'user_verified': userVerified,
        'user_corrected': userCorrected,
      };

      await _firestore
          .collection('barcodes')
          .doc(barcode)
          .set(cacheData, SetOptions(merge: true));

      print('[BARCODE_CACHE] ✅ Successfully cached barcode data');
    } catch (e) {
      print('[BARCODE_CACHE] ❌ Error caching barcode: $e');
    }
  }

  /// Upload product image to Firebase Storage
  Future<String?> uploadProductImage(String barcode, File imageFile) async {
    try {
      print('[BARCODE_CACHE] Uploading image for barcode: $barcode');

      final ref = _storage.ref().child('product_images/$barcode.jpg');
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('[BARCODE_CACHE] ✅ Image uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('[BARCODE_CACHE] ❌ Error uploading image: $e');
      return null;
    }
  }

  /// Increment scan count for analytics
  Future<void> incrementScanCount(String barcode) async {
    try {
      await _firestore
          .collection('barcodes')
          .doc(barcode)
          .update({'scanCount': FieldValue.increment(1)});
    } catch (e) {
      print('[BARCODE_CACHE] Error incrementing scan count: $e');
    }
  }

  /// Get most scanned products (for analytics)
  Future<List<Map<String, dynamic>>> getMostScannedProducts({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('barcodes')
          .orderBy('scanCount', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('[BARCODE_CACHE] Error getting most scanned products: $e');
      return [];
    }
  }
}
