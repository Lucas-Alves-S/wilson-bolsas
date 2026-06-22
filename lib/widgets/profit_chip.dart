import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text.dart';

final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Mint/peach currency pill for a model's profit.
class ProfitChip extends StatelessWidget {
  final double profit;
  const ProfitChip({super.key, required this.profit});

  @override
  Widget build(BuildContext context) {
    final positive = profit >= 0;
    final bg = positive ? AppColors.mint.withAlpha(60) : AppColors.peachBg;
    final fg = positive ? AppColors.profitStrong : AppColors.peachText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.pill),
      ),
      child: Text(
        _fmt.format(profit),
        style: AppText.money(size: 12, color: fg, weight: FontWeight.w700),
      ),
    );
  }
}
