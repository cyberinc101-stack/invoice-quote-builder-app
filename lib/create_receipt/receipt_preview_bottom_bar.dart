// receipt_preview_bottom_bar.dart
// lib/screens/receipt_preview_bottom_bar.dart

import 'package:flutter/material.dart';

class ReceiptPreviewBottomBar extends StatelessWidget {
  final Color        accent;
  final VoidCallback onExport;
  final VoidCallback onShare;
  final bool         isLoading;

  const ReceiptPreviewBottomBar({
    super.key,
    required this.accent,
    required this.onExport,
    required this.onShare,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14 + bottomPadding),
      child: isLoading
          ? Center(
              child: SizedBox(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Text('Preparing…',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accent)),
                  ],
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _FilledBtn(onTap: onExport, icon: Icons.picture_as_pdf_rounded, label: 'Save PDF', accent: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OutlineBtn(onTap: onShare, icon: Icons.ios_share_rounded, label: 'Share', accent: accent),
                ),
              ],
            ),
    );
  }
}

class _FilledBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData     icon;
  final String       label;
  final Color        accent;

  const _FilledBtn({required this.onTap, required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, accent.withOpacity(0.80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  final VoidCallback onTap;
  final IconData     icon;
  final String       label;
  final Color        accent;

  const _OutlineBtn({required this.onTap, required this.icon, required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.2),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
