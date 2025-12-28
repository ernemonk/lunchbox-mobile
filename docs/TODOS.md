# 📋 Lunchbox - Development TODOs

**Last Updated:** December 23, 2025  
**Focus:** Revenue Generation → Sustainability

---

## 🚨 CRITICAL PATH: Revenue or Die

**Current Situation:**
- Revenue: $0/month
- Costs at 10K MAU: $6,300/month ($75,600/year)
- **Runway Risk:** Q3 2026 shutdown without monetization

**Mission Critical:** Launch freemium model by January 15, 2026

---

## 🔴 P0 - REVENUE BLOCKERS (Launch by Jan 15, 2026)

### 💳 Payment Integration (Week 1-2)

- [ ] **Install RevenueCat SDK** ⏰ 2 hours
  - Add `purchases_flutter: ^6.0.0` to pubspec.yaml
  - Configure iOS/Android API keys
  - Initialize in main.dart
  - Test SDK initialization
  - Files: `pubspec.yaml`, `lib/main.dart`
  - **Priority: P0 - No revenue without this**

- [ ] **Configure App Store Connect (iOS)** ⏰ 4 hours
  - Create in-app purchase products
  - Monthly: $4.99/month (lunchbox_premium_monthly)
  - Annual: $29.99/year (lunchbox_premium_annual)
  - Configure auto-renewable subscriptions
  - Add App Store localized descriptions
  - Submit for review
  - **Priority: P0 - iOS revenue critical**

- [ ] **Configure Google Play Console (Android)** ⏰ 4 hours
  - Create subscription products
  - Monthly: $4.99/month (lunchbox_premium_monthly)
  - Annual: $29.99/year (lunchbox_premium_annual)
  - Set up billing
  - Add localized descriptions
  - Submit for review
  - **Priority: P0 - Android revenue critical**

- [ ] **Create Pricing Page UI** ⏰ 6-8 hours
  - Beautiful card-based pricing comparison
  - Annual plan: "Save 50%" badge
  - Monthly plan: "Most Flexible" badge
  - Feature comparison table (Free vs Premium)
  - Social proof: "Join 10,000+ home cooks"
  - Trust signals: "Cancel anytime • Secure payments"
  - Loading states for purchase flow
  - Error handling for payment failures
  - Files: `lib/views/pricing_page.dart`
  - **Priority: P0 - Primary conversion page**

- [ ] **Implement Purchase Flow** ⏰ 4 hours
  - Connect pricing page to RevenueCat
  - Handle purchase initiation
  - Process receipt validation
  - Update Firestore subscription status
  - Show success/error feedback
  - Track analytics: purchase_initiated, purchase_completed
  - Files: `lib/services/subscription_service.dart`
  - **Priority: P0 - Revenue flow**

- [ ] **Payment Error Handling** ⏰ 2 hours
  - Handle declined cards gracefully
  - Network error retry with exponential backoff
  - "Update payment method" flow
  - User-friendly error messages (not RevenueCat codes)
  - Track: payment_failed, payment_retry events
  - **Priority: P0 - Prevents revenue leaks**

### 🚧 Paywall Implementation (Week 2)

- [ ] **Trial Expiration Modal (Hard Paywall)** ⏰ 2 hours
  - Check Firestore `users/{uid}/trialEndDate`
  - Block all features when trial expires
  - Modal: "Your 7-day trial has ended"
  - CTA: "Subscribe to Continue" → Navigate to pricing
  - Track: trial_expired event
  - Files: `lib/views/trial_expired_modal.dart`
  - **Priority: P0 - Stops free usage**

- [ ] **Soft Paywall for Recipe Generation** ⏰ 2 hours
  - Implement daily limit: 3 generations for free users
  - Store counter in Firestore: `users/{uid}/dailyRecipeCount`
  - Reset counter at midnight (Cloud Function or client-side)
  - Show upgrade modal when limit hit
  - Track: paywall_shown, paywall_dismissed, paywall_converted
  - Files: Update `lib/views/recipe_generator/recipe_generator_page.dart`
  - **Priority: P0 - Freemium pressure**

- [ ] **Subscription Management Page** ⏰ 3 hours
  - Read from Firestore: `users/{uid}/subscription`
  - Display: Current plan, renewal date, price
  - "Manage Subscription" → App Store/Play Store
  - "Cancel Subscription" with retention modal
  - Show subscription history
  - Handle paused/grace period states
  - Files: `lib/views/subscription_management_page.dart`
  - **Priority: P0 - Retention critical**

### 📊 Analytics & Tracking (Week 2-3)

- [ ] **Subscription Funnel Events** ⏰ 2 hours
  - Events: trial_started, paywall_shown, subscribe_initiated, subscribe_completed
  - Track conversion rate at each step
  - Revenue per user
  - Files: `lib/services/analytics_service.dart`
  - **Priority: P0 - Can't optimize blindly**

