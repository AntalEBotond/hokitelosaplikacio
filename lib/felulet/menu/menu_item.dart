import 'package:flutter/material.dart';

class MenuItemData {
  const MenuItemData({required this.icon, required this.title, this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
}
