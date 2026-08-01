// smart_layout_option.dart
// lib/screens/cv_edit_section/step_customize/smart_layout_option.dart

import 'package:flutter/material.dart';
import '../../../../helpers/lang_helper.dart';

class SmartLayoutOption extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback? onTap;

  const SmartLayoutOption({
    super.key,
    this.isEnabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t        = watchLang(context);
    final dotColor = isEnabled
        ? const Color(0xFF4CAF50)  // green = on
        : const Color(0xFFEF5350); // red   = off

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isEnabled
              ? const Color(0xFF7B1FA2)
              : const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF9C27B0)
                .withOpacity(isEnabled ? 0.0 : 0.35),
            width: 1,
          ),
          boxShadow: isEnabled
              ? const [
                  BoxShadow(
                    color: Color(0x409C27B0),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: isEnabled ? Colors.white : const Color(0xFF9C27B0),
            ),
            const SizedBox(width: 5),
            Text(
              t['customize_smart_layout_btn'] ?? 'Smart Layout',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isEnabled ? Colors.white : const Color(0xFF9C27B0),
                letterSpacing: 0.1,
              ),
            ),
            // -- Status dot on the RIGHT -----------------------------------
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withOpacity(0.6),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
