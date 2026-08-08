// home_screen.dart
// lib/screens/home_screen.dart
//
// SLIMMED (earlier pass): _SavedDocumentsSection and every List/Grid/
// Compact/Kanban card renderer that used to live in this file were
// extracted to lib/widgets/saved_documents/saved_documents_section.dart
// (exported as the public SavedDocumentsSection widget). This file now
// only holds the AppBar, hero banner, and the small widgets specific to
// those two things (_AlertBellButton, _CtaButton, _MiniDocIcon).
//
// PER-TYPE ALERT GATING (this pass): the bell badge count now passes all
// four AlertPrefs per-type flags into buildAlerts(), not just the master
// alertsEnabled switch. Previously a user could turn off, say, "Drafts"
// alerts on the Alerts screen's future toggle UI and still see the bell
// badge count include draft nudges, since this call site only knew about
// the master switch. Now the badge, the Alerts screen, and any other
// future consumer of buildAlerts() all read from the exact same four
// flags on AlertPrefs, so they can never disagree.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoice_provider.dart';
import '../providers/quote_provider.dart';
import '../providers/receipt_provider.dart';
import '../alerts/alert_engine.dart';
import '../alerts/alert_prefs.dart';
import '../alerts/custom_reminders/reminder_provider.dart';
import '../widgets/create_receipt_button.dart';
import '../widgets/saved_documents/saved_documents_section.dart';
import 'alerts_screen.dart';
import 'document_templates_screen.dart';
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

    // Watched here (not just read) so the badge count on the bell updates
    // live as invoices/quotes/receipts are saved, paid, or edited — same
    // predicates as the quick-filter chips, via filter_logic.dart, so this
    // number can never disagree with what "Needs Action"/"Overdue" show.
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
    final screenWidth      = MediaQuery.of(context).size.width;
    final showIllustration = screenWidth >= 360;

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
        // Stack instead of Row. The illustration is a decorative Positioned
        // overlay in the top-right corner — it no longer takes a column
        // slot in the layout. The text + button Column below is the
        // Stack's base child and gets the FULL container width, so the
        // three CTA buttons (each Expanded) span edge-to-edge.
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Text(
                    'Professional documents in minutes',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.only(right: showIllustration ? 90 : 0),
                  child: const Text(
                    'Create Your\nInvoice or Quote',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: 0.3,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.only(right: showIllustration ? 90 : 0),
                  child: const Text(
                    'Send professional invoices & quotes instantly',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    softWrap: true,
                  ),
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
                          label: 'Templates',
                          icon: Icons.grid_view_rounded,
                          iconSize: 28,
                          singleLine: true,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF78909C), Color(0xFF546E7A)],
                          ),
                          glowColor: const Color(0x6078909C),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DocumentTemplatesScreen(),
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
            if (showIllustration)
              Positioned(
                right: 0,
                top: 0,
                child: SizedBox(
                  width: 80,
                  height: 100,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        right: 0,
                        top: 10,
                        child: _MiniDocIcon(
                          color: const Color(0xFF7B1FA2),
                          rotateAngle: 0.15,
                          isQuote: true,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 20,
                        child: _MiniDocIcon(
                          color: const Color(0xFF1565C0),
                          rotateAngle: -0.1,
                          isQuote: false,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        top: 0,
                        child: _MiniDocIcon(
                          color: const Color(0xFF2196F3),
                          rotateAngle: 0.0,
                          isQuote: false,
                        ),
                      ),
                    ],
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
          mainAxisAlignment: MainAxisAlignment.center,
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
// _MiniDocIcon
// -----------------------------------------------------------------------------

class _MiniDocIcon extends StatelessWidget {
  final Color  color;
  final double rotateAngle;
  final bool   isQuote;

  const _MiniDocIcon({
    required this.color,
    required this.rotateAngle,
    required this.isQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotateAngle,
      child: Container(
        width: 50,
        height: 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  isQuote ? '?' : '\$',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            ...List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                height: 3,
                width: i == 0 ? 32 : (i == 1 ? 24 : (i == 2 ? 28 : 18)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}