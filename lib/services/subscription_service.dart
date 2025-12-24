import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart';

class SubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Check if user can generate recipes (premium/trial or under daily limit)
  static Future<bool> canGenerateRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) return false;
    
    // Get subscription info
    final subscription = UserSubscription.fromMap(userData['subscription']);
    
    // Premium or active trial = unlimited
    if (subscription.isPremium || subscription.isTrial) {
      return true;
    }
    
    // Free tier = check daily limit
    final usage = UserUsage.fromMap(userData['usage']);
    final today = _getTodayString();
    
    // Reset counter if new day
    if (usage.lastGenerationDate != today) {
      return true;  // New day = fresh limit
    }
    
    // Check if under limit (5 per day)
    return usage.generationsToday < 5;
  }
  
  /// Increment generation counter
  static Future<void> incrementGenerationCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final today = _getTodayString();
    final userRef = _firestore.collection('users').doc(user.uid);
    
    await _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final userData = userDoc.data();
      final usage = UserUsage.fromMap(userData?['usage']);
      
      final isNewDay = usage.lastGenerationDate != today;
      
      transaction.update(userRef, {
        'usage.generationsToday': isNewDay ? 1 : FieldValue.increment(1),
        'usage.lastGenerationDate': today,
        'usage.totalGenerations': FieldValue.increment(1),
      });
    });
  }
  
  /// Check if user can save more favorites
  static Future<bool> canSaveFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) return false;
    
    final subscription = UserSubscription.fromMap(userData['subscription']);
    
    // Premium or trial = unlimited
    if (subscription.isPremium || subscription.isTrial) {
      return true;
    }
    
    // Free tier = 10 max
    final usage = UserUsage.fromMap(userData['usage']);
    return usage.favoritesCount < 10;
  }
  
  /// Get user's subscription info
  static Future<UserSubscription> getSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return UserSubscription.free();
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    
    return UserSubscription.fromMap(userData?['subscription']);
  }
  
  /// Update subscription (called after purchase)
  static Future<void> activateSubscription({
    required String tier,
    required String type,
    required String platform,
    required String transactionId,
    required double amount,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final now = DateTime.now();
    final expiryDate = type == SubscriptionType.annual
        ? now.add(Duration(days: 365))
        : now.add(Duration(days: 30));
    
    await _firestore.collection('users').doc(user.uid).update({
      'subscription': {
        'status': SubscriptionStatus.active,
        'tier': tier,
        'type': type,
        'startDate': Timestamp.fromDate(now),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'cancelledAt': null,
        'autoRenew': true,
        'platform': platform,
        'transactionId': transactionId,
        'originalTransactionId': transactionId,
        'lifetimeValue': FieldValue.increment(amount),
        'totalMonthsActive': type == SubscriptionType.annual ? 12 : 1,
        'lastPaymentDate': Timestamp.fromDate(now),
        'lastPaymentAmount': amount,
      },
    });
  }
  
  /// Cancel subscription (mark as cancelled, but active until expiry)
  static Future<void> cancelSubscription() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await _firestore.collection('users').doc(user.uid).update({
      'subscription.status': SubscriptionStatus.cancelled,
      'subscription.cancelledAt': FieldValue.serverTimestamp(),
      'subscription.autoRenew': false,
    });
  }
  
  /// Activate free trial (30 days of premium for free)
  static Future<void> activateFreeTrial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    // Check if user already has premium or trial
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final currentSubscription = UserSubscription.fromMap(userData?['subscription']);
    
    if (currentSubscription.tier != SubscriptionTier.free) {
      throw Exception('User already has an active subscription');
    }
    
    // Check if user has ever had a trial (prevent multiple trials)
    final hasHadTrial = userData?['hasHadFreeTrial'] == true;
    if (hasHadTrial) {
      throw Exception('User has already used their free trial');
    }
    
    final now = DateTime.now();
    final expiryDate = now.add(const Duration(days: 30));
    
    await _firestore.collection('users').doc(user.uid).update({
      'subscription': {
        'status': SubscriptionStatus.trial,
        'tier': SubscriptionTier.premium,
        'type': null,  // No type for trial
        'startDate': Timestamp.fromDate(now),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'trialEndDate': Timestamp.fromDate(expiryDate),
        'cancelledAt': null,
        'autoRenew': false,  // Trial doesn't auto-renew
        'platform': 'free_trial',
        'transactionId': 'trial_${user.uid}_${now.millisecondsSinceEpoch}',
        'originalTransactionId': 'trial_${user.uid}_${now.millisecondsSinceEpoch}',
        'lifetimeValue': 0.0,  // Free trial = $0
        'totalMonthsActive': 1,
        'lastPaymentDate': Timestamp.fromDate(now),
        'lastPaymentAmount': 0.0,
      },
      'hasHadFreeTrial': true,  // Mark that user has used their trial
    });

    // Track trial activation in analytics
    try {
      await _firestore.collection('user_analytics').doc(user.uid)
        .collection('subscription_events')
        .add({
          'event': 'trial_activated',
          'timestamp': Timestamp.fromDate(now),
          'expiryDate': Timestamp.fromDate(expiryDate),
          'daysRemaining': 30,
        });
    } catch (e) {
      print('[ANALYTICS] Failed to track trial activation: $e');
    }
  }
  
  /// Check if user's trial/subscription has expired and update status
  /// This should be called when app starts or when checking subscription status
  static Future<void> checkAndUpdateExpiredSubscriptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) return;
    
    final subscription = UserSubscription.fromMap(userData['subscription']);
    
    // Check if subscription/trial has expired
    if (subscription.expiryDate != null && 
        subscription.expiryDate!.isBefore(DateTime.now()) &&
        (subscription.status == SubscriptionStatus.trial || 
         subscription.status == SubscriptionStatus.active)) {
      
      final wasTrial = subscription.status == SubscriptionStatus.trial;
      
      // Expire the subscription - revert to free tier
      await _firestore.collection('users').doc(user.uid).update({
        'subscription.status': SubscriptionStatus.expired,
        'subscription.tier': SubscriptionTier.free,
      });
      
      print('[SUBSCRIPTION] Expired subscription for user ${user.uid}');

      // Track expiration in analytics
      try {
        await _firestore.collection('user_analytics').doc(user.uid)
          .collection('subscription_events')
          .add({
            'event': wasTrial ? 'trial_expired' : 'subscription_expired',
            'timestamp': FieldValue.serverTimestamp(),
            'expiryDate': subscription.expiryDate,
            'wasAutoRenew': subscription.autoRenew,
            'tier': subscription.tier,
          });
      } catch (e) {
        print('[ANALYTICS] Failed to track expiration: $e');
      }
    }
  }
  
  /// Check if user has already used their free trial
  static Future<bool> hasUsedFreeTrial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    
    return userData?['hasHadFreeTrial'] == true;
  }
  
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
