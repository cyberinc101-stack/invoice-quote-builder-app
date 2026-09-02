// lib/screens/invoice_create_section/step_create_invoice/step_create_invoice.dart
//
// INVOICE LIBRARY RESTRUCTURE PASS (this update): this step is now a
// library screen, mirroring step_customers.dart/step_templates.dart's
// pattern (header -> info banner -> "Create Invoice" button -> "Saved
// Invoices" section with Hide/Show -> cards -> "Continue to Customise"
// button in the StepNavBar) instead of being one long inline form.
//
// The actual form (invoice number, dates, currency, customer override,
// Saved Item Sets panel, line items, tax/discount, totals, notes) has
// moved into a new bottom sheet, create_invoice_bottom_sheet.dart
// (CreateInvoiceBottomSheet) — opened here via _showCreateSheet(),
// exactly the way step_customers.dart opens _CustomerSheet and
// step_templates.dart opens _TemplateSheet.
//
// This screen owns a library of SavedInvoiceDraft (invoice_data.dart),
// persisted as a single JSON-encoded SharedPreferences list under
// 'invoice_saved_draft_list' — same persistence shape as
// _kPrefCustomerList/_kPrefTemplateList/_kPrefLineItemSetList. Tapping
// "Create Invoice" opens the sheet blank (seeded only from
// widget.selectedCustomer/widget.selectedTemplate, same as before);
// saving it appends a new draft to the library and selects it. Tapping
// a saved card selects it (single-select, like Customers/Templates);
// tapping its pencil icon reopens the sheet pre-filled with that draft's
// data for further editing; tapping its trash icon deletes it.
//
// "Continue to Customise" requires a selected draft. When tapped,
// _syncSelectedToProvider() builds the same InvoiceData shape the old
// _syncToProvider() did — business info / logo resolution against
// widget.selectedTemplate and whatever's already on InvoiceProvider is
// unchanged — except invoice-specific fields (customer override, dates,
// currency, line items, tax/discount, notes) now come from the selected
// SavedInvoiceDraft.data rather than this step's own controllers, since
// this step no longer holds any of that state directly. Then it calls
// widget.onNext() exactly as before.
//
// CreateInvoiceBottomBar (create_invoice_form_widgets.dart) is no longer
// used by this step — StepNavBar (invoice_edit_widgets.dart, already
// used by step_customers.dart/step_templates.dart) takes over
// Back/Continue navigation for the whole step, matching those two
// screens exactly. CreateInvoiceBottomBar itself is left in place
// (unused but harmless) in case anything else still references it.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/invoice_models.dart';
import '../../../providers/invoice_provider.dart';
import '../invoice_edit_widgets.dart';
import 'create_invoice_form_widgets.dart';
import 'create_invoice_bottom_sheet.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _kMaxInvoiceDrafts = 100;
const _kPrefInvoiceDraftList = 'invoice_saved_draft_list';

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------
Future<void> _persistDrafts(List<SavedInvoiceDraft> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefInvoiceDraftList,
    jsonEncode(list.map((d) => d.toJson()).toList()),
  );
}

Future<List<SavedInvoiceDraft>> _loadDrafts() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefInvoiceDraftList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => SavedInvoiceDraft.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// StepCreateInvoice
// =============================================================================

class StepCreateInvoice extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Customer? selectedCustomer;
  final InvoiceTemplate? selectedTemplate;

  /// Visual PDF layout chosen in InvoiceTemplateChooserScreen (e.g. 1 =
  /// Executive). Null/unrecognized falls back to the only built layout.
  final int? layoutTemplateId;

  const StepCreateInvoice({
    super.key,
    required this.onBack,
    required this.onNext,
    this.selectedCustomer,
    this.selectedTemplate,
    this.layoutTemplateId,
  });

  @override
  State<StepCreateInvoice> createState() => _StepCreateInvoiceState();
}

class _StepCreateInvoiceState extends State<StepCreateInvoice> {
  static const _accent = Color(0xFF2196F3); // blue accent for invoices

