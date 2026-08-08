// document_filter_bar.dart
// lib/widgets/document_filter_bar.dart
//
// REDESIGN v5 + FOLDERS: v5's structure (single scrollable quick-access
// row, everything else behind one "Filters" bottom sheet) is unchanged.
// The Filters sheet has a Folder dropdown (added in an earlier pass) —
// NOT the quick-access row, so the always-visible row stayed exactly as
// compact as before. New constructor params from that pass: selectedFolder,
// onFolderChanged, availableFolders. "Clear all" also resets the folder
// filter.
//
// FIX (this pass): the Status section (Payment/Quote/Receipt) only used to
// render when selectedType matched that exact pill, so with "All" selected
// — the default — no status dropdown ever showed, even when documents
// existed. Now each status dropdown shows whenever its type is selected OR
// "All" is selected and that type has documents.
//
// NEW (earlier pass): a quick-access "Folders" chip in the always-visible
// scrollable row itself, positioned immediately to the left of the Drafts
// chip. Filtering by folder was previously only reachable via the full
// Filters sheet, which buries a feature that gets used constantly once a
// user starts organizing documents. Tapping the new chip opens a
// lightweight bottom sheet (_FolderChip._openFolderPicker) listing "All
// Folders" plus every folder name; picking one applies immediately (no
// separate "Apply" step — this is meant to be a fast single-tap filter,
// unlike the fuller Filters sheet's folder dropdown, which stays as-is for
// people who open Filters directly). The chip shows "Folders" when nothing
// is selected, or the folder name itself (highlighted like the other
// active pills) once one is picked.

import 'package:flutter/material.dart';
import '../models/invoice_data.dart' show PaymentStatus;
import '../models/quote_data.dart' show QuoteStatus;
import '../models/receipt_data.dart' show ReceiptStatus;
import '../filters/filter_types.dart';

enum DocTypeFilter { all, invoices, quotes, receipts }

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

  final QuickFilter selectedQuickFilter;
  final ValueChanged<QuickFilter> onQuickFilterChanged;
  final int needsActionCount;
  final int overdueCount;
  final int draftsCount;
  final int overdue1to30Count;
  final int overdue31to60Count;
  final int overdue61plusCount;

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

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

  // Folder filter.
  final String? selectedFolder;
  final ValueChanged<String?> onFolderChanged;
  final List<String> availableFolders;

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
    required this.selectedQuickFilter,
    required this.onQuickFilterChanged,
    required this.needsActionCount,
    required this.overdueCount,
    required this.draftsCount,
    required this.overdue1to30Count,
    required this.overdue31to60Count,
    required this.overdue61plusCount,
    required this.searchQuery,
    required this.onSearchChanged,
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
  });

  @override
  State<DocumentFilterBar> createState() => _DocumentFilterBarState();
}

class _DocumentFilterBarState extends State<DocumentFilterBar> {
  late final TextEditingController _searchController;
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

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

            // FIX: previously each Status dropdown only rendered when
            // selectedType matched that EXACT pill (Invoices/Quotes/
            // Receipts). With "All" selected — the default — none of the
            // three matched, so the whole Status section silently vanished
            // even when documents existed. Now each dropdown shows
            // whenever its type is the selected pill OR "All" is selected
            // and that type actually has documents.
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Grab handle ──────────────────────────────────────
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

                    // ── Header ───────────────────────────────────────────
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

                    // ── Status (contextual to selected type) ─────────────
                    // Labeled per-type (not just "Status") because with
                    // "All" selected, more than one of these can render at
                    // once — plain "Status" three times in a row would be
                    // ambiguous about which dropdown controls what.
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

                    // ── Folder ─────────────────────────────────────────
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

                    // ── Date range + Sort — same row, one line ───────────
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

                    // ── Amount range — one line, Min + Max side by side ──
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

                    // ── Done ──────────────────────────────────────────────
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
      // Guard in case the sheet is dismissed by swipe/backdrop tap rather
      // than the Done button — make sure any typed min/max still commits.
      _submitAmountRange();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
                    hintText: 'Search by title, client, or number',
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
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Pill(
                  label: 'All',
                  count: widget.invoiceCount + widget.quoteCount + widget.receiptCount,
                  selected: widget.selectedType == DocTypeFilter.all,
                  onTap: () => widget.onTypeChanged(DocTypeFilter.all),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: 'Invoices',
                  count: widget.invoiceCount,
                  selected: widget.selectedType == DocTypeFilter.invoices,
                  onTap: () => widget.onTypeChanged(DocTypeFilter.invoices),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: 'Quotes',
                  count: widget.quoteCount,
                  selected: widget.selectedType == DocTypeFilter.quotes,
                  onTap: () => widget.onTypeChanged(DocTypeFilter.quotes),
                ),
                const SizedBox(width: 8),
                _Pill(
                  label: 'Receipts',
                  count: widget.receiptCount,
                  selected: widget.selectedType == DocTypeFilter.receipts,
                  onTap: () => widget.onTypeChanged(DocTypeFilter.receipts),
                ),

