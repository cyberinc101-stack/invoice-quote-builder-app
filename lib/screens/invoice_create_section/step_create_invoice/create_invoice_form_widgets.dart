// lib/screens/invoice_create_section/step_create_invoice/create_invoice_form_widgets.dart
//
// AUTO-SCROLL-ON-FOCUS PASS (this update): CreateInvoiceField (the
// shared text field used everywhere on the Create Invoice sheet —
// Container Name, Invoice Number, Currency Code/Symbol, Customer
// fields, Tax/Discount Name/%, Notes) is now a StatefulWidget that owns
// a FocusNode. On focus, it retries Scrollable.ensureVisible() at
// several points during the keyboard's rise animation
// (80/200/350/500ms) so the field scrolls up above the keyboard
// automatically — matches the identical pass already applied to
// step_customers.dart's and step_templates.dart's shared _SheetField.
// Constructor/API unchanged, so no call site needed any wiring changes.
// CreateInvoiceRateNameField's own "Custom…" free-text field (used for
// hand-typed tax/discount names) gets the same treatment below, since
// it's a separate TextFormField not routed through CreateInvoiceField.
//
// CHAR CAP PASS (earlier): the "Custom…" free-text field inside
// CreateInvoiceRateNameField is capped at 8 characters (was 20) — this
// is the single shared widget used by both the New Item draft card
// (create_invoice_item_widgets.dart) and the Saved Item edit sheet
// (create_invoice_saved_line_items_widgets.dart), so the cap applies to
// custom tax/discount names in both places at once. Also caps how much
// room a name can take in the narrow per-line rate cell on the printed
// document and in the totals breakdown labels.
//
// TAX NAME DROPDOWN PASS (earlier): CreateInvoiceRateNameField is no
// longer a plain free-text field — it's now a dropdown of common presets
// (kTaxNamePresets / kDiscountNamePresets below, picked via the new
// `kind` param) + a "Custom…" option that reveals the same free-text
// field as before. This guarantees every item using a preset name (e.g.
// "GST") produces the exact same string, so invoice_data.dart's
// itemTaxExtraByName/itemDiscountExtraByName (which group by exact
// trimmed string — unchanged, no fuzzy matching) reliably merge them
// into one totals row. Picking "Custom…" fires a one-time toast (via the
// new lib/widgets/app_toasts.dart) explaining that custom names are
// grouped by exact spelling, since that's the one case where two
// differently-typed strings ("GST" vs "gst") will still split into
// separate rows. Both call sites (create_invoice_item_widgets.dart,
// create_invoice_saved_line_items_widgets.dart) now pass `kind:` to pick
// the right preset list — everything else about the field's external
// API (controller/hint/accent/onChanged) is unchanged, so nothing else
// about those two files' wiring needed to change beyond adding `kind:`.
//
// TAX SIGN PASS (earlier): added CreateInvoiceTaxSignToggle — a
// compact +/− segmented control choosing whether an item's tax adds to
// the total (sales tax) or subtracts from it (a withholding tax), writing
// to LineItem.itemTaxIsAddition. Shared by the New Item draft card and
// the Saved Item edit sheet, same reasoning as CreateInvoiceUnitDropdown
// below.
//
// UNIT OF MEASURE PASS (earlier): added CreateInvoiceUnitDropdown —
// a shared dropdown reading from invoice_data.dart's kLineItemUnits
// picklist (pulled in transitively via the existing invoice_models.dart
// import below, same as every other model type this file already uses),
// so both the New Item draft card (create_invoice_item_widgets.dart) and
// the Saved Item edit sheet (create_invoice_saved_line_items_widgets.
// dart) render the exact same option list and label text, and can never
// drift out of sync with each other or with the UNIT column rendered on
// the actual document (executive_invoice_stationary_layout.dart).
//
// FILE SPLIT (earlier): extracted from the former single
// step_create_invoice.dart (was _InvoiceField, _DateField,
// _ContextBanner/_BannerChip, _InvoiceCurrencyDisplayModeSelector,
// _InvoiceBottomBar — now public as CreateInvoiceField,
// CreateInvoiceDateField, CreateInvoiceContextBanner,
// CreateInvoiceCurrencyDisplayModeSelector, CreateInvoiceBottomBar so
// step_create_invoice.dart can import them). _BannerChip stays private —
// it's only ever used by CreateInvoiceContextBanner in this same file.
// No behavior changed — only location and class names.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/invoice_models.dart';
import '../../../widgets/app_toasts.dart';

