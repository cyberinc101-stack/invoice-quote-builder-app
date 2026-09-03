// lib/screens/splash_screen.dart
//
// REAL ICON PASS (this update): the hero graphic used to be _DocumentStack,
// a hand-drawn Flutter recreation of the QUOTE/INVOICE/RECEIPT card fan
// (three separately-built _DocCard widgets). That's now replaced with the
// app's actual icon image (assets/icon/app_icon.png -- the same artwork
// used for the launcher icon) rendered via Image.asset inside a rounded,
// drop-shadowed container, so the splash and the launcher icon are
// guaranteed to look identical instead of being two hand-maintained copies
// of the same design. _DocumentStack and _DocCard are removed since
// nothing else in the file used them. Needs assets/icon/app_icon.png
// declared under flutter/assets in pubspec.yaml.
//
// Loading splash for Invoice & Quote Builder. Single screen — no
// multi-page animation timeline, just a themed loading state while
// main() finishes its startup work, then a fade into
// LanguageSelectScreen (see language_ui_select.dart).
//
// Replaces the old splash_screen.dart, which was a leftover from the
// forked CV-builder app. Visual language here matches the home-screen
// hero card and the app's ColorScheme.fromSeed(0xFF2196F3) in main.dart:
// dark navy gradient background, the app's own icon artwork instead of
// CV-builder branding.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'language_ui_select.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    Timer(const Duration(milliseconds: 1800), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LanguageSelectScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0E1F), Color(0xFF10162E), Color(0xFF152048)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),
            Positioned(
              top: -70,
              right: -70,
              child: _Glow(color: const Color(0xFF2196F3), size: 240, alpha: 0.20),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: _Glow(color: const Color(0xFF7B1FA2), size: 200, alpha: 0.14),
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _AppIcon(),
                      const SizedBox(height: 36),
                      const Text(
                        'Invoice & Quote Builder',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Professional documents in minutes',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 48),
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App icon visual ─────────────────────────────────────────────────────
// The real launcher icon artwork, presented with rounded corners and a
// drop shadow. The shadow lives on the outer Container so it isn't
// clipped by the inner ClipRRect that rounds the image itself.

class _AppIcon extends StatelessWidget {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 136,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          'assets/icon/app_icon.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

// ─── Background decoration helpers ──────────────────────────────────────

class _Glow extends StatelessWidget {
  final Color color;
  final double size;
  final double alpha;

  const _Glow({required this.color, required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), Colors.transparent],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 0.5;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
