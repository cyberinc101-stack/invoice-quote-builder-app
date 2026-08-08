// lib/main.dart
//
// NOTIFICATION TAP-THROUGH (this pass): added rootNavigatorKey and wired
// NotificationService.instance.onReminderTapped so tapping a reminder
// notification actually opens RemindersScreen with that reminder
// highlighted — previously nothing consumed a notification tap at all, so
// it just brought the app to the foreground wherever it last was.
// flushPendingLaunchTap() is called once, in a post-frame callback right
// after runApp(), to catch the case where the app was fully terminated and
// this very launch was caused by the notification tap (the Navigator
// doesn't exist yet at the point NotificationService.init() runs, so that
// specific tap has to be replayed once it does).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/invoice_provider.dart';
import 'providers/quote_provider.dart';
import 'providers/receipt_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/category_provider.dart';
import 'providers/expense_provider.dart';
import 'alerts/alert_prefs.dart';
import 'alerts/custom_reminders/reminder_provider.dart';
import 'alerts/custom_reminders/reminder_screen.dart';
import 'alerts/notifications/notification_service.dart';
import 'screens/reports/reports_prefs.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

// ─── Language translation maps ─────────────────────────────────────────
import 'language_keys/lang_en_english.dart';
import 'language_keys/lang_ru_russian.dart';
import 'language_keys/lang_zh_chinese.dart';
import 'language_keys/lang_hi_hindi.dart';
import 'language_keys/lang_bn_bengali.dart';
import 'language_keys/lang_fr_french.dart';
import 'language_keys/lang_de_german.dart';
import 'language_keys/lang_ko_korean.dart';
import 'language_keys/lang_ja_japanese.dart';
import 'language_keys/lang_tr_turkish.dart';
import 'language_keys/lang_it_italian.dart';
import 'language_keys/lang_pt_br_brazilian.dart';
import 'language_keys/lang_ur_urdu.dart';
import 'language_keys/lang_he_hebrew.dart';
import 'language_keys/lang_ar_arabic.dart';
import 'language_keys/lang_es_spanish.dart';
import 'language_keys/lang_es_mx_mexican.dart';
import 'language_keys/lang_id_indonesian.dart';
import 'language_keys/lang_ms_malay.dart';
import 'language_keys/lang_uk_ukrainian.dart';
import 'language_keys/lang_pl_polish.dart';
import 'language_keys/lang_fa_persian.dart';
import 'language_keys/lang_sw_swahili.dart';
import 'language_keys/lang_th_thai.dart';
import 'language_keys/lang_vi_vietnamese.dart';
import 'language_keys/lang_tl_filipino.dart';
import 'language_keys/lang_nl_dutch.dart';
import 'language_keys/lang_sv_swedish.dart';
import 'language_keys/lang_el_greek.dart';
import 'language_keys/lang_ro_romanian.dart';
import 'language_keys/lang_hu_hungarian.dart';
import 'language_keys/lang_cs_czech.dart';
import 'language_keys/lang_fi_finnish.dart';
import 'language_keys/lang_no_norwegian.dart';
import 'language_keys/lang_pt_portuguese.dart';

// ─── Dev toggles ────────────────────────────────────────────────────────
/// Set to false before releasing to the Play Store / App Store.
const bool _kAlwaysShowFlow = true;

/// DEV ONLY — skips splash/onboarding entirely and opens Home directly.
/// Set to false (or delete this block) before release.
const bool _kSkipToHomeDev = true;

/// Bump to force all users through the flow again (production only).
const int _kOnboardingVersion = 1;
// ─────────────────────────────────────────────────────────────────────────

/// Root navigator key — lets NotificationService push a route in response
/// to a notification tap without needing a BuildContext of its own (the
/// tap can arrive before any screen's context exists yet, e.g. cold start).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

const Map<String, Map<String, String>> kTranslationMap = {
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  GoogleFonts.config.allowRuntimeFetching = false;

  final prefs = await SharedPreferences.getInstance();

  if (_kAlwaysShowFlow) {
    await prefs.remove('onboarding_complete');
    await prefs.remove('onboarding_version');
  } else {
    final stored = prefs.getInt('onboarding_version') ?? 0;
    if (stored < _kOnboardingVersion) {
      await prefs.remove('onboarding_complete');
      await prefs.remove('app_language_code');
      await prefs.remove('app_language_name');
      await prefs.remove('app_language_flag');
      await prefs.setInt('onboarding_version', _kOnboardingVersion);
    }
  }

  final invoiceProvider = InvoiceProvider();
  final quoteProvider   = QuoteProvider();
  final receiptProvider = ReceiptProvider();
  final themeProvider   = ThemeProvider();
  final alertPrefs      = AlertPrefs();
  final reminderProvider = ReminderProvider();
  final categoryProvider = CategoryProvider();
  final expenseProvider  = ExpenseProvider();
  final reportsPrefs     = ReportsPrefs();

  await NotificationService.instance.init();
  // Prompts for notification + exact-alarm permission on Android 13+/12+.
  // Safe to call every launch — the plugin/OS no-ops if already granted.
  await NotificationService.instance.requestPermissions();

  // Route a tapped reminder notification to the Reminders screen with that
  // reminder highlighted. Assigning this here (before runApp) is safe even
  // though rootNavigatorKey.currentState is still null at this point —
  // it's only read later, inside the closure, once a tap actually happens.
  NotificationService.instance.onReminderTapped = (reminderId) {
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => RemindersScreen(highlightReminderId: reminderId),
      ),
    );
  };

  await Future.wait([
    invoiceProvider.loadPersistedInvoices(),
    quoteProvider.loadPersistedQuotes(),
    receiptProvider.loadPersistedReceipts(),
    themeProvider.load(),
    alertPrefs.load(),
    reminderProvider.loadPersistedReminders(),
    categoryProvider.loadPersistedCategories(),
    expenseProvider.loadPersistedExpenses(),
    reportsPrefs.load(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
        ChangeNotifierProvider<QuoteProvider>.value(value: quoteProvider),
        ChangeNotifierProvider<ReceiptProvider>.value(value: receiptProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<AlertPrefs>.value(value: alertPrefs),
        ChangeNotifierProvider<ReminderProvider>.value(value: reminderProvider),
        ChangeNotifierProvider<CategoryProvider>.value(value: categoryProvider),
        ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
        ChangeNotifierProvider<ReportsPrefs>.value(value: reportsPrefs),
      ],
      child: const InvoiceBuilderApp(),
    ),
  );

  // Delivers a notification tap that happened before the Navigator existed
  // (app launched cold, straight from tapping the notification). Must run
  // after the first frame so rootNavigatorKey.currentState is attached.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationService.instance.flushPendingLaunchTap();
  });
}

class InvoiceBuilderApp extends StatelessWidget {
  const InvoiceBuilderApp({super.key});

  // ── Light theme ─────────────────────────────────────────────────────
  static final ThemeData _light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Color(0xFF2196F3),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );

  // ── Dark theme ──────────────────────────────────────────────────────
  static final ThemeData _dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0D0D1A),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Color(0xFF1A1A2E),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      color: const Color(0xFF1E2235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    dividerColor: const Color(0xFF2A2D3E),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF90CAF9),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeProvider>().themeMode;
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Invoice & Quote Builder',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _light,
      darkTheme: _dark,
      home: _kSkipToHomeDev ? const HomeScreen() : const SplashScreen(),
    );
  }
}
