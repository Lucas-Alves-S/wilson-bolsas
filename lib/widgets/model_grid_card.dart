import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_dimens.dart';
import '../core/theme/app_text.dart';
import '../core/theme/color_swatches.dart';
import '../models/purse_model_with_bom.dart';
import 'stock_badge.dart';

final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// Catalog grid card for the Modelos screen.
class ModelGridCard extends StatelessWidget {
  final PurseModelWithBom data;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ModelGridCard({
    super.key,
    required this.data,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final model = data.model;
    final image = model.imagePath;
    final hasImage = image != null && File(image).existsSync();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: softCard(radius: AppDimens.radiusCardSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo / placeholder
            Stack(
              children: [
                SizedBox(
                  height: 118,
                  width: double.infinity,
                  child: hasImage
                      ? Image.file(File(image), fit: BoxFit.cover)
                      : _Placeholder(seed: model.name),
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: StockBadge(stock: model.currentStock),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.money(size: 15, weight: FontWeight.w600),
                  ),
                  if (model.color != null && model.color!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _ColorChip(label: model.color!),
                  ],
                  const SizedBox(height: 11),
                  _Row(label: 'Venda', value: _money.format(model.sellingPrice)),
                  const SizedBox(height: 6),
                  _Row(
                    label: 'Custo',
                    value: _money.format(data.cost),
                    valueColor: AppColors.costText,
                  ),
                  const SizedBox(height: 7),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: 7),
                  _Row(
                    label: 'Lucro',
                    value: _money.format(data.profit),
                    labelColor: AppColors.profit,
                    valueColor: AppColors.profitStrong,
                    bold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool bold;

  const _Row({
    required this.label,
    required this.value,
    this.labelColor = AppColors.textMuted,
    this.valueColor = AppColors.ink,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: labelColor,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: AppText.money(
            size: bold ? 13.5 : 12.5,
            color: valueColor,
            weight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  const _ColorChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 9, 3),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(AppDimens.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: colorSwatch(label),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withAlpha(31)),
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.chipText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String seed;
  const _Placeholder({required this.seed});

  @override
  Widget build(BuildContext context) {
    final base = pastelFromString(seed);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, Color.lerp(base, Colors.white, 0.45)!],
        ),
      ),
      child: Center(
        child: Text(
          'FOTO',
          style: AppText.money(
            size: 10,
            color: AppColors.ink.withAlpha(70),
            weight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

