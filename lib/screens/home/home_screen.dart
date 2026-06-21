import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../models/purse_model.dart';
import '../../models/purse_model_with_bom.dart';
import '../../providers/purse_model_provider.dart';
import '../../repositories/purse_model_repository.dart';
import '../../widgets/stock_badge.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PurseModelWithBom> _boms = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final provider = context.read<PurseModelProvider>();
    await provider.loadAll();
    final repo = PurseModelRepository(DatabaseHelper.instance);
    final loaded = <PurseModelWithBom>[];
    for (final model in provider.models) {
      if (model.id != null) {
        loaded.add(await repo.getWithBom(model.id!));
      }
    }
    if (mounted) {
      setState(() {
        _boms = loaded;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final models = context.watch<PurseModelProvider>().models;
    final totalUnits = models.fold<int>(0, (s, m) => s + m.currentStock);
    final totalValue = _boms.fold<double>(
        0, (s, b) => s + b.model.sellingPrice * b.model.currentStock);
    final totalProfit = _boms.fold<double>(
        0, (s, b) => s + b.profit * b.model.currentStock);
    final lowStock =
        models.where((m) => m.currentStock < kLowStockThreshold).toList();
    final mostProfitable = _boms.isNotEmpty
        ? (_boms.reduce((a, b) => a.profit > b.profit ? a : b))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wilson Bolsas'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _SummaryRow(
                    totalModels: models.length,
                    totalUnits: totalUnits,
                    totalValue: totalValue,
                    totalProfit: totalProfit,
                  ),
                  const SizedBox(height: 20),
                  if (mostProfitable != null) ...[
                    _SectionTitle('Modelo mais lucrativo'),
                    const SizedBox(height: 8),
                    _MostProfitableCard(bom: mostProfitable),
                    const SizedBox(height: 20),
                  ],
                  if (lowStock.isNotEmpty) ...[
                    _SectionTitle('Estoque baixo'),
                    const SizedBox(height: 8),
                    ...lowStock.map((m) => _LowStockTile(model: m)),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 8),
                  _SectionTitle('Acesso rápido'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Modelos',
                          onTap: () => context.go('/models'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.inventory_2_outlined,
                          label: 'Materiais',
                          onTap: () => context.go('/materials'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int totalModels;
  final int totalUnits;
  final double totalValue;
  final double totalProfit;

  const _SummaryRow({
    required this.totalModels,
    required this.totalUnits,
    required this.totalValue,
    required this.totalProfit,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
            label: 'Modelos', value: '$totalModels', icon: Icons.shopping_bag),
        _StatCard(
            label: 'Unidades em estoque',
            value: '$totalUnits',
            icon: Icons.warehouse_outlined),
        _StatCard(
            label: 'Valor em estoque',
            value: _currency.format(totalValue),
            icon: Icons.attach_money),
        _StatCard(
            label: 'Lucro potencial',
            value: _currency.format(totalProfit),
            icon: Icons.trending_up,
            valueColor: totalProfit >= 0
                ? Colors.green.shade700
                : Colors.red.shade700),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 20, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleSmall);
  }
}

class _MostProfitableCard extends StatelessWidget {
  final PurseModelWithBom bom;
  const _MostProfitableCard({required this.bom});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
        title: Text(bom.model.name),
        subtitle: Text('Lucro: ${_currency.format(bom.profit)} · '
            'Margem: ${bom.marginPercent.toStringAsFixed(1)}%'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go('/models/${bom.model.id}'),
      ),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final PurseModel model;
  const _LowStockTile({required this.model});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text(model.name),
        trailing: StockBadge(stock: model.currentStock),
        onTap: () => context.go('/models/${model.id}'),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label,
                  style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
