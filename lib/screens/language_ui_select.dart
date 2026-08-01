// lib/screens/language_ui_select.dart
//
// Language selector screen.
// Flow: Splash → THIS SCREEN → OnboardingFlow → HomeScreen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_flags/country_flags.dart';
import '../providers/invoice_provider.dart';
import 'onboarding_screens/onboarding_flow.dart';

// -- Language translation maps -------------------------------------------------
import '../language_keys/lang_en_english.dart';
import '../language_keys/lang_ru_russian.dart';
import '../language_keys/lang_zh_chinese.dart';
import '../language_keys/lang_hi_hindi.dart';
import '../language_keys/lang_bn_bengali.dart';
import '../language_keys/lang_fr_french.dart';
import '../language_keys/lang_de_german.dart';
import '../language_keys/lang_ko_korean.dart';
import '../language_keys/lang_ja_japanese.dart';
import '../language_keys/lang_tr_turkish.dart';
import '../language_keys/lang_it_italian.dart';
import '../language_keys/lang_pt_br_brazilian.dart';
import '../language_keys/lang_ur_urdu.dart';
import '../language_keys/lang_he_hebrew.dart';
import '../language_keys/lang_ar_arabic.dart';
import '../language_keys/lang_es_spanish.dart';
import '../language_keys/lang_es_mx_mexican.dart';
import '../language_keys/lang_id_indonesian.dart';
import '../language_keys/lang_ms_malay.dart';
import '../language_keys/lang_uk_ukrainian.dart';
import '../language_keys/lang_pl_polish.dart';
import '../language_keys/lang_fa_persian.dart';
import '../language_keys/lang_sw_swahili.dart';
import '../language_keys/lang_th_thai.dart';
import '../language_keys/lang_vi_vietnamese.dart';
import '../language_keys/lang_tl_filipino.dart';
import '../language_keys/lang_nl_dutch.dart';
import '../language_keys/lang_sv_swedish.dart';
import '../language_keys/lang_el_greek.dart';
import '../language_keys/lang_ro_romanian.dart';
import '../language_keys/lang_hu_hungarian.dart';
import '../language_keys/lang_cs_czech.dart';
import '../language_keys/lang_fi_finnish.dart';
import '../language_keys/lang_no_norwegian.dart';
import '../language_keys/lang_pt_portuguese.dart';

class LanguageSelectScreen extends StatefulWidget {
  final String? currentLanguageCode;

  const LanguageSelectScreen({Key? key, this.currentLanguageCode})
      : super(key: key);

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  late String _selectedCode;

  static const Map<String, Map<String, String>> _translationMap = {
    'en'    : enEnglish,
    'ru'    : ruRussian,
    'zh'    : zhChinese,
    'hi'    : hiHindi,
    'bn'    : bnBengali,
    'fr'    : frFrench,
    'de'    : deGerman,
    'ko'    : koKorean,
    'ja'    : jaJapanese,
    'tr'    : trTurkish,
    'it'    : itItalian,
    'pt_br' : ptBrBrazilian,
    'ur'    : urUrdu,
    'he'    : heHebrew,
    'ar'    : arArabic,
    'es'    : esSpanish,
    'es_mx' : esMxMexican,
    'id'    : idIndonesian,
    'ms'    : msMalay,
    'uk'    : ukUkrainian,
    'pl'    : plPolish,
    'fa'    : faPersian,
    'sw'    : swSwahili,
    'th'    : thThai,
    'vi'    : viVietnamese,
    'tl'    : tlFilipino,
    'nl'    : nlDutch,
    'sv'    : svSwedish,
    'el'    : elGreek,
    'ro'    : roRomanian,
    'hu'    : huHungarian,
    'cs'    : csCzech,
    'fi'    : fiFinnish,
    'no'    : noNorwegian,
    'pt'    : ptPortuguese,
  };

