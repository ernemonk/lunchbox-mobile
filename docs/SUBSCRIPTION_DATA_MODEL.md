# 💳 Subscription Data Model

**Purpose:** Define the Firestore structure for managing user subscriptions and usage limits

---

## 📊 User Document Structure

```javascript
users/{uid}
{
  // ===== EXISTING FIELDS =====
  email: "user@example.com",
  role: "user",  // "user" | "admin" (for permissions only)
  fridge: [{name: "Chicken", quantity: "2 lbs"}, ...],
  createdAt: timestamp,
  
  // ===== NEW SUBSCRIPTION FIELDS =====
  subscription: {
    // Status tracking
    status: "active",  // "free" | "active" | "trial" | "cancelled" | "expired"
    tier: "premium",   // "free" | "premium" | "family"
    type: "annual",    // "monthly" | "annual" | null
    
    // Dates
    startDate: timestamp("2026-01-15T00:00:00Z"),
    expiryDate: timestamp("2027-01-15T00:00:00Z"),
    cancelledAt: null,  // timestamp when user cancelled (null if not cancelled)
    trialEndDate: null, // timestamp for trial expiry (null if not on trial)
    
    // Payment info
    platform: "ios",  // "ios" | "android" | "web"
    transactionId: "1000000123456789",  // Latest transaction
    originalTransactionId: "1000000123456789",  // First transaction (iOS)
    autoRenew: true,  // Whether subscription will auto-renew
    
    // Analytics
    lifetimeValue: 39.99,  // Total revenue from this user
    totalMonthsActive: 1,  // How many months they've been subscribed
    lastPaymentDate: timestamp("2026-01-15T00:00:00Z"),
    lastPaymentAmount: 39.99
  },
  
  // ===== USAGE TRACKING (for rate limiting) =====
  usage: {
    // Daily limits
    generationsToday: 3,
    lastGenerationDate: "2025-12-22",  // Reset counter when date changes
    
    // Storage limits
    favoritesCount: 8,     // Current number of saved recipes
    fridgeItemsCount: 42,  // Current number of fridge items
    
    // Historical
    totalGenerations: 156,  // All-time
    totalFavorites: 23      // All-time (including deleted)
  },
  
  // ===== FUTURE: FAMILY PLAN =====
  familyPlan: {
    isOwner: true,  // Is this the account owner?
    familyId: "family_abc123",  // Shared family group ID
    members: ["uid1", "uid2", "uid3"],  // If owner
    ownerUid: null  // If member, reference to owner
  }
}
```

---

## 🔐 Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check subscription status
    function isActiveSubscriber(userData) {
      return userData.subscription.status == 'active' &&
             userData.subscription.expiryDate > request.time &&
             userData.subscription.tier in ['premium', 'family'];
    }
    
    // Helper function to check generation limit
    function canGenerateRecipes(userData) {
      let today = request.time.toMillis() / 86400000;  // Days since epoch
      let lastGenDate = userData.usage.lastGenerationDate;
      
      // Premium = unlimited
      if (isActiveSubscriber(userData)) {
        return true;
      }
      
      // Free tier = 5 per day
      return userData.usage.generationsToday < 5;
    }
    
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
      
      // Only allow specific subscription fields to be updated
      allow update: if request.auth.uid == userId &&
                      request.resource.data.diff(resource.data).affectedKeys()
                        .hasOnly(['subscription', 'usage']);
    }
  }
}
```

---

## 💻 Code Implementation

### 1. Helper Class (Dart)

```dart
// lib/models/subscription.dart

class SubscriptionStatus {
  static const String free = 'free';
  static const String active = 'active';
  static const String trial = 'trial';
  static const String cancelled = 'cancelled';
  static const String expired = 'expired';
}

class SubscriptionTier {
  static const String free = 'free';
  static const String premium = 'premium';
  static const String family = 'family';
}

class SubscriptionType {
  static const String monthly = 'monthly';
  static const String annual = 'annual';
}

class UserSubscription {
  final String status;
  final String tier;
  final String? type;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final DateTime? cancelledAt;
  final bool autoRenew;
  final String? platform;
  final double lifetimeValue;
  
  UserSubscription({
    required this.status,
    required this.tier,
    this.type,
    this.startDate,
    this.expiryDate,
    this.cancelledAt,
    this.autoRenew = true,
    this.platform,
    this.lifetimeValue = 0.0,
  });
  
