import 'package:flutter/material.dart';

import '../core/database/database_helper.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text.dart';

/// Pill showing the stock count, e.g. "5 un.".
/// Ink-dark normally; peach when below the low-stock threshold.
class StockBadge extends StatelessWidget {
  final int stock;
  const StockBadge({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final low = stock < kLowStockThreshold;
    final bg = low ? AppColors.peachBg : AppColors.ink.withAlpha(209);
    final fg = low ? AppColors.peachText : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.pill),
      ),
      child: Text(
        '$stock un.',
        style: AppText.money(size: 10.5, color: fg, weight: FontWeight.w600),
      ),
    );
  }
}
