// document_filter_bar.dart
// lib/widgets/document_filter_bar.dart
//
// STATUS QUICK-CHIPS (this pass): Paid (invoices) / Accepted (quotes) /
// Declined (quotes) join the always-visible quick-access row, alongside
// the existing needsAction/overdue/aging-bucket/drafts chips. All three
// route through the exact same QuickFilter plumbing filter_logic.dart
// already had wired (applyQuickFilterToInvoices/Quotes/Receipts,
// countPaid/countAccepted/countDeclined) — no new filtering logic here,
// just new required count params (paidCount, acceptedCount,
// declinedCount) and two contextual visibility booleans.
//
// Visibility is contextual, matching the exact pattern the Status
// dropdowns inside the Filters sheet already use: Paid only shows when
// Invoices (or All, with invoices present) is the selected type; Accepted
// and Declined only show when Quotes (or All, with quotes present) is
// selected. This keeps the row from permanently carrying chips that don't
// apply to whatever's currently in view. Each new chip still hides itself
// at count 0 (unless currently selected), same as the existing
// needsAction/overdue chips — reusing _QuickEntry's existing
// `.where((e) => e.count > 0 || selected)` filter rather than adding a
// second visibility mechanism.
//
// EXPENSES (earlier pass): DocTypeFilter gained a fifth value, `expenses`,
// and this bar gained a required `expensesCount` param. The "All" pill's
// count now sums invoices+quotes+receipts+expenses so it reads as the
// true total of everything Home can show. A new Expenses quick-access
// pill sits in the scrollable row immediately before the Folders chip
// (per Jesse's ask: "add the expense filter into the filter bar next to
// folders") — tapping it calls onTypeChanged(DocTypeFilter.expenses),
// same mechanism as the four existing type pills, so
// SavedDocumentsSection's existing type-filter branch just gets a fifth
// case rather than a whole separate code path. There's no Expense
// "Status" section in the Filters sheet — expenses have no payment/quote/
// receipt-style status field, only the existing Folder/Date/Sort/Amount
// sections, which already apply to expenses too via
// filterExpensesByFolder/DateRange/AmountRange/sortExpenses in
// filter_logic.dart.
//
// REDESIGN v5 + FOLDERS: v5's structure (single scrollable quick-access
// row, everything else behind one "Filters" bottom sheet) is unchanged.
// The Filters sheet has a Folder dropdown (added in an earlier pass) —
// NOT the quick-access row, so the always-visible row stayed exactly as
// compact as before. New constructor params from that pass: selectedFolder,
// onFolderChanged, availableFolders. "Clear all" also resets the folder
// filter.
//
// NEW (earlier pass): two small params so the caller (SavedDocumentsSection)
// can keep this ENTIRE bar mounted and unchanged while folder-browsing
// mode is active, instead of swapping it out for a separate header:
//   - isBrowsingFolders: when true, the "Folders" quick chip renders in
//     its active/selected state (same highlighted look a type pill gets
//     when selected), even if no selectedFolder is set yet. Previously the
//     chip only highlighted once a folder had actually been picked, which
//     gave no feedback that folder-browsing mode was currently active.
//   - searchHint: optional override for the search field's placeholder
//     text (e.g. "Search folders" while browsing folders). Defaults to the
//     usual "Search by title, client, or number" when omitted. Only the
//     text changes — the field's position, size, and styling are
//     untouched, so switching in/out of folder-browsing mode never causes
//     a layout jump.
// Both are purely cosmetic — this widget still just reports taps via
// onFoldersChipTap/onSearchChanged and lets the caller decide what they
// mean, same as before.
//
// CHANGED (earlier pass): the quick-access "Folders" chip no longer
// navigates anywhere itself — it now calls the required onFoldersChipTap
// callback, letting the parent (SavedDocumentsSection) decide what
// "tapping Folders" means. In practice that now means toggling an inline
// _browsingFolders flag so the folder grid renders in the content area
// below this same bar, instead of pushing a new screen or swapping this
// bar out. The folders_overview_screen.dart import is gone since this
// widget no longer references it directly.
//
// FIX (earlier pass): the needsAction/overdue/overdue1to30/overdue31to60/
// overdue61plus quick-filter chips each hide themselves (SizedBox.shrink())
// when their count is 0 and they're not selected — but the row used to
// always insert a SizedBox(width: 8) after every one of them regardless,
// plus the divider before the whole group, even when every single one of
// them was hidden. With all five sitting at 0 (a common state — most users
// don't have overdue/needs-action items constantly), that left a visible
// dead strip of empty spacing between the Receipts pill and the Folders
// chip, with nothing tappable in it. The quick-filter chips are now built
// into a filtered list first (only entries with count > 0 or currently
// selected survive), and the divider + inter-chip spacing is only emitted
// around chips that actually render — so a fully-empty state collapses to
// zero extra width instead of leaving a gap.
//
// FIX (earlier pass): the Status section (Payment/Quote/Receipt) only used to
// render when selectedType matched that exact pill, so with "All" selected
// — the default — no status dropdown ever showed, even when documents
// existed. Now each status dropdown shows whenever its type is selected OR
// "All" is selected and that type has documents.
//
// NEW (earlier pass): a quick-access "Folders" chip in the always-visible
// scrollable row itself, positioned immediately to the left of the Drafts
// chip. Filtering by folder was previously only reachable via the full
// Filters sheet, which buries a feature that gets used constantly once a
// user starts organizing documents.

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

  // NEW: counts backing the Paid / Accepted / Declined quick chips.
  // Contextual visibility (Paid needs Invoices/All; Accepted+Declined need
  // Quotes/All) is computed in build() from selectedType + invoiceCount/
  // quoteCount, same pattern the Filters sheet's Status dropdowns already
  // use — no separate "show" params needed here.
  final int paidCount;
  final int acceptedCount;
  final int declinedCount;

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  // NEW: optional placeholder override for the search field — lets the
  // caller relabel it (e.g. "Search folders") without altering its
  // position, size, or style. Falls back to the standard document-search
  // hint when null.
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

  // Folder filter.
  final String? selectedFolder;
  final ValueChanged<String?> onFolderChanged;
  final List<String> availableFolders;

  // Called when the quick-access "Folders" chip is tapped. This widget no
  // longer navigates on its own — the parent decides (e.g.
  // SavedDocumentsSection toggles its inline _browsingFolders flag).
  final VoidCallback onFoldersChipTap;

  // NEW: true while the caller's folder-browsing content is showing, so
  // the Folders chip can render in its active/selected state even before
  // any individual folder has been picked — giving the same "this pill is
  // currently driving what's below" feedback every other pill already
  // gives.
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _minController = TextEditingController(
        text: widget.minAmount == null ? '' : widget.minAmount!.toStringAsFixed(0));
    _maxController = TextEditingController(
        text: widget.maxAmount == null ? '' : widget.maxAmount!.toStringAsFixed(0));
  }

  // NEW: the search field is now shared between document search and
  // folder-name search (SavedDocumentsSection reuses the same
  // _searchQuery for both). When the caller toggles folder-browsing mode
  // it also clears that shared query, so this controller needs to follow
  // widget.searchQuery on external changes rather than only tracking its
  // own onChanged calls — otherwise the field would keep showing stale
  // text after the caller cleared it out from under this widget.
  @override
  void didUpdateWidget(covariant DocumentFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text &&
        widget.searchQuery != oldWidget.searchQuery) {
      _searchController.text = widget.searchQuery;
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

            // FIX: previously each Status dropdown only rendered when
            // selectedType matched that EXACT pill (Invoices/Quotes/
            // Receipts). With "All" selected — the default — none of the
            // three matched, so the whole Status section silently vanished
            // even when documents existed. Now each dropdown shows
            // whenever its type is the selected pill OR "All" is selected
            // and that type actually has documents. Expenses have no
            // status field, so there's no fourth dropdown here.
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

    // NEW: contextual visibility for the Paid / Accepted / Declined quick
    // chips — same rule the Filters sheet's Status dropdowns already use
    // (showInvoiceStatus/showQuoteStatus above): show when that type is
    // the selected pill, OR "All" is selected and that type actually has
    // documents.
    final showPaidChip = widget.selectedType == DocTypeFilter.invoices ||
        (widget.selectedType == DocTypeFilter.all && widget.invoiceCount > 0);
    final showQuoteStatusChips = widget.selectedType == DocTypeFilter.quotes ||
        (widget.selectedType == DocTypeFilter.all && widget.quoteCount > 0);

    // FIX: build the overdue/needs-action/paid/accepted/declined quick
    // chips as a filtered list first — only entries that are actually
    // going to render (contextually applicable, AND count > 0 or
    // currently the selected quick filter) survive. Spacing is then only
    // emitted between/around chips that are really there, so a fully-empty
    // state (everything at 0, nothing selected) contributes zero extra
    // width instead of a dead strip of padding.
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
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Pill(
                  label: 'All',
                  count: widget.invoiceCount + widget.quoteCount + widget.receiptCount + widget.expensesCount,
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

                // Divider between the type group and the quick-filter group.
                // FIX: only emitted when there's at least one quick-filter
                // chip about to render after it — otherwise it was pure
                // dead space between Receipts and Folders.
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

                // FIX: only chips that survived the filter render, each
                // followed by its own SizedBox(8) — no gaps left behind by
                // hidden ones.
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

                // NEW: Expenses quick pill — same _Pill widget the four
                // document type pills use, positioned immediately before
                // the Folders chip. Tapping it sets selectedType to
                // DocTypeFilter.expenses, same mechanism as All/Invoices/
                // Quotes/Receipts above.
                _Pill(
                  label: 'Expenses',
                  count: widget.expensesCount,
                  selected: widget.selectedType == DocTypeFilter.expenses,
                  onTap: () => widget.onTypeChanged(DocTypeFilter.expenses),
                ),
                const SizedBox(width: 8),

                // CHANGED: no longer navigates itself — calls
                // widget.onFoldersChipTap so the parent decides what
                // "Folders" tapped means (SavedDocumentsSection toggles its
                // inline _browsingFolders flag). isActive now considers
                // isBrowsingFolders too, so the chip highlights the moment
                // folder-browsing content is showing — not just once an
                // individual folder has been chosen.
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
              ],
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

// ── Folders quick-access chip ───────────────────────────────────────────
//
// No longer owns navigation — tapping it just calls the onTap callback
// passed in from DocumentFilterBar (which forwards widget.onFoldersChipTap).
// The parent screen decides what that means: SavedDocumentsSection toggles
// its inline _browsingFolders flag so the folder grid renders in the
// content area below this same bar, right here on the same screen, instead
// of pushing to a separate FoldersOverviewScreen or swapping this bar out.
//
// CHANGED (earlier pass): active state is now passed in explicitly via
// `isActive` (computed by the caller as isBrowsingFolders ||
// selectedFolder != null) rather than being derived here from
// selectedFolder alone — so the chip highlights as soon as folder-browsing
// content is showing, not only once a specific folder has been chosen.

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
