import 'package:flutter/material.dart';
import 'doc_template_adapter.dart';
import 'doc_edit_bundle.dart';
import 'doc_header.dart' show kPageW, kPageH, kPagePadH, kPagePadV, kContentW;
import 'doc_line_items.dart' show buildSharedLineItemRow, buildSharedLineItemsHeaderRow;
import 'doc_totals.dart' show buildSharedTotalsAndNotesSection, buildSharedThankYouFooter;
import 'doc_footer.dart' show buildSharedFooterTaglines;
import '../document_backgrounds/background_spec.dart';
import '../document_backgrounds/background_render.dart';
import '../pagination/a4_paginator.dart';
import '../../models/invoice_data.dart' show LineItem;

typedef HeaderBuilder = Widget Function(DocTemplateAdapter adapter);

typedef LineItemRowBuilder = Widget Function({
  required LineItem item,
  required DocTemplateAdapter adapter,
  required String ff,
  required int index,
});
typedef TotalsSectionBuilder = Widget Function(DocTemplateAdapter adapter);
typedef FooterContentBuilder = Widget Function(DocTemplateAdapter adapter);
typedef LineItemsHeaderRowBuilder = Widget Function(DocTemplateAdapter adapter);

// STAGE A REWIRE (earlier): the whole footer block (thank-you text,
// divider, taglines row) now goes through the shared
// renderDocumentBackground()/BackgroundSpec module in
// document_backgrounds/ instead of doc_header.dart's old
// withOptionalBackgroundImage — the same function header and body now
// use, so a fix to bleed/opacity/scrim logic in one place reaches all
// three render sites instead of drifting apart again. Two real changes
// beyond just swapping the call:
//   1. FULL-BLEED: footer now bleeds to the true page edge (bleedLeft/
//      bleedRight: kPagePadH) instead of stopping at the footer
//      content's own horizontal bounds — matching header/body, which
//      also sit inside kPagePadH and are meant to look identical.
//   2. The padding-around-text condition now checks
//      spec.hasVisibleImage (enabled AND an actual image path) instead
//      of just a.footerBackgroundEnabled — so toggling the switch on
//      before picking an image no longer adds unwanted breathing room
//      around text with nothing behind it.
// When no footer background is set (the default for every existing
// document), renderDocumentBackground returns the Column completely
// untouched, so nothing here changes visually.
Widget _defaultFooterContent(DocTemplateAdapter a) {
  final content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      buildSharedThankYouFooter(a),
      buildSharedFooterTaglines(a),
    ],
  );

  final spec = BackgroundSpec.fromFields(
    imagePath: a.footerBackgroundImagePath,
    enabled: a.footerBackgroundEnabled,
    opacity: a.footerBackgroundOpacity,
    offsetDx: a.footerBackgroundOffsetDx,
    offsetDy: a.footerBackgroundOffsetDy,
    scale: a.footerBackgroundScale,
  );

  return renderDocumentBackground(
    spec: spec,
    bleedLeft: kPagePadH,
    bleedRight: kPagePadH,
    // A little breathing room around the text when an image is actually
    // showing, so the scrim reads as a deliberate band rather than text
    // sitting flush against the image's edge. No padding at all when
    // there's no background — matches the pre-existing layout exactly.
    child: spec.hasVisibleImage
        ? Padding(padding: const EdgeInsets.all(14), child: content)
        : content,
  );
}

class TemplateDocument extends StatelessWidget {
  final DocTemplateAdapter adapter;
  final HeaderBuilder buildFullHeader;
  final HeaderBuilder buildContinuationHeader;
  final void Function(int pageCount)? onPageCount;
  final DocEditBundle? edit;

  final LineItemRowBuilder? buildLineItemRow;
  final TotalsSectionBuilder? buildTotalsSection;
  final FooterContentBuilder? buildFooterContent;
  final LineItemsHeaderRowBuilder? buildLineItemsHeaderRow;

  // PER-PAGE BACKGROUND PASS: optional — when supplied, A4Paginator
  // calls this once per rendered page to get that page's own
  // whole-page background image (one continuous photo behind header +
  // meta row + items + footer, instead of the separately-clipped
  // header/body/footer zone backgrounds above). Left null by every
  // existing caller until the adapter actually exposes the
  // page-background fields (scope + per-page specs) needed to build
  // one — see page_background_spec.dart's resolvePageBackground for
  // the expected shape once those fields exist on DocTemplateAdapter.
  final PageBackgroundResolver? pageBackgroundResolver;

  const TemplateDocument({
    super.key,
    required this.adapter,
    required this.buildFullHeader,
    required this.buildContinuationHeader,
    this.onPageCount,
    this.edit,
    this.buildLineItemRow,
    this.buildTotalsSection,
    this.buildFooterContent,
    this.buildLineItemsHeaderRow,
    this.pageBackgroundResolver,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (final (index, item) in adapter.lineItems.indexed)
        buildLineItemRow != null
            ? buildLineItemRow!(item: item, adapter: adapter, ff: adapter.fontFamily, index: index)
            : buildSharedLineItemRow(item: item, adapter: adapter, ff: adapter.fontFamily, edit: edit, index: index),
      buildTotalsSection != null
          ? buildTotalsSection!(adapter)
          : buildSharedTotalsAndNotesSection(adapter, edit: edit),
    ];

    return A4Paginator(
      pageWidth: kPageW,
      pageHeight: kPageH,
      contentWidth: kContentW,
      pagePadding: const EdgeInsets.symmetric(horizontal: kPagePadH, vertical: kPagePadV),
      items: items,
      onPageCount: onPageCount,
      fontFamily: adapter.fontFamily,
      headerBuilder: (pageIndex, pageCount) =>
          pageIndex == 0 ? buildFullHeader(adapter) : buildContinuationHeader(adapter),
      footerBuilder: (pageIndex, pageCount) => pageIndex == pageCount - 1
          ? (buildFooterContent != null ? buildFooterContent!(adapter) : _defaultFooterContent(adapter))
          : const SizedBox.shrink(),
      itemsHeaderRowBuilder: () => (buildLineItemsHeaderRow ??
          (DocTemplateAdapter a) => buildSharedLineItemsHeaderRow(adapter: a))(adapter),
      footerItemCount: 1,
      textScale: adapter.fontSize / 12.0,
      // MID-PAGE BACKGROUND PASS: passes straight through to
      // A4Paginator's own bodyBackgroundImagePath/bodyBackgroundEnabled
      // — see that file for the render-side handling. Null/false by
      // default, so every document without one is unaffected.
      bodyBackgroundImagePath: adapter.bodyBackgroundImagePath,
      bodyBackgroundEnabled: adapter.bodyBackgroundEnabled,
      bodyBackgroundOpacity: adapter.bodyBackgroundOpacity,
      bodyBackgroundOffsetDx: adapter.bodyBackgroundOffsetDx,
      bodyBackgroundOffsetDy: adapter.bodyBackgroundOffsetDy,
      bodyBackgroundScale: adapter.bodyBackgroundScale,
      // PER-PAGE BACKGROUND PASS: straight pass-through — null until a
      // caller supplies one.
      pageBackgroundResolver: pageBackgroundResolver,
    );
  }
}
