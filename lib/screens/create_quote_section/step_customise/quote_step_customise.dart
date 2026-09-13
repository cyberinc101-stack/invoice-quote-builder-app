// lib/screens/create_quote_section/step_customise/quote_step_customise.dart
//
// MERGE PASS (this update): imports redirected off the three deleted
// executive_quote_logic_data.dart / executive_quote_stationary_
// layout.dart / executive_invoice_payment_terms_signature.dart files.
// ExecutiveQuotePreview, quoteAccent, and kSignatureFonts now all come
// from executive_template.dart (the merged, adapter-based file that
// replaces all three — see that file's own MERGE PASS header comment),
// and kPageW now comes from shared_doc_widgets.dart. No other change in
// this file — same widget tree, same behavior, same call sites.
//
// DEBUG PASS (earlier): added a one-line debugPrint at the top of
// _QuotePreviewCardState._buildPreviewWidget() to diagnose why terms/
// signature aren't rendering on the Live Preview for brand-new quotes.
// Prints QuoteData.signatureMode, termsAndConditions, and both relevant
// enabledFields flags every time the preview widget builds. Safe to
// remove once the underlying bug is found — has no effect on behavior,
// only console output.
//
// TERMS & SIGNATURE PASS (earlier): "Terms & Signature" is now a
// real toggle group (termsAndConditions alongside Signature) —
// QuoteData has a matching termsAndConditions field
// (quote_data.dart's own PAYMENT INFO + TERMS PASS). Text entry still
// happens on the template sheet, not here — Customise only toggles
// visibility, same as every other field. Payment Info was deliberately
// left off Quote's Customise (and off its template sheet) — a quote
// isn't collecting payment, that belongs on the Invoice it converts
// into — even though QuoteData still carries bankName/etc harmlessly
// unused.
//
// FONT FIX PASS (earlier): _kFonts previously listed "Source Sans
// Pro" (never bundled) and was missing Lora/Nunito/Raleway/Space
// Grotesk — the same stale-list bug Invoice's step_customise.dart had
// before its own FONT FAMILY LIST FIX. Selecting "Source Sans Pro" set
// QuoteData.fontFamily to a string that resolves to nothing, silently
// falling back to the platform default everywhere fontFamily is read.
// _kFonts now exactly mirrors Invoice's/pubspec's bundled family names.
// The Font Family chips also now preview each chip's own label IN that
// font (fontFamily: previewFamily), matching Invoice's identical chip
// fix and the Signature Font chips just below on this same screen.
// 'Default' deliberately maps to fontFamily: null (platform default)
// rather than the literal string 'Default'.
//
// SIGNATURE PASS (earlier): added a new _SignatureSection between
// _FieldsSection and _LogoSection — Quote's Signature toggle now lives
// here (previously QuoteData had no signature fields at all, and the
// only signature UI in the app was quote_step_template_signature.dart's
// _QuoteSignatureSection, which wrote to QuoteTemplate, not the live
// QuoteData). Three mode chips (Upload/Type/Blank) mirror
// _QuoteSignatureSection's own chip row exactly; picking 'typed' reveals
// a name field, an inline Size slider, and six google_fonts script-font
// chips (Dancing Script/Great Vibes/Sacramento/Pacifico/Alex Brush/
// Caveat — kSignatureFonts, now imported from executive_template.dart so
// all three doc types share one canonical list); picking 'image' reveals
// an upload tile. Tapping the already-selected mode chip deselects back
// to '' (no signature at all), matching Invoice's deselect convention.
// Wired to QuoteProvider's new updateSignatureMode/Name/ImagePath/
// FontSize/FontFamily methods (quote_provider.dart's SIGNATURE PASS),
// which write straight onto the live QuoteData via copyWith — same
// layer every other control on this screen already writes to. The
// section itself is wrapped so it only shows once 'signature' is on in
// enabledFields; a small toggle at the top of the section controls that
// field the same way every other _FieldsSection row does, kept separate
// here (rather than folded into _FieldsSection's Quote Details group)
// since it needs its own multi-row conditional UI that a plain
// SwitchListTile can't hold.
//
// PREVIEW BUTTON PARITY PASS (earlier): added an inline "Preview &
// Download" call-to-action button, matching Receipt's/Invoice's
// identical additions.
//
// LAYOUT PARITY PASS (earlier): full rebuild to match Invoice's
// step_customise.dart structure and file layout.
//
// FIELD GROUPS (earlier) — see prior header comment for the full
// rationale; unaffected by this update except that 'signature' now has
// its own dedicated section rather than living in _FieldsSection.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../providers/quote_provider.dart';
import '../../../providers/history_provider.dart';
import '../../../models/quote_data.dart';
import '../../../models/history_event.dart' show HistoryDocType;
import '../../../widgets/shared_logo_picker.dart';
import '../quote_edit_widgets.dart' show QuoteField, QuoteTotalsCard, QuoteColorPicker;
import '../../saved_invoice_details_section/saved_document_detail_screen.dart';
import 'quote_full_preview_screen.dart';
// MERGE PASS: all three symbols now come from the merged
// executive_template.dart instead of the deleted
// executive_quote_logic_data.dart / executive_quote_stationary_
// layout.dart / executive_invoice_payment_terms_signature.dart.
import '../../../document_layout_templates/01_executive/executive_template.dart'
    show ExecutiveQuotePreview, quoteAccent, kSignatureFonts;
