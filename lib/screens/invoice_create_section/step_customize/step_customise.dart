// lib/screens/invoice_create_section/step_customize/step_customise.dart
//
// MERGE PASS (this update): imports redirected off the three deleted
// executive_invoice_logic_data.dart / executive_invoice_stationary_
// layout.dart files. ExecutiveInvoicePreview and invoiceAccent now come
// from executive_template.dart (the merged, adapter-based file that
// replaces them — see that file's own MERGE PASS header comment), and
// kPageW now comes from shared_doc_widgets.dart. No other change in this
// file — same widget tree, same behavior, same call sites.
//
// FONT CHIP PREVIEW PASS (earlier): the "Font Family" chips
// (_FontSection) now render each chip's own label IN that font, the
// same way the Signature Font chips beneath the Signature toggle
// already do — so tapping through Roboto/Lato/Lora/etc. previews the
// actual look before committing, instead of every chip label rendering
// in whatever the app's own default UI font happens to be. All nine
// real fonts are locally bundled in pubspec.yaml (no GoogleFonts/
// network call involved), so a plain TextStyle(fontFamily: font)
// resolves correctly. 'Default' is a sentinel that deliberately matches
// no registered family — its chip previews with fontFamily: null (the
// platform default) rather than passing the literal string 'Default'
// as a font name.
//
// FONT FAMILY LIST FIX (earlier): _kFonts previously listed
// "Playfair Display" and "Source Sans Pro" — neither matched a font
// family actually registered in pubspec.yaml ("Playfair Display" was
// registered there as plain "Playfair"; "Source Sans Pro" wasn't
// bundled at all). Selecting either chip set InvoiceData.fontFamily to
// a string that resolves to nothing, so every TextStyle(fontFamily: ff)
// call site silently fell back to the platform default — this was the
// "font changer not working" bug. Fixed two ways: (1) pubspec.yaml's
// Playfair family entry is renamed to "Playfair Display" to match this
// list and the font's real name: (2) "Source Sans Pro" is replaced with
// the four fonts pubspec already bundles but this list never offered —
// Lora, Nunito, Raleway, Space Grotesk. _kFonts now exactly mirrors
// pubspec's registered family names, so every chip resolves to a real,
// loaded font.
//
// SIGNATURE FONT FAMILY PASS (earlier): the Signature row's inline
// "Size" slider (added by the earlier SIGNATURE SIZER PASS) now also
// grows a row of six font chips directly beneath it, visible only while
// the Signature toggle is on and only relevant when signature mode is
// 'typed' (the chips are harmless — just unused — for 'image'/'blank'
// modes, since InvoiceData.signatureFontFamily only affects the typed
// render path in executive_invoice_payment_terms_signature.dart /
// invoice_pdf_extra_sections.dart). Reads/writes
// InvoiceData.signatureFontFamily via the new
// InvoiceProvider.updateSignatureFontFamily(). Font list
// (_kSignatureFonts) is kept local to this file rather than imported
// from the stationary-layout file, so this file has no compile-time
// dependency on that file's internals — six real fonts, now bundled
// locally (see pubspec.yaml's SIGNATURE FONT FAMILY PASS entries):
// Dancing Script, Great Vibes, Sacramento, Pacifico, Alex Brush, Caveat.
//
// PREVIEW BUTTON PARITY PASS (earlier): added an inline "Preview &
// Download" call-to-action button, matching the one Receipt's
// ReceiptStepCustomise already has (receipt_step_customise.dart) —
// placed directly after the Summary section, before "Back to Top",
// same position Receipt uses. New private _PreviewButton widget watches
// InvoiceProvider itself to pick up the invoice's own accent color
// (invoiceAccent()) for its gradient, rather than Receipt's fixed green,
// and calls the existing _openFullPreview() callback already used by
// tapping the Live Preview card above — no new navigation logic, just a
// second, more visible way to reach the same screen.
//
// PAYMENT TERMS REMOVAL PASS (earlier): the "Payment Terms" toggle
// row has been removed from the Payment Info group in _kFieldGroups —
// matches the corresponding removal in client_info.dart
// (BusinessInfo.paymentTerms), invoice_data.dart (InvoiceData.paymentTerms
// + its enabledFields default), the template editor's "Payment Terms /
// Due Note" input field, and the two render sites
// (executive_invoice_payment_terms_signature.dart's buildPaymentInfoPanel,
// invoice_pdf_extra_sections.dart's buildPdfPaymentInfoPanel). Payment
// Info is now a 5-field group instead of 6.
//
// PERSISTED GROUP COLLAPSE PASS (earlier): each field group in
// _FieldsSection (Header & Meta, Billed To, Invoice Details, Payment
// Info, Terms & Signature, Notes & Thank You) now remembers its own
// expand/collapse state via SharedPreferences, keyed per group label —
// same pattern as step_templates.dart's _CollapsibleGroup. Every group
// starts COLLAPSED the very first time (no persisted value yet), and
// after that stays however the person last left it, whether that was
// via tapping the header row or flipping the group's master switch.
// Previously a group's initial expand state was seeded from whether
// its fields happened to already be all-on (_groupIsOn) — that
// heuristic is gone; _expanded now only ever reflects the persisted (or
// default-false) value plus whatever the person does in this session.
//
// SIGNATURE SIZER PASS (earlier): the Signature row in the Terms &
// Signature group grows an inline "Size" slider directly beneath its
// switch, visible only while the switch is on. Reads/writes
// InvoiceData.signatureFontSize via InvoiceProvider.updateSignatureFontSize().
//
// AMOUNT DUE PASS (earlier): added two toggles — dueDateSummary and
// amountDue — to the Invoice Details group, gating the Due Date/Amount
// Due bar rendered directly under Grand Total.
//
// GROUPED TOGGLES PASS (earlier): _FieldsSection rebuilt from a flat
// list of SwitchListTiles into six collapsible groups — see this pass's
// note in the class body for full behaviour.
//
// PAYMENT INFO / TERMS & SIGNATURE TOGGLES PASS (earlier): added
// show/hide toggle rows for the eight new InvoiceData fields.
//
// HISTORY WIRING PASS (earlier): _handleSave() now logs a 'created'
// activity-feed event via HistoryProvider right after
// InvoiceProvider.saveCurrentInvoice() succeeds.
//
// SAVE-FROM-CUSTOMISE PASS (earlier): Invoice's save no longer happens
// via a dialog on InvoiceFullPreviewScreen — this step now shows an
// "Invoice Title" section and the bottom bar's primary button is
// "Save Invoice".
//
// SUMMARY LAYOUT / SUMMARY PASS (earlier): added a plain-header Summary
// section with InvoiceTotalsCard.
//
// FIELDS SECTION REORDER / FIELDS SECTION PASS (earlier): added and
// repositioned the "Invoice Fields" toggle section under Live Preview.
//
// LOGO SIZE RANGE / COLOR PICKER CONSOLIDATION / TEMPLATE / LOGO SIZER
// PASSES (earlier): see prior header comments for each of these —
// unaffected by this update.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/invoice_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/invoice_data.dart';
import '../../../models/history_event.dart' show HistoryDocType;
import '../../../models/invoice_color_ext.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../invoice_edit_widgets.dart' show InvoiceTotalsCard;
import '../step_create_invoice/create_invoice_form_widgets.dart' show CreateInvoiceField;
import '../../saved_invoice_details_section/saved_document_detail_screen.dart';
import 'invoice_full_preview_screen.dart';
// MERGE PASS: both symbols now come from the merged executive_template.dart
// instead of the deleted executive_invoice_logic_data.dart /
// executive_invoice_stationary_layout.dart.
import '../../../document_layout_templates/01_executive/executive_template.dart'
    show ExecutiveInvoicePreview, invoiceAccent;
