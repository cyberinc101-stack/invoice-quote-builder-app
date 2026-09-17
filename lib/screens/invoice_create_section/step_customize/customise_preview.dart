// customise_preview.dart
// lib/screens/invoice_create_section/step_customize/customise_preview.dart
//
// FILE-SPLIT PASS: pulled out of the former monolithic step_customise.dart.
// Holds the live inline invoice preview card (was `_InvoicePreviewCard`,
// now public `InvoicePreviewCard` so step_customise.dart can build it).
// Behavior unchanged from the original file — see doc_header.dart and
// customise_logo_section.dart for the freeform-logo drag/pinch/size fixes
// this preview's callbacks feed into.
//
// DRAG-VS-TAP CONFLICT FIX (this update): step_customise.dart used to wrap
// this ENTIRE card in a GestureDetector(onTap: _openFullPreview) to open
// the full-preview screen. That put a tap recognizer directly in front of
// (as an ancestor of) the freeform header logo's own drag/pinch
// GestureDetector (_DraggableHeaderLogo in doc_header.dart) — a fast,
// deliberate drag generally still wins the gesture arena once it passes
// Flutter's touch-slop threshold, but any shorter, slower, or more
// careful drag attempt (which is most real-world attempts at precisely
// nudging a logo into place) gets resolved as a tap instead, firing
// _openFullPreview and jumping the user to the full-preview screen
// mid-drag instead of moving the logo. Fixed by removing that blanket
// tap wrapper entirely and adding an explicit, OPT-IN
// [onOpenFullPreview] callback here instead, wired only to the small
// "Tap to preview & download PDF" caption at the bottom of the card — a
// region that never overlaps the live document (and therefore never
// overlaps the logo's own gesture detector), so the two gestures can no
// longer compete for the same touch.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/invoice_provider.dart';
import '../../../models/invoice_data.dart';
import '../../../document_layout_templates/01_executive/executive_template.dart'
    show ExecutiveInvoicePreview, invoiceAccent;
import '../../../document_layout_templates/document_template_layout_data/doc_header.dart'
    show kPageW;
import '../../../document_layout_templates/pagination/scaled_page_stack.dart';
import '../invoice_template_previews/preview_registry.dart' show buildInvoicePreview;

// =============================================================================
// Inline invoice preview
//
// PAN + PINCH HEADER LOGO PASS: _buildPreviewWidget hands
// ExecutiveInvoicePreview a SECOND callback (onFreeformLogoScaleChanged)
// alongside the existing offset one, so once the freeform header-logo
// layout is active (Business Name + Tagline both hidden — see
// doc_header.dart), the person can pinch directly on the live preview to
// resize the logo, at the same time as dragging it. Both callbacks write
// straight back to InvoiceProvider, same "live" pattern every other
// control on this screen already uses (Logo Size slider, background
// opacity slider, etc) — and since the "Logo Size in Header" slider in
// the logo section reads the same provider value, pinching and sliding
// stay perfectly in sync with each other.
//
// DRAG-ON-HEADER PASS (earlier): _buildPreviewWidget hands
// ExecutiveInvoicePreview a callback (onFreeformLogoOffsetChanged) so that
// the person can drag the logo right here on the live preview instead of
// through a separate dialog.
// =============================================================================

class InvoicePreviewCard extends StatefulWidget {
  // DRAG-VS-TAP CONFLICT FIX: optional now — when supplied, only the
  // bottom caption below the document opens the full-preview screen.
  // When omitted, the card simply has no tap-to-open behaviour at all.
  final VoidCallback? onOpenFullPreview;

  const InvoicePreviewCard({super.key, this.onOpenFullPreview});

  @override
  State<InvoicePreviewCard> createState() => _InvoicePreviewCardState();
}

class _InvoicePreviewCardState extends State<InvoicePreviewCard> {
  int _pageCount = 1;

  void _setPageCount(int count) {
    if (count == _pageCount) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _pageCount = count);
    });
  }

  Widget _buildPreviewWidget(InvoiceData data, InvoiceProvider provider) {
    // DRAG-ON-HEADER PASS: the drag callback writes the new offset
    // straight back to the provider on every frame of the gesture —
    // same "live" pattern the Logo Size / background sliders already
    // use elsewhere on this screen.
    void onFreeformDrag(Offset normOffset) {
      provider.updateHeaderLogoFreeform(
        offsetDx: normOffset.dx,
        offsetDy: normOffset.dy,
        scale: provider.invoiceData.headerLogoFreeformScale,
      );
    }

    // PAN + PINCH PASS: mirrors onFreeformDrag above, but for the pinch
    // gesture's live scale value instead of position. Reads the current
    // offset back off the provider each call (rather than closing over a
    // stale value) so a pinch mid-drag never clobbers a position change
    // from the same gesture — both callbacks can fire on the same
    // onScaleUpdate frame in doc_header.dart's _DraggableHeaderLogo.
    void onFreeformScale(double newScale) {
      provider.updateHeaderLogoFreeform(
        offsetDx: provider.invoiceData.headerLogoFreeformOffsetDx,
        offsetDy: provider.invoiceData.headerLogoFreeformOffsetDy,
        scale: newScale,
      );
    }

    if (data.layoutTemplateId == 1) {
      return ExecutiveInvoicePreview(
        data: data,
        onPageCount: _setPageCount,
        onFreeformLogoOffsetChanged: onFreeformDrag,
        onFreeformLogoScaleChanged: onFreeformScale,
      );
    }
    _setPageCount(1);
    return buildInvoicePreview(data.layoutTemplateId, data) ??
        ExecutiveInvoicePreview(
          data: data,
          onPageCount: _setPageCount,
          onFreeformLogoOffsetChanged: onFreeformDrag,
          onFreeformLogoScaleChanged: onFreeformScale,
        );
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
                  child: _buildPreviewWidget(data, provider),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        // DRAG-VS-TAP CONFLICT FIX: the full-preview trigger now lives
        // ONLY on this caption — a region that never overlaps the
        // rendered document, so it can never compete with the header
        // logo's own drag/pinch GestureDetector for the same touch.
        // Falls back to plain (non-tappable) text when no callback is
        // supplied.
        Center(
          child: widget.onOpenFullPreview == null
              ? Text('Tap to preview & download PDF',
                  style: TextStyle(fontSize: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.35),
                      fontStyle: FontStyle.italic))
              : GestureDetector(
                  onTap: widget.onOpenFullPreview,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text('Tap to preview & download PDF',
                        style: TextStyle(fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.underline,
                            decorationColor: colorScheme.onSurface.withValues(alpha: 0.3))),
                  ),
                ),
        ),
      ],
    );
  }
}