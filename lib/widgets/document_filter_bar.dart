// document_filter_bar.dart
// lib/widgets/document_filter_bar.dart
//
// CLEARABLE FILTERS BADGE PASS (this update): the small dot that used to
// appear on the Filters button (_FiltersButton) whenever any advanced
// filter was active was purely decorative -- it told you filters were on,
// but clearing them still meant opening the Filters sheet and tapping
// "Clear all". That dot is now a small tappable "×" badge sitting in the
// button's top-right corner, OUTSIDE the button's own square (Positioned
// at top: -6, right: -6 against an outer Stack that wraps the button
// rather than sitting inside it, so it visually reads as an overlay
// badge, not part of the button face). Tapping it calls the same
// clear-everything logic the Filters sheet's own "Clear all" link uses --
// pulled out into a new _DocumentFilterBarState._clearAllFilters() method
// so both call sites share one implementation instead of duplicating the
// nine reset calls. The badge only renders when
// _hasActiveAdvancedFilters is true, same condition that already drove
// the old dot and the button's own highlighted/active visual state.
// _FiltersButton gained a new required onClear callback to carry this.

import 'package:flutter/material.dart';
import '../models/invoice_data.dart' show PaymentStatus;
import '../models/quote_data.dart' show QuoteStatus;
import '../models/receipt_data.dart' show ReceiptStatus;
import '../filters/filter_types.dart';

enum DocTypeFilter { all, invoices, quotes, receipts, expenses }

// INVOICE/RECEIPT DRAFT FILTER PASS: value type for the Invoice Status
// dropdown only. Superset of PaymentStatus plus "any" (no filter) and
// "draft" (completionPercent < 100, not a PaymentStatus value at all).
// Never persisted, never leaves this file.
enum _InvoiceStatusFilterOption { any, unpaid, partial, paid, overdue, draft }

_InvoiceStatusFilterOption _invoiceStatusFilterFromPaymentStatus(PaymentStatus? s) {
  if (s == null) return _InvoiceStatusFilterOption.any;
  switch (s) {
    case PaymentStatus.unpaid:
      return _InvoiceStatusFilterOption.unpaid;
    case PaymentStatus.partial:
      return _InvoiceStatusFilterOption.partial;
    case PaymentStatus.paid:
      return _InvoiceStatusFilterOption.paid;
    case PaymentStatus.overdue:
      return _InvoiceStatusFilterOption.overdue;
  }
}

PaymentStatus? _paymentStatusFromInvoiceStatusFilter(_InvoiceStatusFilterOption o) {
  switch (o) {
    case _InvoiceStatusFilterOption.unpaid:
      return PaymentStatus.unpaid;
    case _InvoiceStatusFilterOption.partial:
      return PaymentStatus.partial;
    case _InvoiceStatusFilterOption.paid:
      return PaymentStatus.paid;
    case _InvoiceStatusFilterOption.overdue:
      return PaymentStatus.overdue;
    case _InvoiceStatusFilterOption.any:
    case _InvoiceStatusFilterOption.draft:
      return null;
  }
}

// INVOICE/RECEIPT DRAFT FILTER PASS: same idea as
// _InvoiceStatusFilterOption above, for the Receipt Status dropdown.
enum _ReceiptStatusFilterOption { any, issued, refunded, draft }

_ReceiptStatusFilterOption _receiptStatusFilterFromReceiptStatus(ReceiptStatus? s) {
  if (s == null) return _ReceiptStatusFilterOption.any;
  switch (s) {
    case ReceiptStatus.issued:
      return _ReceiptStatusFilterOption.issued;
    case ReceiptStatus.refunded:
      return _ReceiptStatusFilterOption.refunded;
  }
}

