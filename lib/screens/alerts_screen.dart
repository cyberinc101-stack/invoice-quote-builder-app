// alerts_screen.dart
// lib/screens/alerts_screen.dart
//
// PER-TYPE GATING (earlier pass): buildAlerts() here receives the same
// four AlertPrefs flags home_screen.dart's bell badge reads, so a type
// turned off in Settings disappears from both places consistently. Filter
// chips for a turned-off type render as "<Label> · Off" and the empty
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
// RECURRENCE-AWARE DISMISS (this pass): swiping a recurring reminder now
// advances it to its next occurrence (via advanceRecurringReminder)
// instead of deleting the series — matching the same behavior on the
// Reminders screen. Only a non-recurring reminder actually goes away, with
// Undo.
//
// SNOOZE (this pass): due reminder alert cards show two quick Snooze
// buttons ("1h" / "Tomorrow") that push the reminder's time back without
// touching it otherwise — handy for "not now, but don't lose this."

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import '../alerts/alert_types.dart';
import '../alerts/alert_engine.dart';
import '../alerts/alert_prefs.dart';
import '../alerts/custom_reminders/reminder_provider.dart';
import '../alerts/custom_reminders/reminder_model.dart';
import '../alerts/custom_reminders/reminder_screen.dart';
import 'saved_invoice_details_section/saved_document_detail_screen.dart';
import 'settings_screen.dart';

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

Color _alertFilterColor(AlertFilter f, ColorScheme cs) {
  switch (f) {
    case AlertFilter.all: return cs.primary;
    case AlertFilter.overdue: return const Color(0xFFD32F2F);
    case AlertFilter.expiring: return const Color(0xFFD32F2F);
    case AlertFilter.drafts: return const Color(0xFFF57C00);
    case AlertFilter.reminders: return const Color(0xFFD32F2F);
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

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertFilter _selectedFilter = AlertFilter.all;

  @override
  Widget build(BuildContext context) {
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
          appBar: AppBar(
            title: const Text('Alerts'),
            actions: [
              IconButton(
                icon: const Icon(Icons.alarm_add_rounded),
                tooltip: 'Manage Reminders',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RemindersScreen()),
                ),
              ),
            ],
          ),
          body: !alertsEnabled
              ? const _DisabledState()
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    _FilterChipRow(
                      selected: _selectedFilter,
                      totalCount: alerts.length,
                      overdueCount: overdueCount,
                      expiringCount: expiringCount,
                      draftsCount: draftsCount,
                      remindersCount: remindersCount,
                      disabledFilters: disabledFilters,
                      onChanged: (f) => setState(() => _selectedFilter = f),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyState(
                              filter: _selectedFilter,
                              hasAnyAlerts: alerts.isNotEmpty,
                              isTypeDisabled: disabledFilters.contains(_selectedFilter),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (_selectedFilter == AlertFilter.all) ...[
                                  if (highPriority.isNotEmpty) ...[
                                    const _GroupHeader(label: 'Needs Action', color: Color(0xFFD32F2F)),
                                    const SizedBox(height: 8),
                                    ...highPriority.map((a) => _AlertCardWrapper(alert: a)),
                                    const SizedBox(height: 20),
                                  ],
                                  if (mediumPriority.isNotEmpty) ...[
                                    const _GroupHeader(label: 'Drafts To Finish', color: Color(0xFFF57C00)),
                                    const SizedBox(height: 8),
                                    ...mediumPriority.map((a) => _AlertCardWrapper(alert: a)),
                                  ],
                                ] else
                                  ...filtered.map((a) => _AlertCardWrapper(alert: a)),
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

// ── Filter chip row ─────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  final AlertFilter selected;
  final int totalCount;
  final int overdueCount;
  final int expiringCount;
  final int draftsCount;
  final int remindersCount;
  final Set<AlertFilter> disabledFilters;
  final ValueChanged<AlertFilter> onChanged;

  const _FilterChipRow({
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
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final f in AlertFilter.values) ...[
            _AlertFilterChip(
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

class _AlertFilterChip extends StatelessWidget {
  final AlertFilter filter;
  final int count;
  final bool selected;
  final bool typeDisabled;
  final VoidCallback onTap;

  const _AlertFilterChip({
    required this.filter,
    required this.count,
    required this.selected,
    required this.typeDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = _alertFilterColor(filter, cs);
    final isEmptyAndUnselected = count == 0 && !selected && filter != AlertFilter.all && !typeDisabled;

    final label = typeDisabled
        ? '${_alertFilterLabel(filter)} · Off'
        : '${_alertFilterLabel(filter)} · $count';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: typeDisabled
              ? cs.onSurface.withOpacity(0.03)
              : (selected ? color : cs.onSurface.withOpacity(0.045)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: typeDisabled
                ? cs.outline.withOpacity(0.12)
                : (selected ? color : cs.outline.withOpacity(0.18)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              typeDisabled ? Icons.notifications_off_outlined : _alertFilterIcon(filter),
              size: 13,
              color: typeDisabled
                  ? cs.onSurface.withOpacity(0.25)
                  : (selected
                      ? Colors.white
                      : (isEmptyAndUnselected ? cs.onSurface.withOpacity(0.3) : color)),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: typeDisabled
                    ? cs.onSurface.withOpacity(0.25)
                    : (selected
                        ? Colors.white
                        : (isEmptyAndUnselected ? cs.onSurface.withOpacity(0.35) : cs.onSurface.withOpacity(0.68))),
              ),
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
            Icon(Icons.notifications_off_rounded, size: 48, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              'Alerts are turned off',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              "You won't see overdue, expiring, or draft nudges until you turn this back on.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.4)),
            ),
            const SizedBox(height: 16),
            FilledButton(
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isTypeDisabled
                  ? Icons.notifications_off_outlined
                  : (filter == AlertFilter.all ? Icons.notifications_off_outlined : _alertFilterIcon(filter)),
              size: 48,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              copy.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              copy.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.4)),
            ),
            if (isTypeDisabled) ...[
              const SizedBox(height: 16),
              FilledButton(
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

class _GroupHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _GroupHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ],
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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFD32F2F).withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          isRecurring ? Icons.repeat_rounded : Icons.delete_outline_rounded,
          color: const Color(0xFFD32F2F),
        ),
      ),
      onDismissed: (_) {
        final provider = context.read<ReminderProvider>();
        if (isRecurring) {
          // Recurring reminders never fully disappear from a swipe — the
          // series continues at its next occurrence.
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
        return const Color(0xFFD32F2F);
      case AlertPriority.medium:
        return const Color(0xFFF57C00);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReminder = alert.type == AlertType.customReminder && alert.reminder != null;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2235) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alert.subtitle,
                    style: TextStyle(fontSize: 12, color: _color, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                        Icon(Icons.swipe_left_alt_rounded, size: 11, color: cs.onSurface.withOpacity(0.3)),
                        const SizedBox(width: 3),
                        Text(
                          alert.reminder!.isRecurring ? 'Swipe to advance' : 'Swipe to dismiss',
                          style: TextStyle(fontSize: 10, color: cs.onSurface.withOpacity(0.3)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (!isReminder) Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// Small pill button used for the Snooze actions on due reminder alert
// cards. Plain GestureDetector (not InkWell) so it doesn't need a Material
// ancestor, matching the rest of this file's tap-target style.
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.snooze_rounded, size: 13, color: cs.onSurface.withOpacity(0.6)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
