// document_filter_bar.dart
// lib/widgets/document_filter_bar.dart
//
// REDESIGN v3 (this pass): merges the cascading Type → Status pills with a
// full filter set — search, quick-filter chips (now including three
// overdue aging buckets), a date-range preset dropdown (with a custom-range
// date picker), a sort dropdown, and an amount-range pair of fields.
// Everything free-tier for now; gating behind RevenueCat is a later pass.
//
// ASSUMPTION: date-range and sort key off SavedInvoice/Quote/Receipt
// .lastEditedAt (a real DateTime already on every saved doc) rather than
// dueDate/issueDate/expiryDate/paymentDate, which are free-text Strings.

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

  Future<void> _pickCustomRange() async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search ──────────────────────────────────────────────────────
          TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by title, client, or number',
              hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.4)),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: cs.onSurface.withOpacity(0.5)),
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
              fillColor: cs.onSurface.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 13),
            onSubmitted: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),

          // ── Type / Status cascading pills ──────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TypePill(
                  label: 'All',
                  count: widget.invoiceCount + widget.quoteCount + widget.receiptCount,
                  selected: widget.selectedType == DocTypeFilter.all,
                  onTap: () => widget.onTypeChanged(DocTypeFilter.all),
                ),
                const SizedBox(width: 8),
                _TypePill(
                  label: 'Invoices',
                  count: widget.invoiceCount,
                  selected: widget.selectedType == DocTypeFilter.invoices,
                  onTap: () => widget.onTypeChanged(DocTypeFilter.invoices),
                ),
                const SizedBox(width: 8),
                _TypePill(
                  label: 'Quotes',
                  count: widget.quoteCount,
                  selected: widget.selectedType == DocTypeFilter.quotes,
                  onTap: () => widget.onTypeChanged(DocTypeFilter.quotes),
                ),
                const SizedBox(width: 8),
                _TypePill(
                  label: 'Receipts',
                  count: widget.receiptCount,
                  selected: widget.selectedType == DocTypeFilter.receipts,
                  onTap: () => widget.onTypeChanged(DocTypeFilter.receipts),
                ),
                if (widget.selectedType == DocTypeFilter.invoices) ...[
                  const SizedBox(width: 8),
                  _StatusDropdown<PaymentStatus>(
                    value: widget.selectedPaymentStatus,
                    items: PaymentStatus.values,
                    labelOf: (s) => s.name,
                    onChanged: widget.onPaymentStatusChanged,
                  ),
                ],
                if (widget.selectedType == DocTypeFilter.quotes) ...[
                  const SizedBox(width: 8),
                  _StatusDropdown<QuoteStatus>(
                    value: widget.selectedQuoteStatus,
                    items: QuoteStatus.values,
                    labelOf: (s) => s.name,
                    onChanged: widget.onQuoteStatusChanged,
                  ),
                ],
                if (widget.selectedType == DocTypeFilter.receipts) ...[
                  const SizedBox(width: 8),
                  _StatusDropdown<ReceiptStatus>(
                    value: widget.selectedReceiptStatus,
                    items: ReceiptStatus.values,
                    labelOf: (s) => s.name,
                    onChanged: widget.onReceiptStatusChanged,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Quick filter chips (incl. aging buckets) ───────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickChip(
                  label: quickFilterLabel(QuickFilter.needsAction),
                  count: widget.needsActionCount,
                  selected: widget.selectedQuickFilter == QuickFilter.needsAction,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.needsAction
                          ? QuickFilter.none
                          : QuickFilter.needsAction),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: quickFilterLabel(QuickFilter.overdue),
                  count: widget.overdueCount,
                  selected: widget.selectedQuickFilter == QuickFilter.overdue,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.overdue
                          ? QuickFilter.none
                          : QuickFilter.overdue),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: quickFilterLabel(QuickFilter.overdue1to30),
                  count: widget.overdue1to30Count,
                  selected: widget.selectedQuickFilter == QuickFilter.overdue1to30,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.overdue1to30
                          ? QuickFilter.none
                          : QuickFilter.overdue1to30),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: quickFilterLabel(QuickFilter.overdue31to60),
                  count: widget.overdue31to60Count,
                  selected: widget.selectedQuickFilter == QuickFilter.overdue31to60,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.overdue31to60
                          ? QuickFilter.none
                          : QuickFilter.overdue31to60),
                ),
                const SizedBox(width: 8),
                _QuickChip(
                  label: quickFilterLabel(QuickFilter.overdue61plus),
                  count: widget.overdue61plusCount,
                  selected: widget.selectedQuickFilter == QuickFilter.overdue61plus,
                  onTap: () => widget.onQuickFilterChanged(
                      widget.selectedQuickFilter == QuickFilter.overdue61plus
                          ? QuickFilter.none
                          : QuickFilter.overdue61plus),
                ),
                const SizedBox(width: 8),
                _QuickChip(
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
          const SizedBox(height: 10),

          // ── Date range / Sort / Amount range ───────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DropdownPill<DateRangePreset>(
                  icon: Icons.date_range_rounded,
                  value: widget.selectedDateRange,
                  items: DateRangePreset.values,
                  labelOf: dateRangePresetLabel,
                  onChanged: (p) {
                    if (p == DateRangePreset.custom) {
                      _pickCustomRange();
                    } else {
                      widget.onCustomRangeChanged(null, null);
                      widget.onDateRangeChanged(p);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _DropdownPill<SortOption>(
                  icon: Icons.sort_rounded,
                  value: widget.selectedSort,
                  items: SortOption.values,
                  labelOf: sortOptionLabel,
                  onChanged: widget.onSortChanged,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Min \$',
                      hintStyle: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.4)),
                      filled: true,
                      fillColor: cs.onSurface.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _submitAmountRange(),
                    onEditingComplete: _submitAmountRange,
                  ),
                ),
                const SizedBox(width: 6),
                Text('–', style: TextStyle(color: cs.onSurface.withOpacity(0.4))),
                const SizedBox(width: 6),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Max \$',
                      hintStyle: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.4)),
                      filled: true,
                      fillColor: cs.onSurface.withOpacity(0.05),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _submitAmountRange(),
                    onEditingComplete: _submitAmountRange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small building-block widgets ─────────────────────────────────────────

class _TypePill extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TypePill({
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
          color: selected ? cs.primary : cs.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _QuickChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.secondary.withOpacity(0.9) : cs.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : cs.outline.withOpacity(0.2),
          ),
        ),
        child: Text(
          '$label · $count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : cs.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _StatusDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  const _StatusDropdown({
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: value,
          isDense: true,
          hint: Text('Status', style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.6))),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: cs.onSurface.withOpacity(0.5)),
          style: TextStyle(fontSize: 12, color: cs.onSurface),
          items: [
            const DropdownMenuItem<Never>(value: null, child: Text('Any status')),
            ...items.map((i) => DropdownMenuItem<T?>(value: i, child: Text(labelOf(i)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DropdownPill<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  const _DropdownPill({
    required this.icon,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: cs.onSurface.withOpacity(0.5)),
          style: TextStyle(fontSize: 12, color: cs.onSurface),
          items: items
              .map((i) => DropdownMenuItem<T>(
                    value: i,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: cs.onSurface.withOpacity(0.5)),
                        const SizedBox(width: 6),
                        Text(labelOf(i)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}