ReceiptStatus? _receiptStatusFromReceiptStatusFilter(_ReceiptStatusFilterOption o) {
  switch (o) {
    case _ReceiptStatusFilterOption.issued:
      return ReceiptStatus.issued;
    case _ReceiptStatusFilterOption.refunded:
      return ReceiptStatus.refunded;
    case _ReceiptStatusFilterOption.any:
    case _ReceiptStatusFilterOption.draft:
      return null;
  }
}

class DocumentFilterBar extends StatefulWidget {
  final DocTypeFilter selectedType;
  final ValueChanged<DocTypeFilter> onTypeChanged;

  final PaymentStatus? selectedPaymentStatus;
  final ValueChanged<PaymentStatus?> onPaymentStatusChanged;

  // INVOICE/RECEIPT DRAFT FILTER PASS: independent of
  // selectedPaymentStatus/onPaymentStatusChanged above -- true means
  // "filter to invoices where completionPercent < 100" (same rule the
  // existing Drafts quick-filter chip uses). selectedPaymentStatus is
  // always null whenever this is true, and vice versa -- see the
  // dropdown's onChanged below for exactly how both are kept in sync.
  final bool invoiceDraftSelected;
  final ValueChanged<bool> onInvoiceDraftChanged;

  final QuoteStatus? selectedQuoteStatus;
  final ValueChanged<QuoteStatus?> onQuoteStatusChanged;

  final ReceiptStatus? selectedReceiptStatus;
  final ValueChanged<ReceiptStatus?> onReceiptStatusChanged;

  // INVOICE/RECEIPT DRAFT FILTER PASS: same pairing as
  // invoiceDraftSelected above, for receipts.
  final bool receiptDraftSelected;
  final ValueChanged<bool> onReceiptDraftChanged;

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
    required this.invoiceDraftSelected,
    required this.onInvoiceDraftChanged,
    required this.selectedQuoteStatus,
    required this.onQuoteStatusChanged,
    required this.selectedReceiptStatus,
    required this.onReceiptStatusChanged,
    required this.receiptDraftSelected,
    required this.onReceiptDraftChanged,
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
      widget.invoiceDraftSelected ||
      widget.selectedQuoteStatus != null ||
      widget.selectedReceiptStatus != null ||
      widget.receiptDraftSelected ||
      widget.selectedDateRange != DateRangePreset.values.first ||
      widget.customRangeStart != null ||
      widget.minAmount != null ||
      widget.maxAmount != null ||
      widget.selectedFolder != null;