                // Divider between the type group and the quick-filter group
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    width: 1,
                    height: 18,
                    color: cs.outline.withValues(alpha: 0.2),
                  ),
                ),

                _QuickPill(
                  label: quickFilterLabel(QuickFilter.needsAction),
                  count: widget.needsActionCount,
                  selected: widget.selectedQuickFilter == QuickFilter.needsAction,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.needsAction
                          ? QuickFilter.none
                          : QuickFilter.needsAction),
                ),
                const SizedBox(width: 8),
                _QuickPill(
                  label: quickFilterLabel(QuickFilter.overdue),
                  count: widget.overdueCount,
                  selected: widget.selectedQuickFilter == QuickFilter.overdue,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.overdue
                          ? QuickFilter.none
                          : QuickFilter.overdue),
                ),
                const SizedBox(width: 8),
                _QuickPill(
                  label: quickFilterLabel(QuickFilter.overdue1to30),
                  count: widget.overdue1to30Count,
                  selected: widget.selectedQuickFilter == QuickFilter.overdue1to30,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.overdue1to30
                          ? QuickFilter.none
                          : QuickFilter.overdue1to30),
                ),
                const SizedBox(width: 8),
                _QuickPill(
                  label: quickFilterLabel(QuickFilter.overdue31to60),
                  count: widget.overdue31to60Count,
                  selected: widget.selectedQuickFilter == QuickFilter.overdue31to60,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.overdue31to60
                          ? QuickFilter.none
                          : QuickFilter.overdue31to60),
                ),
                const SizedBox(width: 8),
                _QuickPill(
                  label: quickFilterLabel(QuickFilter.overdue61plus),
                  count: widget.overdue61plusCount,
                  selected: widget.selectedQuickFilter == QuickFilter.overdue61plus,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.overdue61plus
                          ? QuickFilter.none
                          : QuickFilter.overdue61plus),
                ),
                const SizedBox(width: 8),

                // NEW: quick-access Folders chip, positioned immediately to
                // the left of the Drafts chip below. Opens a lightweight
                // picker sheet and applies the folder filter on a single
                // tap — the Filters sheet's own Folder dropdown (above)
                // still exists for people who open Filters directly.
                _FolderChip(
                  selectedFolder: widget.selectedFolder,
                  availableFolders: widget.availableFolders,
                  onFolderChanged: widget.onFolderChanged,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
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

// ── Type pill (All/Invoices/Quotes/Receipts) ───────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
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

// ── Folders quick-access chip — NEW ─────────────────────────────────────
//
// Unlike _QuickPill, this never hides itself (folders may not exist yet,
// but the chip is how a user discovers the feature in the first place).
// Shows "Folders" when nothing's selected, or the selected folder's name
// (highlighted like an active pill) once one is picked. Tapping opens
// _openFolderPicker, a lightweight bottom sheet — separate from, and
// faster than, the Folder dropdown already living in the full Filters
// sheet.

class _FolderChip extends StatelessWidget {
  final String? selectedFolder;
  final List<String> availableFolders;
  final ValueChanged<String?> onFolderChanged;

  const _FolderChip({
    required this.selectedFolder,
    required this.availableFolders,
    required this.onFolderChanged,
  });

  void _openFolderPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.folder_outlined, size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Filter by Folder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                if (availableFolders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Text(
                      "No folders yet. Long-press a document, then use its ⋮ menu's "
                      '"Move to Folder" to create one.',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  )
                else ...[
                  _FolderOptionTile(
                    label: 'All Folders',
                    selected: selectedFolder == null,
                    onTap: () {
                      onFolderChanged(null);
                      Navigator.pop(sheetContext);
                    },
                  ),
                  ...availableFolders.map(
                    (f) => _FolderOptionTile(
                      label: f,
                      selected: selectedFolder == f,
                      onTap: () {
                        onFolderChanged(f);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = selectedFolder != null;
    final label = selectedFolder ?? 'Folders';

    return GestureDetector(
      onTap: () => _openFolderPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 140),
        decoration: BoxDecoration(
          color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? cs.primary : cs.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 13,
              color: active ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6),
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
                  color: active ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Row used inside the folder picker sheet ─────────────────────────────

class _FolderOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FolderOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.folder_outlined,
              size: 18,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: cs.onSurface,
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