# 👤 User Onboarding & Pricing Guide

## How Users Get Added to the System

### 1. New User Signup Flow

**File:** [lib/views/signup_page.dart](lib/views/signup_page.dart)

When a user signs up with email/password:

1. **Firebase Authentication** creates the account
2. **Firestore** creates a user document at `users/{uid}` with:
   ```javascript
   {
     email: "user@example.com",
     uid: "firebase_uid_123",
     createdAt: timestamp,
     role: "user",
     fridge: [],  // Empty fridge
     
     // Free tier subscription (automatic)
     subscription: {
       status: "free",
       tier: "free",
       autoRenew: true,
       lifetimeValue: 0.0
     },
     
     // Usage tracking initialized
     usage: {
       generationsToday: 0,
       lastGenerationDate: "",
       favoritesCount: 0,
       fridgeItemsCount: 0,
       totalGenerations: 0
     }
   }
   ```

3. User is **automatically enrolled in the free tier**
4. User can immediately start using the app with free limits

### 2. Existing User Migration

For users who signed up before the subscription system:

**Use the migration utility:** [lib/services/subscription_migration.dart](lib/services/subscription_migration.dart)

```dart
// Migrate all existing users
final count = await SubscriptionMigration.migrateExistingUsers();
print('Migrated $count users');

// Or migrate a single user
await SubscriptionMigration.migrateSingleUser('user_uid_123');
```

---

## 💰 Pricing Structure

### Free Tier (Default for All New Users)

**Cost:** $0/month

**Limits:**
- ⏰ **5 recipe generations per day** (resets at midnight)
- 📝 **10 saved favorites** maximum
- 🧊 **50 fridge items** maximum
- 📅 **7 days history** only
- ❌ No export/print
- ❌ No meal planning

**How limits work:**
```dart
// Check if user can generate
final canGenerate = await SubscriptionService.canGenerateRecipes();
if (!canGenerate) {
  // Show upgrade dialog
}

// After generation, increment counter
await SubscriptionService.incrementGenerationCount();

// Check favorites limit
final canSave = await SubscriptionService.canSaveFavorite();
```

**Upgrade triggers:**
1. "Daily limit reached" after 5th generation
2. "Upgrade to save more" when trying to save 11th favorite
3. Feature locked screens for premium features

---

### Premium Tier

**Cost:**
- **$4.99/month** (monthly billing)
- **$39.99/year** (33% savings - $3.33/month)

**Benefits:**
- ♾️ **Unlimited recipe generations**
- ♾️ **Unlimited saved favorites**
- ♾️ **Unlimited fridge items**
- 📜 **Full recipe history** (forever)
- 📄 **Export & Print** recipes as PDF
- 📚 **Recipe collections** (organize by theme)
- ⚡ **Priority email support** (24h response)
- 🚀 **Early access** to new features

**Future features (Phase 2):**
- 🗓️ **Meal planning** (weekly calendar)
- 🛒 **Shopping lists** (auto-generated)
- 📊 **Nutrition tracking** (calories/macros)
- 🧠 **Advanced AI** (personalized recommendations)

**How to activate:**
```dart
// After successful in-app purchase
await SubscriptionService.activateSubscription(
  tier: SubscriptionTier.premium,
  type: SubscriptionType.annual,  // or monthly
  platform: 'ios',  // or 'android', 'web'
  transactionId: 'transaction_id_from_store',
  amount: 39.99,
);
```

---

### Family Tier (Coming Q2 2026)

**Cost:**
- **$7.99/month**
- **$69.99/year**

**Benefits:**
- All Premium features
- **Up to 5 family members**
- **Shared fridge** (everyone sees same inventory)
- **Individual dietary profiles**
- **Meal voting** (family picks together)

---

## 📊 Revenue Model Explained

### Unit Economics

**Cost per user (with API calls):**
- Free user: ~$0.60/month (limited generations)
- Premium user: ~$1.50/month (unlimited generations)

**Revenue per premium user:**
- Monthly: $4.99/month
- Annual: $3.33/month (amortized)
- Blended ARPU: ~$3.50/month

**Profit margin:**
- Premium user profit: $4.99 - $1.50 = **$3.49/month** (~70% margin)
- At scale (10K MAU, 5% conversion):
  - 500 premium users × $3.50 = **$1,750/month**
  - Costs: ~$1,000/month
  - Net profit: **$750/month**

### Conversion Funnel

