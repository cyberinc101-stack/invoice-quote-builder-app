// lib/screens/onboarding_screens/onboarding_screen_2.dart

import 'package:flutter/material.dart';
import 'onboarding_flow.dart';

class OnboardingPage2Templates extends StatefulWidget {
  const OnboardingPage2Templates({super.key});

  @override
  State<OnboardingPage2Templates> createState() =>
      _OnboardingPage2TemplatesState();
}

class _OnboardingPage2TemplatesState
    extends State<OnboardingPage2Templates> {
  int _active = 1;

  static const List<_TplInfo> _templates = [
    _TplInfo(nameKey: 'ob2_tpl_executive', tagKey: 'ob2_tag_corporate',
        top: Color(0xFF0D1B4B), btm: Color(0xFF1A3A8F)),
    _TplInfo(nameKey: 'ob2_tpl_vibrant', tagKey: 'ob2_tag_creative',
        top: Color(0xFF6A0032), btm: Color(0xFFD81B60)),
    _TplInfo(nameKey: 'ob2_tpl_nordic', tagKey: 'ob2_tag_minimal',
        top: Color(0xFF0A2E12), btm: Color(0xFF388E3C)),
    _TplInfo(nameKey: 'ob2_tpl_tech_dark', tagKey: 'ob2_tag_modern',
        top: Color(0xFF050D14), btm: Color(0xFF0097A7)),
    _TplInfo(nameKey: 'ob2_tpl_luxury', tagKey: 'ob2_tag_premium',
        top: Color(0xFF1A0530), btm: Color(0xFF8E24AA)),
  ];

  @override
  Widget build(BuildContext context) {
    final Map<String, String> _t = AppTranslations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final size        = MediaQuery.of(context).size;
    final visualH     = (size.height * 0.42).clamp(220.0, 340.0);
    final active      = _templates[_active];
    final accentColor = active.btm;

    return Column(
      children: [
        // ── Visual panel ──────────────────────────────────────────────────
        SizedBox(
          height: visualH,
          width: double.infinity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [active.top, active.btm.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Ambient glow
                Positioned(
                  top: -40, right: -40,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        active.btm.withValues(alpha: 0.25),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                // Card row
                Positioned(
                  top: 0, bottom: 52, left: 0, right: 0,
                  child: Center(
                    child: SizedBox(
                      height: 220,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(_templates.length, (i) {
                          final isAct = i == _active;
                          final tpl   = _templates[i];
                          return GestureDetector(
                            onTap: () => setState(() => _active = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                              margin: EdgeInsets.symmetric(horizontal: isAct ? 6 : 3),
                              width: isAct ? 84 : 56,
                              height: isAct ? 218 : 158,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [tpl.top, tpl.btm],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: isAct
                                    ? Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2)
                                    : Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: tpl.btm.withValues(alpha: isAct ? 0.6 : 0.2),
                                    blurRadius: isAct ? 28 : 8,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(9),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: isAct ? 10 : 7,
                                    backgroundColor: Colors.white.withValues(alpha: 0.22),
                                  ),
                                  const SizedBox(height: 7),
                                  ...List.generate(3, (li) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Container(
                                      height: 3,
                                      width: isAct
                                          ? [52.0, 38.0, 44.0][li]
                                          : [34.0, 24.0, 30.0][li],
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  )),
                                  if (isAct) ...[
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.25)),
                                      ),
                                      child: Text(
                                        _t[tpl.tagKey] ?? tpl.tagKey,
                                        style: const TextStyle(
                                          fontSize: 7.5,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                // Template name + hint at bottom
                Positioned(
                  bottom: 14, left: 0, right: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Column(
                      key: ValueKey(_active),
                      children: [
                        Text(
                          _t[active.nameKey] ?? active.nameKey,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _t['ob2_tap_hint'] ?? 'Tap any template to preview',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  _TagPill(label: _t['ob2_tag'] ?? '✦  Templates', color: accentColor),
                  const SizedBox(height: 12),
                  Text(
                    _t['ob2_title'] ?? 'Every Industry.\nEvery Ambition.',
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
                    _t['ob2_body'] ??
                        'From boardroom-ready layouts to bold creative designs — a template that tells your story.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _StyleTag(label: _t['ob2_tag_corporate'] ?? 'Corporate',
                        color: const Color(0xFF1A3A8F), isDark: isDark),
                    _StyleTag(label: _t['ob2_tag_creative'] ?? 'Creative',
                        color: const Color(0xFFD81B60), isDark: isDark),
                    _StyleTag(label: _t['ob2_tag_minimal'] ?? 'Minimal',
                        color: const Color(0xFF388E3C), isDark: isDark),
                    _StyleTag(label: _t['ob2_tag_modern'] ?? 'Modern',
                        color: const Color(0xFF0097A7), isDark: isDark),
                    _StyleTag(label: _t['ob2_tag_premium'] ?? 'Premium',
                        color: const Color(0xFF8E24AA), isDark: isDark),
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

class _TplInfo {
  final String nameKey, tagKey;
  final Color top, btm;
  const _TplInfo({required this.nameKey, required this.top,
      required this.btm, required this.tagKey});
}

class _TagPill extends StatelessWidget {
  final String label;
  final Color color;
  const _TagPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(label,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2,
        )),
  );
}

class _StyleTag extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _StyleTag({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(label,
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: color,
        )),
  );
}