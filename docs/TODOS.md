# 📋 Lunchbox - Development TODOs

**Last Updated:** December 23, 2025  
**Focus:** Monetization, Payments, Subscription Management & Core Usability

---

## 💰 Business Model Status

| Component | Status | Priority | Revenue Impact |
|-----------|--------|----------|----------------|
| Free Trial (7-day) | ✅ Active | P0 | Entry funnel |
| Subscription Paywall | ✅ Active | P0 | Primary revenue |
| Payment Processing (RevenueCat) | ✅ Live | P0 | Revenue critical |
| Trial Expiration Handling (Firestore) | ⚠️ Partial | **P0** | Conversion blocker |
| Subscription Recovery | ❌ Missing | **P0** | Revenue leak |
| Pricing Page | ❌ Missing | **P0** | Conversion critical |
| Promotional Offers | ❌ Missing | P1 | Acquisition cost |
| Usage Analytics | ✅ Active | P1 | Retention insights |

---

## 📊 Implementation Status Summary

| Feature | Designed | Coded | UI Visible | Revenue Impact |
|---------|----------|-------|------------|----------------|
| Trial Expiration UI | ❌ | ⚠️ | ❌ | **HIGH - Conversion** |
| Subscription Management | ⚠️ | ⚠️ | ⚠️ | **HIGH - Retention** |
| Pricing/Paywall Page | ❌ | ❌ | ❌ | **CRITICAL - Revenue** |
| Payment Error Handling | ❌ | ❌ | ❌ | **HIGH - Revenue leak** |
| Promo Code System | ❌ | ❌ | ❌ | **MEDIUM - Acquisition** |
| Analytics Tracking | ✅ | ✅ | N/A | MEDIUM - Insights |
| Error Handling | ✅ | ✅ | ✅ | MEDIUM - Retention |
| Loading Skeletons | ✅ | ✅ | ✅ | LOW - Polish |
| Offline Caching | ✅ | ✅ | ✅ | MEDIUM - Retention |
| Recipe Feedback | ✅ | ✅ | ✅ | MEDIUM - AI learning |

---

## 🔴 P0 - REVENUE CRITICAL (Do This Week)

### 💳 Subscription & Monetization (Firestore-Based)

- [ ] **Trial Expiration Modal (Hard Paywall)** ⏰ **1-2 hours**
  - Check Firestore `users/{uid}/trialEndDate` field
  - Block all features when trial expires (Firestore-based check)
  - Show: "Your 7-day trial has ended"
  - CTA: "Subscribe to Continue" → Navigate to pricing page
  - Track: trial_expired event
  - **Implementation:** Firestore real-time listener on trial status
  - **Revenue Impact:** Stops free usage, forces conversion decision
  - Files: `lib/services/subscription_service.dart`, `lib/views/trial_expired_modal.dart`
  - **Priority: P0 - Revenue blocker**

- [ ] **Beautiful Pricing/Paywall Page** ⏰ **3-4 hours**
  - Annual plan: $29.99/year (Save 50%)
  - Monthly plan: $4.99/month
  - Feature comparison table
  - Social proof: "Join 10,000+ home cooks"
  - Trust signals: "Cancel anytime • Secure payments"
  - Clear CTA buttons with loading states
  - Show savings calculation for annual
  - **Revenue Impact:** Primary conversion page
  - Files: `lib/views/pricing_page.dart`
  - **Priority: P0 - No revenue without this**

- [ ] **Graceful Payment Error Handling** ⏰ **2 hours**
  - Handle declined cards, network errors
  - Show user-friendly messages (not RevenueCat errors)
  - "Update payment method" button
  - Retry logic with exponential backoff
  - Track: payment_failed, payment_retry events
  - **Revenue Impact:** Prevents revenue loss from temporary failures
  - Files: `lib/services/subscription_service.dart`
  - **Priority: P0 - Stops revenue leaks**

