# 📅 Trial & Subscription Expiration Management

**Last Updated:** December 22, 2025

---

## 🎯 How Trial Management Works

### Activation

**When a user starts a free trial:**

1. `activateFreeTrial()` is called
2. Creates subscription with:
   ```dart
   status: "trial"
   tier: "premium"
   startDate: now
   expiryDate: now + 30 days
   trialEndDate: now + 30 days
   ```
3. Sets `hasHadFreeTrial: true` on user document
4. User gets full premium access

### Expiration Detection

**Three ways trials/subscriptions expire:**

#### 1. **Automatic Check on App Start** ✅ (Implemented)

**File:** [lib/main.dart](../lib/main.dart#L56-L62)

```dart
// In AuthWrapper.initState()
await SubscriptionService.checkAndUpdateExpiredSubscriptions();
```

**What it does:**
- Runs when app starts
- Checks if `expiryDate` < now
- If expired → Updates status to "expired", tier to "free"
- User automatically loses premium access

**Pros:**
- ✅ Automatic
- ✅ No server needed
- ✅ Runs on every app launch

**Cons:**
- ❌ Only checks when user opens app
- ❌ If user doesn't open app, stays premium

#### 2. **Check Before Each Action** ✅ (Implemented)

**File:** [lib/services/subscription_service.dart](../lib/services/subscription_service.dart)

```dart
// Before allowing recipe generation
static Future<bool> canGenerateRecipes() async {
  final subscription = UserSubscription.fromMap(userData['subscription']);
  
  // Premium check includes expiry validation
  if (subscription.isPremium) {  // ← Checks expiryDate internally
    return true;
  }
  // ... check free tier limits
}
```

**Built into `isPremium` getter:**
```dart
bool get isPremium {
  if (status != SubscriptionStatus.active) return false;
  if (tier == SubscriptionTier.free) return false;
  
  // Check expiry
  if (expiryDate != null && expiryDate!.isBefore(DateTime.now())) {
    return false;  // ← Expired = no premium access
  }
  
  return true;
}
```

**What it does:**
- Every feature checks `isPremium` or `isTrial`
- Getter automatically validates expiry date
- If expired → Returns false → User can't use premium features

**Pros:**
- ✅ Real-time enforcement
- ✅ Works even if database not updated
- ✅ Can't bypass by modifying Firestore

**Cons:**
- ❌ Status in database may show "trial" even after expiry (until app opened)

#### 3. **Cloud Function (Scheduled)** ⚠️ (NOT Implemented - Optional)

**Best for production but requires Cloud Functions:**

```typescript
// functions/index.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Run every day at midnight
export const expireSubscriptions = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    
    // Find all expired subscriptions
    const expiredQuery = await db.collection('users')
      .where('subscription.expiryDate', '<', now)
      .where('subscription.status', 'in', ['trial', 'active'])
      .get();
    
    const batch = db.batch();
    
    expiredQuery.docs.forEach(doc => {
      batch.update(doc.ref, {
        'subscription.status': 'expired',
        'subscription.tier': 'free'
      });
    });
    
    await batch.commit();
    
    console.log(`Expired ${expiredQuery.size} subscriptions`);
  });
```

**Pros:**
- ✅ Runs automatically daily
- ✅ Works even if user never opens app
- ✅ Database always accurate
- ✅ Can send expiration emails

**Cons:**
- ❌ Requires Firebase Blaze plan (paid)
- ❌ More complex setup
- ❌ Costs money for Cloud Functions

---

## 🚫 Preventing Multiple Trials

### Current Implementation ✅

**File:** [lib/services/subscription_service.dart](../lib/services/subscription_service.dart#L136-L158)

```dart
static Future<void> activateFreeTrial() async {
  // ...
  
  // Check if user has ever had a trial (prevent multiple trials)
  final hasHadTrial = userData?['hasHadFreeTrial'] == true;
  if (hasHadTrial) {
    throw Exception('User has already used their free trial');
  }
  
  // ... activate trial ...
  
  await _firestore.collection('users').doc(user.uid).update({
    // ...
    'hasHadFreeTrial': true,  // ← Mark as used forever
  });
}
```

**How it works:**
1. User activates trial → `hasHadFreeTrial: true` is set
2. Flag never changes (even after trial expires)
3. If user tries again → Exception thrown
4. UI shows "Trial Already Used" message

**User document structure:**
```javascript
users/{uid}
{
  subscription: { ... },
  hasHadFreeTrial: true,  // ← Prevents re-activation
}
```

---

## 📊 Trial States & Transitions

```
NEW USER
   ↓
[Free Tier]
subscription.status: "free"
subscription.tier: "free"
hasHadFreeTrial: false
   ↓
   User clicks "Start Free Trial"
   ↓
[Active Trial]
subscription.status: "trial"
subscription.tier: "premium"
subscription.expiryDate: now + 30 days
hasHadFreeTrial: true  ← Set forever
   ↓
   30 days pass...
   ↓
[Expired Trial]
subscription.status: "expired"  ← Changed by expiration check
subscription.tier: "free"       ← Changed by expiration check
hasHadFreeTrial: true           ← Still true
   ↓
   User tries to start trial again
   ↓
[Blocked]
"You have already used your free trial"
```

---

## 🔍 Checking Expiration Status

### For Users (UI)

**Subscription Page:**
```dart
// Shows real-time status
final subscription = await SubscriptionService.getSubscription();

if (subscription.isTrial) {
  print('Active trial: ${subscription.daysRemaining} days left');
} else if (subscription.status == SubscriptionStatus.expired) {
  print('Trial expired - now on free tier');
}
```

### For Developers (Testing)

**Check user's subscription status in Firestore Console:**

1. Go to Firestore → `users` collection
2. Find user document
3. Check fields:
   ```javascript
   subscription: {
     status: "trial" | "expired" | "free",
     expiryDate: Timestamp,
     tier: "premium" | "free"
   }
   hasHadFreeTrial: true | false
   ```

**Manually expire a trial (for testing):**
```javascript
// In Firestore Console, update:
subscription.expiryDate = [yesterday's date]

// On next app open or feature use:
// → Automatically detected as expired
// → User loses premium access
```

---

## ⏰ Timing Examples

### Scenario 1: Normal Trial

```
Dec 22, 2025 @ 10:00 AM
User activates trial
→ expiryDate = Jan 21, 2026 @ 10:00 AM

Dec 23-Jan 20
→ subscription.isTrial = true
→ Full premium access

Jan 21, 2026 @ 10:01 AM
User opens app
→ checkAndUpdateExpiredSubscriptions() runs
→ expiryDate < now → Expired
→ Status changed to "expired"
→ Tier changed to "free"
→ User sees "Trial expired" message
```

### Scenario 2: User Doesn't Open App

```
Dec 22, 2025
Trial activated → expires Jan 21, 2026

Jan 21-30, 2026
User doesn't open app
→ Database still shows "trial" ❌
→ But if they did open app and try to generate:
   → isPremium checks expiryDate
   → expiryDate < now = false
   → Access denied ✅

Jan 31, 2026
User opens app
→ checkAndUpdateExpiredSubscriptions() runs
→ Status updated to "expired"
→ Database now accurate ✅
```

### Scenario 3: User Tries to Game System

```
User activates trial
→ hasHadFreeTrial = true

User deletes & reinstalls app
→ Same Firebase Auth UID
→ hasHadFreeTrial still true
→ Can't activate again ✅

User creates new account
→ New UID
→ hasHadFreeTrial = false
→ Can get new trial ⚠️ (expected behavior)
```

---

## 🛠️ Management Options

### Option 1: Current Setup (Recommended for MVP)

**What you have:**
- ✅ Client-side expiration checks
- ✅ Auto-check on app start
- ✅ One trial per user
- ❌ No scheduled cleanup

**When to use:**
- MVP/early stage
- Free Firebase plan
- Small user base (<1000)

**Limitations:**
- Database may be temporarily inaccurate
- No automatic email notifications
- Relies on users opening app

### Option 2: Add Cloud Functions (Production)

**What to add:**
- Daily scheduled function to expire trials
- Email notifications 3 days before expiry
- Email when trial expires

**When to use:**
- Production app
- Paid Firebase plan (Blaze)
- >1000 users

**Cost:**
- ~$0.01 per 1000 function invocations
- ~$1-5/month for typical usage

### Option 3: Hybrid (Best of Both)

**Use both:**
1. Client-side checks for instant enforcement
2. Cloud Function for database accuracy + emails

**Pros:**
- Best reliability
- Accurate database
- User notifications

---

## 📈 Monitoring Trial Status

### Analytics to Track

1. **Trial Activations**
   ```dart
   // Add to activateFreeTrial()
   await FirebaseAnalytics.instance.logEvent(
     name: 'trial_started',
     parameters: {'user_id': user.uid}
   );
   ```

2. **Trial Expirations**
   ```dart
   // Add to checkAndUpdateExpiredSubscriptions()
   if (expired) {
     await FirebaseAnalytics.instance.logEvent(
       name: 'trial_expired',
       parameters: {'user_id': user.uid}
     );
   }
   ```

3. **Conversion Attempts**
   ```dart
   // When user tries to activate trial again
   await FirebaseAnalytics.instance.logEvent(
     name: 'trial_reactivation_attempted'
   );
   ```

### Firestore Queries

**Find all active trials:**
```dart
final activeTrials = await FirebaseFirestore.instance
  .collection('users')
  .where('subscription.status', isEqualTo: 'trial')
  .where('subscription.expiryDate', isGreaterThan: Timestamp.now())
  .get();

print('Active trials: ${activeTrials.docs.length}');
```

**Find expired trials needing cleanup:**
```dart
final needsCleanup = await FirebaseFirestore.instance
  .collection('users')
  .where('subscription.status', isEqualTo: 'trial')
  .where('subscription.expiryDate', isLessThan: Timestamp.now())
  .get();

print('Trials to expire: ${needsCleanup.docs.length}');
```

---

## 🔧 Manual Management

### Extend a Trial (Support Request)

```dart
// Add 7 more days to a user's trial
final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
final doc = await userRef.get();
final currentExpiry = (doc.data()?['subscription']['expiryDate'] as Timestamp).toDate();
final newExpiry = currentExpiry.add(Duration(days: 7));

await userRef.update({
  'subscription.expiryDate': Timestamp.fromDate(newExpiry),
});
```

### Reset Trial (Edge Case)

```dart
// Allow user to use trial again (rare case)
await userRef.update({
  'hasHadFreeTrial': false,
  'subscription': UserSubscription.free().toMap(),
});
```

### Manually Expire Trial

```dart
// Immediately end a trial
await userRef.update({
  'subscription.status': SubscriptionStatus.expired,
  'subscription.tier': SubscriptionTier.free,
});
```

---

## ✅ Summary

| Aspect | Current Status | How It Works |
|--------|---------------|--------------|
| **Trial Start** | ✅ Automated | User clicks button → 30 days activated |
| **Trial End Detection** | ✅ Automated | App start + feature checks |
| **Database Update** | ✅ On app open | `checkAndUpdateExpiredSubscriptions()` |
| **Access Enforcement** | ✅ Real-time | `isPremium` checks expiry date |
| **Prevent Multiple Trials** | ✅ Implemented | `hasHadFreeTrial` flag |
| **Scheduled Cleanup** | ❌ Optional | Cloud Function (not implemented) |
| **Email Notifications** | ❌ Future | Requires Cloud Functions |

**Current approach is sufficient for MVP.** Add Cloud Functions when you scale or need email notifications.
