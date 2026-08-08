// lib/screens/onboarding_screens/onboarding_screen_4.dart

import 'package:flutter/material.dart';
import 'onboarding_flow.dart';

class OnboardingPage4GetStarted extends StatelessWidget {
  const OnboardingPage4GetStarted({super.key});

  static const Color _accent = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    final Map<String, String> _t = AppTranslations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final size        = MediaQuery.of(context).size;
    final visualH     = (size.height * 0.42).clamp(220.0, 340.0);

    final List<_Highlight> highlights = [
      _Highlight(icon: Icons.lock_outline_rounded, color: const Color(0xFF2979FF),
          title: _t['ob4_hl1_title'] ?? 'Private & Secure',
          sub:   _t['ob4_hl1_sub']   ?? 'Data stays on your device.'),
      _Highlight(icon: Icons.save_rounded, color: _accent,
          title: _t['ob4_hl2_title'] ?? 'Auto-Save',
          sub:   _t['ob4_hl2_sub']   ?? 'Every keystroke saved instantly.'),
      _Highlight(icon: Icons.description_rounded, color: const Color(0xFFFF6F00),
          title: _t['ob4_hl3_title'] ?? 'Up to 30 CVs',
          sub:   _t['ob4_hl3_sub']   ?? 'Unique CV for every role.'),
      _Highlight(icon: Icons.share_rounded, color: const Color(0xFF9C27B0),
          title: _t['ob4_hl4_title'] ?? 'One-Tap Share',
          sub:   _t['ob4_hl4_sub']   ?? 'Send PDF without leaving the app.'),
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
                colors: [Color(0xFF071410), Color(0xFF0E2818), Color(0xFF0A1F30)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glows
                Positioned(top: -50, left: -50,
                  child: Container(width: 180, height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        _accent.withValues(alpha: 0.12), Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                Positioned(bottom: -30, right: -30,
                  child: Container(width: 130, height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        const Color(0xFF2979FF).withValues(alpha: 0.10), Colors.transparent,
                      ]),
                    ),
                  ),
                ),
                // Check icon + text
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withValues(alpha: 0.12),
                      border: Border.all(
                          color: _accent.withValues(alpha: 0.45), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.2),
                          blurRadius: 30, spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded, color: _accent, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t['ob4_visual_headline'] ?? "You're All Set!",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t['ob4_visual_subline'] ?? 'Everything you need to land the job.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Stat row
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _StatBubble(
                        value: _t['ob4_stat_templates_value'] ?? '24+',
                        label: _t['ob4_stat_templates_label'] ?? 'Templates'),
                    const SizedBox(width: 8),
                    _StatBubble(
                        value: _t['ob4_stat_max_cvs_value'] ?? '30',
                        label: _t['ob4_stat_max_cvs_label'] ?? 'Max CVs'),
                    const SizedBox(width: 8),
                    _StatBubble(
                        value: _t['ob4_stat_export_value'] ?? 'PDF',
                        label: _t['ob4_stat_export_label'] ?? 'Export'),
                    const SizedBox(width: 8),
                    _StatBubble(
                        value: _t['ob4_stat_private_value'] ?? '🔒',
                        label: _t['ob4_stat_private_label'] ?? 'Private'),
                  ]),
                ]),
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
                  _TagPill(label: _t['ob4_tag'] ?? '✦  Ready to Go', color: _accent),
                  const SizedBox(height: 12),
                  Text(
                    _t['ob4_title'] ?? 'Why Top Candidates\nChoose CV Builder',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 2×2 highlight grid — fixed height to prevent overflow
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.4,
                    children: highlights
                        .map((h) => _HighlightCard(h: h, isDark: isDark, colorScheme: colorScheme))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final _Highlight h;
  final bool isDark;
  final ColorScheme colorScheme;
  const _HighlightCard({required this.h, required this.isDark, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F9FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: h.color.withValues(alpha: isDark ? 0.2 : 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: h.color.withValues(alpha: 0.12),
            ),
            child: Icon(h.icon, color: h.color, size: 15),
          ),
          const SizedBox(width: 9),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(h.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(h.sub,
                  style: TextStyle(
                    fontSize: 9.5,
                    height: 1.3,
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          )),
        ],
      ),
    );
  }
}

class _Highlight {
  final IconData icon;
  final Color color;
  final String title, sub;
  const _Highlight({required this.icon, required this.color,
      required this.title, required this.sub});
}

class _StatBubble extends StatelessWidget {
  final String value, label;
  const _StatBubble({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 9, fontWeight: FontWeight.w500)),
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
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: color, letterSpacing: 0.2)),
  );
}