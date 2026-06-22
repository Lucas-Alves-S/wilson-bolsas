import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Frosted three-tab bottom bar (Início · Modelos · Materiais) matching the
/// "Estoque de Bolsas" mockup.
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Início'),
    (
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
      label: 'Modelos'
    ),
    (
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2,
      label: 'Materiais'
    ),
    (icon: Icons.sync_alt, activeIcon: Icons.sync_alt, label: 'Movim.'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xEBF7F4EF), // paper @ ~0.92
            border: Border(top: BorderSide(color: AppColors.navBorder)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            11,
            16,
            11 + MediaQuery.of(context).padding.bottom,
          ),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    item: _items[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ({IconData icon, IconData activeIcon, String label}) item;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.ink : AppColors.tabInactive;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? item.activeIcon : item.icon, size: 24, color: color),
          const SizedBox(height: 5),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
