// lib/invoice_layout_templates/pagination/doc_field.dart
//
// Shared inline text primitive so Preview and Edit render from the exact
// same widget tree. Read-only mode = plain Text; editable mode = a
// borderless TextField bound to a caller-owned TextEditingController (the
// screen owns the controller, not this widget, so cursor position survives
// rebuilds when sibling rows are added/removed).

import 'package:flutter/material.dart';

class DocField extends StatelessWidget {
  final String value;
  final bool editable;
  final TextStyle style;
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextAlign textAlign;
  final int maxLines;
  final TextInputType? keyboardType;

  const DocField({
    super.key,
    required this.value,
    required this.editable,
    required this.style,
    this.hint = '',
    this.controller,
    this.onChanged,
    this.textAlign = TextAlign.left,
    this.maxLines = 1,
    this.keyboardType,
  }) : assert(!editable || controller != null,
            'DocField needs a controller when editable is true');

  @override
  Widget build(BuildContext context) {
    if (!editable) {
      final isEmpty = value.trim().isEmpty;
      final display = isEmpty ? hint : value;
      if (display.isEmpty) return const SizedBox.shrink();
      return Text(
        display,
        style: isEmpty
            ? style.copyWith(color: style.color?.withValues(alpha: 0.35))
            : style,
        textAlign: textAlign,
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }

    return TextField(
      controller: controller,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      cursorColor: style.color ?? Colors.black87,
      cursorHeight: (style.fontSize ?? 14) * 1.15,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        isDense: true,
        isCollapsed: true,
        hintText: hint,
        hintStyle: style.copyWith(color: style.color?.withValues(alpha: 0.35) ?? Colors.grey),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
