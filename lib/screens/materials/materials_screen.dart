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
import '../../widgets/confirmation_dialog.dart';

final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String _formatStock(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

String _unitSuffix(String unit) =>
    unit.toLowerCase().contains('metro') ? 'm' : 'un.';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  Map<int, double> _need = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNeed();
    });
  }

  /// Loads each model's BOM (same pattern as Home) so we can flag materials
  /// whose stock is below this week's planned production need.
  Future<void> _loadNeed() async {
    final provider = context.read<PurseModelProvider>();
    await provider.loadAll();
    final repo = PurseModelRepository(DatabaseHelper.instance);
    final boms = <PurseModelWithBom>[];
    for (final model in provider.models) {
      if (model.id != null) boms.add(await repo.getWithBom(model.id!));
    }
    if (mounted) setState(() => _need = weeklyMaterialNeed(boms));
  }

  Future<void> _confirmDelete(BuildContext context, MaterialItem mat) async {
    final ok = await showConfirmationDialog(
      context,
      title: 'Excluir material',
      content:
          'Deseja excluir "${mat.name}"? Esta ação não pode ser desfeita.',
    );
    if (ok == true && context.mounted) {
      await context.read<MaterialProvider>().remove(mat.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Consumer<MaterialProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.screenPadH, 16, AppDimens.screenPadH, 12),
                  child: _Header(
                    onAdd: () => context.push('/materials/new'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.screenPadH, 0, AppDimens.screenPadH, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.add_shopping_cart,
                          label: 'Registrar compra',
                          onTap: () async {
                            await context.push('/materials/purchase');
                            if (context.mounted) _loadNeed();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.history,
                          label: 'Histórico',
                          onTap: () => context.push('/materials/purchases'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: provider.loading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.materials.isEmpty
                          ? const _EmptyState()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                  AppDimens.screenPadH, 4, AppDimens.screenPadH, 120),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    '${provider.materials.length} '
                                    '${provider.materials.length == 1 ? 'material cadastrado' : 'materiais cadastrados'}',
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
                                      for (var i = 0;
                                          i < provider.materials.length;
                                          i++) ...[
                                        if (i > 0)
                                          const Divider(
                                              height: 1,
                                              color: AppColors.divider),
                                        _MaterialRow(
                                          mat: provider.materials[i],
                                          low: isMaterialLow(
                                              provider.materials[i], _need),
                                          onTap: () => context.push(
                                              '/materials/${provider.materials[i].id}/edit'),
                                          onLongPress: () => _confirmDelete(
                                              context, provider.materials[i]),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  final MaterialItem mat;
  final bool low;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MaterialRow({
    required this.mat,
    required this.low,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mat.name,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(_fmt.format(mat.lastPricePerUnit),
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            _StockBadge(
              label: '${_formatStock(mat.currentStock)} ${_unitSuffix(mat.unit)}',
              low: low,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill showing the material's current stock; turns peach when low (stock below
/// this week's production need), matching the purse `StockBadge`.
class _StockBadge extends StatelessWidget {
  final String label;
  final bool low;
  const _StockBadge({required this.label, required this.low});

  @override
  Widget build(BuildContext context) {
    final bg = low ? AppColors.peachBg : AppColors.ink.withAlpha(209);
    final fg = low ? AppColors.peachText : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (low) ...[
            const Icon(Icons.warning_amber_rounded,
                size: 13, color: AppColors.peachText),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: AppText.money(size: 13, color: fg, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: softCard(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: AppColors.ink),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
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
              Text('INSUMOS', style: AppText.eyebrow()),
              const SizedBox(height: 3),
              Text('Materiais', style: AppText.display()),
            ],
          ),
        ),
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
          Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.tabInactive),
          SizedBox(height: 12),
          Text('Nenhum material cadastrado',
              style: TextStyle(color: AppColors.textMuted)),
          SizedBox(height: 4),
          Text('Toque no + para adicionar',
              style: TextStyle(color: AppColors.tabInactive, fontSize: 12)),
        ],
      ),
    );
  }
}
