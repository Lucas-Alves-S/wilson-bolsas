import 'package:flutter/material.dart';

/// Maps a free-text Portuguese color name to an approximate swatch, used by the
/// model cards and the Modelos color filter. Falls back to a deterministic
/// pastel for unknown names.
Color colorSwatch(String name) {
  switch (name.trim().toLowerCase()) {
    case 'preta':
    case 'preto':
      return const Color(0xFF211E1B);
    case 'caramelo':
      return const Color(0xFFB5703A);
    case 'vinho':
      return const Color(0xFF7A2E3A);
    case 'bege':
      return const Color(0xFFD9C7A8);
    case 'verde-oliva':
    case 'oliva':
      return const Color(0xFF5E6B3A);
    case 'off-white':
    case 'branco':
      return const Color(0xFFEFEAE0);
    case 'vermelha':
    case 'vermelho':
      return const Color(0xFFB23A3A);
    case 'azul':
      return const Color(0xFF3A5BB2);
    case 'rosa':
      return const Color(0xFFD98AAE);
    case 'marrom':
      return const Color(0xFF6B4A2E);
    default:
      return pastelFromString(name);
  }
}

/// Deterministic pastel from a string, for placeholder gradients.
Color pastelFromString(String s) {
  final h = s.codeUnits.fold<int>(0, (a, c) => a + c) * 47 % 360;
  return HSLColor.fromAHSL(1, h.toDouble(), 0.45, 0.82).toColor();
}
