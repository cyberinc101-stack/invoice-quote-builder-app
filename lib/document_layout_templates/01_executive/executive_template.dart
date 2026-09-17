import 'package:flutter/material.dart';
import '../../models/invoice_data.dart' show InvoiceData, InvoiceColor;
import '../../models/quote_data.dart' show QuoteData, QuoteColor;
import '../../models/receipt_data.dart' show ReceiptData, ReceiptColor;
import '../document_template_layout_data/doc_template_adapter.dart';
import '../document_template_layout_data/doc_edit_bundle.dart';
import '../document_template_layout_data/doc_header.dart'
    show buildSharedHeaderIdentity, buildSharedMetaRow, kRule, kGrey, kGreyLight,
        kPagePadH, kPagePadV, kPageW;
import '../document_template_layout_data/doc_line_items.dart'
    show buildSharedLineItemsHeaderRow;
import '../document_template_layout_data/template_document.dart';
import '../document_backgrounds/background_spec.dart';
import '../document_backgrounds/background_render.dart';

const List<String> kSignatureFonts = [
  'Dancing Script',
  'Great Vibes',
  'Sacramento',
  'Pacifico',
  'Alex Brush',
  'Caveat',
];

// TOP-BLEED FIX (this update): kHeaderBackgroundBandHeight is now the
// TOTAL band height passed to renderDocumentBackground's `height` param
// — it must be read together with kHeaderBackgroundBleedTop below, not
// in isolation. Previously this was 130 with a separate hardcoded
// bleedTop of 16, which left the band's top edge 32pt short of the
// page's true top edge (kPagePadV is 48, not 16) — visible as a strip
// of "invisible padding" above the banner that left/right never had,
// since left/right already correctly bled the full kPagePadH. Fixed by
// bleeding the top the same full amount (kPagePadV) left/right already
// do, and growing the total height by that same +32 so the band's
// BOTTOM edge lands in exactly the same place as before (bottom edge =
// height - bleedTop = 162 - 48 = 114, unchanged from the old 130 - 16 =
// 114) — i.e. this is a pure "extend upward to the true page edge",
// not a change to how far down the band reaches or how much of the
// identity content it covers.
const double kHeaderBackgroundBleedTop = kPagePadV;
const double kHeaderBackgroundBandHeight = 162.0;

// BANNER-SHAPE LOCK PASS: the fixed, locked shape every header
// background image is rendered into — full page width (kPageW, from
// doc_header.dart) by the fixed TOTAL band height above (the true
// on-page banner shape, top edge flush with the page's actual top
// edge). This is the SAME ratio the upload/reposition UI
// (_BackgroundRepositionDialog in customise_background_section.dart)
// should crop against, so what the person frames in that dialog is
// pixel-for-pixel what ends up behind the header. Exported so that
// file can reference it directly instead of a second hardcoded copy of
// the same math.
const double kHeaderBannerAspectRatio = kPageW / kHeaderBackgroundBandHeight; // 595 / 162 ≈ 3.67

Color invoiceAccent(InvoiceData d) {
  switch (d.colorScheme) {
    case InvoiceColor.blue:   return const Color(0xFF2563EB);
    case InvoiceColor.green:  return const Color(0xFF16A34A);
    case InvoiceColor.purple: return const Color(0xFF7C3AED);
    case InvoiceColor.orange: return const Color(0xFFEA580C);
    case InvoiceColor.red:    return const Color(0xFFDC2626);
    case InvoiceColor.teal:   return const Color(0xFF0D9488);
    case InvoiceColor.black:  return const Color(0xFF1A1A1A);
    case InvoiceColor.indigo: return const Color(0xFF4F46E5);
  }
}

Color quoteAccent(QuoteData d) {
  switch (d.colorScheme) {
    case QuoteColor.blue:   return const Color(0xFF2563EB);
    case QuoteColor.green:  return const Color(0xFF16A34A);
    case QuoteColor.purple: return const Color(0xFF7C3AED);
    case QuoteColor.orange: return const Color(0xFFEA580C);
    case QuoteColor.red:    return const Color(0xFFDC2626);
    case QuoteColor.teal:   return const Color(0xFF0D9488);
    case QuoteColor.black:  return const Color(0xFF1A1A1A);
    case QuoteColor.indigo: return const Color(0xFF4F46E5);
  }
}

