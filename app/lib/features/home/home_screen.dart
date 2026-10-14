import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/empty_state.dart';
import 'item_card.dart';
import 'items_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemsProvider>().loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('ReGive')),
      body: RefreshIndicator(
        onRefresh: itemsProvider.loadItems,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Искать вещь по названию',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: itemsProvider.setSearch,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          CategoryFilterChip(
                            category: null,
                            label: 'Все категории',
                            selected: itemsProvider.categoryFilter == null,
                            onTap: () => itemsProvider.setCategoryFilter(null),
                          ),
                          const SizedBox(width: 8),
                          for (final category in itemsProvider.categories) ...[
                            CategoryFilterChip(
                              category: category,
                              label: category.name,
                              selected:
                                  itemsProvider.categoryFilter == category.id,
                              onTap: () =>
                                  itemsProvider.setCategoryFilter(category.id),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (itemsProvider.isLoading && itemsProvider.items.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (itemsProvider.error != null)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.wifi_off_outlined,
                  title: 'Не удалось загрузить вещи',
                  message: itemsProvider.error!,
                ),
              )
            else if (itemsProvider.items.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Пока нет объявлений',
                  message: 'Добавьте первую вещь, нажав «Отдать вещь»',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = itemsProvider.items[index];
                    return ItemCard(
                      item: item,
                      onTap: () => _openDetail(context, item),
                    );
                  }, childCount: itemsProvider.items.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, ThingItem item) {
    Navigator.of(context)
        .pushNamed('/item-detail', arguments: item.id)
        .then(_onReturnFromDetail);
  }

  void _onReturnFromDetail(dynamic changed) {
    if (changed != true || !mounted) return;
    context.read<ItemsProvider>().loadItems();
  }
}
