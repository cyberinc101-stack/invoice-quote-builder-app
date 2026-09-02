// document_detail_status_card.dart
// lib/screens/saved_invoice_details_section/detail/document_detail_status_card.dart
//
// FORMAL REDESIGN: the glowing colored border + gradient icon badge read
// as an alert/warning toast rather than a status field on a financial
// document. Replaced with a plain neutral card and a thin left-edge
// accent bar in the status color (invoice-ledger convention — a quiet
// category marker, not a klaxon). Icon is now a small flat-tint circle
// instead of a gradient badge with a colored shadow. Everything else
// (description text, day-count chip, secondary date row) is unchanged
// in behavior, just restyled.
//
// BUGFIX #1: Flutter's Border does not allow borderRadius when the four
// BorderSides have different colors — the left side was statusColor
// while the other three were neutral gray, which threw "A borderRadius
// can only be given on borders with uniform colors" on every paint and
// left this whole card blank. The left accent bar is now a real
// Container (a colored strip inside a Row) instead of a colored
// BorderSide, so the outer decoration's border is uniform and the
// borderRadius is legal again.
//
// BUGFIX #2: that Row used crossAxisAlignment.stretch to make the accent
// bar span the card's full height, but this card sits inside a Column
// with unbounded height (SliverToBoxAdapter content), so the Row was
// handed h=Infinity and "stretch to infinity" threw "BoxConstraints
// forces an infinite height". Wrapped the Row in IntrinsicHeight, which
// measures the content's real height first and hands that finite value
// down, so stretch has something concrete to stretch the bar to.
//
// Also adds `neutralAccent` — the app's own navy (kHeroGradient[0]) used
// to tint the card's hairline border instead of a flat unrelated gray,
// matching the rest of the redesigned detail screen.

import 'package:flutter/material.dart';

import '../document_detail_widgets.dart';
import '../../../widgets/saved_documents_containers.dart' show DocType;

class DocumentStatusStatsCard extends StatelessWidget {
  final DocType type;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final Color accent;

  /// The app's own navy (kHeroGradient[0]) — tints the card's hairline
  /// border so it reads as this app's brand color rather than generic gray.
  final Color neutralAccent;

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
    required this.neutralAccent,
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

    String? dayCountLabel;
    if (type == DocType.invoice && statusLabel == 'Overdue' && parsedSecondaryDate != null) {
      final daysPast = today.difference(parsedSecondaryDate).inDays;
      if (daysPast > 0) dayCountLabel = '$daysPast day${daysPast == 1 ? '' : 's'} overdue';
    } else if (type == DocType.quote && statusLabel == 'Sent' && parsedSecondaryDate != null) {
      final daysLeft = parsedSecondaryDate.difference(today).inDays;
      if (daysLeft >= 0) dayCountLabel = '$daysLeft day${daysLeft == 1 ? '' : 's'} left';
    }

    // Neutral hairline border tinted with the app's own navy instead of a
    // flat unrelated gray — matches the rest of the redesigned screen.
    final neutralBorder = neutralAccent.withValues(alpha: isDark ? 0.28 : 0.16);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DetailSectionLabel(label: 'Status'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2235) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              // FIX #1: all four sides now share the same neutral color,
              // so borderRadius is legal here. The colored accent moved
              // to a real left-edge strip below instead of a colored
              // BorderSide.
              border: Border.all(color: neutralBorder),
            ),
            // FIX #2: IntrinsicHeight measures the content's real height
            // first, then hands that finite height down to the Row so
            // `stretch` has something concrete to stretch the accent bar
            // to, instead of the unbounded height this card would
            // otherwise inherit from its sliver/Column context.
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar — a real widget now, not a border trick.
                  Container(width: 4, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(statusIcon, color: statusColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      statusLabel,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colorScheme.onSurface, letterSpacing: -0.2),
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
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.25)),
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
                            Divider(height: 1, color: neutralBorder),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}