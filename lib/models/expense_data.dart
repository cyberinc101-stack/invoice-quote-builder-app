// expense_data.dart
// lib/models/expense_data.dart
//
// REFERENCE NUMBER PASS: added referenceNumber — a plain, user-typed
// string (no database, no external lookup) used two ways:
//   1. Manual search/filter on ExpenseScreen and the Home screen's "My
//      Expenses" section (vendor OR reference number).
//   2. Displayed on Reports' "Expenses in this period" cards (e.g.
//      "Travel · Ref: 12345") for reconciling against a physical
//      receipt/reference number.
// copyWith() gets a matching clearReferenceNumber flag, same pattern as
// clearLogo/clearFolder below, so the add/edit sheet can explicitly blank
// it out. Falls back to null when missing from persisted JSON, so no
// migration step is needed for expenses saved before this field existed.
//
// LOGO + FOLDER PASS (earlier): added logoPath/logoOffsetDx/
// logoOffsetDy/logoScale/logoShape (mirrors InvoiceData/QuoteData/
// ReceiptData's business-logo fields, via SharedLogoPicker) and
// folderName (mirrors those same models' folder assignment field).
// copyWith() gets two explicit "clear" flags — clearLogo and
// clearFolder — because a plain `x ?? this.x` copyWith can't express
// "set this field to null" (null just falls through to the old value).
// ExpenseProvider.updateExpensesFolder() uses clearFolder to remove an
// expense from its folder; the add/edit sheet uses clearLogo when the
// user removes the logo image.
//
// lastEditedAt field (earlier pass, kept): mirrors InvoiceData/QuoteData/
// ReceiptData's distinction between "created" and "last edited" — needed
// so the rich expense cards (expense_cards.dart) can show an
// "Edited 3h ago" line the same way Saved Documents cards do, instead of
// a static creation date that never changes when a user fixes an amount
// or vendor name. ExpenseProvider.addExpense()/updateExpense() set this;
// see that file for details. Falls back to createdAt when the key is
// missing from persisted JSON (pre-existing entries saved before this
// field existed), so no migration step is needed.
//
// excludeFromReports (earlier pass, kept): mirrors InvoiceData/QuoteData/
// ReceiptData's field of the same name. Defaults to false, and fromJson()
// falls back to false when the key is missing so existing persisted
// expenses load correctly without a migration step.
//
// All new fields fall back to sensible defaults when missing from
// persisted JSON (null logoPath, zero offset, scale 1.0, 'roundedSquare'
// shape, null folderName, null referenceNumber), so existing persisted
// expenses from before this pass load correctly with no migration step.

class ExpenseEntry {
  final String id;
  final String vendor;
  final double amount;
  final String currency;
  final String categoryId;
  final DateTime date;
  final String notes;
  final DateTime createdAt;
  final DateTime lastEditedAt;
  final bool excludeFromReports;

  // Logo/photo — mirrors the business-logo fields InvoiceData/QuoteData/
  // ReceiptData carry, driven by the same SharedLogoPicker widget.
  final String? logoPath;
  final double logoOffsetDx;
  final double logoOffsetDy;
  final double logoScale;
  final String logoShape; // storage name from LogoShape.storageName

  // Folder assignment — mirrors folderName on SavedInvoice/SavedQuote/
  // SavedReceipt.
  final String? folderName;

  // Reference number — plain manually-typed string. No database backing;
  // matching happens by scanning the in-memory _expenses list in
  // ExpenseProvider (findByReferenceNumber).
  final String? referenceNumber;

  const ExpenseEntry({
    required this.id,
    required this.vendor,
    required this.amount,
    required this.currency,
    required this.categoryId,
    required this.date,
    required this.notes,
    required this.createdAt,
    required this.lastEditedAt,
    this.excludeFromReports = false,
    this.logoPath,
    this.logoOffsetDx = 0.0,
    this.logoOffsetDy = 0.0,
    this.logoScale = 1.0,
    this.logoShape = 'roundedSquare',
    this.folderName,
    this.referenceNumber,
  });

  ExpenseEntry copyWith({
    String? vendor,
    double? amount,
    String? currency,
    String? categoryId,
    DateTime? date,
    String? notes,
    DateTime? lastEditedAt,
    bool? excludeFromReports,
    String? logoPath,
    bool clearLogo = false,
    double? logoOffsetDx,
    double? logoOffsetDy,
    double? logoScale,
    String? logoShape,
    String? folderName,
    bool clearFolder = false,
    String? referenceNumber,
    bool clearReferenceNumber = false,
  }) {
    return ExpenseEntry(
      id: id,
      vendor: vendor ?? this.vendor,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      excludeFromReports: excludeFromReports ?? this.excludeFromReports,
      logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
      logoOffsetDx: logoOffsetDx ?? this.logoOffsetDx,
      logoOffsetDy: logoOffsetDy ?? this.logoOffsetDy,
      logoScale: logoScale ?? this.logoScale,
      logoShape: logoShape ?? this.logoShape,
      folderName: clearFolder ? null : (folderName ?? this.folderName),
      referenceNumber: clearReferenceNumber ? null : (referenceNumber ?? this.referenceNumber),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor': vendor,
        'amount': amount,
        'currency': currency,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'lastEditedAt': lastEditedAt.toIso8601String(),
        'excludeFromReports': excludeFromReports,
        'logoPath': logoPath,
        'logoOffsetDx': logoOffsetDx,
        'logoOffsetDy': logoOffsetDy,
        'logoScale': logoScale,
        'logoShape': logoShape,
        'folderName': folderName,
        'referenceNumber': referenceNumber,
      };

  factory ExpenseEntry.fromJson(Map<String, dynamic> j) {
    final createdAt = DateTime.parse(j['createdAt'] as String);
    return ExpenseEntry(
      id: j['id'] as String,
      vendor: j['vendor'] as String,
      amount: (j['amount'] as num).toDouble(),
      currency: j['currency'] as String,
      categoryId: j['categoryId'] as String,
      date: DateTime.parse(j['date'] as String),
      notes: j['notes'] as String? ?? '',
      createdAt: createdAt,
      // Falls back to createdAt for entries saved before this field
      // existed, so "Edited" reads as "Edited [creation date]" rather
      // than crashing or showing a bogus epoch date.
      lastEditedAt: j['lastEditedAt'] != null
          ? DateTime.parse(j['lastEditedAt'] as String)
          : createdAt,
      excludeFromReports: j['excludeFromReports'] as bool? ?? false,
      logoPath: j['logoPath'] as String?,
      logoOffsetDx: (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
      logoOffsetDy: (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
      logoScale: (j['logoScale'] as num?)?.toDouble() ?? 1.0,
      logoShape: j['logoShape'] as String? ?? 'roundedSquare',
      folderName: j['folderName'] as String?,
      referenceNumber: j['referenceNumber'] as String?,
    );
  }
}