- [ ] **Churn Analytics** ⏰ 1 hour
  - Track: last_active_date, recipe_count, favorite_count
  - Identify at-risk users (no activity 7+ days)
  - Cancellation reasons
  - **Priority: P0 - Retention = LTV**

### 🎯 Onboarding & Conversion (Week 3)

- [ ] **Onboarding Flow (First-Time Users)** ⏰ 4 hours
  - Screen 1: Welcome + value prop
  - Screen 2: Collect diet preference (required)
  - Screen 3: Collect allergies (optional, skippable)
  - Screen 4: "Start Your 7-Day Free Trial" CTA
  - Progress indicator (1/4, 2/4, etc.)
  - Track: onboarding_started, onboarding_completed, onboarding_abandoned
  - Files: `lib/views/onboarding_flow.dart`
  - **Priority: P0 - Entry to funnel**

- [ ] **Update Navigation for Pricing** ⏰ 30 min
  - Add "Upgrade" button to settings
  - Show "Premium" badge on locked features
  - Deep link to pricing page
  - Files: `lib/views/settings_page.dart`
  - **Priority: P0 - Discovery**

---

## 🟠 P1 - REVENUE OPTIMIZATION (Month 2)

### 💸 Promotional Features

- [ ] **Promo Code System** ⏰ 3 hours
  - RevenueCat promo code support
  - UI field on pricing page: "Have a promo code?"
  - Validate and apply discounts
  - Track: promo_applied, promo_invalid
  - **Impact:** Marketing campaigns, partnerships

- [ ] **Winback Offers** ⏰ 2 hours
  - Detect churned users
  - Show 50% discount 3 days after cancellation
  - "We miss you! Come back for 50% off"
  - Track: winback_shown, winback_converted
  - **Impact:** Revenue recovery

- [ ] **Limited-Time Offers** ⏰ 2 hours
  - Banner: "Save 60% - Ends in 2 days!"
  - Countdown timer
  - Different SKU for promotional pricing
  - **Impact:** Urgency, higher conversions

### 📧 Re-engagement

- [ ] **Push Notifications** ⏰ 3 hours
  - Day 1: "Welcome! Generate your first recipe"
  - Day 3: "You have 4 days left in your trial"
  - Day 6: "Last chance! Trial ends tomorrow"
  - Package: `firebase_messaging`
  - Track: notification_sent, notification_opened
  - **Impact:** Trial conversion +20-30%

- [ ] **Email Drip Campaign** ⏰ 4 hours
  - Integrate SendGrid/Mailchimp
  - Trial start: Welcome email
  - Day 3: Feature highlights
  - Day 6: "Don't lose access"
  - Post-trial: Winback email
  - **Impact:** Multi-channel conversion

### 🎨 Conversion Optimization

- [ ] **App Rating Prompt** ⏰ 1 hour
  - Ask after 3 recipe generations or 1 favorite
  - Use `in_app_review` package
  - Don't ask if already rated
  - Track: rating_prompted, rating_completed
  - **Impact:** Higher ratings → more downloads

- [ ] **Referral Program** ⏰ 5 hours
  - "Invite friends, get 1 month free"
  - Share link with unique code
  - Track referrals in Firestore
  - Grant rewards when friend subscribes
  - **Impact:** Viral growth, lower CAC

---

## 🟡 P2 - UX POLISH & RETENTION

### ⚡ Quick Wins

- [x] **Quick Meal Buttons** ✅ COMPLETE (Dec 23, 2025)
  - Time-based suggestions (Breakfast/Lunch/Dinner)
  - Use Fridge mode
  - Surprise Me
  - Customize modal

- [x] **Improved Customize Modal** ✅ COMPLETE (Dec 23, 2025)
  - Modern card-based sections
  - Better visual hierarchy
  - Cleaner spacing and icons

- [ ] **Pull-to-Refresh** ⏰ 30 min
  - Generate new recipes by pulling down
  - Natural mobile interaction
  - Files: `lib/views/recipe_generator/recipe_generator_page.dart`

- [ ] **Swipe Gestures (Save/Skip)** ⏰ 2 hours
  - Swipe right = Save to favorites
  - Swipe left = Skip/dismiss
  - Visual feedback (card tilt, opacity)
  - Haptic feedback
  - **Impact:** More engaging UX

- [ ] **Micro-Animations** ⏰ 2 hours
  - Button scale on press (1.0 → 1.05)
  - Card fade-in on generation
  - Save checkmark animation
  - Haptic feedback on actions
  - **Impact:** Premium feel

- [ ] **Recent Favorites Quick Access** ⏰ 2 hours
  - Horizontal scroll of top 5 favorites
  - At top of recipe generator
  - Quick tap to view
  - **Impact:** Repeat usage, less churn

- [ ] **Copy Ingredients to Clipboard** ⏰ 30 min
  - Button on recipe viewer
  - Formatted for pasting
  - Toast: "Copied to clipboard!"
  - **Impact:** Utility improvement

