import 'package:flutter/material.dart';

class ItemCategory {
  final int id;
  final String name;
  final IconData icon;

  const ItemCategory({
    required this.id,
    required this.name,
    required this.icon,
  });

  static const List<ItemCategory> all = [
    ItemCategory(id: 1, name: 'Одежда', icon: Icons.checkroom_outlined),
    ItemCategory(id: 2, name: 'Книги', icon: Icons.menu_book_outlined),
    ItemCategory(id: 3, name: 'Мебель', icon: Icons.weekend_outlined),
    ItemCategory(id: 4, name: 'Электроника', icon: Icons.devices_outlined),
    ItemCategory(
      id: 5,
      name: 'Детские товары',
      icon: Icons.child_friendly_outlined,
    ),
    ItemCategory(id: 6, name: 'Другое', icon: Icons.category_outlined),
  ];

  static ItemCategory byId(int id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.last);
}
