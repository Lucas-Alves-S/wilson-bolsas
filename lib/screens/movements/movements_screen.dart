import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/color_swatches.dart';
import '../../models/purse_model.dart';
import '../../models/stock_movement.dart';
import '../../providers/purse_model_provider.dart';
import '../../repositories/stock_movement_repository.dart';
import '../../widgets/stock_badge.dart';

final _monthFormat = DateFormat("MMMM 'de' y", 'pt_BR');
final _dayFormat = DateFormat('d MMM', 'pt_BR');

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Global stock-movement history grouped by month, matching the
/// "Estoque de Bolsas" design.
class MovementsScreen extends StatefulWidget {
  const MovementsScreen({super.key});

  @override
  State<MovementsScreen> createState() => _MovementsScreenState();
}

class _MovementsScreenState extends State<MovementsScreen> {
  List<StockMovement> _movements = [];
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
      // Direct-repo read (same pattern as Home/Modelos) so we don't disturb the
      // per-model StockMovementProvider used by the model detail screen.
      await context.read<PurseModelProvider>().loadAll();
      final repo = StockMovementRepository(DatabaseHelper.instance);
      final movements = await repo.getAllRecent();
      if (mounted) setState(() => _movements = movements);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startMovement() async {
    final models = context.read<PurseModelProvider>().models;
    if (models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um modelo primeiro.')),
      );
      return;
    }
    final picked = await showModalBottomSheet<PurseModel>(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                child: Row(
                  children: [
                    Text('Movimentar qual modelo?',
                        style: AppText.display(size: 18)),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final m in models)
                      InkWell(
                        onTap: () => Navigator.of(sheetContext).pop(m),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.name,
                                  style: const TextStyle(
                                      fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                              ),
                              StockBadge(stock: m.currentStock),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked?.id == null || !mounted) return;
    await context.push('/models/${picked!.id}/movement');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final modelsById = {
      for (final m in context.watch<PurseModelProvider>().models)
        if (m.id != null) m.id!: m,
    };

    // Group movements by month, preserving recency order (movements already
    // come sorted by moved_at DESC, so groups end up ordered most-recent-first).
    final groups = <DateTime, List<StockMovement>>{};
    for (final mv in _movements) {
      final key = DateTime(mv.movedAt.year, mv.movedAt.month);
      groups.putIfAbsent(key, () => []).add(mv);
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
              child: _Header(onAdd: _startMovement),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Não foi possível carregar as movimentações.\n$_error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textMuted),
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
                                      padding: const EdgeInsets.only(bottom: 18),
                                      child: _MonthGroup(
                                        title: _capitalize(
                                            _monthFormat.format(entry.key)),
                                        movements: entry.value,
                                        modelsById: modelsById,
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
  final List<StockMovement> movements;
  final Map<int, PurseModel> modelsById;

  const _MonthGroup({
    required this.title,
    required this.movements,
    required this.modelsById,
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
              for (var i = 0; i < movements.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                _MovementRow(
                  mv: movements[i],
                  model: modelsById[movements[i].modelId],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MovementRow extends StatelessWidget {
  final StockMovement mv;
  final PurseModel? model;
  const _MovementRow({required this.mv, required this.model});

  @override
  Widget build(BuildContext context) {
    final positive = mv.delta > 0;
    final amountColor = positive ? AppColors.profitStrong : AppColors.peachText;
    final iconColor = positive ? AppColors.profitStrong : AppColors.peachDot;
    final color = model?.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: positive ? const Color(0xFFD7EFE1) : AppColors.peachBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              positive ? Icons.arrow_upward : Icons.arrow_downward,
              size: 15,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model?.name ?? 'Modelo #${mv.modelId}',
                  style:
                      const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (color != null && color.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _MiniColorChip(label: color),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${positive ? '+' : '−'}${mv.delta.abs()} un.',
                style: AppText.money(
                    size: 15, color: amountColor, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                _dayFormat.format(mv.movedAt),
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

/// Compact color chip (dot + name) used inside movement rows.
class _MiniColorChip extends StatelessWidget {
  final String label;
  const _MiniColorChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 2, 8, 2),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(AppDimens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colorSwatch(label),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withAlpha(31)),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.chipText,
            ),
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
              Text('Movimentações', style: AppText.display()),
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
          Icon(Icons.sync_alt, size: 64, color: AppColors.tabInactive),
          SizedBox(height: 12),
          Text('Nenhuma movimentação registrada',
              style: TextStyle(color: AppColors.textMuted)),
          SizedBox(height: 4),
          Text('Movimente o estoque de um modelo para começar',
              style: TextStyle(color: AppColors.tabInactive, fontSize: 12)),
        ],
      ),
    );
  }
}
