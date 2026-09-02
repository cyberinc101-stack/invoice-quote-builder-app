// lib/screens/splash_screen.dart
//
// Loading splash for Invoice & Quote Builder. Single screen — no
// multi-page animation timeline, just a themed loading state while
// main() finishes its startup work, then a fade into
// LanguageSelectScreen (see language_ui_select.dart).
//
// Replaces the old splash_screen.dart, which was a leftover from the
// forked CV-builder app. Visual language here matches the home-screen
// hero card and the app's ColorScheme.fromSeed(0xFF2196F3) in main.dart:
// dark navy gradient background, a fanned stack of three document cards
// (Quote / Receipt / Invoice) instead of CV-builder branding.

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
                      const _DocumentStack(),
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

// ─── Document stack visual ──────────────────────────────────────────────

class _DocumentStack extends StatelessWidget {
  const _DocumentStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 154,
      width: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            top: 18,
            child: Transform.rotate(
              angle: -0.18,
              child: const _DocCard(
                label: 'QUOTE',
                icon: Icons.request_quote_rounded,
                gradient: LinearGradient(
                  colors: [Color(0xFFAD1457), Color(0xFFE91E63)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            right: 4,
            top: 14,
            child: Transform.rotate(
              angle: 0.18,
              child: const _DocCard(
                label: 'RECEIPT',
                icon: Icons.receipt_long_rounded,
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          const _DocCard(
            label: 'INVOICE',
            icon: Icons.description_rounded,
            gradient: LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF2196F3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            elevated: true,
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final bool elevated;

  const _DocCard({
    required this.label,
    required this.icon,
    required this.gradient,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = elevated ? 96.0 : 84.0;
    final h = elevated ? 124.0 : 108.0;

    return Container(
      width: w,
      height: h,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: elevated
            ? Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.45 : 0.25),
            blurRadius: elevated ? 26 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9),
              size: elevated ? 22 : 18),
          SizedBox(height: elevated ? 8 : 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: elevated ? 11 : 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const Spacer(),
          ...List.generate(3, (i) {
            const widths = [0.8, 0.55, 0.68];
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Container(
                height: 3,
                width: widths[i] * w * 0.7,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
          if (elevated)
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2196F3),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
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
