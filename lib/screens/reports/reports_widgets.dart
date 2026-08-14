// reports_widgets.dart
// lib/screens/reports/reports_widgets.dart
//
// Presentational widgets used by reports_screen.dart. Kept dependency-free
// (no provider reads in here) so the screen stays the single source of
// truth for data and these just render whatever numbers they're given.
//
// HOME UI-PARITY PASS (this update): added ReportsHeroCard — a plain
// gradient wrapper using the exact same navy gradient
// (Color(0xFF1A1A2E) -> Color(0xFF16213E) -> Color(0xFF0F3460)) and
// rounded-corner/shadow treatment as HomeScreen's hero banner
// (_buildHeroBanner in home_screen.dart), so Reports' top section now
// reads as the same "premium dark card" as Home's, instead of the old
// flat teal AppBar. reports_screen.dart wraps the period selector, folder
// selector, and DataSourceToggleRow in this card.
//
// DataSourceToggleRow was restyled to live on that dark card: each chip
// now gets its own per-type gradient (blue/purple/green/red), matching
// the colors Home's Create Invoice / Create Quote / Create Receipt CTA
// buttons already use, filled solid when selected and a translucent
// white outline when not — instead of the old single-teal-tint chip.
// The public constructor signature is UNCHANGED except the now-unused
// `accent` param was removed (its only call site is reports_screen.dart,
// updated alongside this file).
//
// Everything else in this file (ReportsStatCard, NetMarginBadge,
// TaxSetAsideCard, CategoryBarRow, TopClientsCard, ReportsEmptyState,
// ReportsSectionHeader) is UNCHANGED from the previous pass.

import 'package:flutter/material.dart';
import '../../models/document_category.dart';

// ── Hero card — same gradient/radius/shadow language as Home's banner ─────

class ReportsHeroCard extends StatelessWidget {
  final Widget child;

  const ReportsHeroCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x401A1A2E),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

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
            color: color.withValues(alpha: isDark ? 0.15 : 0.08),
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
        color: color.withValues(alpha: 0.12),
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

// ── Tax set-aside estimate card ─────────────────────────────────────────────
//
// Deliberately simple: net income for the active period × an adjustable
// rate (default 25%, clamped 0-60% in ReportsPrefs). This is a rough
// planning number, not a tax calculation — copy says so explicitly so it
// doesn't read as filed advice.

class TaxSetAsideCard extends StatelessWidget {
  final double net;
  final double taxRatePercent;
  final bool isDark;
  final Color accent;
  final ValueChanged<double> onRateChanged;

  const TaxSetAsideCard({
    super.key,
    required this.net,
    required this.taxRatePercent,
    required this.isDark,
    required this.accent,
    required this.onRateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasProfit = net > 0;
    final estimate = hasProfit ? net * (taxRatePercent / 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.savings_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tax set-aside estimate',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
              _RateStepper(ratePercent: taxRatePercent, accent: accent, onChanged: onRateChanged),
            ],
          ),
          const SizedBox(height: 10),
          if (!hasProfit)
            Text(
              'No set-aside needed — net is zero or negative this period.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withValues(alpha: 0.5)),
            )
          else ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: estimate),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) => Text(
                animatedValue.toStringAsFixed(2),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'at ${taxRatePercent.toStringAsFixed(0)}% of net income — a rough guide, not tax advice.',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
            ),
          ],
        ],
      ),
    );
  }
}

class _RateStepper extends StatelessWidget {
  final double ratePercent;
  final Color accent;
  final ValueChanged<double> onChanged;

  const _RateStepper({required this.ratePercent, required this.accent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            accent: accent,
            onTap: () => onChanged((ratePercent - 1).clamp(0.0, 60.0)),
          ),
          SizedBox(
            width: 34,
            child: Text(
              '${ratePercent.toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accent),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            accent: accent,
            onTap: () => onChanged((ratePercent + 1).clamp(0.0, 60.0)),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 14, color: accent),
        ),
      ),
    );
  }
}

