// alert_type_toggles.dart
// lib/alerts/alert_type_toggles.dart
//
// PUSH WIRING (this pass): each switch's onChanged now does two things
// instead of one — (1) persists the flag via AlertPrefs, same as before,
// and (2) applies the resulting EFFECTIVE state (alertPrefs.alertsEnabled
// && the new per-type value) to that category's real push notifications,
// via the matching provider's applyXEnabled() method. Previously these
// switches only changed what buildAlerts() shows in-app — the actual OS
// push notifications for a "disabled" category kept firing regardless.
// "Drafts" fans out to all three document providers since one toggle
// covers invoices/quotes/receipts drafts at once, matching its subtitle
// text below. See document_alert_scheduler.dart's header comment for the
// full rationale.
//
// Reusable list of the four per-type alert switches (Overdue Invoices /
// Expiring Quotes / Drafts / Reminders), reading and writing straight from
// AlertPrefs. Drop this into Settings (nested under the master switch) or
// anywhere else a quick-toggle UI is useful — no duplicated state, since
// every consumer shares the same AlertPrefs instance via provider.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'alert_prefs.dart';
import 'custom_reminders/reminder_provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';

class AlertTypeTogglesList extends StatelessWidget {
  final bool showHeader;
  final bool dense;

  const AlertTypeTogglesList({
    super.key,
    this.showHeader = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AlertPrefs>();
    final cs = Theme.of(context).colorScheme;

    final items = <_ToggleItem>[
      _ToggleItem(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFD32F2F),
        title: 'Overdue Invoices',
        subtitle: 'Nudge me when an invoice is past its due date',
        value: prefs.overdueInvoicesEnabled,
        onChanged: (value) {
          prefs.setOverdueInvoicesEnabled(value);
          context
              .read<InvoiceProvider>()
              .applyOverdueAlertsEnabled(prefs.alertsEnabled && value);
        },
      ),
      _ToggleItem(
        icon: Icons.hourglass_bottom_rounded,
        color: const Color(0xFFD32F2F),
        title: 'Expiring Quotes',
        subtitle: 'Nudge me when a quote is about to expire',
        value: prefs.quotesExpiringEnabled,
        onChanged: (value) {
          prefs.setQuotesExpiringEnabled(value);
          context
              .read<QuoteProvider>()
              .applyExpiringAlertsEnabled(prefs.alertsEnabled && value);
        },
      ),
      _ToggleItem(
        icon: Icons.edit_note_rounded,
        color: const Color(0xFFF57C00),
        title: 'Drafts',
        subtitle: 'Nudge me about unfinished invoices, quotes & receipts',
        value: prefs.draftsEnabled,
        onChanged: (value) {
          prefs.setDraftsEnabled(value);
          final effective = prefs.alertsEnabled && value;
          context.read<InvoiceProvider>().applyDraftAlertsEnabled(effective);
          context.read<QuoteProvider>().applyDraftAlertsEnabled(effective);
          context.read<ReceiptProvider>().applyDraftAlertsEnabled(effective);
        },
      ),
      _ToggleItem(
        icon: Icons.notifications_active_rounded,
        color: const Color(0xFFD32F2F),
        title: 'Reminders',
        subtitle: 'Show my custom reminders once they come due',
        value: prefs.remindersEnabled,
        onChanged: (value) {
          prefs.setRemindersEnabled(value);
          context
              .read<ReminderProvider>()
              .applyRemindersPushEnabled(prefs.alertsEnabled && value);
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'ALERT TYPES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: cs.primary,
              ),
            ),
          ),
        for (final item in items)
          Padding(
            padding: EdgeInsets.symmetric(vertical: dense ? 2 : 6),
            child: Row(
              children: [
                Container(
                  width: dense ? 30 : 36,
                  height: dense ? 30 : 36,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: dense ? 15 : 18, color: item.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: dense ? 13 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!dense)
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: item.value,
                  onChanged: item.onChanged,
                  activeColor: const Color(0xFF2196F3),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ToggleItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  _ToggleItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
