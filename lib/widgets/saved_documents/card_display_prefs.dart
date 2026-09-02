// card_display_prefs.dart
// lib/widgets/saved_documents/card_display_prefs.dart
//
// Persisted, app-wide set of switches controlling which stats render on
// every saved-document-style card — Saved Documents (Home), Expenses, and
// the Reports "Documents in this period" list all read from this single
// instance (registered once in main.dart via ChangeNotifierProvider, same
// pattern as AlertPrefs), so a toggle flipped in one place updates every
// card family immediately and the choice survives an app restart.
//
// This is a CONTENT toggle (which stats show on the card) — separate from
// DocLayoutMode/ExpenseLayoutMode/ReportsLayoutMode, which control the
// card's shape (list/grid/compactGrid/compact). A user can be on Grid
// layout with the logo hidden, or List layout with everything showing —
// the two concerns are independent.
//
// LOGO HIGHLIGHT / LOGO IMAGE TOGGLES (this update): added
// `showLogoHighlight` and `showLogoImage` — both scoped specifically to
// the logo avatar/banner rendered by DocLogoAvatar/DocLogoBanner (see
// doc_card_shared.dart), independent of `showLogo` (which controls
// whether the logo block renders AT ALL).
//   - showLogoHighlight: controls the colored glow/box-shadow rendered
//     behind the logo (image OR fallback initial/icon). Off = flat, no
//     shadow.
//   - showLogoImage: controls whether the actual uploaded picture is
//     drawn. Off = always render the fallback initial/icon look, even if
//     a logo image is saved on the document — lets a user who uploaded a
//     logo still opt into the plain initial-letter card look without
//     having to delete the logo itself.
// Both default to true so existing behaviour is unchanged for anyone who
// hasn't touched the new switches.
//
// BUSINESS NAME TOGGLE (earlier): added `showBusinessName` — controls
// the small business-name label rendered under the logo avatar on the
// List and Grid layouts (see doc_cards.dart). Separate switch from
// showLogo since a user may want the logo visible without the name label
// underneath it (or vice versa, though the name label only ever renders
// alongside a visible logo — see doc_cards.dart's nesting).
//
// CARD STYLE PASS (earlier): added `cardStyle` (CardStyle.standard /
// CardStyle.logoBanner) — a separate axis from the field switches above.
// Standard is the existing side-by-side logo + text layout. Logo Banner
// renders the business logo as a full-width band across the top of the
// card (List layout only for now — compactGrid/compact stay square, no
// room for a banner at those sizes). This is deliberately NOT another
// switchTile alongside showLogo/showAmount/etc: it changes the card's
// shape, not just which fields are visible, so it gets its own segmented
// control in the sheet rather than being mixed into that list.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CardStyle { standard, logoBanner }

class CardDisplayPrefs extends ChangeNotifier {
  static const String _kShowLogo             = 'card_display_show_logo';
  static const String _kShowAmount           = 'card_display_show_amount';
  static const String _kShowSecondaryDate    = 'card_display_show_secondary_date';
  static const String _kShowCreatedAndItems  = 'card_display_show_created_items';
  static const String _kShowProgress         = 'card_display_show_progress';
  static const String _kShowStatusChip       = 'card_display_show_status_chip';
  static const String _kShowBusinessName     = 'card_display_show_business_name';
  static const String _kShowLogoHighlight    = 'card_display_show_logo_highlight';
  static const String _kShowLogoImage        = 'card_display_show_logo_image';
  static const String _kCardStyle            = 'card_display_card_style';

  bool showLogo            = true;
  bool showAmount          = true;
  bool showSecondaryDate   = true;
  bool showCreatedAndItems = true;
  bool showProgress        = true;
  bool showStatusChip      = true;
  bool showBusinessName    = true;
  bool showLogoHighlight   = true;
  bool showLogoImage       = true;
  CardStyle cardStyle      = CardStyle.standard;

  SharedPreferences? _prefs;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      showLogo            = prefs.getBool(_kShowLogo)            ?? true;
      showAmount           = prefs.getBool(_kShowAmount)          ?? true;
      showSecondaryDate    = prefs.getBool(_kShowSecondaryDate)   ?? true;
      showCreatedAndItems  = prefs.getBool(_kShowCreatedAndItems) ?? true;
      showProgress         = prefs.getBool(_kShowProgress)        ?? true;
      showStatusChip       = prefs.getBool(_kShowStatusChip)      ?? true;
      showBusinessName     = prefs.getBool(_kShowBusinessName)    ?? true;
      showLogoHighlight    = prefs.getBool(_kShowLogoHighlight)   ?? true;
      showLogoImage        = prefs.getBool(_kShowLogoImage)       ?? true;
      final styleIndex     = prefs.getInt(_kCardStyle) ?? 0;
      cardStyle = (styleIndex >= 0 && styleIndex < CardStyle.values.length)
          ? CardStyle.values[styleIndex]
          : CardStyle.standard;
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[CardDisplayPrefs] load error: $e');
      _loaded = true;
    }
  }

  Future<void> setShowLogo(bool value) async {
    showLogo = value;
    notifyListeners();
    await _prefs?.setBool(_kShowLogo, value);
  }

  Future<void> setShowAmount(bool value) async {
    showAmount = value;
    notifyListeners();
    await _prefs?.setBool(_kShowAmount, value);
  }

  Future<void> setShowSecondaryDate(bool value) async {
    showSecondaryDate = value;
    notifyListeners();
    await _prefs?.setBool(_kShowSecondaryDate, value);
  }

  Future<void> setShowCreatedAndItems(bool value) async {
    showCreatedAndItems = value;
    notifyListeners();
    await _prefs?.setBool(_kShowCreatedAndItems, value);
  }

  Future<void> setShowProgress(bool value) async {
    showProgress = value;
    notifyListeners();
    await _prefs?.setBool(_kShowProgress, value);
  }

  Future<void> setShowStatusChip(bool value) async {
    showStatusChip = value;
    notifyListeners();
    await _prefs?.setBool(_kShowStatusChip, value);
  }

  Future<void> setShowBusinessName(bool value) async {
    showBusinessName = value;
    notifyListeners();
    await _prefs?.setBool(_kShowBusinessName, value);
  }

  Future<void> setShowLogoHighlight(bool value) async {
    showLogoHighlight = value;
    notifyListeners();
    await _prefs?.setBool(_kShowLogoHighlight, value);
  }

  Future<void> setShowLogoImage(bool value) async {
    showLogoImage = value;
    notifyListeners();
    await _prefs?.setBool(_kShowLogoImage, value);
  }

  Future<void> setCardStyle(CardStyle value) async {
    cardStyle = value;
    notifyListeners();
    await _prefs?.setInt(_kCardStyle, value.index);
  }
}
