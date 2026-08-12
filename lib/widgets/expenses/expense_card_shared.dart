// expense_card_shared.dart
// lib/widgets/expenses/expense_card_shared.dart
//
// LOGO FIX (this pass): ExpenseGradientAvatar now supports independent
// width/height (defaulting to `size`, same pattern as _DocLogoAvatar in
// doc_card_shared.dart) instead of always forcing a square. The List
// layout (ExpenseListCard) now passes height: double.infinity inside an
// IntrinsicHeight + CrossAxisAlignment.stretch row so the logo/photo
// fills the card's full height edge-to-edge instead of a small square.
// Grid/compactGrid/compact stay square — not enough room at those sizes.
//
// SORT TOGGLE (earlier pass): ExpenseSortToggleButton, driven by
// SortOption (from filter_types.dart) instead of ExpenseLayoutMode, used
// by expense_screen.dart's count row and Home's "My Expenses" header.
//
// DOC-CARD STYLE PASS (earlier): the expense card system visually matches
// lib/widgets/saved_documents_containers.dart's _DocCard — a two-tone
// gradient icon box with an accent-tinted drop shadow, and an icon+label
// status chip. Each expense's own category colour stands in as its
// "accent" since expenses don't have a single fixed accent colour the way
// invoices/quotes/receipts do.
//
// Everything else — selection mode, the 3-dot menu, folder tags, logo
// fields, reference number — is unchanged in shape; only the visual skin
// and the avatar sizing changed.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../filters/filter_types.dart';
import '../../models/document_category.dart';
import '../../models/expense_data.dart';
import '../shared_logo_picker.dart' show LogoShape, LogoShapeX, SharedLogoThumbnail;

const Color kExpenseAccent = Color(0xFFE53935);

// ── Pre-computed per-card view model ──────────────────────────────────────

class ExpenseCardEntry {
  final String key;
  final ExpenseEntry expense;
  final DocumentCategory category;
  final String editedLabel; // relative, e.g. "37m ago" / "2d ago"
  final String dateLabel; // short date of expense.date, e.g. "8 Aug 2026"
  final String createdLabel; // short date of createdAt
  final VoidCallback onTap;
  final VoidCallback onShowMenu;

  final String? logoPath;
  final Offset logoOffset;
  final double logoScale;
  final LogoShape logoShape;

  final String? folderName;
  final String? referenceNumber;

  const ExpenseCardEntry({
    required this.key,
    required this.expense,
    required this.category,
    required this.editedLabel,
    required this.dateLabel,
    required this.createdLabel,
    required this.onTap,
    required this.onShowMenu,
    this.logoPath,
    this.logoOffset = Offset.zero,
    this.logoScale = 1.0,
    this.logoShape = LogoShape.roundedSquare,
    this.folderName,
    this.referenceNumber,
  });

  bool get excluded => expense.excludeFromReports;
  String get title => expense.vendor.trim().isEmpty ? '(No vendor)' : expense.vendor.trim();
  String get amountLabel => '${expense.currency} ${expense.amount.toStringAsFixed(2)}';
}

// ── Date/time formatting helpers ────────────────────────────────────────

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String formatExpenseShortDate(DateTime dt) => '${dt.day} ${_shortMonths[dt.month - 1]} ${dt.year}';

String formatExpenseRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return formatExpenseShortDate(dt);
}

// ── Layout mode (list / grid / compactGrid / compact) ──────────────────

enum ExpenseLayoutMode { list, grid, compactGrid, compact }

extension ExpenseLayoutModeX on ExpenseLayoutMode {
  IconData get icon {
    switch (this) {
      case ExpenseLayoutMode.list:
        return Icons.view_agenda_rounded;
      case ExpenseLayoutMode.grid:
        return Icons.grid_view_rounded;
      case ExpenseLayoutMode.compactGrid:
        return Icons.apps_rounded;
      case ExpenseLayoutMode.compact:
        return Icons.view_headline_rounded;
    }
  }

  String get label {
    switch (this) {
      case ExpenseLayoutMode.list:
        return 'List';
      case ExpenseLayoutMode.grid:
        return 'Grid';
      case ExpenseLayoutMode.compactGrid:
        return 'Compact grid';
      case ExpenseLayoutMode.compact:
        return 'Compact';
    }
  }
}

class ExpenseLayoutToggleButton extends StatelessWidget {
  final ExpenseLayoutMode selected;
  final ValueChanged<ExpenseLayoutMode> onChanged;

