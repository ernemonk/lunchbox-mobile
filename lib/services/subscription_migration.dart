import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription.dart';

/// Migration utility to initialize subscription data for existing users
/// 
/// This should be run once to add subscription and usage fields
/// to all existing user documents in Firestore.
/// 
/// Usage:
/// - Can be called from an admin panel
/// - Or run once through a debug button
/// - Or executed via Firebase Cloud Functions
class SubscriptionMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Migrate all existing users to have subscription data
  /// 
  /// This will:
  /// 1. Query all users in the 'users' collection
  /// 2. Add default 'subscription' and 'usage' fields if missing
  /// 3. Use batch operations for efficiency (up to 500 users per batch)
  /// 
  /// Returns: Number of users migrated
  static Future<int> migrateExistingUsers() async {
    print('[MIGRATION] Starting user subscription migration...');
    
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('users').get();
      print('[MIGRATION] Found ${usersSnapshot.docs.length} total users');
      
      int migratedCount = 0;
      int skippedCount = 0;
      int batchCount = 0;
      WriteBatch batch = _firestore.batch();
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        
        // Skip if already has subscription data
        if (data.containsKey('subscription') && data.containsKey('usage')) {
          skippedCount++;
          continue;
        }
        
        // Add subscription and usage fields
        batch.update(doc.reference, {
          'subscription': UserSubscription.free().toMap(),
          'usage': UserUsage().toMap(),
        });
        
        migratedCount++;
        batchCount++;
        
        // Firestore batches are limited to 500 operations
        if (batchCount >= 500) {
          await batch.commit();
          print('[MIGRATION] Committed batch of $batchCount users');
          batch = _firestore.batch();
          batchCount = 0;
        }
      }
      
      // Commit remaining operations
      if (batchCount > 0) {
        await batch.commit();
        print('[MIGRATION] Committed final batch of $batchCount users');
      }
      
      print('[MIGRATION] Migration complete!');
      print('[MIGRATION] - Migrated: $migratedCount users');
      print('[MIGRATION] - Skipped (already migrated): $skippedCount users');
      
      return migratedCount;
    } catch (e, stackTrace) {
      print('[MIGRATION] Error during migration: $e');
      print('[MIGRATION] Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// Migrate a single user by UID
  /// 
  /// Useful for testing or handling individual user issues
  static Future<bool> migrateSingleUser(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        print('[MIGRATION] User $uid does not exist');
        return false;
      }
      
      final data = userDoc.data();
      
      // Check if already migrated
      if (data?.containsKey('subscription') == true && 
          data?.containsKey('usage') == true) {
        print('[MIGRATION] User $uid already has subscription data');
        return false;
      }
      
      // Add subscription and usage fields
      await userDoc.reference.update({
        'subscription': UserSubscription.free().toMap(),
        'usage': UserUsage().toMap(),
      });
      
      print('[MIGRATION] Successfully migrated user $uid');
      return true;
    } catch (e) {
      print('[MIGRATION] Error migrating user $uid: $e');
      return false;
    }
  }
  
  /// Check migration status - returns stats
  /// 
  /// Returns a map with:
  /// - total: Total number of users
  /// - migrated: Users with subscription data
  /// - needsMigration: Users without subscription data
  static Future<Map<String, int>> checkMigrationStatus() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      int total = usersSnapshot.docs.length;
      int migrated = 0;
      int needsMigration = 0;
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        
        if (data.containsKey('subscription') && data.containsKey('usage')) {
          migrated++;
        } else {
          needsMigration++;
        }
      }
      
      return {
        'total': total,
        'migrated': migrated,
        'needsMigration': needsMigration,
      };
    } catch (e) {
      print('[MIGRATION] Error checking migration status: $e');
      rethrow;
    }
  }
}
