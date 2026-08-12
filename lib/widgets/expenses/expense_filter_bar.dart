// expense_filter_bar.dart
// lib/widgets/expenses/expense_filter_bar.dart
//
// Search + Filters bar for the Expenses screen, matching
// lib/widgets/document_filter_bar.dart's visual language (search field
// styling, "Filters" tune-icon button, bottom sheet layout) but scoped to
// what expenses actually have: Folder, Date & Sort, Amount Range. Backed
// by the existing filterExpensesByFolder/DateRange/AmountRange and
// sortExpenses helpers already in lib/filters/filter_logic.dart — this
// widget only supplies the UI and reports changes via callbacks, the same
// contract DocumentFilterBar uses (it doesn't filter anything itself).
//
// No type pills (this screen only ever shows expenses) and no Status
// section (expenses have no payment/quote/receipt-style status field) —
// those are the two things DocumentFilterBar has that don't apply here.
// Everything else — search field look, the Filters button with its active
// dot, the bottom sheet's grab handle/header/"Clear all"/Done button — is
// styled to match exactly so switching between Home and Expenses doesn't
// feel like a different app.

import 'package:flutter/material.dart';
import '../../filters/filter_types.dart';

const Color _kExpenseAccent = Color(0xFFE53935);

class ExpenseFilterBar extends StatefulWidget {
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

  final String? selectedFolder;
  final ValueChanged<String?> onFolderChanged;
  final List<String> availableFolders;

  const ExpenseFilterBar({
    super.key,
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
  State<ExpenseFilterBar> createState() => _ExpenseFilterBarState();
}

class _ExpenseFilterBarState extends State<ExpenseFilterBar> {
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
  void didUpdateWidget(covariant ExpenseFilterBar oldWidget) {
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

  bool get _hasActiveFilters =>
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Filters',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: cs.onSurface)),
                        if (_hasActiveFilters)
                          GestureDetector(
                            onTap: () {
                              widget.onDateRangeChanged(DateRangePreset.values.first);
                              widget.onCustomRangeChanged(null, null);
                              _minController.clear();
                              _maxController.clear();
                              widget.onAmountRangeChanged(null, null);
                              widget.onFolderChanged(null);
                              setSheetState(() {});
                            },
                            child: const Text('Clear all',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kExpenseAccent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Folder ─────────────────────────────────────────
                    _SheetSection(
                      label: 'Folder',
                      child: _SheetDropdown<String?>(
                        value: widget.selectedFolder,
                        hint: 'All Folders',
                        icon: Icons.folder_outlined,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Folders')),
                          ...widget.availableFolders.map((f) => DropdownMenuItem(value: f, child: Text(f))),
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
                                        child: Text(dateRangePresetLabel(p), overflow: TextOverflow.ellipsis),
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
                                        child: Text(sortOptionLabel(s), overflow: TextOverflow.ellipsis),
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

                    // ── Amount range ─────────────────────────────────────
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
                            child: Text('–', style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.35))),
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
                          backgroundColor: _kExpenseAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w700)),
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

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by vendor or reference number',
              hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.4)),
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
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
                borderSide: BorderSide(color: _kExpenseAccent.withValues(alpha: 0.55)),
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
        _FiltersButton(active: _hasActiveFilters, onTap: _openFiltersSheet),
      ],
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
          color: active ? _kExpenseAccent.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? _kExpenseAccent.withValues(alpha: 0.45) : cs.outline.withValues(alpha: 0.18),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: active ? _kExpenseAccent : cs.onSurface.withValues(alpha: 0.6),
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
                    color: _kExpenseAccent,
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
