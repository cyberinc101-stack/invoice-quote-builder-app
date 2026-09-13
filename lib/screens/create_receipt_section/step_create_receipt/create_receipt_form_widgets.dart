// lib/screens/create_receipt_section/step_create_receipt/create_receipt_form_widgets.dart
//
// NEW FILE — CREATE-RECEIPT UI PARITY PASS: mirrors
// create_quote_section/step_create_quote/create_quote_form_widgets.dart,
// adapted for Receipt. Named distinctly (CreateReceiptField,
// CreateReceiptDateField, etc.) from the existing ReceiptField/
// ReceiptDateField/receiptSectionHeader in ../receipt_edit_widgets.dart —
// those stay in use elsewhere (Customer/Template/Customise steps) and
// are untouched; this file's widgets are used only by
// create_receipt_bottom_sheet.dart and create_receipt_item_widgets.dart,
// same as Quote's Create* widgets are scoped to its own
// step_create_quote/ folder.
//
// Deliberately included: the Unit dropdown (Receipt's LineItem is the
// same shared class from invoice_data.dart Quote/Invoice use, so a unit
// like "hour" or "kg" is just as valid on a receipt line item).
//
// PER-ITEM TAX/DISCOUNT PASS (this update): added CreateReceiptTaxSignToggle
// and CreateReceiptRateNameField, mirroring Quote's own
// CreateQuoteTaxSignToggle/CreateQuoteRateNameField exactly (own preset
// constants so the two never share/collide state) — Receipt's LineItem
// is the same shared class Quote/Invoice use, so per-item tax/discount
// is just as valid here; see receipt_data.dart's PER-ITEM TAX/DISCOUNT
// PASS for the model-side math these back.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/invoice_data.dart' show kLineItemUnits, unitDisplayLabel;
import '../step_templates/receipt_step_template.dart' show ReceiptTemplate;
import '../step_customer/receipt_step_customer.dart' show ReceiptClient;
import '../../../widgets/app_toasts.dart';

// =============================================================================
// Context Banner (shows selected template / client from previous steps)
// =============================================================================

class CreateReceiptContextBanner extends StatelessWidget {
  final ReceiptTemplate? template;
  final ReceiptClient? client;
  final bool isDark;

  const CreateReceiptContextBanner({
    super.key,
    required this.template,
    required this.client,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasTemplate = template != null;
    final hasClient = client != null;

    if (!hasTemplate && !hasClient) {
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
            sub: template!.businessName.isNotEmpty ? template!.businessName : null,
            isDark: isDark,
          ),
        if (hasTemplate && hasClient) const SizedBox(height: 8),
        if (hasClient)
          _BannerChip(
            icon: Icons.person_rounded,
            color: const Color(0xFF2E7D32),
            label: 'Customer: ${client!.name}',
            sub: client!.email.isNotEmpty ? client!.email : null,
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
// Receipt field – reusable text field, with auto-scroll-on-focus like
// Invoice's/Quote's Create* field.
// =============================================================================

class CreateReceiptField extends StatefulWidget {
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
  final List<TextInputFormatter>? extraFormatters;

  const CreateReceiptField({
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
  State<CreateReceiptField> createState() => _CreateReceiptFieldState();
}

class _CreateReceiptFieldState extends State<CreateReceiptField> {
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

class CreateReceiptDateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color accent;

  const CreateReceiptDateField({
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
                    value.isEmpty ? '—' : value,
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
// Currency display mode selector
// =============================================================================

class CreateReceiptCurrencyDisplayModeSelector extends StatelessWidget {
  final String value;
  final Color accent;
  final ValueChanged<String> onChanged;
  final String previewCode;
  final String previewSymbol;

  const CreateReceiptCurrencyDisplayModeSelector({
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
// Unit-of-measure dropdown — shared by the draft item card and the Saved
// Item edit sheet, reads from invoice_data.dart's kLineItemUnits picklist
// so it can never drift out of sync with Invoice's/Quote's own dropdown.
// =============================================================================

class CreateReceiptUnitDropdown extends StatelessWidget {
  final String value;
  final Color accent;
  final ValueChanged<String> onChanged;

  const CreateReceiptUnitDropdown({
    super.key,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
// Tax sign toggle — whether an item's tax ADDS to the total or
// SUBTRACTS from it (withholding). Mirrors Quote's/Invoice's
// CreateQuoteTaxSignToggle/CreateInvoiceTaxSignToggle exactly.
// =============================================================================

class CreateReceiptTaxSignToggle extends StatelessWidget {
  final bool isAddition;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const CreateReceiptTaxSignToggle({
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
// Rate name field — dropdown of common presets + a "Custom…" option,
// mirrors Quote's/Invoice's CreateQuoteRateNameField/
// CreateInvoiceRateNameField exactly (own preset constants so the three
// never share/collide state).
// =============================================================================

enum CreateReceiptRateNameKind { tax, discount }

const List<String> kReceiptTaxNamePresets = [
  '',
  'GST',
  'VAT',
  'Sales Tax',
  'HST',
  'PST',
  'Withholding Tax',
];

const List<String> kReceiptDiscountNamePresets = [
  '',
  'Trade Discount',
  'Loyalty Discount',
  'Bulk Discount',
  'Employee Discount',
];

const String kReceiptRateNameCustomSentinel = '__custom__';

class CreateReceiptRateNameField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final Color accent;
  final ValueChanged<String> onChanged;
  final CreateReceiptRateNameKind kind;

  const CreateReceiptRateNameField({
    super.key,
    required this.controller,
    required this.hint,
    required this.accent,
    required this.onChanged,
    this.kind = CreateReceiptRateNameKind.tax,
  });

  @override
  State<CreateReceiptRateNameField> createState() => _CreateReceiptRateNameFieldState();
}

class _CreateReceiptRateNameFieldState extends State<CreateReceiptRateNameField> {
  late bool _customMode;
  bool _hasShownCustomToast = false;

  final FocusNode _customFocusNode = FocusNode();
  static const _retryDelaysMs = [80, 200, 350, 500];

  List<String> get _presets =>
      widget.kind == CreateReceiptRateNameKind.tax ? kReceiptTaxNamePresets : kReceiptDiscountNamePresets;

  @override
  void initState() {
    super.initState();
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
        ? kReceiptRateNameCustomSentinel
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
              value: kReceiptRateNameCustomSentinel,
              child: Text('Custom…'),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            if (v == kReceiptRateNameCustomSentinel) {
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
