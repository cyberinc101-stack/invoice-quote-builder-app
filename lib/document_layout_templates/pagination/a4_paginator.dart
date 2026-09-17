import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../document_backgrounds/background_spec.dart';
import '../document_backgrounds/background_render.dart';
import '../document_backgrounds/page_background_spec.dart';

typedef PageSectionBuilder = Widget Function(int pageIndex, int pageCount);

// PER-PAGE BACKGROUND PASS: resolves which whole-page background (if
// any) a given page should render, given the total page count. Callers
// build this from PageBackgroundScope + PageBackgroundSpec data (see
// page_background_spec.dart's resolvePageBackground — this typedef's
// signature matches that function's own (pageIndex, pageCount) shape
// exactly, so a caller can usually just pass
// `(i, n) => resolvePageBackground(scope: ..., pageIndex: i, pageCount: n, ...)`
// directly).
typedef PageBackgroundResolver = PageBackgroundSpec? Function(int pageIndex, int pageCount);

class A4Paginator extends StatefulWidget {
  final List<Widget> items;
  final PageSectionBuilder headerBuilder;
  final PageSectionBuilder footerBuilder;
  final double pageWidth;
  final double pageHeight;
  final double contentWidth;
  final EdgeInsets pagePadding;
  final void Function(int pageCount)? onPageCount;

  final double headerGap;
  final double footerGap;
  final double itemGap;
  final double pageGap;

  final bool showPageNumbers;
  final String? fontFamily;

  final double footerBottomInset;

  final double textScale;

  final Widget Function()? itemsHeaderRowBuilder;
  final double itemsHeaderRowGap;

  final int footerItemCount;

  // MID-PAGE BACKGROUND PASS: optional background image behind the
  // body content area (the item rows + totals block, i.e. everything
  // inside the Expanded region between the header and the footer) —
  // rendered on EVERY page, not just the last one, since it's part of
  // the repeating per-page layout rather than a once-per-document
  // block like the header/footer.
  //
  // FULL-BLEED FIX (earlier): this used to be wrapped in
  // withOptionalBackgroundImage confined to the items region's own
  // bounds — i.e. inside this page's horizontal pagePadding, same
  // "boxed in, not true full-bleed" bug the header background had
  // before its own fix. Now goes through the shared
  // renderDocumentBackground() (see document_backgrounds/), bled by
  // pagePadding.left/right to reach the true page edge, matching how
  // the header/footer backgrounds reach it. No height cap here (unlike
  // header/footer) — the body region's own natural per-page height
  // (however many item rows fit) is exactly what should be covered,
  // not an artificial fixed band.
  //
  // NOTE: this zone-scoped body background and the new page-level
  // background below (pageBackgroundResolver) are independent and can
  // both be active at once — the page-level layer paints first, the
  // zone-scoped body background (if also enabled) paints on top of it
  // within its own region. For "one continuous image across header +
  // billed-to + items", use pageBackgroundResolver instead of this.
  final String? bodyBackgroundImagePath;
  final bool bodyBackgroundEnabled;
  final double bodyBackgroundOpacity;
  final double bodyBackgroundOffsetDx;
  final double bodyBackgroundOffsetDy;
  final double bodyBackgroundScale;

  // FULL-BLEED HEADER BACKGROUND PASS (historical note): these fields
  // were added in an earlier pass toward moving the header background
  // to this level, but that refactor was never completed — the header
  // background is actually handled in executive_template.dart's
  // _fullBleedHeaderBackground instead (see that file). These fields
  // are unused by _buildPage below; left in place only because a
  // caller may already be passing them and removing the params would
  // be a breaking change for no behavioural gain. Do not wire these up
  // without also removing executive_template.dart's own header
  // background handling, or the header would double-render it.
  final String? headerBackgroundImagePath;
  final bool headerBackgroundEnabled;
  final double headerBackgroundOpacity;
  final double headerBackgroundOffsetDx;
  final double headerBackgroundOffsetDy;
  final double headerBackgroundScale;

