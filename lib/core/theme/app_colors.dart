import 'package:flutter/material.dart';

/// 🎨 Lunchbox Color Scheme
/// 
/// Food-oriented palette designed to:
/// - Stimulate appetite (warm oranges/reds)
/// - Convey freshness (vibrant greens)
/// - Feel inviting and accessible
/// - Support the "delicious, personalized meals" vision
/// 
/// Based on food psychology:
/// - Red/Orange: Increases appetite, creates warmth
/// - Green: Represents health, freshness, vegetables
/// - Cream: Clean, approachable, comfortable

class AppColors {
  // 🍅 Primary Colors - Appetite & Energy
  static const Color primary = Color(0xFFFF6B6B);        // Tomato Red
  static const Color primaryLight = Color(0xFFFF9F9F);   // Light Coral
  static const Color primaryDark = Color(0xFFE63946);    // Deep Red
  
  // 🥗 Secondary Colors - Health & Freshness  
  static const Color secondary = Color(0xFF51CF66);      // Fresh Green
  static const Color secondaryLight = Color(0xFF8CE99A); // Mint Green
  static const Color secondaryDark = Color(0xFF37B24D);  // Deep Green
  
  // 🍊 Accent Colors - Warmth & Comfort
  static const Color accent = Color(0xFFFF9068);         // Warm Orange
  static const Color accentLight = Color(0xFFFFB088);    // Peach
  static const Color accentDark = Color(0xFFFF7043);     // Deep Orange
  
  // 🤍 Neutral Colors
  static const Color background = Color(0xFFFFFBF7);     // Warm White
  static const Color surface = Color(0xFFFFFFFF);        // Pure White
  static const Color cardBg = Color(0xFFF8F9FA);         // Light Gray
  
  // ✏️ Text Colors
  static const Color textPrimary = Color(0xFF2D3748);    // Charcoal
  static const Color textSecondary = Color(0xFF718096);  // Medium Gray
  static const Color textLight = Color(0xFFA0AEC0);      // Light Gray
  
  // 🎯 Semantic Colors
  static const Color success = Color(0xFF51CF66);        // Green
  static const Color error = Color(0xFFFF6B6B);          // Red
  static const Color warning = Color(0xFFFFB020);        // Amber
  static const Color info = Color(0xFF4299E1);           // Blue
  
  // 🎨 Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warmGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, Color(0xFFFFF5F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // 🌈 Shadows
  static BoxShadow primaryShadow = BoxShadow(
    color: primary.withOpacity(0.3),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );
  
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 10,
    offset: const Offset(0, 2),
  );
  
  static BoxShadow subtleShadow = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 6,
    offset: const Offset(0, 2),
  );
}
