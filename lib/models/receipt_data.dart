// receipt_data.dart
// lib/models/receipt_data.dart

import 'invoice_data.dart' show LineItem;

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum ReceiptStatus { issued, refunded }

enum ReceiptColor { blue, green, purple, orange, red, teal, black, indigo }

enum PaymentMethod { cash, card, bankTransfer, other }

// ─────────────────────────────────────────────────────────────────────────────
// ReceiptData
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptData {
  String businessName;
  String businessEmail;
  String businessPhone;
  String businessAddress;
  String? businessLogoPath;

  String clientName;
  String clientEmail;
  String clientPhone;
  String clientAddress;

  String receiptNumber;
  String paymentDate;
  String notes;
  String currency;

  List<LineItem> lineItems;

  double        taxRate;
  double        discountRate;
  PaymentMethod paymentMethod;
  ReceiptStatus status;
  String        fontFamily;
  ReceiptColor  colorScheme;

  ReceiptData({
    this.businessName     = '',
    this.businessEmail    = '',
    this.businessPhone    = '',
    this.businessAddress  = '',
    this.businessLogoPath,
    this.clientName       = '',
    this.clientEmail      = '',
    this.clientPhone      = '',
    this.clientAddress    = '',
    this.receiptNumber    = '',
    this.paymentDate      = '',
    this.notes            = '',
    this.currency         = 'USD',
    List<LineItem>? lineItems,
    this.taxRate          = 0.0,
    this.discountRate     = 0.0,
    this.paymentMethod    = PaymentMethod.cash,
    this.status           = ReceiptStatus.issued,
    this.fontFamily       = 'Roboto',
    this.colorScheme      = ReceiptColor.green,
  }) : lineItems = lineItems ?? [];

  // ── Computed totals ────────────────────────────────────────────────────────

  double get subtotal       => lineItems.fold(0.0, (sum, i) => sum + i.total);
  double get discountAmount => subtotal * (discountRate / 100);
  double get taxAmount      => (subtotal - discountAmount) * (taxRate / 100);
  double get amountPaid     => subtotal - discountAmount + taxAmount;

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
        'receiptNumber':    receiptNumber,
        'paymentDate':      paymentDate,
        'notes':            notes,
        'currency':         currency,
        'lineItems':        lineItems.map((i) => i.toJson()).toList(),
        'taxRate':          taxRate,
        'discountRate':     discountRate,
        'paymentMethod':    paymentMethod.name,
        'status':           status.name,
        'fontFamily':       fontFamily,
        'colorScheme':      colorScheme.name,
      };

  factory ReceiptData.fromJson(Map<String, dynamic> j) => ReceiptData(
        businessName:     j['businessName']     as String? ?? '',
        businessEmail:    j['businessEmail']    as String? ?? '',
        businessPhone:    j['businessPhone']    as String? ?? '',
        businessAddress:  j['businessAddress']  as String? ?? '',
        businessLogoPath: j['businessLogoPath'] as String?,
        clientName:       j['clientName']       as String? ?? '',
        clientEmail:      j['clientEmail']      as String? ?? '',
        clientPhone:      j['clientPhone']      as String? ?? '',
        clientAddress:    j['clientAddress']    as String? ?? '',
        receiptNumber:    j['receiptNumber']    as String? ?? '',
        paymentDate:      j['paymentDate']      as String? ?? '',
        notes:            j['notes']            as String? ?? '',
        currency:         j['currency']         as String? ?? 'USD',
        lineItems: (j['lineItems'] as List<dynamic>? ?? [])
            .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        taxRate:      (j['taxRate']      as num?)?.toDouble() ?? 0.0,
        discountRate: (j['discountRate'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: PaymentMethod.values.firstWhere(
          (p) => p.name == (j['paymentMethod'] as String? ?? ''),
          orElse: () => PaymentMethod.cash,
        ),
        status: ReceiptStatus.values.firstWhere(
          (s) => s.name == (j['status'] as String? ?? ''),
          orElse: () => ReceiptStatus.issued,
        ),
        fontFamily:  j['fontFamily'] as String? ?? 'Roboto',
        colorScheme: ReceiptColor.values.firstWhere(
          (c) => c.name == (j['colorScheme'] as String? ?? ''),
          orElse: () => ReceiptColor.green,
        ),
      );

  // ── copyWith ───────────────────────────────────────────────────────────────

  ReceiptData copyWith({
    String?         businessName,
    String?         businessEmail,
    String?         businessPhone,
    String?         businessAddress,
    String?         businessLogoPath,
    String?         clientName,
    String?         clientEmail,
    String?         clientPhone,
    String?         clientAddress,
    String?         receiptNumber,
    String?         paymentDate,
    String?         notes,
    String?         currency,
    List<LineItem>? lineItems,
    double?         taxRate,
    double?         discountRate,
    PaymentMethod?  paymentMethod,
    ReceiptStatus?  status,
    String?         fontFamily,
    ReceiptColor?   colorScheme,
  }) =>
      ReceiptData(
        businessName:     businessName     ?? this.businessName,
        businessEmail:    businessEmail    ?? this.businessEmail,
        businessPhone:    businessPhone    ?? this.businessPhone,
        businessAddress:  businessAddress  ?? this.businessAddress,
        businessLogoPath: businessLogoPath ?? this.businessLogoPath,
        clientName:       clientName       ?? this.clientName,
        clientEmail:      clientEmail      ?? this.clientEmail,
        clientPhone:      clientPhone      ?? this.clientPhone,
        clientAddress:    clientAddress    ?? this.clientAddress,
        receiptNumber:    receiptNumber    ?? this.receiptNumber,
        paymentDate:      paymentDate      ?? this.paymentDate,
        notes:            notes            ?? this.notes,
        currency:         currency         ?? this.currency,
        lineItems:        lineItems        ?? List<LineItem>.from(this.lineItems),
        taxRate:          taxRate          ?? this.taxRate,
        discountRate:     discountRate     ?? this.discountRate,
        paymentMethod:    paymentMethod    ?? this.paymentMethod,
        status:           status           ?? this.status,
        fontFamily:       fontFamily       ?? this.fontFamily,
        colorScheme:      colorScheme      ?? this.colorScheme,
      );

  ReceiptData deepCopy() => copyWith(
        lineItems: lineItems.map((i) => i.copyWith()).toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SavedReceipt  — wrapper stored in SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────

class SavedReceipt {
  final String      id;
  final String      title;
  final String      templateName;
  final ReceiptData data;
  final DateTime    createdAt;
  final DateTime    lastEditedAt;
  final int         completionPercent;
  final String?     folderName;

  SavedReceipt({
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
    return 'RC';
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

  factory SavedReceipt.fromJson(Map<String, dynamic> j) => SavedReceipt(
        id:               j['id']           as String,
        title:            j['title']        as String? ?? 'Receipt',
        templateName:     j['templateName'] as String? ?? '',
        data: ReceiptData.fromJson(j['data'] as Map<String, dynamic>? ?? {}),
        createdAt:    DateTime.parse(j['createdAt']    as String),
        lastEditedAt: DateTime.parse(j['lastEditedAt'] as String),
        completionPercent: j['completionPercent'] as int? ?? 0,
        folderName: j['folderName'] as String?,
      );

  // NEW: folderName/clearFolderName — same pattern as SavedInvoice.copyWith.
  SavedReceipt copyWith({
    String?      title,
    String?      templateName,
    ReceiptData? data,
    DateTime?    lastEditedAt,
    int?         completionPercent,
    String?      folderName,
    bool         clearFolderName = false,
  }) =>
      SavedReceipt(
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
