import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/material_item.dart';
import '../models/model_material.dart';
import '../providers/material_provider.dart';

class BomEditor extends StatelessWidget {
  final List<ModelMaterial> entries;
  final void Function(List<ModelMaterial>) onChanged;

  const BomEditor({
    super.key,
    required this.entries,
    required this.onChanged,
  });

  void _add(BuildContext context, List<MaterialItem> allMaterials) {
    final usedIds = entries.map((e) => e.materialId).toSet();
    final available =
        allMaterials.where((m) => !usedIds.contains(m.id)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os materiais já foram adicionados')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddMaterialSheet(
        available: available,
        onAdd: (mm) {
          onChanged([...entries, mm]);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _remove(int index) {
    final next = [...entries]..removeAt(index);
    onChanged(next);
  }

  void _updateQty(int index, double qty) {
    final next = [...entries];
    next[index] = next[index].copyWith(quantityPerUnit: qty);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final materials = context.watch<MaterialProvider>().materials;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Ficha técnica',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _add(context, materials),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhum material cadastrado ainda.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ),
        ...entries.asMap().entries.map((e) {
          final idx = e.key;
          final mm = e.value;
          final mat =
              materials.where((m) => m.id == mm.materialId).firstOrNull;
          return _BomRow(
            name: mat?.name ?? 'Material #${mm.materialId}',
            unit: mat?.unit ?? '',
            quantity: mm.quantityPerUnit,
            onQuantityChanged: (qty) => _updateQty(idx, qty),
            onRemove: () => _remove(idx),
          );
        }),
      ],
    );
  }
}

class _BomRow extends StatefulWidget {
  final String name;
  final String unit;
  final double quantity;
  final void Function(double) onQuantityChanged;
  final VoidCallback onRemove;

  const _BomRow({
    required this.name,
    required this.unit,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<_BomRow> createState() => _BomRowState();
}

class _BomRowState extends State<_BomRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.quantity.toString().replaceAll(RegExp(r'\.?0+$'), ''),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(widget.name,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _ctrl,
              decoration: InputDecoration(
                suffixText: widget.unit,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              onChanged: (v) {
                final d = double.tryParse(v.replaceAll(',', '.'));
                if (d != null && d > 0) widget.onQuantityChanged(d);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Theme.of(context).colorScheme.error,
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddMaterialSheet extends StatefulWidget {
  final List<MaterialItem> available;
  final void Function(ModelMaterial) onAdd;

  const _AddMaterialSheet({required this.available, required this.onAdd});

  @override
  State<_AddMaterialSheet> createState() => _AddMaterialSheetState();
}

class _AddMaterialSheetState extends State<_AddMaterialSheet> {
  MaterialItem? _selected;
  final _qtyCtrl = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Adicionar material',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            DropdownButtonFormField<MaterialItem>(
              decoration: const InputDecoration(labelText: 'Material'),
              items: widget.available
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.name),
                      ))
                  .toList(),
              onChanged: (m) => setState(() => _selected = m),
              validator: (v) => v == null ? 'Selecione um material' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyCtrl,
              decoration: InputDecoration(
                labelText: 'Quantidade por bolsa',
                suffixText: _selected?.unit ?? '',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              validator: (v) {
                final d = double.tryParse(
                    (v ?? '').trim().replaceAll(',', '.'));
                if (d == null || d <= 0) return 'Quantidade inválida';
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final qty = double.parse(
                      _qtyCtrl.text.trim().replaceAll(',', '.'));
                  widget.onAdd(ModelMaterial(
                    modelId: 0,
                    materialId: _selected!.id!,
                    quantityPerUnit: qty,
                    material: _selected,
                  ));
                },
                child: const Text('Adicionar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
