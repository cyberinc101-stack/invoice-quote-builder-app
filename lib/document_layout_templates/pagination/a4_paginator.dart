// lib/document_layout_templates/pagination/a4_paginator.dart
//
// Generic, model-agnostic A4 pagination engine shared across invoice,
// quote, and receipt templates. Given a list of "item" widgets (one per
// line-item row), a header builder, and a footer builder, this measures
// REAL rendered heights (not estimates) and splits items across as many
// fixed-size A4 pages as needed — never scaling text down to force a fit.
//
// ITEMS-HEADER-ROW PASS (this update): every template used to bake its
// own "DESCRIPTION | QTY | UNIT PRICE ... " column-header row into the
// TAIL of its buildContinuationHeader function, which meant that row
// rendered unconditionally on every non-first page — including a page
// that ends up holding ONLY the totals/payment/terms/signature block
// (which happens whenever that block doesn't fit under the last item on
// its natural page and gets pushed to a page of its own; see the
// SINGLE-PASS FOOTER FIX note below for why that block moves as one
// atomic unit). The result: a floating column-header row with nothing
// underneath it before the totals started — which read as "the item
// table continues onto a new page, empty."
//
// Fixed by moving this row OUT of each template's header functions and
// INTO this engine as its own repeating slot (`itemsHeaderRowBuilder`),
// rendered directly under the main header — but ONLY on a page that
// actually has >=1 item. A totals-only page (zero items) now shows just
// its header and the totals block, with no orphaned column-header row.
// Every template's Preview/Editor class now passes its own row builder
// (shared default or a custom design) via TemplateDocument's new
// `buildLineItemsHeaderRow` param — see template_document.dart.
//
// Measurement: the row's height is probed via its own GlobalKey exactly
// like the header/footer/items. Pass 1's packing math reserves this
// height (plus `itemsHeaderRowGap`) on every candidate page, since pass
// 1 never produces a page with zero items (see _paginate). Pass 2's
// footer-only overflow page correctly reserves NOTHING for this row,
// since _buildPage only renders it when `items.isNotEmpty`.
//
// TEXT-SCALING PASS (this update): the whole widget tree (probes +
// pages) is now wrapped in a MediaQuery override forcing
// TextScaler.noScaling. These are fixed-size A4 pages built out of
// hand-tuned pixel font sizes — if a user's device accessibility
// text-size setting scaled that text up, rows would grow taller than
// what was measured and packed, breaking pagination and layout in
// unpredictable ways (overflow, clipped text, mis-packed pages). Since
// this is a print-style document rather than scrolling app UI, locking
// it to a 1.0 scale — independent of the user's device setting — is the
// standard fix and keeps the document looking identical everywhere.
//
// Header/footer convention:
//   headerBuilder(pageIndex, pageCount) — pageIndex 0 = first page. Treat
//     pageIndex > 0 as "continuation" (light header) regardless of the
//     exact pageCount value passed during measurement (a sentinel value
//     is used internally while the real count is still unknown).
//   footerBuilder(pageIndex, pageCount) — render your totals/notes block
//     only when pageIndex == pageCount - 1 (the last page); return
//     SizedBox.shrink() otherwise.
//
// Implementation notes carried over from earlier passes:
//   - Page numbers are rendered via a Stack + Positioned overlay in
//     _buildPage, NOT as another item in the content Column — it must
//     never participate in the header/items/footer flow or its own
//     height, so it can't shift _paginate()'s packing math or the
//     offstage probe measurements.
//   - MATERIAL-ANCESTRY MEASUREMENT FIX: the offstage probe subtree is
//     wrapped in a Material ancestor identical in kind to the one
//     _buildPage uses, so both resolve the same DefaultTextStyle for
//     every Text widget they measure/paint.
//   - SINGLE-PASS FOOTER FIX: items are packed in a single tight pass
//     with zero footer awareness — nothing about where an item lands is
//     ever influenced by the footer. AFTER that's settled, this checks
//     once whether the footer fits directly under the last item on the
//     page it actually landed on. If it doesn't, the footer gets an
//     extra page of its own (with a light continuation header, no
//     items, and — per this update — no items-header-row either) —
//     every item stays exactly where it naturally packed.
//   - FOOTER-GAP FIX: items and (on the last page) the footer stack in
//     document order with no Expanded between them, so the footer
//     always sits immediately after the last item row; leftover space
//     on a short page falls after the footer, not between it and the
//     items.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

