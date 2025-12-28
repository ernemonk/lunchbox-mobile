# 💳 Payment Integration Plan

**Status:** Planning → Implementation  
**Priority:** 🔴 P0 - CRITICAL PATH TO REVENUE  
**Target Launch:** January 15, 2026  
**Estimated Effort:** 2 weeks

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Technology Choice: RevenueCat](#technology-choice-revenuecat)
3. [Implementation Phases](#implementation-phases)
4. [Code Architecture](#code-architecture)
5. [Testing Strategy](#testing-strategy)
6. [Security Considerations](#security-considerations)
7. [Troubleshooting Guide](#troubleshooting-guide)

---

## 🎯 Overview

### Current State
- **Backend:** Subscription service exists ✅ (`lib/services/subscription_service.dart`)
- **Firestore:** User subscription schema defined ✅
- **Payment SDK:** NOT installed ❌
- **UI:** No pricing page ❌
- **Store Config:** No IAP products ❌

### Target State
- Users can purchase subscriptions in-app
- RevenueCat handles receipt validation
- Firestore syncs subscription status
- Works on both iOS and Android

### Revenue Impact
- **Without payment:** $0 revenue, -$6,300/month at 10K MAU
- **With payment (5% conversion):** $2,500 MRR, positive ROI
- **Break-even:** 2,000 paid users

---

## 🔧 Technology Choice: RevenueCat

### Why RevenueCat?

| Feature | RevenueCat | Native IAP | Alternatives |
|---------|-----------|------------|--------------|
| **Cross-platform** | ✅ iOS + Android unified API | ❌ Separate code | ⚠️ Varies |
| **Receipt Validation** | ✅ Server-side automatic | ❌ Must build yourself | ⚠️ Varies |
| **Pricing Experiments** | ✅ A/B testing built-in | ❌ Manual | ❌ Manual |
| **Analytics** | ✅ MRR, LTV, cohorts | ❌ None | ⚠️ Basic |
| **Webhooks** | ✅ Real-time events | ❌ None | ⚠️ Limited |
| **Free Tier** | ✅ Up to $10K MRR | N/A | ❌ Usually paid |
| **Setup Time** | ⏰ 4-6 hours | ⏰ 20+ hours | ⏰ 8-15 hours |

**Decision:** Use RevenueCat for faster time-to-market and robust infrastructure.

### Pricing
- **Free:** Up to $10,000 MRR (perfect for launch)
- **Growth:** 1% of MRR above $10K
- **At break-even:** $0 (under free tier)
- **At 10K MAU with 5% conversion:** Still free

---

## 📅 Implementation Phases

### Phase 1: SDK Setup (Day 1-2)

#### 1.1 Install Dependencies
```yaml
# pubspec.yaml
dependencies:
  purchases_flutter: ^6.0.0  # RevenueCat SDK
  purchases_ui_flutter: ^6.0.0  # Optional: Prebuilt paywalls
```

Run: `flutter pub get`

#### 1.2 Create RevenueCat Account
1. Sign up at https://app.revenuecat.com
2. Create new project: "Lunchbox"
3. Get API keys:
   - iOS: App Store API Key
   - Android: Google Play API Key
4. **Store keys securely** (not in git!)

#### 1.3 Initialize SDK
**File:** `lib/main.dart`

```dart
import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize RevenueCat
  await Purchases.configure(
    PurchasesConfiguration('YOUR_API_KEY_HERE')
      ..appUserID = FirebaseAuth.instance.currentUser?.uid
      ..observerMode = false,
  );
  
  runApp(const MyApp());
}
```

**Security:** Use environment variables or `flutter_dotenv` for API keys.

---

### Phase 2: Store Configuration (Day 2-3)

#### 2.1 App Store Connect (iOS)

**Steps:**
1. Log in to https://appstoreconnect.apple.com
2. Go to "My Apps" → Lunchbox → "In-App Purchases"
3. Click "+" to create new subscription

**Product 1: Monthly**
- **Reference Name:** Lunchbox Premium Monthly
- **Product ID:** `lunchbox_premium_monthly`
- **Subscription Group:** Lunchbox Premium
- **Price:** $4.99 USD
- **Auto-renewable:** Yes
- **Billing Period:** 1 month
- **Free Trial:** 7 days
- **Description:** "Unlimited recipe generations, save unlimited favorites, no ads"

**Product 2: Annual**
- **Reference Name:** Lunchbox Premium Annual
- **Product ID:** `lunchbox_premium_annual`
- **Subscription Group:** Lunchbox Premium
- **Price:** $29.99 USD
- **Auto-renewable:** Yes
- **Billing Period:** 1 year
- **Free Trial:** 7 days (if never subscribed before)
- **Promotional Text:** "Save 50% with annual plan"

**Screenshots Needed:**
- App screenshots showing premium features
- Promotional images (1024x1024)

**Review Time:** 24-48 hours

#### 2.2 Google Play Console (Android)

**Steps:**
1. Log in to https://play.google.com/console
2. Select Lunchbox app → "Monetize" → "Subscriptions"
3. Click "Create subscription"

**Product 1: Monthly**
- **Product ID:** `lunchbox_premium_monthly`
- **Name:** Lunchbox Premium (Monthly)
- **Description:** "Unlimited AI recipe generations. Save unlimited favorites. No ads."
- **Price:** $4.99 USD
- **Billing Period:** Every month
- **Free Trial:** 7 days
- **Grace Period:** 3 days (for payment failures)

**Product 2: Annual**
- **Product ID:** `lunchbox_premium_annual`
- **Name:** Lunchbox Premium (Annual)
- **Description:** "Save 50% with the annual plan! All premium features included."
- **Price:** $29.99 USD
- **Billing Period:** Every year
- **Free Trial:** 7 days
- **Grace Period:** 3 days

**Base Plans Required:** Yes (required for new subscriptions)

**Review Time:** 24-48 hours

#### 2.3 RevenueCat Configuration

1. **Link App Store Connect:**
   - RevenueCat Dashboard → App Settings → iOS
   - Upload App Store Connect API Key (.p8 file)
   - Enter Issuer ID and Key ID

2. **Link Google Play:**
   - RevenueCat Dashboard → App Settings → Android
   - Upload Google Play Service Account JSON
   - Grant "View financial data" permission

3. **Create Offerings:**
   - Dashboard → Offerings → Create New
   - **Offering ID:** `default`
   - **Packages:**
     - Monthly: `$rc_monthly` → `lunchbox_premium_monthly`
     - Annual: `$rc_annual` → `lunchbox_premium_annual`

4. **Configure Webhooks:**
   - URL: `https://us-central1-lunchbox.cloudfunctions.net/revenuecat-webhook`
   - Events: Purchase, Renewal, Cancellation, Expiration
   - Used to sync Firestore subscription status

---

### Phase 3: Pricing Page UI (Day 3-5)

**File:** `lib/views/pricing_page.dart`

#### Design Specifications

**Layout:**
```
┌─────────────────────────────────┐
│      ⭐ Choose Your Plan        │
├─────────────────────────────────┤
│                                 │
│  ┌──────────────────────────┐  │
│  │   💎 Annual Plan         │  │
│  │   $29.99/year            │  │
│  │   ✅ Save 50%            │  │
│  │   ✅ Unlimited recipes   │  │
│  │   ✅ No ads              │  │
│  │   [Subscribe Now]        │  │
│  └──────────────────────────┘  │
│                                 │
│  ┌──────────────────────────┐  │
│  │   📅 Monthly Plan        │  │
│  │   $4.99/month            │  │
│  │   ✅ Most flexible       │  │
│  │   ✅ Cancel anytime      │  │
│  │   [Subscribe Now]        │  │
│  └──────────────────────────┘  │
│                                 │
│  📊 10,000+ home cooks trust us │
│  🔒 Cancel anytime • Secure     │
└─────────────────────────────────┘
```

#### Code Skeleton

```dart
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:lunchbox/core/theme/app_colors.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage> {
  List<Package>? _packages;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        setState(() {
          _packages = offerings.current!.availablePackages;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load plans: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePackage(Package package) async {
    try {
      setState(() => _isLoading = true);
      
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      
      // Check if user is now subscribed
      if (customerInfo.entitlements.active.isNotEmpty) {
        // Update Firestore via webhook or manually
        await _updateFirestoreSubscription(customerInfo);
        
        // Show success and navigate
        if (mounted) {
          Navigator.pop(context, true); // Return to previous screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Premium! 🎉'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      _handlePurchaseError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handlePurchaseError(PlatformException error) {
    String message = 'Purchase failed';
    
    switch (error.code) {
      case '1': // User cancelled
        message = 'Purchase cancelled';
        break;
      case '2': // Store problem
        message = 'Unable to connect to store';
        break;
      case '3': // Purchase not allowed
        message = 'Purchase not allowed';
        break;
      case '4': // Payment declined
        message = 'Payment declined. Please check your payment method.';
        break;
      default:
        message = 'An error occurred: ${error.message}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Future<void> _updateFirestoreSubscription(CustomerInfo info) async {
    // Update user document with subscription status
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'subscription.status': 'active',
        'subscription.tier': 'premium',
        'subscription.updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Plan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _buildPricingCards(),
    );
  }

  Widget _buildPricingCards() {
    // TODO: Build beautiful pricing cards
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final package in _packages ?? [])
          _PricingCard(
            package: package,
            onPurchase: () => _purchasePackage(package),
          ),
      ],
    );
  }
}

class _PricingCard extends StatelessWidget {
  final Package package;
  final VoidCallback onPurchase;

  const _PricingCard({required this.package, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    // TODO: Build premium card with gradient, features, CTA
    return Card(child: ListTile(title: Text(package.storeProduct.title)));
  }
}
```

---

### Phase 4: Subscription Sync (Day 5-6)

#### 4.1 Firestore Webhook Handler

**File:** `backend/cloud-functions/revenuecat-webhook/index.js`

```javascript
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.revenuecatWebhook = functions.https.onRequest(async (req, res) => {
  // Verify webhook signature (RevenueCat docs)
  // ...

  const event = req.body.event;
  const userId = event.app_user_id;

  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'RENEWAL':
      await admin.firestore().collection('users').doc(userId).update({
        'subscription.status': 'active',
        'subscription.tier': 'premium',
        'subscription.expiryDate': new Date(event.expiration_at_ms),
        'subscription.type': event.period_type, // monthly/annual
        'subscription.updatedAt': admin.firestore.FieldValue.serverTimestamp(),
      });
      break;

    case 'CANCELLATION':
      await admin.firestore().collection('users').doc(userId).update({
        'subscription.status': 'cancelled',
        'subscription.willRenew': false,
        'subscription.updatedAt': admin.firestore.FieldValue.serverTimestamp(),
      });
      break;

    case 'EXPIRATION':
      await admin.firestore().collection('users').doc(userId).update({
        'subscription.status': 'expired',
        'subscription.tier': 'free',
        'subscription.updatedAt': admin.firestore.FieldValue.serverTimestamp(),
      });
      break;
  }

  res.status(200).send('OK');
});
```

**Deploy:** `firebase deploy --only functions:revenuecatWebhook`

#### 4.2 Client-Side Sync (Fallback)

If webhook fails, sync on app open:

```dart
// lib/services/subscription_service.dart
static Future<void> syncWithRevenueCat() async {
  try {
    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    
    final isActive = customerInfo.entitlements.active.isNotEmpty;
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'subscription.status': isActive ? 'active' : 'free',
        'subscription.tier': isActive ? 'premium' : 'free',
        'subscription.syncedAt': FieldValue.serverTimestamp(),
      });
    }
  } catch (e) {
    print('[SYNC] Error syncing subscription: $e');
  }
}
```

Call in `main.dart` on app start.

---

### Phase 5: Paywall Logic (Day 6-7)

#### 5.1 Trial Expiration Modal

**File:** `lib/widgets/trial_expired_modal.dart`

```dart
Future<void> showTrialExpiredModal(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false, // Force user to decide
    builder: (context) => AlertDialog(
      title: const Text('Your 7-Day Trial Has Ended'),
      content: const Text(
        'Continue enjoying unlimited recipes and premium features by subscribing now!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Maybe Later'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PricingPage()),
            );
          },
          child: const Text('Subscribe Now'),
        ),
      ],
    ),
  );
}
```

**Trigger:** Check trial expiry on recipe generation, favorites save, etc.

#### 5.2 Soft Paywall (Daily Limits)

**File:** `lib/views/recipe_generator/recipe_generator_page.dart`

```dart
Future<void> _generateRecipes() async {
  // Check if user can generate
  final canGenerate = await SubscriptionService.canGenerateRecipes();
  
  if (!canGenerate) {
    _showUpgradeModal();
    return;
  }
  
  // Proceed with generation...
  // ...
  
  // After generation, increment count
  await SubscriptionService.incrementGenerationCount();
}

void _showUpgradeModal() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Daily Limit Reached'),
      content: const Text(
        'You've used all 3 free recipe generations today. Upgrade to Premium for unlimited recipes!',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PricingPage()),
            );
          },
          child: const Text('Upgrade'),
        ),
      ],
    ),
  );
}
```

---

## 🧪 Testing Strategy

### Test Accounts

#### iOS Sandbox Testing
1. **Create Sandbox Tester:**
   - App Store Connect → Users and Access → Sandbox Testers
   - Add test email (can be fake: `test@lunchbox.test`)
2. **Sign out** of real App Store on device
3. **Purchase** will prompt for sandbox credentials
4. **Test:**
   - Purchase monthly
   - Purchase annual
   - Cancel subscription
   - Restore purchases

#### Android Testing
1. **Add License Testers:**
   - Google Play Console → Testing → License Testing
   - Add Google account emails
2. **Use Test Track:**
   - Upload app to Internal Testing
   - Add testers to track
3. **Test:**
   - Purchase monthly
   - Purchase annual
   - Cancel via Google Play
   - Test payment failures

### Test Scenarios

| Scenario | Expected Behavior | Verified |
|----------|-------------------|----------|
| **Purchase monthly** | User becomes premium, Firestore updates | ☐ |
| **Purchase annual** | User becomes premium, saves 50% | ☐ |
| **Cancel subscription** | Access until expiry, then free tier | ☐ |
| **Restore purchases** | Premium access restored | ☐ |
| **Payment declined** | Error message, retry option | ☐ |
| **Network failure** | Graceful error, retry | ☐ |
| **Trial expiration** | Hard paywall modal shown | ☐ |
| **Daily limit hit** | Soft paywall modal shown | ☐ |
| **Webhook delivery** | Firestore syncs within 30s | ☐ |
| **Webhook failure** | Client sync on next app open | ☐ |

---

## 🔒 Security Considerations

### 1. API Key Protection

**❌ NEVER commit API keys to git!**

**Use environment variables:**

```dart
// lib/config/env.dart
class Env {
  static const String revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'YOUR_KEY_HERE', // Only for dev
  );
}
```

**Run with:**
```bash
flutter run --dart-define=REVENUECAT_API_KEY=your_actual_key
```

### 2. Receipt Validation

- ✅ **RevenueCat handles server-side validation** (you don't need to!)
- ✅ Prevents fake purchases
- ✅ Detects jailbreak/root hacks

### 3. Firestore Security Rules

```javascript
// firestore.rules
match /users/{userId}/subscription {
  allow read: if request.auth.uid == userId;
  allow write: if false; // Only Cloud Functions can write
}
```

Subscription status can ONLY be modified by:
1. RevenueCat webhook (Cloud Function)
2. Admin users (server-side only)

### 4. Rate Limiting

Prevent abuse of free tier:
- Daily generation limit: 3/day
- Reset at midnight UTC
- Firestore counter: `users/{uid}/dailyRecipeCount`
- Counter includes timestamp for reset logic

---

## 🐛 Troubleshooting Guide

### Issue: "Product not available for purchase"

**Causes:**
- Store product not approved yet
- Wrong product ID
- App not signed with correct certificate

**Fix:**
1. Wait 24-48 hours after creating product
2. Verify product ID matches exactly
3. Re-sign app with distribution certificate

### Issue: "Receipt validation failed"

**Causes:**
- RevenueCat API key mismatch
- Bundle ID doesn't match

**Fix:**
1. Verify API key in RevenueCat dashboard
2. Check bundle ID: `com.aztech.lunchbox`
3. Re-upload service account JSON (Android)

### Issue: "Subscription not syncing to Firestore"

**Causes:**
- Webhook not configured
- Cloud Function error
- Network issues

**Fix:**
1. Check RevenueCat webhook logs
2. Check Cloud Function logs: `firebase functions:log`
3. Force sync: Call `SubscriptionService.syncWithRevenueCat()`

### Issue: "Purchase succeeds but user still sees paywall"

**Causes:**
- Sync delay
- Cache issue
- Entitlement not granted

**Fix:**
1. Wait 30 seconds for webhook
2. Force app restart
3. Call `Purchases.syncPurchases()`
4. Check RevenueCat dashboard for active entitlement

---

## 📊 Success Metrics

Track in Firebase Analytics:

```dart
FirebaseAnalytics.instance.logEvent(
  name: 'purchase_initiated',
  parameters: {'product_id': packageId},
);

FirebaseAnalytics.instance.logEvent(
  name: 'purchase_completed',
  parameters: {
    'product_id': packageId,
    'price': package.storeProduct.price,
    'currency': package.storeProduct.currencyCode,
  },
);
```

**Monitor:**
- Paywall impressions
- Purchase initiated
- Purchase completed
- Purchase failed (with error codes)
- Trial started
- Trial expired
- Subscription cancelled

---

## ✅ Launch Checklist

### Pre-Launch
- [ ] RevenueCat SDK installed
- [ ] API keys configured (not in git!)
- [ ] App Store products created & approved
- [ ] Google Play products created & approved
- [ ] Pricing page UI complete
- [ ] Purchase flow tested on iOS sandbox
- [ ] Purchase flow tested on Android test track
- [ ] Webhook configured & tested
- [ ] Firestore security rules updated
- [ ] Analytics events implemented
- [ ] Error handling complete
- [ ] Trial expiration modal tested
- [ ] Daily limit modal tested

### Launch Day
- [ ] App Store version submitted
- [ ] Google Play version submitted
- [ ] Monitor RevenueCat dashboard
- [ ] Monitor Firebase Analytics
- [ ] Monitor Crashlytics for payment errors
- [ ] Test real purchase (refund after)

### Post-Launch (Week 1)
- [ ] Track conversion rate
- [ ] Monitor payment failures
- [ ] Check webhook reliability
- [ ] Validate Firestore sync accuracy
- [ ] Collect user feedback
- [ ] Fix critical bugs within 24h

---

## 📚 Resources

- **RevenueCat Docs:** https://docs.revenuecat.com
- **Flutter Plugin:** https://pub.dev/packages/purchases_flutter
- **App Store Connect Guide:** https://developer.apple.com/app-store-connect/
- **Google Play Billing:** https://developer.android.com/google/play/billing

---

**Estimated Timeline:** 10-14 days  
**Risk Level:** Medium (standard integration)  
**Revenue Impact:** 🔴 CRITICAL - Blocks all revenue  

**Next Action:** Install RevenueCat SDK and create store accounts
