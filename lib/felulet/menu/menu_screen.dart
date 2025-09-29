import 'package:flutter/material.dart';

import '../profil/profile_page.dart';
import 'left_side_menu.dart';
import 'menu_item.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  int _selectedIndex = 0;

  List<MenuItemData> _items() => [
        MenuItemData(icon: Icons.home_outlined, title: 'Kezdőlap', onTap: () => _selectIndex(0)),
        MenuItemData(icon: Icons.person_outline, title: 'Profil', onTap: () => _selectIndex(1)),
        MenuItemData(icon: Icons.settings_outlined, title: 'Beállítások', onTap: () => _selectIndex(2)),
        MenuItemData(icon: Icons.help_outline, title: 'Súgó', onTap: () => _selectIndex(3)),
        MenuItemData(icon: Icons.logout, title: 'Kijelentkezés', onTap: _logout),
      ];

  void _selectIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Kezdőlap', 'Profil', 'Beállítások', 'Súgó'];
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 720;

    final content = IndexedStack(
      index: _selectedIndex,
      children: const [
        _PlaceholderPage(icon: Icons.home_outlined, title: 'Üdv a főoldalon!'),
        ProfilePage(),
        _PlaceholderPage(icon: Icons.settings_outlined, title: 'Beállítások hamarosan'),
        _PlaceholderPage(icon: Icons.help_outline, title: 'Segítség és GYIK készül'),
      ],
    );

    if (isCompact) {
      return Scaffold(
        appBar: AppBar(title: Text(titles[_selectedIndex])),
        drawer: Drawer(
          child: LeftSideMenu(
            items: _items(),
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              Navigator.pop(context);
              _selectIndex(index);
            },
          ),
        ),
        body: content,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          LeftSideMenu(
            items: _items(),
            selectedIndex: _selectedIndex,
            onItemSelected: (index) => _selectIndex(index),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.background.withOpacity(0.02),
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushReplacementNamed('/login');
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Friss és modern 2025-ös felület, hamarosan több tartalommal!'),
        ],
      ),
    );
  }
}
