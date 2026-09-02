// receipt_data.dart
// lib/models/receipt_data.dart
//
// FONT SIZE PASS (this update): added fontSize (double, default 12.0) —
// same gap as QuoteData: Receipt had a fontFamily field but no numeric
// size field, and no UI for either. Added so Receipt's Customise step
// can show Font Family + Text Size controls matching Invoice's, via the
// new receipt_step_customise.dart. Default (12.0) preserves existing
// render behaviour for every persisted receipt, no migration needed.
//
// LOGO FALLBACK MARK PASS (earlier): added businessLogoShowInitial
// (bool, default true) and businessLogoInitialLetter (String, default
// '') — mirrors InvoiceData/QuoteData's own new fields. See
// invoice_data.dart's doc comment for the full rationale. Defaults
// preserve existing render behaviour for every persisted receipt, no
// migration needed.
//
// WEBSITE + SOCIAL PASS (earlier): added businessWebsite/showWebsite
// and per-platform Facebook/Instagram/Twitter handle + toggle pairs
// (facebookHandle/showFacebook, etc). Each platform is independently
// shown/hidden and holds a plain @handle string — not a raw platform ID,
// per the recommendation that follows: a numeric/internal ID reads as
// broken on a receipt, an @handle next to an icon reads as normal. All
// default to off/empty so existing persisted receipts are unaffected.
//
// PAPER FORMAT PASS (earlier). THERMAL FIELDS PASS (earlier):
// cashierName/posId/taxId/paymentReference/authCode/cardLast4/show*/
// qrData/footerMessage/compactThermalLayout.
//
// CURRENCY DISPLAY PASS (earlier): added currencySymbol and
// currencyDisplayMode, mirroring InvoiceData/QuoteData's own fields —
// free text, no hardcoded currency list, defaults preserve existing
// render behaviour for persisted receipts.

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

  double businessLogoOffsetDx;
  double businessLogoOffsetDy;
  double businessLogoScale;
  String businessLogoShape;
  double businessLogoDisplaySize;

  // No-logo fallback mark — see LOGO FALLBACK MARK PASS above / the same
  // fields on InvoiceData. Only meaningful when businessLogoPath is NOT
  // set.
  bool businessLogoShowInitial;
  String businessLogoInitialLetter;

  String clientName;
  String clientEmail;
  String clientPhone;
  String clientAddress;

  String receiptNumber;
  String paymentDate;
  String notes;
  String currency;

  // Free-text currency symbol + display mode — see InvoiceData for the
  // full rationale. Not gated by any hardcoded currency list.
  String currencySymbol;
  String currencyDisplayMode; // 'code' | 'symbol' | 'both'

  List<LineItem> lineItems;

  double        taxRate;
  double        discountRate;
  PaymentMethod paymentMethod;
  ReceiptStatus status;
  String        fontFamily;

  // FONT SIZE PASS: numeric text size (points), mirrors
  // InvoiceProvider.fontSize / QuoteData.fontSize. Drives the new Text
  // Size slider on receipt_step_customise.dart.
  double        fontSize;

  ReceiptColor  colorScheme;

  int layoutTemplateId;
  String paperFormat;

  // ── Thermal / POS receipt fields ─────────────────────────────────────────
  String cashierName;
  String posId;
  String taxId;
  String paymentReference;
  String authCode;
  String cardLast4;

  bool showLogo;
  bool showBusinessDetails;
  bool showCustomerDetails;
  bool showReceiptNumber;
  bool showDateTime;
  bool showTaxLine;
  bool showDiscountLine;
  bool showPaymentMethod;
  bool showBarcode;
  bool showQrCode;

  String qrData;
  String footerMessage;
  bool compactThermalLayout;

  // ── Website + social — thermal footer only ───────────────────────────────
  bool showWebsite;
  String businessWebsite;

  bool showFacebook;
  String facebookHandle;
  bool showInstagram;
  String instagramHandle;
  bool showTwitter;
  String twitterHandle;

  bool excludeFromReports;

  ReceiptData({
    this.businessName     = '',
    this.businessEmail    = '',
    this.businessPhone    = '',
    this.businessAddress  = '',
    this.businessLogoPath,
    this.businessLogoOffsetDx = 0.0,
    this.businessLogoOffsetDy = 0.0,
    this.businessLogoScale    = 1.0,
    this.businessLogoShape    = 'roundedSquare',
    this.businessLogoDisplaySize = 40.0,
    this.businessLogoShowInitial = true,
    this.businessLogoInitialLetter = '',
    this.clientName       = '',
    this.clientEmail      = '',
    this.clientPhone      = '',
    this.clientAddress    = '',
    this.receiptNumber    = '',
    this.paymentDate      = '',
    this.notes            = '',
    this.currency         = 'USD',
    this.currencySymbol      = '',
    this.currencyDisplayMode = 'code',
    List<LineItem>? lineItems,
    this.taxRate          = 0.0,
    this.discountRate     = 0.0,
    this.paymentMethod    = PaymentMethod.cash,
    this.status           = ReceiptStatus.issued,
    this.fontFamily       = 'Roboto',
    this.fontSize         = 12.0,
    this.colorScheme      = ReceiptColor.green,
    this.layoutTemplateId = 1,
    this.paperFormat      = 'a4',
    this.cashierName        = '',
    this.posId              = '',
    this.taxId               = '',
    this.paymentReference   = '',
    this.authCode            = '',
    this.cardLast4           = '',
    this.showLogo             = true,
    this.showBusinessDetails  = true,
    this.showCustomerDetails  = true,
    this.showReceiptNumber    = true,
    this.showDateTime         = true,
    this.showTaxLine          = true,
    this.showDiscountLine     = true,
    this.showPaymentMethod    = true,
    this.showBarcode          = false,
    this.showQrCode           = false,
    this.qrData                = '',
    this.footerMessage         = 'Thank you for your purchase!',
    this.compactThermalLayout  = false,
    this.showWebsite          = false,
    this.businessWebsite      = '',
    this.showFacebook         = false,
    this.facebookHandle       = '',
    this.showInstagram        = false,
    this.instagramHandle      = '',
    this.showTwitter          = false,
    this.twitterHandle        = '',
    this.excludeFromReports = false,
  }) : lineItems = lineItems ?? [];

  double get subtotal       => lineItems.fold(0.0, (sum, i) => sum + i.total);
  double get discountAmount => subtotal * (discountRate / 100);
  double get taxAmount      => (subtotal - discountAmount) * (taxRate / 100);
  double get amountPaid     => subtotal - discountAmount + taxAmount;

  Map<String, dynamic> toJson() => {
        'businessName':     businessName,
        'businessEmail':    businessEmail,
        'businessPhone':    businessPhone,
        'businessAddress':  businessAddress,
        'businessLogoPath': businessLogoPath,
        'businessLogoOffsetDx': businessLogoOffsetDx,
        'businessLogoOffsetDy': businessLogoOffsetDy,
        'businessLogoScale':    businessLogoScale,
        'businessLogoShape':    businessLogoShape,
        'businessLogoDisplaySize': businessLogoDisplaySize,
        'businessLogoShowInitial': businessLogoShowInitial,
        'businessLogoInitialLetter': businessLogoInitialLetter,
        'clientName':       clientName,
        'clientEmail':      clientEmail,
        'clientPhone':      clientPhone,
        'clientAddress':    clientAddress,
        'receiptNumber':    receiptNumber,
        'paymentDate':      paymentDate,
        'notes':            notes,
        'currency':         currency,
        'currencySymbol':      currencySymbol,
        'currencyDisplayMode': currencyDisplayMode,
        'lineItems':        lineItems.map((i) => i.toJson()).toList(),
        'taxRate':          taxRate,
        'discountRate':     discountRate,
        'paymentMethod':    paymentMethod.name,
        'status':           status.name,
        'fontFamily':       fontFamily,
        'fontSize':         fontSize,
        'colorScheme':      colorScheme.name,
        'layoutTemplateId': layoutTemplateId,
        'paperFormat':      paperFormat,
        'cashierName':      cashierName,
        'posId':            posId,
        'taxId':            taxId,
        'paymentReference': paymentReference,
        'authCode':         authCode,
        'cardLast4':        cardLast4,
        'showLogo':             showLogo,
        'showBusinessDetails':  showBusinessDetails,
        'showCustomerDetails':  showCustomerDetails,
        'showReceiptNumber':    showReceiptNumber,
        'showDateTime':         showDateTime,
        'showTaxLine':          showTaxLine,
        'showDiscountLine':     showDiscountLine,
        'showPaymentMethod':    showPaymentMethod,
        'showBarcode':          showBarcode,
        'showQrCode':           showQrCode,
        'qrData':               qrData,
        'footerMessage':        footerMessage,
        'compactThermalLayout': compactThermalLayout,
        'showWebsite':          showWebsite,
        'businessWebsite':      businessWebsite,
        'showFacebook':         showFacebook,
        'facebookHandle':       facebookHandle,
        'showInstagram':        showInstagram,
        'instagramHandle':      instagramHandle,
        'showTwitter':          showTwitter,
        'twitterHandle':        twitterHandle,
        'excludeFromReports': excludeFromReports,
      };

  factory ReceiptData.fromJson(Map<String, dynamic> j) => ReceiptData(
        businessName:     j['businessName']     as String? ?? '',
        businessEmail:    j['businessEmail']    as String? ?? '',
        businessPhone:    j['businessPhone']    as String? ?? '',
        businessAddress:  j['businessAddress']  as String? ?? '',
        businessLogoPath: j['businessLogoPath'] as String?,
        businessLogoOffsetDx: (j['businessLogoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        businessLogoOffsetDy: (j['businessLogoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        businessLogoScale:    (j['businessLogoScale']    as num?)?.toDouble() ?? 1.0,
        businessLogoShape:    j['businessLogoShape']      as String? ?? 'roundedSquare',
        businessLogoDisplaySize: (j['businessLogoDisplaySize'] as num?)?.toDouble() ?? 40.0,
        businessLogoShowInitial: j['businessLogoShowInitial'] as bool? ?? true,
        businessLogoInitialLetter: j['businessLogoInitialLetter'] as String? ?? '',
        clientName:       j['clientName']       as String? ?? '',
        clientEmail:      j['clientEmail']      as String? ?? '',
        clientPhone:      j['clientPhone']      as String? ?? '',
        clientAddress:    j['clientAddress']    as String? ?? '',
        receiptNumber:    j['receiptNumber']    as String? ?? '',
        paymentDate:      j['paymentDate']      as String? ?? '',
        notes:            j['notes']            as String? ?? '',
        currency:         j['currency']         as String? ?? 'USD',
        currencySymbol:      j['currencySymbol'] as String? ?? '',
        currencyDisplayMode: j['currencyDisplayMode'] as String? ?? 'code',
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
        fontSize:    (j['fontSize'] as num?)?.toDouble() ?? 12.0,
        colorScheme: ReceiptColor.values.firstWhere(
          (c) => c.name == (j['colorScheme'] as String? ?? ''),
          orElse: () => ReceiptColor.green,
        ),
        layoutTemplateId: (j['layoutTemplateId'] as num?)?.toInt() ?? 1,
        paperFormat: j['paperFormat'] as String? ?? 'a4',
        cashierName:      j['cashierName']      as String? ?? '',
        posId:            j['posId']            as String? ?? '',
        taxId:            j['taxId']            as String? ?? '',
        paymentReference: j['paymentReference'] as String? ?? '',
        authCode:         j['authCode']         as String? ?? '',
        cardLast4:        j['cardLast4']        as String? ?? '',
        showLogo:             j['showLogo']             as bool? ?? true,
        showBusinessDetails:  j['showBusinessDetails']  as bool? ?? true,
        showCustomerDetails:  j['showCustomerDetails']  as bool? ?? true,
        showReceiptNumber:    j['showReceiptNumber']    as bool? ?? true,
        showDateTime:         j['showDateTime']         as bool? ?? true,
        showTaxLine:          j['showTaxLine']          as bool? ?? true,
        showDiscountLine:     j['showDiscountLine']     as bool? ?? true,
        showPaymentMethod:    j['showPaymentMethod']    as bool? ?? true,
        showBarcode:          j['showBarcode']          as bool? ?? false,
        showQrCode:           j['showQrCode']           as bool? ?? false,
        qrData:               j['qrData']               as String? ?? '',
        footerMessage: j['footerMessage'] as String? ?? 'Thank you for your purchase!',
        compactThermalLayout: j['compactThermalLayout'] as bool? ?? false,
        showWebsite:     j['showWebsite']     as bool?   ?? false,
        businessWebsite: j['businessWebsite'] as String? ?? '',
        showFacebook:    j['showFacebook']    as bool?   ?? false,
        facebookHandle:  j['facebookHandle']  as String? ?? '',
        showInstagram:   j['showInstagram']   as bool?   ?? false,
        instagramHandle: j['instagramHandle'] as String? ?? '',
        showTwitter:     j['showTwitter']     as bool?   ?? false,
        twitterHandle:   j['twitterHandle']   as String? ?? '',
        excludeFromReports: j['excludeFromReports'] as bool? ?? false,
      );

  ReceiptData copyWith({
    String?         businessName,
    String?         businessEmail,
    String?         businessPhone,
    String?         businessAddress,
    String?         businessLogoPath,
    bool            clearBusinessLogo = false,
    double?         businessLogoOffsetDx,
    double?         businessLogoOffsetDy,
    double?         businessLogoScale,
    String?         businessLogoShape,
    double?         businessLogoDisplaySize,
    bool?           businessLogoShowInitial,
    String?         businessLogoInitialLetter,
    String?         clientName,
    String?         clientEmail,
    String?         clientPhone,
    String?         clientAddress,
    String?         receiptNumber,
    String?         paymentDate,
    String?         notes,
    String?         currency,
    String?         currencySymbol,
    String?         currencyDisplayMode,
    List<LineItem>? lineItems,
    double?         taxRate,
    double?         discountRate,
    PaymentMethod?  paymentMethod,
    ReceiptStatus?  status,
    String?         fontFamily,
    double?         fontSize,
    ReceiptColor?   colorScheme,
    int?            layoutTemplateId,
    String?         paperFormat,
    String?         cashierName,
    String?         posId,
    String?         taxId,
    String?         paymentReference,
    String?         authCode,
    String?         cardLast4,
    bool?           showLogo,
    bool?           showBusinessDetails,
    bool?           showCustomerDetails,
    bool?           showReceiptNumber,
    bool?           showDateTime,
    bool?           showTaxLine,
    bool?           showDiscountLine,
    bool?           showPaymentMethod,
    bool?           showBarcode,
    bool?           showQrCode,
    String?         qrData,
    String?         footerMessage,
    bool?           compactThermalLayout,
    bool?           showWebsite,
    String?         businessWebsite,
    bool?           showFacebook,
    String?         facebookHandle,
    bool?           showInstagram,
    String?         instagramHandle,
    bool?           showTwitter,
    String?         twitterHandle,
    bool?           excludeFromReports,
  }) =>
      ReceiptData(
        businessName:     businessName     ?? this.businessName,
        businessEmail:    businessEmail    ?? this.businessEmail,
        businessPhone:    businessPhone    ?? this.businessPhone,
        businessAddress:  businessAddress  ?? this.businessAddress,
        businessLogoPath: clearBusinessLogo ? null : (businessLogoPath ?? this.businessLogoPath),
        businessLogoOffsetDx: businessLogoOffsetDx ?? this.businessLogoOffsetDx,
        businessLogoOffsetDy: businessLogoOffsetDy ?? this.businessLogoOffsetDy,
        businessLogoScale:    businessLogoScale    ?? this.businessLogoScale,
        businessLogoShape:    businessLogoShape    ?? this.businessLogoShape,
        businessLogoDisplaySize: businessLogoDisplaySize ?? this.businessLogoDisplaySize,
        businessLogoShowInitial: businessLogoShowInitial ?? this.businessLogoShowInitial,
        businessLogoInitialLetter: businessLogoInitialLetter ?? this.businessLogoInitialLetter,
        clientName:       clientName       ?? this.clientName,
        clientEmail:      clientEmail      ?? this.clientEmail,
        clientPhone:      clientPhone      ?? this.clientPhone,
        clientAddress:    clientAddress    ?? this.clientAddress,
        receiptNumber:    receiptNumber    ?? this.receiptNumber,
        paymentDate:      paymentDate      ?? this.paymentDate,
        notes:            notes            ?? this.notes,
        currency:         currency         ?? this.currency,
        currencySymbol:      currencySymbol      ?? this.currencySymbol,
        currencyDisplayMode: currencyDisplayMode ?? this.currencyDisplayMode,
        lineItems:        lineItems        ?? List<LineItem>.from(this.lineItems),
        taxRate:          taxRate          ?? this.taxRate,
        discountRate:     discountRate     ?? this.discountRate,
        paymentMethod:    paymentMethod    ?? this.paymentMethod,
        status:           status           ?? this.status,
        fontFamily:       fontFamily       ?? this.fontFamily,
        fontSize:         fontSize         ?? this.fontSize,
        colorScheme:      colorScheme      ?? this.colorScheme,
        layoutTemplateId: layoutTemplateId ?? this.layoutTemplateId,
        paperFormat:      paperFormat      ?? this.paperFormat,
        cashierName:      cashierName      ?? this.cashierName,
        posId:            posId            ?? this.posId,
        taxId:            taxId            ?? this.taxId,
        paymentReference: paymentReference ?? this.paymentReference,
        authCode:         authCode         ?? this.authCode,
        cardLast4:        cardLast4        ?? this.cardLast4,
        showLogo:             showLogo             ?? this.showLogo,
        showBusinessDetails:  showBusinessDetails  ?? this.showBusinessDetails,
        showCustomerDetails:  showCustomerDetails  ?? this.showCustomerDetails,
        showReceiptNumber:    showReceiptNumber    ?? this.showReceiptNumber,
        showDateTime:         showDateTime         ?? this.showDateTime,
        showTaxLine:          showTaxLine          ?? this.showTaxLine,
        showDiscountLine:     showDiscountLine     ?? this.showDiscountLine,
        showPaymentMethod:    showPaymentMethod    ?? this.showPaymentMethod,
        showBarcode:          showBarcode          ?? this.showBarcode,
        showQrCode:           showQrCode           ?? this.showQrCode,
        qrData:               qrData               ?? this.qrData,
        footerMessage:        footerMessage        ?? this.footerMessage,
        compactThermalLayout: compactThermalLayout ?? this.compactThermalLayout,
        showWebsite:      showWebsite      ?? this.showWebsite,
        businessWebsite:  businessWebsite  ?? this.businessWebsite,
        showFacebook:     showFacebook     ?? this.showFacebook,
        facebookHandle:   facebookHandle   ?? this.facebookHandle,
        showInstagram:    showInstagram    ?? this.showInstagram,
        instagramHandle:  instagramHandle  ?? this.instagramHandle,
        showTwitter:      showTwitter      ?? this.showTwitter,
        twitterHandle:    twitterHandle    ?? this.twitterHandle,
        excludeFromReports: excludeFromReports ?? this.excludeFromReports,
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
