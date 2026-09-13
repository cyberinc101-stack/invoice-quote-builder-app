// lib/widgets/shared_sheet_field.dart
//
// STRUCTURED ADDRESS PASS: public counterpart of the private `_SheetField`
// / `_counter` helpers duplicated identically in step_customers.dart and
// step_templates.dart. Extracted so the new AddressFieldGroup (see
// shared_address_field_group.dart) can render its six address fields with
// the exact same look, character-limit counter, "(Optional)" label suffix
// and keyboard-avoidance auto-scroll behaviour as every other field on
// those sheets.
//
// The two original private `_SheetField`/`_counter` implementations are
// left completely untouched — still used for every non-address field on
// both sheets. This is purely additive.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget sharedFieldCounter(BuildContext context, int current, int max) {
  final colorScheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(top: 4, right: 2),
    child: Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$current / $max',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: current > max
              ? const Color(0xFFF44336)
              : colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    ),
  );
}

class SharedSheetField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final String? hint;
  final IconData? icon;
  final int? max;
  final int maxLines;
  final bool required;
  final TextInputType? keyboard;
  final Color accent;
  final String? Function(String?)? validator;

  const SharedSheetField({
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
    this.validator,
  });

  @override
  State<SharedSheetField> createState() => _SharedSheetFieldState();
}

class _SharedSheetFieldState extends State<SharedSheetField> {
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
    final atLimit =
        widget.max != null && widget.ctrl.text.length >= widget.max!;
    final displayLabel =
        widget.required ? widget.label : '${widget.label} (Optional)';

    return TextFormField(
      controller: widget.ctrl,
      focusNode: _focusNode,
      keyboardType: widget.keyboard,
      maxLines: widget.maxLines,
      style: TextStyle(color: colorScheme.onSurface),
      inputFormatters: widget.max != null
          ? [LengthLimitingTextInputFormatter(widget.max!)]
          : null,
      validator: widget.validator ??
          (widget.required
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null),
      decoration: InputDecoration(
        labelText: displayLabel,
        labelStyle:
            TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        hintText: widget.hint,
        hintStyle: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.35),
            fontSize: 13),
        prefixIcon: widget.icon != null
            ? Icon(widget.icon,
                size: 20, color: colorScheme.onSurface.withValues(alpha: 0.45))
            : null,
        suffixIcon: atLimit
            ? Tooltip(
                message: 'Character limit reached',
                child: const Icon(Icons.warning_amber_rounded,
                    size: 18, color: Color(0xFFF44336)))
            : null,
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
                color:
                    atLimit ? const Color(0xFFF44336) : colorScheme.outline)),
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