- [ ] **Subscription Management Page** ⏰ **2-3 hours**
  - Read subscription data from Firestore: `users/{uid}/subscription`
  - Show current plan, renewal date, price
  - "Manage Subscription" → App Store/Play Store (RevenueCat)
  - "Cancel Subscription" (with retention modal)
  - Show subscription history from Firestore
  - Handle paused/grace period states
  - **Implementation:** Firestore subscription status + RevenueCat integration
  - **Revenue Impact:** Reduces churn, improves retention
  - Files: `lib/views/subscription_management.dart`
  - **Priority: P0 - Retention critical**

- [ ] **Soft Paywall for Premium Features** ⏰ **1 hour**
  - Store daily usage in Firestore: `users/{uid}/dailyRecipeCount`
  - Free: 3 recipe generations/day
  - Premium: Unlimited generations
  - Show upgrade prompt when limit reached
  - Reset counter daily using Cloud Function or client-side
  - Track: paywall_shown, paywall_dismissed, paywall_converted
  - **Implementation:** Firestore counter + subscription status check
  - **Revenue Impact:** Creates upgrade pressure without blocking trial
  - Files: `lib/services/subscription_service.dart`, update recipe_generator.dart
  - **Priority: P0 - Freemium conversion**

### 📊 Critical Analytics for Revenue

- [ ] **Subscription Funnel Tracking** ⏰ **1 hour**
  - Events: trial_started, paywall_shown, subscribe_initiated, subscribe_completed
  - Track conversion rate at each step
  - A/B test pricing page variations
  - **Revenue Impact:** Identify conversion bottlenecks
  - Files: `lib/services/analytics_service.dart`
  - **Priority: P0 - Can't optimize what you don't measure**

- [ ] **Churn Prevention Analytics** ⏰ **1 hour**
  - Track: last_active_date, recipe_count, favorite_count
  - Identify at-risk users (no activity in 7 days)
  - Trigger re-engagement notifications
  - **Revenue Impact:** Reduces monthly churn
  - Files: `lib/services/analytics_service.dart`
  - **Priority: P0 - Retention = LTV**

### 🎯 Critical Usability (Conversion Blockers)

- [ ] **Onboarding Flow (First-Time User Experience)** ⏰ **3-4 hours**
  - Step 1: Welcome + value prop (3 screens)
  - Step 2: Collect diet preference (required)
  - Step 3: Collect allergies (optional, skippable)
  - Step 4: Trial CTA "Start Your 7-Day Free Trial"
  - Show progress indicator (1/4, 2/4, etc.)
  - **Revenue Impact:** First impression drives trial → subscription
  - Files: `lib/views/onboarding_flow.dart`
  - **Priority: P0 - Entry to revenue funnel**

- [ ] **App Store Optimization Assets** ⏰ **2 hours**
  - Screenshots showing: Recipe cards, fridge management, AI generation
  - Feature graphic with key value props
  - Promo video (30 sec): Problem → Solution → CTA
  - Description with keywords: meal planning, recipe generator, AI chef
  - **Revenue Impact:** Increases organic downloads
  - Files: `ios/screenshots/`, `android/screenshots/`
  - **Priority: P0 - Acquisition critical**

---

## 🟠 P1 - REVENUE OPTIMIZATION (Do This Month)

### 💸 Promotions & Offers

- [ ] **Promo Code System** ⏰ **3-4 hours**
  - Support RevenueCat promo codes
  - UI: "Have a promo code?" field on pricing page
  - Validate and apply discounts
  - Track: promo_applied, promo_invalid events
  - **Revenue Impact:** Enables marketing campaigns, partnerships
  - Files: `lib/services/subscription_service.dart`, update pricing_page.dart
  - **Priority: P1 - Marketing lever**

