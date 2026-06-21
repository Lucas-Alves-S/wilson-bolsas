import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/model_material.dart';
import '../../models/purse_model.dart';
import '../../providers/purse_model_provider.dart';
import '../../widgets/bom_editor.dart';
import '../../widgets/currency_text_field.dart';

class ModelFormScreen extends StatefulWidget {
  final int? modelId;
  const ModelFormScreen({super.key, this.modelId});

  bool get isEditing => modelId != null;

  @override
  State<ModelFormScreen> createState() => _ModelFormScreenState();
}

class _ModelFormScreenState extends State<ModelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  List<ModelMaterial> _bom = [];
  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  Future<void> _loadExisting() async {
    final provider = context.read<PurseModelProvider>();
    await provider.loadDetail(widget.modelId!);
    final detail = provider.selected;
    if (detail != null && mounted) {
      _nameCtrl.text = detail.model.name;
      _priceCtrl.text = detail.model.sellingPrice.toString();
      setState(() {
        _bom = detail.bom;
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final price = double.parse(
        _priceCtrl.text.trim().replaceAll(',', '.'));
    final now = DateTime.now();
    final provider = context.read<PurseModelProvider>();

    if (widget.isEditing) {
      final existing = provider.selected!.model;
      await provider.save(
        existing.copyWith(
          name: _nameCtrl.text.trim(),
          sellingPrice: price,
          updatedAt: now,
        ),
        _bom,
      );
    } else {
      await provider.add(
        PurseModel(
          name: _nameCtrl.text.trim(),
          sellingPrice: price,
          createdAt: now,
          updatedAt: now,
        ),
        _bom,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.isEditing;
    if (isEditing && !_loaded) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? 'Editar modelo' : 'Novo modelo')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar modelo' : 'Novo modelo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome do modelo'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            CurrencyTextField(
              controller: _priceCtrl,
              label: 'Preço de venda',
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            BomEditor(
              entries: _bom,
              onChanged: (updated) => setState(() => _bom = updated),
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
