import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/material_item.dart';
import '../../providers/material_provider.dart';
import '../../widgets/currency_text_field.dart';

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
  final _unitCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _saving = false;
  MaterialItem? _original;

  static const _unitSuggestions = [
    'metros',
    'unidades',
    'kg',
    'gramas',
    'litros',
    'pares',
  ];

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
      _unitCtrl.text = mat.unit;
      _priceCtrl.text = mat.lastPricePerUnit.toString();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final price = double.parse(
        _priceCtrl.text.trim().replaceAll(',', '.'));
    final now = DateTime.now();
    final provider = context.read<MaterialProvider>();

    if (widget.isEditing && _original != null) {
      await provider.save(_original!.copyWith(
        name: _nameCtrl.text.trim(),
        unit: _unitCtrl.text.trim(),
        lastPricePerUnit: price,
        updatedAt: now,
      ));
    } else {
      await provider.add(MaterialItem(
        name: _nameCtrl.text.trim(),
        unit: _unitCtrl.text.trim(),
        lastPricePerUnit: price,
        createdAt: now,
        updatedAt: now,
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar material' : 'Novo material'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome do material'),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _unitCtrl.text),
              optionsBuilder: (value) => _unitSuggestions
                  .where((s) =>
                      s.toLowerCase().contains(value.text.toLowerCase()))
                  .toList(),
              onSelected: (s) => _unitCtrl.text = s,
              fieldViewBuilder:
                  (context, ctrl, focusNode, onEditingComplete) {
                _unitCtrl.text = ctrl.text;
                return TextFormField(
                  controller: ctrl,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  decoration: const InputDecoration(
                    labelText: 'Unidade (ex: metros, unidades)',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo obrigatório'
                      : null,
                  onChanged: (v) => _unitCtrl.text = v,
                );
              },
            ),
            const SizedBox(height: 16),
            CurrencyTextField(
              controller: _priceCtrl,
              label: 'Preço por unidade',
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
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
