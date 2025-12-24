/// Views barrel file - exports all page/screen widgets
/// 
/// Usage: import 'package:lunchbox/views/views.dart';
/// 
/// Available views:
/// 
/// Authentication:
/// - LoginPage: User login screen
/// - SignupPage: User registration screen
/// 
/// Main Navigation:
/// - MyHomePage: Main navigation hub with bottom nav
/// - RecipeGeneratorPage (UserPreferencesPage): AI recipe generation
/// - FavoritesPage: Saved recipes list
/// - MyFridgePage: Fridge inventory management
/// - SettingsPage: User settings and account management
/// 
/// Recipe:
/// - RecipeViewerPage: Individual recipe display
/// 
/// Subscription:
/// - SubscriptionPage: Subscription management and free trial
/// 
/// Admin:
/// - TweakTheAIPage: AI prompt management (admin only)
/// 
/// Legal:
/// - PrivacyPolicyPage: Privacy policy display
library;

// Authentication
export 'login_page.dart';
export 'signup_page.dart';

// Main Navigation
export 'home_page.dart';
export 'recipe_generator.dart';
export 'favorites_page.dart';
export 'myfridge_page.dart';
export 'settings_page.dart';

// Recipe
export 'recipe.dart';

// Subscription
export 'subscription_page.dart';

// Admin
export 'tweak_the_ai.dart';

// Legal
export 'privacy_policy.dart';
