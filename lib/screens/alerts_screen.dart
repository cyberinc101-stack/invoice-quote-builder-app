// alerts_screen.dart
// lib/screens/alerts_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import '../alerts/alert_types.dart';
import '../alerts/alert_engine.dart';
import '../alerts/alert_prefs.dart';
import '../alerts/custom_reminders/reminder_provider.dart';
import '../alerts/custom_reminders/reminder_screen.dart';
import 'saved_invoice_details_section/saved_document_detail_screen.dart';
import 'settings_screen.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertsEnabled = context.watch<AlertPrefs>().alertsEnabled;
    final dueReminders = context.watch<ReminderProvider>().dueReminders;

    return Consumer3<InvoiceProvider, QuoteProvider, ReceiptProvider>(
      builder: (context, invoiceProvider, quoteProvider, receiptProvider, _) {
        final alerts = alertsEnabled
            ? buildAlerts(
                invoices: invoiceProvider.savedInvoices,
                quotes: quoteProvider.savedQuotes,
                receipts: receiptProvider.savedReceipts,
                dueReminders: dueReminders,
              )
            : <AlertItem>[];

        final highPriority =
            alerts.where((a) => a.priority == AlertPriority.high).toList();
        final mediumPriority =
            alerts.where((a) => a.priority == AlertPriority.medium).toList();

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
              : alerts.isEmpty
                  ? const _EmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (highPriority.isNotEmpty) ...[
                          const _GroupHeader(label: 'Needs Action', color: Color(0xFFD32F2F)),
                          const SizedBox(height: 8),
                          ...highPriority.map((a) => _AlertCard(alert: a)),
                          const SizedBox(height: 20),
                        ],
                        if (mediumPriority.isNotEmpty) ...[
                          const _GroupHeader(label: 'Drafts To Finish', color: Color(0xFFF57C00)),
                          const SizedBox(height: 8),
                          ...mediumPriority.map((a) => _AlertCard(alert: a)),
                        ],
                      ],
                    ),
        );
      },
    );
  }
}

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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, size: 48, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(
              "You're all caught up",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 4),
            Text(
              'No overdue invoices, expiring quotes, due reminders, or unfinished drafts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.4)),
            ),
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
      screen = const RemindersScreen();
    }
    if (screen == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cs.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