  // PER-PAGE BACKGROUND PASS: when supplied, this is called once per
  // rendered page (after the real page count is known — see _buildPage
  // below) to get that page's own whole-page background, if any. Paints
  // as a single Positioned.fill layer BEHIND everything else on the
  // page (header, meta row, items, footer all render as normal content
  // on top of it), so an uploaded image reads as one continuous photo
  // running the full height of the page instead of being cut off at
  // each section's own boundary. Null (the default) means no page-level
  // background at all — every existing document/template that doesn't
  // pass this is completely unaffected.
  //
  // Container/panel colors drawn by header/meta/item-row/footer content
  // are NOT automatically made transparent by this alone — each of
  // those render sites still needs to check whether a page background
  // is active for the page it's on and skip its own opaque fill when it
  // is, so the image underneath isn't hidden. That's still pending
  // (needs content_color_spec.dart + the per-template render code).
  final PageBackgroundResolver? pageBackgroundResolver;

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
    this.footerBottomInset = 10,
    this.itemsHeaderRowBuilder,
    this.itemsHeaderRowGap = 20,
    this.footerItemCount = 0,
    this.textScale = 1.0,
    this.bodyBackgroundImagePath,
    this.bodyBackgroundEnabled = false,
    this.bodyBackgroundOpacity = 1.0,
    this.bodyBackgroundOffsetDx = 0.0,
    this.bodyBackgroundOffsetDy = 0.0,
    this.bodyBackgroundScale = 1.0,
    this.headerBackgroundImagePath,
    this.headerBackgroundEnabled = false,
    this.headerBackgroundOpacity = 1.0,
    this.headerBackgroundOffsetDx = 0.0,
    this.headerBackgroundOffsetDy = 0.0,
    this.headerBackgroundScale = 1.0,
    this.pageBackgroundResolver,
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
  List<bool>? _pageHasRealItem;
  // FULL-BLEED HEADER BACKGROUND PASS: the exact measured height of
  // buildFullHeader's content — needed at build time so the
  // full-bleed Positioned background layer in _buildPage can be sized
  // to precisely that height (not the whole page), so it only ever
  // covers the header section, never bleeding into the items below it.
  double? _fullHeaderHeight;
  int _measurePass = 0;
  static const _kMaxPasses = 8;

  static const int _kProbePageCount = 999;

  // PAGE-NUMBER OVERLAP FIX: the "Page X of Y" label used to be pinned
  // via Positioned(bottom: widget.footerBottomInset, ...) — a fixed
  // distance from the literal page edge, completely independent of how
  // tall the footer content directly above it (thank-you text + divider
  // + up to 6 footer taglines) actually was. The footer flows normally
  // in the page's Column and its own bottom edge lands at that exact
  // same Y. With few/short taglines there was enough slack that the two
  // never touched, but with 5-6 taglines — especially once any of them
  // wrap to two lines — the footer's real height grows enough that its
  // last row sits right under (visually: right through) the page
  // number.
  //
  // Fix: reserve a dedicated band, this many logical pixels tall, at
  // the very bottom of the page exclusively for the number. It's
  // subtracted from the pagination height budget (_paginate's availH)
  // so items/footer never get measured as fitting into space that's
  // actually earmarked for the number, and it's added to the content
  // Padding's bottom inset in _buildPage so the footer's own flow
  // stops above the band instead of sharing it. 14.0 comfortably fits
  // the 8.5pt page-number text this widget renders plus a couple of
  // pixels of breathing room.
  static const double _kPageNumberBandHeight = 14.0;

  @override
  void initState() {
    super.initState();
    _itemKeys = List.generate(widget.items.length, (_) => GlobalKey());
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(A4Paginator old) {
    super.didUpdateWidget(old);
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

    final realItemBoundary = widget.items.length - widget.footerItemCount;
    final hasRealItem = pageIndexLists
        .map((idxList) => idxList.any((i) => i < realItemBoundary))
        .toList();

    if (!mounted) return;
    setState(() {
      _pages = pages;
      _pageHasRealItem = hasRealItem;
      _fullHeaderHeight = fullHeaderH;
    });
    widget.onPageCount?.call(pages.length);
  }

  (List<List<int>>, List<List<Widget>>) _paginate({
    required List<double> itemHeights,
    required double fullHeaderH,
    required double contHeaderH,
    required double footerH,
    required double itemsHeaderRowH,
  }) {
    // PAGE-NUMBER OVERLAP FIX: reserve the number band in the height
    // budget whenever page numbers are switched on at all — we can't
    // know yet whether this document will end up single- or
    // multi-page (that's the very thing this method is computing), and
    // the number only actually renders once pageCount > 1. Reserving
    // it unconditionally here is the conservative choice: a
    // single-page document gives up a few pixels of unused margin it
    // never needed, but a document that does end up multi-page is
    // guaranteed the room it needs. See _buildPage for where the band
    // is actually consumed (only on pages where the number renders).
    final numberReserve = widget.showPageNumbers ? _kPageNumberBandHeight : 0.0;
    final availH = widget.pageHeight - widget.pagePadding.vertical - numberReserve;
    final rowReserve = widget.itemsHeaderRowBuilder == null
        ? 0.0
        : itemsHeaderRowH + widget.itemsHeaderRowGap;

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

    final lastPageHeader = pages.length == 1 ? fullHeaderH : contHeaderH;
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
    final showNumber = widget.showPageNumbers && pageCount > 1;
    final showItemsHeaderRow = widget.itemsHeaderRowBuilder != null && hasRealItems;

    // PAGE-NUMBER OVERLAP FIX: when the number actually renders on this
    // page, push the content column's bottom edge up by the reserved
    // band height so the footer's own flow stops above it, then keep
    // the number itself anchored at the original footerBottomInset —
    // i.e. inside the now-empty band, never sharing a line with
    // whatever the footer's real content height turned out to be.
    final contentBottomPadding =
        widget.footerBottomInset + (showNumber ? _kPageNumberBandHeight : 0.0);

    final itemsRegion = Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: items,
      ),
    );

