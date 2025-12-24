import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lunchbox/components/navigation/bottom_nav_bar.dart';
import 'package:lunchbox/core/theme/app_colors.dart';
import 'package:lunchbox/views/recipe_generator.dart';
import 'package:lunchbox/views/settings_page.dart';
import 'package:lunchbox/views/favorites_page.dart';
import 'package:lunchbox/views/myfridge_page.dart';

/// Main home page that serves as the navigation hub.
/// 
/// Contains a bottom navigation bar with four tabs:
/// - Recipe Generator
/// - Favorites
/// - My Fridge
/// - Settings
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  /// Screen titles for the app bar
  static const List<String> _titles = [
    'Cook Something Delicious',
    'Favorites',
    'My Fridge',
    'Settings',
  ];

  /// Screens corresponding to each navigation tab
  final List<Widget> _screens = const [
    UserPreferencesPage(),
    FavoritesPage(),
    MyFridgePage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withOpacity(0.1),
                width: 1.0,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                onPressed: _signOut,
                tooltip: 'Sign Out',
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
