// step_customise.dart
// lib/screens/invoice_create_section/step_customize/step_customise.dart
//
// SECTION-ORDER PASS (this update): moved the Business Logo card
// (LogoSection) above the Invoice Fields card (FieldsSection) in the
// scroll layout below, so logo setup happens before field toggles.
// Purely a reorder — no changes to either widget or its state.
//
// DRAFT-SYNC PASS (earlier): _handleSave() now writes Footer
// Taglines / business tagline / business logo — all Customise-only
// fields that CreateInvoiceBottomSheet never touches — back onto the
// draft that originated this session, right after the invoice itself
// saves successfully. Without this, those fields only ever lived on the
// finished SavedInvoice; the separate draft library (edited in
// step_create_invoice.dart) never learned about the change, so
// re-selecting the same draft later would silently revert them. See
// step_create_invoice.dart's syncCustomiseFieldsToDraft() and its own
// header comment for the full rationale. This is a no-op whenever the
// current session didn't come from a draft (provider.sourceDraftId ==
// null) — e.g. editing an already-finished saved invoice via "Edit" on
// its detail screen, which is unaffected by any of this.
//
// FILE-SPLIT PASS (earlier): this file used to hold every section on
// the Customise screen in one ~1400-line file. It's now a slim shell —
// state, save/preview actions, scroll handling, and top-level layout only
// — that assembles the sections below, each in its own file:
//
//   customise_shared_widgets.dart   — SectionCard, plainSectionHeader, colorForScheme
//   customise_preview.dart          — InvoicePreviewCard (live inline preview)
//   customise_logo_section.dart     — LogoSection (business logo + drag/pinch position)
//   customise_background_section.dart — BackgroundImageSection (x3) + its dialog
//   customise_style_section.dart    — ColourSection + FontSection
//   customise_fields_section.dart   — FieldsSection + field group specs
//
// Small widgets specific only to this shell (title field, preview/download
// button, summary card, done card, bottom bar) stay here since nothing
// else needs them.
//
// See customise_logo_section.dart and doc_header.dart for the freeform
// header-logo fixes bundled with this split: a single size control
// (duplicate slider removed), size decoupled from the header's own
// height, and the drag-to-left-edge diagnostic note.
//
// HEADER/FOOTER BACKGROUND DISABLED PASS (earlier): the Header
// Background and Footer Background cards are commented out below —
// not removed. The underlying model fields, background_spec.dart /
// background_render.dart plumbing, and doc_header.dart / doc_footer.dart
// render call sites are untouched, so re-enabling later is just
// uncommenting these two blocks. Mid-Page Background is unaffected and
// stays active.
//
// DRAG-VS-TAP CONFLICT FIX (earlier): the live preview used to be
// wrapped in GestureDetector(onTap: _openFullPreview) — putting a tap
// recognizer directly ahead of the header logo's own drag/pinch
// GestureDetector (doc_header.dart's _DraggableHeaderLogo) in the
// gesture-hit-test order. A shorter, slower, or more careful drag
// attempt (exactly what precisely nudging a logo into place looks like)
// could get resolved as a tap instead of a drag, firing _openFullPreview
// and jumping to the full-preview screen mid-attempt instead of moving
// the logo. Fixed by dropping that wrapper and passing _openFullPreview
// into InvoicePreviewCard's new onOpenFullPreview param instead — see
// customise_preview.dart, which now scopes the tap trigger to just the
// small caption under the document, a region that never overlaps the
// logo's own gesture detector.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/invoice_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/invoice_data.dart';
import '../../../models/history_event.dart' show HistoryDocType;
import '../invoice_edit_widgets.dart' show InvoiceTotalsCard;
import '../step_create_invoice/create_invoice_form_widgets.dart' show CreateInvoiceField;
import '../../saved_invoice_details_section/saved_document_detail_screen.dart';
import 'invoice_full_preview_screen.dart';
import '../../../document_layout_templates/01_executive/executive_template.dart'
    show invoiceAccent;
