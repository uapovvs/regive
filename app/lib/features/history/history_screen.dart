import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/app_exception.dart';
import '../../data/regive_repository.dart';
import '../../models/deal.dart';
import '../../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DealRecord> _deals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final deals = await context.read<ReGiveRepository>().fetchHistory();
      if (!mounted) return;
      setState(() {
        _deals = deals;
        _error = null;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История сделок')),
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
    if (_deals.isEmpty) {
      return const RefreshableFill(
        child: EmptyState(
          icon: Icons.history,
          title: 'История пуста',
          message: 'Здесь появятся вещи, которые вы отдали или забрали',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
      itemCount: _deals.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _DealTile(deal: _deals[index]),
    );
  }
}

class _DealTile extends StatelessWidget {
  final DealRecord deal;

  const _DealTile({required this.deal});

  @override
  Widget build(BuildContext context) {
    final isGiven = deal.isGiven;
    final accent = isGiven ? AppColors.terracotta : AppColors.leafDark;

    return Card(
      child: ListTile(
        leading: Icon(
          isGiven ? Icons.north_east_outlined : Icons.south_west_outlined,
          color: accent,
        ),
        title: Text(
          deal.itemTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          isGiven
              ? 'Отдано пользователю ${deal.counterpartName}'
              : 'Получено от ${deal.counterpartName}',
        ),
        trailing: Text(
          DateFormat('d MMM', 'ru').format(deal.createdAt.toLocal()),
          style: const TextStyle(color: AppColors.mutedInk, fontSize: 12),
        ),
      ),
    );
  }
}
