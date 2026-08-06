// reports_widgets.dart
// lib/screens/reports/reports_widgets.dart
//
// Presentational widgets used by reports_screen.dart. Kept dependency-free
// (no provider reads in here) so the screen stays the single source of
// truth for data and these just render whatever numbers they're given.

import 'package:flutter/material.dart';
import '../../models/document_category.dart';

// ── Animated stat card (Income / Expenses / Net) ───────────────────────────

class ReportsStatCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isDark;
  final bool wide;
  final Widget? trailing;

  /// Changing this key restarts the count-up animation (pass the
  /// month + toggle-state signature from the screen).
  final Object animationKey;

  const ReportsStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    required this.animationKey,
    this.wide = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            key: ValueKey(animationKey),
            tween: Tween(begin: 0.0, end: value),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) => Text(
              animatedValue.toStringAsFixed(2),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Net margin badge (small pill: +18% / -6% vs last month) ────────────────

class NetMarginBadge extends StatelessWidget {
  final double? percentChange; // null when there's no comparable prior month

  const NetMarginBadge({super.key, this.percentChange});

  @override
  Widget build(BuildContext context) {
    if (percentChange == null || percentChange!.isNaN || percentChange!.isInfinite) {
      return const SizedBox.shrink();
    }
    final isUp = percentChange! >= 0;
    final color = isUp ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    final sign = isUp ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '$sign${percentChange!.toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Data sources toggle row (Invoices / Quotes / Receipts chips) ───────────

class DataSourceToggleRow extends StatelessWidget {
  final bool includeInvoices;
  final bool includeQuotes;
  final bool includeReceipts;
  final ValueChanged<bool> onInvoicesChanged;
  final ValueChanged<bool> onQuotesChanged;
  final ValueChanged<bool> onReceiptsChanged;
  final Color accent;

  const DataSourceToggleRow({
    super.key,
    required this.includeInvoices,
    required this.includeQuotes,
    required this.includeReceipts,
    required this.onInvoicesChanged,
    required this.onQuotesChanged,
    required this.onReceiptsChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Invoices',
            icon: Icons.receipt_long_rounded,
            selected: includeInvoices,
            accent: accent,
            onChanged: onInvoicesChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleChip(
            label: 'Quotes',
            icon: Icons.request_quote_rounded,
            selected: includeQuotes,
            accent: accent,
            onChanged: onQuotesChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleChip(
            label: 'Receipts',
            icon: Icons.point_of_sale_rounded,
            selected: includeReceipts,
            accent: accent,
            onChanged: onReceiptsChanged,
          ),
        ),
      ],
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? accent.withOpacity(0.14) : colorScheme.onSurface.withOpacity(0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? accent : colorScheme.onSurface.withOpacity(0.12),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: selected ? accent : colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? accent : colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Expense-by-category bar row ─────────────────────────────────────────────

class CategoryBarRow extends StatelessWidget {
  final DocumentCategory category;
  final double amount;
  final double fraction;

  const CategoryBarRow({
    super.key,
    required this.category,
    required this.amount,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 14, color: category.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                ),
              ),
              Text(
                amount.toStringAsFixed(2),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: fraction.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, animatedFraction, _) => LinearProgressIndicator(
                value: animatedFraction,
                minHeight: 6,
                backgroundColor: category.color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation(category.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Friendly empty state for a month with no data at all ───────────────────

class ReportsEmptyState extends StatelessWidget {
  final bool isDark;

  const ReportsEmptyState({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_rounded, size: 34, color: colorScheme.onSurface.withOpacity(0.22)),
          const SizedBox(height: 12),
          Text(
            'Nothing here yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            'This month has no invoices, quotes, receipts or expenses recorded.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.45)),
          ),
        ],
      ),
    );
  }
}

// ── Section header used above the trend strip / status bar / category list ─

class ReportsSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const ReportsSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