// MERGE PASS: kPageW now lives on the shared widgets file.
import '../../../document_layout_templates/document_template_layout_data/doc_header.dart'
    show kPageW;
import '../../../document_layout_templates/pagination/scaled_page_stack.dart';
import '../quote_template_chooser_01/preview_registry.dart' show buildQuotePreview;

// FONT FIX PASS: this list now exactly mirrors the family names
// actually registered in pubspec.yaml's flutter: fonts: section (the
// same set Invoice's step_customise.dart offers), plus the 'Default'
// sentinel, which deliberately doesn't match any registered family — it
// falls through to the platform default on purpose. Previously included
// "Source Sans Pro" (never bundled at all) and never offered
// Lora/Nunito/Raleway/Space Grotesk even though those were already
// bundled and unused.
const List<String> _kFonts = [
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

// =============================================================================
// Public entry point
// =============================================================================

class QuoteStepCustomise extends StatefulWidget {
  final VoidCallback onBack;
  const QuoteStepCustomise({super.key, required this.onBack});

  @override
  State<QuoteStepCustomise> createState() => _QuoteStepCustomiseState();
}

class _QuoteStepCustomiseState extends State<QuoteStepCustomise> {
  final ScrollController _scrollController = ScrollController();

  late final TextEditingController _titleCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = context.read<QuoteProvider>().quoteData;
    final suggested = data.clientName.isNotEmpty
        ? '${data.clientName} — ${data.quoteNumber.isNotEmpty ? data.quoteNumber : 'Quote'}'
        : data.quoteNumber;
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
    final provider = context.read<QuoteProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: provider,
          child: const QuoteFullPreviewScreen(),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give this quote a title before saving')),
      );
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<QuoteProvider>();
    final history = context.read<HistoryProvider>();
    try {
      final saved = provider.saveCurrentQuote(
        title: _titleCtrl.text.trim(),
        templateName: 'Executive',
      );
      final d = saved.data;
      unawaited(history.logCreated(
        docType: HistoryDocType.quote,
        docId: saved.id,
        docNumber: d.quoteNumber,
        clientName: d.clientName.isEmpty ? null : d.clientName,
        amount: d.grandTotal,
        currency: d.currency,
      ));
      provider.resetQuoteData();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SavedDocumentDetailScreen.quote(saved)),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't save quote: $e")),
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
                  'Personalise your quote design',
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
                  child: const _QuotePreviewCard(),
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

                _PreviewButton(onTap: _openFullPreview),
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _scrollToTop,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A0D33)
                          : const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF7B1FA2).withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard_arrow_up_rounded,
                            color: Color(0xFF7B1FA2), size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Back to Top',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B1FA2),
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
    final provider = context.watch<QuoteProvider>();
    final accent = quoteAccent(provider.quoteData);

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
    final provider = context.watch<QuoteProvider>();
    final accent = _colorForScheme(provider.quoteData.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _plainSectionHeader(context, 'Quote Title', accent, icon: Icons.title_rounded),
        QuoteField(
          ctrl: titleCtrl,
          label: 'Title (for your records)',
          hint: 'e.g. Acme Corp — Quote',
          icon: Icons.bookmark_outline_rounded,
          max: 80,
          accent: accent,
        ),
      ],
    );
  }
}

