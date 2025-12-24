/// Example: How to Use Localization in Your App
/// 
/// This file demonstrates how to use translations in your Flutter widgets.
/// To use translations in any widget:
/// 
/// 1. Import the localizations:
///    import 'package:flutter_gen/gen_l10n/app_localizations.dart';
/// 
/// 2. Access translations using AppLocalizations.of(context):
///    Text(AppLocalizations.of(context)!.myFridge)
/// 
/// EXAMPLE WIDGET:
/// 
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
/// 
/// class ExampleWidget extends StatelessWidget {
///   const ExampleWidget({super.key});
/// 
///   @override
///   Widget build(BuildContext context) {
///     final l10n = AppLocalizations.of(context)!;
///     
///     return Scaffold(
///       appBar: AppBar(
///         title: Text(l10n.myFridge), // Shows: "My Fridge" / "Mi Refrigerador" / "Mon Réfrigérateur"
///       ),
///       body: Column(
///         children: [
///           ElevatedButton(
///             onPressed: () {},
///             child: Text(l10n.addItem), // Shows: "Add Item" / "Agregar Artículo" / "Ajouter un Article"
///           ),
///           ElevatedButton(
///             onPressed: () {},
///             child: Text(l10n.scanBarcode), // Shows: "Scan Barcode" / "Escanear Código de Barras" / etc.
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
/// 
/// AVAILABLE TRANSLATIONS:
/// - appName, login, signup, logout
/// - email, password
/// - myFridge, recipes, settings
/// - addItem, scanBarcode, takePhoto
/// - all, category, expiryDate, quantity
/// - save, cancel, delete, edit
/// - subscription, freeTrial, premium, upgrade
/// - searchRecipes, generateRecipe
/// - ingredients, instructions, cookingTime, servings
/// - language
/// 
/// TO ADD MORE TRANSLATIONS:
/// 1. Add the key to lib/l10n/app_en.arb (with description)
/// 2. Add translations to app_es.arb and app_fr.arb
/// 3. Run: flutter pub get (regenerates code)
/// 4. Use: AppLocalizations.of(context)!.yourNewKey
/// 
/// TO CHANGE LANGUAGE PROGRAMMATICALLY:
/// See lib/services/language_service.dart for LanguageService helper

library;
