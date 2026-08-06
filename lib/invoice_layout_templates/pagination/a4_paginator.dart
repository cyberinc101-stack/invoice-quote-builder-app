// lib/invoice_layout_templates/pagination/a4_paginator.dart
//
// Generic, model-agnostic A4 pagination engine shared across invoice,
// quote, and receipt templates. Given a list of "item" widgets (one per
// line-item row), a header builder, and a footer builder, this measures
// REAL rendered heights (not estimates) and splits items across as many
// fixed-size A4 pages as needed — never scaling text down to force a fit.
// This matches how invoice_pdf_service.dart's pw.MultiPage already
// paginates the exported PDF; previously the on-screen preview
// (executive_cv_logic_data.dart) instead shrank content to fit one page,
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

  /// Greedy packing, then a single backtrack pass so the footer always
  /// ends up on the real last page — never shrinks anything, only moves
  /// items to a fresh page when they don't fit.
  List<List<Widget>> _paginate({
    required List<double> itemHeights,
    required double fullHeaderH,
    required double contHeaderH,
    required double footerH,
  }) {
    final availH = widget.pageHeight - widget.pagePadding.vertical;

    List<List<int>> pack({required bool reserveFooterOnLastItem}) {
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
        final isLastItem = i == itemHeights.length - 1;
        final reserve = (reserveFooterOnLastItem && isLastItem)
            ? (widget.footerGap + footerH)
            : 0.0;
        final limit = availH - header - widget.headerGap - reserve;

        if (used + h > limit && current.isNotEmpty) {
          flush();
          isFirstPage = false;
        }
        current.add(i);
        used += h;
      }
      flush();
      if (pages.isEmpty) pages.add([]);
      return pages;
    }

    var pages = pack(reserveFooterOnLastItem: false);

    final lastPageHeader = pages.length == 1 ? fullHeaderH : contHeaderH;
    final lastPageUsed = pages.last.isEmpty
        ? 0.0
        : pages.last.fold<double>(0.0, (sum, idx) => sum + itemHeights[idx]) +
            widget.itemGap * (pages.last.length - 1);
    final lastPageLimit = availH - lastPageHeader - widget.headerGap;

    if (lastPageUsed + widget.footerGap + footerH > lastPageLimit) {
      pages = pack(reserveFooterOnLastItem: true);
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
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.headerBuilder(pageIndex, pageCount),
              SizedBox(height: widget.headerGap),
              ...items,
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
    final probes = Offstage(
      offstage: true,
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
