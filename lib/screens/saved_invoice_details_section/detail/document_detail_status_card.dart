// document_detail_status_card.dart
// lib/screens/saved_invoice_details_section/detail/document_detail_status_card.dart
//
// Prominent, professional status summary card for
// SavedDocumentDetailScreen — sits right under the Total/Line Items stat
// row. Previously the only place status showed at all was the small pill
// in the header; there was no dedicated "is this paid?" / "was this
// accepted?" block with supporting detail. This card makes that the
// single, unmissable answer for each document type:
//   - Invoice: Paid / Partial / Unpaid / Overdue, with due date (or paid
//     date once marked paid) and — for Overdue specifically — how many
//     days overdue, computed from the due date so it never drifts out of
//     sync with the badge itself.
//   - Quote: Accepted / Declined / Sent / Expired / Draft, with expiry
//     date and — while still Sent — how many days remain before it
//     expires.
//   - Receipt: Issued / Refunded, with payment date.
//
// Visually: a large icon+label header row (bold, colored to match the
// status), a one-line plain-English description of what that status
// means, then a divider and one or two DetailActivityRow-style stat
// lines reusing the exact same row widget the Activity card below it
// already uses (document_detail_widgets.dart) — same visual language,
// not a new component vocabulary.

import 'package:flutter/material.dart';

import '../document_detail_widgets.dart';
import '../../../widgets/saved_documents_containers.dart' show DocType;

class DocumentStatusStatsCard extends StatelessWidget {
  final DocType type;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final Color accent;

  /// Invoice: "Due" (or "Paid" once paid). Quote: "Expires". Receipt:
  /// "Paid". Matches the same secondaryDateLabel/secondaryDate the rest
  /// of the screen already computes in _liveState().
  final String? secondaryDateLabel;
  final String? secondaryDateValue;

  const DocumentStatusStatsCard({
    super.key,
    required this.type,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.accent,
    this.secondaryDateLabel,
    this.secondaryDateValue,
  });

  String get _description {
    switch (statusLabel) {
      case 'Paid':
        return 'Payment has been received in full.';
      case 'Partial':
        return 'Some payment has been received — balance still outstanding.';
      case 'Unpaid':
        return 'No payment has been recorded yet.';
      case 'Overdue':
        return 'Payment is past the due date.';
      case 'Accepted':
        return 'The client has accepted this quote.';
      case 'Declined':
        return 'The client has declined this quote.';
      case 'Sent':
        return 'Waiting on a response from the client.';
      case 'Expired':
        return "This quote's expiry date has passed.";
      case 'Draft':
        return "This quote hasn't been sent yet.";
      case 'Issued':
        return 'This receipt has been issued to the client.';
      case 'Refunded':
        return 'This payment was refunded.';
      default:
        return '';
    }
  }

  // Parses dates in the app's stored display format ("d MMM yyyy", e.g.
  // "15 Aug 2026") back into a DateTime so overdue/expiring day-counts can
  // be computed here without needing a second copy of the raw DateTime
  // threaded down from _liveState(). Returns null on anything unparseable
  // (e.g. "—") rather than throwing — the day-count row simply doesn't
  // render in that case.
  DateTime? _parseDisplayDate(String? s) {
    if (s == null || s.isEmpty || s == '—') return null;
    const months = {
      'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
      'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
    };
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = months[parts[1]];
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final parsedSecondaryDate = _parseDisplayDate(secondaryDateValue);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Day-count line — only shown for the two states where "how many
    // days" is actually meaningful and computable: an overdue invoice
    // (days past due) or a still-sent quote (days until expiry).
    String? dayCountLabel;
    if (type == DocType.invoice && statusLabel == 'Overdue' && parsedSecondaryDate != null) {
      final daysPast = today.difference(parsedSecondaryDate).inDays;
      if (daysPast > 0) dayCountLabel = '$daysPast day${daysPast == 1 ? '' : 's'} overdue';
    } else if (type == DocType.quote && statusLabel == 'Sent' && parsedSecondaryDate != null) {
      final daysLeft = parsedSecondaryDate.difference(today).inDays;
      if (daysLeft >= 0) dayCountLabel = '$daysLeft day${daysLeft == 1 ? '' : 's'} left';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionLabel(label: 'Status'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2235) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.2),
              boxShadow: [
                BoxShadow(color: statusColor.withValues(alpha: isDark ? 0.15 : 0.1), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusColor, statusColor.withValues(alpha: 0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusLabel,
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.2),
                          ),
                          if (_description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _description,
                              style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.55)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (dayCountLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dayCountLabel,
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
                if (secondaryDateLabel != null && secondaryDateValue != null) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF0F0F0)),
                  const SizedBox(height: 14),
                  DetailActivityRow(
                    icon: Icons.event_rounded,
                    label: secondaryDateLabel!,
                    value: secondaryDateValue!,
                    color: accent,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
