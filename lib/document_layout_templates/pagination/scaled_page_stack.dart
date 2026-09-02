// lib/document_layout_templates/pagination/scaled_page_stack.dart
//
// Replaces the old Transform.scale + fixed-height SizedBox pattern, which
// assumed a single page. Since documents can now span N A4 pages, height
// must adapt to however many pages A4Paginator produces. FittedBox with a
// fixed width and unconstrained height does exactly that: give it a target
// width, and it scales its child (which reports its own true multi-page
// height) down to fit that width, sizing itself to the scaled result.
//
// Use inside a SingleChildScrollView (or any parent giving loose/unbounded
// height) — never inside something that forces a fixed height, or the
// scaled result will be clipped instead of scrolling.

import 'package:flutter/material.dart';

class ScaledPageStack extends StatelessWidget {
  final double targetWidth;
  final double nativePageWidth;
  final Widget child;

  const ScaledPageStack({
    super.key,
    required this.targetWidth,
    required this.nativePageWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: targetWidth,
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: nativePageWidth,
          child: child,
        ),
      ),
    );
  }
}
