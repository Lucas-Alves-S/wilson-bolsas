import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../models/material_item.dart';
import '../../providers/material_provider.dart';
import '../../widgets/segmented_toggle.dart';

class MaterialFormScreen extends StatefulWidget {
  final int? materialId;
  const MaterialFormScreen({super.key, this.materialId});

  bool get isEditing => materialId != null;

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  int _unitIndex = 0; // 0 = Unidades, 1 = Metros
  bool _saving = false;
  MaterialItem? _original;

  static const _units = ['Unidade', 'Metro'];

  /// Renders stored stock without a trailing ".0" for whole numbers.
  String _formatStock(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  void _loadExisting() {
    final provider = context.read<MaterialProvider>();
    final mat =
        provider.materials.where((m) => m.id == widget.materialId).firstOrNull;
    if (mat != null) {
      _original = mat;
      _nameCtrl.text = mat.name;
      _priceCtrl.text = mat.lastPricePerUnit.toString();
      _stockCtrl.text = _formatStock(mat.currentStock);
      _unitIndex = mat.unit.toLowerCase().contains('metro') ? 1 : 0;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final price = double.parse(_priceCtrl.text.trim().replaceAll(',', '.'));
    final stock = _stockCtrl.text.trim().isEmpty
        ? 0.0
        : double.parse(_stockCtrl.text.trim().replaceAll(',', '.'));
    final unit = _units[_unitIndex];
    final now = DateTime.now();
    final provider = context.read<MaterialProvider>();

    if (widget.isEditing && _original != null) {
      await provider.save(_original!.copyWith(
        name: _nameCtrl.text.trim(),
        unit: unit,
        lastPricePerUnit: price,
        currentStock: stock,
        updatedAt: now,
      ));
    } else {
      await provider.add(MaterialItem(
        name: _nameCtrl.text.trim(),
        unit: unit,
        lastPricePerUnit: price,
        currentStock: stock,
        createdAt: now,
        updatedAt: now,
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final perWord = _unitIndex == 1 ? 'metro' : 'unidade';
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Nav(title: widget.isEditing ? 'Editar material' : 'Novo material'),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.screenPadH, 18, AppDimens.screenPadH, 24),
                  children: [
                    _Label('Nome do material'),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration:
                          const InputDecoration(hintText: 'Ex.: Couro legítimo'),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Campo obrigatório'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _Label('Tipo de unidade'),
                    const SizedBox(height: 9),
                    SegmentedToggle(
                      options: const ['Unidades', 'Metros'],
                      selectedIndex: _unitIndex,
                      onSelect: (i) => setState(() => _unitIndex = i),
                    ),
                    const SizedBox(height: 24),
                    _Label('Preço pago'),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _priceCtrl,
                      decoration: InputDecoration(
                        hintText: '0,00',
                        prefixText: 'R\$ ',
                        prefixStyle:
                            AppText.money(size: 16, weight: FontWeight.w600),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Campo obrigatório';
                        }
                        final parsed =
                            double.tryParse(v.trim().replaceAll(',', '.'));
                        if (parsed == null || parsed < 0) return 'Valor inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Valor pago por $perWord deste material.',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    _Label('Estoque atual'),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _stockCtrl,
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: _unitIndex == 1 ? 'm' : 'un.',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final parsed =
                            double.tryParse(v.trim().replaceAll(',', '.'));
                        if (parsed == null || parsed < 0) return 'Valor inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quantidade em estoque. As compras somam aqui '
                      'automaticamente.',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            _SaveBar(
              saving: _saving,
              onSave: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: AppText.eyebrow(size: 11.5).copyWith(letterSpacing: 0.8));
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
            color: onSave == null
                ? AppColors.ink.withAlpha(120)
                : AppColors.ink,
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
                  'Salvar material',
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
