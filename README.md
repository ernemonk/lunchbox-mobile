# 🍱 Lunchbox

An AI-powered recipe generator mobile app built with Flutter and Firebase. Generate personalized recipes based on your dietary preferences, allergies, and the ingredients you have in your fridge.

## ✨ Features

### 🍳 AI Recipe Generation
- Generate personalized recipes using AI based on your preferences
- Support for multiple diet types: Keto, Carnivore, Vegetarian, Vegan, Pescetarian, Raw Vegan, Ayurvedic
- Allergy-aware recipe suggestions
- Option to generate recipes using only ingredients from your fridge
- Add custom instructions for recipe generation

### 🧊 My Fridge
- Track ingredients you have at home
- Add, edit, and delete fridge items with quantities
- Sync fridge contents across devices via Firebase
- Use fridge inventory for smarter recipe suggestions

### ⭐ Favorites
- Save your favorite generated recipes
- View and manage saved recipes
- Real-time sync with Firebase Firestore

### ⚙️ Settings
- User account management
- Privacy policy access
- Account deletion option
- Admin panel for AI prompt management (admin users only)

### 🔐 Authentication
- Email/password authentication via Firebase Auth
- User registration and login
- Secure session management

## 🛠️ Tech Stack

- **Framework:** Flutter 3.6.1+
- **Language:** Dart
- **Backend:** Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Crashlytics
  - Firebase Performance Monitoring
  - Firebase Dynamic Links
- **State Management:** StatefulWidget
- **Local Storage:** SharedPreferences
- **HTTP Client:** http package

## 📁 Project Structure

```
lib/
├── main.dart                         # App entry point & auth wrapper
├── firebase_options.dart             # Firebase configuration
│
├── core/                             # 🎯 Core utilities & constants
│   ├── core.dart                     # Core barrel file
│   ├── constants/
│   │   ├── constants.dart            # Constants barrel file
│   │   ├── app_assets.dart           # Asset path constants
│   │   ├── app_colors.dart           # Color palette
│   │   └── app_strings.dart          # String constants
│   └── theme/
│       ├── theme.dart                # Theme barrel file
│       └── app_theme.dart            # App-wide theme configuration
│
├── components/                       # 🧩 Reusable UI Components
│   ├── components.dart               # Components barrel file
│   ├── loading/
│   │   ├── loading.dart              # Loading barrel file
│   │   ├── bouncing_image_overlay.dart
│   │   └── image_loading_overlay.dart
│   └── navigation/
│       ├── navigation.dart           # Navigation barrel file
│       └── bottom_nav_bar.dart       # Bottom navigation bar
│
├── services/                         # 🔧 Business Logic & API Services
│   ├── services.dart                 # Services barrel file
│   ├── recipe_service.dart           # AI recipe generation (refactored)
│   └── recipe_generator.dart         # Legacy (kept for compatibility)
│
└── views/                            # 📱 Screen/Page Widgets
    ├── views.dart                    # Views barrel file
    │
    ├── # Authentication
    ├── login_page.dart               # User login
    ├── signup_page.dart              # User registration
    │
    ├── # Main Navigation
    ├── home_page.dart                # Main navigation hub
    ├── recipe_generator.dart         # AI recipe generation UI
    ├── favorites_page.dart           # Saved recipes list
    ├── myfridge_page.dart            # Fridge inventory
    ├── settings_page.dart            # User settings
    │
    ├── # Recipe
    ├── recipe.dart                   # Recipe viewer
    │
    ├── # Admin
    ├── tweak_the_ai.dart             # AI prompt editor
    │
    └── # Legal
        └── privacy_policy.dart       # Privacy policy
```

## 🏗️ Architecture

### Import Conventions

Use barrel files for cleaner imports:

```dart
// ✅ Clean imports using barrel files
import 'package:lunchbox/core/core.dart';
import 'package:lunchbox/components/components.dart';
import 'package:lunchbox/services/services.dart';
import 'package:lunchbox/views/views.dart';

// ❌ Avoid deep imports
import 'package:lunchbox/core/constants/app_colors.dart';
```

### Module Overview

| Module | Purpose |
|--------|---------|
| `core/` | App-wide constants, colors, strings, and theme configuration |
| `components/` | Reusable UI widgets (navigation, loading indicators) |
| `services/` | Business logic, API calls, and data processing |
| `views/` | Screen/page widgets that users interact with |


## 🚀 Getting Started

### Prerequisites

- Flutter SDK ^3.6.1
- Dart SDK
- Firebase project configured
- Android Studio / Xcode (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd lunchbox
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Download and add configuration files:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
   - Update `lib/firebase_options.dart` with your configuration

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Android:**
```bash
flutter build apk --release
# or for App Bundle
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📱 Platforms

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Linux
- ✅ Windows

## 🔥 Firebase Collections

| Collection | Description |
|------------|-------------|
| `users` | User profiles with fridge contents and roles |
| `recipes` | Saved user recipes |
| `prompts` | AI prompt templates (admin-managed) |

## 🎨 Theming

The app uses a centralized theme system located in `lib/core/`:

```dart
// Import the theme
import 'package:lunchbox/core/core.dart';

// Use colors
Container(color: AppColors.primary)   // Coral orange
Container(color: AppColors.secondary) // Sage green

// Use theme in MaterialApp
MaterialApp(theme: AppTheme.lightTheme)

// Use theme decorations
Container(decoration: AppTheme.recipeCardDecoration())
```

### Color Palette

**Color Philosophy:**
- 🍊 **Primary (Coral)** - Stimulates appetite, friendly, action-oriented
- 🥬 **Secondary (Green)** - Fresh ingredients, health, sustainability
- 🍯 **Accent (Amber)** - Favorites, highlights, warmth
- 🏠 **Backgrounds** - Warm whites for cozy, home-cooking feel

| Color | Name | Hex | Usage |
|-------|------|-----|-------|
| 🟠 | Primary | `#FF6B4A` | Buttons, nav, CTAs |
| 🟢 | Secondary | `#4CAF50` | Success, fresh items |
| 🟡 | Accent | `#FFB74D` | Favorites, highlights |
| ⬜ | Background | `#FFFBF8` | Warm off-white |
| 🔴 | Error | `#E53935` | Errors, delete actions |
| ⚫ | Text | `#2D2A26` | Warm charcoal text |

## 📋 Documentation

| Document | Description |
|----------|-------------|
| [README.md](README.md) | Project overview and setup |
| [docs/RFC_VISION.md](docs/RFC_VISION.md) | Product vision, roadmap, and strategy |

## 📄 License

This project is private and not published to pub.dev.

## 🤝 Contributing

This is a private project. Please contact the maintainers for contribution guidelines.
