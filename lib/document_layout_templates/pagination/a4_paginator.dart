// lib/document_layout_templates/pagination/a4_paginator.dart
//
// Generic, model-agnostic A4 pagination engine shared across invoice,
// quote, and receipt templates. Given a list of "item" widgets (one per
// line-item row), a header builder, and a footer builder, this measures
// REAL rendered heights (not estimates) and splits items across as many
// fixed-size A4 pages as needed — never scaling text down to force a fit.
// This matches how invoice_pdf_service.dart's pw.MultiPage already
// paginates the exported PDF; previously the on-screen preview
// (executive_invoice_logic_data.dart) instead shrank content to fit one page,
// which is what this replaces.
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
// MATERIAL-ANCESTRY MEASUREMENT FIX (this update): the offstage probe
// subtree used to measure header/footer/item heights was a bare
// Offstage->Column with no Material ancestor, while the real, painted
// page (_buildPage) wraps its identical content in a Material widget.
// Material injects its own DefaultTextStyle for its subtree (derived
// from the ambient Theme's typography) — any Text widget here that
// doesn't set every style property explicitly (line height, letter
// spacing, etc. — several labels/rows in the footer panels don't) merges
// with whichever DefaultTextStyle it inherits. Measuring that text
// WITHOUT a Material ancestor and then painting it WITH one meant the
// probe could compute a slightly shorter height (often well under a
// pixel per line) than what actually rendered — invisible on a short
// footer, but compounding into a double-digit-pixel discrepancy once a
// footer had many lines (Payment Details rows, per-name discount/tax
// breakdown rows, Terms panel, signature block). That's what produced
// the "RenderFlex overflowed by 22 pixels" bug: A4Paginator's own
// packing math was — and still is — internally consistent (see the
// SINGLE-PASS FOOTER FIX note below), but it was trusting a footer
// height measurement that didn't match reality.
//
// Fixed by wrapping the offstage probe subtree in a Material ancestor
// identical in kind to the one _buildPage uses (color/elevation don't
// affect layout size and are irrelevant here since the probe never
// paints), so both the probe and the real page compute every Text
// widget's merged style — and therefore its height — under the exact
// same DefaultTextStyle. No other file in this pagination/template
// chain needed to change: the mismatch was purely a measurement-context
// bug local to this widget.
//
// SINGLE-PASS FOOTER FIX (earlier): the previous fix packed items
// tightly first, then — if the footer didn't fit after the last item —
// RE-PACKED with the footer's full height reserved against that one
// item. That reserve was the bug: on a page with a tall footer (Payment
// Details + Terms + Signature all filled in, for example), "item height
// + footer reserve" could fail to fit even though the item alone had
// plenty of room, so the item got flushed to a fresh page it didn't
// need — leaving a large dead gap under the last item that DID fit, on
// the page it was already on. Items were still moving because of the
// footer, which is exactly what this pagination engine is meant to
// avoid.
//
// Fixed by dropping the reserve/re-pack entirely: items are packed in a
// single tight pass with zero footer awareness, full stop — nothing
// about where an item lands is ever influenced by the footer. AFTER
// that's settled, this checks once whether the footer fits directly
// under the last item on the page it actually landed on. If it doesn't,
// the footer gets an extra page of its own (with a light continuation
// header and no items) — every item stays exactly where it naturally
// packed, whether or not that page also happens to hold the footer.
//
// FOOTER-GAP FIX (earlier): the items block used to be wrapped in an
// Expanded, so any vertical space left over on a page (after the header,
// items, and — on the last page — the footer's own height) collected
// BETWEEN the last item and the footer, pushing the footer down to the
// page's true bottom margin. On a short page (e.g. a one- or two-item
// invoice) that put a large, visually odd gap between the last line item
// and the totals block instead of the totals sitting directly under it.
// The Expanded is gone — items and (on the last page) the footer now
// simply stack in document order, so the footer always sits immediately
// after the last item row. Any leftover vertical space on a short page
// now falls after the footer, at the true bottom of the page card, which
// is the normal/expected look for a document page (blank space at the
// bottom, not floating totals). Pages that pack tightly or overflow to a
// new page are unaffected either way.

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
  });

  @override
  State<A4Paginator> createState() => _A4PaginatorState();
}

