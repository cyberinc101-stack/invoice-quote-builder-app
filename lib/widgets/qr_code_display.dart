// lib/widgets/qr_code_display.dart
//
// Renders a QR payload string (built by QrService.encodeExpense) in a
// branded card, with a "Copy" fallback for when the user can't hold two
// phones up to each other. Requires the qr_flutter package — see the
// pubspec.yaml note in the build summary.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrCodeDisplay extends StatelessWidget {
  final String data;
  final String title;
  final Color accentColor;

  const QrCodeDisplay({
    super.key,
    required this.data,
    required this.title,
    this.accentColor = const Color(0xFF2196F3),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2235) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(isDark ? 0.18 : 0.1), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colorScheme.onSurface)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withOpacity(0.25), width: 1.2),
            ),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: accentColor),
              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: data));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Copied to clipboard'),
                  backgroundColor: accentColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            icon: Icon(Icons.copy_rounded, size: 16, color: accentColor),
            label: Text('Copy code', style: TextStyle(color: accentColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