typedef PageSectionBuilder = Widget Function(int pageIndex, int pageCount);

class A4Paginator extends StatefulWidget {
  final List<Widget> items;
  final PageSectionBuilder headerBuilder;
  final PageSectionBuilder footerBuilder;
  final double pageWidth;
  final double pageHeight;
  final double contentWidth;
  final EdgeInsets pagePadding;
  final void Function(int pageCount)? onPageCount;

  /// Gap inserted between the header and the first item, on every page.
  final double headerGap;
  /// Gap inserted between the last item and the footer, on the last page.
  final double footerGap;
  /// Vertical gap between consecutive item rows.
  final double itemGap;
  /// Vertical gap between page cards when stacked in the visible tree.
  final double pageGap;

  // PAGE NUMBER PASS: "Page X of Y" label pinned to the bottom-center of
  // every page. Shown only when there's more than one page unless
  // showPageNumbers is forced true. fontFamily lets the caller match the
  // document's own chosen font instead of the platform default.
  final bool showPageNumbers;
  final String? fontFamily;

  // TEXT-SIZE WIRING FIX: this is what actually makes the "Text Size"
  // slider in every customize screen affect the rendered document. See
  // doc_template_adapter.dart's fontSize field for where this value
  // originates, and template_document.dart for how it's turned from a
  // raw pt value into this multiplier. 1.0 = no change from each
  // template's own hand-tuned pixel sizes.
  final double textScale;

  // ITEMS-HEADER-ROW PASS: an optional page-repeating row rendered
  // directly under the main header (with itemsHeaderRowGap between the
  // two), but ONLY on a page that actually holds >=1 REAL item — see
  // footerItemCount below for what "real" excludes. Pass null to opt out
  // entirely (falls back to the old behavior of relying on the caller's
  // own header to show whatever column labels it wants, every page,
  // unconditionally).
  final Widget Function()? itemsHeaderRowBuilder;
  final double itemsHeaderRowGap;

  // REAL-ITEM DETECTION FIX (this update): `items` isn't always ALL real
  // line items — template_document.dart appends the totals/payment/
  // terms/signature block as the LAST entry of this same array (it has
  // to be, so it packs in document order with everything else). That
  // trailing entry is just as capable as any line item of landing alone
  // on its own page when it doesn't fit after the last real item — and
  // when it does, that page's item list is non-empty, which the
  // ITEMS-HEADER-ROW PASS's `items.isNotEmpty` check alone can't tell
  // apart from a page that has a genuine line item on it. footerItemCount
  // tells this engine how many trailing entries to exclude when deciding
  // "does this page have a REAL item" (for the header row) — it has zero
  // effect on packing/measurement, which still treats every entry
  // identically by height, only on this one rendering decision.
  final int footerItemCount;

  const A4Paginator({
    super.key,
    required this.items,
    required this.headerBuilder,
    required this.footerBuilder,
    required this.pageWidth,
    required this.pageHeight,
    required this.contentWidth,
    required this.pagePadding,
    this.onPageCount,
    this.headerGap = 20,
    this.footerGap = 20,
    this.itemGap = 0,
    this.pageGap = 24,
    this.showPageNumbers = true,
    this.fontFamily,
    this.itemsHeaderRowBuilder,
    this.itemsHeaderRowGap = 20,
    this.footerItemCount = 0,
    this.textScale = 1.0,
  });