```
New User Signup (100%)
        ↓
Free Tier (100%) - Use app, hit limits
        ↓
Upgrade Prompts (when hitting limits)
        ↓
Premium Conversion (5% target)
        ↓
Long-term Retention (92% monthly - 8% churn)
```

**Key conversion triggers:**
1. Daily limit hit (5 generations)
2. Can't save more favorites (10 max)
3. Want meal planning features
4. Need to export/print recipes
5. Want unlimited access

---

## 🎯 Subscription Lifecycle

### 1. Free User Journey

```
Day 1:  Sign up → Free tier
Day 2:  Generate 3 recipes ✓
Day 3:  Generate 5 recipes ✓ (limit reached)
        → "Upgrade for unlimited" dialog shown
Day 4:  Generate 5 more ✓ (counter reset)
Day 7:  Save 10th favorite
        → "Upgrade to save more" dialog shown
```

### 2. Premium Upgrade Journey

```
User clicks "Upgrade Now"
        ↓
Paywall screen (shows pricing)
        ↓
Select plan (monthly or annual)
        ↓
Platform payment (iOS/Android store)
        ↓
Payment successful
        ↓
activateSubscription() called
        ↓
User document updated:
  - subscription.status = "active"
  - subscription.tier = "premium"
  - subscription.expiryDate = +30 days or +365 days
        ↓
User now has unlimited access
```

### 3. Subscription Renewal

**Handled by platform (iOS/Android):**
- Auto-renewal on billing date
- Need to implement webhook to update Firestore
- Check `expiryDate` to detect expired subscriptions

### 4. Cancellation

```dart
// User cancels subscription
await SubscriptionService.cancelSubscription();

// User document updated:
subscription.status = "cancelled"
subscription.cancelledAt = now
subscription.autoRenew = false

// User keeps access until expiryDate
// After expiryDate, reverts to free tier
```

---

## 🔧 Implementation Checklist

### ✅ Completed
- [x] Subscription data models
- [x] Free tier rate limiting (5/day)
- [x] Subscription service
- [x] Recipe generator integration
- [x] Firestore security rules
- [x] Migration utility
- [x] Auto-initialize new signups

### 🚧 To Do
- [ ] **Paywall UI** (subscription selection screen)
- [ ] **In-app purchases** (iOS StoreKit, Android Billing)
- [ ] **Receipt validation** (verify purchases)
- [ ] **Restore purchases** button
- [ ] **Subscription status screen** (view plan, cancel)
- [ ] **Webhook handlers** (for auto-renewal updates)
- [ ] **Trial period** (optional 7-day free trial)
- [ ] **Favorites count tracking** (increment/decrement)
- [ ] **Analytics** (track conversions, revenue)

---

## 📈 Success Metrics

Track these to measure subscription performance:

### Conversion Metrics
- **Free to Premium conversion rate** (target: 5%)
- **Trials to paid conversion** (if implementing trials)
- **Monthly to annual upgrade rate**

### Retention Metrics
- **Monthly churn rate** (target: <8%)
- **Customer lifetime** (target: 18 months)
- **LTV:CAC ratio** (target: 3:1 or better)

### Revenue Metrics
- **MRR** (Monthly Recurring Revenue)
- **ARR** (Annual Recurring Revenue)
- **ARPU** (Average Revenue Per User)
- **Lifetime Value** (LTV)

### Engagement Metrics
- **Generations per user per week**
- **Free users hitting daily limit** (conversion opportunity)
- **Time to first upgrade** (how long before converting)

---

## 🛡️ Security Notes

**Subscription validation happens in two places:**

1. **Client-side** (for UX):
   ```dart
   final canGenerate = await SubscriptionService.canGenerateRecipes();
   ```

2. **Server-side** (in Firestore rules):
   ```javascript
   function isActiveSubscriber(userData) {
     return userData.subscription.status == 'active' &&
            userData.subscription.expiryDate > request.time &&
            userData.subscription.tier in ['premium', 'family'];
   }
   ```

**Never trust client-side checks alone!** Always enforce limits in Firestore security rules and/or Cloud Functions.

---

## 💡 Pro Tips

1. **Make free tier valuable** - Let users get hooked on the product before limiting
2. **Show upgrade prompts at the right moment** - When they hit a limit (not randomly)
3. **Annual discount** - Encourage annual plans for better cash flow and retention
4. **Trial period** - Consider 7-day free trial of Premium to reduce friction
5. **Grandfather existing users** - Give early users a lifetime discount/bonus
6. **Track everything** - Know which features drive conversions
