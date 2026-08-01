// invoice_step_template_chooser_registry.dart
// lib/screens/invoice_create_section/invoice_step_template_chooser_registry.dart
//
// Scales the real invoice layout widget down to fit a grid card, using the
// same OverflowBox + Transform.scale technique as the CV app's
// StepChooserScaledPreview — except here it scales the actual
// ExecutiveInvoicePreview (via buildInvoicePreview) instead of a bespoke
// mini-illustration widget, since invoice layouts are already single-page
// and cheap to render at design size.

import 'package:flutter/material.dart';
import '../../invoice_layout_templates/01_executive_cv_layout/executive_page_stationary_layout.dart'
    show kPageW, kPageH;
import 'invoice_template_chooser_01/preview_registry.dart';

class InvoiceStepChooserScaledPreview extends StatelessWidget {
  final int templateId;
  const InvoiceStepChooserScaledPreview({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final content = buildInvoicePreview(templateId, sampleInvoiceData());

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