Color receiptAccent(ReceiptData d) {
  switch (d.colorScheme) {
    case ReceiptColor.blue:   return const Color(0xFF2563EB);
    case ReceiptColor.green:  return const Color(0xFF16A34A);
    case ReceiptColor.purple: return const Color(0xFF7C3AED);
    case ReceiptColor.orange: return const Color(0xFFEA580C);
    case ReceiptColor.red:    return const Color(0xFFDC2626);
    case ReceiptColor.teal:   return const Color(0xFF0D9488);
    case ReceiptColor.black:  return const Color(0xFF1A1A1A);
    case ReceiptColor.indigo: return const Color(0xFF4F46E5);
  }
}

// HEADER-BACKGROUND SCOPE + FULL-BLEED FIX (earlier): two bugs fixed
// together, since both were caused by the same wrapping location.
//
// Bug 1 — background bled into FROM/BILLED-TO/DETAILS: the header
// background used to wrap the WHOLE `content` Column (logo/doc-type
// identity block + the rule divider + buildSharedMetaRow's three-column
// FROM/BILLED-TO/DETAILS row) inside withOptionalBackgroundImage. That
// meant the image + scrim rendered behind the address/date text too, not
// just the header band the person actually meant. Fixed by wrapping ONLY
// buildSharedHeaderIdentity's result — the rule divider and
// buildSharedMetaRow now render on the plain page background exactly as
// before this pass, regardless of whether a header background is set.
//
// Bug 2 — couldn't reach the true left/right page edges: the wrapped
// content lives inside the page's own horizontal padding (kPagePadH on
// each side, applied by A4Paginator's _buildPage), so the background
// band was boxed in ~48pt short of the real page edge no matter what.
//
// CRASH FIX (earlier): the first version of this fix used OverflowBox to
// widen the background band. OverflowBox inherits its PARENT's
// constraint for any axis it doesn't explicitly override — and the live
// Customise-screen preview renders the whole page inside a FittedBox
// (ScaledPageStack, to scale the native-size page down to fit the phone
// screen), which by design gives its child UNBOUNDED height.
//
// DOCUMENT BACKGROUNDS FOUNDATION PASS (earlier): the hand-rolled Stack +
// Positioned bleed logic that used to live directly in this function has
// moved into background_render.dart's renderDocumentBackground() — the
// ONE place every background render site (header here, footer, mid-page
// body) now shares.
//
// BANNER-SHAPE LOCK / COVER-FIT FIX (this update): `fit` used to be
// hardcoded to BoxFit.contain, on the theory that showing the whole
// uploaded image letterboxed was safer than cropping it. In practice
// that was the actual bug behind two reported symptoms at once:
//
//   1. "White space gap at top, image sitting below its container" —
//      contain shrinks the image to fit kPageW's WIDTH, and since almost
//      no uploaded image is naturally kHeaderBannerAspectRatio (~4.58:1)
//      shaped, that left the image shorter than the 130pt band, with
//      empty band space above/below it.
//   2. "Can't move the image left to right" — once an image's width
//      already matches the band's full width under `contain`, there is
//      zero horizontal pixels left to pan through, so
//      headerBackgroundOffsetDx had nothing to actually move.
//
// Switching to BoxFit.cover fixes both: the image always fills the
// entire band edge-to-edge (cropping whatever doesn't fit, never
// leaving empty space), and — because it now genuinely overflows the
// band on one axis — offsetDx/offsetDy panning and the pinch/slider
// zoom (spec.clampedScale, see background_render.dart's
// _imageScrimStack, which only applies scale when fit == BoxFit.cover)
// become real, visible controls. This also makes the header's actual
// render finally match the small thumbnail preview shown while editing
// in customise_background_section.dart, which already used
// BoxFit.cover — the two had drifted apart, which is why what you saw
// while picking an image never matched what the document actually
// produced.
Widget _fullBleedHeaderBackground({
  required DocTemplateAdapter a,
  required Widget content,
}) {
  final spec = BackgroundSpec.fromFields(
    imagePath: a.headerBackgroundImagePath,
    enabled: a.headerBackgroundEnabled,
    opacity: a.headerBackgroundOpacity,
    offsetDx: a.headerBackgroundOffsetDx,
    offsetDy: a.headerBackgroundOffsetDy,
    scale: a.headerBackgroundScale,
    // BANNER-SHAPE LOCK / COVER-FIT FIX: always fill the fixed
    // kPageW × kHeaderBackgroundBandHeight banner shape completely —
    // see the pass note above for why `contain` was the actual root
    // cause of both the gap and the broken left/right drag.
    fit: BoxFit.cover,
  );
  // HEIGHT-CAP FIX: a background band should have its own sensible
  // fixed cap (kHeaderBackgroundBandHeight), independent of whatever
  // the identity content currently measures — see that constant's own
  // doc comment for why.
  //
  // TOP-BLEED FIX: bleedLeft/Right/Top now ALL reach the true page edge
  // — bleedTop uses kHeaderBackgroundBleedTop (= kPagePadV, the page's
  // real top inset), the same treatment left/right already had via
  // kPagePadH. See kHeaderBackgroundBandHeight's doc comment for why
  // the total height grew alongside this, to keep the band's bottom
  // edge exactly where it was before.
  return renderDocumentBackground(
    spec: spec,
    child: content,
    bleedLeft: kPagePadH,
    bleedRight: kPagePadH,
    bleedTop: kHeaderBackgroundBleedTop,
    height: kHeaderBackgroundBandHeight,
  );
}

