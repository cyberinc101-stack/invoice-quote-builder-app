// receipt_thermal_torn_edge.dart
// lib/create_receipt/receipt_thermal_torn_edge.dart
//
// Shared torn/zigzag bottom-edge clipper for thermal receipt preview
// widgets — used by both ThermalReceiptLivePreview (real data) and the
// chooser screen's static mockup, so the two always look identical.

import 'package:flutter/material.dart';

class TornEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const toothWidth = 10.0;
    const toothHeight = 6.0;
    final path = Path()..lineTo(0, size.height - toothHeight);

    var x = 0.0;
    var up = true;
    while (x < size.width) {
      final nextX = (x + toothWidth).clamp(0.0, size.width);
      path.lineTo(nextX, up ? size.height : size.height - toothHeight);
      x = nextX;
      up = !up;
    }

    path
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