  static const List<Map<String, String>> _languages = [
    {'code': 'en',    'name': 'English',               'country': 'United States',  'flag': '🇺🇸', 'native': 'English'},
    {'code': 'ru',    'name': 'Russian',               'country': 'Russia',         'flag': '🇷🇺', 'native': 'Русский'},
    {'code': 'zh',    'name': 'Mandarin Chinese',      'country': 'China',          'flag': '🇨🇳', 'native': '中文'},
    {'code': 'hi',    'name': 'Hindi',                 'country': 'India',          'flag': '🇮🇳', 'native': 'हिन्दी'},
    {'code': 'bn',    'name': 'Bengali',               'country': 'Bangladesh',     'flag': '🇧🇩', 'native': 'বাংলা'},
    {'code': 'fr',    'name': 'French',                'country': 'France',         'flag': '🇫🇷', 'native': 'Français'},
    {'code': 'de',    'name': 'German',                'country': 'Germany',        'flag': '🇩🇪', 'native': 'Deutsch'},
    {'code': 'ko',    'name': 'Korean',                'country': 'South Korea',    'flag': '🇰🇷', 'native': '한국어'},
    {'code': 'ja',    'name': 'Japanese',              'country': 'Japan',          'flag': '🇯🇵', 'native': '日本語'},
    {'code': 'tr',    'name': 'Turkish',               'country': 'Turkey',         'flag': '🇹🇷', 'native': 'Türkçe'},
    {'code': 'it',    'name': 'Italian',               'country': 'Italy',          'flag': '🇮🇹', 'native': 'Italiano'},
    {'code': 'pt_br', 'name': 'Portuguese (Brazil)',   'country': 'Brazil',         'flag': '🇧🇷', 'native': 'Português Brasileiro'},
    {'code': 'ur',    'name': 'Urdu',                  'country': 'Pakistan',       'flag': '🇵🇰', 'native': 'اردو'},
    {'code': 'he',    'name': 'Hebrew',                'country': 'Israel',         'flag': '🇮🇱', 'native': 'עברית'},
    {'code': 'ar',    'name': 'Arabic',                'country': 'Egypt',          'flag': '🇪🇬', 'native': 'العربية'},
    {'code': 'es',    'name': 'Spanish',               'country': 'Spain',          'flag': '🇪🇸', 'native': 'Español'},
    {'code': 'es_mx', 'name': 'Spanish (Mexico)',      'country': 'Mexico',         'flag': '🇲🇽', 'native': 'Español Mexicano'},
    {'code': 'id',    'name': 'Indonesian',            'country': 'Indonesia',      'flag': '🇮🇩', 'native': 'Bahasa Indonesia'},
    {'code': 'ms',    'name': 'Malay',                 'country': 'Malaysia',       'flag': '🇲🇾', 'native': 'Bahasa Melayu'},
    {'code': 'uk',    'name': 'Ukrainian',             'country': 'Ukraine',        'flag': '🇺🇦', 'native': 'Українська'},
    {'code': 'pl',    'name': 'Polish',                'country': 'Poland',         'flag': '🇵🇱', 'native': 'Polski'},
    {'code': 'fa',    'name': 'Persian',               'country': 'Iran',           'flag': '🇮🇷', 'native': 'فارسی'},
    {'code': 'sw',    'name': 'Swahili',               'country': 'Kenya',          'flag': '🇰🇪', 'native': 'Kiswahili'},
    {'code': 'th',    'name': 'Thai',                  'country': 'Thailand',       'flag': '🇹🇭', 'native': 'ภาษาไทย'},
    {'code': 'vi',    'name': 'Vietnamese',            'country': 'Vietnam',        'flag': '🇻🇳', 'native': 'Tiếng Việt'},
    {'code': 'tl',    'name': 'Filipino',              'country': 'Philippines',    'flag': '🇵🇭', 'native': 'Filipino'},
    {'code': 'nl',    'name': 'Dutch',                 'country': 'Netherlands',    'flag': '🇳🇱', 'native': 'Nederlands'},
    {'code': 'sv',    'name': 'Swedish',               'country': 'Sweden',         'flag': '🇸🇪', 'native': 'Svenska'},
    {'code': 'el',    'name': 'Greek',                 'country': 'Greece',         'flag': '🇬🇷', 'native': 'Ελληνικά'},
    {'code': 'ro',    'name': 'Romanian',              'country': 'Romania',        'flag': '🇷🇴', 'native': 'Română'},
    {'code': 'hu',    'name': 'Hungarian',             'country': 'Hungary',        'flag': '🇭🇺', 'native': 'Magyar'},
    {'code': 'cs',    'name': 'Czech',                 'country': 'Czech Republic', 'flag': '🇨🇿', 'native': 'Čeština'},
    {'code': 'fi',    'name': 'Finnish',               'country': 'Finland',        'flag': '🇫🇮', 'native': 'Suomi'},
    {'code': 'no',    'name': 'Norwegian',             'country': 'Norway',         'flag': '🇳🇴', 'native': 'Norsk'},
    {'code': 'pt',    'name': 'Portuguese (Portugal)', 'country': 'Portugal',       'flag': '🇵🇹', 'native': 'Português'},
  ];

  static const Map<String, String> _langToCountryCode = {
    'en'    : 'US', 'ru' : 'RU', 'zh' : 'CN', 'hi' : 'IN', 'bn' : 'BD',
    'fr'    : 'FR', 'de' : 'DE', 'ko' : 'KR', 'ja' : 'JP', 'tr' : 'TR',
    'it'    : 'IT', 'pt_br' : 'BR', 'ur' : 'PK', 'he' : 'IL', 'ar' : 'EG',
    'es'    : 'ES', 'es_mx' : 'MX', 'id' : 'ID', 'ms' : 'MY', 'uk' : 'UA',
    'pl'    : 'PL', 'fa' : 'IR', 'sw' : 'KE', 'th' : 'TH', 'vi' : 'VN',
    'tl'    : 'PH', 'nl' : 'NL', 'sv' : 'SE', 'el' : 'GR', 'ro' : 'RO',
    'hu'    : 'HU', 'cs' : 'CZ', 'fi' : 'FI', 'no' : 'NO', 'pt' : 'PT',
  };