// PAN + PINCH HEADER LOGO PASS (earlier): _executiveFullHeader accepts
// onFreeformLogoScaleChanged, forwarded straight into
// buildSharedHeaderIdentity() alongside the existing offset callback.
// Leaving all three drag/pinch callbacks null (every call site that
// doesn't pass them) renders exactly as before — PDF export and the
// static Full Preview screen are untouched.
//
// FREEFORM HEADER LOGO DRAG PASS (earlier): _executiveFullHeader accepts
// the two drag callbacks and forwards them into buildSharedHeaderIdentity().
//
// The continuation header (_executiveContinuationHeader below) is
// deliberately NOT wrapped/wired for drag, pinch, or a background — it's
// a thin one-line running header repeated on every overflow page, not
// the main header band.
Widget _executiveFullHeader(
  DocTemplateAdapter a, {
  DocEditBundle? edit,
  ValueChanged<Offset>? onFreeformLogoOffsetChanged,
  ValueChanged<double>? onFreeformLogoScaleChanged,
  VoidCallback? onFreeformLogoDragEnd,
}) {
  final identity = buildSharedHeaderIdentity(
    a: a,
    edit: edit,
    onFreeformLogoOffsetChanged: onFreeformLogoOffsetChanged,
    onFreeformLogoScaleChanged: onFreeformLogoScaleChanged,
    onFreeformLogoDragEnd: onFreeformLogoDragEnd,
  );

  // HEADER-BACKGROUND SCOPE FIX: only the identity block (logo +
  // doc-type/number) sits inside the optional background band now.
  final headerBand = a.headerBackgroundEnabled
      ? _fullBleedHeaderBackground(a: a, content: identity)
      : identity;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      headerBand,
      const SizedBox(height: 28),
      Container(height: 1, color: kRule),
      const SizedBox(height: 24),
      buildSharedMetaRow(a: a, edit: edit),
    ],
  );
}

