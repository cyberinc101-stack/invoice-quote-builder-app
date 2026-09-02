// document_filter_bar.dart
// lib/widgets/document_filter_bar.dart
//
// AUTO-CENTER PILL PASS (this update): tapping a type pill (All/Invoices/
// Quotes/Receipts/Expenses) selects it but previously left the horizontal
// scroll position untouched — on a narrow screen, selecting a pill near
// the right edge (e.g. "Receipts") could leave it partially under the
// fade mask or off the visible area entirely, with no indication where
// the newly-selected pill went. Each type pill now carries its own
// GlobalKey (_pillKeys, one per DocTypeFilter); didUpdateWidget detects
// a selectedType change and, on the next frame (once the new pill's
// RenderBox exists), calls Scrollable.ensureVisible(alignment: 0.5) to
// smoothly scroll the row so the selected pill centers itself in the
// visible strip. _Pill now accepts and forwards `key` so these GlobalKeys
// can actually attach to the right widget instance. Quick-filter chips
// and the Folders/Drafts chips are unaffected — this only centers the
// five main type pills, which is what was asked for.
//
// BOTTOM SAFE-AREA FIX (earlier pass): the Filters bottom sheet's content
// padding was a fixed EdgeInsets.fromLTRB(20, 12, 20, 24) -- on devices
// with an on-screen (gesture or 3-button) Android nav bar, that fixed
// 24px wasn't enough to clear it, so the "Done" button at the bottom of
// the sheet sat partially behind the nav bar. Now adds
// MediaQuery.of(context).padding.bottom on top of the fixed 24px, same
// fix applied to the "Move to Folder" sheet in
// saved_documents_section.dart. The existing
// Padding(bottom: viewInsets.bottom) wrapping the whole sheet is
// unchanged -- that one handles the on-screen keyboard, this handles the
// nav bar; they're two different insets and both are needed.
//
// SWIPE-FADE (earlier pass): the single scrollable row of type pills
// (All/Invoices/Quotes/Receipts/Expenses) + quick-filter chips + Folders +
// Drafts previously gave no visual cue that it scrolls horizontally --
// Jesse felt it wasn't obvious more content was swipable off to the
// right, and wanted the row's pills to always render in full rather than
// looking potentially cut off. The ListView itself was never actually
// clipping a pill mid-render (each pill sizes to its own content), but
// with no scroll affordance the trailing pill sitting flush against the
// screen edge read as "cut off" even when it wasn't.
//
// Fix: wrap the row in a ShaderMask that fades opacity to zero over the
// last ~28px on the right edge only (left edge stays fully opaque, since
// the row always starts scrolled to the left with nothing hidden behind
// it). This uses BlendMode.dstIn against a horizontal gradient going
// white -> transparent -- a widely-used, lightweight signal that a
// horizontal list continues off-screen. Purely visual: doesn't change
// hit-testing, scroll physics, or any pill's actual layout. A trailing
// SizedBox(width: 24) was also added after the last chip so it clears the
// fade zone with room to spare, rather than the fade eating into the last
// real chip right at the end of the row.

import 'package:flutter/material.dart';
import '../models/invoice_data.dart' show PaymentStatus;
import '../models/quote_data.dart' show QuoteStatus;
import '../models/receipt_data.dart' show ReceiptStatus;
import '../filters/filter_types.dart';

enum DocTypeFilter { all, invoices, quotes, receipts, expenses }

class DocumentFilterBar extends StatefulWidget {
  final DocTypeFilter selectedType;
  final ValueChanged<DocTypeFilter> onTypeChanged;

  final PaymentStatus? selectedPaymentStatus;
  final ValueChanged<PaymentStatus?> onPaymentStatusChanged;
  final QuoteStatus? selectedQuoteStatus;
  final ValueChanged<QuoteStatus?> onQuoteStatusChanged;
  final ReceiptStatus? selectedReceiptStatus;
  final ValueChanged<ReceiptStatus?> onReceiptStatusChanged;

  final int invoiceCount;
  final int quoteCount;
  final int receiptCount;
  final int expensesCount;

  final QuickFilter selectedQuickFilter;
  final ValueChanged<QuickFilter> onQuickFilterChanged;
  final int needsActionCount;
  final int overdueCount;
  final int draftsCount;
  final int overdue1to30Count;
  final int overdue31to60Count;
  final int overdue61plusCount;

  final int paidCount;
  final int acceptedCount;
  final int declinedCount;

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  final String? searchHint;