// MERGE PASS: kPageW now lives on the shared widgets file (every
// template's page geometry constant lives here, not per-template).
import '../../../document_layout_templates/document_template_layout_data/doc_header.dart'
    show kPageW;
import '../../../document_layout_templates/pagination/scaled_page_stack.dart';
import '../invoice_template_previews/preview_registry.dart' show buildInvoicePreview;

// SIGNATURE FONT FAMILY PASS: the six real script font families offered
// for a typed signature — now bundled locally (see pubspec.yaml), not
// fetched at runtime. Kept local to this file (rather than imported
// from the stationary-layout file) so this file has no compile-time
// dependency on that file's internals — just the string names, which
// InvoiceData.signatureFontFamily stores directly and consumers
// resolve by exact registered family name.
const List<String> kSignatureFonts = [
  'Dancing Script',
  'Great Vibes',
  'Sacramento',
  'Pacifico',
  'Alex Brush',
  'Caveat',
];

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

                GestureDetector(
                  onTap: _openFullPreview,
                  child: const _InvoicePreviewCard(),
                ),
                const SizedBox(height: 24),

                const _FieldsSection(),
                const SizedBox(height: 16),

                const _LogoSection(),
                const SizedBox(height: 16),

                const _LogoSizeSection(),
                const SizedBox(height: 16),

                const _ColourSection(),
                const SizedBox(height: 16),

                const _FontSection(),
                const SizedBox(height: 16),

                const _SizeSection(),
                const SizedBox(height: 24),

                const _SummarySection(),
                const SizedBox(height: 20),

                // PREVIEW BUTTON PARITY PASS: matches Receipt's inline
                // "Preview & Download" CTA button
                // (receipt_step_customise.dart) — same position (right
                // after Summary), same shape, but tinted with this
                // invoice's own accent color instead of Receipt's fixed
                // green.
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
// Preview & Download button — PREVIEW BUTTON PARITY PASS: mirrors
// Receipt's inline CTA button exactly in shape/layout, but watches
// InvoiceProvider itself to pick up this invoice's own accent color via
// invoiceAccent() rather than Receipt's fixed green gradient.
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
    final accent = _colorForScheme(provider.invoiceData.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _plainSectionHeader(context, 'Invoice Title', accent, icon: Icons.title_rounded),
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
// Inline invoice preview
// =============================================================================

class _InvoicePreviewCard extends StatefulWidget {
  const _InvoicePreviewCard();

  @override
  State<_InvoicePreviewCard> createState() => _InvoicePreviewCardState();
}

class _InvoicePreviewCardState extends State<_InvoicePreviewCard> {
  int _pageCount = 1;

  void _setPageCount(int count) {
    if (count == _pageCount) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _pageCount = count);
    });
  }

  Widget _buildPreviewWidget(InvoiceData data) {
    if (data.layoutTemplateId == 1) {
      return ExecutiveInvoicePreview(data: data, onPageCount: _setPageCount);
    }
    _setPageCount(1);
    return buildInvoicePreview(data.layoutTemplateId, data) ??
        ExecutiveInvoicePreview(data: data, onPageCount: _setPageCount);
  }

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final data        = provider.invoiceData;
    final accent      = invoiceAccent(data);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
          ),
          child: Row(children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Text('Live Preview',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
            const Spacer(),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.article_outlined, size: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.45)),
              const SizedBox(width: 4),
              Text(_pageCount == 1 ? '1 page' : '$_pageCount pages',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.6))),
            ]),
          ]),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ScaledPageStack(
                  targetWidth: constraints.maxWidth,
                  nativePageWidth: kPageW,
                  child: _buildPreviewWidget(data),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Tap to preview & download PDF',
              style: TextStyle(fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                  fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }
}

