// lib/providers/theme_provider.dart
//
// Holds the app-wide ThemeMode and persists the user's choice to
// SharedPreferences so it survives app restarts.
//
// ── Usage in main.dart ────────────────────────────────────────────────────────
//
//   // 1. Add ThemeProvider alongside your other providers:
//   MultiProvider(
//     providers: [
//       ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
//       ChangeNotifierProvider(create: (_) => CVProvider()),
//     ],
//     child: const _App(),
//   )
//
//   // 2. Consume it in your MaterialApp widget:
//   class _App extends StatelessWidget {
//     @override
//     Widget build(BuildContext context) {
//       final themeMode = context.watch<ThemeProvider>().themeMode;
//       return MaterialApp(
//         themeMode: themeMode,
//         theme: ThemeData.light(useMaterial3: true).copyWith(
//           colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
//         ),
//         darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
//           colorScheme: ColorScheme.fromSeed(
//             seedColor: const Color(0xFF1565C0),
//             brightness: Brightness.dark,
//           ),
//           scaffoldBackgroundColor: const Color(0xFF0D0D1A),
//           cardColor: const Color(0xFF1E2235),
//         ),
//         home: ...,
//       );
//     }
//   }
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  /// Call once at startup (e.g. `ThemeProvider()..load()` in your provider
  /// declaration) to restore the persisted preference.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _themeMode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Toggle between light and dark and persist the choice.
  Future<void> toggle() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  /// Set an explicit mode.
  Future<void> setMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}