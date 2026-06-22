import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../models/material_item.dart';
import '../../models/material_purchase.dart';
import '../../providers/material_provider.dart';
import '../../repositories/material_purchase_repository.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _monthFormat = DateFormat("MMMM 'de' y", 'pt_BR');
final _dayFormat = DateFormat('d MMM', 'pt_BR');

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

String _qty(double v, String unit) {
  final n = v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
  final suffix = unit.toLowerCase().contains('metro') ? 'm' : 'un.';
  return '$n $suffix';
}

/// History of material purchases grouped by month, matching the
/// Movimentações design.
class MaterialPurchasesScreen extends StatefulWidget {
  const MaterialPurchasesScreen({super.key});

  @override
  State<MaterialPurchasesScreen> createState() =>
      _MaterialPurchasesScreenState();
}

class _MaterialPurchasesScreenState extends State<MaterialPurchasesScreen> {
  List<MaterialPurchase> _purchases = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<MaterialProvider>().loadAll();
      final repo = MaterialPurchaseRepository(DatabaseHelper.instance);
      final purchases = await repo.getAllRecent();
      if (mounted) setState(() => _purchases = purchases);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startPurchase() async {
    final materials = context.read<MaterialProvider>().materials;
    if (materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um material primeiro.')),
      );
      return;
    }
    await context.push('/materials/purchase');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final materialsById = {
      for (final m in context.watch<MaterialProvider>().materials)
        if (m.id != null) m.id!: m,
    };

    final groups = <DateTime, List<MaterialPurchase>>{};
    for (final p in _purchases) {
      final key = DateTime(p.purchasedAt.year, p.purchasedAt.month);
      groups.putIfAbsent(key, () => []).add(p);
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimens.screenPadH, 16, AppDimens.screenPadH, 12),
              child: _Header(onAdd: _startPurchase),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Não foi possível carregar as compras.\n$_error',
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      : groups.isEmpty
                          ? const _EmptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                    AppDimens.screenPadH, 4,
                                    AppDimens.screenPadH, 120),
                                children: [
                                  for (final entry in groups.entries)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 18),
                                      child: _MonthGroup(
                                        title: _capitalize(
                                            _monthFormat.format(entry.key)),
                                        purchases: entry.value,
                                        materialsById: materialsById,
                                      ),
                                    ),
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthGroup extends StatelessWidget {
  final String title;
  final List<MaterialPurchase> purchases;
  final Map<int, MaterialItem> materialsById;

  const _MonthGroup({
    required this.title,
    required this.purchases,
    required this.materialsById,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 14),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: softCard(),
          child: Column(
            children: [
              for (var i = 0; i < purchases.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                _PurchaseRow(
                  purchase: purchases[i],
                  material: materialsById[purchases[i].materialId],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PurchaseRow extends StatelessWidget {
  final MaterialPurchase purchase;
  final MaterialItem? material;
  const _PurchaseRow({required this.purchase, required this.material});

  @override
  Widget build(BuildContext context) {
    final unit = material?.unit ?? 'Unidade';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFD7EFE1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 16, color: AppColors.profitStrong),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material?.name ?? 'Material #${purchase.materialId}',
                  style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  '+${_qty(purchase.quantity, unit)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency.format(purchase.totalPrice),
                style: AppText.money(size: 15, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                _dayFormat.format(purchase.purchasedAt),
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  const _Header({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HISTÓRICO', style: AppText.eyebrow()),
              const SizedBox(height: 3),
              Text('Compras', style: AppText.display()),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppDimens.radiusIcon),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withAlpha(46),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 64, color: AppColors.tabInactive),
          SizedBox(height: 12),
          Text('Nenhuma compra registrada',
              style: TextStyle(color: AppColors.textMuted)),
          SizedBox(height: 4),
          Text('Toque no + para registrar uma compra',
              style: TextStyle(color: AppColors.tabInactive, fontSize: 12)),
        ],
      ),
    );
  }
}