// =============================================================================
// Business logo section
// =============================================================================

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final data     = provider.invoiceData;
    final colorScheme = Theme.of(context).colorScheme;
    final accent   = _colorForScheme(data.colorScheme);
    final hasLogo  = data.businessLogoPath != null && data.businessLogoPath!.isNotEmpty;
    final currentShape = logoShapeFromString(data.businessLogoShape);
    final previewSize = (90.0 + (data.businessLogoDisplaySize - 40.0) * 3.0).clamp(90.0, 260.0);

    return _SectionCard(
      icon: Icons.image_rounded,
      title: 'Business Logo',
      child: Column(
        children: [
          Center(
            child: Opacity(
              opacity: hasLogo ? 1.0 : 0.5,
              child: SharedLogoPicker(
                logoPath: data.businessLogoPath,
                logoOffset: Offset(data.businessLogoOffsetDx, data.businessLogoOffsetDy),
                logoScale: data.businessLogoScale,
                logoShape: currentShape,
                accent: accent,
                compact: true,
                compactBoxSize: previewSize,
                onChanged: (path, offset, scale, shape) {
                  provider.updateBusinessLogo(
                    path: path,
                    offset: offset,
                    scale: scale,
                    shape: shape.storageName,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasLogo ? 'Tap logo to change, reposition, or remove' : 'Tap to upload a logo',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 14),
          Opacity(
            opacity: hasLogo ? 1.0 : 0.4,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: LogoShape.values.map((s) {
                final selected = s == currentShape;
                return GestureDetector(
                  onTap: hasLogo
                      ? () => provider.updateBusinessLogo(
                            path: data.businessLogoPath,
                            offset: Offset(data.businessLogoOffsetDx, data.businessLogoOffsetDy),
                            scale: data.businessLogoScale,
                            shape: s.storageName,
                          )
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? accent : colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, size: 16, color: selected ? accent : colorScheme.onSurface.withValues(alpha: 0.5)),
                        const SizedBox(width: 5),
                        Text(s.label,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? accent : colorScheme.onSurface.withValues(alpha: 0.5))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Logo size section
// =============================================================================

class _LogoSizeSection extends StatelessWidget {
  const _LogoSizeSection();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final data        = provider.invoiceData;
    final colorScheme = Theme.of(context).colorScheme;
    final accent      = _colorForScheme(data.colorScheme);
    final hasLogo = data.businessLogoPath != null && data.businessLogoPath!.isNotEmpty;

    return Opacity(
      opacity: hasLogo ? 1.0 : 0.4,
      child: _SectionCard(
        icon: Icons.photo_size_select_large_rounded,
        title: 'Logo Size',
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.image_outlined, size: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.5)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor:   accent,
                      inactiveTrackColor: accent.withValues(alpha: 0.2),
                      thumbColor:         accent,
                      overlayColor:       accent.withValues(alpha: 0.15),
                      trackHeight:        4,
                    ),
                    child: Slider(
                      value: data.businessLogoDisplaySize,
                      min: 24,
                      max: 96,
                      divisions: 12,
                      onChanged: hasLogo ? (v) => provider.updateBusinessLogoSize(v) : null,
                    ),
                  ),
                ),
                Icon(Icons.image_outlined, size: 24,
                    color: colorScheme.onSurface.withValues(alpha: 0.5)),
              ],
            ),
            Text(
              hasLogo ? '${data.businessLogoDisplaySize.toInt()}px' : 'Add a logo to enable',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: hasLogo ? accent : colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Colour section
// =============================================================================

Color _colorForScheme(InvoiceColor scheme) {
  const map = {
    InvoiceColor.blue:   Color(0xFF1565C0),
    InvoiceColor.green:  Color(0xFF2E7D32),
    InvoiceColor.purple: Color(0xFF6A1B9A),
    InvoiceColor.orange: Color(0xFFE65100),
    InvoiceColor.red:    Color(0xFFC62828),
    InvoiceColor.teal:   Color(0xFF00695C),
    InvoiceColor.black:  Color(0xFF212121),
    InvoiceColor.indigo: Color(0xFF283593),
  };
  return map[scheme] ?? const Color(0xFF1565C0);
}

Widget _plainSectionHeader(
  BuildContext context,
  String label,
  Color accent, {
  IconData? icon,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration:
              BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        if (icon != null) ...[
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

class _ColourSection extends StatelessWidget {
  const _ColourSection();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final selected    = provider.invoiceData.colorScheme;
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.palette_rounded,
      title: 'Accent Colour',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
        ),
        itemCount: InvoiceColor.values.length,
        itemBuilder: (_, i) {
          final scheme = InvoiceColor.values[i];
          final isSelected = scheme == selected;
          return GestureDetector(
            onTap: () => provider.updateColorScheme(scheme),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2196F3)
                      : colorScheme.outline.withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(scheme.primaryColor),
                            Color(scheme.accentColor),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(9),
                          topRight: Radius.circular(9),
                        ),
                      ),
                      child: isSelected
                          ? const Center(
                              child: Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 22))
                          : null,
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(9),
                        bottomRight: Radius.circular(9),
                      ),
                    ),
                    child: Text(
                      scheme.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF2196F3)
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Font section
// =============================================================================

// FONT FAMILY LIST FIX: this list now exactly mirrors the family names
// actually registered in pubspec.yaml's flutter: fonts: section (plus
// the 'Default' sentinel, which deliberately doesn't match any
// registered family — it falls through to the platform default on
// purpose). Previously included "Playfair Display" (pubspec only
// registered "Playfair" — mismatch) and "Source Sans Pro" (never
// bundled at all), and never offered Lora/Nunito/Raleway/Space Grotesk
// even though those were already bundled and unused.
const _kFonts = [
  'Default',
  'Roboto',
  'Lato',
  'Lora',
  'Montserrat',
  'Nunito',
  'Open Sans',
  'Playfair Display',
  'Raleway',
  'Space Grotesk',
];

class _FontSection extends StatelessWidget {
  const _FontSection();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final selected    = provider.invoiceData.fontFamily;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = _colorForScheme(provider.invoiceData.colorScheme);

    return _SectionCard(
      icon: Icons.text_fields_rounded,
      title: 'Font Family',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _kFonts.map((font) {
          final isActive = font == selected;
          // FONT CHIP PREVIEW PASS: 'Default' deliberately matches no
          // registered family — preview it with the platform default
          // (fontFamily: null) rather than passing the literal string
          // 'Default' as a font name. Every other entry here is a real,
          // locally-bundled family (see pubspec.yaml), so passing it
          // straight through resolves correctly with no network call.
          final previewFamily = font == 'Default' ? null : font;
          return GestureDetector(
            onTap: () => provider.updateFontFamily(font),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? accent
                    : isDark
                        ? const Color(0xFF2A2A3E)
                        : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? accent
                      : colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                font,
                style: TextStyle(
                  fontFamily: previewFamily,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Size section
// =============================================================================

class _SizeSection extends StatelessWidget {
  const _SizeSection();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<InvoiceProvider>();
    final size        = provider.fontSize;
    final colorScheme = Theme.of(context).colorScheme;
    final accent      = _colorForScheme(provider.invoiceData.colorScheme);

    return _SectionCard(
      icon: Icons.format_size_rounded,
      title: 'Text Size',
      child: Column(
        children: [
          Row(
            children: [
              Text('A',
                  style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5))),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor:   accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.2),
                    thumbColor:         accent,
                    overlayColor:       accent.withValues(alpha: 0.15),
                    trackHeight:        4,
                  ),
                  child: Slider(
                    value: size,
                    min: 10,
                    max: 16,
                    divisions: 6,
                    onChanged: (v) => provider.updateFontSize(v),
                  ),
                ),
              ),
              Text('A',
                  style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.5))),
            ],
          ),
          Text(
            '${size.toInt()}pt',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: accent),
          ),
        ],
      ),
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
    final accent   = _colorForScheme(data.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _plainSectionHeader(context, 'Summary', accent, icon: Icons.summarize_rounded),
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
// Fields section — GROUPED, collapsible, each group with its own master
// switch and a REMEMBERED (persisted) expand state — see file header
// comment (PERSISTED GROUP COLLAPSE PASS).
// =============================================================================

class _FieldToggleSpec {
  final String key;
  final String label;
  final IconData icon;
  const _FieldToggleSpec(this.key, this.label, this.icon);
}

class _FieldGroupSpec {
  final String label;
  final IconData icon;
  final List<_FieldToggleSpec> fields;
  const _FieldGroupSpec(this.label, this.icon, this.fields);
}

const _kFieldGroups = <_FieldGroupSpec>[
  _FieldGroupSpec('Header & Meta', Icons.tag_rounded, [
    _FieldToggleSpec('invoiceNumber', 'Invoice Number', Icons.tag_rounded),
    _FieldToggleSpec('date', 'Issue Date', Icons.calendar_today_rounded),
    _FieldToggleSpec('dueDate', 'Due Date', Icons.event_rounded),
    _FieldToggleSpec('businessLogo', 'Business Logo', Icons.image_rounded),
  ]),
  _FieldGroupSpec('Billed To', Icons.person_rounded, [
    _FieldToggleSpec('customerName', 'Customer Name', Icons.person_outline_rounded),
    _FieldToggleSpec('customerEmail', 'Customer Email', Icons.email_rounded),
    _FieldToggleSpec('customerPhone', 'Customer Phone', Icons.phone_rounded),
    _FieldToggleSpec('customerAddress', 'Customer Address', Icons.location_on_rounded),
  ]),
  _FieldGroupSpec('Invoice Details', Icons.receipt_long_rounded, [
    _FieldToggleSpec('tax', 'Tax', Icons.percent_rounded),
    _FieldToggleSpec('discount', 'Discount', Icons.local_offer_rounded),
    _FieldToggleSpec('dueDateSummary', 'Due Date (Totals)', Icons.event_available_rounded),
    _FieldToggleSpec('amountDue', 'Amount Due (Totals)', Icons.payments_rounded),
  ]),
  // PAYMENT TERMS REMOVAL PASS: 'paymentTerms' toggle row removed — this
  // group is now 5 fields instead of 6.
  _FieldGroupSpec('Payment Info', Icons.account_balance_rounded, [
    _FieldToggleSpec('bankName', 'Bank Name', Icons.account_balance_rounded),
    _FieldToggleSpec('accountName', 'Account Name', Icons.badge_outlined),
    _FieldToggleSpec('accountNumber', 'Account Number', Icons.pin_rounded),
    _FieldToggleSpec('otherPaymentDetails', 'Other Payment Details', Icons.notes_outlined),
    _FieldToggleSpec('poNumber', 'PO / Reference Number', Icons.confirmation_number_outlined),
  ]),
  _FieldGroupSpec('Terms & Signature', Icons.gavel_rounded, [
    _FieldToggleSpec('termsAndConditions', 'Terms & Conditions', Icons.gavel_rounded),
    _FieldToggleSpec('signature', 'Signature', Icons.draw_outlined),
  ]),
  _FieldGroupSpec('Notes & Thank You', Icons.notes_rounded, [
    _FieldToggleSpec('notes', 'Notes', Icons.notes_rounded),
    _FieldToggleSpec('thankYouMessage', 'Thank You Message', Icons.favorite_border_rounded),
  ]),
];

// PERSISTED GROUP COLLAPSE PASS: SharedPreferences key prefix for each
// group's remembered expand/collapse state. Keyed by group label; not
// per-invoice — this is a sheet-level UI preference.
const _kFieldGroupExpandedPrefPrefix = 'invoice_customise_field_group_expanded_';

class _FieldsSection extends StatefulWidget {
  const _FieldsSection();

  @override
  State<_FieldsSection> createState() => _FieldsSectionState();
}

class _FieldsSectionState extends State<_FieldsSection> {
  // Group label -> expanded. Starts empty; _loadPersistedExpand() fills
  // it in from SharedPreferences (defaulting each group to false/closed
  // if nothing was ever persisted for it). Until that load completes,
  // _groupCard's `_expanded[group.label] ?? false` reads as closed too,
  // so there's no flicker from an open-then-closes-again default.
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    _loadPersistedExpand();
  }

  Future<void> _loadPersistedExpand() async {
    final prefs = await SharedPreferences.getInstance();
    final loaded = <String, bool>{};
    for (final g in _kFieldGroups) {
      loaded[g.label] = prefs.getBool('$_kFieldGroupExpandedPrefPrefix${g.label}') ?? false;
    }
    if (!mounted) return;
    setState(() => _expanded.addAll(loaded));
  }

  Future<void> _persistExpand(String groupLabel, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kFieldGroupExpandedPrefPrefix$groupLabel', value);
  }

  bool _groupIsOn(InvoiceData data, _FieldGroupSpec group) {
    return group.fields.every((f) => data.enabledFields[f.key] ?? true);
  }

  void _toggleGroup(InvoiceProvider provider, _FieldGroupSpec group, bool v) {
    final updated = Map<String, bool>.from(provider.invoiceData.enabledFields);
    for (final f in group.fields) {
      updated[f.key] = v;
    }
    provider.updateEnabledFields(updated);
    setState(() => _expanded[group.label] = v);
    _persistExpand(group.label, v);
  }

  void _setExpanded(String groupLabel, bool v) {
    setState(() => _expanded[groupLabel] = v);
    _persistExpand(groupLabel, v);
  }

  Widget _fieldRow(BuildContext context, InvoiceProvider provider, _FieldToggleSpec f) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _colorForScheme(provider.invoiceData.colorScheme);
    final value = provider.invoiceData.enabledFields[f.key] ?? true;
    final isSignatureRow = f.key == 'signature';
    final sigSize = provider.invoiceData.signatureFontSize;
    final sigFamily = provider.invoiceData.signatureFontFamily;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(9),
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : const Color(0xFFFAFAFA),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            visualDensity: VisualDensity.compact,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(f.icon, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.label,
                    style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            value: value,
            activeThumbColor: accent,
            onChanged: (v) {
              final updated = Map<String, bool>.from(provider.invoiceData.enabledFields);
              updated[f.key] = v;
              provider.updateEnabledFields(updated);
            },
          ),
          if (isSignatureRow && value) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Row(
                children: [
                  Icon(Icons.format_size_rounded, size: 15,
                      color: colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 6),
                  Text('Size', style: TextStyle(fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.55))),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accent,
                        inactiveTrackColor: accent.withValues(alpha: 0.2),
                        thumbColor: accent,
                        overlayColor: accent.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: sigSize,
                        min: 14,
                        max: 36,
                        divisions: 11,
                        onChanged: (v) => provider.updateSignatureFontSize(v),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text('${sigSize.toInt()}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
                  ),
                ],
              ),
            ),
            // SIGNATURE FONT FAMILY PASS: font-chip row directly beneath
            // the Size slider — same visibility gate (signature toggle
            // on). Tapping a chip writes InvoiceData.signatureFontFamily
            // via InvoiceProvider.updateSignatureFontFamily(). Each
            // chip's own label previews in its actual script font — now
            // via a plain TextStyle(fontFamily:) against the locally
            // bundled asset (see pubspec.yaml), not GoogleFonts.getFont()
            // — so the person can see what they're picking before
            // committing, with no network dependency.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kSignatureFonts.map((font) {
                  final active = sigFamily == font;
                  return GestureDetector(
                    onTap: () => provider.updateSignatureFontFamily(active ? '' : font),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: active
                            ? accent
                            : (isDark
                                ? colorScheme.surfaceContainerHighest
                                : const Color(0xFFF0F0F0)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active ? accent : colorScheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        font,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 13,
                          color: active ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _groupCard(BuildContext context, InvoiceProvider provider, _FieldGroupSpec group) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _colorForScheme(provider.invoiceData.colorScheme);
    final data = provider.invoiceData;
    final groupOn = _groupIsOn(data, group);
    // PERSISTED GROUP COLLAPSE PASS: reads only the remembered/default
    // state — no longer falls back to groupOn (whether the fields
    // happen to already be all-on), so a freshly-all-on group still
    // starts closed until the person opens it themselves.
    final isExpanded = _expanded[group.label] ?? false;
    final onCount = group.fields.where((f) => data.enabledFields[f.key] ?? true).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? const Color(0xFF23233A) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(12),
              bottom: isExpanded ? Radius.zero : const Radius.circular(12),
            ),
            onTap: () => _setExpanded(group.label, !isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(group.icon, size: 17,
                      color: groupOn ? accent : colorScheme.onSurface.withValues(alpha: 0.45)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      group.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$onCount/${group.fields.length}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accent),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 6),
                  Switch(
                    value: groupOn,
                    activeThumbColor: accent,
                    onChanged: (v) => _toggleGroup(provider, group, v),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Column(
                children: [for (final f in group.fields) _fieldRow(context, provider, f)],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.tune_rounded,
      title: 'Invoice Fields',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flip a group on/off, or tap it to expand and fine-tune individual fields.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 10),
          for (final g in _kFieldGroups) _groupCard(context, provider, g),
        ],
      ),
    );
  }
}

// =============================================================================
// Reusable section card
// =============================================================================

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final Widget   child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.55)),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
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