  const ExpenseLayoutToggleButton({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<ExpenseLayoutMode>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Layout',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => ExpenseLayoutMode.values.map((mode) {
        final isSelected = mode == selected;
        return PopupMenuItem<ExpenseLayoutMode>(
          value: mode,
          child: Row(
            children: [
              Icon(mode.icon, size: 18, color: isSelected ? cs.primary : cs.onSurface),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  mode.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_rounded, size: 16, color: cs.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected.icon, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Sort toggle ──────────────────────────────────────────────────────────

class ExpenseSortToggleButton extends StatelessWidget {
  final SortOption selected;
  final ValueChanged<SortOption> onChanged;

  const ExpenseSortToggleButton({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<SortOption>(
      initialValue: selected,
      onSelected: onChanged,
      tooltip: 'Sort',
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => SortOption.values.map((opt) {
        final isSelected = opt == selected;
        return PopupMenuItem<SortOption>(
          value: opt,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  sortOptionLabel(opt),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_rounded, size: 16, color: cs.primary),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 15, color: cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Selection badge — mirrors _SelectionBadge in doc_card_shared.dart ────

class ExpenseSelectionBadge extends StatelessWidget {
  final bool selected;
  final Color accent;

  const ExpenseSelectionBadge({super.key, required this.selected, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accent : Colors.white,
        border: Border.all(color: selected ? accent : Colors.grey.shade400, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))],
      ),
      child: selected ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
    );
  }
}

// ── 3-dot options icon — mirrors _ThreeDotIcon in doc_card_shared.dart ──

class ExpenseThreeDotIcon extends StatelessWidget {
  final VoidCallback onTap;
  const ExpenseThreeDotIcon({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), shape: BoxShape.circle),
        child: Icon(Icons.more_vert_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.65)),
      ),
    );
  }
}

// ── Category avatar (flat, legacy) — kept for any other call sites. ─────

class ExpenseCategoryAvatar extends StatelessWidget {
  final DocumentCategory category;
  final double size;
  final double iconSize;
  final double borderRadius;

  const ExpenseCategoryAvatar({
    super.key,
    required this.category,
    required this.size,
    this.iconSize = 24,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(category.icon, color: category.color, size: iconSize),
    );
  }
}

// ── Logo avatar (legacy, flat fallback) — kept for compatibility. ───────

class ExpenseLogoAvatar extends StatelessWidget {
  final String? logoPath;
  final Offset logoOffset;
  final double logoScale;
  final LogoShape logoShape;
  final DocumentCategory category;
  final double size;
  final double iconSize;
  final double borderRadius;

  const ExpenseLogoAvatar({
    super.key,
    required this.logoPath,
    required this.logoOffset,
    required this.logoScale,
    required this.logoShape,
    required this.category,
    required this.size,
    this.iconSize = 24,
    this.borderRadius = 12,
  });

  bool get _hasLogo =>
      logoPath != null && logoPath!.isNotEmpty && File(logoPath!).existsSync();

  @override
  Widget build(BuildContext context) {
    if (!_hasLogo) {
      return ExpenseCategoryAvatar(
        category: category,
        size: size,
        iconSize: iconSize,
        borderRadius: borderRadius,
      );
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: logoShape.radiusFor(size),
        border: Border.all(color: category.color.withValues(alpha: 0.3), width: 1),
      ),
      child: SharedLogoThumbnail(
        logoPath: logoPath!,
        logoOffset: logoOffset,
        logoScale: logoScale,
        logoShape: logoShape,
        boxSize: size,
      ),
    );
  }
}

// ── Gradient avatar — the doc-card-style icon box. Renders the expense's
// uploaded photo/logo when one is set, otherwise a two-tone gradient box
// in the category's colour with a white icon and a colour-tinted drop
// shadow. width/height now default to `size` (a square) but can be set
// independently — the List layout passes height: double.infinity inside
// an IntrinsicHeight row so the avatar fills the card's full height
// edge-to-edge instead of sitting in a small square. ─────────────────────

class ExpenseGradientAvatar extends StatelessWidget {
  final String? logoPath;
  final Offset logoOffset;
  final double logoScale;
  final LogoShape logoShape;
  final DocumentCategory category;
  final double size;
  final double? width;
  final double? height;
  final double iconSize;
  final double borderRadius;

  const ExpenseGradientAvatar({
    super.key,
    required this.logoPath,
    required this.logoOffset,
    required this.logoScale,
    required this.logoShape,
    required this.category,
    required this.size,
    this.width,
    this.height,
    this.iconSize = 24,
    this.borderRadius = 14,
  });

  bool get _hasLogo =>
      logoPath != null && logoPath!.isNotEmpty && File(logoPath!).existsSync();

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;

    if (_hasLogo) {
      return Container(
        width: w,
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(color: category.color.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: SharedLogoThumbnail(
          logoPath: logoPath!,
          logoOffset: logoOffset,
          logoScale: logoScale,
          logoShape: logoShape,
          boxSize: w,
        ),
      );
    }
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [category.color, category.color.withValues(alpha: 0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: category.color.withValues(alpha: 0.28), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Icon(category.icon, color: Colors.white, size: iconSize),
    );
  }
}

// ── "Excluded" chip ───────────────────────────────────────────────────────

Widget excludedChip() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kExpenseAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_off_rounded, size: 10, color: kExpenseAccent),
          const SizedBox(width: 3),
          const Text(
            'Excluded',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kExpenseAccent),
          ),
        ],
      ),
    );

Widget excludedChipCompact() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: kExpenseAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.visibility_off_rounded, size: 9, color: kExpenseAccent),
          const SizedBox(width: 3),
          const Text(
            'Excluded',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: kExpenseAccent),
          ),
        ],
      ),
    );
