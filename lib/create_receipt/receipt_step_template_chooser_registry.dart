// receipt_step_template_chooser_registry.dart
// lib/create_receipt/receipt_step_template_chooser_registry.dart
//
// Scales the real receipt layout widget down to fit a grid card — same
// OverflowBox + Transform.scale technique as
// invoice_step_template_chooser_registry.dart / quote_step_template_chooser_registry.dart.

import 'package:flutter/material.dart';
import '../document_layout_templates/01_executive/executive_receipt_stationary_layout.dart'
    show kPageW, kPageH;
import 'receipt_template_chooser_01/preview_registry.dart';

class ReceiptStepChooserScaledPreview extends StatelessWidget {
  final int templateId;
  const ReceiptStepChooserScaledPreview({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final content = buildReceiptPreview(templateId, sampleReceiptData());

    if (content == null) {
      // Stub template — no layout built yet.
      return Container(
        color: const Color(0xFFF3F4F6),
        alignment: Alignment.center,
        child: const Icon(Icons.hourglass_empty_rounded,
            color: Color(0xFFB0B7C3), size: 28),
      );
    }

    return LayoutBuilder(
      builder: (_, constraints) {
        final scale = constraints.maxWidth / kPageW;
        return OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: kPageW,
          maxHeight: kPageH,
          child: IgnorePointer(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: SizedBox(width: kPageW, height: kPageH, child: content),
            ),
          ),
        );
      },
    );
  }
}
