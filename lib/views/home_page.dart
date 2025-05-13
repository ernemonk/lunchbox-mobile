import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lunchbox/components/menu_bar.dart';
import 'package:lunchbox/views/recipe_generator.dart';
import 'package:lunchbox/views/settings_page.dart';
import 'package:lunchbox/views/favorites_page.dart';
import 'package:lunchbox/views/myfridge_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Track selected screen index

  // Titles for each screen
  final List<String> _titles = ["Lunchboxer", "Favorites","My Fridge","Settings"];

  // Screens to navigate between
  final List<Widget> _screens = [
    const UserPreferencesPage(),  // Placeholder Home Screen
    const FavoritesPage(), // Placeholder Settings Screen
    const MyFridgePage(), // Placeholder Settings Screen
    const SettingsPage(), // Placeholder Settings Screen


  ];

  // Handle navigation
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
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(
        bottom: BorderSide(
          color: Color.fromARGB(255, 200, 200, 200), // Change this to your desired border color
          width: 1.0,
        ),
      ),
    ),
    child: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        _titles[_selectedIndex],
        style: const TextStyle(color: Colors.indigo),
      ),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black),
          onPressed: _signOut,
        ),
      ],
    ),
  ),
),


      body: IndexedStack(
        index: _selectedIndex,
        children: _screens, // Show the selected screen
      ),
      bottomNavigationBar: Menu(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Handle navigation
      ),
    );
  }
}
