import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/color_swatches.dart';
import '../../models/purse_model_with_bom.dart';
import '../../providers/purse_model_provider.dart';
import '../../repositories/purse_model_repository.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/model_grid_card.dart';

/// Sentinel returned by the filter sheet to mean "clear the filter" (vs. null
/// which means the sheet was dismissed without a choice).
const _kAll = ' __all__';

/// Stock availability filter for the Modelos catalog.
enum StockFilter {
  all('Todos'),
  inStock('Em estoque'),
  outOfStock('Sem estoque');

  const StockFilter(this.label);
  final String label;

  bool matches(int stock) => switch (this) {
        StockFilter.all => true,
        StockFilter.inStock => stock > 0,
        StockFilter.outOfStock => stock == 0,
      };
}

class ModelsScreen extends StatefulWidget {
  const ModelsScreen({super.key});

  @override
  State<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends State<ModelsScreen> {
  final Map<int, PurseModelWithBom> _details = {};
  String? _colorFilter;
  StockFilter _stockFilter = StockFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final provider = context.read<PurseModelProvider>();
    final repo = PurseModelRepository(DatabaseHelper.instance);
    final updated = <int, PurseModelWithBom>{};
    for (final model in provider.models) {
      if (model.id == null) continue;
      updated[model.id!] = await repo.getWithBom(model.id!);
    }
    if (mounted) {
      setState(() {
        _details
          ..clear()
          ..addAll(updated);
      });
    }
  }

  Future<void> _openNew() async {
    final provider = context.read<PurseModelProvider>();
    await context.push('/models/new');
    await provider.loadAll();
    _loadDetails();
  }

  Future<void> _openPlan() async {
    final provider = context.read<PurseModelProvider>();
    await context.push('/models/plan');
    await provider.loadAll();
    _loadDetails();
  }

  Future<void> _openDetail(int id) async {
    final provider = context.read<PurseModelProvider>();
    await context.push('/models/$id');
    await provider.loadAll();
    _loadDetails();
  }

  Future<void> _openColorFilter(List<String> colors) async {
    final selected = await showModalBottomSheet<String?>(
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
                    Text('Filtrar por cor', style: AppText.display(size: 18)),
                  ],
                ),
              ),
              _ColorOption(
                label: 'Todas',
                selected: _colorFilter == null,
                onTap: () => Navigator.of(sheetContext).pop(_kAll),
              ),
              for (final c in colors)
                _ColorOption(
                  label: c,
                  swatch: colorSwatch(c),
                  selected: _colorFilter == c,
                  onTap: () => Navigator.of(sheetContext).pop(c),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected == null) return; // dismissed
    setState(() => _colorFilter = selected == _kAll ? null : selected);
  }

  Future<void> _openStockFilter() async {
    final selected = await showModalBottomSheet<StockFilter>(
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
                    Text('Filtrar por estoque',
                        style: AppText.display(size: 18)),
                  ],
                ),
              ),
              for (final f in StockFilter.values)
                _ColorOption(
                  label: f.label,
                  selected: _stockFilter == f,
                  onTap: () => Navigator.of(sheetContext).pop(f),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected == null) return; // dismissed
    setState(() => _stockFilter = selected);
  }

  Future<void> _confirmDelete(int id, String name) async {
    final ok = await showConfirmationDialog(
      context,
      title: 'Excluir modelo',
      content: 'Deseja excluir "$name"? Esta ação não pode ser desfeita.',
    );
    if (ok == true && mounted) {
      _details.remove(id);
      await context.read<PurseModelProvider>().remove(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<PurseModelProvider>(
          builder: (context, provider, _) {
            final models = provider.models;
            final colors = models
                .map((m) => m.color)
                .whereType<String>()
                .where((c) => c.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            // Drop a stale filter if its color no longer exists.
            if (_colorFilter != null && !colors.contains(_colorFilter)) {
              _colorFilter = null;
            }
            final shown = models
                .where((m) =>
                    (_colorFilter == null || m.color == _colorFilter) &&
                    _stockFilter.matches(m.currentStock))
                .toList();
            final totalUnits =
                shown.fold<int>(0, (s, m) => s + m.currentStock);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.screenPadH, 16, AppDimens.screenPadH, 12),
                  child: _Header(
                    onAdd: _openNew,
                    onPlan: _openPlan,
                    colorFilter: _colorFilter,
                    onColorTap:
                        colors.isEmpty ? null : () => _openColorFilter(colors),
                    onColorClear: () => setState(() => _colorFilter = null),
                    stockFilter: _stockFilter,
                    onStockTap: _openStockFilter,
                    onStockClear: () =>
                        setState(() => _stockFilter = StockFilter.all),
                  ),
                ),
                Expanded(
                  child: provider.loading
                      ? const Center(child: CircularProgressIndicator())
                      : models.isEmpty
                          ? const _EmptyState()
                          : shown.isEmpty
                              ? const _NoMatchState()
                              : GridView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                      AppDimens.screenPadH, 4,
                                      AppDimens.screenPadH, 120),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    mainAxisExtent: 280,
                                  ),
                                  itemCount: shown.length,
                                  itemBuilder: (context, index) {
                                    final model = shown[index];
                                    final detail = _details[model.id] ??
                                        PurseModelWithBom(
                                            model: model, bom: const []);
                                    return ModelGridCard(
                                      data: detail,
                                      onTap: () => _openDetail(model.id!),
                                      onLongPress: () =>
                                          _confirmDelete(model.id!, model.name),
                                    );
                                  },
                                ),
                ),
                if (!provider.loading && shown.isNotEmpty)
                  _Counter(models: shown.length, units: totalUnits),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onPlan;
  final String? colorFilter;
  final VoidCallback? onColorTap;
  final VoidCallback onColorClear;
  final StockFilter stockFilter;
  final VoidCallback onStockTap;
  final VoidCallback onStockClear;

  const _Header({
    required this.onAdd,
    required this.onPlan,
    required this.colorFilter,
    required this.onColorTap,
    required this.onColorClear,
    required this.stockFilter,
    required this.onStockTap,
    required this.onStockClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CATÁLOGO', style: AppText.eyebrow()),
                  const SizedBox(height: 3),
                  Text('Modelos', style: AppText.display()),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _PlanButton(onTap: onPlan),
            const SizedBox(width: 9),
            _AddButton(onTap: onAdd),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _FilterPill(
              placeholder: 'Cor',
              label: colorFilter,
              swatch: colorFilter == null ? null : colorSwatch(colorFilter!),
              onTap: onColorTap,
              onClear: onColorClear,
            ),
            const SizedBox(width: 9),
            _FilterPill(
              placeholder: 'Estoque',
              label: stockFilter == StockFilter.all ? null : stockFilter.label,
              onTap: onStockTap,
              onClear: onStockClear,
            ),
          ],
        ),
      ],
    );
  }
}

