// alerts_screen.dart
// lib/screens/alerts_screen.dart
//
// PROFESSIONAL RESTYLE (this pass): replaced the bold gradient hero +
// colorful pill filters with a clean, minimal look closer to a native
// settings/notifications screen — plain white/surface AppBar, a discreet
// single-row stats strip (small icon + number, muted colors, thin
// dividers instead of tinted boxes), flat segmented-style filter tabs
// instead of colored gradient chips, and list-style cards with a small
// neutral icon circle, subtle 1px divider, and minimal color usage
// (color only appears on the icon and on genuinely urgent text, not as
// background fills or gradients). No behavioral changes: same filters,
// same swipe-to-dismiss / advance-recurring logic, same Undo snackbar,
// same snooze buttons, same per-type disabled states, same navigation on
// tap.
//
// PER-TYPE GATING (earlier pass): buildAlerts() here receives the same
// four AlertPrefs flags home_screen.dart's bell badge reads, so a type
// turned off in Settings disappears from both places consistently. Filter
// tabs for a turned-off type render as "<Label> · Off" and the empty
// state explains why, with a shortcut to Settings.
//
// UNDO (earlier pass): swiping away a non-recurring reminder-type alert
// offers Undo via ReminderProvider.restoreReminder().
//
// REMINDER DISMISS: a custom reminder's AlertCard is wrapped in a
// Dismissible (swipe left) that calls ReminderProvider directly — no need
// to open the Reminders screen just to clear one. Only reminder-type
// alerts get this; document alerts (overdue/expiring/draft) aren't
// deletable from here since they're derived from the document itself.
//
// RECURRENCE-AWARE DISMISS (earlier pass): swiping a recurring reminder
// advances it to its next occurrence (via advanceRecurringReminder)
// instead of deleting the series — matching the same behavior on the
// Reminders screen. Only a non-recurring reminder actually goes away, with
// Undo.
//
// SNOOZE (earlier pass): due reminder alert cards show two quick Snooze
// buttons ("1h" / "Tomorrow") that push the reminder's time back without
// touching it otherwise — handy for "not now, but don't lose this."

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../models/invoice_data.dart' show PaymentStatus;
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import '../alerts/alert_types.dart';
import '../alerts/alert_engine.dart';
import '../alerts/alert_prefs.dart';
import '../alerts/custom_reminders/reminder_provider.dart';
import '../alerts/custom_reminders/reminder_model.dart';
import '../alerts/custom_reminders/reminder_screen.dart';
import '../widgets/saved_documents_containers.dart' show DocType;
import 'saved_invoice_details_section/saved_document_detail_screen.dart';
import 'settings_screen.dart';
import '../services/invoice_pdf_service.dart';
import '../services/quote_pdf_service.dart';
import '../services/receipt_pdf_service.dart';

enum AlertFilter { all, overdue, expiring, drafts, reminders }

String _alertFilterLabel(AlertFilter f) {
  switch (f) {
    case AlertFilter.all: return 'All';
    case AlertFilter.overdue: return 'Overdue';
    case AlertFilter.expiring: return 'Expiring';
    case AlertFilter.drafts: return 'Drafts';
    case AlertFilter.reminders: return 'Reminders';
  }
}

IconData _alertFilterIcon(AlertFilter f) {
  switch (f) {
    case AlertFilter.all: return Icons.notifications_rounded;
    case AlertFilter.overdue: return Icons.warning_amber_rounded;
    case AlertFilter.expiring: return Icons.hourglass_bottom_rounded;
    case AlertFilter.drafts: return Icons.edit_note_rounded;
    case AlertFilter.reminders: return Icons.notifications_active_rounded;
  }
}

// Muted, low-saturation accents — used sparingly (icon tint / urgent text
// only), never as a background fill or gradient, matching the reference
// screens' restrained use of color.
Color _alertFilterColor(AlertFilter f, ColorScheme cs) {
  switch (f) {
    case AlertFilter.all: return cs.onSurface.withValues(alpha: 0.6);
    case AlertFilter.overdue: return const Color(0xFFC62828);
    case AlertFilter.expiring: return const Color(0xFFC62828);
    case AlertFilter.drafts: return const Color(0xFFB26A00);
    case AlertFilter.reminders: return const Color(0xFF1565C0);
  }
}