- [ ] **Winback Offers for Expired Users** ⏰ **2 hours**
  - Show 50% discount to users who canceled
  - Display 3 days after cancellation
  - "We miss you! Come back for 50% off"
  - Track: winback_shown, winback_converted
  - **Revenue Impact:** Recovers churned revenue
  - Files: `lib/services/subscription_service.dart`, `lib/views/winback_modal.dart`
  - **Priority: P1 - Revenue recovery**

- [ ] **Limited-Time Offers (Black Friday, etc.)** ⏰ **2-3 hours**
  - Banner on pricing page: "Save 60% - Ends in 2 days!"
  - Countdown timer
  - Different SKU for promotional pricing
  - **Revenue Impact:** Drives urgency, increases conversions
  - Files: Update pricing_page.dart
  - **Priority: P1 - Seasonal revenue boost**

### Quick Wins (High Impact, Low Effort)

- [ ] **Swipe Gestures (Save/Skip)** ⏰ **1 hour**
  - Swipe right = Save to favorites
  - Swipe left = Skip/dismiss
  - Visual feedback (card tilt, opacity)
  - Haptic feedback
  - **Impact:** More engaging, faster actions
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P2 - Engagement**

- [ ] **Micro-Animations** ⏰ **2 hours**
  - Button scale on press (1.0 → 1.05)
  - Haptic feedback on key actions
  - Card fade-in on generation
  - Save checkmark animation
  - **Impact:** Feels premium, increases perceived quality
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P2 - Polish**

- [ ] **Pull-to-Refresh** ⏰ **30 min**
  - Generate new recipes by pulling down
  - Natural mobile interaction
  - **Impact:** Reduces friction for power users
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P2 - Convenience**

- [ ] **Recent Favorites Quick Access** ⏰ **1-2 hours**
  - Horizontal scroll of top 5 favorites at top
  - Quick tap to view recipe
  - **Impact:** Increases repeat usage, reduces churn
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P2 - Retention**

- [ ] **Copy Ingredients to Clipboard** ⏰ **30 min**
  - Button on recipe card
  - Formatted for easy pasting
  - Toast: "Copied to clipboard!"
  - **Impact:** Quality of life improvement
  - Files: `lib/views/recipe.dart`
  - **Priority: P2 - Utility**

- [ ] **Empty State Illustrations** ⏰ **1 hour**
  - Custom illustrations for: no fridge items, no favorites, no recipes
  - Friendly copy: "Your fridge is empty. Add some ingredients!"
  - **Impact:** More polished, less jarring
  - Files: All views
  - **Priority: P2 - Polish**boost**

### 📧 Re-engagement & Retention

- [ ] **Push Notifications for Trial Users** ⏰ **2 hours**
  - Day 1: "Welcome! Generate your first recipe"
  - Day 3: "You have 4 days left in your trial"
  - Day 6: "Last chance! Trial ends tomorrow"
  - Track: notification_sent, notification_opened, notification_converted
  - **Revenue Impact:** Increases trial engagement → conversion
  - Files: `lib/services/notification_service.dart`
  - **Priority: P1 - Trial conversion lever**

- [ ] **Email Drip Campaign Setup** ⏰ **3 hours**
  - Integrate SendGrid or Mailchimp
  - Trial start: Welcome email
  - Day 3: Feature highlights email
  - Day 6: "Don't lose access" email
  - Post-trial: Winback email (if not subscribed)
  - **Revenue Impact:** Multi-channel increases conversion 20-30%
  - Files: Backend integration, Firebase Cloud Functions
  - **Priority: P1 - Conversion multiplier**

### 🎨 Usability Improvements (Retention)

- [ ] **App Rating Prompt** ⏰ **1 hour**
  - Ask after 3 recipe generations or 1 favorite saved
  - Use `in_app_review` package (native prompts)
  - Don't ask if user already rated
  - Track: rating_prompted, rating_completed
  - **Revenue Impact:** Higher ratings → more downloads
  - Files: `lib/services/rating_service.dart`
  - **Priority: P1 - Organic growth**