Widget _executiveContinuationHeader(DocTemplateAdapter a, {DocEditBundle? edit}) {
  final showDocNumber = docFieldOn(a, 'invoiceNumber');
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(a.businessName.isEmpty ? 'Your Business' : a.businessName,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kGrey, fontFamily: a.fontFamily)),
      Flexible(
        child: Text(
            showDocNumber
                ? '${a.docTypeLabel} #${a.docNumber.isEmpty ? '—' : a.docNumber} ${a.continuationSuffix}'
                : '${a.docTypeLabel} ${a.continuationSuffix}',
            style: TextStyle(fontSize: 9.5, color: kGreyLight, fontFamily: a.fontFamily),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

class ExecutiveInvoicePreview extends StatelessWidget {
  final InvoiceData data;
  final void Function(int pageCount)? onPageCount;
  final ValueChanged<Offset>? onFreeformLogoOffsetChanged;
  final ValueChanged<double>? onFreeformLogoScaleChanged;
  final VoidCallback? onFreeformLogoDragEnd;
  const ExecutiveInvoicePreview({
    super.key,
    required this.data,
    this.onPageCount,
    this.onFreeformLogoOffsetChanged,
    this.onFreeformLogoScaleChanged,
    this.onFreeformLogoDragEnd,
  });

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(
          a,
          onFreeformLogoOffsetChanged: onFreeformLogoOffsetChanged,
          onFreeformLogoScaleChanged: onFreeformLogoScaleChanged,
          onFreeformLogoDragEnd: onFreeformLogoDragEnd,
        ),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

class ExecutiveQuotePreview extends StatelessWidget {
  final QuoteData data;
  final void Function(int pageCount)? onPageCount;
  final ValueChanged<Offset>? onFreeformLogoOffsetChanged;
  final ValueChanged<double>? onFreeformLogoScaleChanged;
  final VoidCallback? onFreeformLogoDragEnd;
  const ExecutiveQuotePreview({
    super.key,
    required this.data,
    this.onPageCount,
    this.onFreeformLogoOffsetChanged,
    this.onFreeformLogoScaleChanged,
    this.onFreeformLogoDragEnd,
  });

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(
          a,
          onFreeformLogoOffsetChanged: onFreeformLogoOffsetChanged,
          onFreeformLogoScaleChanged: onFreeformLogoScaleChanged,
          onFreeformLogoDragEnd: onFreeformLogoDragEnd,
        ),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

class ExecutiveReceiptPreview extends StatelessWidget {
  final ReceiptData data;
  final void Function(int pageCount)? onPageCount;
  final ValueChanged<Offset>? onFreeformLogoOffsetChanged;
  final ValueChanged<double>? onFreeformLogoScaleChanged;
  final VoidCallback? onFreeformLogoDragEnd;
  const ExecutiveReceiptPreview({
    super.key,
    required this.data,
    this.onPageCount,
    this.onFreeformLogoOffsetChanged,
    this.onFreeformLogoScaleChanged,
    this.onFreeformLogoDragEnd,
  });

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(
          a,
          onFreeformLogoOffsetChanged: onFreeformLogoOffsetChanged,
          onFreeformLogoScaleChanged: onFreeformLogoScaleChanged,
          onFreeformLogoDragEnd: onFreeformLogoDragEnd,
        ),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
      );
}

class ExecutiveInvoiceEditor extends StatelessWidget {
  final InvoiceData data;
  final DocEditBundle edit;
  final void Function(int pageCount)? onPageCount;
  final ValueChanged<Offset>? onFreeformLogoOffsetChanged;
  final ValueChanged<double>? onFreeformLogoScaleChanged;
  final VoidCallback? onFreeformLogoDragEnd;
  const ExecutiveInvoiceEditor({
    super.key,
    required this.data,
    required this.edit,
    this.onPageCount,
    this.onFreeformLogoOffsetChanged,
    this.onFreeformLogoScaleChanged,
    this.onFreeformLogoDragEnd,
  });

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: invoiceToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(
          a,
          edit: edit,
          onFreeformLogoOffsetChanged: onFreeformLogoOffsetChanged,
          onFreeformLogoScaleChanged: onFreeformLogoScaleChanged,
          onFreeformLogoDragEnd: onFreeformLogoDragEnd,
        ),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a, edit: edit),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
        edit: edit,
      );
}

class ExecutiveQuoteEditor extends StatelessWidget {
  final QuoteData data;
  final DocEditBundle edit;
  final void Function(int pageCount)? onPageCount;
  final ValueChanged<Offset>? onFreeformLogoOffsetChanged;
  final ValueChanged<double>? onFreeformLogoScaleChanged;
  final VoidCallback? onFreeformLogoDragEnd;
  const ExecutiveQuoteEditor({
    super.key,
    required this.data,
    required this.edit,
    this.onPageCount,
    this.onFreeformLogoOffsetChanged,
    this.onFreeformLogoScaleChanged,
    this.onFreeformLogoDragEnd,
  });

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: quoteToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(
          a,
          edit: edit,
          onFreeformLogoOffsetChanged: onFreeformLogoOffsetChanged,
          onFreeformLogoScaleChanged: onFreeformLogoScaleChanged,
          onFreeformLogoDragEnd: onFreeformLogoDragEnd,
        ),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a, edit: edit),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
        edit: edit,
      );
}

class ExecutiveReceiptEditor extends StatelessWidget {
  final ReceiptData data;
  final DocEditBundle edit;
  final void Function(int pageCount)? onPageCount;
  final ValueChanged<Offset>? onFreeformLogoOffsetChanged;
  final ValueChanged<double>? onFreeformLogoScaleChanged;
  final VoidCallback? onFreeformLogoDragEnd;
  const ExecutiveReceiptEditor({
    super.key,
    required this.data,
    required this.edit,
    this.onPageCount,
    this.onFreeformLogoOffsetChanged,
    this.onFreeformLogoScaleChanged,
    this.onFreeformLogoDragEnd,
  });

  @override
  Widget build(BuildContext context) => TemplateDocument(
        adapter: receiptToAdapter(data),
        buildFullHeader: (a) => _executiveFullHeader(
          a,
          edit: edit,
          onFreeformLogoOffsetChanged: onFreeformLogoOffsetChanged,
          onFreeformLogoScaleChanged: onFreeformLogoScaleChanged,
          onFreeformLogoDragEnd: onFreeformLogoDragEnd,
        ),
        buildContinuationHeader: (a) => _executiveContinuationHeader(a, edit: edit),
        buildLineItemsHeaderRow: (a) => buildSharedLineItemsHeaderRow(adapter: a),
        onPageCount: onPageCount,
        edit: edit,
      );
}