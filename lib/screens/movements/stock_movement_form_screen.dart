import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/color_swatches.dart';
import '../../models/purse_model.dart';
import '../../models/stock_movement.dart';
import '../../providers/purse_model_provider.dart';
import '../../providers/stock_movement_provider.dart';
import '../../widgets/segmented_toggle.dart';

final _dateFormat = DateFormat("d 'de' MMMM 'de' y", 'pt_BR');

class StockMovementFormScreen extends StatefulWidget {
  final int modelId;
  const StockMovementFormScreen({super.key, required this.modelId});

  @override
  State<StockMovementFormScreen> createState() =>
      _StockMovementFormScreenState();
}

class _StockMovementFormScreenState extends State<StockMovementFormScreen> {
  final _reasonCtrl = TextEditingController();
  bool _isAddition = true;
  int _quantity = 1;
  DateTime _date = DateTime.now();
  bool _saving = false;

  static const _reasonSuggestions = [
    'Venda',
    'Produção',
    'Devolução',
    'Correção de estoque',
    'Perda',
  ];

  PurseModel? get _model => context
      .read<PurseModelProvider>()
      .models
      .where((m) => m.id == widget.modelId)
      .firstOrNull;

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
    setState(() => _saving = true);

    final delta = _isAddition ? _quantity : -_quantity;
    final reason = _reasonCtrl.text.trim();
    final movement = StockMovement(
      modelId: widget.modelId,
      delta: delta,
      reason: reason.isEmpty ? null : reason,
      movedAt: _date,
    );

    final movProvider = context.read<StockMovementProvider>();
    final modelProvider = context.read<PurseModelProvider>();
    await movProvider.addMovement(movement);
    await modelProvider.loadAll();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
    final color = model?.color;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Nav(title: 'Nova movimentação'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppDimens.screenPadH, 18, AppDimens.screenPadH, 24),
                children: [
                  _Label('Tipo'),
                  const SizedBox(height: 9),
                  SegmentedToggle(
                    options: const ['Entrada', 'Saída'],
                    selectedIndex: _isAddition ? 0 : 1,
                    onSelect: (i) => setState(() => _isAddition = i == 0),
                  ),
                  const SizedBox(height: 22),
                  _Label('Modelo'),
                  const SizedBox(height: 9),
                  _ReadOnlyField(child: _ModelValue(name: model?.name)),
                  if (color != null && color.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _Label('Cor'),
                    const SizedBox(height: 9),
                    _ReadOnlyField(child: _ColorValue(label: color)),
                  ],
                  const SizedBox(height: 22),
                  _Label('Quantidade'),
                  const SizedBox(height: 9),
                  _QuantityStepper(
                    value: _quantity,
                    onChanged: (v) => setState(() => _quantity = v),
                  ),
                  const SizedBox(height: 22),
                  _Label('Motivo (opcional)'),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _reasonCtrl,
                    decoration: const InputDecoration(hintText: 'Ex.: Venda'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _reasonSuggestions)
                        _SuggestionChip(
                          label: s,
                          onTap: () => setState(() => _reasonCtrl.text = s),
                        ),
                    ],
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
            _SaveBar(
              label: _isAddition ? 'Registrar entrada' : 'Registrar saída',
              saving: _saving,
              onSave: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelValue extends StatelessWidget {
  final String? name;
  const _ModelValue({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name ?? 'Modelo selecionado',
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }
}

class _ColorValue extends StatelessWidget {
  final String label;
  const _ColorValue({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: colorSwatch(label),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withAlpha(31)),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// White bordered field surface used to present read-only values (Modelo, Cor,
/// Data) consistently with the form's editable fields.
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

class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusField),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepButton(
            icon: Icons.remove,
            filled: false,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Text(
            '$value',
            style: AppText.money(
                size: 28, weight: FontWeight.w700, letterSpacing: -1),
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: filled ? AppColors.ink : AppColors.chipBg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon,
              size: 16, color: filled ? Colors.white : AppColors.ink),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.chipBg,
          borderRadius: BorderRadius.circular(AppDimens.pill),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.chipText,
          ),
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