import '../step_create_invoice/step_create_invoice.dart'
    show syncCustomiseFieldsToDraft;

import 'customise_shared_widgets.dart';
import 'customise_preview.dart';
import 'customise_logo_section.dart';
import 'customise_background_section.dart';
import 'customise_style_section.dart';
import 'customise_fields_section.dart';

// =============================================================================
// Public entry point
// =============================================================================

class StepCustomise extends StatefulWidget {
  final VoidCallback onBack;
  const StepCustomise({super.key, required this.onBack});

  @override
  State<StepCustomise> createState() => _StepCustomiseState();
}

class _StepCustomiseState extends State<StepCustomise> {
  final ScrollController _scrollController = ScrollController();

  late final TextEditingController _titleCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = context.read<InvoiceProvider>().invoiceData;
    final suggested = data.clientName.isNotEmpty
        ? '${data.clientName} — ${data.invoiceNumber.isNotEmpty ? data.invoiceNumber : 'Invoice'}'
        : data.invoiceNumber;
    _titleCtrl = TextEditingController(text: suggested);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _scrollToTop() => _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

  void _openFullPreview() {
    final provider = context.read<InvoiceProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const InvoiceFullPreviewScreen(),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this invoice a title before saving')),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<InvoiceProvider>();
    final history = context.read<HistoryProvider>();
    try {
      final saved = provider.saveCurrentInvoice(
        title: _titleCtrl.text.trim(),
        templateName: 'Executive',
      );
      // DRAFT-SYNC PASS: write Customise-only fields (Footer Taglines,
      // business tagline, business logo) back onto the draft that
      // originated this session, if any — see this file's header
      // comment and step_create_invoice.dart's syncCustomiseFieldsToDraft()
      // for the full rationale. Fire-and-forget: this is a best-effort
      // convenience sync onto a separate library and must never block
      // or fail the actual invoice save above, which has already
      // succeeded by this point.
      final sourceDraftId = provider.sourceDraftId;
      if (sourceDraftId != null) {
        unawaited(syncCustomiseFieldsToDraft(sourceDraftId, saved.data));
      }
      final d = saved.data;
      unawaited(history.logCreated(
        docType: HistoryDocType.invoice,
        docId: saved.id,
        docNumber: d.invoiceNumber,
        clientName: d.clientName.isEmpty ? null : d.clientName,
        amount: d.grandTotal,
        currency: d.currency,
      ));
      provider.resetInvoiceData();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SavedDocumentDetailScreen.invoice(saved)),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't save invoice: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customise',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Personalise your invoice design',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),

                const SizedBox(height: 20),

                _TitleSection(titleCtrl: _titleCtrl),
                const SizedBox(height: 24),

                // DRAG-VS-TAP CONFLICT FIX: no longer wraps the whole
                // card in a tap handler — see this file's header
                // comment. The full-preview trigger is now scoped
                // entirely inside InvoicePreviewCard, on just its
                // bottom caption.
                InvoicePreviewCard(onOpenFullPreview: _openFullPreview),
                const SizedBox(height: 24),

                // SECTION-ORDER PASS: LogoSection now sits above
                // FieldsSection so business logo setup happens before
                // the field-visibility toggles.
                //
                // COLLAPSIBLE SECTIONS + MERGE PASS: Logo Size lives
                // inside LogoSection now (see customise_logo_section.dart)
                // — no separate standalone size card underneath it.
                //
                // DRAG-ON-HEADER PASS: the "Position in Header" control
                // no longer opens a separate dialog — see
                // customise_logo_section.dart's own comment for what
                // replaced it, and the SINGLE-SIZER FIX there for the
                // duplicate-slider fix bundled with this split.
                const LogoSection(),
                const SizedBox(height: 16),

                const FieldsSection(),
                const SizedBox(height: 16),

                // BACKGROUND-IMAGE PASS: header/footer background image
                // upload + on/off switch, one card each. Sit right after
                // the logo controls since they're the other
                // "upload an image for the document" section.
                //
                // HEADER/FOOTER BACKGROUND DISABLED PASS: commented out
                // for now — may come back later. Uncomment to re-enable.
                // const BackgroundImageSection(
                //   title: 'Header Background',
                //   icon: Icons.wallpaper_rounded,
                //   target: BackgroundImageTarget.header,
                // ),
                // const SizedBox(height: 16),

                const BackgroundImageSection(
                  title: 'Mid-Page Background',
                  icon: Icons.wallpaper_rounded,
                  target: BackgroundImageTarget.body,
                ),
                const SizedBox(height: 16),

                // HEADER/FOOTER BACKGROUND DISABLED PASS: commented out
                // for now — may come back later. Uncomment to re-enable.
                // const BackgroundImageSection(
                //   title: 'Footer Background',
                //   icon: Icons.wallpaper_rounded,
                //   target: BackgroundImageTarget.footer,
                // ),
                // const SizedBox(height: 16),

                const ColourSection(),
                const SizedBox(height: 16),

                // COLLAPSIBLE SECTIONS + MERGE PASS: Text Size lives
                // inside FontSection now (see customise_style_section.dart)
                // — no separate standalone size card underneath it.
                const FontSection(),
                const SizedBox(height: 24),

                const _SummarySection(),
                const SizedBox(height: 20),

                _PreviewButton(onTap: _openFullPreview),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _scrollToTop,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0D1B2A)
                          : const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard_arrow_up_rounded,
                            color: Color(0xFF2196F3), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Back to Top',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const _DoneCard(),
              ],
            ),
          ),
        ),

        _BottomBar(onBack: widget.onBack, onSave: _handleSave, isSaving: _saving),
      ],
    );
  }
}