- [ ] **Referral Program** ⏰ **4-5 hours**
  - "Invite friends, get 1 month free"
  - Share link with unique referral code
  - Track referrals in Firestore
  - Grant rewards when friend subscribes
  - **Revenue Impact:** Reduces CAC, viral growth
  - Files: `lib/services/referral_service.dart`, `lib/views/referral_page.dart`
  - **Priority: P1 - Acquisition channel**

---

## 🎨 P2 - UX Polish (Elite Experience)

### ⚡ Immediate Activation (Code exists, just needs UI hookup)

- [x] **Activate Quick Meal Buttons (5 min)** ✅ COMPLETE (Dec 23, 2025)
  - Function: `_buildQuickMealButton()` already coded (line 965)
  - Function: `_generateQuickMeal()` already coded (line 90)
  - Function: `_getSuggestedMealType()` already coded (line 101)
  - **Action:** Add button row to recipe_generator.dart UI
  - **Impact:** 80% faster recipe generation (1 click instead of 7)
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P0 - Unlock existing investment**

- [x] **Use Smart Time Defaults (2 min)** ✅ COMPLETE (Dec 23, 2025)
  - Function: `_getSuggestedMealType()` returns context-aware meal type
  - **Action:** Pre-populate modal with time-based suggestion
  - **Impact:** Reduce cognitive load, faster decisions
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P0 - Already coded**

### 🏗️ Toyota Lean (Eliminate Waste)

- [x] **Persistent Preferences** ✅ COMPLETE
  - Save/load diet, allergies, recipe count
  - Eliminates re-entry waste
  
- [x] **Always-Visible Preference Bar** ✅ COMPLETE
  - Shows current diet, allergies, fridge-only mode
  - Edit button for quick changes

- [ ] **Auto-Refresh on Pull-Down**
  - Generate new recipes without tapping button
  - Natural mobile interaction
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P1**

### 🛒 Amazon-Inspired Features

- [x] **Social Proof on Recipe Cards** ✅ COMPLETE (Dec 23, 2025)
  - Add: ⭐ rating, 👥 "X people cooked this"
  - Requires: Analytics for cook count
  - **Action:** Track "made_this" events, display aggregates
  - Files: `lib/views/recipe_generator.dart`, Firestore aggregation
  - **Priority: P1**