// =============================================================================
// Inline quote preview
// =============================================================================

class _QuotePreviewCard extends StatefulWidget {
  const _QuotePreviewCard();

  @override
  State<_QuotePreviewCard> createState() => _QuotePreviewCardState();
}

class _QuotePreviewCardState extends State<_QuotePreviewCard> {
  int _pageCount = 1;

  void _setPageCount(int count) {
    if (count == _pageCount) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _pageCount = count);
    });
  }

  Widget _buildPreviewWidget(QuoteData data) {
    final registryWidget = buildQuotePreview(data.layoutTemplateId, data);
    if (registryWidget != null) {
      _setPageCount(1);
      return registryWidget;
    }
    return ExecutiveQuotePreview(data: data, onPageCount: _setPageCount);
  }

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<QuoteProvider>();
    final data        = provider.quoteData;
    final accent      = quoteAccent(data);
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
    final provider = context.watch<QuoteProvider>();
    final data     = provider.quoteData;
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
                  provider.updateBusinessInfo(
                    businessLogoPath: path,
                    clearBusinessLogo: path == null,
                    businessLogoOffsetDx: offset.dx,
                    businessLogoOffsetDy: offset.dy,
                    businessLogoScale: scale,
                    businessLogoShape: shape.storageName,
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
                      ? () => provider.updateBusinessInfo(
                            businessLogoPath: data.businessLogoPath,
                            businessLogoOffsetDx: data.businessLogoOffsetDx,
                            businessLogoOffsetDy: data.businessLogoOffsetDy,
                            businessLogoScale: data.businessLogoScale,
                            businessLogoShape: s.storageName,
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
    final provider    = context.watch<QuoteProvider>();
    final data        = provider.quoteData;
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
                      onChanged: hasLogo
                          ? (v) => provider.updateBusinessInfo(businessLogoDisplaySize: v)
                          : null,
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

Color _colorForScheme(QuoteColor scheme) {
  const map = {
    QuoteColor.blue:   Color(0xFF1565C0),
    QuoteColor.green:  Color(0xFF2E7D32),
    QuoteColor.purple: Color(0xFF6A1B9A),
    QuoteColor.orange: Color(0xFFE65100),
    QuoteColor.red:    Color(0xFFC62828),
    QuoteColor.teal:   Color(0xFF00695C),
    QuoteColor.black:  Color(0xFF212121),
    QuoteColor.indigo: Color(0xFF283593),
  };
  return map[scheme] ?? const Color(0xFF6A1B9A);
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
    final provider    = context.watch<QuoteProvider>();
    final selected    = provider.quoteData.colorScheme;

    return _SectionCard(
      icon: Icons.palette_rounded,
      title: 'Accent Colour',
      child: QuoteColorPicker(
        selected: selected,
        onChanged: provider.updateColorScheme,
      ),
    );
  }
}

// =============================================================================
// Font section
// =============================================================================

class _FontSection extends StatelessWidget {
  const _FontSection();

  @override
  Widget build(BuildContext context) {
    final provider    = context.watch<QuoteProvider>();
    final selected    = provider.quoteData.fontFamily;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final accent      = _colorForScheme(provider.quoteData.colorScheme);

    return _SectionCard(
      icon: Icons.text_fields_rounded,
      title: 'Font Family',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _kFonts.map((font) {
          final isActive = font == selected;
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
    final provider    = context.watch<QuoteProvider>();
    final size        = provider.quoteData.fontSize;
    final colorScheme = Theme.of(context).colorScheme;
    final accent      = _colorForScheme(provider.quoteData.colorScheme);

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

// TAX/DISCOUNT NAME REMOVAL PASS: the "Tax Name (Optional)"/
// "Discount Name (Optional)" fields have been removed from this
// section entirely — QuoteData.taxName/discountName still exist on the
// model (harmless, unused from here) but are no longer editable from
// Customise. Simplified back to a StatelessWidget since no
// TextEditingControllers are needed anymore.
class _SummarySection extends StatelessWidget {
  const _SummarySection();

  String _currencyPrefix(QuoteData data) {
    final symbol = data.currencySymbol.trim();
    final code = data.currency.trim().toUpperCase();
    if (symbol.isNotEmpty) return symbol;
    if (code.isNotEmpty) return '$code ';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuoteProvider>();
    final data     = provider.quoteData;
    final accent   = _colorForScheme(data.colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _plainSectionHeader(context, 'Summary', accent, icon: Icons.summarize_rounded),
        QuoteTotalsCard(
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
// Fields section
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
    _FieldToggleSpec('invoiceNumber', 'Quote Number', Icons.tag_rounded),
    _FieldToggleSpec('date', 'Issue Date', Icons.calendar_today_rounded),
    _FieldToggleSpec('dueDate', 'Valid Until', Icons.event_rounded),
    _FieldToggleSpec('businessLogo', 'Business Logo', Icons.image_rounded),
  ]),
  _FieldGroupSpec('Client Details', Icons.person_rounded, [
    _FieldToggleSpec('customerName', 'Client Name', Icons.person_outline_rounded),
    _FieldToggleSpec('customerEmail', 'Client Email', Icons.email_rounded),
    _FieldToggleSpec('customerPhone', 'Client Phone', Icons.phone_rounded),
    _FieldToggleSpec('customerAddress', 'Client Address', Icons.location_on_rounded),
  ]),
  _FieldGroupSpec('Quote Details', Icons.request_quote_rounded, [
    _FieldToggleSpec('tax', 'Tax', Icons.percent_rounded),
    _FieldToggleSpec('discount', 'Discount', Icons.local_offer_rounded),
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

const _kFieldGroupExpandedPrefPrefix = 'quote_customise_field_group_expanded_';

class _FieldsSection extends StatefulWidget {
  const _FieldsSection();

  @override
  State<_FieldsSection> createState() => _FieldsSectionState();
}

class _FieldsSectionState extends State<_FieldsSection> {
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

  bool _groupIsOn(QuoteData data, _FieldGroupSpec group) {
    return group.fields.every((f) => data.enabledFields[f.key] ?? true);
  }

  void _toggleGroup(QuoteProvider provider, _FieldGroupSpec group, bool v) {
    final updated = Map<String, bool>.from(provider.quoteData.enabledFields);
    for (final f in group.fields) {
      updated[f.key] = v;
    }
    provider.updateEnabledFields(updated);
    if (group.label == 'Quote Details') {
      provider.updateQuoteData(provider.quoteData.copyWith(
        taxEnabled: v,
        discountEnabled: v,
      ));
    }
    setState(() => _expanded[group.label] = v);
    _persistExpand(group.label, v);
  }

  void _setExpanded(String groupLabel, bool v) {
    setState(() => _expanded[groupLabel] = v);
    _persistExpand(groupLabel, v);
  }

  Widget _fieldRow(BuildContext context, QuoteProvider provider, _FieldToggleSpec f) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _colorForScheme(provider.quoteData.colorScheme);
    final data = provider.quoteData;

    final isRateRow = f.key == 'tax' || f.key == 'discount';
    final isSignatureRow = f.key == 'signature';
    final value = isRateRow
        ? (f.key == 'tax' ? data.taxEnabled : data.discountEnabled)
        : (data.enabledFields[f.key] ?? true);
    final sigSize = data.signatureFontSize;
    final sigFamily = data.signatureFontFamily;

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
              final updated = Map<String, bool>.from(data.enabledFields);
              updated[f.key] = v;
              provider.updateEnabledFields(updated);
              if (isRateRow) {
                provider.updateQuoteData(provider.quoteData.copyWith(
                  taxEnabled: f.key == 'tax' ? v : data.taxEnabled,
                  discountEnabled: f.key == 'discount' ? v : data.discountEnabled,
                ));
              }
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

  Widget _groupCard(BuildContext context, QuoteProvider provider, _FieldGroupSpec group) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _colorForScheme(provider.quoteData.colorScheme);
    final data = provider.quoteData;
    final groupOn = _groupIsOn(data, group);
    final isExpanded = _expanded[group.label] ?? false;
    final onCount = group.fields.where((f) {
      if (f.key == 'tax') return data.taxEnabled;
      if (f.key == 'discount') return data.discountEnabled;
      return data.enabledFields[f.key] ?? true;
    }).length;

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
    final provider = context.watch<QuoteProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return _SectionCard(
      icon: Icons.tune_rounded,
      title: 'Quote Fields',
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
                Text('Your quote is ready!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2),
                Text('Give it a title above, then tap Save Quote below.',
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
                            'Save Quote',
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
