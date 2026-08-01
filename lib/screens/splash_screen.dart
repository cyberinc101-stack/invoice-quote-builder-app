// lib/screens/splash_screen.dart
//
// Branded splash screen.
// FLOW: Splash → LanguageSelectScreen → OnboardingFlow → HomeScreen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'language_ui_select.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _titleCtrl;
  late AnimationController _iconsCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _shimmerCtrl;
  late AnimationController _taglineCtrl;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _logoRotate;
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _iconsOpacity;
  late Animation<Offset> _iconsSlide;
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _pulse;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoCtrl    = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 900));
    _titleCtrl   = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _iconsCtrl   = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _taglineCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _pulseCtrl   = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2400))
      ..repeat();

    _logoScale = Tween<double>(begin: 0.35, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0.0, 0.45, curve: Curves.easeIn)));
    _logoRotate = Tween<double>(begin: -0.1, end: 0.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(
        begin: const Offset(0, 0.35), end: Offset.zero).animate(
        CurvedAnimation(parent: _titleCtrl, curve: Curves.easeOutCubic));

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOut));
    _taglineSlide = Tween<Offset>(
        begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _taglineCtrl, curve: Curves.easeOutCubic));

    _iconsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _iconsCtrl, curve: Curves.easeOut));
    _iconsSlide = Tween<Offset>(
        begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(parent: _iconsCtrl, curve: Curves.easeOutCubic));

    _pulse = Tween<double>(begin: 0.25, end: 0.65).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(begin: -1.0, end: 2.0).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    _logoCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    _titleCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    _taglineCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _iconsCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder:        (_, __, ___) => const LanguageSelectScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _titleCtrl.dispose();
    _iconsCtrl.dispose();
    _taglineCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF080C18),
      // ── Use body with a single Positioned.fill Stack ──────────────────────
      // Every layer is Positioned.fill so it spans the full screen width.
      // The content Column sits inside Positioned.fill + SafeArea.
      body: Stack(
        fit: StackFit.expand, // ← KEY FIX: forces all children to fill the stack
        children: [
          // ── Deep background gradient ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF080C18),
                  Color(0xFF0D1530),
                  Color(0xFF0A1628),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── Pulsing radial glow ───────────────────────────────────────────
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 0.75,
                  colors: [
                    const Color(0xFF1565C0).withOpacity(_pulse.value * 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Ambient glow orbs ─────────────────────────────────────────────
          Positioned(top: -80, right: -80,
            child: _GlowOrb(color: const Color(0xFF1E88E5),
                size: 260, opacity: 0.08)),
          Positioned(bottom: size.height * 0.15, left: -70,
            child: _GlowOrb(color: const Color(0xFF7C4DFF),
                size: 220, opacity: 0.07)),
          Positioned(top: size.height * 0.3, right: -40,
            child: _GlowOrb(color: const Color(0xFF00BCD4),
                size: 120, opacity: 0.05)),
          Positioned(bottom: -40, right: size.width * 0.3,
            child: _GlowOrb(color: const Color(0xFF2196F3),
                size: 160, opacity: 0.06)),

          // ── Dot grid pattern ──────────────────────────────────────────────
          CustomPaint(painter: _DotGridPainter()),

          // ── Main content ──────────────────────────────────────────────────
          // SafeArea inside Positioned.fill → full width, safe insets
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // ── Logo ────────────────────────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_logoCtrl, _pulse, _shimmerCtrl]),
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotate.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse ring
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (_, __) => Container(
                                width: 140, height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF2196F3)
                                        .withOpacity(_pulse.value * 0.4),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            // Middle ring
                            AnimatedBuilder(
                              animation: _pulse,
                              builder: (_, __) => Container(
                                width: 118, height: 118,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1565C0)
                                      .withOpacity(_pulse.value * 0.15),
                                  border: Border.all(
                                    color: const Color(0xFF2196F3)
                                        .withOpacity(_pulse.value * 0.25),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            // Icon tile with shimmer
                            Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1040A0),
                                    Color(0xFF1976D2),
                                    Color(0xFF42A5F5),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1565C0)
                                        .withOpacity(0.7),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF42A5F5)
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: Stack(children: [
                                  AnimatedBuilder(
                                    animation: _shimmer,
                                    builder: (_, __) => Positioned.fill(
                                      child: Transform.translate(
                                        offset: Offset(
                                            _shimmer.value * 160, 0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.white.withOpacity(0.18),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.5, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Center(
                                    child: Icon(Icons.description_rounded,
                                        color: Colors.white, size: 48),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── App name ─────────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _titleCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _titleOpacity,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFF90CAF9),
                            Color(0xFFFFFFFF),
                            Color(0xFF64B5F6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds),
                        child: const Text(
                          'CV Builder Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Glowing divider ───────────────────────────────────────────
                AnimatedBuilder(
                  animation: _titleCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _titleOpacity,
                    child: Container(
                      width: 56, height: 2.5,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF90CAF9)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.6),
                          blurRadius: 8,
                        )],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Tagline ───────────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _taglineCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _taglineOpacity,
                    child: SlideTransition(
                      position: _taglineSlide,
                      child: const Text(
                        'Professional CVs, made easy',
                        style: TextStyle(
                          color: Color(0xFF90A4AE),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 44),

                // ── Feature icons row ─────────────────────────────────────────
                AnimatedBuilder(
                  animation: _iconsCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _iconsOpacity,
                    child: SlideTransition(
                      position: _iconsSlide,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FeatureIcon(icon: Icons.edit_document,
                              label: 'Edit',
                              color: const Color(0xFF2196F3)),
                          const SizedBox(width: 20),
                          _FeatureIcon(icon: Icons.palette_outlined,
                              label: 'Design',
                              color: const Color(0xFF9C27B0)),
                          const SizedBox(width: 20),
                          _FeatureIcon(icon: Icons.share_rounded,
                              label: 'Share',
                              color: const Color(0xFF00BCD4)),
                          const SizedBox(width: 20),
                          _FeatureIcon(icon: Icons.workspace_premium_rounded,
                              label: 'Pro',
                              color: const Color(0xFFFFB300)),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Loading indicator — always inside SafeArea ────────────────
                AnimatedBuilder(
                  animation: _iconsCtrl,
                  builder: (_, __) => FadeTransition(
                    opacity: _iconsOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF2196F3).withOpacity(0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text('Loading...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dot grid background painter ───────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;
    const double spacing = 28;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter oldDelegate) => false;
}

// ── Private widgets ───────────────────────────────────────────────────────────

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  const _FeatureIcon(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.22), width: 1),
            boxShadow: [BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )],
          ),
          child: Icon(icon, color: color, size: 25),
        ),
        const SizedBox(height: 6),
        Text(label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color  color;
  final double size;
  final double opacity;
  const _GlowOrb(
      {required this.color, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(opacity * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}