bool _matchesFilter(AlertItem a, AlertFilter f) {
  switch (f) {
    case AlertFilter.all: return true;
    case AlertFilter.overdue: return a.type == AlertType.overdueInvoice;
    case AlertFilter.expiring: return a.type == AlertType.quoteExpiringSoon;
    case AlertFilter.drafts: return a.type == AlertType.draftInProgress;
    case AlertFilter.reminders: return a.type == AlertType.customReminder;
  }
}

// Short uppercase document-type badge shown on each card, so a glance at
// the left edge tells you what kind of thing this alert is about without
// reading the title.
String _docTypeBadge(AlertItem a) {
  if (a.reminder != null) return 'REMINDER';
  switch (a.docType) {
    case DocType.invoice: return 'INVOICE';
    case DocType.quote: return 'QUOTE';
    case DocType.receipt: return 'RECEIPT';
    default: return '';
  }
}

// "3m ago" / "2h ago" / "5d ago" for a due reminder's remindAt. Reminders
// shown on this screen are always already-due (ReminderProvider.dueReminders
// filters on isDue), so this only ever needs to look backwards.
String _dueSince(DateTime remindAt) {
  final elapsed = DateTime.now().difference(remindAt);
  if (elapsed.inMinutes < 1) return 'Just now';
  if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
  if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
  return '${elapsed.inDays}d ago';
}

// ── Follow Up ────────────────────────────────────────────────────────────
// Regenerates the linked document's PDF and opens the OS share sheet
// (email/WhatsApp/SMS/etc.) with a friendly, canned follow-up message
// prefilled — the user just picks the channel and taps send. Nothing here
// sends anything automatically or silently; it's a one-tap shortcut to
// the same manual "re-send the PDF with a note" flow the user already
// does today, just without having to hunt the document down first.
//
// Shown on any alert that carries a linked invoice/quote/receipt —
// overdue invoices, expiring quotes, and draft nudges for all three
// document types.

bool _hasFollowUpTarget(AlertItem a) =>
    a.invoice != null || a.quote != null || a.receipt != null;

String _followUpMessage(AlertItem a) {
  if (a.invoice != null) {
    final inv = a.invoice!;
    final amount = inv.data.grandTotal.toStringAsFixed(2);
    return 'Hi ${inv.data.clientName.isEmpty ? 'there' : inv.data.clientName}, '
        'just a friendly follow-up on invoice ${inv.data.invoiceNumber} '
        '(${amount}) — let me know if you have any questions. Thanks!';
  }
  if (a.quote != null) {
    final q = a.quote!;
    return 'Hi ${q.data.clientName.isEmpty ? 'there' : q.data.clientName}, '
        'following up on the quote ${q.data.quoteNumber} I sent over — '
        "let me know if you'd like to go ahead or if you have any questions!";
  }
  if (a.receipt != null) {
    final r = a.receipt!;
    return 'Hi ${r.data.clientName.isEmpty ? 'there' : r.data.clientName}, '
        'here is a copy of receipt ${r.data.receiptNumber} for your records. '
        'Let me know if you need anything else!';
  }
  return '';
}

