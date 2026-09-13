// receipt_paper_format_picker.dart
// lib/create_receipt/receipt_paper_format_picker.dart
//
// Radio-style row of paper format options (A4 / 58mm / 80mm). Used two
// places: compact=true under each card in ReceiptTemplateChooserScreen's
// grid, compact=false as a standalone section elsewhere if needed later.

import 'package:flutter/material.dart';
import 'receipt_paper_format.dart';

class ReceiptPaperFormatPicker extends StatelessWidget {
  final ReceiptPaperFormat selected;
  final Color accent;
  final ValueChanged<ReceiptPaperFormat> onChanged;
  final bool compact;

  const ReceiptPaperFormatPicker({
    super.key,
    required this.selected,
    required this.accent,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: compact ? 5 : 8,
      runSpacing: compact ? 5 : 8,
      children: ReceiptPaperFormat.values.map((f) {
        final isSelected = f == selected;
        return GestureDetector(
          onTap: () => onChanged(f),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 7 : 12,
              vertical: compact ? 3 : 7,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? accent
                  : (isDark
                      ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                      : const Color(0xFFF3F4F6)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? accent : colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: compact ? 11 : 14,
                  color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.45),
                ),
                SizedBox(width: compact ? 3 : 5),
                Text(
                  f.label,
                  style: TextStyle(
                    fontSize: compact ? 9.5 : 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
