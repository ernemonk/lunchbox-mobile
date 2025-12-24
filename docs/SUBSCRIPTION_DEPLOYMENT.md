# Subscription System Deployment Guide

## ✅ What Was Implemented

1. **Subscription Models** ([lib/models/subscription.dart](lib/models/subscription.dart))
   - `UserSubscription` class with status tracking
   - `UserUsage` class for rate limiting
   - Constants for subscription tiers, types, and statuses

2. **Subscription Service** ([lib/services/subscription_service.dart](lib/services/subscription_service.dart))
   - Rate limiting (5 recipes/day for free tier)
   - Premium subscription checks
   - Generation counter tracking
   - Subscription activation/cancellation

3. **Recipe Generator Integration** ([lib/views/recipe_generator.dart](lib/views/recipe_generator.dart))
   - Checks subscription limits before generation
   - Shows upgrade dialog when limit reached
   - Tracks generation count automatically

4. **Firestore Security Rules** ([firestore.rules](firestore.rules))
   - Server-side validation of subscription status
   - Rate limiting enforcement
   - Secure data access controls

5. **Migration Utility** ([lib/services/subscription_migration.dart](lib/services/subscription_migration.dart))
   - Migrates existing users to new data structure
   - Batch processing for efficiency
   - Status checking utilities

---

## 🚀 Deployment Steps

### Step 1: Deploy Firestore Rules

```bash
# Make sure you have Firebase CLI installed
firebase deploy --only firestore:rules
```

### Step 2: Migrate Existing Users

You have several options to run the migration:

**Option A: Debug Button (Recommended for testing)**

Add a temporary button in your app (e.g., in settings):

```dart
import 'package:lunchbox/services/subscription_migration.dart';

// In your widget
ElevatedButton(
  onPressed: () async {
    final count = await SubscriptionMigration.migrateExistingUsers();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Migrated $count users')),
    );
  },
  child: Text('Migrate Users'),
)
```

**Option B: Firebase Cloud Function**

Deploy this as a one-time function:

```javascript
// In Firebase Functions
const admin = require('firebase-admin');

exports.migrateUsers = functions.https.onRequest(async (req, res) => {
  const db = admin.firestore();
  const usersRef = db.collection('users');
  const snapshot = await usersRef.get();
  
  const batch = db.batch();
  let count = 0;
  
  snapshot.forEach(doc => {
    const data = doc.data();
    if (!data.subscription || !data.usage) {
      batch.update(doc.ref, {
        subscription: {
          status: 'free',
          tier: 'free',
          autoRenew: true,
          lifetimeValue: 0.0
        },
        usage: {
          generationsToday: 0,
          lastGenerationDate: '',
          favoritesCount: 0,
          fridgeItemsCount: 0,
          totalGenerations: 0
        }
      });
      count++;
    }
  });
  
  await batch.commit();
  res.send(`Migrated ${count} users`);
});
```

**Option C: Check Status First**

```dart
// Check migration status before running
final status = await SubscriptionMigration.checkMigrationStatus();
print('Total users: ${status['total']}');
print('Already migrated: ${status['migrated']}');
print('Need migration: ${status['needsMigration']}');
```

### Step 3: Test the Implementation

1. **Test Free Tier Limits:**
   - Generate 5 recipes in a day
   - Verify 6th generation shows upgrade dialog

2. **Test Premium Access:**
   - Manually update a test user to premium:
   ```dart
   await SubscriptionService.activateSubscription(
     tier: SubscriptionTier.premium,
     type: SubscriptionType.monthly,
     platform: 'test',
     transactionId: 'test_123',
     amount: 9.99,
   );
   ```
   - Verify unlimited recipe generation

3. **Test Daily Reset:**
   - Wait until next day (or manually change `lastGenerationDate` in Firestore)
   - Verify counter resets

### Step 4: Build and Test

```bash
# Get dependencies (if needed)
flutter pub get

# Run the app
flutter run

# Or build for production
flutter build ios --release
flutter build apk --release
```

---

## 📋 Next Steps

1. **Create Paywall UI**
   - Design subscription plans screen
   - Implement in-app purchases (iOS/Android)
   - Add restore purchases functionality

2. **Add Subscription Management**
   - User can view subscription status
   - Cancel/renew options
   - Receipt validation

3. **Track Favorites Count**
   - Update `usage.favoritesCount` when saving/removing favorites
   - Implement limit checking using `SubscriptionService.canSaveFavorite()`

4. **Analytics Dashboard**
   - Monitor free vs premium users
   - Track conversion rates
   - Revenue reporting

---

## 🔍 Monitoring

After deployment, monitor:

1. **Firestore Console:**
   - Verify users have `subscription` and `usage` fields
   - Check generation counters are incrementing

2. **Error Logs:**
   - Watch for migration errors
   - Check for rate limiting issues

3. **User Feedback:**
   - Ensure upgrade dialogs appear correctly
   - Verify free tier limits are working

---

## 🐛 Troubleshooting

**Issue: Users not migrated**
- Run `SubscriptionMigration.checkMigrationStatus()` to verify
- Check Firestore rules allow updates
- Verify user is authenticated

**Issue: Rate limiting not working**
- Check `usage.lastGenerationDate` format (YYYY-MM-DD)
- Verify `incrementGenerationCount()` is called after generation
- Check Firestore security rules are deployed

**Issue: Premium users hitting limits**
- Verify `subscription.status` is 'active'
- Check `subscription.expiryDate` is in the future
- Ensure `subscription.tier` is 'premium' or 'family'

---

## 📝 Important Notes

- ⚠️ **Don't forget to deploy Firestore rules** - Without them, client-side checks can be bypassed
- 💰 **Revenue tracking** - All subscription transactions update `lifetimeValue`
- 🔄 **Auto-renewal** - Platform (iOS/Android) handles renewal, you'll need webhooks to update Firestore
- 🎁 **Trial period** - Currently defined but not implemented - add this when creating paywall