  // Parse from Firestore
  factory UserSubscription.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return UserSubscription.free();
    }
    
    return UserSubscription(
      status: map['status'] ?? SubscriptionStatus.free,
      tier: map['tier'] ?? SubscriptionTier.free,
      type: map['type'],
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      autoRenew: map['autoRenew'] ?? true,
      platform: map['platform'],
      lifetimeValue: (map['lifetimeValue'] ?? 0.0).toDouble(),
    );
  }
  
  // Factory for free tier
  factory UserSubscription.free() {
    return UserSubscription(
      status: SubscriptionStatus.free,
      tier: SubscriptionTier.free,
    );
  }
  
  // Check if user has premium access
  bool get isPremium {
    if (status != SubscriptionStatus.active) return false;
    if (tier == SubscriptionTier.free) return false;
    
    // Check expiry
    if (expiryDate != null && expiryDate!.isBefore(DateTime.now())) {
      return false;
    }
    
    return true;
  }
  
  // Check if user is in trial
  bool get isTrial {
    return status == SubscriptionStatus.trial &&
           (expiryDate?.isAfter(DateTime.now()) ?? false);
  }
  
  // Get days remaining
  int? get daysRemaining {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }
  
  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'tier': tier,
      'type': type,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'autoRenew': autoRenew,
      'platform': platform,
      'lifetimeValue': lifetimeValue,
    };
  }
}

class UserUsage {
  final int generationsToday;
  final String lastGenerationDate;
  final int favoritesCount;
  final int fridgeItemsCount;
  final int totalGenerations;
  
  UserUsage({
    this.generationsToday = 0,
    this.lastGenerationDate = '',
    this.favoritesCount = 0,
    this.fridgeItemsCount = 0,
    this.totalGenerations = 0,
  });
  
  factory UserUsage.fromMap(Map<String, dynamic>? map) {
    if (map == null) return UserUsage();
    
    return UserUsage(
      generationsToday: map['generationsToday'] ?? 0,
      lastGenerationDate: map['lastGenerationDate'] ?? '',
      favoritesCount: map['favoritesCount'] ?? 0,
      fridgeItemsCount: map['fridgeItemsCount'] ?? 0,
      totalGenerations: map['totalGenerations'] ?? 0,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'generationsToday': generationsToday,
      'lastGenerationDate': lastGenerationDate,
      'favoritesCount': favoritesCount,
      'fridgeItemsCount': fridgeItemsCount,
      'totalGenerations': totalGenerations,
    };
  }
}
```

### 2. Check Subscription Status

```dart
// lib/services/subscription_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription.dart';

class SubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Check if user can generate recipes (premium or under daily limit)
  static Future<bool> canGenerateRecipes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    if (userData == null) return false;
    
    // Get subscription info
    final subscription = UserSubscription.fromMap(userData['subscription']);
    
    // Premium = unlimited
    if (subscription.isPremium) {
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
    
    // Premium = unlimited
    if (subscription.isPremium) {
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
  
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
```

### 3. Usage in Recipe Generator

```dart
// lib/views/recipe_generator.dart

Future<void> _generateRecipes() async {
  // Check if user can generate
  final canGenerate = await SubscriptionService.canGenerateRecipes();
  
  if (!canGenerate) {
    _showUpgradeDialog();
    return;
  }
  
  // ... existing generation code ...
  
  // After successful generation, increment counter
  await SubscriptionService.incrementGenerationCount();
}

void _showUpgradeDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Daily Limit Reached'),
      content: Text(
        'You\'ve used your 5 free recipe generations for today.\n\n'
        'Upgrade to Premium for unlimited generations!',
      ),
      actions: [
        TextButton(
          child: Text('Maybe Later'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Upgrade Now'),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaywallPage()),
            );
          },
        ),
      ],
    ),
  );
}
```

---

## 🔄 Migration Script

For existing users, initialize their subscription data:

```dart
// Run once to migrate existing users
Future<void> migrateExistingUsers() async {
  final usersSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .get();
  
  final batch = FirebaseFirestore.instance.batch();
  
  for (var doc in usersSnapshot.docs) {
    final data = doc.data();
    
    // Skip if already has subscription data
    if (data.containsKey('subscription')) continue;
    
    batch.update(doc.reference, {
      'subscription': UserSubscription.free().toMap(),
      'usage': UserUsage().toMap(),
    });
  }
  
  await batch.commit();
  print('Migrated ${usersSnapshot.docs.length} users');
}
```

---

## ✅ Summary

**Key Fields:**
- `subscription.status` - Active, expired, cancelled, etc.
- `subscription.tier` - Free, premium, family
- `subscription.expiryDate` - When subscription ends
- `usage.generationsToday` - For rate limiting

**Keep `role` separate** - Use only for admin permissions, not subscriptions!