// =============================================================================
// Context Banner (shows selected template / customer from previous steps)
// =============================================================================

class CreateInvoiceContextBanner extends StatelessWidget {
  final InvoiceTemplate? template;
  final Customer? customer;
  final bool isDark;

  const CreateInvoiceContextBanner({
    super.key,
    required this.template,
    required this.customer,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTemplate = template != null;
    final hasCustomer = customer != null;

    if (!hasTemplate && !hasCustomer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2200) : const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark
                  ? const Color(0xFFFFE082).withValues(alpha: 0.4)
                  : const Color(0xFFFFE082)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded,
                size: 14, color: Color(0xFFF57F17)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No template or customer selected. You can fill in details manually below.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFFFFA726)
                      : const Color(0xFF795548),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (hasTemplate)
          _BannerChip(
            icon: Icons.description_rounded,
            color: const Color(0xFF1565C0),
            label: 'Template: ${template!.name}',
            sub: (template!.businessInfo.name.isNotEmpty)
                ? template!.businessInfo.name
                : null,
            isDark: isDark,
          ),
        if (hasTemplate && hasCustomer) const SizedBox(height: 8),
        if (hasCustomer)
          _BannerChip(
            icon: Icons.person_rounded,
            color: const Color(0xFF2E7D32),
            label: 'Customer: ${customer!.name}',
            sub: customer!.email.isNotEmpty ? customer!.email : null,
            isDark: isDark,
          ),
      ],
    );
  }
}

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? sub;
  final bool isDark;

  const _BannerChip({
    required this.icon,
    required this.color,
    required this.label,
    this.sub,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              size: 16, color: Color(0xFF4CAF50)),
        ],
      ),
    );
  }
}

// =============================================================================
// Invoice field – reusable text field
//
// AUTO-SCROLL-ON-FOCUS PASS: converted from StatelessWidget to
// StatefulWidget so each field can own a FocusNode and, on focus, retry
// Scrollable.ensureVisible() at several points during the keyboard's
// rise animation (80/200/350/500ms) rather than guessing once. See file
// header comment. Constructor/API is unchanged.
// =============================================================================

class CreateInvoiceField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData? icon;
  final int? max;
  final int maxLines;
  final bool required;
  final TextInputType? keyboard;
  final Color accent;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final String? Function(String?)? validator;

  /// Additional formatters to apply alongside the length limiter -- e.g.
  /// Tax %/Discount % pass a digit-only RegExp formatter here.
  final List<TextInputFormatter>? extraFormatters;

  const CreateInvoiceField({
    super.key,
    required this.ctrl,
    required this.label,
    required this.accent,
    this.hint,
    this.icon,
    this.max,
    this.maxLines = 1,
    this.required = false,
    this.keyboard,
    this.onChanged,
    this.suffix,
    this.validator,
    this.extraFormatters,
  });

  @override
  State<CreateInvoiceField> createState() => _CreateInvoiceFieldState();
}

class _CreateInvoiceFieldState extends State<CreateInvoiceField> {
  final FocusNode _focusNode = FocusNode();

  static const _retryDelaysMs = [80, 200, 350, 500];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) return;
    for (final delayMs in _retryDelaysMs) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted || !_focusNode.hasFocus) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.2,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atLimit = widget.max != null && widget.ctrl.text.length >= widget.max!;

    return TextFormField(
      controller: widget.ctrl,
      focusNode: _focusNode,
      keyboardType: widget.keyboard,
      maxLines: widget.maxLines,
      style: TextStyle(color: colorScheme.onSurface),
      inputFormatters: [
        if (widget.extraFormatters != null) ...widget.extraFormatters!,
        if (widget.max != null) LengthLimitingTextInputFormatter(widget.max!),
      ],
      onChanged: widget.onChanged,
      validator: widget.validator ??
          (widget.required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle:
            TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        hintText: widget.hint,
        hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.35), fontSize: 13),
        prefixIcon: widget.icon != null
            ? Icon(widget.icon, size: 20,
                color: colorScheme.onSurface.withValues(alpha: 0.45))
            : null,
        suffixIcon: widget.suffix ??
            (atLimit
                ? Tooltip(
                    message: 'Character limit reached',
                    child: const Icon(Icons.warning_amber_rounded,
                        size: 18, color: Color(0xFFF44336)))
                : null),
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: atLimit
                    ? const Color(0xFFF44336)
                    : colorScheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: atLimit ? const Color(0xFFF44336) : widget.accent,
                width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFF44336))),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// =============================================================================
