import 'package:flutter/material.dart';
import '../helpers/lang_helper.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';

class VeryTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onSettingsTap;
  final VoidCallback? onPremiumTap;
  final VoidCallback? onHomeTap;
  final bool showBackButton;

  const VeryTopHeader({
    super.key,
    this.onSettingsTap,
    this.onPremiumTap,
    this.onHomeTap,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    // ── Pull translations from CVProvider ────────────────────────────────────
    final t = getLang(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              showBackButton
                  ? _HeaderIconButton(
                      onTap: onHomeTap ?? () => Navigator.pop(context),
                      icon: Icons.arrow_back_rounded,
                      tooltip: t['header_tooltip_back'] ?? 'Back',
                    )
                  : _HeaderIconButton(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistoryScreen()),
                        );
                      },
                      icon: Icons.history_rounded,
                      tooltip: t['header_tooltip_my_cvs'] ?? 'My CVs',
                    ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t['header_app_title'] ?? 'CV Builder Pro',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      t['header_app_subtitle'] ?? 'Your career, perfected',
                      style: const TextStyle(
                        color: Color(0xFF90CAF9),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              _HeaderIconButton(
                onTap: onSettingsTap ?? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen()),
                  );
                },
                icon: Icons.more_vert_rounded,
                tooltip: t['header_tooltip_settings'] ?? 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String tooltip;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}