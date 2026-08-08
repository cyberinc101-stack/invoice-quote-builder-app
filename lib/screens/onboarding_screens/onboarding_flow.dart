// lib/screens/onboarding_screens/onboarding_flow.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../home_screen.dart';
import '../../language_keys/lang_en_english.dart';
import 'onboarding_screen_1.dart';
import 'onboarding_screen_2.dart';
import 'onboarding_screen_3.dart';
import 'onboarding_screen_4.dart';

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_complete') ?? false;
}

Future<void> markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_complete', true);
}

class AppTranslations extends InheritedWidget {
  final Map<String, String> t;
  const AppTranslations({super.key, required this.t, required super.child});

  static Map<String, String> of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTranslations>()?.t ??
        enEnglish;
  }

  @override
  bool updateShouldNotify(AppTranslations old) => t != old.t;
}

class OnboardingFlow extends StatefulWidget {
  final Map<String, String> translations;
  const OnboardingFlow({super.key, this.translations = enEnglish});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with SingleTickerProviderStateMixin {
  final PageController _ctrl = PageController();
  int _page = 0;
  static const int _total = 4;

  static const List<Widget> _pages = [
    OnboardingPage1Welcome(),
    OnboardingPage2Templates(),
    OnboardingPage3Build(),
    OnboardingPage4GetStarted(),
  ];

  // Rich accent palette — one per page
  static const List<Color> _accents = [
    Color(0xFF2979FF),
    Color(0xFFE91E63),
    Color(0xFFFF6F00),
    Color(0xFF00C853),
  ];

  late final AnimationController _accentCtrl;
  late final Animation<Color?> _accentAnim;
  Color _prevAccent = _accents[0];
  Color _nextAccent = _accents[0];

  @override
  void initState() {
    super.initState();
    _accentCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _accentAnim = ColorTween(begin: _accents[0], end: _accents[0])
        .animate(CurvedAnimation(parent: _accentCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _accentCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _animateAccent(int newPage) {
    _prevAccent = _accents[_page];
    _nextAccent = _accents[newPage];
    _accentCtrl.duration = const Duration(milliseconds: 380);
    (_accentAnim as Animation<Color?>);
    // Re-drive the tween
    final tween = ColorTween(begin: _prevAccent, end: _nextAccent);
    // We re-create by rebuilding; accent read from _accents[_page] directly.
  }

  void _goTo(int page) {
    _animateAccent(page);
    _ctrl.animateToPage(page,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic);
  }

  void _next() => _page < _total - 1 ? _goTo(_page + 1) : _finish();
  void _back() { if (_page > 0) _goTo(_page - 1); }
  void _skip() => _goTo(_total - 1);

  Future<void> _finish() async {
    await markOnboardingComplete();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final accent      = _accents[_page];
    final t           = widget.translations;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return AppTranslations(
      t: t,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0A12) : const Color(0xFFF5F7FA),
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                isDark:      isDark,
                page:        _page,
                total:       _total,
                isFirst:     _page == 0,
                isLast:      _page == _total - 1,
                onBack:      _back,
                onSkip:      _skip,
                colorScheme: colorScheme,
                accent:      accent,
                t:           t,
              ),
              Expanded(
                child: PageView(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: _pages,
                ),
              ),
              _BottomBar(
                isDark:      isDark,
                page:        _page,
                total:       _total,
                isLast:      _page == _total - 1,
                accent:      accent,
                onNext:      _next,
                colorScheme: colorScheme,
                t:           t,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isDark;
  final int page, total;
  final bool isFirst, isLast;
  final VoidCallback onBack, onSkip;
  final ColorScheme colorScheme;
  final Color accent;
  final Map<String, String> t;

  const _TopBar({
    required this.isDark,
    required this.page,
    required this.total,
    required this.isFirst,
    required this.isLast,
    required this.onBack,
    required this.onSkip,
    required this.colorScheme,
    required this.accent,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final counterText = (t['onboarding_page_counter'] ?? '{current} / {total}')
        .replaceAll('{current}', '${page + 1}')
        .replaceAll('{total}', '$total');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: isFirst ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: isFirst ? null : onBack,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back_rounded,
                    color: colorScheme.onSurface, size: 18),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                counterText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: isLast ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: GestureDetector(
              onTap: isLast ? null : onSkip,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  t['onboarding_skip'] ?? 'Skip',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool isDark;
  final int page, total;
  final bool isLast;
  final Color accent;
  final VoidCallback onNext;
  final ColorScheme colorScheme;
  final Map<String, String> t;

  const _BottomBar({
    required this.isDark,
    required this.page,
    required this.total,
    required this.isLast,
    required this.accent,
    required this.onNext,
    required this.colorScheme,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF0A0A12) : const Color(0xFFF5F7FA),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        children: [
          // Dot indicators
          Row(
            children: List.generate(total, (i) {
              final isActive = i == page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(right: 6),
                width: isActive ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? accent
                      : colorScheme.onSurface.withValues(alpha: 0.15),
                ),
              );
            }),
          ),
          const Spacer(),
          // CTA button
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 52,
              padding: EdgeInsets.symmetric(horizontal: isLast ? 28 : 22),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLast) ...[
                    const Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 17),
                    const SizedBox(width: 8),
                    Text(
                      t['onboarding_get_started'] ?? 'Get Started',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ] else ...[
                    Text(
                      t['onboarding_next'] ?? 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 17),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}