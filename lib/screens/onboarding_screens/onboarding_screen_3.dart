// lib/screens/onboarding_screens/onboarding_screen_3.dart

import 'package:flutter/material.dart';
import 'onboarding_flow.dart';

class OnboardingPage3Build extends StatefulWidget {
  const OnboardingPage3Build({super.key});

  @override
  State<OnboardingPage3Build> createState() => _OnboardingPage3BuildState();
}

class _OnboardingPage3BuildState extends State<OnboardingPage3Build>
    with TickerProviderStateMixin {
  late AnimationController _progressCtrl;
  late Animation<double>   _progress;
  late AnimationController _shimmerCtrl;
  late Animation<double>   _shimmer;
  int _layoutPhase = 0;

  static const Color _accent = Color(0xFFFF6F00);

  static const List<String> _sectionKeysPhase0 = [
    'ob3_section_references',
    'ob3_section_work',
    'ob3_section_skills',
    'ob3_section_education',
  ];
  static const List<String> _sectionKeysPhase1 = [
    'ob3_section_work',
    'ob3_section_education',
    'ob3_section_skills',
    'ob3_section_references',
  ];

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _progress = CurvedAnimation(parent: _progressCtrl, curve: Curves.easeInOut);
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _progressCtrl.forward();
      _runLayoutLoop();
    });
  }

  Future<void> _runLayoutLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 2000));
      if (!mounted) return;
      _shimmerCtrl.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _layoutPhase = _layoutPhase == 0 ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Color _sectionColor(String key) {
    switch (key) {
      case 'ob3_section_work':       return const Color(0xFF2979FF);
      case 'ob3_section_education':  return const Color(0xFF9C27B0);
      case 'ob3_section_skills':     return const Color(0xFFFF6F00);
      case 'ob3_section_references': return const Color(0xFF00C853);
      default:                       return Colors.white;
    }
  }

  IconData _sectionIcon(String key) {
    switch (key) {
      case 'ob3_section_work':       return Icons.work_rounded;
      case 'ob3_section_education':  return Icons.school_rounded;
      case 'ob3_section_skills':     return Icons.star_rounded;
      case 'ob3_section_references': return Icons.people_rounded;
      default:                       return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> _t = AppTranslations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final size        = MediaQuery.of(context).size;
    final visualH     = (size.height * 0.42).clamp(220.0, 340.0);

    final sectionKeys = _layoutPhase == 0 ? _sectionKeysPhase0 : _sectionKeysPhase1;

    final List<_StepDef> steps = [
      _StepDef(icon: Icons.style_rounded,          color: const Color(0xFF2979FF),
          label: _t['ob3_step1_label'] ?? 'Pick a Template',
          desc:  _t['ob3_step1_desc']  ?? 'Choose from 24+ stunning designs.'),
      _StepDef(icon: Icons.person_rounded,         color: const Color(0xFF9C27B0),
          label: _t['ob3_step2_label'] ?? 'Fill Your Details',
          desc:  _t['ob3_step2_desc']  ?? 'Guided fields for all sections.'),
      _StepDef(icon: Icons.auto_fix_high_rounded,  color: _accent,
          label: _t['ob3_step3_label'] ?? 'Smart Layout',
          desc:  _t['ob3_step3_desc']  ?? 'One tap reflows your CV perfectly.'),
      _StepDef(icon: Icons.picture_as_pdf_rounded, color: const Color(0xFF00C853),
          label: _t['ob3_step4_label'] ?? 'Export as PDF',
          desc:  _t['ob3_step4_desc']  ?? 'Pixel-perfect PDF ready to send.'),
    ];

    return Column(
      children: [
        // ── Visual panel ──────────────────────────────────────────────────
        SizedBox(
          height: visualH,
          width: double.infinity,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0C1015), Color(0xFF141E2B), Color(0xFF0D1E30)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient glow
                Positioned(top: -50, right: -50,
                  child: Container(width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _accent.withOpacity(0.1), Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                // CV preview card
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Card
                        Container(
                          width: 190,
                          height: visualH * 0.55,
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151E2E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.07)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2979FF).withOpacity(0.12),
                                blurRadius: 32, spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFF2979FF).withOpacity(0.25),
                                ),
                                const SizedBox(width: 8),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(height: 5, width: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(height: 3, width: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ]),
                              ]),
                              const SizedBox(height: 10),
                              // Sections
                              Expanded(
                                child: Column(
                                  children: sectionKeys.map((key) {
                                    final c = _sectionColor(key);
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      curve: Curves.easeInOutCubic,
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: c.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: c.withOpacity(0.25)),
                                      ),
                                      child: Row(children: [
                                        Icon(_sectionIcon(key), size: 9, color: c),
                                        const SizedBox(width: 6),
                                        Text(
                                          _t[key] ?? key,
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withOpacity(0.75),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(width: 20, height: 2.5,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                      ]),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Shimmer
                        AnimatedBuilder(
                          animation: _shimmer,
                          builder: (_, __) => ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 190,
                              height: visualH * 0.55,
                              child: Transform.translate(
                                offset: Offset(_shimmer.value * 190, 0),
                                child: Container(
                                  width: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.08),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Badge row
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      _Badge(
                        icon: Icons.auto_fix_high_rounded,
                        label: _t['ob3_badge_smart_layout'] ?? 'Smart Layout',
                        color: _accent,
                      ),
                      const SizedBox(width: 8),
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (_, __) => AnimatedOpacity(
                          opacity: _progress.value >= 0.99 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 400),
                          child: _Badge(
                            icon: Icons.check_circle_rounded,
                            label: _t['ob3_badge_cv_ready'] ?? 'CV Ready!',
                            color: const Color(0xFF00C853),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ],
            ),
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
                  _TagPill(label: _t['ob3_tag'] ?? '✦  Smart Layout', color: _accent),
                  const SizedBox(height: 12),
                  Text(
                    _t['ob3_title'] ?? 'Your CV.\nPerfectly Arranged.',
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
                    _t['ob3_body'] ??
                        'Smart Layout reorders your sections for maximum impact — putting your strongest content where recruiters look first.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 2×2 step grid
                  Row(children: [
                    Expanded(child: _StepTile(step: steps[0], isDark: isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _StepTile(step: steps[1], isDark: isDark)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _StepTile(step: steps[2], isDark: isDark, highlight: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _StepTile(step: steps[3], isDark: isDark)),
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

class _StepDef {
  final IconData icon;
  final Color color;
  final String label, desc;
  const _StepDef({required this.icon, required this.color,
      required this.label, required this.desc});
}

class _StepTile extends StatelessWidget {
  final _StepDef step;
  final bool isDark;
  final bool highlight;
  const _StepTile({required this.step, required this.isDark, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: highlight
            ? step.color.withOpacity(isDark ? 0.14 : 0.07)
            : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8F9FC)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: step.color.withOpacity(highlight ? 0.35 : 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26, height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.color.withOpacity(0.12),
            ),
            child: Icon(step.icon, size: 13, color: step.color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(step.desc,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.35,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          )),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.35)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 11),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    ]),
  );
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: color, letterSpacing: 0.2)),
  );
}