/// Pill-shaped filter trigger used on the Modelos header. Shows the active
/// value (with an optional color swatch) and a clear affordance, or a muted
/// placeholder + chevron when no filter is applied.
class _FilterPill extends StatelessWidget {
  final String placeholder;
  final String? label;
  final Color? swatch;
  final VoidCallback? onTap;
  final VoidCallback onClear;

  const _FilterPill({
    required this.placeholder,
    required this.label,
    this.swatch,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final active = label != null;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(active ? 8 : 12, 8, active ? 8 : 12, 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimens.pill),
            border: Border.all(color: AppColors.fieldBorder),
            boxShadow: kCardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (active && swatch != null) ...[
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: swatch,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withAlpha(31)),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                active ? label! : placeholder,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: active ? onClear : null,
                child: Icon(
                  active ? Icons.close : Icons.keyboard_arrow_down,
                  size: active ? 14 : 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final String label;
  final Color? swatch;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.label,
    this.swatch,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          children: [
            if (swatch != null) ...[
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withAlpha(31)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 18, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _NoMatchState extends StatelessWidget {
  const _NoMatchState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_alt_off_outlined,
              size: 56, color: AppColors.tabInactive),
          SizedBox(height: 12),
          Text('Nenhum modelo com esses filtros',
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Light icon button (soft card) that opens the weekly production-planning
/// screen, sat next to the dark "add model" button.
class _PlanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppDimens.radiusIcon),
          border: Border.all(color: AppColors.fieldBorder),
          boxShadow: kCardShadow,
        ),
        child: const Icon(Icons.event_note, color: AppColors.ink, size: 21),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class _Counter extends StatelessWidget {
  final int models;
  final int units;
  const _Counter({required this.models, required this.units});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.only(
          top: 6, bottom: 6 + MediaQuery.of(context).padding.bottom),
      child: Text(
        '$models ${models == 1 ? 'modelo' : 'modelos'} · $units unidades',
        style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
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
          Icon(Icons.shopping_bag_outlined,
              size: 64, color: AppColors.tabInactive),
          SizedBox(height: 12),
          Text('Nenhum modelo cadastrado',
              style: TextStyle(color: AppColors.textMuted)),
          SizedBox(height: 4),
          Text('Toque no + para adicionar',
              style: TextStyle(color: AppColors.tabInactive, fontSize: 12)),
        ],
      ),
    );
  }
}
