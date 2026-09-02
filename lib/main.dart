// lib/main.dart
//
// SPLASH SKIP PASS (this update): SplashScreen is commented out of the
// startup flow — `home:` now goes straight to LanguageSelectScreen
// instead. The splash_screen.dart import is commented out (not deleted)
// and its old import line is left directly above as a marker, so
// re-enabling it later is a one-line swap back. SplashScreen's own file
// is untouched — nothing in it needed to change, since none of its
// animation/timer logic does anything except eventually navigate to
// LanguageSelectScreen, which this now does immediately instead.
//
// RELEASE PASS (earlier pass): flipped both dev-only toggles off.
//   - _kAlwaysShowFlow: true -> false. Was wiping onboarding_complete/
//     onboarding_version out of SharedPreferences on every single launch,
//     which meant no real user could ever get past onboarding once and
//     have it stick — they'd be forced through it again next time they
//     opened the app. Now the persisted value is respected and the
//     version-bump branch (below) is what actually runs.
//   - _kSkipToHomeDev: true -> false. Was skipping splash/onboarding
//     entirely and opening HomeScreen directly. Now `home:` in
//     InvoiceBuilderApp resolves to LanguageSelectScreen as intended
//     (previously SplashScreen — see SPLASH SKIP PASS above).
// Left _kOnboardingVersion as-is (1) — bump this in a future release if
// onboarding content changes and existing users need to see it again.
//
// CLIENT COLOR PREFS (earlier pass): registered ClientColorPrefs — the
// persisted client-name -> logo-background-color mapping (lib/widgets/
// saved_documents/client_color_prefs.dart) — the same way CardDisplayPrefs/
// SavedLayoutPrefs/etc. are already registered: instantiated above runApp,
// loaded in the startup Future.wait, and provided via
// ChangeNotifierProvider.value so every card family that renders
// DocLogoAvatar/DocLogoBanner (Home's Invoices/Quotes/Receipts sections,
// and anywhere else that reuses those widgets) reads from the exact same
// instance and stays in sync when a color is set or cleared.
//
// WEEKLY DIGEST WIRING (earlier pass): two additions for the weekly
// summary notification (lib/alerts/notifications/digest_scheduler.dart):
//   1. NotificationService.instance.onDigestTapped — routes a tapped
//      digest notification to ReportsScreen, same pattern as
//      onReminderTapped/onDocumentAlertTapped above it (assigned before
//      runApp, safe since rootNavigatorKey.currentState is only read
//      later, inside the closure, once a tap actually happens).
//   2. WeeklyDigestScheduler.instance.sync(alertPrefs.weeklyDigestEnabled)
//      — called once, right after the startup Future.wait resolves (so
//      alertPrefs.weeklyDigestEnabled reflects the real persisted value,
//      not its default), to (re)confirm the recurring weekly schedule is
//      still in place on every app launch. Cheap/idempotent — see
//      scheduleWeeklyDigest()'s doc comment in notification_service.dart
//      for why calling this on every launch doesn't create duplicates.
//
// CARD DISPLAY PREFS (earlier pass): registered CardDisplayPrefs — the
// persisted, app-wide set of switches for which stats show on saved-
// document/expense/report cards (lib/widgets/saved_documents/
// card_display_prefs.dart) — the same way AlertPrefs/ReportsPrefs/etc.
// are already registered: instantiated above runApp, loaded in the
// startup Future.wait, and provided via ChangeNotifierProvider.value so
// every card family (Home's Invoices/Quotes/Receipts/Expenses sections,
// the Expenses screen, and the Reports document list) reads from the
// exact same instance and stays in sync.
//
// NOTIFICATION TAP-THROUGH (earlier pass): added rootNavigatorKey and wired
// NotificationService.instance.onReminderTapped so tapping a reminder
// notification actually opens RemindersScreen with that reminder
// highlighted — previously nothing consumed a notification tap at all, so
// it just brought the app to the foreground wherever it last was.
// flushPendingLaunchTap() is called once, in a post-frame callback right
// after runApp(), to catch the case where the app was fully terminated and
// this very launch was caused by the notification tap (the Navigator
// doesn't exist yet at the point NotificationService.init() runs, so that
// specific tap has to be replayed once it does).
//
// DOCUMENT ALERT PUSH (earlier pass): DocumentAlertScheduler now schedules
// real push notifications for overdue invoices / expiring quotes / stale
// drafts (see lib/alerts/notifications/document_alert_scheduler.dart and
// the hooks added to InvoiceProvider/QuoteProvider/ReceiptProvider). Wired
// onDocumentAlertTapped here so tapping one of those opens the right
// document. SavedDocumentDetailScreen's factories (.invoice/.quote/
// .receipt) take the actual Saved* object rather than a bare id, so the
// handler below looks the document up from the matching provider via
// rootNavigatorKey.currentContext (providers live above MaterialApp in the
// widget tree, so the navigator's own context can still read them) before
// pushing. If the document was deleted between the notification firing and
// being tapped, the lookup comes back null and this is a silent no-op
// rather than a crash.

