// quick_filter_bar.dart
// lib/filters/quick_filter_bar.dart
//
// Horizontal row of smart-filter chips: Needs Action / Overdue / Drafts.
// Sits above DocumentFilterBar in home_screen.dart. Tapping a selected chip
// again clears it (toggle behaviour), same as the existing status chips.

import 'package:flutter/material.dart';
import 'filter_types.dart';

class QuickFilterBar extends StatelessWidget {
  final QuickFilter selected;
  final ValueChanged<QuickFilter> onChanged;
  final int needsActionCount;
  final int overdueCount;
  final int draftsCount;

  const QuickFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.needsActionCount,
    required this.overdueCount,
    required this.draftsCount,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <_QuickChipData>[
      _QuickChipData(
        QuickFilter.needsAction,
        'Needs Action',
        Icons.priority_high_rounded,
        const Color(0xFFF44336),
        needsActionCount,
      ),
      _QuickChipData(
        QuickFilter.overdue,
        'Overdue',
        Icons.schedule_rounded,
        const Color(0xFFFF9800),
        overdueCount,
      ),
      _QuickChipData(
        QuickFilter.drafts,
        'Drafts',
        Icons.edit_note_rounded,
        const Color(0xFF9E9E9E),
        draftsCount,
      ),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final c = chips[i];
          final isSelected = selected == c.filter;
          return _QuickChip(
            label: c.label,
            icon: c.icon,
            color: c.color,
            count: c.count,
            isSelected: isSelected,
            onTap: () => onChanged(isSelected ? QuickFilter.none : c.filter),
          );
        },
      ),
    );
  }
}

class _QuickChipData {
  final QuickFilter filter;
  final String label;
  final IconData icon;
  final Color color;
  final int count;

  const _QuickChipData(this.filter, this.label, this.icon, this.color, this.count);
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isSelected
        ? color.withOpacity(isDark ? 0.28 : 0.15)
        : (isDark ? cs.surfaceContainerHighest : const Color(0xFFF5F5F5));
    final border = isSelected ? color : Colors.transparent;
    final fg = isSelected ? color : cs.onSurface.withOpacity(0.55);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: border, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: fg,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.25)
                      : cs.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
