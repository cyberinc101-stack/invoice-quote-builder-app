// lib/screens/onboarding_screens/onboarding_screen_1.dart

import 'package:flutter/material.dart';
import 'onboarding_flow.dart';

class OnboardingPage1Welcome extends StatelessWidget {
  const OnboardingPage1Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> _t = AppTranslations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final size        = MediaQuery.of(context).size;
    // Use 44% of screen height for visual, rest for text
    final visualH     = (size.height * 0.42).clamp(220.0, 340.0);

    return Column(
      children: [
        // ── Visual panel ──────────────────────────────────────────────────
        SizedBox(
          height: visualH,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF050B1F), Color(0xFF0A1740), Color(0xFF0F2560)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Subtle grid pattern
              CustomPaint(painter: _GridPainter()),
              // Ambient glows
              Positioned(top: -60, right: -60,
                child: Container(width: 220, height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF2979FF).withOpacity(0.18),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              Positioned(bottom: -30, left: -30,
                child: Container(width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      const Color(0xFF7C4DFF).withOpacity(0.12),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              // CV cards arrangement
              Center(
                child: SizedBox(
                  height: visualH * 0.72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Back left card
                      Positioned(
                        left: size.width * 0.06,
                        top: visualH * 0.04,
                        child: Transform.rotate(
                          angle: -0.14,
                          child: _CvCard(
                            width: 100, height: 130,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      // Back right card
                      Positioned(
                        right: size.width * 0.06,
                        top: visualH * 0.02,
                        child: Transform.rotate(
                          angle: 0.14,
                          child: _CvCard(
                            width: 100, height: 130,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      // Front main card
                      _CvCard(
                        width: 130, height: 168,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1565C0), Color(0xFF2979FF)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        showBadge: true,
                        glowColor: const Color(0xFF2979FF),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom pill
              Positioned(
                bottom: 16,
                left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFFFFD740), size: 12),
                      const SizedBox(width: 7),
                      Text(
                        _t['ob1_pill_label'] ?? 'Professional CV Builder',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Text panel ────────────────────────────────────────────────────
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF0A0A12) : Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TagPill(
                    label: _t['ob1_tag'] ?? '✦  Welcome',
                    color: const Color(0xFF2979FF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _t['ob1_title'] ?? 'Create a CV That\nOpens Doors',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t['ob1_body'] ??
                        'Stand out from hundreds of applicants. Build a polished, job-winning CV in minutes — no design skills needed.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _FeatureChip(
                      icon: Icons.style_rounded,
                      label: _t['ob1_chip_templates'] ?? '24+ Templates',
                      color: const Color(0xFF2979FF),
                      isDark: isDark,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _FeatureChip(
                      icon: Icons.picture_as_pdf_rounded,
                      label: _t['ob1_chip_pdf'] ?? 'PDF Export',
                      color: const Color(0xFF2979FF),
                      isDark: isDark,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _FeatureChip(
                      icon: Icons.star_rounded,
                      label: _t['ob1_chip_free'] ?? 'Free to Use',
                      color: const Color(0xFF2979FF),
                      isDark: isDark,
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 0.5;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}

class _CvCard extends StatelessWidget {
  final double width, height;
  final LinearGradient gradient;
  final bool showBadge;
  final Color? glowColor;

  const _CvCard({
    required this.width,
    required this.height,
    required this.gradient,
    this.showBadge = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: showBadge
            ? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: (glowColor ?? Colors.black).withOpacity(showBadge ? 0.5 : 0.25),
            blurRadius: showBadge ? 32 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(11),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: showBadge ? 13 : 9,
            backgroundColor: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: showBadge ? 5 : 3.5,
              width: showBadge ? 58 : 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: showBadge ? 3.5 : 2.5,
              width: showBadge ? 40 : 26,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 10),
        ...List.generate(5, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Container(
            height: showBadge ? 3.5 : 2.5,
            width: [0.75, 0.55, 0.68, 0.48, 0.62][i] * width * 0.85,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity([0.25, 0.18, 0.22, 0.15, 0.20][i]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
        if (showBadge) ...[
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('PDF',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2979FF),
                    letterSpacing: 0.5,
                  )),
            ),
          ),
        ],
      ]),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  final Color color;
  const _TagPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.2,
        )),
  );
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF4F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(isDark ? 0.2 : 0.12)),
      ),
      child: Column(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 5),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.55),
            )),
      ]),
    );
  }
}