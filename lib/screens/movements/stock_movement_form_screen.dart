import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/stock_movement.dart';
import '../../providers/purse_model_provider.dart';
import '../../providers/stock_movement_provider.dart';

class StockMovementFormScreen extends StatefulWidget {
  final int modelId;
  const StockMovementFormScreen({super.key, required this.modelId});

  @override
  State<StockMovementFormScreen> createState() =>
      _StockMovementFormScreenState();
}

class _StockMovementFormScreenState extends State<StockMovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _deltaCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _isAddition = true;
  DateTime _date = DateTime.now();
  bool _saving = false;

  static const _reasonSuggestions = [
    'Venda',
    'Produção',
    'Devolução',
    'Correção de estoque',
    'Perda',
  ];

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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final raw = int.parse(_deltaCtrl.text.trim());
    final delta = _isAddition ? raw : -raw;

    final movement = StockMovement(
      modelId: widget.modelId,
      delta: delta,
      reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
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
    _deltaCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Movimentar estoque')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'Entrada',
                    icon: Icons.arrow_upward,
                    selected: _isAddition,
                    color: Colors.green.shade700,
                    onTap: () => setState(() => _isAddition = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'Saída',
                    icon: Icons.arrow_downward,
                    selected: !_isAddition,
                    color: Colors.red.shade700,
                    onTap: () => setState(() => _isAddition = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _deltaCtrl,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                prefixIcon: Icon(
                  _isAddition ? Icons.add : Icons.remove,
                  color: _isAddition
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n <= 0) return 'Informe uma quantidade válida';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (value) => _reasonSuggestions
                  .where((s) =>
                      s.toLowerCase().contains(value.text.toLowerCase()))
                  .toList(),
              onSelected: (s) => _reasonCtrl.text = s,
              fieldViewBuilder: (context, ctrl, focusNode, onEditingComplete) {
                _reasonCtrl.text = ctrl.text;
                return TextFormField(
                  controller: ctrl,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: const InputDecoration(
                    labelText: 'Motivo (opcional)',
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (v) => _reasonCtrl.text = v,
                );
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data',
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(25) : Colors.transparent,
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : Colors.grey,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
