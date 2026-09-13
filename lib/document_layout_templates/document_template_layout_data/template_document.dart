// template_document.dart
// lib/document_layout_templates/document_template_layout_data/template_document.dart
//
// ITEMS-HEADER-ROW PASS (this update): the "DESCRIPTION | QTY | UNIT
// PRICE ..." column-header row used to be baked into the TAIL of every
// template's buildFullHeader/buildContinuationHeader functions, which
// meant it rendered unconditionally on every page — including a
// totals-only overflow page with zero line items on it (see
// a4_paginator.dart's header comment for the full bug this caused: a
// floating column-header row above nothing). Fixed by adding a new
// optional param here, `buildLineItemsHeaderRow`, threaded straight
// into A4Paginator's new `itemsHeaderRowBuilder` slot — the engine now
// owns showing/hiding this row per page based on whether that page
// actually has items, instead of every template deciding it blindly.
// Each of the 10 template designs now supplies its own row builder
// (shared default, or a custom one for the templates that style this
// row differently) via this param instead of calling it inline inside
// their own header functions.
//
// FIX (carried over from the merge pass): HeaderBuilder/
// LineItemRowBuilder/TotalsSectionBuilder are plain
// Widget Function(DocTemplateAdapter) / no-edit-param shapes — this is
// deliberate. All 9 non-Executive template designs (Nordic through
// Emerald) implement these typedefs with this exact shape, and Dart's
// function-type subtyping requires an implementing function to declare
// every named parameter the typedef declares. Executive is the only
// design that needs edit-mode, and it gets it via a closure built in
// executive_template.dart (which captures its own `edit` field and
// calls its real, edit-aware private header helper) — not by widening
// the type every template must match. buildLineItemsHeaderRow follows
// the same plain shape; the row itself never needs edit-mode (it's pure
// column labels, nothing tappable), so no template needs an edit-aware
// variant of it.

import 'package:flutter/material.dart';
import 'doc_template_adapter.dart';
import 'doc_edit_bundle.dart';
import 'doc_header.dart' show kPageW, kPageH, kPagePadH, kPagePadV, kContentW;
import 'doc_line_items.dart' show buildSharedLineItemRow, buildSharedLineItemsHeaderRow;
import 'doc_totals.dart' show buildSharedTotalsAndNotesSection, buildSharedThankYouFooter;
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

/// `edit` is the one constructor param that makes this widget do double
/// duty as both Preview (edit: null, unchanged behavior) and Editor
/// (edit: non-null) — replacing the need for separate
/// ExecutiveXPreview/ExecutiveXEditor implementations per doc type. See
/// executive_template.dart's ExecutiveInvoiceEditor etc for the thin
/// wrappers that pass `edit` through.
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
  });

  @override
  Widget build(BuildContext context) {
    // `edit` is passed directly to the shared DEFAULT builders
    // (buildSharedLineItemRow / buildSharedTotalsAndNotesSection) as an
    // ordinary parameter — that's fine, those aren't typedef-constrained.
    // It is NOT passed to a caller-supplied buildLineItemRow!/
    // buildTotalsSection! override, since those must match the plain
    // (no-edit) typedefs every template implements.
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
      // buildFullHeader/buildContinuationHeader are plain
      // Widget Function(DocTemplateAdapter) — edit-awareness for
      // Executive's header lives entirely in the closures
      // executive_template.dart passes in as buildFullHeader/
      // buildContinuationHeader, not in an extra parameter here.
      headerBuilder: (pageIndex, pageCount) =>
          pageIndex == 0 ? buildFullHeader(adapter) : buildContinuationHeader(adapter),
      footerBuilder: (pageIndex, pageCount) => pageIndex == pageCount - 1
          ? (buildFooterContent != null ? buildFooterContent!(adapter) : buildSharedThankYouFooter(adapter))
          : const SizedBox.shrink(),
      // ITEMS-HEADER-ROW PASS: falls back to the plain shared row when a
      // template doesn't supply its own styled version. A4Paginator
      // itself decides, per page, whether to actually show this — see
      // its header comment.
      itemsHeaderRowBuilder: () => (buildLineItemsHeaderRow ??
          (DocTemplateAdapter a) => buildSharedLineItemsHeaderRow(adapter: a))(adapter),
      // REAL-ITEM DETECTION FIX: `items` above always ends with exactly
      // one non-real entry — the totals/payment/terms/signature block
      // built a few lines up. Telling A4Paginator this is what lets it
      // tell "this page has a real line item" apart from "this page
      // happens to hold only that trailing totals block, landed here by
      // the normal packing loop because it didn't fit after the last
      // real item" — without this, a totals-only page would still show
      // the items-header-row above it, which is the exact bug this pass
      // fixes. See a4_paginator.dart's footerItemCount doc comment.
      footerItemCount: 1,
      // TEXT-SIZE WIRING FIX: turns adapter.fontSize (a raw pt value from
      // the "Text Size" slider, range 10–16, default 12) into a
      // multiplier relative to that 12pt baseline. A4Paginator applies
      // this uniformly via MediaQuery's textScaler, so every hardcoded
      // fontSize across every template scales together without any of
      // them needing to reference this value directly.
      textScale: adapter.fontSize / 12.0,
    );
  }
}
