// quote_step_template_chooser_registry.dart
// lib/screens/create_quote_section/quote_step_template_chooser_registry.dart
//
// Scales the real quote layout widget down to fit a grid card — same
// OverflowBox + Transform.scale technique as
// invoice_create_section/invoice_step_template_chooser_registry.dart.
//
// Since no quote layout is built yet, buildQuotePreview() always returns
// null right now, so every card falls through to the "Coming Soon"
// placeholder icon below. Once a real quote layout exists, this file
// doesn't need any changes — it already renders whatever
// buildQuotePreview() returns.

import 'package:flutter/material.dart';
import 'quote_template_chooser_01/preview_registry.dart';

class QuoteStepChooserScaledPreview extends StatelessWidget {
  final int templateId;
  const QuoteStepChooserScaledPreview({super.key, required this.templateId});

  @override
  Widget build(BuildContext context) {
    final content = buildQuotePreview(templateId, sampleQuoteData());

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
        final scale = constraints.maxWidth / kQuotePageW;
        return OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: kQuotePageW,
          maxHeight: kQuotePageH,
          child: IgnorePointer(
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: SizedBox(width: kQuotePageW, height: kQuotePageH, child: content),
            ),
          ),
        );
      },
    );
  }
}
