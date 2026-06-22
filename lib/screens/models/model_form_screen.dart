import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  final _colorCtrl = TextEditingController();
  String? _imagePath;
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
      _colorCtrl.text = detail.model.color ?? '';
      setState(() {
        _imagePath = detail.model.imagePath;
        _bom = detail.bom;
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (picked == null) return;
    // Copy the picked file into the app's documents directory so it survives
    // after the original (cache/gallery) entry is gone.
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'model_${DateTime.now().millisecondsSinceEpoch}'
        '${p.extension(picked.path)}';
    final saved = await File(picked.path).copy(p.join(dir.path, fileName));
    if (mounted) setState(() => _imagePath = saved.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final price = double.parse(
        _priceCtrl.text.trim().replaceAll(',', '.'));
    final now = DateTime.now();
    final provider = context.read<PurseModelProvider>();

    final color = _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim();

    if (widget.isEditing) {
      final existing = provider.selected!.model;
      await provider.save(
        existing.copyWith(
          name: _nameCtrl.text.trim(),
          sellingPrice: price,
          color: color,
          imagePath: _imagePath,
          updatedAt: now,
        ),
        _bom,
      );
    } else {
      await provider.add(
        PurseModel(
          name: _nameCtrl.text.trim(),
          sellingPrice: price,
          color: color,
          imagePath: _imagePath,
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
            _ImagePickerField(
              imagePath: _imagePath,
              onPick: _pickImage,
              onClear: () => setState(() => _imagePath = null),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome do modelo'),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _colorCtrl,
              decoration: const InputDecoration(
                labelText: 'Cor (ex: Preta, Caramelo)',
              ),
              textCapitalization: TextCapitalization.words,
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

class _ImagePickerField extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _ImagePickerField({
    required this.imagePath,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && File(imagePath!).existsSync();
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 160,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(imagePath!), fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        iconSize: 18,
                        onPressed: onClear,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      size: 32, color: Theme.of(context).hintColor),
                  const SizedBox(height: 8),
                  Text('Adicionar foto',
                      style: TextStyle(color: Theme.of(context).hintColor)),
                ],
              ),
      ),
    );
  }
}
