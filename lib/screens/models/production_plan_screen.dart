import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/database/database_helper.dart';
import '../../core/planning/material_needs.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/color_swatches.dart';
import '../../models/material_item.dart';
import '../../models/purse_model_with_bom.dart';
import '../../providers/material_provider.dart';
import '../../providers/purse_model_provider.dart';
import '../../repositories/purse_model_repository.dart';

String _formatAmount(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

String _unitSuffix(String unit) =>
    unit.toLowerCase().contains('metro') ? 'm' : 'un.';

class ProductionPlanScreen extends StatefulWidget {
  const ProductionPlanScreen({super.key});

  @override
  State<ProductionPlanScreen> createState() => _ProductionPlanScreenState();
}

class _ProductionPlanScreenState extends State<ProductionPlanScreen> {
  List<PurseModelWithBom> _boms = [];
  final Map<int, int> _targets = {};
  bool _loading = true;
  bool _saving = false;
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
      if (mounted) {
        setState(() {
          _boms = boms;
          _targets
            ..clear()
            ..addEntries(
                boms.map((b) => MapEntry(b.model.id!, b.model.weeklyTarget)));
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<PurseModelProvider>().saveWeeklyTargets(_targets);
    if (mounted) Navigator.of(context).pop();
  }

  /// Recomputes the shopping shortfall from the *unsaved* targets so the summary
  /// reflects what the user is currently planning.
  List<_BuyLine> _toBuy() {
    final projected = _boms
        .map((b) => PurseModelWithBom(
              model: b.model.copyWith(weeklyTarget: _targets[b.model.id] ?? 0),
              bom: b.bom,
            ))
        .toList();
    final need = weeklyMaterialNeed(projected);
    final materials = context.read<MaterialProvider>().materials;
    final lines = <_BuyLine>[];
    for (final m in materials) {
      final qty = materialToBuy(m, need);
      if (qty > 0) lines.add(_BuyLine(material: m, quantity: qty));
    }
    lines.sort((a, b) => a.material.name.compareTo(b.material.name));
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Nav(title: 'Planejar a semana'),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Não foi possível carregar os modelos.\n$_error',
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      : _boms.isEmpty
                          ? const _EmptyState()
                          : _content(),
            ),
            if (!_loading && _error == null && _boms.isNotEmpty)
              _SaveBar(
                saving: _saving,
                onSave: _saving ? null : _save,
              ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final buy = _toBuy();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadH, 6, AppDimens.screenPadH, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Quantas unidades de cada modelo você vai produzir esta semana?',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: softCard(),
          child: Column(
            children: [
              for (var i = 0; i < _boms.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                _ModelPlanRow(
                  data: _boms[i],
                  value: _targets[_boms[i].model.id] ?? 0,
                  onChanged: (v) =>
                      setState(() => _targets[_boms[i].model.id!] = v),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text('A COMPRAR',
            style: AppText.eyebrow(size: 11.5).copyWith(letterSpacing: 0.8)),
        const SizedBox(height: 10),
        if (buy.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: softCard(),
            child: const Text(
              'Estoque suficiente para este plano.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: softCard(),
            child: Column(
              children: [
                for (var i = 0; i < buy.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.divider),
                  _BuyRow(line: buy[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _BuyLine {
  final MaterialItem material;
  final double quantity;
  const _BuyLine({required this.material, required this.quantity});
}

class _ModelPlanRow extends StatelessWidget {
  final PurseModelWithBom data;
  final int value;
  final ValueChanged<int> onChanged;
  const _ModelPlanRow({
    required this.data,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = data.model.color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.model.name,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                if (color != null && color.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _MiniColorChip(label: color),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _Stepper(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _Stepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            filled: false,
            onTap: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppText.money(
                  size: 20, weight: FontWeight.w700, letterSpacing: -0.5),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            filled: true,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;
  const _StepButton(
      {required this.icon, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: filled ? AppColors.ink : AppColors.chipBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon,
              size: 15, color: filled ? Colors.white : AppColors.ink),
        ),
      ),
    );
  }
}

class _BuyRow extends StatelessWidget {
  final _BuyLine line;
  const _BuyRow({required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.material.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${_formatAmount(line.quantity)} ${_unitSuffix(line.material.unit)}',
            style: AppText.money(
                size: 14.5,
                weight: FontWeight.w700,
                color: AppColors.peachText),
          ),
        ],
      ),
    );
  }
}

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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_note_outlined,
              size: 64, color: AppColors.tabInactive),
          SizedBox(height: 12),
          Text('Nenhum modelo cadastrado',
              style: TextStyle(color: AppColors.textMuted)),
          SizedBox(height: 4),
          Text('Cadastre modelos para planejar a produção',
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

class _SaveBar extends StatelessWidget {
  final bool saving;
  final VoidCallback? onSave;
  const _SaveBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadH, 8, AppDimens.screenPadH, 16),
      child: GestureDetector(
        onTap: onSave,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: onSave == null ? AppColors.ink.withAlpha(120) : AppColors.ink,
            borderRadius: BorderRadius.circular(AppDimens.radiusButton),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withAlpha(46),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text(
                  'Salvar planejamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
