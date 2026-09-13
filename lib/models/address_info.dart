// lib/models/address_info.dart
//
// STRUCTURED ADDRESS PASS: shared value type for a postal address, used by
// both ClientInfo (Customer) and BusinessInfo (Business + Sender) in
// client_info.dart. Replaces the old single free-text Address field with
// six distinct fields (Address Line 1/2, City, State/Province, Country,
// ZIP/Postal Code) so the invoice preview can eventually lay it out
// properly instead of wrapping one long unstructured string.
//
// BACKWARD COMPATIBILITY: ClientInfo.address / BusinessInfo.address /
// BusinessInfo.senderAddress (the original String fields) are NOT removed
// — every existing template/customer/invoice already has data in them, and
// other parts of the app (PDF export, Quote/Receipt document types that
// share the same Customer model, etc.) still read them as plain strings.
// Those String fields are now auto-derived from AddressInfo.singleLine at
// save time (see step_customers.dart / step_templates.dart's _save()), so
// anything reading the old field keeps working unchanged, while the new
// structured data is available wherever it's wired up (e.g. a future pass
// on the invoice render layout for proper multi-line postal formatting).
//
// MIGRATION: fromJson() accepts either the new structured Map OR a legacy
// plain String (old persisted data) — a legacy string is preserved into
// `line1` rather than discarded or fuzzy-parsed into city/state/etc (that
// kind of free-text parsing is unreliable and was deliberately avoided).

class AddressInfo {
  String line1;
  String line2;
  String city;
  String state;
  String country;
  String postalCode;

  AddressInfo({
    this.line1 = '',
    this.line2 = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.postalCode = '',
  });

  bool get isEmpty =>
      line1.trim().isEmpty &&
      line2.trim().isEmpty &&
      city.trim().isEmpty &&
      state.trim().isEmpty &&
      country.trim().isEmpty &&
      postalCode.trim().isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Comma-separated single line — used to keep the legacy String address
  /// fields on ClientInfo/BusinessInfo populated for any code that still
  /// reads them (customer/template cards, PDF export, Quote/Receipt, etc).
  String get singleLine {
    final parts = [line1, line2, city, state, postalCode, country]
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    return parts.join(', ');
  }

  /// Standard postal-style multi-line layout for document rendering:
  ///   Line 1
  ///   Line 2
  ///   City, State ZIP
  ///   Country
  /// Skips any line that would otherwise be blank. Not used yet anywhere
  /// in this pass — this is here ready for whenever the invoice render
  /// layout (executive_invoice_stationary_layout.dart) is updated to lay
  /// the address out properly instead of using the single-line string.
  List<String> get formattedLines {
    final lines = <String>[];
    if (line1.trim().isNotEmpty) lines.add(line1.trim());
    if (line2.trim().isNotEmpty) lines.add(line2.trim());

    final cityState =
        [city.trim(), state.trim()].where((p) => p.isNotEmpty).join(', ');
    final cityStateZip = [cityState, postalCode.trim()]
        .where((p) => p.isNotEmpty)
        .join(' ');
    if (cityStateZip.isNotEmpty) lines.add(cityStateZip);

    if (country.trim().isNotEmpty) lines.add(country.trim());
    return lines;
  }

  AddressInfo copyWith({
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? country,
    String? postalCode,
  }) =>
      AddressInfo(
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        city: city ?? this.city,
        state: state ?? this.state,
        country: country ?? this.country,
        postalCode: postalCode ?? this.postalCode,
      );

  Map<String, dynamic> toJson() => {
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
      };

  /// Accepts either the new structured Map, or a legacy plain String (the
  /// old single-field address) — old data is preserved into `line1` so
  /// nothing is lost, with the rest left blank for the user to fill in.
  factory AddressInfo.fromJson(dynamic j) {
    if (j is Map) {
      final m = Map<String, dynamic>.from(j);
      return AddressInfo(
        line1: m['line1'] as String? ?? '',
        line2: m['line2'] as String? ?? '',
        city: m['city'] as String? ?? '',
        state: m['state'] as String? ?? '',
        country: m['country'] as String? ?? '',
        postalCode: m['postalCode'] as String? ?? '',
      );
    }
    if (j is String && j.trim().isNotEmpty) {
      return AddressInfo(line1: j.trim());
    }
    return AddressInfo();
  }
}