import 'dart:async';

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
import 'alerts/notifications/digest_scheduler.dart';
import 'screens/saved_invoice_details_section/saved_document_detail_screen.dart';
import 'screens/reports/reports_prefs.dart';
import 'screens/reports/reports_screen.dart';
// SPLASH SKIP PASS: splash screen is out of the startup flow for now —
// import commented out alongside its `home:` usage below. Uncomment both
// to bring it back.
// import 'screens/splash_screen.dart';
import 'screens/language_ui_select.dart';
import 'screens/home_screen.dart';
import 'widgets/saved_documents/card_display_prefs.dart';
import 'widgets/saved_documents/saved_layout_prefs.dart';
import 'widgets/saved_documents/client_color_prefs.dart';

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
const bool _kAlwaysShowFlow = false;

/// DEV ONLY — skips splash/onboarding entirely and opens Home directly.
/// Set to false (or delete this block) before release.
const bool _kSkipToHomeDev = false;

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
  final cardDisplayPrefs = CardDisplayPrefs();
  final savedLayoutPrefs = SavedLayoutPrefs();
  final clientColorPrefs = ClientColorPrefs();

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

  // Route a tapped document alert (overdue invoice / quote expiring /
  // draft nudge) to that document's detail screen. `category` is the raw
  // DocAlertCategory.name string from document_alert_scheduler.dart:
  // "overdueInvoice" / "draftInvoice" -> invoice, "quoteExpiring" /
  // "draftQuote" -> quote, "draftReceipt" -> receipt. The document is
  // looked up fresh from its provider (rather than trusting anything
  // cached in the notification payload) so a rename/status-change since
  // the push was scheduled is always reflected, and a deletion in the
  // meantime is a safe no-op instead of showing stale data.
  NotificationService.instance.onDocumentAlertTapped = (category, docId) {
    final navState = rootNavigatorKey.currentState;
    final context = rootNavigatorKey.currentContext;
    if (navState == null || context == null) return;

    switch (category) {
      case 'overdueInvoice':
      case 'draftInvoice':
        final inv = context.read<InvoiceProvider>().getInvoiceById(docId);
        if (inv != null) {
          navState.push(MaterialPageRoute(
            builder: (_) => SavedDocumentDetailScreen.invoice(inv),
          ));
        }
        break;
      case 'quoteExpiring':
      case 'draftQuote':
        final q = context.read<QuoteProvider>().getQuoteById(docId);
        if (q != null) {
          navState.push(MaterialPageRoute(
            builder: (_) => SavedDocumentDetailScreen.quote(q),
          ));
        }
        break;
      case 'draftReceipt':
        final matches = context
            .read<ReceiptProvider>()
            .savedReceipts
            .where((r) => r.id == docId);
        if (matches.isNotEmpty) {
          navState.push(MaterialPageRoute(
            builder: (_) => SavedDocumentDetailScreen.receipt(matches.first),
          ));
        }
        break;
    }
  };

  // Route a tapped weekly-digest notification straight to Reports — no
  // id/category to look up (there's only ever one digest slot), so this
  // is simpler than onDocumentAlertTapped above: just push the screen.
  NotificationService.instance.onDigestTapped = () {
    rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const ReportsScreen()),
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
    cardDisplayPrefs.load(),
    savedLayoutPrefs.load(),
    clientColorPrefs.load(),
  ]);

  // (Re)confirms the recurring weekly-summary notification is scheduled,
  // reflecting whatever alertPrefs.weeklyDigestEnabled resolved to from
  // persisted storage above — must run AFTER the Future.wait, not before,
  // since alertPrefs.load() is what populates that value. Safe/cheap to
  // call on every launch — see scheduleWeeklyDigest()'s doc comment.
  unawaited(WeeklyDigestScheduler.instance.sync(alertPrefs.weeklyDigestEnabled));

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
        ChangeNotifierProvider<CardDisplayPrefs>.value(value: cardDisplayPrefs),
        ChangeNotifierProvider<SavedLayoutPrefs>.value(value: savedLayoutPrefs),
        ChangeNotifierProvider<ClientColorPrefs>.value(value: clientColorPrefs),
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
      // SPLASH SKIP PASS: was `_kSkipToHomeDev ? const HomeScreen() : const
      // SplashScreen()`. SplashScreen is commented out of the flow for
      // now (see the commented import above) — non-dev launches now go
      // straight to LanguageSelectScreen instead of sitting through the
      // splash animation first. To bring the splash screen back: uncomment
      // its import above and swap the line below back to
      // `const SplashScreen()`.
      home: _kSkipToHomeDev ? const HomeScreen() : const LanguageSelectScreen(),
    );
  }
}