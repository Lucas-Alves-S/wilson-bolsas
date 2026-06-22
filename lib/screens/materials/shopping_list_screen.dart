import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/planning/material_needs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../models/material_item.dart';
import '../../models/purse_model_with_bom.dart';
import '../../providers/material_provider.dart';
import '../../providers/purse_model_provider.dart';
import '../../repositories/purse_model_repository.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String _formatAmount(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String _unitSuffix(String unit) =>
    unit.toLowerCase().contains('metro') ? 'm' : 'un.';

/// Materials to buy to cover this week's production plan (need − stock),
/// reachable from the home banner.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  Map<int, double> _need = {};
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
      final provider = context.read<PurseModelProvider>();
      await provider.loadAll();
      if (mounted) await context.read<MaterialProvider>().loadAll();
      final repo = PurseModelRepository(DatabaseHelper.instance);
      final boms = <PurseModelWithBom>[];
      for (final model in provider.models) {
        if (model.id != null) boms.add(await repo.getWithBom(model.id!));
      }
      if (mounted) setState(() => _need = weeklyMaterialNeed(boms));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final materials = context.watch<MaterialProvider>().materials;
    final lines = <_BuyLine>[];
    for (final m in materials) {
      final qty = materialToBuy(m, _need);
      if (qty > 0) lines.add(_BuyLine(material: m, quantity: qty));
    }
    lines.sort((a, b) => a.material.name.compareTo(b.material.name));
    final total = lines.fold<double>(
        0, (s, l) => s + l.quantity * l.material.lastPricePerUnit);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Nav(title: 'Lista de compras'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Não foi possível carregar a lista.\n$_error',
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      : lines.isEmpty
                          ? const _EmptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                    AppDimens.screenPadH, 4,
                                    AppDimens.screenPadH, 120),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      'Quantidade que falta para o plano da '
                                      'semana. Toque para registrar a compra.',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textMuted),
                                    ),
                                  ),
                                  Container(
                                    clipBehavior: Clip.antiAlias,
                                    decoration: softCard(),
                                    child: Column(
                                      children: [
                                        for (var i = 0; i < lines.length; i++) ...[
                                          if (i > 0)
                                            const Divider(
                                                height: 1,
                                                color: AppColors.divider),
                                          _ShoppingRow(
                                            line: lines[i],
                                            onTap: () async {
                                              await context.push(
                                                  '/materials/${lines[i].material.id}/purchase');
                                              if (context.mounted) _load();
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _TotalCard(total: total),
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

class _BuyLine {
  final MaterialItem material;
  final double quantity;
  const _BuyLine({required this.material, required this.quantity});
}

class _ShoppingRow extends StatelessWidget {
  final _BuyLine line;
  final VoidCallback onTap;
  const _ShoppingRow({required this.line, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = line.material;
    final estimated = line.quantity * m.lastPricePerUnit;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.peachBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.add_shopping_cart,
                  size: 16, color: AppColors.peachText),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '~ ${_currency.format(estimated)}',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatAmount(line.quantity)} ${_unitSuffix(m.unit)}',
              style: AppText.money(
                  size: 15,
                  weight: FontWeight.w700,
                  color: AppColors.peachText),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.peachChevron),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  const _TotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: softCard(),
      child: Row(
        children: [
          Expanded(
            child: Text('CUSTO ESTIMADO',
                style: AppText.eyebrow(size: 11)),
          ),
          Text(
            _currency.format(total),
            style: AppText.money(size: 18, weight: FontWeight.w700),
          ),
        ],
      ),
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
          Icon(Icons.check_circle_outline,
              size: 64, color: AppColors.tabInactive),
          SizedBox(height: 12),
          Text('Nada a comprar esta semana',
              style: TextStyle(color: AppColors.textMuted)),
          SizedBox(height: 4),
          Text('Seu estoque cobre o plano de produção',
              style: TextStyle(color: AppColors.tabInactive, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Nav extends StatelessWidget {
  final String title;
  const _Nav({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(13),
                boxShadow: kCardShadow,
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.ink),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
