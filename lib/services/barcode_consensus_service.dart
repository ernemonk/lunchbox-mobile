/// Barcode Consensus Service
/// Stores user-submitted versions directly in the barcodes collection
/// Simple array of versions with voting

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BarcodeConsensusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Get consensus data for a barcode (top-voted version or main data)
  /// Returns product data from the barcodes collection
  Future<Map<String, dynamic>?> getConsensusData(String barcode) async {
    try {
      print('[CONSENSUS] Getting consensus for barcode: $barcode');
      final doc = await _firestore.collection('barcodes').doc(barcode).get();
      
      if (!doc.exists) {
        print('[CONSENSUS] No consensus data found');
        return null;
      }
      
      final data = doc.data()!;
      final versions = List<Map<String, dynamic>>.from(data['versions'] ?? []);
      
      // If there are versions, use the top-voted one
      if (versions.isNotEmpty) {
        versions.sort((a, b) => (b['votes'] as int? ?? 0).compareTo(a['votes'] as int? ?? 0));
        final topVersion = versions.first;
        print('[CONSENSUS] Found consensus with ${versions.length} versions');
        return {
          'barcode': barcode,
          'name': topVersion['name'] ?? data['name'],
          'brand': topVersion['brand'] ?? data['brand'],
          'category': topVersion['category'] ?? data['category'],
          'image_url': topVersion['image_url'] ?? data['image_url'],
          'unit': topVersion['unit'] ?? data['unit'] ?? 'pieces',
          'sources': ['Community Consensus'],
          'user_verified': true,
        };
      }
      
      // Otherwise use the main document data
      print('[CONSENSUS] Found barcode data (no versions yet)');
      return {
        'barcode': barcode,
        'name': data['name'],
        'brand': data['brand'],
        'category': data['category'],
        'image_url': data['image_url'],
        'unit': data['unit'] ?? 'pieces',
        'sources': data['sources'] ?? ['Cached'],
        'user_verified': data['user_verified'] ?? false,
      };
    } catch (e) {
      print('[CONSENSUS] Error getting consensus: $e');
      return null;
    }
  }

  /// Increment scan count for a barcode
  Future<void> incrementScanCount(String barcode) async {
    try {
      await _firestore.collection('barcodes').doc(barcode).update({
        'scanCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('[CONSENSUS] Error incrementing scan count: $e');
    }
  }

  /// Track when a user adds a barcode item to their fridge
  Future<void> trackFridgeAddition(String barcode, String userId) async {
    try {
      await _firestore.collection('barcodes').doc(barcode).update({
        'fridgeAdditions': FieldValue.increment(1),
        'lastFridgeAddition': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('[CONSENSUS] Error tracking fridge addition: $e');
    }
  }

  /// Submit user's version of product data
  /// Adds to the 'versions' array in barcodes/{barcode}
  Future<void> submitProductData(
    String barcode,
    Map<String, dynamic> productData, {
    File? imageFile,
  }) async {
    print('[CONSENSUS] ========================================');
    print('[CONSENSUS] 🚀 submitProductData START');
    print('[CONSENSUS] Barcode: $barcode');
    print('[CONSENSUS] Saving to: barcodes/$barcode');
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('[CONSENSUS] ❌ User not authenticated');
        throw Exception('User not authenticated');
      }
      print('[CONSENSUS] ✅ User: ${user.uid}');

      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          print('[CONSENSUS] ⚠️ Image too large (max 5MB), skipping');
        } else {
          imageUrl = await _uploadImage(barcode, user.uid, imageFile);
          if (imageUrl.isEmpty) {
            imageUrl = null; // Reset to null if upload failed
            print('[CONSENSUS] ⚠️ Image upload failed, using existing image');
          } else {
            print('[CONSENSUS] ✅ Image uploaded: $imageUrl');
          }
        }
      }

      // Build the version object - use new image URL or fall back to existing
      final finalImageUrl = (imageUrl != null && imageUrl.isNotEmpty) 
          ? imageUrl 
          : productData['image_url'];
          
      final version = {
        'user_id': user.uid,
        'name': productData['name'],
        'brand': productData['brand'],
        'category': productData['category'],
        'image_url': finalImageUrl,
        'ingredients': productData['ingredients'] ?? '',
        'allergens': productData['allergens'] ?? [],
        'nutrition': productData['nutrition'] ?? {},
        'unit': productData['unit'] ?? 'pieces',
        'submitted_at': DateTime.now().toIso8601String(),
        'votes': 1,
        'voters': [user.uid],
      };
      print('[CONSENSUS] 📦 Version: $version');

      // Reference to the barcode document
      final docRef = _firestore.collection('barcodes').doc(barcode);
      print('[CONSENSUS] 🔥 Writing to: barcodes/$barcode');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          // Create new barcode document with this version
          print('[CONSENSUS] 📝 Creating new barcode document...');
          transaction.set(docRef, {
            'barcode': barcode,
            'name': productData['name'],
            'brand': productData['brand'],
            'category': productData['category'],
            'image_url': imageUrl ?? productData['image_url'],
            'unit': productData['unit'] ?? 'pieces',
            'versions': [version],
            'lastUpdated': FieldValue.serverTimestamp(),
            'user_corrected': true,
          });
        } else {
          // Add to existing versions array
          print('[CONSENSUS] 📝 Adding to existing versions...');
          final data = doc.data()!;
          final versions = List<Map<String, dynamic>>.from(data['versions'] ?? []);
          
          // Check if user already has a version, update it
          final existingIdx = versions.indexWhere((v) => v['user_id'] == user.uid);
          if (existingIdx != -1) {
            versions[existingIdx] = version;
            print('[CONSENSUS] ♻️ Updated existing version at index $existingIdx');
          } else {
            versions.add(version);
            print('[CONSENSUS] ➕ Added new version, total: ${versions.length}');
          }
          
          transaction.update(docRef, {
            'versions': versions,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      });

      print('[CONSENSUS] ✅✅✅ SAVED TO barcodes/$barcode ✅✅✅');
      print('[CONSENSUS] ========================================');
    } catch (e, stack) {
      print('[CONSENSUS] ❌ ERROR: $e');
      print('[CONSENSUS] Stack: $stack');
      rethrow;
    }
  }

  /// Get all versions for a barcode
  Future<List<Map<String, dynamic>>> getSubmissions(String barcode) async {
    try {
      print('[CONSENSUS] Getting versions for: barcodes/$barcode');
      final doc = await _firestore.collection('barcodes').doc(barcode).get();
      
      if (!doc.exists) {
        print('[CONSENSUS] No document found');
        return [];
      }
      
      final data = doc.data()!;
      final versions = List<Map<String, dynamic>>.from(data['versions'] ?? []);
      
      // Sort by votes descending
      versions.sort((a, b) => (b['votes'] as int? ?? 0).compareTo(a['votes'] as int? ?? 0));
      
      print('[CONSENSUS] Found ${versions.length} versions');
      return versions;
    } catch (e) {
      print('[CONSENSUS] Error getting versions: $e');
      return [];
    }
  }

  /// Vote for a version
  Future<void> voteForSubmission(String barcode, int versionIndex) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      print('[CONSENSUS] Voting for version $versionIndex in barcodes/$barcode');
      
      final docRef = _firestore.collection('barcodes').doc(barcode);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) throw Exception('Barcode not found');
        
        final data = doc.data()!;
        final versions = List<Map<String, dynamic>>.from(data['versions'] ?? []);
        
        if (versionIndex < 0 || versionIndex >= versions.length) {
          throw Exception('Invalid version index');
        }
        
        // Remove user's vote from all versions
        for (var v in versions) {
          final voters = List<String>.from(v['voters'] ?? []);
          if (voters.contains(user.uid)) {
            voters.remove(user.uid);
            v['voters'] = voters;
            v['votes'] = voters.length;
          }
        }
        
        // Add vote to selected version
        final voters = List<String>.from(versions[versionIndex]['voters'] ?? []);
        if (!voters.contains(user.uid)) {
          voters.add(user.uid);
          versions[versionIndex]['voters'] = voters;
          versions[versionIndex]['votes'] = voters.length;
        }
        
        transaction.update(docRef, {'versions': versions});
      });
      
      print('[CONSENSUS] ✅ Vote recorded');
    } catch (e) {
      print('[CONSENSUS] Error voting: $e');
      rethrow;
    }
  }

  /// Get user's current vote
  Future<int?> getUserVote(String barcode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final versions = await getSubmissions(barcode);
      
      for (var i = 0; i < versions.length; i++) {
        final voters = List<String>.from(versions[i]['voters'] ?? []);
        if (voters.contains(user.uid)) {
          return i;
        }
      }
      
      return null;
    } catch (e) {
      print('[CONSENSUS] Error getting user vote: $e');
      return null;
    }
  }

  /// Upload image to Firebase Storage
  Future<String> _uploadImage(String barcode, String userId, File imageFile) async {
    try {
      // Verify file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }
      
      final fileSize = await imageFile.length();
      print('[CONSENSUS] 📸 Uploading image: ${imageFile.path} (${fileSize} bytes)');
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'barcode_images/$barcode/${userId}_$timestamp.jpg';
      print('[CONSENSUS] 📸 Storage path: $storagePath');
      
      final ref = _storage.ref().child(storagePath);
      
      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'barcode': barcode,
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final uploadTask = ref.putFile(imageFile, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('[CONSENSUS] 📸 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });
      
      await uploadTask;
      
      final downloadUrl = await ref.getDownloadURL();
      print('[CONSENSUS] 📸 Upload complete! URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('[CONSENSUS] ❌ Error uploading image: $e');
      // Don't fail the whole submission, just skip the image
      return '';
    }
  }
}