- [ ] **Progressive Disclosure (Multi-Step Wizard)**
  - Replace modal with step-by-step flow
  - Step 1: "What are you cooking?" (Breakfast/Lunch/Dinner)
  - Step 2: "Any restrictions?" (I'm good / Customize)
  - **Impact:** Less overwhelming, higher completion rate
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P2**

- [ ] **Recent Favorites Horizontal Scroll**
  - Show top 3-5 favorites at top of page
  - Quick access to tried recipes
  - **Impact:** Increases repeat usage
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P2**

### 📱 TikTok-Inspired Engagement

- [x] **Full-Screen Recipe Cards** ✅ COMPLETE (Dec 23, 2025)
  - Replace small list cards with immersive full-height cards
  - ~70% of screen height
  - Gradient overlay for text readability
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P2**

- [ ] **Swipe Gestures (Save/Skip)**
  - Swipe right = Save to favorites
  - Swipe left = Skip/dismiss
  - Double-tap = Quick save
  - Package: `flutter_swipable` or custom `GestureDetector`
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P2**

- [x] **Vertical Feed Scrolling** ✅ COMPLETE (Dec 23, 2025)
  - TikTok-style one-recipe-per-screen
  - Swipe up/down to browse (using PageView.builder)
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P3**

- [ ] **Micro-Animations**
  - Button scale on press (1.0 → 1.05)
  - Haptic feedback on actions
  - Card fade-in stagger
  - Checkmark burst on save
  - Package: `animated_widgets`, `flutter_animate`
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P2**

- [ ] **"For You" Algorithm Tab**
  - Personalized recipe feed based on analytics
  - Requires: ML model or heuristic scoring
  - Inputs: favorite cuisines, cook frequency, time of day
  - Files: New `for_you_service.dart`, update recipe_generator.dart
  - **Priority: P3 (Phase 3 - Q3 2026)**

---

## 🔴 P0 - Critical (Do Now)

- [x] **Add error handling & retry logic to recipe generation** ✅ COMPLETE (Dec 23, 2025)
  - Users see blank screen on API failures
  - Add user-friendly error messages
  - Add retry button with exponential backoff
  - Files: `lib/views/recipe_generator.dart`, `lib/services/recipe_service.dart`

- [x] **Add loading skeleton/shimmer instead of spinner** ✅ COMPLETE (Dec 23, 2025)
  - Improves perceived performance
  - Key value prop: "Get recipe ideas in seconds"
  - Package: `shimmer: ^3.0.0`

- [x] **Cache generated recipes locally** ✅ COMPLETE (Dec 23, 2025)
  - RFC mentions offline support as key consideration
  - Currently only using SharedPreferences (limited)
  - Consider: `hive` or `sqflite` for structured storage
  - Enable offline recipe viewing

- [x] **Add recipe feedback mechanism (thumbs up/down)** ✅ COMPLETE (Dec 23, 2025)
  - RFC open question: "How to ensure AI-generated recipes are good?"
  - Track to Firestore for future AI improvements
  - Foundation for AI learning feature

---

## 🟠 P1 - High Priority (Q1 2026 Aligned)

- [ ] **Add expiration dates to fridge items**
  - Foundation for "low-stock alerts" in Phase 2
  - Reduces food waste (core value prop)
  - Update Firestore schema: `fridge: [{name, quantity, expirationDate}]`

- [ ] **Persist user preferences (diet/allergies)**
  - Currently re-enter each session
  - Save to Firestore user document
  - Load on app start
  - Files: `lib/views/recipe_generator.dart`

- [ ] **Shopping list generation from recipe**
  - Bridge to Q2 2026 milestone
  - "Add missing ingredients to list" button
  - New page: `lib/views/shopping_list_page.dart`

- [ ] **Recipe rating system (1-5 stars)**
  - Foundation for AI learning (Phase 3)
  - Track recipe success rate KPI
  - Update Firestore: `recipes/{id}/rating`

- [ ] **Push notifications setup**
  - Roadmap shows Q2 2026
  - Add `firebase_messaging` package
  - Notification types: expiring ingredients, meal suggestions

- [ ] **Onboarding flow for new users**
  - No first-time user experience currently
  - Key for hitting 10K users milestone
  - Collect: diet preference, allergies, skill level

- [ ] **Add Firebase Analytics events**
  - Can't measure KPIs without tracking
  - Events: recipe_generated, recipe_saved, fridge_item_added
  - Track session duration, feature usage

### Fridge Feature Improvements (Phase 1 Enhancement - PRIORITIZED)

- [ ] **Quick add mode for fridge items (simplified entry)**
  - Streamline the add dialog: just name + quantity (optional unit)
  - One-tap category auto-detection or default to "Other"
  - Skip expiry date initially (optional for later)
  - Goal: Add items in <5 seconds
  - **Impact:** Removes friction barrier to keeping fridge updated
  - Files: `lib/views/myfridge_page.dart`, update dialog logic
  - **Priority: P0 - Implement First**

- [ ] **Barcode scanning integration**
  - Add `barcode_scan2` package for iOS/Android
  - Scan barcodes to auto-populate fridge items
  - Lookup item name + category from barcode database (optional: integrate OpenFoodFacts API)
  - New floating action button: **Scan** vs. **Add Manual** (Quick Add)
  - **Phase 2 bridge:** Leads to automated inventory management
  - Files: `lib/views/myfridge_page.dart`, new service: `barcode_service.dart`
  - **Priority: P0 - Implement Second**

- [ ] **OCR detection from pictures (image intake)**
  - Add camera/gallery picker to detect ingredients from photos
  - Use `google_mlkit_text_recognition` (ML Kit Text Recognition) or `tesseract` for OCR
  - Flow: Take photo of grocery receipt/ingredients → Extract text → Parse ingredient names
  - Auto-populate fridge with detected items (user confirms/edits)
  - Alternative: Photo of fridge contents for batch inventory
  - **Impact:** Massive UX improvement - users snap a photo instead of typing
  - Files: `lib/views/myfridge_page.dart`, new service: `ocr_service.dart`
  - Packages: `image_picker`, `google_mlkit_text_recognition`, `flutter_vision`
  - **Priority: P0 - Implement Third (after barcode works)**

- [ ] **Implement category organization for fridge items**
  - Organize by: Produce, Proteins, Dairy, Pantry, Other
  - Add category icon & color coding
  - Visual delight + constraint clarity for recipe generation
  - Update Firestore schema: `fridge: [{name, quantity, unit, category, expiryDate}]`
  - � P3 - Future Features (Q2+ 2026)

### Advanced Features

- [ ] **Recipe rating system (1-5 stars)**
  - Foundation for AI learning
  - Track recipe success rate KPI
  - Update Firestore: `recipes/{id}/rating`
  - **Priority: P3**

- [ ] **Shopping list generation from recipe**
  - "Add missing ingredients to list" button
  - New page: `lib/views/shopping_list_page.dart`
  - **Priority: P3**

- [ ] **Expiration date tracking**
  - Add to fridge items
  - Low-stock alerts
  - Update Firestore schema
  - **Priority: P3**

- [ ] **"For You" Algorithm Tab**
  - Personalized recipe feed
  - ML model or heuristic scoring
  - Based on favorites, cuisine preferences
  - **Priority: P3 - Phase 3**

- [ ] **Progressive Disclosure Wizard**
  - Multi-step recipe generation
  - Less overwhelming UI
  - Step 1: Meal type, Step 2: Restrictions
  - **Priority: P3**re
  - Won't scale for meal planning feature
  - Improves testability

- [ ] **Unit tests for services**
  - Zero tests currently
  - Start with `recipe_service.dart`
  - Add GitHub Actions CILower Priority)