  final DateRangePreset selectedDateRange;
  final ValueChanged<DateRangePreset> onDateRangeChanged;
  final DateTime? customRangeStart;
  final DateTime? customRangeEnd;
  final void Function(DateTime? start, DateTime? end) onCustomRangeChanged;

  final SortOption selectedSort;
  final ValueChanged<SortOption> onSortChanged;

  final double? minAmount;
  final double? maxAmount;
  final void Function(double? min, double? max) onAmountRangeChanged;

  final String? selectedFolder;
  final ValueChanged<String?> onFolderChanged;
  final List<String> availableFolders;

  final VoidCallback onFoldersChipTap;

  final bool isBrowsingFolders;

  const DocumentFilterBar({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.selectedPaymentStatus,
    required this.onPaymentStatusChanged,
    required this.selectedQuoteStatus,
    required this.onQuoteStatusChanged,
    required this.selectedReceiptStatus,
    required this.onReceiptStatusChanged,
    required this.invoiceCount,
    required this.quoteCount,
    required this.receiptCount,
    required this.expensesCount,
    required this.selectedQuickFilter,
    required this.onQuickFilterChanged,
    required this.needsActionCount,
    required this.overdueCount,
    required this.draftsCount,
    required this.overdue1to30Count,
    required this.overdue31to60Count,
    required this.overdue61plusCount,
    required this.paidCount,
    required this.acceptedCount,
    required this.declinedCount,
    required this.searchQuery,
    required this.onSearchChanged,
    this.searchHint,
    required this.selectedDateRange,
    required this.onDateRangeChanged,
    required this.customRangeStart,
    required this.customRangeEnd,
    required this.onCustomRangeChanged,
    required this.selectedSort,
    required this.onSortChanged,
    required this.minAmount,
    required this.maxAmount,
    required this.onAmountRangeChanged,
    required this.selectedFolder,
    required this.onFolderChanged,
    required this.availableFolders,
    required this.onFoldersChipTap,
    this.isBrowsingFolders = false,
  });

  @override
  State<DocumentFilterBar> createState() => _DocumentFilterBarState();
}

class _DocumentFilterBarState extends State<DocumentFilterBar> {
  late final TextEditingController _searchController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  // AUTO-CENTER PILL PASS: one GlobalKey per type pill, so
  // Scrollable.ensureVisible can locate the newly-selected pill's
  // RenderBox after a rebuild and scroll it into the center of the row.
  final Map<DocTypeFilter, GlobalKey> _pillKeys = {
    for (final f in DocTypeFilter.values) f: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _minController = TextEditingController(
        text: widget.minAmount == null ? '' : widget.minAmount!.toStringAsFixed(0));
    _maxController = TextEditingController(
        text: widget.maxAmount == null ? '' : widget.maxAmount!.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant DocumentFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text &&
        widget.searchQuery != oldWidget.searchQuery) {
      _searchController.text = widget.searchQuery;
    }

    // AUTO-CENTER PILL PASS: the parent only re-renders this widget with
    // a new selectedType after its own setState has run, so by the next
    // frame the newly-selected pill's key has a live context to scroll
    // to. alignment: 0.5 centers it in the ListView's viewport rather
    // than just scrolling it minimally into view at an edge.
    if (widget.selectedType != oldWidget.selectedType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _pillKeys[widget.selectedType]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.5,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _submitAmountRange() {
    final min = double.tryParse(_minController.text.trim());
    final max = double.tryParse(_maxController.text.trim());
    widget.onAmountRangeChanged(min, max);
  }

  bool get _hasActiveAdvancedFilters =>
      widget.selectedPaymentStatus != null ||
      widget.selectedQuoteStatus != null ||
      widget.selectedReceiptStatus != null ||
      widget.selectedDateRange != DateRangePreset.values.first ||
      widget.customRangeStart != null ||
      widget.minAmount != null ||
      widget.maxAmount != null ||
      widget.selectedFolder != null;

  Future<void> _pickCustomRange(void Function(void Function()) setSheetState) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (widget.customRangeStart != null && widget.customRangeEnd != null)
          ? DateTimeRange(start: widget.customRangeStart!, end: widget.customRangeEnd!)
          : null,
    );
    if (picked != null) {
      widget.onCustomRangeChanged(picked.start, picked.end);
      widget.onDateRangeChanged(DateRangePreset.custom);
      setSheetState(() {});
    }
  }

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final cs = Theme.of(context).colorScheme;

