// home_screen.dart
// lib/screens/home_screen.dart
//
// HERO CLUSTER FIT + RECEIPT TEXTURE FIX (this pass): two problems with
// the new _MiniDocCluster illustration. (1) The RECEIPT label on the
// green card used overflow: TextOverflow.visible with no clipping
// container around it, so on narrower screens the tail of the word spilled
// out past the card AND past the hero banner's own right edge, where it
// got abruptly hard-cut by the screen bound instead of the card's own
// shape -- visually reading as a rendering bug ("EIPT"). (2) The green
// card was just a plain rounded rectangle in the app's accent green with
// no actual receipt-like texture, unlike the torn-thermal-roll shape used
// in the app icon artwork (app_icon_store_listing.png). Both fixed here:
//   - _FanCard (red QUOTE card) now wraps its content in ClipRRect, so
//     text is clipped to the card's own rounded shape rather than able to
//     spill past it.
//   - The green card is now built by a dedicated _ReceiptFanCard, clipped
//     with a custom zigzag ClipPath (_TornEdgeClipper) that gives it the
//     same jagged top/bottom "torn thermal roll" silhouette as the icon
//     artwork, instead of a plain rectangle -- and its own text is
//     likewise contained within that clipped shape.
//   - The whole cluster is also ~15% smaller and repositioned closer to
//     the banner's own top-right corner (was hanging off the edge at
//     right:-6) so it sits fully inside the container at every supported
//     screen width, instead of relying on the fan angle/label length
//     never being wide enough to reach the edge.
//
// HERO ILLUSTRATION REDESIGN + SHARE BUTTON (earlier pass): the hero
// banner's top-right illustration was three plain colored rectangles
// (_MiniDocIcon, blue/purple/blue) with no connection to the app's actual
// brand identity -- and the app icon/store listing artwork was separately
// redesigned into a red QUOTE card + white INVOICE card + green RECEIPT
// card fan. That pass replaced _MiniDocIcon's stack with _MiniDocCluster,
// a compact recreation of that exact three-card composition (same
// red/white/green palette, same QUOTE/INVOICE/RECEIPT labels, same
// %/$/check badges, same PAID pill on the invoice card) at hero-banner
// scale, so the app's icon and its own home screen actually look like the
// same product. The cluster is wrapped in a GestureDetector that calls
// Share.share() with a short promo blurb, with a small semi-transparent
// share-icon badge on its bottom-left corner as the tap affordance.
// share_plus was already a project dependency (used by invoice/quote/
// receipt PDF services for their own share sheets), so no new package
// was needed.
//
// SLIMMED (earlier pass): _SavedDocumentsSection and every List/Grid/
// Compact/Kanban card renderer that used to live in this file were
// extracted to lib/widgets/saved_documents/saved_documents_section.dart
// (exported as the public SavedDocumentsSection widget). This file now
// only holds the AppBar, hero banner, and the small widgets specific to
// those two things (_AlertBellButton, _CtaButton, _MiniDocCluster).
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
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                // Right padding matches _MiniDocCluster's new (shrunk)
                // footprint (94 wide + a little clearance) so headline
                // text still wraps clear of the illustration.
                Padding(
                  padding: EdgeInsets.only(right: showIllustration ? 96 : 0),
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
                  padding: EdgeInsets.only(right: showIllustration ? 96 : 0),
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
            // Illustration -> the app's QUOTE/INVOICE/RECEIPT card-fan
            // artwork (matching the app icon), tappable as a share button.
            // Positioned inset from the corner (was right:-6/top:-4,
            // hanging off the edge) so the smaller cluster sits fully
            // inside the banner at every supported width.
            if (showIllustration)
              Positioned(
                right: 2,
                top: 2,
                child: _MiniDocCluster(
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
// _MiniDocCluster — hero-banner-scale recreation of the app icon's own
// QUOTE (red) / INVOICE (white) / RECEIPT (green) card fan, doubling as a
// share button. Shrunk ~15% and inset from the corner (vs. the previous
// pass) so it can never hang off the banner's edge, and both side cards
// now clip their own content to their own shape so an overflowing label
// gets cut by the card, not by the screen.
// -----------------------------------------------------------------------------

class _MiniDocCluster extends StatelessWidget {
  final VoidCallback onShare;
  const _MiniDocCluster({required this.onShare});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onShare,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 98,
        height: 112,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // RED — QUOTE, tilted left
            Positioned(
              left: 0,
              top: 20,
              child: Transform.rotate(
                angle: -0.30, // ~-17deg
                child: _FanCard(
                  width: 49,
                  height: 71,
                  gradientColors: const [Color(0xFFFF5A52), Color(0xFFC21E17)],
                  label: 'QUOTE',
                  badgeSymbol: '%',
                  badgeTextColor: const Color(0xFFC21E17),
                ),
              ),
            ),
            // GREEN — RECEIPT, tilted right, real torn-roll silhouette
            Positioned(
              right: 0,
              top: 20,
              child: Transform.rotate(
                angle: 0.30, // ~+17deg
                child: _ReceiptFanCard(
                  width: 49,
                  height: 71,
                  label: 'RECEIPT',
                ),
              ),
            ),
            // WHITE — INVOICE, upright, on top
            Positioned(
              left: 22,
              top: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 54,
                  height: 85,
                  padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFFFFF), Color(0xFFF3F1EC)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x47000000),
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INVOICE',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 7.8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8332B),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '\$',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8332B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'PAID',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 5.8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Small share-icon badge — the only visual hint that this
            // decorative-looking cluster is actually tappable.
            Positioned(
              left: -2,
              bottom: -2,
              child: Container(
                width: 21,
                height: 21,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1.1),
                ),
                child: const Icon(Icons.share_rounded, color: Colors.white, size: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shared card shape for the red QUOTE side card — a rounded rect with a
// corner badge + bold label. Content is wrapped in ClipRRect so the label
// is guaranteed to be clipped to the card's own rounded shape rather than
// able to spill past it into the rest of the Stack (which is what caused
// the RECEIPT label's tail to get hard-cut by the screen edge before).
class _FanCard extends StatelessWidget {
  final double width;
  final double height;
  final List<Color> gradientColors;
  final String label;
  final String badgeSymbol;
  final Color badgeTextColor;

  const _FanCard({
    required this.width,
    required this.height,
    required this.gradientColors,
    required this.label,
    required this.badgeSymbol,
    required this.badgeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 6.6,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
            const Spacer(),
            Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Text(
                badgeSymbol,
                style: TextStyle(
                  color: badgeTextColor,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Green RECEIPT card — same idea as _FanCard but clipped to a jagged
// zigzag top/bottom edge (_TornEdgeClipper) instead of a rounded rect, so
// it actually reads as a torn thermal-paper receipt rather than a plain
// colored rectangle. The checkmark is hand-drawn with two joined line
// segments (not a Unicode glyph) so it renders identically across every
// device font instead of depending on how a given font draws "check".
class _ReceiptFanCard extends StatelessWidget {
  final double width;
  final double height;
  final String label;

  const _ReceiptFanCard({required this.width, required this.height, required this.label});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _TornEdgeClipper(),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3ADB76), Color(0xFF189249)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 6.6,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
            const Spacer(),
            Container(
              width: 15,
              height: 15,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: CustomPaint(size: const Size(8, 8), painter: _CheckPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

// Draws a simple checkmark as two joined line segments -- used instead of
// a Unicode check glyph so it renders identically regardless of the
// device's default font (some fonts draw check glyphs inconsistently
// thin/heavy or off-center at very small sizes).
class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF189249)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * 0.05, size.height * 0.55)
      ..lineTo(size.width * 0.4, size.height * 0.9)
      ..lineTo(size.width * 0.95, size.height * 0.15);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Zigzag top/bottom clip -- gives the receipt card a torn-paper-roll
// silhouette matching the app icon artwork's own thermal-roll shape,
// instead of a plain rectangle. Six teeth per edge, amplitude scaled to
// the card's own height so it looks proportional at any size this card
// is used at.
class _TornEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const teeth = 6;
    final segment = size.width / teeth;
    final amp = size.height * 0.035;

    final path = Path()..moveTo(0, amp);
    for (int i = 0; i <= teeth; i++) {
      final x = i * segment;
      final y = (i.isEven) ? 0.0 : amp * 2;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height - amp * 2);
    for (int i = teeth; i >= 0; i--) {
      final x = i * segment;
      final y = size.height - ((i.isEven) ? 0.0 : amp * 2);
      path.lineTo(x, y);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}