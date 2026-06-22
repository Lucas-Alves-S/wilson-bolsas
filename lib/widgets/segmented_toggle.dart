import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Two-option segmented control (e.g. Unidades / Metros) matching the mockup.
class SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.segmentedTrack,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? AppColors.ink : null,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    options[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: i == selectedIndex
                          ? Colors.white
                          : AppColors.costText,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
