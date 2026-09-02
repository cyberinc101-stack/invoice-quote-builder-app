// lib/screens/invoice_create_section/invoice_edit_widgets.dart
//
// SUMMARY PASS (this update): added InvoiceTotalsCard — Invoice had no
// totals-card widget at all, unlike QuoteTotalsCard (quote_edit_widgets.dart)
// and ReceiptTotalsCard (receipt_edit_widgets.dart), even though
// InvoiceData already computes subtotal/taxAmount/discountAmount/
// grandTotal (see invoice_data.dart). Mirrors those two widgets' design
// exactly (same row layout, overflow-guarded amount text) so all three
// documents' Summary sections look identical. Used by
// step_customise.dart's new _SummarySection.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Re-export so step files only need one import for helpers
export '../../models/invoice_models.dart';
export '../../services/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final String  message;
  final String? sub;
  final IconData icon;

  const EmptyState({
    super.key,
    this.message = 'Nothing here yet',
    this.sub,
    this.icon    = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.center,
            ),
            if (sub != null) ...[
              const SizedBox(height: 6),
              Text(
                sub!,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// InvoiceTotalsCard
// SUMMARY PASS: mirrors QuoteTotalsCard (quote_edit_widgets.dart) and
// ReceiptTotalsCard (receipt_edit_widgets.dart) exactly — same row
// layout, same overflow guard (maxLines: 1 + ellipsis) on every amount,
// including the final Total line.
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceTotalsCard extends StatelessWidget {
  final double subtotal, taxAmount, discountAmount, total;
  final double taxRate, discountRate;
  final String currencySymbol;
  final Color accent;

  const InvoiceTotalsCard({
    super.key,
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.total,
    required this.taxRate,
    required this.discountRate,
    required this.currencySymbol,
    required this.accent,
  });

  Widget _row(String label, String value, ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7))),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _row('Subtotal', '$currencySymbol ${subtotal.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row('Tax (${taxRate.toStringAsFixed(taxRate % 1 == 0 ? 0 : 1)}%)',
              '$currencySymbol ${taxAmount.toStringAsFixed(2)}', colorScheme),
          const SizedBox(height: 8),
          _row('Discount (${discountRate.toStringAsFixed(discountRate % 1 == 0 ? 0 : 1)}%)',
              '-$currencySymbol ${discountAmount.toStringAsFixed(2)}', colorScheme),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: accent.withValues(alpha: 0.3), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '$currencySymbol ${total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accent),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// StepNavBar
// ─────────────────────────────────────────────────────────────────────────────

class StepNavBar extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool   isLoading;

  const StepNavBar({
    super.key,
    this.onBack,
    this.onNext,
    this.nextLabel = 'Next',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16, 12, 16, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                  size: 22,
                ),
              ),
            ),
          const SizedBox(width: 12),
          if (onNext != null)
            Expanded(
              child: GestureDetector(
                onTap: isLoading ? null : onNext,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isLoading
                          ? [
                              colorScheme.surfaceContainerHighest,
                              colorScheme.surfaceContainerHighest,
                            ]
                          : [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                  ),
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                nextLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
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
