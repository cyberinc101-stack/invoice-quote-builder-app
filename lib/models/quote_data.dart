// quote_data.dart
// lib/models/quote_data.dart

import 'invoice_data.dart' show LineItem;

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum QuoteStatus { draft, sent, accepted, declined, expired }

enum QuoteColor { blue, green, purple, orange, red, teal, black, indigo }

// ─────────────────────────────────────────────────────────────────────────────
// QuoteData
// ─────────────────────────────────────────────────────────────────────────────

class QuoteData {
  String businessName;
  String businessEmail;
  String businessPhone;
  String businessAddress;
  String? businessLogoPath;

  String clientName;
  String clientEmail;
  String clientPhone;
  String clientAddress;

  String quoteNumber;
  String issueDate;
  String expiryDate;
  String notes;
  String currency;

  List<LineItem> lineItems;

  double      taxRate;
  double      discountRate;
  QuoteStatus quoteStatus;
  String      fontFamily;
  QuoteColor  colorScheme;

  QuoteData({
    this.businessName     = '',
    this.businessEmail    = '',
    this.businessPhone    = '',
    this.businessAddress  = '',
    this.businessLogoPath,
    this.clientName       = '',
    this.clientEmail      = '',
    this.clientPhone      = '',
    this.clientAddress    = '',
    this.quoteNumber      = '',
    this.issueDate        = '',
    this.expiryDate       = '',
    this.notes            = '',
    this.currency         = 'USD',
    List<LineItem>? lineItems,
    this.taxRate          = 0.0,
    this.discountRate     = 0.0,
    this.quoteStatus      = QuoteStatus.draft,
    this.fontFamily       = 'Roboto',
    this.colorScheme      = QuoteColor.purple,
  }) : lineItems = lineItems ?? [];

  // ── Computed totals ────────────────────────────────────────────────────────

