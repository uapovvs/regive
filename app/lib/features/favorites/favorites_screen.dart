import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_exception.dart';
import '../../data/regive_repository.dart';
import '../../models/item.dart';
import '../../widgets/empty_state.dart';
import '../home/item_card.dart';
import '../home/items_provider.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<ThingItem> _favorites = [];
  bool _isLoading = true;
  String? _error;
  ItemsProvider? _itemsProvider;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<ItemsProvider>();
    if (!identical(provider, _itemsProvider)) {
      _itemsProvider?.removeListener(_onFavoritesChanged);
      _itemsProvider = provider..addListener(_onFavoritesChanged);
    }
  }

  @override
  void dispose() {
    _itemsProvider?.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    final provider = context.read<ItemsProvider>();
    setState(() {
      _favorites = _favorites
          .where((item) => provider.isFavorite(item.id))
          .toList();
    });
  }

  Future<void> _load() async {
    try {
      final favorites = await context
          .read<ReGiveRepository>()
          .fetchFavoriteItems();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _error = null;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onReturnFromDetail() {
    if (!mounted) return;
    _load();
    context.read<ItemsProvider>().loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: _load, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return RefreshableFill(
        child: EmptyState(
          icon: Icons.wifi_off_outlined,
          title: 'Ошибка загрузки',
          message: _error!,
        ),
      );
    }
    if (_favorites.isEmpty) {
      return const RefreshableFill(
        child: EmptyState(
          icon: Icons.favorite_border,
          title: 'Пока нет избранного',
          message: 'Нажмите на сердечко у вещи, чтобы сохранить её здесь',
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final item = _favorites[index];
        return ItemCard(
          item: item,
          onTap: () =>
              Navigator.of(context)
                  .pushNamed('/item-detail', arguments: item.id)
                  .then((_) => _onReturnFromDetail()),
        );
      },
    );
  }
}
