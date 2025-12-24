import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // Check if user has premium access (includes active trials)
  bool get isPremium {
    // Trial status is also premium
    if (status == SubscriptionStatus.trial) {
      if (expiryDate != null && expiryDate!.isAfter(DateTime.now())) {
        return true;
      }
      return false;
    }
    
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
