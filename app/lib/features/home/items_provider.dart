import 'package:flutter/foundation.dart';

import '../../data/app_exception.dart';
import '../../data/regive_repository.dart';
import '../../models/category.dart';
import '../../models/item.dart';

class ItemsProvider extends ChangeNotifier {
  final ReGiveRepository repository;

  ItemsProvider(this.repository);

  List<ThingItem> _items = [];
  Set<String> _favoriteIds = {};

  String _search = '';
  int? _categoryFilter;

  bool _isLoading = false;
  String? _error;

  List<ThingItem> get items => _items;
  List<ItemCategory> get categories => ItemCategory.all;
  int? get categoryFilter => _categoryFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isFavorite(String itemId) => _favoriteIds.contains(itemId);

  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.fetchItems(search: _search, categoryId: _categoryFilter),
        repository.fetchFavoriteIds(),
      ]);
      _items = results[0] as List<ThingItem>;
      _favoriteIds = results[1] as Set<String>;
    } on AppException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    loadItems();
  }

  void setCategoryFilter(int? categoryId) {
    _categoryFilter = categoryId;
    loadItems();
  }

  /// Сердечко переключается сразу, а при ошибке записи возвращается обратно.
  Future<void> toggleFavorite(ThingItem item) async {
    final wasFavorite = _favoriteIds.contains(item.id);
    wasFavorite ? _favoriteIds.remove(item.id) : _favoriteIds.add(item.id);
    notifyListeners();

    try {
      wasFavorite
          ? await repository.removeFavorite(item.id)
          : await repository.addFavorite(item.id);
    } on AppException {
      wasFavorite ? _favoriteIds.add(item.id) : _favoriteIds.remove(item.id);
      notifyListeners();
      rethrow;
    }
  }
}