  String _countryCode(String langCode) => _langToCountryCode[langCode] ?? 'UN';

  List<Map<String, String>> get _filtered => _languages;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.currentLanguageCode ?? '';
  }

  Future<void> _selectAndContinue(Map<String, String> language) async {
    final code = language['code']!;

    HapticFeedback.lightImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', code);
    await prefs.setString('app_language_name', language['name']!);
    await prefs.setString('app_language_flag', language['flag']!);

    if (!mounted) return;

    // Language selection no longer sets translations on a provider
    // since we removed CVProvider. If you add a settings provider
    // later, wire it up here.

    setState(() => _selectedCode = code);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (widget.currentLanguageCode != null) {
      Navigator.pop(context, {
        ...language,
        'translations': _translationMap[code] ?? enEnglish,
      });
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => OnboardingFlow(
            translations: _translationMap[code] ?? enEnglish,
          ),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  String get _noResultsLabel {
    final map = _translationMap[_selectedCode] ?? enEnglish;
    return map['lang_select_no_results'] ?? 'No languages found';
  }

  @override
  Widget build(BuildContext context) {
    final filtered    = _filtered;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final bgColor          = isDark ? const Color(0xFF12151F) : const Color(0xFFF2F4FA);
    final unselectedCard   = isDark ? const Color(0xFF1E2235) : const Color(0xFFF7F8FC);
    final selectedCard     = isDark ? const Color(0xFF1A2A4A) : const Color(0xFFEFF4FF);
    final unselectedBorder = isDark ? const Color(0xFF2A2E45) : const Color(0xFFE4E8F0);
    final selectedBorder   = colorScheme.primary.withValues(alpha: 0.55);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, color: colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Select Language',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF0D1117),
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: bgColor,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 52,
                      color: colorScheme.onSurface.withValues(alpha: 0.18)),
                  const SizedBox(height: 12),
                  Text(
                    _noResultsLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: 24 + bottomInset,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final lang       = filtered[index];
                final isSelected = lang['code'] == _selectedCode;

                return _LanguageTile(
                  lang             : lang,
                  isSelected       : isSelected,
                  isDark           : isDark,
                  countryCode      : _countryCode(lang['code']!),
                  selectedCard     : selectedCard,
                  unselectedCard   : unselectedCard,
                  selectedBorder   : selectedBorder,
                  unselectedBorder : unselectedBorder,
                  primaryColor     : colorScheme.primary,
                  onSurface        : colorScheme.onSurface,
                  onTap            : () => _selectAndContinue(lang),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LanguageTile
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.lang,
    required this.isSelected,
    required this.isDark,
    required this.countryCode,
    required this.selectedCard,
    required this.unselectedCard,
    required this.selectedBorder,
    required this.unselectedBorder,
    required this.primaryColor,
    required this.onSurface,
    required this.onTap,
  });

  final Map<String, String> lang;
  final bool         isSelected;
  final bool         isDark;
  final String       countryCode;
  final Color        selectedCard;
  final Color        unselectedCard;
  final Color        selectedBorder;
  final Color        unselectedBorder;
  final Color        primaryColor;
  final Color        onSurface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? selectedCard : unselectedCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? selectedBorder : unselectedBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: isDark ? 0.18 : 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: primaryColor.withValues(alpha: 0.08),
            highlightColor: primaryColor.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  _FlagWidget(
                    countryCode:  countryCode,
                    isSelected:   isSelected,
                    primaryColor: primaryColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang['name']!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            height: 1.2,
                            letterSpacing: -0.1,
                            color: isSelected ? primaryColor : onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          lang['native']!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            fontStyle: FontStyle.italic,
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.65)
                                : onSurface.withValues(alpha: 0.48),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          lang['country']!,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            letterSpacing: 0.1,
                            color: onSurface.withValues(alpha: 0.30),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: isSelected
                        ? Container(
                            key: const ValueKey('checked'),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 15),
                          )
                        : Container(
                            key: const ValueKey('unchecked'),
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: onSurface.withValues(alpha: 0.18),
                                width: 1.5,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _FlagWidget
// ─────────────────────────────────────────────────────────────────────────────

class _FlagWidget extends StatelessWidget {
  const _FlagWidget({
    required this.countryCode,
    required this.isSelected,
    required this.primaryColor,
  });

  final String countryCode;
  final bool   isSelected;
  final Color  primaryColor;

  @override
  Widget build(BuildContext context) {
    final double w = isSelected ? 52 : 48;
    final double h = isSelected ? 37 : 34;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.24 : 0.13),
            blurRadius: isSelected ? 12 : 7,
            offset: const Offset(0, 3),
          ),
          if (isSelected)
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.20),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CountryFlag.fromCountryCode(countryCode, width: w, height: h),
      ),
    );
  }
}