import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../models/material_item.dart';
import '../../models/material_purchase.dart';
import '../../providers/material_provider.dart';
import '../../providers/material_purchase_provider.dart';

final _dateFormat = DateFormat("d 'de' MMMM 'de' y", 'pt_BR');

class MaterialPurchaseFormScreen extends StatefulWidget {
  final int? materialId;
  const MaterialPurchaseFormScreen({super.key, this.materialId});

  @override
  State<MaterialPurchaseFormScreen> createState() =>
      _MaterialPurchaseFormScreenState();
}

class _MaterialPurchaseFormScreenState
    extends State<MaterialPurchaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  int? _materialId;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _materialId = widget.materialId;
    // Without a pre-selected material, prompt the user to pick one once the
    // material list is available.
    if (_materialId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickMaterial());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillPrice());
    }
  }

  MaterialItem? get _material => context
      .read<MaterialProvider>()
      .materials
      .where((m) => m.id == _materialId)
      .firstOrNull;

  void _prefillPrice() {
    final mat = _material;
    if (mat != null && _priceCtrl.text.isEmpty && mat.lastPricePerUnit > 0) {
      _priceCtrl.text = _trim(mat.lastPricePerUnit);
    }
  }

  String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Future<void> _pickMaterial() async {
    final materials = context.read<MaterialProvider>().materials;
    if (materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastre um material primeiro.')),
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final picked = await showModalBottomSheet<MaterialItem>(
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
                    Text('Comprar qual material?',
                        style: AppText.display(size: 18)),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final m in materials)
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(m.unit,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textMuted)),
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
    if (!mounted) return;
    if (picked?.id == null) {
      // User dismissed the picker without choosing — nothing to do here.
      if (_materialId == null) Navigator.of(context).pop();
      return;
    }
    setState(() => _materialId = picked!.id);
    _prefillPrice();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_materialId == null) {
      _pickMaterial();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final qty = double.parse(_qtyCtrl.text.trim().replaceAll(',', '.'));
    final price = double.parse(_priceCtrl.text.trim().replaceAll(',', '.'));
    final purchase = MaterialPurchase(
      materialId: _materialId!,
      quantity: qty,
      unitPrice: price,
      purchasedAt: _date,
    );

    await context.read<MaterialPurchaseProvider>().addPurchase(purchase);
    if (!mounted) return;
    // The purchase mutated material stock + last price in the DB; refresh the
    // catalog so lists and the home warning reflect it.
    await context.read<MaterialProvider>().loadAll();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the material list loads so the chosen material resolves.
    context.watch<MaterialProvider>();
    final mat = _material;
    final unitWord = mat == null
        ? ''
        : (mat.unit.toLowerCase().contains('metro') ? 'm' : 'un.');
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Nav(title: 'Registrar compra'),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimens.screenPadH, 18, AppDimens.screenPadH, 24),
                  children: [
                    _Label('Material'),
                    const SizedBox(height: 9),
                    GestureDetector(
                      onTap: _pickMaterial,
                      child: _ReadOnlyField(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                mat?.name ?? 'Selecionar material',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: mat == null
                                      ? AppColors.textMuted
                                      : AppColors.ink,
                                ),
                              ),
                            ),
                            const Icon(Icons.unfold_more,
                                size: 18, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _Label('Quantidade comprada'),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _qtyCtrl,
                      autofocus: mat != null,
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: unitWord,
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
                        if (parsed == null || parsed <= 0) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    _Label('Preço pago por $unitWord'.trim()),
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
                        if (parsed == null || parsed < 0) {
                          return 'Valor inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atualiza o estoque e o último preço deste material.',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 22),
                    _Label('Data'),
                    const SizedBox(height: 9),
                    GestureDetector(
                      onTap: _pickDate,
                      child: _ReadOnlyField(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _dateFormat.format(_date),
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined,
                                size: 18, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _SaveBar(
              label: 'Registrar compra',
              saving: _saving,
              onSave: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

/// White bordered field surface for read-only/picker values.
class _ReadOnlyField extends StatelessWidget {
  final Widget child;
  const _ReadOnlyField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: child,
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
  final String label;
  final bool saving;
  final VoidCallback? onSave;
  const _SaveBar(
      {required this.label, required this.saving, required this.onSave});

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
              : Text(
                  label,
                  style: const TextStyle(
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
