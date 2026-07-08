import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'home_screen.dart';
import 'sync_screen.dart';
import 'food_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    SyncScreen(),
    FoodScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.cardDark,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        elevation: 8,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: _selectedIndex == 0 ? AppColors.textLight : AppColors.textMuted),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.date_range, color: _selectedIndex == 1 ? AppColors.textLight : AppColors.textMuted),
            label: 'Sync',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu, color: _selectedIndex == 2 ? AppColors.textLight : AppColors.textMuted),
            label: 'Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: _selectedIndex == 3 ? AppColors.textLight : AppColors.textMuted),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