Future<void> _sendFollowUp(BuildContext context, AlertItem a) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    if (a.invoice != null) {
      await InvoicePdfService().generateAndSharePDF(
        a.invoice!,
        shareText: _followUpMessage(a),
      );
    } else if (a.quote != null) {
      await QuotePdfService().generateAndSharePDF(
        a.quote!,
        shareText: _followUpMessage(a),
      );
    } else if (a.receipt != null) {
      await ReceiptPdfService().generateAndSharePDF(
        a.receipt!,
        shareText: _followUpMessage(a),
      );
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      content: Text('Could not prepare the follow-up: $e'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// Marks the linked invoice as paid directly from its overdue alert card —
// clears the debt (stamping paidDate via InvoiceProvider.
// updateSavedInvoiceStatus) and, because that same call also re-syncs the
// document's push notification, immediately cancels the pending overdue
// push. The alert then disappears from this list on the next rebuild
// (buildAlerts() no longer finds it overdue), so there's no separate
// "dismiss" step needed here.
Future<void> _markInvoicePaid(BuildContext context, AlertItem alert) async {
  final invoice = alert.invoice;
  if (invoice == null) return;
  context.read<InvoiceProvider>().updateSavedInvoiceStatus(invoice.id, PaymentStatus.paid);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('"${invoice.title}" marked as paid'),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertFilter _selectedFilter = AlertFilter.all;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alertPrefs = context.watch<AlertPrefs>();
    final alertsEnabled = alertPrefs.alertsEnabled;
    final dueReminders = context.watch<ReminderProvider>().dueReminders;

    final disabledFilters = <AlertFilter>{
      if (!alertPrefs.overdueInvoicesEnabled) AlertFilter.overdue,
      if (!alertPrefs.quotesExpiringEnabled) AlertFilter.expiring,
      if (!alertPrefs.draftsEnabled) AlertFilter.drafts,
      if (!alertPrefs.remindersEnabled) AlertFilter.reminders,
    };

    return Consumer3<InvoiceProvider, QuoteProvider, ReceiptProvider>(
      builder: (context, invoiceProvider, quoteProvider, receiptProvider, _) {
        final alerts = alertsEnabled
            ? buildAlerts(
                invoices: invoiceProvider.savedInvoices,
                quotes: quoteProvider.savedQuotes,
                receipts: receiptProvider.savedReceipts,
                dueReminders: dueReminders,
                overdueInvoicesEnabled: alertPrefs.overdueInvoicesEnabled,
                quotesExpiringEnabled: alertPrefs.quotesExpiringEnabled,
                draftsEnabled: alertPrefs.draftsEnabled,
                remindersEnabled: alertPrefs.remindersEnabled,
              )
            : <AlertItem>[];

        final overdueCount = alerts.where((a) => a.type == AlertType.overdueInvoice).length;
        final expiringCount = alerts.where((a) => a.type == AlertType.quoteExpiringSoon).length;
        final draftsCount = alerts.where((a) => a.type == AlertType.draftInProgress).length;
        final remindersCount = alerts.where((a) => a.type == AlertType.customReminder).length;

        final filtered = alerts.where((a) => _matchesFilter(a, _selectedFilter)).toList();
        final highPriority = filtered.where((a) => a.priority == AlertPriority.high).toList();
        final mediumPriority = filtered.where((a) => a.priority == AlertPriority.medium).toList();

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF14162220) : const Color(0xFFF7F8FA),
          appBar: AppBar(
            title: const Text('Alerts'),
            elevation: 0,
            scrolledUnderElevation: 0.5,
            backgroundColor: isDark ? const Color(0xFF14162220) : const Color(0xFFF7F8FA),
            foregroundColor: cs.onSurface,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.alarm_add_rounded),
                tooltip: 'Manage Reminders',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RemindersScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Alert Settings',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          body: !alertsEnabled
              ? Column(
                  children: [
                    _AlertsStatsBar(
                      overdueCount: 0,
                      expiringCount: 0,
                      draftsCount: 0,
                      remindersCount: 0,
                      disabled: true,
                    ),
                    const Expanded(child: _DisabledState()),
                  ],
                )
              : Column(
                  children: [
                    _AlertsStatsBar(
                      overdueCount: overdueCount,
                      expiringCount: expiringCount,
                      draftsCount: draftsCount,
                      remindersCount: remindersCount,
                    ),
                    _FilterTabRow(
                      selected: _selectedFilter,
                      totalCount: alerts.length,
                      overdueCount: overdueCount,
                      expiringCount: expiringCount,
                      draftsCount: draftsCount,
                      remindersCount: remindersCount,
                      disabledFilters: disabledFilters,
                      onChanged: (f) => setState(() => _selectedFilter = f),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyState(
                              filter: _selectedFilter,
                              hasAnyAlerts: alerts.isNotEmpty,
                              isTypeDisabled: disabledFilters.contains(_selectedFilter),
                            )
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: [
                                if (_selectedFilter == AlertFilter.all) ...[
                                  if (highPriority.isNotEmpty) ...[
                                    _GroupHeader(label: 'Needs Action', count: highPriority.length),
                                    const SizedBox(height: 6),
                                    _CardGroup(children: highPriority.map((a) => _AlertCardWrapper(alert: a)).toList()),
                                    const SizedBox(height: 20),
                                  ],
                                  if (mediumPriority.isNotEmpty) ...[
                                    _GroupHeader(label: 'Drafts To Finish', count: mediumPriority.length),
                                    const SizedBox(height: 6),
                                    _CardGroup(children: mediumPriority.map((a) => _AlertCardWrapper(alert: a)).toList()),
                                  ],
                                ] else
                                  _CardGroup(children: filtered.map((a) => _AlertCardWrapper(alert: a)).toList()),
                              ],
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

// ── Discreet stats strip ─────────────────────────────────────────────────
// A single thin row of small icon+number pairs separated by hairline
// dividers — replaces the old full-bleed gradient hero. Sits directly
// under the AppBar as a plain surface card, matching the understated
// "settings list" tone of the reference screens rather than a dashboard
// banner.

class _AlertsStatsBar extends StatelessWidget {
  final int overdueCount;
  final int expiringCount;
  final int draftsCount;
  final int remindersCount;
  final bool disabled;

  const _AlertsStatsBar({
    required this.overdueCount,
    required this.expiringCount,
    required this.draftsCount,
    required this.remindersCount,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(child: _StatCell(icon: Icons.warning_amber_rounded, label: 'Overdue', count: overdueCount, disabled: disabled)),
          _VDivider(),
          Expanded(child: _StatCell(icon: Icons.hourglass_bottom_rounded, label: 'Expiring', count: expiringCount, disabled: disabled)),
          _VDivider(),
          Expanded(child: _StatCell(icon: Icons.edit_note_rounded, label: 'Drafts', count: draftsCount, disabled: disabled)),
          _VDivider(),
          Expanded(child: _StatCell(icon: Icons.notifications_active_rounded, label: 'Reminders', count: remindersCount, disabled: disabled)),
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(width: 1, height: 30, color: cs.outline.withValues(alpha: 0.14));
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool disabled;
  const _StatCell({required this.icon, required this.label, required this.count, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: disabled ? 0.25 : 0.55);
    final strong = cs.onSurface.withValues(alpha: disabled ? 0.3 : 0.85);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: muted),
        const SizedBox(height: 4),
        Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: strong)),
        const SizedBox(height: 1),
        Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: muted)),
      ],
    );
  }
}

// ── Filter tabs ─────────────────────────────────────────────────────────
// Flat, low-contrast segmented tabs — a light gray track with a small
// white/selected pill, no gradients or drop shadows. Closer to the
// reference screenshots' restrained visual language than the previous
// colorful chip row.

class _FilterTabRow extends StatelessWidget {
  final AlertFilter selected;
  final int totalCount;
  final int overdueCount;
  final int expiringCount;
  final int draftsCount;
  final int remindersCount;
  final Set<AlertFilter> disabledFilters;
  final ValueChanged<AlertFilter> onChanged;

  const _FilterTabRow({
    required this.selected,
    required this.totalCount,
    required this.overdueCount,
    required this.expiringCount,
    required this.draftsCount,
    required this.remindersCount,
    required this.disabledFilters,
    required this.onChanged,
  });

  int _countFor(AlertFilter f) {
    switch (f) {
      case AlertFilter.all: return totalCount;
      case AlertFilter.overdue: return overdueCount;
      case AlertFilter.expiring: return expiringCount;
      case AlertFilter.drafts: return draftsCount;
      case AlertFilter.reminders: return remindersCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final f in AlertFilter.values) ...[
            _FilterTab(
              filter: f,
              count: _countFor(f),
              selected: selected == f,
              typeDisabled: disabledFilters.contains(f),
              onTap: () => onChanged(f),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final AlertFilter filter;
  final int count;
  final bool selected;
  final bool typeDisabled;
  final VoidCallback onTap;

  const _FilterTab({
    required this.filter,
    required this.count,
    required this.selected,
    required this.typeDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final label = typeDisabled
        ? '${_alertFilterLabel(filter)} · Off'
        : '${_alertFilterLabel(filter)} · $count';

    final bg = typeDisabled
        ? cs.onSurface.withValues(alpha: 0.04)
        : (selected
            ? (isDark ? Colors.white.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.88))
            : (isDark ? const Color(0xFF1E2235) : Colors.white));

    final textColor = typeDisabled
        ? cs.onSurface.withValues(alpha: 0.28)
        : (selected ? (isDark ? Colors.white : Colors.white) : cs.onSurface.withValues(alpha: 0.6));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: typeDisabled
                ? cs.outline.withValues(alpha: 0.1)
                : (selected ? Colors.transparent : cs.outline.withValues(alpha: 0.14)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              typeDisabled ? Icons.notifications_off_outlined : _alertFilterIcon(filter),
              size: 13,
              color: textColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ── States ───────────────────────────────────────────────────────────────

class _DisabledState extends StatelessWidget {
  const _DisabledState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(icon: Icons.notifications_off_rounded, color: cs.onSurface.withValues(alpha: 0.35)),
            const SizedBox(height: 16),
            Text(
              'Alerts are turned off',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 4),
            Text(
              "You won't see overdue, expiring, or draft nudges until you turn this back on.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: const Text('Go to Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AlertFilter filter;
  final bool hasAnyAlerts;
  final bool isTypeDisabled;
  const _EmptyState({required this.filter, required this.hasAnyAlerts, this.isTypeDisabled = false});

  ({String title, String subtitle}) get _copy {
    if (isTypeDisabled) {
      return (
        title: '${_alertFilterLabel(filter)} alerts are off',
        subtitle: 'Turn this alert type back on in Settings to see it here.',
      );
    }
    switch (filter) {
      case AlertFilter.all:
        return (
          title: "You're all caught up",
          subtitle: 'No overdue invoices, expiring quotes, due reminders, or unfinished drafts.',
        );
      case AlertFilter.overdue:
        return (title: 'No overdue invoices', subtitle: 'Every invoice is either paid or still within its due date.');
      case AlertFilter.expiring:
        return (title: 'No quotes expiring soon', subtitle: "Nothing's coming up on an expiry date right now.");
      case AlertFilter.drafts:
        return (title: 'No drafts waiting', subtitle: 'Every invoice, quote, and receipt is finished.');
      case AlertFilter.reminders:
        return (title: 'No due reminders', subtitle: "You're not overdue on any custom reminder right now.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final copy = _copy;
    final color = isTypeDisabled ? cs.onSurface.withValues(alpha: 0.35) : cs.onSurface.withValues(alpha: 0.4);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBadge(
              icon: isTypeDisabled
                  ? Icons.notifications_off_outlined
                  : (filter == AlertFilter.all ? Icons.check_circle_outline_rounded : _alertFilterIcon(filter)),
              color: filter == AlertFilter.all && !isTypeDisabled ? const Color(0xFF2E7D32) : color,
            ),
            const SizedBox(height: 16),
            Text(
              copy.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 4),
            Text(
              copy.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
            ),
            if (isTypeDisabled) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: const Text('Go to Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Soft circular icon badge used by the empty/disabled states.
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 28, color: color),
    );
  }
}

// Plain section label — small caps-style header, no colored bar, matching
// the reference screens' section headers (e.g. "Explore" tab groupings).
class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  const _GroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

// Wraps a list of cards in a single rounded surface with hairline
// dividers between rows — the "grouped settings list" look from the
// reference screens, instead of each card floating separately with its
// own shadow.
class _CardGroup extends StatelessWidget {
  final List<Widget> children;
  const _CardGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, thickness: 1, indent: 60, color: cs.outline.withValues(alpha: 0.1)),
          ],
        ],
      ),
    );
  }
}

// ── Alert card wrapper — adds swipe-to-dismiss for reminder-type alerts ──

class _AlertCardWrapper extends StatelessWidget {
  final AlertItem alert;
  const _AlertCardWrapper({required this.alert});

  @override
  Widget build(BuildContext context) {
    if (alert.reminder == null) {
      return _AlertCard(alert: alert);
    }

    final reminder = alert.reminder!;
    final isRecurring = reminder.isRecurring;

    return Dismissible(
      key: ValueKey('reminder_alert_${reminder.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFC62828).withValues(alpha: 0.1),
        child: Icon(
          isRecurring ? Icons.repeat_rounded : Icons.delete_outline_rounded,
          color: const Color(0xFFC62828),
          size: 20,
        ),
      ),
      onDismissed: (_) {
        final provider = context.read<ReminderProvider>();
        if (isRecurring) {
          provider.advanceRecurringReminder(reminder.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('"${alert.title}" moved to its next occurrence'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        } else {
          provider.deleteReminder(reminder.id);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Reminder "${alert.title}" dismissed'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => provider.restoreReminder(reminder),
            ),
          ));
        }
      },
      child: _AlertCard(alert: alert),
    );
  }
}

// Flat list-row card — small neutral icon circle, title + subtitle, a
// muted document-type tag, and a chevron. No accent bar, no drop shadow,
// no tinted background: the row sits inside _CardGroup's shared surface
// and is separated from its neighbours by a hairline divider only,
// matching the reference screens' plain list rows.
class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  const _AlertCard({required this.alert});

  IconData get _icon {
    switch (alert.type) {
      case AlertType.overdueInvoice:
        return Icons.warning_amber_rounded;
      case AlertType.quoteExpiringSoon:
        return Icons.hourglass_bottom_rounded;
      case AlertType.draftInProgress:
        return Icons.edit_note_rounded;
      case AlertType.customReminder:
        return Icons.notifications_active_rounded;
    }
  }

  Color get _color {
    switch (alert.priority) {
      case AlertPriority.high:
        return alert.type == AlertType.customReminder ? const Color(0xFF1565C0) : const Color(0xFFC62828);
      case AlertPriority.medium:
        return const Color(0xFFB26A00);
    }
  }

  void _onTap(BuildContext context) {
    Widget? screen;
    if (alert.invoice != null) {
      screen = SavedDocumentDetailScreen.invoice(alert.invoice!);
    } else if (alert.quote != null) {
      screen = SavedDocumentDetailScreen.quote(alert.quote!);
    } else if (alert.receipt != null) {
      screen = SavedDocumentDetailScreen.receipt(alert.receipt!);
    } else if (alert.reminder != null) {
      screen = RemindersScreen(highlightReminderId: alert.reminder!.id);
    }
    if (screen == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isReminder = alert.type == AlertType.customReminder && alert.reminder != null;
    final badge = _docTypeBadge(alert);
    final color = _color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: color, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isReminder) ...[
                          const SizedBox(width: 6),
                          Text(
                            _dueSince(alert.reminder!.remindAt),
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.4)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (badge.isNotEmpty) ...[
                          Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                          Text(
                            '  ·  ',
                            style: TextStyle(fontSize: 10, color: cs.onSurface.withValues(alpha: 0.25)),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            alert.subtitle,
                            style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (!isReminder && _hasFollowUpTarget(alert)) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _FollowUpButton(onTap: () => _sendFollowUp(context, alert)),
                          if (alert.type == AlertType.overdueInvoice && alert.invoice != null) ...[
                            const SizedBox(width: 6),
                            _MarkPaidButton(onTap: () => _markInvoicePaid(context, alert)),
                          ],
                        ],
                      ),
                    ],
                    if (isReminder) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SnoozeButton(
                            label: '1h',
                            onTap: () => context
                                .read<ReminderProvider>()
                                .snoozeReminder(alert.reminder!.id, const Duration(hours: 1)),
                          ),
                          const SizedBox(width: 6),
                          _SnoozeButton(
                            label: 'Tomorrow',
                            onTap: () => context
                                .read<ReminderProvider>()
                                .snoozeReminder(alert.reminder!.id, const Duration(days: 1)),
                          ),
                          const Spacer(),
                          Icon(Icons.swipe_left_alt_rounded, size: 11, color: cs.onSurface.withValues(alpha: 0.25)),
                          const SizedBox(width: 3),
                          Text(
                            alert.reminder!.isRecurring ? 'Swipe to advance' : 'Swipe to dismiss',
                            style: TextStyle(fontSize: 9.5, color: cs.onSurface.withValues(alpha: 0.25)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!isReminder)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 2),
                  child: Icon(Icons.chevron_right_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.25)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Follow Up pill button — regenerates the linked document's PDF and
// opens the OS share sheet with a canned message prefilled (see
// _sendFollowUp above). Uses cs.primary so it reads as a real action,
// distinct from the neutral Snooze buttons.
class _FollowUpButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FollowUpButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_rounded, size: 12, color: cs.primary),
            const SizedBox(width: 5),
            Text(
              'Follow Up',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// Mark Paid pill button — shown only on overdue-invoice alert cards.
// Uses a green accent (distinct from the primary-colored Follow Up
// button) since this is a positive, resolving action.
class _MarkPaidButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MarkPaidButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: green.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 12, color: green),
            const SizedBox(width: 5),
            Text(
              'Mark Paid',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: green),
            ),
          ],
        ),
      ),
    );
  }
}

// Small neutral pill button used for the Snooze actions.
class _SnoozeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SnoozeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.snooze_rounded, size: 12, color: cs.onSurface.withValues(alpha: 0.55)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: cs.onSurface.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}