// =============================================================================
// Preview & Download button
// =============================================================================

class _PreviewButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PreviewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final accent = invoiceAccent(provider.invoiceData);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withValues(alpha: 0.80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.preview_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Preview & Download',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Title section
// =============================================================================

class _TitleSection extends StatelessWidget {
  final TextEditingController titleCtrl;
  const _TitleSection({required this.titleCtrl});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final accent = colorForScheme(provider.invoiceData.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        plainSectionHeader(context, 'Invoice Title', accent, icon: Icons.title_rounded),
        CreateInvoiceField(
          ctrl: titleCtrl,
          label: 'Title (for your records)',
          hint: 'e.g. Acme Corp — Invoice',
          icon: Icons.bookmark_outline_rounded,
          max: 80,
          accent: accent,
        ),
      ],
    );
  }
}

// =============================================================================
// Summary section
// =============================================================================

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  String _currencyPrefix(InvoiceData data) {
    final symbol = data.currencySymbol.trim();
    final code = data.currency.trim().toUpperCase();
    if (symbol.isNotEmpty) return symbol;
    if (code.isNotEmpty) return '$code ';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final data     = provider.invoiceData;
    final accent   = colorForScheme(data.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        plainSectionHeader(context, 'Summary', accent, icon: Icons.summarize_rounded),
        InvoiceTotalsCard(
          subtotal: data.subtotal,
          taxAmount: data.taxAmount,
          discountAmount: data.discountAmount,
          total: data.grandTotal,
          taxRate: data.taxRate,
          discountRate: data.discountRate,
          currencySymbol: _currencyPrefix(data),
          accent: accent,
        ),
      ],
    );
  }
}

// =============================================================================
// Done card
// =============================================================================

class _DoneCard extends StatelessWidget {
  const _DoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 32),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your invoice is ready!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Give it a title above, then tap Save Invoice below.',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Bottom bar
// =============================================================================

class _BottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSave;
  final bool isSaving;
  const _BottomBar({required this.onBack, required this.onSave, required this.isSaving});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, -3)),
        ],
      ),
      child: Row(
        children: [
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
              child: Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.55), size: 22),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: GestureDetector(
              onTap: isSaving ? null : onSave,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x504CAF50),
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ],
                ),
                child: isSaving
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Save Invoice',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}