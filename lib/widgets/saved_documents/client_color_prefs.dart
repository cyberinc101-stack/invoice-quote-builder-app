// client_color_prefs.dart
// lib/widgets/saved_documents/client_color_prefs.dart
//
// Persisted, app-wide mapping of client name -> a chosen background color
// for that client's logo box on every document card (List/Grid/Compact
// Grid/Compact/Kanban, wherever DocLogoAvatar or DocLogoBanner renders).
// Keyed by CLIENT, not by document — so every invoice, quote, and receipt
// for "Acme Corp" shows the same color regardless of which document is
// open, letting a user scan a card list and recognise a client by their
// assigned color rather than reading the title each time.
//
// WHY THIS ALSO SOLVES THE "logo has its own opaque background" PROBLEM:
// a transparent PNG logo lets our letterbox background show through
// directly, so picking a color here is purely cosmetic/categorising for
// that case. But a JPEG (or any logo with a solid background already
// baked into its pixels) can never have that background stripped by the
// app — there is no way to un-bake pixel data. What we CAN do is let the
// user pick the SAME (or a complementary) color as their logo's own
// background here, so the small margin of letterbox around the image
// visually matches instead of creating a mismatched "box within a box"
// seam. Either way, one picker, one mental model: "what color sits behind
// my logo."
//
// STORAGE: a single SharedPreferences string, JSON-encoded
// {normalizedClientKey: colorValue}. Client keys are normalised via
// normalizedClientKey() below (trimmed, lowercased) so "Acme Corp" and
// "acme corp " resolve to the same entry — matches how businessName is
// free-typed per document with no enforced canonical casing.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Normalises a client/business name into a stable lookup key — trimmed
/// and lowercased, so casing/whitespace differences across documents for
/// the same real-world client don't create separate color entries.
String normalizedClientKey(String clientName) => clientName.trim().toLowerCase();

class ClientColorPrefs extends ChangeNotifier {
  static const String _kKey = 'client_logo_colors_v1';

  final Map<String, Color> _colors = {};
  SharedPreferences? _prefs;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      final raw = prefs.getString(_kKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (value is int) _colors[key] = Color(value);
        });
      }
    } catch (e) {
      debugPrint('[ClientColorPrefs] load error: $e');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  /// The saved color for this client, or null if the client has never had
  /// one set — callers should fall back to their own default tint (e.g.
  /// DocLogoAvatar's accent-based kDocLogoLetterboxBg) when null.
  Color? colorFor(String clientName) {
    if (clientName.trim().isEmpty) return null;
    return _colors[normalizedClientKey(clientName)];
  }

  Future<void> setColorFor(String clientName, Color color) async {
    final key = normalizedClientKey(clientName);
    if (key.isEmpty) return;
    _colors[key] = color;
    notifyListeners();
    await _persist();
  }

  Future<void> clearColorFor(String clientName) async {
    final key = normalizedClientKey(clientName);
    if (!_colors.containsKey(key)) return;
    _colors.remove(key);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final encoded = jsonEncode(_colors.map((k, v) => MapEntry(k, v.toARGB32())));
      await _prefs?.setString(_kKey, encoded);
    } catch (e) {
      debugPrint('[ClientColorPrefs] persist error: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Swatch picker — a lightweight bottom sheet, no external color-picker
// package required. A fixed palette keeps every user's picks visually
// distinct and legible against both the logo and the rest of the card,
// rather than opening onto a full HSV wheel that could produce a color
// too close to the card's own background or text.
// ─────────────────────────────────────────────────────────────────────────

const List<Color> kClientColorSwatches = [
  Color(0xFFEF5350), // red
  Color(0xFFFF7043), // deep orange
  Color(0xFFFFA726), // orange
  Color(0xFFFFCA28), // amber
  Color(0xFFD4E157), // lime
  Color(0xFF66BB6A), // green
  Color(0xFF26A69A), // teal
  Color(0xFF29B6F6), // light blue
  Color(0xFF42A5F5), // blue
  Color(0xFF5C6BC0), // indigo
  Color(0xFF7E57C2), // deep purple
  Color(0xFFAB47BC), // purple
  Color(0xFFEC407A), // pink
  Color(0xFF8D6E63), // brown
  Color(0xFF78909C), // blue grey
];

/// Opens a bottom sheet letting the person pick (or clear) the background
/// color shown behind this client's logo across every document card.
/// [currentColor] highlights the active swatch, if any.
Future<void> showClientColorPicker(
  BuildContext context, {
  required String clientName,
  required Color? currentColor,
  required ValueChanged<Color> onColorSelected,
  required VoidCallback onCleared,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logo background color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                clientName.trim().isEmpty
                    ? 'Applies to every document for this client'
                    : 'Applies to every document for "$clientName"',
                style: TextStyle(fontSize: 12.5, color: cs.onSurface.withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final swatch in kClientColorSwatches)
                    _ColorSwatchButton(
                      color: swatch,
                      selected: currentColor != null && currentColor.toARGB32() == swatch.toARGB32(),
                      onTap: () {
                        Navigator.pop(ctx);
                        onColorSelected(swatch);
                      },
                    ),
                ],
              ),
              if (currentColor != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onCleared();
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Use default color'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _ColorSwatchButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorSwatchButton({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.black87, width: 2.5) : null,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
      ),
    );
  }
}
