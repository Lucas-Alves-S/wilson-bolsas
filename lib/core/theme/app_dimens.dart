import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Radii, shadows and shared decorations for the redesign.
class AppDimens {
  AppDimens._();

  // Radii
  static const radiusHero = 28.0;
  static const radiusCard = 22.0;
  static const radiusCardSmall = 20.0;
  static const radiusField = 15.0;
  static const radiusButton = 16.0;
  static const radiusIcon = 14.0;
  static const pill = 999.0;

  // Screen padding
  static const screenPadH = 22.0;
}

/// Soft elevation used by white cards across the app.
const List<BoxShadow> kCardShadow = [
  BoxShadow(
    color: Color(0x0A211E1B), // rgba(33,30,27,.04)
    blurRadius: 2,
    offset: Offset(0, 1),
  ),
  BoxShadow(
    color: Color(0x0D211E1B), // rgba(33,30,27,.05)
    blurRadius: 18,
    offset: Offset(0, 6),
  ),
];

/// White rounded card surface with the soft shadow.
BoxDecoration softCard({double radius = AppDimens.radiusCard}) => BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: kCardShadow,
    );
