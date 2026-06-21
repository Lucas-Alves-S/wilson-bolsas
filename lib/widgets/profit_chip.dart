import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class ProfitChip extends StatelessWidget {
  final double profit;
  const ProfitChip({super.key, required this.profit});

  @override
  Widget build(BuildContext context) {
    final positive = profit >= 0;
    final color = positive ? Colors.green.shade700 : Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        _fmt.format(profit),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
