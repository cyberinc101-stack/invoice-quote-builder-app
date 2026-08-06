// invoice_data.dart
// lib/models/invoice_data.dart

// ─────────────────────────────────────────────────────────────────────────────
// LineItem
// ─────────────────────────────────────────────────────────────────────────────

class LineItem {
  String description;
  double quantity;
  double unitPrice;

  LineItem({
    this.description = '',
    this.quantity    = 1.0,
    this.unitPrice   = 0.0,
  });

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity':    quantity,
        'unitPrice':   unitPrice,
      };

  factory LineItem.fromJson(Map<String, dynamic> j) => LineItem(
        description: j['description'] as String? ?? '',
        quantity:    (j['quantity']   as num?)?.toDouble() ?? 1.0,
        unitPrice:   (j['unitPrice']  as num?)?.toDouble() ?? 0.0,
      );

  LineItem copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
  }) =>
      LineItem(
        description: description ?? this.description,
        quantity:    quantity    ?? this.quantity,
        unitPrice:   unitPrice   ?? this.unitPrice,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum PaymentStatus { unpaid, partial, paid, overdue }

enum InvoiceColor { blue, green, purple, orange, red, teal, black, indigo }

// ─────────────────────────────────────────────────────────────────────────────
// InvoiceData
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceData {
  String businessName;
  String businessEmail;
  String businessPhone;
  String businessAddress;
  String? businessLogoPath;

  String clientName;
  String clientEmail;
  String clientPhone;
  String clientAddress;

  String invoiceNumber;
  String issueDate;
  String dueDate;
  String notes;
  String currency;

  List<LineItem> lineItems;

  double        taxRate;
  double        discountRate;
  PaymentStatus paymentStatus;
  String        fontFamily;
  InvoiceColor  colorScheme;

  // NEW: system-stamped (not user-typed, unlike issueDate/dueDate) — set the
  // moment paymentStatus flips to PaymentStatus.paid, cleared if it's ever
  // changed away from paid. See InvoiceProvider.updateSavedInvoiceStatus.
  DateTime? paidDate;

  InvoiceData({
    this.businessName     = '',
    this.businessEmail    = '',
    this.businessPhone    = '',
    this.businessAddress  = '',
    this.businessLogoPath,
    this.clientName       = '',
    this.clientEmail      = '',
    this.clientPhone      = '',
    this.clientAddress    = '',
    this.invoiceNumber    = '',
    this.issueDate        = '',
    this.dueDate           = '',
    this.notes            = '',
    this.currency         = 'USD',
    List<LineItem>? lineItems,
    this.taxRate          = 0.0,
    this.discountRate     = 0.0,
    this.paymentStatus    = PaymentStatus.unpaid,
    this.fontFamily       = 'Roboto',
    this.colorScheme      = InvoiceColor.blue,
    this.paidDate,
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
        'invoiceNumber':    invoiceNumber,
        'issueDate':        issueDate,
        'dueDate':          dueDate,
        'notes':            notes,
        'currency':         currency,
        'lineItems':        lineItems.map((i) => i.toJson()).toList(),
        'taxRate':          taxRate,
        'discountRate':     discountRate,
        'paymentStatus':    paymentStatus.name,
        'fontFamily':       fontFamily,
        'colorScheme':      colorScheme.name,
        'paidDate':         paidDate?.toIso8601String(),
      };

  factory InvoiceData.fromJson(Map<String, dynamic> j) => InvoiceData(
        businessName:     j['businessName']     as String? ?? '',
        businessEmail:    j['businessEmail']    as String? ?? '',
        businessPhone:    j['businessPhone']    as String? ?? '',
        businessAddress:  j['businessAddress']  as String? ?? '',
        businessLogoPath: j['businessLogoPath'] as String?,
        clientName:       j['clientName']       as String? ?? '',
        clientEmail:      j['clientEmail']      as String? ?? '',
        clientPhone:      j['clientPhone']      as String? ?? '',
        clientAddress:    j['clientAddress']    as String? ?? '',
        invoiceNumber:    j['invoiceNumber']    as String? ?? '',
        issueDate:        j['issueDate']        as String? ?? '',
        dueDate:          j['dueDate']          as String? ?? '',
        notes:            j['notes']            as String? ?? '',
        currency:         j['currency']         as String? ?? 'USD',
        lineItems: (j['lineItems'] as List<dynamic>? ?? [])
            .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        taxRate:      (j['taxRate']      as num?)?.toDouble() ?? 0.0,
        discountRate: (j['discountRate'] as num?)?.toDouble() ?? 0.0,
        paymentStatus: PaymentStatus.values.firstWhere(
          (s) => s.name == (j['paymentStatus'] as String? ?? ''),
          orElse: () => PaymentStatus.unpaid,
        ),
        fontFamily:  j['fontFamily'] as String? ?? 'Roboto',
        colorScheme: InvoiceColor.values.firstWhere(
          (c) => c.name == (j['colorScheme'] as String? ?? ''),
          orElse: () => InvoiceColor.blue,
        ),
        paidDate: j['paidDate'] != null
            ? DateTime.tryParse(j['paidDate'] as String)
            : null,
      );

  // ── copyWith ───────────────────────────────────────────────────────────────
  //
  // clearPaidDate: pass true to explicitly wipe paidDate back to null — plain
  // `paidDate: null` alone can never clear an existing value through the
  // standard `?? this.paidDate` pattern (same reasoning as SavedInvoice's
  // clearFolderName).

  InvoiceData copyWith({
    String?         businessName,
    String?         businessEmail,
    String?         businessPhone,
    String?         businessAddress,
    String?         businessLogoPath,
    String?         clientName,
    String?         clientEmail,
    String?         clientPhone,
    String?         clientAddress,
    String?         invoiceNumber,
    String?         issueDate,
    String?         dueDate,
    String?         notes,
    String?         currency,
    List<LineItem>? lineItems,
    double?         taxRate,
    double?         discountRate,
    PaymentStatus?  paymentStatus,
    String?         fontFamily,
    InvoiceColor?   colorScheme,
    DateTime?       paidDate,
    bool            clearPaidDate = false,
  }) =>
      InvoiceData(
        businessName:     businessName     ?? this.businessName,
        businessEmail:    businessEmail    ?? this.businessEmail,
        businessPhone:    businessPhone    ?? this.businessPhone,
        businessAddress:  businessAddress  ?? this.businessAddress,
        businessLogoPath: businessLogoPath ?? this.businessLogoPath,
        clientName:       clientName       ?? this.clientName,
        clientEmail:      clientEmail      ?? this.clientEmail,
        clientPhone:      clientPhone      ?? this.clientPhone,
        clientAddress:    clientAddress    ?? this.clientAddress,
        invoiceNumber:    invoiceNumber    ?? this.invoiceNumber,
        issueDate:        issueDate        ?? this.issueDate,
        dueDate:          dueDate          ?? this.dueDate,
        notes:            notes            ?? this.notes,
        currency:         currency         ?? this.currency,
        lineItems:        lineItems        ?? List<LineItem>.from(this.lineItems),
        taxRate:          taxRate          ?? this.taxRate,
        discountRate:     discountRate     ?? this.discountRate,
        paymentStatus:    paymentStatus    ?? this.paymentStatus,
        fontFamily:       fontFamily       ?? this.fontFamily,
        colorScheme:      colorScheme      ?? this.colorScheme,
        paidDate: clearPaidDate ? null : (paidDate ?? this.paidDate),
      );

  InvoiceData deepCopy() => copyWith(
        lineItems: lineItems.map((i) => i.copyWith()).toList(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SavedInvoice  — wrapper stored in SharedPreferences
// ─────────────────────────────────────────────────────────────────────────────

class SavedInvoice {
  final String      id;
  final String      title;
  final String      templateName;
  final InvoiceData data;
  final DateTime    createdAt;
  final DateTime    lastEditedAt;
  final int         completionPercent;
  final String?     folderName;

  SavedInvoice({
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
    return 'IN';
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

  factory SavedInvoice.fromJson(Map<String, dynamic> j) => SavedInvoice(
        id:               j['id']           as String,
        title:            j['title']        as String? ?? 'Invoice',
        templateName:     j['templateName'] as String? ?? '',
        data: InvoiceData.fromJson(j['data'] as Map<String, dynamic>? ?? {}),
        createdAt:    DateTime.parse(j['createdAt']    as String),
        lastEditedAt: DateTime.parse(j['lastEditedAt'] as String),
        completionPercent: j['completionPercent'] as int? ?? 0,
        folderName: j['folderName'] as String?,
      );

  // NEW: folderName/clearFolderName — pass a folderName to set it, or pass
  // clearFolderName: true to explicitly wipe it back to null (needed since
  // `folderName: null ?? this.folderName` alone can never actually clear an
  // existing value).
  SavedInvoice copyWith({
    String?      title,
    String?      templateName,
    InvoiceData? data,
    DateTime?    lastEditedAt,
    int?         completionPercent,
    String?      folderName,
    bool         clearFolderName = false,
  }) =>
      SavedInvoice(
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