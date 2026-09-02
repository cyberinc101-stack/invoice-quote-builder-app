// expense_card_shared.dart
// lib/widgets/expenses/expense_card_shared.dart
//
// LOGO HIGHLIGHT / LOGO IMAGE PASS (this update): ExpenseGradientAvatar and
// ExpenseLogoBanner both gained showHighlight/showImage params, passed
// straight through to the underlying DocLogoAvatar/DocLogoBanner (see
// doc_card_shared.dart) they delegate to. Both default to true so any
// existing call site that doesn't pass them renders exactly as before.
// expense_cards.dart's call sites now pass
// CardDisplayPrefs.showLogoHighlight/showLogoImage through, same as every
// other doc-family card already does.
//
// SHARED-SOURCE PASS (earlier): ExpenseSelectionBadge, ExpenseThreeDotIcon,
// ExpenseGradientAvatar, and ExpenseLogoBanner no longer contain their own
// rendering logic -- each is now a thin wrapper delegating straight to the
// public widgets in doc_card_shared.dart (SelectionBadge, ThreeDotIcon,
// DocLogoAvatar, DocLogoBanner). Public class names and constructor
// signatures are UNCHANGED, so any other call site (expense_cards.dart,
// expense_screen.dart, etc.) keeps working with zero changes -- only the
// implementation moved, so a visual fix made once in doc_card_shared.dart
// (e.g. the logo-shadow parity fix) now applies to expense cards too,
// automatically, instead of needing the same fix copy-pasted here.
//
// For the avatar/banner delegates: businessName is always passed as ''
// (expenses have no business name to monogram), and fallbackIcon is
// category.icon, so the shared widget's own fallback logic naturally
// renders the category icon instead of an initial -- no separate
// fallback branch needed here.
//
// Everything else in this file (ExpenseCardEntry, date/time formatting,
// ExpenseLayoutMode, ExpenseLayoutToggleButton, ExpenseSortToggleButton,
// ExpenseCategoryAvatar, ExpenseLogoAvatar (legacy), excludedChip /
// excludedChipCompact) is unchanged from the previous pass.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../filters/filter_types.dart';
import '../../models/document_category.dart';
import '../../models/expense_data.dart';
import '../shared_logo_picker.dart' show LogoShape, LogoShapeX, SharedLogoThumbnail;
import '../saved_documents/doc_card_shared.dart';

const Color kExpenseAccent = Color(0xFFE53935);

// -- Pre-computed per-card view model --------------------------------------

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

// -- Date/time formatting helpers -------------------------------------------

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

// -- Layout mode (list / grid / compactGrid / compact) ----------------------

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

// -- Sort toggle --------------------------------------------------------------

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

// -- Selection badge -- delegates to doc_card_shared.dart's SelectionBadge --

class ExpenseSelectionBadge extends StatelessWidget {
  final bool selected;
  final Color accent;

  const ExpenseSelectionBadge({super.key, required this.selected, required this.accent});

  @override
  Widget build(BuildContext context) => SelectionBadge(selected: selected, accent: accent);
}

// -- 3-dot options icon -- delegates to doc_card_shared.dart's ThreeDotIcon --

class ExpenseThreeDotIcon extends StatelessWidget {
  final VoidCallback onTap;
  final Color? background;
  final Color? iconColor;
  const ExpenseThreeDotIcon({super.key, required this.onTap, this.background, this.iconColor});

  @override
  Widget build(BuildContext context) =>
      ThreeDotIcon(onTap: onTap, background: background, iconColor: iconColor);
}

// -- Category avatar (flat, legacy) -- kept for any other call sites. -------

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

// -- Logo avatar (legacy, flat fallback) -- kept for compatibility. ---------

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

// -- Gradient avatar -- delegates to doc_card_shared.dart's DocLogoAvatar.
// businessName is always '' (expenses have no business name), and
// fallbackIcon is the category's own icon, so the shared widget's normal
// fallback path renders the category icon (with the same accent-tinted
// drop shadow every doc-family avatar now gets) instead of a monogram.
// showHighlight/showImage pass straight through to DocLogoAvatar -- see
// that class in doc_card_shared.dart for what each controls. Both default
// to true so existing call sites that don't pass them are unaffected. ----

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
  final bool showHighlight;
  final bool showImage;

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
    this.showHighlight = true,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return DocLogoAvatar(
      logoPath: logoPath,
      logoOffset: logoOffset,
      logoScale: logoScale,
      logoShape: logoShape,
      businessName: '',
      accentColor: category.color,
      size: size,
      width: width,
      height: height,
      iconSize: iconSize,
      borderRadius: borderRadius,
      fallbackIcon: category.icon,
      showHighlight: showHighlight,
      showImage: showImage,
    );
  }
}

// -- Logo banner -- delegates to doc_card_shared.dart's DocLogoBanner, same
// businessName: '' / fallbackIcon: category.icon pattern as the avatar
// above. showHighlight/showImage pass straight through, same as the
// avatar. ----------------------------------------------------------------

class ExpenseLogoBanner extends StatelessWidget {
  final String? logoPath;
  final Offset logoOffset;
  final double logoScale;
  final LogoShape logoShape;
  final DocumentCategory category;
  final double height;
  final double topRadius;
  final bool showHighlight;
  final bool showImage;

  const ExpenseLogoBanner({
    super.key,
    required this.logoPath,
    required this.logoOffset,
    required this.logoScale,
    required this.logoShape,
    required this.category,
    this.height = 110,
    this.topRadius = 18,
    this.showHighlight = true,
    this.showImage = true,
  });

  @override
  Widget build(BuildContext context) {
    return DocLogoBanner(
      logoPath: logoPath,
      logoOffset: logoOffset,
      logoScale: logoScale,
      logoShape: logoShape,
      businessName: '',
      accentColor: category.color,
      height: height,
      topRadius: topRadius,
      fallbackIcon: category.icon,
      showHighlight: showHighlight,
      showImage: showImage,
    );
  }
}

// -- "Excluded" chip ----------------------------------------------------------

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