  bool _loading = true;
  List<SavedInvoiceDraft> _library = [];
  int? _selectedIndex;
  bool _showLibraryPanel = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final drafts = await _loadDrafts();
    if (!mounted) return;
    setState(() {
      _library = drafts;
      _loading = false;
    });
  }

  void _toggleDraft(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }

  void _showCreateSheet({SavedInvoiceDraft? existing, int? editIndex}) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CreateInvoiceBottomSheet(
        selectedCustomer: widget.selectedCustomer,
        selectedTemplate: widget.selectedTemplate,
        existing: existing,
        onSaved: (draft) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = draft);
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(draft);
              _selectedIndex = newIdx;
              _showLibraryPanel = true;
            });
          }
          _persistDrafts(_library);
        },
      ),
    );
  }

  void _deleteDraft(int index) {
    setState(() {
      _library.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
    });
    _persistDrafts(_library);
  }

  // ---------------------------------------------------------------------------
  // Continue — requires a selected draft. Syncs it into InvoiceProvider
  // (business info/logo resolution unchanged from the pre-restructure
  // _syncToProvider()) then hands off to the parent flow via
  // widget.onNext(), exactly as before.
  // ---------------------------------------------------------------------------
  void _continue() {
    if (_selectedIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select or create an invoice to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _syncSelectedToProvider();
    widget.onNext();
  }

  void _syncSelectedToProvider() {
    final draft = _library[_selectedIndex!];
    final d = draft.data;
    final provider = context.read<InvoiceProvider>();
    final current = provider.invoiceData;
    final businessInfo = widget.selectedTemplate?.businessInfo;

    // LOGO OVERWRITE FIX (unchanged from the original step file): keep
    // whatever's already on the provider if it already has a logo set;
    // only pull from the template when the provider has none at all yet.
    final providerHasLogo = current.businessLogoPath != null &&
        current.businessLogoPath!.isNotEmpty;
    final useTemplateLogo = !providerHasLogo && businessInfo?.logoPath != null;

    final resolvedLogoPath =
        useTemplateLogo ? businessInfo!.logoPath : current.businessLogoPath;
    final resolvedLogoOffsetDx = useTemplateLogo
        ? businessInfo!.logoOffsetDx
        : current.businessLogoOffsetDx;
    final resolvedLogoOffsetDy = useTemplateLogo
        ? businessInfo!.logoOffsetDy
        : current.businessLogoOffsetDy;
    final resolvedLogoScale =
        useTemplateLogo ? businessInfo!.logoScale : current.businessLogoScale;
    final resolvedLogoShape =
        useTemplateLogo ? businessInfo!.logoShape : current.businessLogoShape;

    final data = InvoiceData(
      businessName: businessInfo?.name ?? current.businessName,
      businessEmail: businessInfo?.email ?? current.businessEmail,
      businessPhone: businessInfo?.phone ?? current.businessPhone,
      businessAddress: businessInfo?.address ?? current.businessAddress,
      businessLogoPath: resolvedLogoPath,
      businessLogoOffsetDx: resolvedLogoOffsetDx,
      businessLogoOffsetDy: resolvedLogoOffsetDy,
      businessLogoScale: resolvedLogoScale,
      businessLogoShape: resolvedLogoShape,
      clientName: d.clientName,
      clientEmail: d.clientEmail,
      clientPhone: d.clientPhone,
      clientAddress: d.clientAddress,
      invoiceNumber: d.invoiceNumber,
      issueDate: d.issueDate,
      dueDate: d.dueDate,
      notes: d.notes,
      currency: d.currency,
      currencySymbol: d.currencySymbol,
      currencyDisplayMode: d.currencyDisplayMode,
      lineItems: d.lineItems.map((i) => i.copyWith()).toList(),
      taxRate: d.taxRate,
      discountRate: d.discountRate,
      paymentStatus: current.paymentStatus,
      fontFamily: current.fontFamily,
      colorScheme: current.colorScheme,
      layoutTemplateId: widget.layoutTemplateId ?? current.layoutTemplateId,
    );

    provider.updateInvoiceData(data);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atMax = _library.length >= _kMaxInvoiceDrafts;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create Invoice',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Save one or more invoices, then continue with the one you want',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_loading)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${_library.length}/$_kMaxInvoiceDrafts',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: atMax
                                      ? const Color(0xFFEF5350)
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Context banner (template / customer selection) ─
                      CreateInvoiceContextBanner(
                        template: widget.selectedTemplate,
                        customer: widget.selectedCustomer,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // ── Create Invoice button ──────────────────────
                      GestureDetector(
                        onTap: atMax
                            ? () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Maximum of $_kMaxInvoiceDrafts invoices reached.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                )
                            : () => _showCreateSheet(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: atMax
                                ? (isDark
                                    ? colorScheme.surfaceContainerHighest
                                    : const Color(0xFFF5F5F5))
                                : (isDark
                                    ? const Color(0xFF0D1B2E)
                                    : const Color(0xFFE3F2FD)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: atMax
                                  ? colorScheme.outline.withValues(alpha: 0.3)
                                  : (isDark
                                      ? _accent.withValues(alpha: 0.5)
                                      : const Color(0xFF90CAF9)),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: atMax
                                    ? colorScheme.onSurface.withValues(alpha: 0.3)
                                    : _accent,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  atMax
                                      ? 'Maximum Invoices Reached'
                                      : 'Create Invoice',
                                  style: TextStyle(
                                    color: atMax
                                        ? colorScheme.onSurface
                                            .withValues(alpha: 0.3)
                                        : _accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Library header ────────────────────────────────────────
              if (!_loading && _library.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bookmark_rounded,
                                size: 16, color: _accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Saved Invoices',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _selectedIndex != null ? '1 ✓' : 'none',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedIndex != null
                                      ? _accent
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.45),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(
                                  () => _showLibraryPanel = !_showLibraryPanel),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0D1B2E)
                                      : const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _showLibraryPanel ? 'Hide' : 'Show',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: _accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      _showLibraryPanel
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: _accent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap a card to select it for this invoice.',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Draft cards ────────────────────────────────────────────
              if (!_loading && _showLibraryPanel && _library.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, displayIdx) {
                        final i = _library.length - 1 - displayIdx; // newest first
                        return _InvoiceDraftCard(
                          draft: _library[i],
                          isSelected: _selectedIndex == i,
                          onTap: () => _toggleDraft(i),
                          onEdit: () => _showCreateSheet(
                              existing: _library[i], editIndex: i),
                          onDelete: () => _deleteDraft(i),
                        );
                      },
                      childCount: _library.length,
                    ),
                  ),
                ),

              // ── Empty state ─────────────────────────────────────────
              if (!_loading && _library.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No invoices created yet',
                    sub: 'Tap above to create your first invoice',
                  ),
                ),

              if (_loading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),

        // ── Bottom nav bar (Back / Continue to Customise) ───────────────
        SafeArea(
          top: false,
          bottom: true,
          child: StepNavBar(
            onBack: widget.onBack,
            onNext: _continue,
            nextLabel: 'Continue to Customise',
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Invoice Draft Card
// =============================================================================

class _InvoiceDraftCard extends StatelessWidget {
  final SavedInvoiceDraft draft;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _accent = Color(0xFF2196F3);

  const _InvoiceDraftCard({
    required this.draft,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = draft.data;
    final currencyPrefix = d.currencySymbol.trim().isNotEmpty
        ? d.currencySymbol.trim()
        : (d.currency.trim().isNotEmpty ? '${d.currency.trim()} ' : '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF0D1B2E) : Colors.white)
            : (isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? _accent.withValues(alpha: isDark ? 0.6 : 0.5)
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: isDark ? 0.12 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? _accent
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),

              // Icon block
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? (isDark
                          ? _accent.withValues(alpha: 0.15)
                          : const Color(0xFFE3F2FD))
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  border: Border.all(
                    color: isSelected
                        ? _accent.withValues(alpha: 0.4)
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: isSelected
                      ? _accent
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.invoiceNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        d.invoiceNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? _accent
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                _accent.withValues(alpha: isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${draft.itemCount} item${draft.itemCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$currencyPrefix${draft.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edited ${draft.lastEditedDisplay()}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Selected to continue',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? _accent.withValues(alpha: 0.12)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.edit_rounded, color: _accent, size: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Color(0xFFEF5350), size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
