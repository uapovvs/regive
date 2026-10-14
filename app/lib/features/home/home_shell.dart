import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/app_bottom_nav.dart';
import '../favorites/favorites_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import 'home_screen.dart';
import 'items_provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Widget _tab(int index) => switch (index) {
    1 => const FavoritesScreen(),
    2 => const HistoryScreen(),
    3 => const ProfileScreen(),
    _ => const SizedBox.shrink(),
  };

  void _openItemForm() {
    Navigator.of(context).pushNamed('/item-form').then((changed) {
      if (changed == true && mounted) {
        context.read<ItemsProvider>().loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Главная живёт постоянно (сохраняет поиск и фильтр), остальные вкладки
    // пересоздаются при каждом открытии, чтобы показывать свежие данные.
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _index == 0 ? 0 : 1,
            children: [
              const HomeScreen(),
              KeyedSubtree(key: ValueKey(_index), child: _tab(_index)),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppBottomNav(
              currentIndex: _index,
              onTap: (index) => setState(() => _index = index),
              onAdd: _openItemForm,
            ),
          ),
        ],
      ),
    );
  }
}
