import 'package:flutter/material.dart';

import 'package:medilink/features/alerts/screens/alerts_screen.dart';
import 'package:medilink/features/inventory/screens/inventory_screen.dart';
import 'package:medilink/features/notes/screens/notes_screen.dart';
import 'package:medilink/features/profile/screens/profile_screen.dart';

import 'dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  int _dashboardKey = 0;
  int _inventoryKey = 0;
  int _notesKey = 0;
  int _alertsKey = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      DashboardScreen(key: ValueKey(_dashboardKey)),
      InventoryScreen(key: ValueKey(_inventoryKey)),
      NotesScreen(key: ValueKey(_notesKey)),
      AlertsScreen(key: ValueKey(_alertsKey)),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            if (index == currentIndex) {
              return;
            }

            switch (index) {
              case 0:
                _dashboardKey++;
                break;
              case 1:
                _inventoryKey++;
                break;
              case 2:
                _notesKey++;
                break;
              case 3:
                _alertsKey++;
                break;
            }

            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}