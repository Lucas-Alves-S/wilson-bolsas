import 'package:flutter/material.dart';

/// Design tokens for the "Estoque de Bolsas" redesign.
///
/// Extracted from the Claude Design mockup (Estoque de Bolsas.dc.html):
/// a warm, pastel palette built on a paper background, ink-dark surfaces,
/// a mint profit accent and a peach low-stock accent.
class AppColors {
  AppColors._();

  // Surfaces
  static const paper = Color(0xFFF7F4EF); // scaffold / app background
  static const card = Color(0xFFFFFFFF); // white cards
  static const pageOuter = Color(0xFFE7E5DF); // outer canvas (unused in-app)

  // Ink / text
  static const ink = Color(0xFF211E1B); // primary text + dark elements
  static const textMuted = Color(0xFF9A948C); // captions / labels
  static const textSubtle = Color(0xFF7D7973); // secondary copy
  static const tabInactive = Color(0xFFB3ADA4); // inactive nav / placeholders
  static const chipText = Color(0xFF6B655D); // chip label text
  static const costText = Color(0xFF8A847C); // muted numeric (cost)

  // Profit (mint)
  static const mint = Color(0xFF8FE3B8); // accent fill
  static const profit = Color(0xFF1F7A52); // profit label
  static const profitStrong = Color(0xFF13633F); // profit value
  static const onMint = Color(0xFF0F3D28); // text on mint fill

  // Low-stock (peach)
  static const peachBg = Color(0xFFFBE6D6);
  static const peachDot = Color(0xFFE0894C);
  static const peachText = Color(0xFF8A4B22);
  static const peachChevron = Color(0xFFC08350);

  // Lines / chips
  static const chipBg = Color(0xFFF3F1EC);
  static const fieldBorder = Color(0xFFE8E2D8);
  static const divider = Color(0xFFF1ECE4);
  static const segmentedTrack = Color(0xFFEBE6DD);
  static const navBorder = Color(0xFFECE7DF);
}