  double get subtotal       => lineItems.fold(0.0, (sum, i) => sum + i.total);
  double get discountAmount => subtotal * (discountRate / 100);
  double get taxAmount      => (subtotal - discountAmount) * (taxRate / 100);
  double get grandTotal     => subtotal - discountAmount + taxAmount;

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'businessName':     businessName,
        'businessEmail':    businessEmail,
        'businessPhone':    businessPhone,
        'businessAddress':  businessAddress,
        'businessLogoPath': businessLogoPath,
        'clientName':       clientName,
        'clientEmail':      clientEmail,
        'clientPhone':      clientPhone,
        'clientAddress':    clientAddress,
        'quoteNumber':      quoteNumber,
        'issueDate':        issueDate,
        'expiryDate':       expiryDate,
        'notes':            notes,
        'currency':         currency,
        'lineItems':        lineItems.map((i) => i.toJson()).toList(),
        'taxRate':          taxRate,
        'discountRate':     discountRate,
        'quoteStatus':      quoteStatus.name,
        'fontFamily':       fontFamily,
        'colorScheme':      colorScheme.name,
      };

  factory QuoteData.fromJson(Map<String, dynamic> j) => QuoteData(
        businessName:     j['businessName']     as String? ?? '',
        businessEmail:    j['businessEmail']    as String? ?? '',
        businessPhone:    j['businessPhone']    as String? ?? '',
        businessAddress:  j['businessAddress']  as String? ?? '',
        businessLogoPath: j['businessLogoPath'] as String?,
        clientName:       j['clientName']       as String? ?? '',
        clientEmail:      j['clientEmail']      as String? ?? '',
        clientPhone:      j['clientPhone']      as String? ?? '',
        clientAddress:    j['clientAddress']    as String? ?? '',
        quoteNumber:      j['quoteNumber']      as String? ?? '',
        issueDate:        j['issueDate']        as String? ?? '',
        expiryDate:       j['expiryDate']       as String? ?? '',
        notes:            j['notes']            as String? ?? '',
        currency:         j['currency']         as String? ?? 'USD',
        lineItems: (j['lineItems'] as List<dynamic>? ?? [])
            .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        taxRate:      (j['taxRate']      as num?)?.toDouble() ?? 0.0,
        discountRate: (j['discountRate'] as num?)?.toDouble() ?? 0.0,
        quoteStatus: QuoteStatus.values.firstWhere(
          (s) => s.name == (j['quoteStatus'] as String? ?? ''),
          orElse: () => QuoteStatus.draft,
        ),
        fontFamily:  j['fontFamily'] as String? ?? 'Roboto',
        colorScheme: QuoteColor.values.firstWhere(
          (c) => c.name == (j['colorScheme'] as String? ?? ''),
          orElse: () => QuoteColor.purple,
        ),
      );

  // ── copyWith ───────────────────────────────────────────────────────────────

  QuoteData copyWith({
    String?         businessName,
    String?         businessEmail,
    String?         businessPhone,
    String?         businessAddress,
    String?         businessLogoPath,
    String?         clientName,
    String?         clientEmail,
    String?         clientPhone,
    String?         clientAddress,
    String?         quoteNumber,
    String?         issueDate,
    String?         expiryDate,
    String?         notes,
    String?         currency,
    List<LineItem>? lineItems,
    double?         taxRate,
    double?         discountRate,
    QuoteStatus?    quoteStatus,
    String?         fontFamily,
    QuoteColor?     colorScheme,
  }) =>
      QuoteData(
        businessName:     businessName     ?? this.businessName,
        businessEmail:    businessEmail    ?? this.businessEmail,
        businessPhone:    businessPhone    ?? this.businessPhone,
        businessAddress:  businessAddress  ?? this.businessAddress,
        businessLogoPath: businessLogoPath ?? this.businessLogoPath,
        clientName:       clientName       ?? this.clientName,
        clientEmail:      clientEmail      ?? this.clientEmail,
        clientPhone:      clientPhone      ?? this.clientPhone,
        clientAddress:    clientAddress    ?? this.clientAddress,
        quoteNumber:      quoteNumber      ?? this.quoteNumber,
        issueDate:        issueDate        ?? this.issueDate,
        expiryDate:       expiryDate       ?? this.expiryDate,
        notes:            notes            ?? this.notes,
        currency:         currency         ?? this.currency,
        lineItems:        lineItems        ?? List<LineItem>.from(this.lineItems),
        taxRate:          taxRate          ?? this.taxRate,
        discountRate:     discountRate     ?? this.discountRate,
        quoteStatus:      quoteStatus      ?? this.quoteStatus,
        fontFamily:       fontFamily       ?? this.fontFamily,
        colorScheme:      colorScheme      ?? this.colorScheme,
      );

  QuoteData deepCopy() => copyWith(
        lineItems: lineItems.map((i) => i.copyWith()).toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SavedQuote  — wrapper stored in SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────

class SavedQuote {
  final String    id;
  final String    title;
  final String    templateName;
  final QuoteData data;
  final DateTime  createdAt;
  final DateTime  lastEditedAt;
  final int       completionPercent;
  final String?   folderName;

  SavedQuote({
    required this.id,
    required this.title,
    required this.templateName,
    required this.data,
    required this.createdAt,
    required this.lastEditedAt,
    required this.completionPercent,
    this.folderName,
  });

  String lastEditedDisplay() {
    final diff = DateTime.now().difference(lastEditedAt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    == 1) return 'Yesterday';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  String get initials {
    final parts = title.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0].substring(0, 2).toUpperCase();
    return 'QT';
  }

  Map<String, dynamic> toJson() => {
        'id':                id,
        'title':             title,
        'templateName':      templateName,
        'data':              data.toJson(),
        'createdAt':         createdAt.toIso8601String(),
        'lastEditedAt':      lastEditedAt.toIso8601String(),
        'completionPercent': completionPercent,
        'folderName':        folderName,
      };

  factory SavedQuote.fromJson(Map<String, dynamic> j) => SavedQuote(
        id:           j['id']           as String,
        title:        j['title']        as String? ?? 'Quote',
        templateName: j['templateName'] as String? ?? '',
        data: QuoteData.fromJson(j['data'] as Map<String, dynamic>? ?? {}),
        createdAt:    DateTime.parse(j['createdAt']    as String),
        lastEditedAt: DateTime.parse(j['lastEditedAt'] as String),
        completionPercent: j['completionPercent'] as int? ?? 0,
        folderName: j['folderName'] as String?,
      );

  // NEW: folderName/clearFolderName — same pattern as SavedInvoice.copyWith.
  SavedQuote copyWith({
    String?    title,
    String?    templateName,
    QuoteData? data,
    DateTime?  lastEditedAt,
    int?       completionPercent,
    String?    folderName,
    bool       clearFolderName = false,
  }) =>
      SavedQuote(
        id:                id,
        title:             title             ?? this.title,
        templateName:      templateName      ?? this.templateName,
        data:              data              ?? this.data.deepCopy(),
        createdAt:         createdAt,
        lastEditedAt:      lastEditedAt      ?? this.lastEditedAt,
        completionPercent: completionPercent ?? this.completionPercent,
        folderName: clearFolderName ? null : (folderName ?? this.folderName),
      );
}
