import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography helpers for the redesign.
///
/// Space Grotesk drives display text and all numbers/currency (tight tracking,
/// tabular figures); DM Sans is the body family (configured globally on the
/// theme's textTheme).
class AppText {
  AppText._();

  static const _tabular = [FontFeature.tabularFigures()];

  /// Large display heading (screen titles).
  static TextStyle display({
    double size = 30,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w700,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -1.2,
        height: 1.0,
        color: color,
      );

  /// Space Grotesk for numbers/currency, with tabular figures.
  static TextStyle money({
    double size = 13,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = -0.3,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: letterSpacing,
        color: color,
        fontFeatures: _tabular,
      );

  /// Uppercase muted eyebrow / field label.
  static TextStyle eyebrow({
    Color color = AppColors.textMuted,
    double size = 12.5,
  }) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
        color: color,
      );
}