// Date tap field
// =============================================================================

class CreateInvoiceDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color accent;

  const CreateInvoiceDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withValues(alpha: 0.45)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                        fontSize: 14, color: colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Currency display mode selector — segmented Code / Symbol / Both control
// with a live preview, mirroring step_customers.dart's
// _CurrencyDisplayModeSelector. Kept private/self-contained here rather
// than shared, matching this app's existing per-flow widget pattern.
// =============================================================================

class CreateInvoiceCurrencyDisplayModeSelector extends StatelessWidget {
  final String value; // 'code' | 'symbol' | 'both'
  final Color accent;
  final ValueChanged<String> onChanged;
  final String previewCode;
  final String previewSymbol;

  const CreateInvoiceCurrencyDisplayModeSelector({
    super.key,
    required this.value,
    required this.accent,
    required this.onChanged,
    required this.previewCode,
    required this.previewSymbol,
  });

  String _previewFor(String mode) {
    const amount = '200.00';
    final hasSymbol = previewSymbol.trim().isNotEmpty;
    final hasCode = previewCode.trim().isNotEmpty;
    switch (mode) {
      case 'symbol':
        return hasSymbol ? '$previewSymbol$amount' : (hasCode ? '$previewCode $amount' : amount);
      case 'both':
        if (hasSymbol && hasCode) return '$previewCode $previewSymbol$amount';
        if (hasSymbol) return '$previewSymbol$amount';
        return hasCode ? '$previewCode $amount' : amount;
      case 'code':
      default:
        return hasCode ? '$previewCode $amount' : (hasSymbol ? '$previewSymbol$amount' : amount);
    }
  }

