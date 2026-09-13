// lib/widgets/app_toasts.dart
//
// Centralized toast/SnackBar helper — one place for consistent styling
// (color, icon, shape, duration) instead of every screen hand-rolling
// its own SnackBar. Existing ad-hoc SnackBar calls elsewhere in the app
// (e.g. _EditSavedLineItemSheet._save()'s "Please enter a description.")
// are left as-is for now — migrate opportunistically rather than as one
// big-bang pass — but every NEW toast (starting with the Custom tax/
// discount name grouping notice in create_invoice_form_widgets.dart)
// should go through this instead.

import 'package:flutter/material.dart';

enum AppToastType { info, success, warning, error }

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  late final Color color;
  late final IconData icon;
  switch (type) {
    case AppToastType.info:
      color = const Color(0xFF1565C0);
      icon = Icons.info_outline_rounded;
      break;
    case AppToastType.success:
      color = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
      break;
    case AppToastType.warning:
      color = const Color(0xFFF57F17);
      icon = Icons.warning_amber_rounded;
      break;
    case AppToastType.error:
      color = const Color(0xFFC62828);
      icon = Icons.error_outline_rounded;
      break;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ),
  );
}
