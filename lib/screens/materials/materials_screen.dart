import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../models/material_item.dart';
import '../../providers/material_provider.dart';
import '../../widgets/confirmation_dialog.dart';

final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, MaterialItem mat) async {
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
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MaterialRow({
    required this.mat,
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
                  Text(mat.unit,
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(
              _fmt.format(mat.lastPricePerUnit),
              style: AppText.money(size: 15, weight: FontWeight.w600),
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
