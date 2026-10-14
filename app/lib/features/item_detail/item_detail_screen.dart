import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/session.dart';
import '../../core/theme.dart';
import '../../data/app_exception.dart';
import '../../data/regive_repository.dart';
import '../../models/item.dart';
import '../../widgets/app_image.dart';
import '../home/items_provider.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  ThingItem? _item;
  bool _isLoading = true;
  bool _isActing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final item = await context.read<ReGiveRepository>().fetchItem(
        widget.itemId,
      );
      setState(() {
        _item = item;
        _error = null;
      });
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _claim() async {
    setState(() => _isActing = true);
    try {
      await context.read<ReGiveRepository>().claimItem(
        widget.itemId,
        receiverName: context.read<SessionProvider>().user?.name ?? '',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Вы забрали эту вещь')));
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить объявление?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isActing = true);
    try {
      await context.read<ReGiveRepository>().deleteItem(widget.itemId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _isActing = false);
    }
  }

  Future<void> _toggleFavorite(ItemsProvider provider, ThingItem item) async {
    try {
      await provider.toggleFavorite(item);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final item = _item;

    return Scaffold(
      appBar: AppBar(
        title: Text(item?.title ?? 'Объявление'),
        actions: [
          if (item != null && session.user?.id == item.ownerId)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamed('/item-form', arguments: item)
                      .then((changed) {
                        if (changed == true) _load();
                      }),
            ),
          if (item != null && session.user?.id == item.ownerId)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isActing ? null : _delete,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : item == null
          ? const SizedBox.shrink()
          : _buildBody(context, item, session),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThingItem item,
    SessionProvider session,
  ) {
    final isOwner = session.user?.id == item.ownerId;
    final icon = item.category.icon;
    final itemsProvider = context.watch<ItemsProvider>();
    final isFavorite = itemsProvider.isFavorite(item.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: AppImage(
                url: item.imageUrl,
                cacheWidth: 1000,
                placeholder: Container(
                  color: AppColors.leaf.withValues(alpha: 0.08),
                  child: Icon(icon, size: 64, color: AppColors.leafDark),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.terracotta,
                ),
                onPressed: () => _toggleFavorite(itemsProvider, item),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Добавил(а) ${item.ownerName} · ${DateFormat('d MMMM, HH:mm', 'ru').format(item.createdAt.toLocal())}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.mutedInk),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(item.categoryName),
                avatar: Icon(icon, size: 16),
              ),
              Chip(
                label: Text(
                  item.condition == 'new' ? 'Новое' : 'В употреблении',
                ),
              ),
              if (item.city.isNotEmpty)
                Chip(
                  label: Text(item.city),
                  avatar: const Icon(Icons.place_outlined, size: 16),
                ),
              Chip(
                label: Text(item.isAvailable ? 'Доступно' : 'Забрано'),
                backgroundColor: item.isAvailable
                    ? AppColors.leaf.withValues(alpha: 0.12)
                    : AppColors.mutedInk.withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Описание',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            item.description.isEmpty ? 'Без описания' : item.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          if (!isOwner && item.isAvailable)
            ElevatedButton.icon(
              onPressed: _isActing ? null : _claim,
              icon: const Icon(Icons.volunteer_activism_outlined),
              label: _isActing
                  ? const Text('Забираем...')
                  : const Text('Забрать эту вещь'),
            ),
          if (isOwner)
            Text(
              'Это ваше объявление',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.mutedInk),
            ),
        ],
      ),
    );
  }
}
