// home_screen.dart
// lib/screens/home_screen.dart
//
// SHARE-ONLY HERO (this update): removed the _MiniDocCluster illustration
// entirely (the tilted red QUOTE / white INVOICE / green RECEIPT card fan,
// plus its supporting _FanCard, _ReceiptFanCard, _CheckPainter, and
// _TornEdgeClipper classes -- none of them were used anywhere else in the
// file). In its place is a plain circular share icon button
// (_ShareIconButton), so the hero banner keeps the one-tap "share this app"
// affordance without the card-fan artwork. Because there's no illustration
// to dodge anymore, the hero text column (badge, headline, subtitle) is now
// centered (CrossAxisAlignment.center + TextAlign.center) instead of
// left-aligned with a reserved right-side gutter, and the
// screenWidth/showIllustration gating that used to hide the illustration on
// narrow screens is gone since the button is small enough to always show.
// Also updated the subtitle copy -- it used to read "Send professional
// invoices & quotes instantly" even though the banner has a Create Receipt
// button too; it now reads "...invoices, quotes & receipts instantly".
//
// HISTORY BUTTON PASS (earlier pass): the "Templates" CTA button (bottom
// row of the hero banner) is now "History" and opens HistoryScreen
// (history_screen.dart) instead of DocumentTemplatesScreen —
// HistoryScreen already existed in the codebase but had no button
// anywhere pointing to it. document_templates_screen.dart's own import
// is removed since nothing here references it anymore; the file itself
// is left on disk (delete manually if you're sure nothing else links to
// it — this pass only touches this button).
//
// SLIMMED (earlier pass): _SavedDocumentsSection and every List/Grid/
// Compact/Kanban card renderer that used to live in this file were
// extracted to lib/widgets/saved_documents/saved_documents_section.dart
// (exported as the public SavedDocumentsSection widget). This file now
// only holds the AppBar, hero banner, and the small widgets specific to
// those two things (_AlertBellButton, _CtaButton, _ShareIconButton).
//
// PER-TYPE ALERT GATING (earlier pass): the bell badge count now passes all
// four AlertPrefs per-type flags into buildAlerts(), not just the master
// alertsEnabled switch, so the badge, the Alerts screen, and any other
// future consumer of buildAlerts() all read from the exact same four
// flags on AlertPrefs and can never disagree.
//
// ICON ALIGNMENT FIX (earlier pass): the Templates icon sat lower than the
// other three CTA icons because the shared IntrinsicHeight row gave every
// button the same total height, but MainAxisAlignment.center made each
// icon's position depend on that button's own (label-line-count-dependent)
// content height. Fixed by switching to MainAxisAlignment.start so every
// icon anchors to the same offset from the top regardless of label length.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import '../alerts/alert_engine.dart';
import '../alerts/alert_prefs.dart';
import '../alerts/custom_reminders/reminder_provider.dart';
import '../widgets/create_receipt_button.dart';
import '../widgets/saved_documents/saved_documents_section.dart';
import 'alerts_screen.dart';
import 'history_screen.dart';
import 'invoice_template_chooser_screen.dart';
import 'quote_template_chooser_screen.dart';
import 'settings_screen.dart';
import 'expense_screen.dart';
import 'reports/reports_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final alertPrefs = context.watch<AlertPrefs>();
    final alertsEnabled = alertPrefs.alertsEnabled;
    final invoices = context.watch<InvoiceProvider>().savedInvoices;
    final quotes    = context.watch<QuoteProvider>().savedQuotes;
    final receipts  = context.watch<ReceiptProvider>().savedReceipts;
    final dueReminders = context.watch<ReminderProvider>().dueReminders;
    final alertCount = alertsEnabled
        ? buildAlerts(
            invoices: invoices,
            quotes: quotes,
            receipts: receipts,
            dueReminders: dueReminders,
            overdueInvoicesEnabled: alertPrefs.overdueInvoicesEnabled,
            quotesExpiringEnabled: alertPrefs.quotesExpiringEnabled,
            draftsEnabled: alertPrefs.draftsEnabled,
            remindersEnabled: alertPrefs.remindersEnabled,
          ).length
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice & Quote Builder'),
        actions: [
          _AlertBellButton(
            count: alertCount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AlertsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_outlined),
            tooltip: 'Expenses',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Reports',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildHeroBanner(context),
            const SizedBox(height: 28),
            const SavedDocumentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Text(
                    'Professional documents in minutes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create Your\nInvoice or Quote',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: 0.3,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Send professional invoices, quotes & receipts instantly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 18),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _CtaButton(
                          label: 'Create Invoice',
                          icon: Icons.receipt_long_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                          ),
                          glowColor: const Color(0x602196F3),
                          onTap: () {
                            context.read<InvoiceProvider>().resetInvoiceData();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InvoiceTemplateChooserScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CtaButton(
                          label: 'Create Quote',
                          icon: Icons.request_quote_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
                          ),
                          glowColor: const Color(0x607B1FA2),
                          onTap: () {
                            context.read<QuoteProvider>().resetQuoteData();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QuoteTemplateChooserScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: CreateReceiptButton(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CtaButton(
                          label: 'History',
                          icon: Icons.history_rounded,
                          singleLine: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF78909C), Color(0xFF546E7A)],
                          ),
                          glowColor: const Color(0x6078909C),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Standalone share affordance -- replaces the old _MiniDocCluster
            // illustration. No card artwork anymore, just the tappable icon.
            Positioned(
              right: 4,
              top: 4,
              child: _ShareIconButton(
                onShare: () => Share.share(
                  'Check out Invoice, Quote & Receipt Maker Pro — create '
                  'professional invoices, quotes and receipts in minutes!',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _AlertBellButton — bell icon + badge, lives in the AppBar
// -----------------------------------------------------------------------------

class _AlertBellButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AlertBellButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Alerts',
          onPressed: onTap,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// _CtaButton
// -----------------------------------------------------------------------------

class _CtaButton extends StatelessWidget {
  final String         label;
  final IconData       icon;
  final LinearGradient gradient;
  final Color          glowColor;
  final VoidCallback   onTap;
  final bool           singleLine;
  final double         iconSize;

  const _CtaButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
    this.singleLine = false,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient:     gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: glowColor, blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            const SizedBox(height: 6),
            if (singleLine)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  softWrap: false,
                ),
              )
            else
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// _ShareIconButton — the hero banner's tap-to-share affordance. Previously
// this lived on the corner of the _MiniDocCluster illustration (the QUOTE/
// INVOICE/RECEIPT card fan); now that the illustration is gone, it's just a
// small semi-transparent circular icon button sitting in the banner's
// top-right corner.
// -----------------------------------------------------------------------------

class _ShareIconButton extends StatelessWidget {
  final VoidCallback onShare;
  const _ShareIconButton({required this.onShare});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onShare,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
        ),
        child: const Icon(Icons.share_rounded, color: Colors.white, size: 16),
      ),
    );
  }
}