  static const _options = [
    ('code', 'Code'),
    ('symbol', 'Symbol'),
    ('both', 'Both'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Format',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: _options.map((opt) {
              final (mode, label) = opt;
              final selected = value == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: selected ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _previewFor(mode),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? Colors.white.withValues(alpha: 0.85)
                                : colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Unit-of-measure dropdown — shared by the New Item draft card
// (create_invoice_item_widgets.dart) and the Saved Item edit sheet
// (create_invoice_saved_line_items_widgets.dart), so both read from the
// exact same kLineItemUnits picklist and unitDisplayLabel() text
// (invoice_data.dart) and can never drift out of sync with each other or
// with the UNIT column rendered on the actual document.
//
// UNIT OF MEASURE PASS: new widget. When 'custom' is selected, the
// caller is responsible for showing its own free-text field for
// customUnitLabel right below this (kept separate rather than baked in
// here, since the two call sites lay out that follow-up field slightly
// differently).
// =============================================================================

class CreateInvoiceUnitDropdown extends StatelessWidget {
  final String value; // one of kLineItemUnits
  final Color accent;
  final ValueChanged<String> onChanged;

  const CreateInvoiceUnitDropdown({
    super.key,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Defensive: if a persisted/unknown unit key ever shows up that
    // isn't in the current picklist, fall back to '' rather than
    // crashing DropdownButtonFormField on a value with no matching item.
    final safeValue = kLineItemUnits.contains(value) ? value : '';

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      isExpanded: true,
      style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
      dropdownColor: isDark ? const Color(0xFF23233A) : Colors.white,
      icon: Icon(Icons.expand_more_rounded, size: 18,
          color: colorScheme.onSurface.withValues(alpha: 0.45)),
      decoration: InputDecoration(
        labelText: 'Unit',
        labelStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
        filled: true,
        fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: accent, width: 1.5)),
      ),
      items: kLineItemUnits
          .map((u) => DropdownMenuItem(
                value: u,
                child: Text(
                  unitDisplayLabel(u),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// =============================================================================
// Tax sign toggle — whether an item's tax ADDS to the total (ordinary
// sales tax, the default) or SUBTRACTS from it (a withholding tax).
// Shared by the New Item draft card (create_invoice_item_widgets.dart)
// and the Saved Item edit sheet (create_invoice_saved_line_items_widgets.
// dart), same reasoning as CreateInvoiceUnitDropdown above — one shared
// widget so both read/write LineItem.itemTaxIsAddition identically and
// can never look or behave differently from each other.
//
// TAX SIGN PASS: new widget. Deliberately shown only while the caller's
// Tax switch is on — a sign has no meaning for a disabled rate — so this
// widget itself doesn't gate on that; the two call sites already wrap it
// in `if (item.taxEnabled) ...` the same way they already gate the %
// input.
// =============================================================================

class CreateInvoiceTaxSignToggle extends StatelessWidget {
  final bool isAddition; // true = adds to total, false = subtracts (withholding)
  final Color accent;
  final ValueChanged<bool> onChanged;

  const CreateInvoiceTaxSignToggle({
    super.key,
    required this.isAddition,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget segment(bool value, IconData icon, String tooltip) {
      final selected = isAddition == value;
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 15,
                color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(true, Icons.add_rounded, 'Adds to total (sales tax)'),
          segment(false, Icons.remove_rounded, 'Subtracts from total (withholding tax)'),
        ],
      ),
    );
  }
}

// =============================================================================
// Rate name field — dropdown of common presets ("GST", "VAT", "Sales
// Tax"… for tax; "Trade Discount", "Early Payment Discount"… for
// discount) + a "Custom…" option that reveals a free-text field, shown
// beneath the Tax/Discount switch while it's on, on both the New Item
// draft card and the Saved Item edit sheet. The actual text lives on
// LineItem.itemTaxName or itemDiscountName depending on which switch
// it's attached to — the caller decides which controller/onChanged pair
// to bind and which `kind` (tax vs discount) picks the right preset
// list; this widget doesn't otherwise know or care which field it's
// naming.
//
// AUTO-SCROLL-ON-FOCUS PASS (this update): the "Custom…" free-text field
// below now owns a FocusNode with the same retry-based
// Scrollable.ensureVisible() behaviour as CreateInvoiceField above,
// since it's a separate TextFormField not routed through that widget.
//
// CHAR CAP PASS (earlier): the "Custom…" free-text field is capped
// at 8 characters (was 20) — keeps a hand-typed name short enough to fit
// cleanly in the narrow per-line rate cell on the printed document and
// in the totals breakdown labels, and matches the same cap applied to
// the whole-invoice Tax Name/Discount Name fields on the Create Invoice
// sheet.
//
// TAX NAME DROPDOWN PASS (earlier): replaces the previous plain
// TextFormField. Presets guarantee identical strings across items (so
// invoice_data.dart's itemTaxExtraByName/itemDiscountExtraByName —
// unchanged, exact-string grouping — reliably merge same-named items
// into one totals row). Picking "Custom…" reveals the same free-text
// field the old version always showed, and fires a one-time toast (see
// lib/widgets/app_toasts.dart) explaining that custom names only group
// by exact spelling, since typos/case differences there ("GST" vs
// "gst") will still produce separate totals rows — that's the one case
// a fixed preset list can't protect against.
// =============================================================================

enum CreateInvoiceRateNameKind { tax, discount }

/// Preset tax names. '' (No name) is deliberately first, same convention
/// as kLineItemUnits — an unnamed rate is a valid, common choice and
/// renders as the plain "Tax"/"Item Tax" row every existing item already
/// shows.
const List<String> kTaxNamePresets = [
  '',
  'GST',
  'VAT',
  'Sales Tax',
  'HST',
  'PST',
  'Withholding Tax',
];

/// Preset discount names — same '' (No name) first convention.
const List<String> kDiscountNamePresets = [
  '',
  'Trade Discount',
  'Early Payment Discount',
  'Bulk Discount',
  'Loyalty Discount',
];

/// Sentinel dropdown value for "Custom…" — never itself written to
/// LineItem.itemTaxName/itemDiscountName (those only ever hold '', a
/// preset, or genuine free-typed text), purely an internal marker for
/// which branch of the dropdown is selected.
const String kRateNameCustomSentinel = '__custom__';

class CreateInvoiceRateNameField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Color accent;
  final ValueChanged<String> onChanged;
  final CreateInvoiceRateNameKind kind;

  const CreateInvoiceRateNameField({
    super.key,
    required this.controller,
    required this.hint,
    required this.accent,
    required this.onChanged,
    this.kind = CreateInvoiceRateNameKind.tax,
  });

  @override
  State<CreateInvoiceRateNameField> createState() => _CreateInvoiceRateNameFieldState();
}

class _CreateInvoiceRateNameFieldState extends State<CreateInvoiceRateNameField> {
  late bool _customMode;
  bool _hasShownCustomToast = false;

  // AUTO-SCROLL-ON-FOCUS PASS: same retry-based ensureVisible behaviour
  // as CreateInvoiceField, applied here since the "Custom…" text field
  // below is its own separate TextFormField.
  final FocusNode _customFocusNode = FocusNode();
  static const _retryDelaysMs = [80, 200, 350, 500];

  List<String> get _presets =>
      widget.kind == CreateInvoiceRateNameKind.tax ? kTaxNamePresets : kDiscountNamePresets;

  @override
  void initState() {
    super.initState();
    // Existing items saved before this pass (or a genuinely custom name
    // typed since) won't match any preset — open straight into custom
    // mode so their text is never silently hidden/lost.
    _customMode = widget.controller.text.isNotEmpty && !_presets.contains(widget.controller.text);
    _customFocusNode.addListener(_onCustomFocusChange);
  }

  void _onCustomFocusChange() {
    if (!_customFocusNode.hasFocus) return;
    for (final delayMs in _retryDelaysMs) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted || !_customFocusNode.hasFocus) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.2,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _selectPreset(String value) {
    setState(() => _customMode = false);
    widget.controller.text = value;
    widget.onChanged(value);
  }

  void _selectCustom() {
    final wasPreset = _presets.contains(widget.controller.text);
    setState(() => _customMode = true);
    if (wasPreset) {
      // Switching away from a preset into Custom — clear so the person
      // types a fresh name rather than silently keeping the preset text
      // under a now-editable field.
      widget.controller.clear();
      widget.onChanged('');
    }
    if (!_hasShownCustomToast) {
      _hasShownCustomToast = true;
      showAppToast(
        context,
        'Custom names are grouped by exact spelling — "GST" and "gst" will show as separate totals.',
        type: AppToastType.info,
      );
    }
  }

  void _exitCustomBackToPresets() {
    setState(() => _customMode = false);
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  void dispose() {
    _customFocusNode.removeListener(_onCustomFocusChange);
    _customFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentDropdownValue = _customMode
        ? kRateNameCustomSentinel
        : (_presets.contains(widget.controller.text) ? widget.controller.text : '');

    InputDecoration fieldDeco({String? hintText, Widget? suffixIcon}) => InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.35)),
          isDense: true,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          filled: true,
          fillColor: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF9F9F9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outline)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.outline)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: widget.accent, width: 1.5)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: currentDropdownValue,
          isExpanded: true,
          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
          dropdownColor: isDark ? const Color(0xFF23233A) : Colors.white,
          icon: Icon(Icons.expand_more_rounded, size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.45)),
          decoration: fieldDeco(hintText: widget.hint),
          items: [
            ..._presets.map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(p.isEmpty ? 'No name' : p, overflow: TextOverflow.ellipsis),
              ),
            ),
            const DropdownMenuItem(
              value: kRateNameCustomSentinel,
              child: Text('Custom…'),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            if (v == kRateNameCustomSentinel) {
              _selectCustom();
            } else {
              _selectPreset(v);
            }
          },
        ),
        if (_customMode) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller,
            focusNode: _customFocusNode,
            autofocus: true,
            onChanged: widget.onChanged,
            style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface),
            inputFormatters: [LengthLimitingTextInputFormatter(8)],
            decoration: fieldDeco(
              hintText: widget.hint,
              suffixIcon: Tooltip(
                message: 'Back to presets',
                child: GestureDetector(
                  onTap: _exitCustomBackToPresets,
                  child: Icon(Icons.close_rounded, size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Bottom action bar
// =============================================================================

class CreateInvoiceBottomBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const CreateInvoiceBottomBar({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20, MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: const [
          BoxShadow(
              color: Color(0x10000000),
              blurRadius: 12,
              offset: Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          // Back
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.55), size: 22),
            ),
          ),
          const SizedBox(width: 10),

          // Continue
          Expanded(
            child: GestureDetector(
              onTap: onContinue,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x501565C0),
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Continue',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}