            final showInvoiceStatus = widget.selectedType == DocTypeFilter.invoices ||
                (widget.selectedType == DocTypeFilter.all && widget.invoiceCount > 0);
            final showQuoteStatus = widget.selectedType == DocTypeFilter.quotes ||
                (widget.selectedType == DocTypeFilter.all && widget.quoteCount > 0);
            final showReceiptStatus = widget.selectedType == DocTypeFilter.receipts ||
                (widget.selectedType == DocTypeFilter.all && widget.receiptCount > 0);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                // BOTTOM SAFE-AREA FIX: was a fixed 24px, which sat the
                // Done button behind the on-screen Android nav bar on
                // devices that have one. Adds the device's own bottom
                // safe-area inset on top of the fixed 24px so the button
                // always clears it -- this is separate from the
                // viewInsets.bottom padding above (that one is for the
                // keyboard), both are needed together.
                padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + MediaQuery.of(context).padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        if (_hasActiveAdvancedFilters)
                          GestureDetector(
                            onTap: () {
                              widget.onPaymentStatusChanged(null);
                              widget.onQuoteStatusChanged(null);
                              widget.onReceiptStatusChanged(null);
                              widget.onDateRangeChanged(DateRangePreset.values.first);
                              widget.onCustomRangeChanged(null, null);
                              _minController.clear();
                              _maxController.clear();
                              widget.onAmountRangeChanged(null, null);
                              widget.onFolderChanged(null);
                              setSheetState(() {});
                            },
                            child: Text(
                              'Clear all',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (showInvoiceStatus)
                      _SheetSection(
                        label: widget.selectedType == DocTypeFilter.all
                            ? 'Invoice Status'
                            : 'Status',
                        child: _SheetDropdown<PaymentStatus?>(
                          value: widget.selectedPaymentStatus,
                          hint: 'Any status',
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Any status')),
                            ...PaymentStatus.values.map(
                                (s) => DropdownMenuItem(value: s, child: Text(s.name))),
                          ],
                          onChanged: (v) {
                            widget.onPaymentStatusChanged(v);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    if (showQuoteStatus)
                      _SheetSection(
                        label: widget.selectedType == DocTypeFilter.all
                            ? 'Quote Status'
                            : 'Status',
                        child: _SheetDropdown<QuoteStatus?>(
                          value: widget.selectedQuoteStatus,
                          hint: 'Any status',
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Any status')),
                            ...QuoteStatus.values.map(
                                (s) => DropdownMenuItem(value: s, child: Text(s.name))),
                          ],
                          onChanged: (v) {
                            widget.onQuoteStatusChanged(v);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    if (showReceiptStatus)
                      _SheetSection(
                        label: widget.selectedType == DocTypeFilter.all
                            ? 'Receipt Status'
                            : 'Status',
                        child: _SheetDropdown<ReceiptStatus?>(
                          value: widget.selectedReceiptStatus,
                          hint: 'Any status',
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Any status')),
                            ...ReceiptStatus.values.map(
                                (s) => DropdownMenuItem(value: s, child: Text(s.name))),
                          ],
                          onChanged: (v) {
                            widget.onReceiptStatusChanged(v);
                            setSheetState(() {});
                          },
                        ),
                      ),

                    _SheetSection(
                      label: 'Folder',
                      child: _SheetDropdown<String?>(
                        value: widget.selectedFolder,
                        hint: 'All Folders',
                        icon: Icons.folder_outlined,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Folders')),
                          ...widget.availableFolders.map(
                              (f) => DropdownMenuItem(value: f, child: Text(f))),
                        ],
                        onChanged: (v) {
                          widget.onFolderChanged(v);
                          setSheetState(() {});
                        },
                      ),
                    ),

                    _SheetSection(
                      label: 'Date & Sort',
                      child: Row(
                        children: [
                          Expanded(
                            child: _SheetDropdown<DateRangePreset>(
                              icon: Icons.date_range_rounded,
                              value: widget.selectedDateRange,
                              items: DateRangePreset.values
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          dateRangePresetLabel(p),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (p) {
                                if (p == null) return;
                                if (p == DateRangePreset.custom) {
                                  _pickCustomRange(setSheetState);
                                } else {
                                  widget.onCustomRangeChanged(null, null);
                                  widget.onDateRangeChanged(p);
                                }
                                setSheetState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SheetDropdown<SortOption>(
                              icon: Icons.sort_rounded,
                              value: widget.selectedSort,
                              items: SortOption.values
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          sortOptionLabel(s),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (s) {
                                if (s == null) return;
                                widget.onSortChanged(s);
                                setSheetState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    _SheetSection(
                      label: 'Amount Range',
                      child: Row(
                        children: [
                          Expanded(
                            child: _SheetAmountField(
                              controller: _minController,
                              hint: 'Min',
                              onSubmit: () {
                                _submitAmountRange();
                                setSheetState(() {});
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text('–',
                                style: TextStyle(
                                    fontSize: 14, color: cs.onSurface.withValues(alpha: 0.35))),
                          ),
                          Expanded(
                            child: _SheetAmountField(
                              controller: _maxController,
                              hint: 'Max',
                              onSubmit: () {
                                _submitAmountRange();
                                setSheetState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          _submitAmountRange();
                          Navigator.pop(sheetContext);
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Done',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _submitAmountRange();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final showPaidChip = widget.selectedType == DocTypeFilter.invoices ||
        (widget.selectedType == DocTypeFilter.all && widget.invoiceCount > 0);
    final showQuoteStatusChips = widget.selectedType == DocTypeFilter.quotes ||
        (widget.selectedType == DocTypeFilter.all && widget.quoteCount > 0);

    final quickEntries = <_QuickEntry>[
      _QuickEntry(QuickFilter.needsAction, widget.needsActionCount),
      _QuickEntry(QuickFilter.overdue, widget.overdueCount),
      _QuickEntry(QuickFilter.overdue1to30, widget.overdue1to30Count),
      _QuickEntry(QuickFilter.overdue31to60, widget.overdue31to60Count),
      _QuickEntry(QuickFilter.overdue61plus, widget.overdue61plusCount),
      if (showPaidChip) _QuickEntry(QuickFilter.paid, widget.paidCount),
      if (showQuoteStatusChips) _QuickEntry(QuickFilter.accepted, widget.acceptedCount),
      if (showQuoteStatusChips) _QuickEntry(QuickFilter.declined, widget.declinedCount),
    ].where((e) => e.count > 0 || widget.selectedQuickFilter == e.filter).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search + Filters button ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.searchHint ?? 'Search by title, client, or number',
                    hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
                    prefixIcon:
                        Icon(Icons.search_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged('');
                              setState(() {});
                            },
                          ),
                    filled: true,
                    fillColor: cs.onSurface.withValues(alpha: 0.045),
                    contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.18)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.55)),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.18)),
                    ),
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              _FiltersButton(
                active: _hasActiveAdvancedFilters,
                onTap: _openFiltersSheet,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Single scrollable line: type pills + quick-filter chips ────
          // SWIPE-FADE: the whole ListView is wrapped in a ShaderMask so
          // the trailing (right) edge fades to transparent over its last
          // ~28px, signalling more content is swipable without a hard
          // clipped edge. Purely a paint-time mask -- scrolling, hit
          // testing, and pill layout are unchanged.
          SizedBox(
            height: 34,
            child: ShaderMask(
              shaderCallback: (bounds) {
                final fadeFraction = (28 / bounds.width).clamp(0.0, 1.0);
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 1 - fadeFraction, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _Pill(
                    key: _pillKeys[DocTypeFilter.all],
                    label: 'All',
                    count: widget.invoiceCount + widget.quoteCount + widget.receiptCount + widget.expensesCount,
                    selected: widget.selectedType == DocTypeFilter.all,
                    onTap: () => widget.onTypeChanged(DocTypeFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    key: _pillKeys[DocTypeFilter.invoices],
                    label: 'Invoices',
                    count: widget.invoiceCount,
                    selected: widget.selectedType == DocTypeFilter.invoices,
                    onTap: () => widget.onTypeChanged(DocTypeFilter.invoices),
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    key: _pillKeys[DocTypeFilter.quotes],
                    label: 'Quotes',
                    count: widget.quoteCount,
                    selected: widget.selectedType == DocTypeFilter.quotes,
                    onTap: () => widget.onTypeChanged(DocTypeFilter.quotes),
                  ),
                  const SizedBox(width: 8),
                  _Pill(
                    key: _pillKeys[DocTypeFilter.receipts],
                    label: 'Receipts',
                    count: widget.receiptCount,
                    selected: widget.selectedType == DocTypeFilter.receipts,
                    onTap: () => widget.onTypeChanged(DocTypeFilter.receipts),
                  ),

                  if (quickEntries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Container(
                        width: 1,
                        height: 18,
                        color: cs.outline.withValues(alpha: 0.2),
                      ),
                    )
                  else
                    const SizedBox(width: 8),

                  for (final entry in quickEntries) ...[
                    _QuickPill(
                      label: quickFilterLabel(entry.filter),
                      count: entry.count,
                      selected: widget.selectedQuickFilter == entry.filter,
                      onTap: () => widget.onQuickFilterChanged(
                          widget.selectedQuickFilter == entry.filter
                              ? QuickFilter.none
                              : entry.filter),
                    ),
                    const SizedBox(width: 8),
                  ],

                  _Pill(
                    key: _pillKeys[DocTypeFilter.expenses],
                    label: 'Expenses',
                    count: widget.expensesCount,
                    selected: widget.selectedType == DocTypeFilter.expenses,
                    onTap: () => widget.onTypeChanged(DocTypeFilter.expenses),
                  ),
                  const SizedBox(width: 8),

                  _FolderChip(
                    selectedFolder: widget.selectedFolder,
                    isActive: widget.isBrowsingFolders || widget.selectedFolder != null,
                    onTap: widget.onFoldersChipTap,
                  ),
                  const SizedBox(width: 8),

                  _QuickPill(
                    label: quickFilterLabel(QuickFilter.drafts),
                    count: widget.draftsCount,
                    selected: widget.selectedQuickFilter == QuickFilter.drafts,
                    onTap: () => widget.onQuickFilterChanged(
                        widget.selectedQuickFilter == QuickFilter.drafts
                            ? QuickFilter.none
                            : QuickFilter.drafts),
                  ),
                  // Trailing spacer so the last real pill/chip clears the
                  // fade zone with room to spare, rather than the fade
                  // beginning to eat into it right at the end of the row.
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small holder used to filter the overdue/needs-action/status quick
// chips ─────────────────────────────────────────────────────────────────

class _QuickEntry {
  final QuickFilter filter;
  final int count;
  const _QuickEntry(this.filter, this.count);
}

// ── Filters button — sits next to search, opens the bottom sheet ──────────

class _FiltersButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FiltersButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: active ? cs.primary.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? cs.primary.withValues(alpha: 0.45) : cs.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (active)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Type pill (All/Invoices/Quotes/Receipts/Expenses) ──────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  // AUTO-CENTER PILL PASS: `key` is now accepted and forwarded to
  // `super.key` so a GlobalKey assigned per DocTypeFilter in
  // _DocumentFilterBarState actually attaches to this specific pill
  // instance — required for Scrollable.ensureVisible to find it.
  const _Pill({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          '$label · $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.68),
          ),
        ),
      ),
    );
  }
}

// ── Quick-filter chip — same language as _Pill, hides itself when empty ───

class _QuickPill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _QuickPill({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (count == 0 && !selected) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? cs.primary : cs.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          '$label · $count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.68),
          ),
        ),
      ),
    );
  }
}

// ── Folders quick-access chip ───────────────────────────────────────────

class _FolderChip extends StatelessWidget {
  final String? selectedFolder;
  final bool isActive;
  final VoidCallback onTap;

  const _FolderChip({
    required this.selectedFolder,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = selectedFolder ?? 'Folders';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 140),
        decoration: BoxDecoration(
          color: isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? cs.primary : cs.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 13,
              color: isActive ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom-sheet section wrapper — label above a full-width control ───────

class _SheetSection extends StatelessWidget {
  final String label;
  final Widget child;

  const _SheetSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface.withValues(alpha: 0.55),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

// ── Full-width dropdown used inside the bottom sheet ───────────────────────

class _SheetDropdown<T> extends StatelessWidget {
  final T value;
  final String? hint;
  final IconData? icon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _SheetDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: hint != null
              ? Text(hint!, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)))
              : null,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
          items: icon == null
              ? items
              : items
                  .map((item) => DropdownMenuItem<T>(
                        value: item.value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                            const SizedBox(width: 6),
                            Flexible(child: item.child),
                          ],
                        ),
                      ))
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Full-width amount field used inside the bottom sheet ───────────────────

class _SheetAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmit;

  const _SheetAmountField({
    required this.controller,
    required this.hint,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.18)),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
        decoration: InputDecoration(
          isCollapsed: true,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(Icons.attach_money_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.45)),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.35)),
          border: InputBorder.none,
        ),
        onSubmitted: (_) => onSubmit(),
        onEditingComplete: onSubmit,
      ),
    );
  }
}