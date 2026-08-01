// lib/utils/text_sanitizer.dart
class TextSanitizer {
  static final _replacements = <String, String>{
    '\u25C6': '\u00B7', // ◆ BLACK DIAMOND
    '\u25C7': '\u00B7', // ◇ WHITE DIAMOND
    '\u25CF': '\u00B7', // ● BLACK CIRCLE
    '\u25A0': '\u00B7', // ■ BLACK SQUARE
    '\u25A1': '\u00B7', // □ WHITE SQUARE
    '\u25AA': '\u00B7', // ▪ BLACK SMALL SQUARE
    '\u25AB': '\u00B7', // ▫ WHITE SMALL SQUARE
    '\u25B6': '\u00B7', // ▶ BLACK RIGHT-POINTING TRIANGLE
    '\u25B8': '\u00B7', // ▸ SMALL BLACK RIGHT-POINTING TRIANGLE
    '\u2756': '\u00B7', // ❖ BLACK DIAMOND MINUS WHITE X
    '\u2666': '\u00B7', // ♦ BLACK DIAMOND SUIT
    '\u2023': '\u00B7', // ‣ TRIANGULAR BULLET
    '\u2043': '\u00B7', // ⁃ HYPHEN BULLET
    '\u2219': '\u00B7', // ∙ BULLET OPERATOR
  };

  static String clean(String? input) {
    if (input == null || input.isEmpty) return '';
    var result = input;
    for (final entry in _replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  static List<String> cleanList(List<String> items) =>
      items.map(clean).toList();
}