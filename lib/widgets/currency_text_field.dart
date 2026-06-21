import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const CurrencyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'R\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
      ],
      validator: validator ??
          (v) {
            if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
            final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
            if (parsed == null || parsed < 0) return 'Valor inválido';
            return null;
          },
    );
  }
}