  @override
  State<A4Paginator> createState() => _A4PaginatorState();
}

class _A4PaginatorState extends State<A4Paginator> {
  late List<GlobalKey> _itemKeys;
  final GlobalKey _fullHeaderKey = GlobalKey();
  final GlobalKey _contHeaderKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();
  final GlobalKey _itemsHeaderRowKey = GlobalKey();

  List<List<Widget>>? _pages;
  // REAL-ITEM DETECTION FIX: parallel to _pages — pages[p].isNotEmpty
  // just means "has SOMETHING" (which could be only the trailing
  // totals-block pseudo-item); this tracks "has >=1 REAL line item",
  // which is what actually decides whether the items-header-row shows.
  List<bool>? _pageHasRealItem;
  int _measurePass = 0;
  static const _kMaxPasses = 8;

  // Sentinel pageCount passed to the builders while probing header/footer
  // height — real content shouldn't format text differently based on this
  // (e.g. avoid "page 1 of 999" — use "continued" instead, see convention
  // note at the top of this file).
  static const int _kProbePageCount = 999;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(A4Paginator old) {
    super.didUpdateWidget(old);
    // Always remeasure on any rebuild with new item widgets — text edits
    // can change wrap height even when the item count is unchanged, so
    // there's no cheap short-circuit that's actually safe here.
    _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());
    _pages = null;
    _pageHasRealItem = null;
    _measurePass = 0;
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
  }

  double? _heightOf(GlobalKey key) {
    final rb = key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null || !rb.hasSize) return null;
    return rb.size.height;
  }

  void _measure() {
    if (!mounted) return;

    final fullHeaderH = _heightOf(_fullHeaderKey);
    final contHeaderH = _heightOf(_contHeaderKey);
    final footerH = _heightOf(_footerKey);
    final itemsHeaderRowH =
        widget.itemsHeaderRowBuilder == null ? 0.0 : _heightOf(_itemsHeaderRowKey);
    final itemHeights = _itemKeys.map(_heightOf).toList();

    if (fullHeaderH == null ||
        contHeaderH == null ||
        footerH == null ||
        itemsHeaderRowH == null ||
        itemHeights.any((h) => h == null)) {
      if (_measurePass++ < _kMaxPasses) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
      }
      return;
    }

    final (pageIndexLists, pages) = _paginate(
      itemHeights: itemHeights.cast<double>(),
      fullHeaderH: fullHeaderH,
      contHeaderH: contHeaderH,
      footerH: footerH,
      itemsHeaderRowH: itemsHeaderRowH,
    );

    // REAL-ITEM DETECTION FIX: a page "has a real item" only if at least
    // one of its item indices falls before the trailing footerItemCount
    // entries of widget.items — the totals-block pseudo-item(s) at the
    // end don't count, no matter which pass (tight-pack or the
    // footer-overflow pass) put them on a page by themselves.
    final realItemBoundary = widget.items.length - widget.footerItemCount;
    final hasRealItem = pageIndexLists
        .map((idxList) => idxList.any((i) => i < realItemBoundary))
        .toList();

    if (!mounted) return;
    setState(() {
      _pages = pages;
      _pageHasRealItem = hasRealItem;
    });
    widget.onPageCount?.call(pages.length);
  }

  /// Single tight pack, then a single check — never a re-pack. See the
  /// SINGLE-PASS FOOTER FIX note at the top of this file for why the old
  /// two-pass/reserve approach is gone: reserving the footer's height
  /// against the last item could bump that item to a fresh page even
  /// when it had plenty of room on the current one, leaving a dead gap
  /// behind. Items here are placed once and never move for the footer's
  /// sake — the footer either fits where the last item landed, or it
  /// gets a page of its own.
  (List<List<int>>, List<List<Widget>>) _paginate({
    required List<double> itemHeights,
    required double fullHeaderH,
    required double contHeaderH,
    required double footerH,
    required double itemsHeaderRowH,
  }) {
    final availH = widget.pageHeight - widget.pagePadding.vertical;
    final rowReserve = widget.itemsHeaderRowBuilder == null
        ? 0.0
        : itemsHeaderRowH + widget.itemsHeaderRowGap;

    // ── Pass 1: pack items tightly. Zero footer awareness — nothing
    // here ever changes based on what the footer needs. Every page this
    // loop produces holds >=1 item, so it always reserves rowReserve —
    // the items-header-row is only ever OMITTED on the zero-item footer
    // page pass 2 may add below. ──────────────────────────────────────
    final pages = <List<int>>[];
    var current = <int>[];
    var used = 0.0;
    var isFirstPage = true;

    void flush() {
      if (current.isNotEmpty) pages.add(current);
      current = [];
      used = 0.0;
    }

    for (int i = 0; i < itemHeights.length; i++) {
      final gap = current.isEmpty ? 0.0 : widget.itemGap;
      final h = itemHeights[i] + gap;
      final header = isFirstPage ? fullHeaderH : contHeaderH;
      final limit = availH - header - widget.headerGap - rowReserve;

      if (used + h > limit && current.isNotEmpty) {
        flush();
        isFirstPage = false;
      }
      current.add(i);
      used += h;
    }
    flush();
    if (pages.isEmpty) pages.add([]);

    // ── Pass 2: does the footer fit directly under the last item, on
    // the page it actually landed on above? If not, the footer gets an
    // extra page to itself — every item stays exactly where pass 1 put
    // it; nothing is moved to make room. That extra page holds ZERO
    // items, so _buildPage will correctly skip the items-header-row on
    // it (no floating column labels above a bare totals block). ───────
    final lastPageHeader = pages.length == 1 ? fullHeaderH : contHeaderH;
    // REAL-ITEM DETECTION FIX: gate the row reservation on a REAL item
    // being present, not just any item — pages.last could already be the
    // totals-only page here if pass 1's own tight-pack loop is what
    // pushed the totals block onto a fresh page (a footerItemCount of 0
    // — the default — makes this identical to the old isNotEmpty check).
    final realItemBoundary = widget.items.length - widget.footerItemCount;
    final lastPageHasRealItem = pages.last.any((i) => i < realItemBoundary);
    final lastPageUsed = pages.last.isEmpty
        ? 0.0
        : pages.last.fold<double>(0.0, (sum, idx) => sum + itemHeights[idx]) +
            widget.itemGap * (pages.last.length - 1);
    final lastPageRowReserve = lastPageHasRealItem ? rowReserve : 0.0;
    final lastPageLimit = availH - lastPageHeader - widget.headerGap - lastPageRowReserve;

    if (lastPageUsed + widget.footerGap + footerH > lastPageLimit) {
      pages.add(<int>[]);
    }

    final widgetPages = pages
        .map((idxList) => idxList.map((i) => widget.items[i]).toList())
        .toList();
    return (pages, widgetPages);
  }

  Widget _buildPage(int pageIndex, int pageCount, List<Widget> items, {required bool hasRealItems}) {
    // PAGE NUMBER PASS: rendered as a Stack overlay, NOT as part of the
    // header/items/footer Column — it must have zero effect on
    // _paginate()'s packing math or on the offstage probe's measured
    // heights.
    final showNumber = widget.showPageNumbers && pageCount > 1;
    // ITEMS-HEADER-ROW PASS + REAL-ITEM DETECTION FIX: gated on
    // hasRealItems, NOT items.isNotEmpty — a page can be non-empty while
    // holding only the trailing totals-block pseudo-item(s), which must
    // NOT trigger the column-header row. See footerItemCount's doc
    // comment above for why items.isNotEmpty alone can't tell these
    // apart.
    final showItemsHeaderRow = widget.itemsHeaderRowBuilder != null && hasRealItems;

    return SizedBox(
      width: widget.pageWidth,
      height: widget.pageHeight,
      child: Material(
        color: Colors.white,
        elevation: 2,
        child: Stack(
          children: [
            Padding(
              padding: widget.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.headerBuilder(pageIndex, pageCount),
                  SizedBox(height: widget.headerGap),
                  if (showItemsHeaderRow) ...[
                    widget.itemsHeaderRowBuilder!(),
                    SizedBox(height: widget.itemsHeaderRowGap),
                  ],
                  // FOOTER-GAP FIX: plain (non-Expanded) Column. Items lay out
                  // at their natural height directly below the header, and —
                  // on the last page — the footer follows immediately after
                  // the last item, separated only by footerGap.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items,
                  ),
                  if (pageIndex == pageCount - 1) ...[
                    SizedBox(height: widget.footerGap),
                    widget.footerBuilder(pageIndex, pageCount),
                  ],
                ],
              ),
            ),
            if (showNumber)
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Center(
                  child: Text(
                    'Page ${pageIndex + 1} of $pageCount',
                    style: TextStyle(
                      fontSize: 8.5,
                      color: const Color(0xFF9CA3AF),
                      fontFamily: widget.fontFamily,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Off-stage probes: laid out (so keys resolve to real RenderBoxes) but
    // not painted/hit-tested — pure measurement, zero visual footprint.
    //
    // MATERIAL-ANCESTRY MEASUREMENT FIX: wrapped in a Material ancestor
    // matching what _buildPage's real page uses.
    //
    // ITEMS-HEADER-ROW PASS: probed here too (unconditionally, even
    // though it's conditionally rendered per real page) so its height is
    // always known before the first _paginate() call.
    final probes = Offstage(
      offstage: true,
      child: Material(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: _fullHeaderKey,
              width: widget.contentWidth,
              child: widget.headerBuilder(0, _kProbePageCount),
            ),
            SizedBox(
              key: _contHeaderKey,
              width: widget.contentWidth,
              child: widget.headerBuilder(1, _kProbePageCount),
            ),
            SizedBox(
              key: _footerKey,
              width: widget.contentWidth,
              child: widget.footerBuilder(0, 1),
            ),
            if (widget.itemsHeaderRowBuilder != null)
              SizedBox(
                key: _itemsHeaderRowKey,
                width: widget.contentWidth,
                child: widget.itemsHeaderRowBuilder!(),
              ),
            for (int i = 0; i < widget.items.length; i++)
              SizedBox(
                key: _itemKeys[i],
                width: widget.contentWidth,
                child: widget.items[i],
              ),
          ],
        ),
      ),
    );

    final pages = _pages;
    final hasRealItemFlags = _pageHasRealItem;
    final pageWidgets = pages == null
        // First frame — nothing measured yet. hasRealItems: true here is
        // a harmless default (this placeholder page never actually
        // shows the header row in practice, since it has zero items to
        // render anyway) rather than a real determination.
        ? [_buildPage(0, 1, const [], hasRealItems: true)]
        : [
            for (int p = 0; p < pages.length; p++)
              _buildPage(p, pages.length, pages[p], hasRealItems: hasRealItemFlags?[p] ?? true)
          ];

    // TEXT-SCALING PASS: text scale is locked to widget.textScale rather
    // than the device's own accessibility setting — same protection as
    // before (a user's system font-size setting can't grow rows past
    // what was measured/packed here and break pagination), but now
    // driven by the document's own "Text Size" slider value instead of
    // being pinned to a flat 1.0. See doc_template_adapter.dart's
    // fontSize field and template_document.dart for where this value
    // comes from.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(widget.textScale)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          probes,
          for (int i = 0; i < pageWidgets.length; i++) ...[
            if (i > 0) SizedBox(height: widget.pageGap),
            pageWidgets[i],
          ],
        ],
      ),
    );
  }
}