### 📱 Advanced Features (Phase 2)

- [ ] **Shopping List Generation** ⏰ 4 hours
  - "Add missing ingredients to list" button
  - Compare recipe ingredients vs fridge
  - New page: `lib/views/shopping_list_page.dart`
  - **Impact:** Bridge to Q2 2026 milestone

- [ ] **Recipe Rating System (1-5 stars)** ⏰ 3 hours
  - Star rating UI on recipe cards
  - Track in Firestore: `recipes/{id}/rating`
  - Foundation for AI learning
  - **Impact:** Recipe quality KPIs

- [ ] **Expiration Date Tracking** ⏰ 3 hours
  - Add to fridge items
  - Low-stock alerts
  - "Use soon" badge on expiring items
  - **Impact:** Reduce food waste

- [ ] **Category Organization (Fridge)** ⏰ 2 hours
  - Organize by: Produce, Proteins, Dairy, Pantry
  - Color coding and icons
  - Filter by category
  - **Impact:** Better UX

---

## 🟢 P3 - FUTURE ENHANCEMENTS (Q2 2026+)

### 🤖 AI Improvements

- [ ] **"For You" Algorithm**
  - Personalized feed based on favorites
  - ML model for recommendations
  - Inputs: cuisine preferences, cook frequency, time of day

- [ ] **Voice Input for Recipes**
  - "Hey Lunchbox, what can I make with chicken?"
  - Voice-to-text recipe generation

### 📊 Analytics Dashboard

- [ ] **User Analytics Page**
  - Top 3 favorite cuisines
  - Most common diet selection
  - Generation success rate
  - Waste reduction metrics

### 🛠️ Infrastructure

- [ ] **Performance Monitoring** ⏰ 1 hour
  - Firebase Performance
  - Track: recipe generation time, page loads
  - **Impact:** Slow app = churn

- [ ] **Crash Reporting** ⏰ 1 hour
  - Firebase Crashlytics already integrated
  - Add custom crash tags
  - Track stability metrics

- [ ] **A/B Testing Infrastructure** ⏰ 3 hours
  - Firebase Remote Config
  - Test: pricing page variations, trial lengths
  - Track conversion rates
  - **Impact:** Data-driven optimization

---

## 📅 Sprint Plan (4 Weeks to Launch)

### Week 1: Payment Foundation
- [ ] RevenueCat SDK setup
- [ ] App Store Connect configuration
- [ ] Google Play Console configuration
- [ ] Pricing page UI
- **Deliverable:** Can process payments

### Week 2: Paywall & Limits
- [ ] Trial expiration modal
- [ ] Daily generation limits (soft paywall)
- [ ] Purchase flow implementation
- [ ] Payment error handling
- **Deliverable:** Revenue flow active

### Week 3: Conversion Optimization
- [ ] Onboarding flow
- [ ] Subscription management page
- [ ] Analytics events
- [ ] Navigation updates
- **Deliverable:** Funnel optimized

### Week 4: Testing & Polish
- [ ] End-to-end purchase testing
- [ ] Edge case handling
- [ ] App Store submission
- [ ] Play Store submission
- **Deliverable:** LIVE in production

---

## 💰 Success Metrics (Month 1)

| Metric | Target |
|--------|--------|
| Trial Starts | 1,000+ |
| Trial → Paid Conversion | 5%+ |
| Monthly Churn | <5% |
| MRR | $2,500+ |
| Daily Active Users | 300+ |
| Recipe Generations | 10,000+ |

---

## 🎯 Break-Even Math

**Costs at Scale:**
- 10K MAU = $6,300/month
- Cost per user = $0.63/month

**Revenue Needed:**
- Need: 2,000 paid users @ $2.50 avg = $5,000/month
- At 5% conversion from 10K MAU = 500 paid users
- **Gap:** Need 20K MAU to break even OR 10% conversion

**Strategy:** Focus on conversion optimization (10% is achievable)

---

## ✅ Recently Completed

- [x] Quick Meal Buttons (Dec 23, 2025)
- [x] Time-based meal suggestions (Dec 23, 2025)
- [x] Customize modal redesign (Dec 23, 2025)
- [x] Barcode scanning (Dec 22, 2025)
- [x] OCR ingredient detection (Dec 22, 2025)
- [x] Shimmer loading states (Dec 21, 2025)
- [x] Error handling & retry logic (Dec 21, 2025)
- [x] Hive caching (Dec 21, 2025)
- [x] Recipe feedback system (Dec 21, 2025)
- [x] Subscription backend service (Dec 20, 2025)
- [x] Firebase security rules (Dec 20, 2025)

---

**Next Action:** Start Week 1 - RevenueCat SDK installation
**Deadline:** January 15, 2026
**Risk Level:** 🔴 CRITICAL - Revenue or shutdown Q3 2026
