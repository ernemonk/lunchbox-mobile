import 'package:flutter/material.dart';

/// App-wide color constants for consistent theming.
/// 
/// # Lunchbox Color Philosophy
/// 
/// The color scheme is designed around three core principles:
/// 
/// 1. **Appetite Appeal** - Warm oranges stimulate hunger and action
/// 2. **Freshness** - Greens represent fresh ingredients and health
/// 3. **Warmth** - Cream backgrounds create a cozy, home-cooking feel
/// 
/// ## Color Psychology
/// - **Coral/Orange**: Energetic, appetizing, friendly, action-oriented
/// - **Sage Green**: Fresh, healthy, sustainable, calming
/// - **Warm Neutrals**: Inviting, clean, readable, homey
/// 
/// ## Usage
/// ```dart
/// import 'package:lunchbox/core/constants/app_colors.dart';
/// 
/// Container(color: AppColors.primary) // Coral orange
/// Container(color: AppColors.secondary) // Sage green
/// ```
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================
  // 🍊 PRIMARY COLORS - Coral Orange (Appetite & Action)
  // ============================================================
  
  /// Main brand color - Coral Orange
  /// Stimulates appetite, conveys warmth and friendliness
  static const Color primary = Color(0xFFFF6B4A);
  
  /// Light coral - for backgrounds, hover states
  static const Color primaryLight = Color(0xFFFFE5DF);
  
  /// Medium coral - for secondary elements
  static const Color primaryMedium = Color(0xFFFF8A70);
  
  /// Dark coral - for emphasis, pressed states
  static const Color primaryDark = Color(0xFFE54D2E);

  // ============================================================
  // 🥬 SECONDARY COLORS - Sage Green (Fresh & Healthy)
  // ============================================================
  
  /// Secondary color - Sage Green
  /// Represents freshness, health, and sustainability
  static const Color secondary = Color(0xFF4CAF50);
  
  /// Light sage - for success backgrounds
  static const Color secondaryLight = Color(0xFFE8F5E9);
  
  /// Medium sage - for badges, tags
  static const Color secondaryMedium = Color(0xFF81C784);
  
  /// Dark sage - for emphasis
  static const Color secondaryDark = Color(0xFF388E3C);

  // ============================================================
  // 🍯 ACCENT COLORS - Warm Amber (Favorites & Highlights)
  // ============================================================
  
  /// Accent color - Honey Amber
  /// For favorites, stars, special highlights
  static const Color accent = Color(0xFFFFB74D);
  
  /// Light amber
  static const Color accentLight = Color(0xFFFFF3E0);
  
  /// Dark amber
  static const Color accentDark = Color(0xFFF57C00);

  // ============================================================
  // 🏠 BACKGROUND COLORS - Warm & Inviting
  // ============================================================
  
  /// Main background - Warm White
  static const Color background = Color(0xFFFFFBF8);
  
  /// Pure white - for cards, dialogs
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Light cream - for subtle sections
  static const Color surfaceLight = Color(0xFFFAF7F5);
  
  /// Scaffold background - slight warmth
  static const Color scaffoldBackground = Color(0xFFFFFCFA);

  // ============================================================
  // ✏️ TEXT COLORS - Readable & Warm
  // ============================================================
  
  /// Primary text - Warm Charcoal (not pure black)
  static const Color textPrimary = Color(0xFF2D2A26);
  
  /// Secondary text - Warm Gray
  static const Color textSecondary = Color(0xFF6B6560);
  
  /// Disabled/hint text
  static const Color textDisabled = Color(0xFFB5AFA8);
  
  /// Text on primary color (coral)
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// Text on secondary color (green)
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // ============================================================
  // 🚦 SEMANTIC COLORS - Status & Feedback
  // ============================================================
  
  /// Success - Fresh Green
  static const Color success = Color(0xFF4CAF50);
  
  /// Warning - Warm Amber
  static const Color warning = Color(0xFFFF9800);
  
  /// Error - Tomato Red
  static const Color error = Color(0xFFE53935);
  
  /// Info - Sky Blue
  static const Color info = Color(0xFF29B6F6);

  // ============================================================
  // 🎨 UI ELEMENT COLORS
  // ============================================================
  
  /// Border color - Soft warm gray
  static const Color border = Color(0xFFE8E4E0);
  
  /// Divider color
  static const Color divider = Color(0xFFEDE9E5);
  
  /// Icon color - Warm gray
  static const Color icon = Color(0xFF6B6560);
  
  /// Icon on primary background
  static const Color iconOnPrimary = Color(0xFFFFFFFF);
  
  /// Shimmer/skeleton loading
  static const Color shimmer = Color(0xFFF0ECE8);

  // ============================================================
  // 🧭 NAVIGATION COLORS
  // ============================================================
  
  /// Selected navigation item - uses primary
  static const Color navSelected = primary;
  
  /// Unselected navigation item
  static const Color navUnselected = Color(0xFF9E9892);
  
  /// Navigation bar background
  static const Color navBackground = Color(0xFFFFFFFF);

  // ============================================================
  // 🍽️ RECIPE/FOOD THEME COLORS
  // ============================================================
  
  /// Favorite star - Honey gold
  static const Color favorite = Color(0xFFFFB74D);
  
  /// Recipe card background
  static const Color recipeCard = Color(0xFFFFFFFF);
  
  /// Recipe card accent border
  static const Color recipeAccent = primaryLight;
  
  /// Ingredient chip background
  static const Color ingredientChip = Color(0xFFFFE5DF);
  
  /// Ingredient chip text
  static const Color ingredientChipText = Color(0xFFE54D2E);
  
  /// Diet tag colors
  static const Color dietVegan = Color(0xFF4CAF50);
  static const Color dietKeto = Color(0xFF9C27B0);
  static const Color dietVegetarian = Color(0xFF8BC34A);

  // ============================================================
  // 🌅 GRADIENT COLORS - For Auth & Special Screens
  // ============================================================
  
  /// Gradient start - Warm peach
  static const Color gradientStart = Color(0xFFFFD4C4);
  
  /// Gradient middle - Soft coral
  static const Color gradientMiddle = Color(0xFFFFAB91);
  
  /// Gradient end - Light coral
  static const Color gradientEnd = Color(0xFFFF8A70);

  // ============================================================
  // 🛠️ HELPER METHODS
  // ============================================================
  
  /// Primary color with opacity
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  
  /// Secondary color with opacity
  static Color secondaryWithOpacity(double opacity) => secondary.withOpacity(opacity);

  /// Get MaterialColor swatch from primary
  static MaterialColor get primarySwatch => MaterialColor(
    primary.value,
    const <int, Color>{
      50: Color(0xFFFFE5DF),
      100: Color(0xFFFFCDBF),
      200: Color(0xFFFFAB9A),
      300: Color(0xFFFF8A70),
      400: Color(0xFFFF7A5C),
      500: Color(0xFFFF6B4A),
      600: Color(0xFFE54D2E),
      700: Color(0xFFCC3D20),
      800: Color(0xFFB32D12),
      900: Color(0xFF8C1D06),
    },
  );
}

