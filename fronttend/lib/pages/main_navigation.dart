
import 'package:flutter/material.dart';
import 'homepage.dart';
import 'catalogue_page.dart';
import 'publier_page.dart';
import 'panne_page.dart';
import 'dashboard_page.dart';
import 'panier_page.dart';
import 'reservations_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    CataloguePage(),
    PublierPage(),
    PannePage(),
    DashboardPage(),
    PanierPage(),
    ReservationsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 380;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(5, 21, 44, 1),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromRGBO(5, 21, 44, 1),
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.white60,
        selectedFontSize: isSmallScreen ? 9.5 : 11.0,
        unselectedFontSize: isSmallScreen ? 9.0 : 10.5,
        iconSize: isSmallScreen ? 20 : 24,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Appareils',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Publier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            activeIcon: Icon(Icons.build),
            label: 'Diagnostic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Panier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            activeIcon: Icon(Icons.event_note),
            label: 'Réservations',
          ),
        ],
      ),
    );
  }
}