    // FULL-BLEED FIX (earlier): itemsRegion sits inside this page's
    // own horizontal Padding (pagePadding.left/right below), same as
    // header/footer content does — so the body background needs the
    // exact same bleed treatment to reach the true page edge instead of
    // stopping at the content's own left/right bounds. bleedLeft/Right
    // is `widget.pagePadding`'s own values (not a hardcoded constant),
    // since A4Paginator is generic across whatever page padding its
    // caller configures. No height cap (unlike header/footer) — the
    // Expanded region's own natural per-page height is exactly what
    // should be covered.
    final bodySpec = BackgroundSpec.fromFields(
      imagePath: widget.bodyBackgroundImagePath,
      enabled: widget.bodyBackgroundEnabled,
      opacity: widget.bodyBackgroundOpacity,
      offsetDx: widget.bodyBackgroundOffsetDx,
      offsetDy: widget.bodyBackgroundOffsetDy,
      scale: widget.bodyBackgroundScale,
      fit: BoxFit.cover,
    );
    final itemsRegionWithBackground = renderDocumentBackground(
      spec: bodySpec,
      child: itemsRegion,
      bleedLeft: widget.pagePadding.left,
      bleedRight: widget.pagePadding.right,
    );

    // PER-PAGE BACKGROUND PASS: resolve this specific page's whole-page
    // background (if any) now that the real pageCount is known — a
    // resolver built from PageBackgroundScope.allPages, for instance,
    // needs pageCount to decide how many pages actually get a
    // (possibly duplicated) image.
    final pageBgSpec = widget.pageBackgroundResolver?.call(pageIndex, pageCount);
    final hasPageBg = pageBgSpec?.hasVisibleImage ?? false;

    return SizedBox(
      width: widget.pageWidth,
      height: widget.pageHeight,
      child: Material(
        // PER-PAGE BACKGROUND PASS: Material's own color stays white
        // regardless — the page background layer below paints ON TOP
        // of it (Stack children paint in order), so this doesn't need
        // to change. What DOES still need to go transparent, for the
        // image to actually show through, is every opaque panel/row
        // fill drawn by the header/meta/items/footer content itself —
        // not handled here; see this file's header comment on
        // pageBackgroundResolver.
        color: Colors.white,
        elevation: 2,
        child: Stack(
          children: [
            // PER-PAGE BACKGROUND PASS: painted FIRST so every other
            // Stack child (the real page content below) renders on top
            // of it, as one continuous image behind the whole page
            // rather than the header/footer's own separately-clipped
            // zone backgrounds.
            if (hasPageBg)
              Positioned.fill(
                child: renderFullPageBackgroundLayer(pageBgSpec!.toBackgroundSpec()),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.pagePadding.left,
                widget.pagePadding.top,
                widget.pagePadding.right,
                contentBottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.headerBuilder(pageIndex, pageCount),
                  SizedBox(height: widget.headerGap),
                  if (showItemsHeaderRow) ...[
                    widget.itemsHeaderRowBuilder!(),
                    SizedBox(height: widget.itemsHeaderRowGap),
                  ],
                  Expanded(
                    child: itemsRegionWithBackground,
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
                left: widget.pagePadding.left,
                right: widget.pagePadding.right,
                bottom: widget.footerBottomInset,
                child: Align(
                  alignment: Alignment.bottomRight,
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
        ? [_buildPage(0, 1, const [], hasRealItems: true)]
        : [
            for (int p = 0; p < pages.length; p++)
              _buildPage(p, pages.length, pages[p], hasRealItems: hasRealItemFlags?[p] ?? true)
          ];

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
