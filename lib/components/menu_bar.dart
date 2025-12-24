import 'package:flutter/material.dart';
class Menu extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const Menu({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color.fromARGB(255, 200, 200, 200), // Light grey border
            width: 1.0,
          ),
        ),
      ),
      child: BottomNavigationBar(
  currentIndex: currentIndex,
  onTap: onTap,
  backgroundColor: Colors.white,
  selectedItemColor: Colors.indigo, // 💥 Indigo color for selected item
  unselectedItemColor: Color.fromARGB(255, 139, 132, 110),
  showUnselectedLabels: true,
  selectedLabelStyle: TextStyle(
    fontWeight: FontWeight.bold,
  ),
  unselectedLabelStyle: TextStyle(
    fontWeight: FontWeight.normal,
  ),
  iconSize: 28,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dinner_dining_outlined),
      label: 'Generator',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.star),
      label: 'Favorites',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.food_bank),
      label: 'My Fridge',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ],
  type: BottomNavigationBarType.fixed,
),
    );
  }
}