// ── Data sources toggle row (Invoices / Quotes / Receipts / Expenses chips) ─
//
// Restyled to sit on ReportsHeroCard's dark gradient background. Each chip
// carries its own per-type gradient — the exact colors HomeScreen's
// Create Invoice / Create Quote / Create Receipt CTA buttons use for
// invoices/quotes, plus a matching green for receipts and red for
// expenses — filled solid when selected, translucent white outline when
// not. This replaces the previous single-teal-tint bordered chip design.

class DataSourceToggleRow extends StatelessWidget {
  final bool includeInvoices;
  final bool includeQuotes;
  final bool includeReceipts;
  final bool includeExpenses;
  final ValueChanged<bool> onInvoicesChanged;
  final ValueChanged<bool> onQuotesChanged;
  final ValueChanged<bool> onReceiptsChanged;
  final ValueChanged<bool> onExpensesChanged;

  const DataSourceToggleRow({
    super.key,
    required this.includeInvoices,
    required this.includeQuotes,
    required this.includeReceipts,
    required this.includeExpenses,
    required this.onInvoicesChanged,
    required this.onQuotesChanged,
    required this.onReceiptsChanged,
    required this.onExpensesChanged,
  });

  static const _invoiceGradient = [Color(0xFF2196F3), Color(0xFF1565C0)];
  static const _quoteGradient = [Color(0xFF7B1FA2), Color(0xFF4A148C)];
  static const _receiptGradient = [Color(0xFF43A047), Color(0xFF2E7D32)];
  static const _expenseGradient = [Color(0xFFE53935), Color(0xFFB71C1C)];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HeroToggleChip(
            label: 'Invoices',
            icon: Icons.receipt_long_rounded,
            selected: includeInvoices,
            gradient: _invoiceGradient,
            onChanged: onInvoicesChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HeroToggleChip(
            label: 'Quotes',
            icon: Icons.request_quote_rounded,
            selected: includeQuotes,
            gradient: _quoteGradient,
            onChanged: onQuotesChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HeroToggleChip(
            label: 'Receipts',
            icon: Icons.point_of_sale_rounded,
            selected: includeReceipts,
            gradient: _receiptGradient,
            onChanged: onReceiptsChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _HeroToggleChip(
            label: 'Expenses',
            icon: Icons.payments_rounded,
            selected: includeExpenses,
            gradient: _expenseGradient,
            onChanged: onExpensesChanged,
          ),
        ),
      ],
    );
  }
}

class _HeroToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final List<Color> gradient;
  final ValueChanged<bool> onChanged;

  const _HeroToggleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.gradient,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!selected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? LinearGradient(colors: gradient) : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.16),
            ),
            boxShadow: selected
                ? [BoxShadow(color: gradient.first.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.55),
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
                backgroundColor: category.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(category.color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top clients card ─────────────────────────────────────────────────────
//
// Renders pre-computed, pre-gated, pre-sorted client totals (see
// reports_screen.dart's _topClientsTotals()). Each row shows the client's
// initials, name, total, and a bar scaled against the top client's total.

class TopClientsCard extends StatelessWidget {
  final List<MapEntry<String, double>> entries; // client name -> total
  final bool isDark;
  final Color accent;

  const TopClientsCard({
    super.key,
    required this.entries,
    required this.isDark,
    required this.accent,
  });

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (entries.isEmpty) return const SizedBox.shrink();
    final maxAmount = entries.first.value <= 0 ? 1.0 : entries.first.value;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top clients',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: accent.withValues(alpha: 0.14),
                        child: Text(
                          _initialsFor(entry.key),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        entry.value.toStringAsFixed(2),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: (entry.value / maxAmount).clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedFraction, _) => LinearProgressIndicator(
                        value: animatedFraction,
                        minHeight: 5,
                        backgroundColor: accent.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                  ),
                ],
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
          Icon(Icons.insights_rounded, size: 34, color: colorScheme.onSurface.withValues(alpha: 0.22)),
          const SizedBox(height: 12),
          Text(
            'Nothing here yet',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            'This month has no invoices, quotes, receipts or expenses recorded.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.45)),
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
