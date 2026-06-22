import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../models/purse_model_with_bom.dart';
import '../../providers/purse_model_provider.dart';
import '../../repositories/purse_model_repository.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PurseModelWithBom> _boms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load after the first frame so the provider's notifyListeners() during
    // loadAll() doesn't call setState()/markNeedsBuild() while this widget
    // (which watches the provider) is still building.
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
      final repo = PurseModelRepository(DatabaseHelper.instance);
      final loaded = <PurseModelWithBom>[];
      for (final model in provider.models) {
        if (model.id != null) {
          loaded.add(await repo.getWithBom(model.id!));
        }
      }
      if (mounted) setState(() => _boms = loaded);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final models = context.watch<PurseModelProvider>().models;
    final totalUnits = models.fold<int>(0, (s, m) => s + m.currentStock);
    final totalValue = _boms.fold<double>(
        0, (s, b) => s + b.cost * b.model.currentStock);
    final totalProfit = _boms.fold<double>(
        0, (s, b) => s + b.profit * b.model.currentStock);
    final lowStockCount =
        models.where((m) => m.currentStock < kLowStockThreshold).length;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppDimens.screenPadH, 24, AppDimens.screenPadH, 120),
          children: [
            _Header(),
            const SizedBox(height: 18),
            _HeroProfitCard(profit: totalProfit),
            const SizedBox(height: 14),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Bolsas',
                      value: '$totalUnits',
                      caption: 'unidades em estoque',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MetricCard(
                      label: 'Valor',
                      value: _currency.format(totalValue),
                      caption: 'custo investido',
                      valueSize: 27,
                    ),
                  ),
                ],
              ),
            ),
            if (lowStockCount > 0) ...[
              const SizedBox(height: 14),
              _LowStockBanner(
                count: lowStockCount,
                onTap: () => context.go('/models'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RESUMO DE HOJE', style: AppText.eyebrow()),
        const SizedBox(height: 4),
        Text('Estoque', style: AppText.display(size: 26)),
      ],
    );
  }
}

class _HeroProfitCard extends StatelessWidget {
  final double profit;
  const _HeroProfitCard({required this.profit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppDimens.radiusHero),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -50,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.mint.withAlpha(26),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lucro potencial',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mint,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _currency.format(profit),
                style: AppText.money(
                  size: 54,
                  color: Colors.white,
                  weight: FontWeight.w700,
                  letterSpacing: -2.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(26),
                      borderRadius: BorderRadius.circular(AppDimens.pill),
                    ),
                    child: Text(
                      '--%',
                      style: AppText.money(
                        size: 12,
                        color: Colors.white,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'vs. mês passado',
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.white.withAlpha(168)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String caption;
  final double valueSize;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    this.valueSize = 38,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: softCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.eyebrow(size: 11)),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.money(
              size: valueSize,
              weight: FontWeight.w700,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(caption,
              style:
                  const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _LowStockBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _LowStockBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.peachBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.peachDot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                count == 1
                    ? '1 modelo com estoque baixo'
                    : '$count modelos com estoque baixo',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.peachText,
                ),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.peachChevron),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(
              'Não foi possível carregar os dados.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