  // CLEARABLE FILTERS BADGE PASS: pulled out of the Filters sheet's
  // "Clear all" onTap so both that link and the new "×" badge on
  // _FiltersButton (outside the sheet entirely) share one implementation
  // instead of duplicating the same nine reset calls. Resets every
  // advanced filter this bar tracks back to its default/off state --
  // type pill, quick filter, and search query are deliberately left
  // alone, same as the sheet's own "Clear all" always did (those aren't
  // considered "advanced filters").
  void _clearAllFilters() {
    widget.onPaymentStatusChanged(null);
    widget.onInvoiceDraftChanged(false);
    widget.onQuoteStatusChanged(null);
    widget.onReceiptStatusChanged(null);
    widget.onReceiptDraftChanged(false);
    widget.onDateRangeChanged(DateRangePreset.values.first);
    widget.onCustomRangeChanged(null, null);
    _minController.clear();
    _maxController.clear();
    widget.onAmountRangeChanged(null, null);
    widget.onFolderChanged(null);
    setState(() {});
  }

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
                            // CLEARABLE FILTERS BADGE PASS: now calls the
                            // shared _clearAllFilters() instead of
                            // inlining the same nine reset calls; the
                            // sheet still needs its own setSheetState
                            // after, since _clearAllFilters()'s setState
                            // only rebuilds the outer DocumentFilterBar,
                            // not this modal sheet's own StatefulBuilder.
                            onTap: () {
                              _clearAllFilters();
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
                        // INVOICE/RECEIPT DRAFT FILTER PASS: speaks
                        // _InvoiceStatusFilterOption instead of
                        // PaymentStatus? directly, so it can offer a
                        // "Draft" item that maps to completionPercent <
                        // 100 instead of a real PaymentStatus value.
                        child: _SheetDropdown<_InvoiceStatusFilterOption>(
                          value: widget.invoiceDraftSelected
                              ? _InvoiceStatusFilterOption.draft
                              : _invoiceStatusFilterFromPaymentStatus(widget.selectedPaymentStatus),
                          hint: 'Any status',
                          items: [
                            const DropdownMenuItem(
                              value: _InvoiceStatusFilterOption.any,
                              child: Text('Any status'),
                            ),
                            const DropdownMenuItem(
                              value: _InvoiceStatusFilterOption.draft,
                              child: Text('draft'),
                            ),
                            ...PaymentStatus.values.map(
                              (s) => DropdownMenuItem(
                                value: _invoiceStatusFilterFromPaymentStatus(s),
                                child: Text(s.name),
                              ),
                            ),
                          ],
                          onChanged: (opt) {
                            if (opt == null) return;
                            if (opt == _InvoiceStatusFilterOption.draft) {
                              widget.onPaymentStatusChanged(null);
                              widget.onInvoiceDraftChanged(true);
                            } else {
                              widget.onPaymentStatusChanged(
                                  _paymentStatusFromInvoiceStatusFilter(opt));
                              widget.onInvoiceDraftChanged(false);
                            }
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
                        // INVOICE/RECEIPT DRAFT FILTER PASS: same
                        // treatment as the Invoice Status dropdown above,
                        // using _ReceiptStatusFilterOption instead of
                        // ReceiptStatus? directly.
                        child: _SheetDropdown<_ReceiptStatusFilterOption>(
                          value: widget.receiptDraftSelected
                              ? _ReceiptStatusFilterOption.draft
                              : _receiptStatusFilterFromReceiptStatus(widget.selectedReceiptStatus),
                          hint: 'Any status',
                          items: [
                            const DropdownMenuItem(
                              value: _ReceiptStatusFilterOption.any,
                              child: Text('Any status'),
                            ),
                            const DropdownMenuItem(
                              value: _ReceiptStatusFilterOption.draft,
                              child: Text('draft'),
                            ),
                            ...ReceiptStatus.values.map(
                              (s) => DropdownMenuItem(
                                value: _receiptStatusFilterFromReceiptStatus(s),
                                child: Text(s.name),
                              ),
                            ),
                          ],
                          onChanged: (opt) {
                            if (opt == null) return;
                            if (opt == _ReceiptStatusFilterOption.draft) {
                              widget.onReceiptStatusChanged(null);
                              widget.onReceiptDraftChanged(true);
                            } else {
                              widget.onReceiptStatusChanged(
                                  _receiptStatusFromReceiptStatusFilter(opt));
                              widget.onReceiptDraftChanged(false);
                            }
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
              // CLEARABLE FILTERS BADGE PASS: onClear now wired to the
              // shared _clearAllFilters() — see that method's comment.
              _FiltersButton(
                active: _hasActiveAdvancedFilters,
                onTap: _openFiltersSheet,
                onClear: _clearAllFilters,
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
//
// CLEARABLE FILTERS BADGE PASS: the button itself is now wrapped in an
// outer Stack (clipBehavior: Clip.none) instead of putting the Stack
// INSIDE the 42×42 Container as before — that's what lets the new "×"
// badge sit at negative top/right offsets, rendering OUTSIDE the
// button's own square rather than clipped to it. The old plain
// "active" dot is gone; the badge itself now carries both jobs (shows
// filters are active, AND clears them on tap).

class _FiltersButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _FiltersButton({required this.active, required this.onTap, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
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
            child: Center(
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        if (active)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(Icons.close_rounded, size: 12, color: cs.onPrimary),
              ),
            ),
          ),
      ],
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