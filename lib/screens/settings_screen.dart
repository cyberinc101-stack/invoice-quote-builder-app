import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../alerts/alert_prefs.dart';
import '../alerts/alert_type_toggles.dart';
import '../helpers/lang_helper.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'help_faq_screen.dart';
import 'language_ui_select.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguageName = 'English';
  String _selectedLanguageFlag = '\u{1F1FA}\u{1F1F8}';
  String _selectedLanguageCode = 'en';

  static const String _supportEmail = 'cyberinc101@gmail.com';
  static const String _appVersion   = '1.0.0';

  // FIX (this pass): previous flag literals were corrupted mojibake
  // ('????' for every entry). Rebuilt using Unicode regional-indicator
  // escape pairs (\u{XXXXX}\u{YYYYY}) instead of literal emoji glyphs —
  // escapes can't be mangled by terminal/clipboard encoding the way raw
  // emoji characters can, so this won't silently corrupt again on the
  // next copy/paste round-trip. Language system itself is still a stub
  // (see lib/helpers/lang_helper.dart) — this only fixes the flag icons,
  // not translation. Left as-is per decision to wire real translations
  // later, once everything else is confirmed working.
  static const Map<String, String> _flagMap = {
    'en':    '\u{1F1FA}\u{1F1F8}', // US
    'ru':    '\u{1F1F7}\u{1F1FA}', // RU
    'zh':    '\u{1F1E8}\u{1F1F3}', // CN
    'hi':    '\u{1F1EE}\u{1F1F3}', // IN
    'bn':    '\u{1F1E7}\u{1F1E9}', // BD
    'fr':    '\u{1F1EB}\u{1F1F7}', // FR
    'de':    '\u{1F1E9}\u{1F1EA}', // DE
    'ko':    '\u{1F1F0}\u{1F1F7}', // KR
    'ja':    '\u{1F1EF}\u{1F1F5}', // JP
    'tr':    '\u{1F1F9}\u{1F1F7}', // TR
    'it':    '\u{1F1EE}\u{1F1F9}', // IT
    'pt_br': '\u{1F1E7}\u{1F1F7}', // BR
    'ur':    '\u{1F1F5}\u{1F1F0}', // PK
    'he':    '\u{1F1EE}\u{1F1F1}', // IL
    'ar':    '\u{1F1F8}\u{1F1E6}', // SA
    'es':    '\u{1F1EA}\u{1F1F8}', // ES
    'es_mx': '\u{1F1F2}\u{1F1FD}', // MX
    'id':    '\u{1F1EE}\u{1F1E9}', // ID
    'ms':    '\u{1F1F2}\u{1F1FE}', // MY
    'uk':    '\u{1F1FA}\u{1F1E6}', // UA
    'pl':    '\u{1F1F5}\u{1F1F1}', // PL
    'fa':    '\u{1F1EE}\u{1F1F7}', // IR
    'sw':    '\u{1F1F0}\u{1F1EA}', // KE
    'th':    '\u{1F1F9}\u{1F1ED}', // TH
    'vi':    '\u{1F1FB}\u{1F1F3}', // VN
    'tl':    '\u{1F1F5}\u{1F1ED}', // PH
    'nl':    '\u{1F1F3}\u{1F1F1}', // NL
    'sv':    '\u{1F1F8}\u{1F1EA}', // SE
    'el':    '\u{1F1EC}\u{1F1F7}', // GR
    'ro':    '\u{1F1F7}\u{1F1F4}', // RO
    'hu':    '\u{1F1ED}\u{1F1FA}', // HU
    'cs':    '\u{1F1E8}\u{1F1FF}', // CZ
    'fi':    '\u{1F1EB}\u{1F1EE}', // FI
    'no':    '\u{1F1F3}\u{1F1F4}', // NO
    'pt':    '\u{1F1F5}\u{1F1F9}', // PT
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code  = prefs.getString('app_language_code') ?? 'en';
    final name  = prefs.getString('app_language_name') ?? 'English';
    final flag  = prefs.getString('app_language_flag') ?? (_flagMap[code] ?? '\u{1F1FA}\u{1F1F8}');
    if (mounted) {
      setState(() {
        _selectedLanguageCode = code;
        _selectedLanguageName = name;
        _selectedLanguageFlag = flag;
      });
    }
  }

  Future<void> _openLanguageSelector() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => LanguageSelectScreen(
          currentLanguageCode: _selectedLanguageCode,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLanguageCode = result['code'] as String;
        _selectedLanguageName = result['name'] as String;
        _selectedLanguageFlag = result['flag'] as String;
      });
    }
  }

  Future<void> _launchContactSupport() async {
    final t = watchLang(context);
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'Invoice & Quote Generator Pro - Support Request'},
    );
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t['settings_email_error'] ?? 'Could not open mail app.'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _launchRateApp() async {
    const String playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.invoicequotegenerator.app';
    final Uri uri = Uri.parse(playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? Theme.of(context).colorScheme.primary)
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20,
            color: iconColor ?? Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right, color: Colors.grey.shade400)
              : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t             = getLang(context);
    final themeProvider = context.watch<ThemeProvider>();
    final alertPrefs     = context.watch<AlertPrefs>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t['settings_title'] ?? 'Settings',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(t['settings_section_preferences'] ?? 'Preferences'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  onTap: _openLanguageSelector,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _selectedLanguageFlag,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  title: Text(t['settings_language_tile_title'] ?? 'Language',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    _selectedLanguageName,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing:
                      Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ),
                const Divider(height: 1, indent: 72),

                _buildTile(
                  icon: themeProvider.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconColor: themeProvider.isDark
                      ? const Color(0xFF90CAF9)
                      : const Color(0xFFFFB300),
                  title: t['settings_dark_mode_title'] ?? 'Dark Mode',
                  subtitle: themeProvider.isDark
                      ? t['settings_dark_mode_on']
                      : t['settings_dark_mode_off'],
                  trailing: Switch(
                    value: themeProvider.isDark,
                    onChanged: (_) => themeProvider.toggle(),
                    activeThumbColor: const Color(0xFF2196F3),
                  ),
                ),
                const Divider(height: 1, indent: 72),

                _buildTile(
                  icon: alertPrefs.alertsEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  iconColor: alertPrefs.alertsEnabled
                      ? const Color(0xFFD32F2F)
                      : Colors.grey,
                  title: t['settings_alerts_title'] ?? 'Alerts',
                  subtitle: t['settings_alerts_sub'] ??
                      'Overdue invoices, expiring quotes & drafts',
                  trailing: Switch(
                    value: alertPrefs.alertsEnabled,
                    onChanged: (value) => alertPrefs.setAlertsEnabled(value),
                    activeThumbColor: const Color(0xFF2196F3),
                  ),
                ),

                // NEW: per-type toggles, nested under the master switch.
                // Visually dimmed and non-interactive whenever the master
                // switch is off, since these settings have no visible
                // effect until Alerts is turned back on — but the
                // underlying values still persist, so re-enabling Alerts
                // restores whatever mix the user had configured rather
                // than resetting everything to "on".
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: alertPrefs.alertsEnabled ? 1.0 : 0.4,
                  child: IgnorePointer(
                    ignoring: !alertPrefs.alertsEnabled,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          const AlertTypeTogglesList(showHeader: true, dense: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildSectionHeader(t['settings_section_support'] ?? 'Support'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.help_outline,
                  title: t['settings_help_faq_title'] ?? 'Help & FAQ',
                  subtitle: t['settings_help_faq_sub'],
                  onTap: () => _navigateTo(const HelpFaqScreen()),
                ),
                const Divider(height: 1, indent: 72),
                _buildTile(
                  icon: Icons.mail_outline,
                  title: t['settings_contact_support_title'] ?? 'Contact Support',
                  subtitle: _supportEmail,
                  iconColor: Colors.blue,
                  onTap: _launchContactSupport,
                ),
                const Divider(height: 1, indent: 72),
                _buildTile(
                  icon: Icons.star_outline,
                  title: t['settings_rate_app_title'] ?? 'Rate the App',
                  subtitle: t['settings_rate_app_sub'],
                  iconColor: Colors.amber,
                  onTap: _launchRateApp,
                ),
              ],
            ),
          ),

          _buildSectionHeader(t['settings_section_legal'] ?? 'Legal'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.privacy_tip_outlined,
                  title: t['settings_privacy_policy_title'] ?? 'Privacy Policy',
                  onTap: () => _navigateTo(const PrivacyPolicyScreen()),
                ),
                const Divider(height: 1, indent: 72),
                _buildTile(
                  icon: Icons.description_outlined,
                  title: t['settings_terms_title'] ?? 'Terms of Service',
                  onTap: () => _navigateTo(const TermsOfServiceScreen()),
                ),
              ],
            ),
          ),

          _buildSectionHeader(t['settings_section_about'] ?? 'About'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                _buildTile(
                  icon: Icons.info_outline,
                  title: t['settings_app_version_title'] ?? 'App Version',
                  subtitle: _appVersion,
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