class _A4PaginatorState extends State<A4Paginator> {
  late List<GlobalKey> _itemKeys;
  final GlobalKey _fullHeaderKey = GlobalKey();
  final GlobalKey _contHeaderKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();

  List<List<Widget>>? _pages;
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
    final itemHeights = _itemKeys.map(_heightOf).toList();

    if (fullHeaderH == null ||
        contHeaderH == null ||
        footerH == null ||
        itemHeights.any((h) => h == null)) {
      if (_measurePass++ < _kMaxPasses) {
        SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
      }
      return;
    }

    final pages = _paginate(
      itemHeights: itemHeights.cast<double>(),
      fullHeaderH: fullHeaderH,
      contHeaderH: contHeaderH,
      footerH: footerH,
    );

    if (!mounted) return;
    setState(() => _pages = pages);
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
  List<List<Widget>> _paginate({
    required List<double> itemHeights,
    required double fullHeaderH,
    required double contHeaderH,
    required double footerH,
  }) {
    final availH = widget.pageHeight - widget.pagePadding.vertical;

    // ── Pass 1: pack items tightly. Zero footer awareness — nothing
    // here ever changes based on what the footer needs. ──────────────
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
      final limit = availH - header - widget.headerGap;

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
    // it; nothing is moved to make room. ──────────────────────────────
    final lastPageHeader = pages.length == 1 ? fullHeaderH : contHeaderH;
    final lastPageUsed = pages.last.isEmpty
        ? 0.0
        : pages.last.fold<double>(0.0, (sum, idx) => sum + itemHeights[idx]) +
            widget.itemGap * (pages.last.length - 1);
    final lastPageLimit = availH - lastPageHeader - widget.headerGap;

    if (lastPageUsed + widget.footerGap + footerH > lastPageLimit) {
      pages.add(<int>[]);
    }

    return pages
        .map((idxList) => idxList.map((i) => widget.items[i]).toList())
        .toList();
  }

  Widget _buildPage(int pageIndex, int pageCount, List<Widget> items) {
    return SizedBox(
      width: widget.pageWidth,
      height: widget.pageHeight,
      child: Material(
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: widget.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.headerBuilder(pageIndex, pageCount),
              SizedBox(height: widget.headerGap),
              // FOOTER-GAP FIX: plain (non-Expanded) Column. Items lay out
              // at their natural height directly below the header, and —
              // on the last page — the footer follows immediately after
              // the last item, separated only by footerGap. Any leftover
              // vertical space on a short page now falls after the
              // footer, at the true bottom of the fixed-height page card,
              // instead of being inserted between the items and the
              // footer.
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Off-stage probes: laid out (so keys resolve to real RenderBoxes) but
    // not painted/hit-tested — pure measurement, zero visual footprint.
    //
    // MATERIAL-ANCESTRY MEASUREMENT FIX: wrapped in a Material ancestor
    // matching what _buildPage's real page uses — see the note at the
    // top of this file. color/elevation are irrelevant here (Offstage
    // never paints) and are set only so this mirrors _buildPage exactly;
    // what actually matters is that both subtrees resolve the same
    // DefaultTextStyle for every Text widget they measure/paint.
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
    final pageWidgets = pages == null
        ? [_buildPage(0, 1, const [])] // first frame — nothing measured yet
        : [
            for (int p = 0; p < pages.length; p++)
              _buildPage(p, pages.length, pages[p])
          ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        probes,
        for (int i = 0; i < pageWidgets.length; i++) ...[
          if (i > 0) SizedBox(height: widget.pageGap),
          pageWidgets[i],
        ],
      ],
    );
  }
}