- [ ] **Quick add mode for fridge items** ⏰ **1 hour**
  - Streamline dialog: name + quantity only
  - Skip category, expiry initially
  - Goal: Add items in <5 seconds
  - Files: `lib/views/myfridge_page.dart`
  - **Priority: P3 - Nice to have**

- [ ] **Barcode scanning integration** ⏰ **3-4 hours**
  - Scan barcodes to auto-populate items
  - OpenFoodFacts API integration
  - **Revenue Impact:** Premium feature upsell opportunity
  - Files: `lib/views/myfridge_page.dart`, `barcode_service.dart`
  - **Priority: P3 - Premium feature**

- [ ] **OCR from receipt photos** ⏰ **4-5 hours**
  - Photo → Extract ingredients → Auto-add
  - ML Kit Text Recognition
  - **Revenue Impact:** Premium feature
  - Files: `lib/views/myfridge_page.dart`, `ocr_service.dart`
  - **Priority: P3 - Premium feature**

- [ ] **Category organization**
  - Organize by: Produce, Proteins, Dairy, Pantry
  - Color coding and icons
  - Files: `lib/views/myfridge_page.dart`
  - **Priority: P3**

- [ ] **Smart search & filter**
  - Real-time search by name
  - Filter by category
  - Files: `lib/views/myfridge_page.dart`
  - **Priority: P3dart`

### 🎯 Next Steps (Use the Data!)

- [ ] **Build Analytics Dashboard**
  - Query Firestore to show:
    - Top 3 favorite cuisines
    - Most common diet selection
    - Average recipe count preference
    - Generation success rate (favorites / recipes generated)
  - New page: `lib/views/analytics_dashboard.dart`
  - **Priority: P1 - Q1 2026**

- [ ] **Smart Defaults Based on History**
  - Auto-select user's most common diet
  - Pre-populate recipe count based on past selections
  - Suggest "Fridge Only" if low on ingredients
  - **Action:** Query last 10 generations, calculate mode
  - Files: `lib/views/recipe_generator.dart`
  - **Priority: P1 - Q1 2026**

- [ ] **Ingredient Intelligence**
  - Show: "Chicken appears in 70% of your generations"
  - SuRevenue Metrics & KPIs to Track

### Critical Metrics (Week 1)
- [ ] Trial → Paid conversion rate (Target: 20-30%)
- [ ] Monthly churn rate (Target: <5%)
- [ ] Average revenue per user (ARPU)
- [ ] Daily active users (DAU)
- [ ] Trial drop-off points (where users leave)

### Growth Metrics (Month 1)
- [ ] Customer acquisition cost (CAC)
- [ ] Lifetime value (LTV)
- [ ] LTV:CAC ratio (Target: >3:1)
- [ ] Organic vs paid installs
- [ ] App Store conversion rate

### Engagement Metrics
- [ ] Recipes generated per user
- [ ] Session duration
- [ ] Feature adoption rates
- [ ] Favorites saved per user
- [ ] Days since last activity

---

## ✅ Completed Features

- [x] **Error handling & retry logic** ✅ (Dec 23, 2025)
- [x] **Shimmer loading skeleton** ✅ (Dec 23, 2025)
- [x] **Hive caching for offline** ✅ (Dec 23, 2025)
- [x] **Recipe feedback (thumbs)** ✅ (Dec 23, 2025)
- [x] **Quick Meal Buttons** ✅ (Dec 23, 2025)
- [x] **Smart Time Defaults** ✅ (Dec 23, 2025)
- [x] **Social Proof** ✅ (Dec 23, 2025)
- [x] **Full-Screen TikTok Cards** ✅ (Dec 23, 2025)
- [x] **Vertical Feed Scrolling** ✅ (Dec 23, 2025)
- [x] **Analytics Tracking (Phase 1 & 2)** ✅ (Dec 22, 2025)
- [x] **Persistent Preferences** ✅
- [x] **Preference Bar** ✅
  - Test: pricing page variations, trial length, onboarding flow
  - Track conversion rates
  - **Revenue Impact:** Data-driven optimization
  - **Priority: P1 - Optimization critical**

- [ ] **Crash Reporting (Firebase Crashlytics)** ⏰ **1 hour**
  - Automatic crash reporting
  - Track app stability
  - **Revenue Impact:** Prevents revenue loss from crashes
  - **Priority: P1 - Reliability**

- [ ] **Performance Monitoring** ⏰ **1 hour**
  - Firebase Performance
  - Track: recipe generation time, page load times
  - **Revenue Impact:** Slow app = higher churn
  -🗓️ Recommended Sprint Plan (Revenue-First)

### 🔴 SPRINT 1 - Revenue Foundation (This Week)
**Goal:** Enable revenue generation & prevent leaks
1. [ ] Trial expiration modal (hard paywall)
2. [ ] Beautiful pricing/paywall page
3. [ ] Payment error handling
4. [ ] Subscription management page
5. [ ] Subscription funnel analytics
6. [ ] Crash reporting (Crashlytics)

**Success Metrics:** Can convert trials → paid subscribers

### 🟠 SPRINT 2 - Conversion Optimization (Week 2)
**Goal:** Improve conversion rates & reduce churn
1. [ ] Onboarding flow (3-4 screens)
2. [ ] Soft paywall (generation limits)
3. [ ] Push notifications for trial users
4. [ ] App rating prompt
5. [ ] Churn prevention analytics
6. [ ] A/B testing infrastructure

**Success Metrics:** 20%+ trial conversion rate

### 🟡 SPRINT 3 - Growth & Retention (Week 3-4)
**Goal:** Drive organic growth & reduce churn
1. [ ] Promo code system
2. [ ] Winback offers for churned users
3. [ ] Referral program
4. [ ] App Store optimization
5. [ ] Email drip campaign setup
6. [ ] Performance monitoring

**Success Metrics:** <5% monthly churn, 10% viral coefficient

### 🟢 SPRINT 4 - UX Polish (Week 5+)
**Goal:** Improve retention through delight
1. [ ] Swipe gestures (save/skip)
2. [ ] Micro-animations
3. [ ] Recent favorites quick access
4. [ ] Pull-to-refresh
5. [ ]Technical Notes

- Backend streaming is deployed ✅
- Fastest Gemini model selection ✅
- Parallel Firestore queries ✅
- RevenueCat SDK integrated ✅
- Free trial system active (Firestore-based) ✅
- Trial expiration handled via Firestore fields ✅
- Analytics tracking (Phase 1 & 2) ✅
- All P0 features from previous sprint ✅

### Subscription Architecture
- **Trial Management:** Firestore `users/{uid}/trialEndDate` field
- **Subscription Status:** Firestore `users/{uid}/subscription` document
- **Payment Processing:** RevenueCat (syncs to Firestore via webhooks)
- **Daily Limits:** Firestore `users/{uid}/dailyRecipeCount` counter
- **Why Firestore:** Real-time sync, offline support, simpler client logic

---

## 💡 Revenue Optimization Ideas (Future)

### Pricing Experiments
- [ ] Test $3.99/month vs $4.99/month
- [ ] Test annual discount: 40% vs 50% vs 60%
- [ ] Test trial length: 3-day vs 7-day vs 14-day
- [ ] Family plan: $39.99/year for 5 users

### Premium Features to Gate
- [ ] Unlimited recipe generations (vs 3/day free)
- [ ] Save unlimited favorites (vs 10 free)
- [ ] Barcode scanning
- [ ] OCR from photos
- [ ] AI-generated shopping lists
- [ ] Export recipes to PDF
- [ ] Meal planning calendar

### Promotional Strategies
- [ ] First-month discount for annual (50% off)
- [ ] Student discount (30% off)
- [ ] Black Friday/Cyber Monday (60% off)
- [ ] Influencer promo codes
- [ ] Bundle with partner apps

---

## 🎯 Success Criteria (This Month)

### Revenue Targets
- [ ] 100+ paid subscribers
- [ ] 20%+ trial → paid conversion
- [ ] <5% monthly churn
- [ ] $500+ MRR (Monthly Recurring Revenue)

### Product Metrics
- [ ] 4.5+ star rating on App Store
- [ ] <1% crash rate
- [ ] <3 sec recipe generation time
- [ ] 80%+ onboarding completion

### Growth Metrics
- [ ] 1,000+ trial starts
- [ ] 50+ organic installs/day
- [ ] 10%+ viral coefficient (referrals)

---

## 🚀 THIS WEEK'S PRIORITIES (Revenue Critical - Firestore Implementation)

1. **Trial Expiration Modal** (2 hours) - Firestore-based expiration check ⚠️
2. **Pricing Page** (4 hours) - Enable conversions ⚠️
3. **Payment Error Handling** (2 hours) - Stop revenue leaks ⚠️
4. **Subscription Management** (3 hours) - Firestore subscription display ⚠️
5. **Funnel Analytics** (1 hour) - Measure conversion ⚠️
6. **Onboarding Flow** (4 hours) - Improve first impression ⚠️

**Total: ~16 hours = 2 days of focused work**

**Architecture Note:** All trial/subscription status checks use Firestore for real-time sync. RevenueCat handles payments and syncs to Firestore via webhooks.

---

*Updated Dec 23, 2025 - Focus: Monetization & Growth (Firestore-Based)*