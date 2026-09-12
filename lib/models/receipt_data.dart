// receipt_data.dart
// lib/models/receipt_data.dart
//
// SIGNATURE PASS (this update): ReceiptData gains a three-mode
// Signature block, mirroring InvoiceData's/QuoteData's own signature
// fields exactly:
//   - signatureMode ('typed' | 'image' | 'blank' | '' deselected)
//   - signatureName / signatureImagePath / signatureFontSize (22.0) /
//     signatureFontFamily ('' — default italic look, or one of the six
//     google_fonts script families)
//   - showSignature (bool, default true) — Receipt uses individual
//     show* booleans rather than an enabledFields map, so the show/hide
//     toggle for Signature follows that same pattern.
// All new fields default to '' / 'blank' / null / 22.0 / '' / true so
// every persisted receipt loads exactly as before this pass. Rendered
// by executive_receipt_stationary_layout.dart's buildFooterSection via
// a new buildSignatureBlock() call and exported by
// receipt_pdf_service.dart's Executive PDF builder.
//
// All earlier passes (PER-ITEM TAX/DISCOUNT, TAX/DISCOUNT TOGGLE + NAME,
// CREATE-RECEIPT PARITY, CASHIER NAME TOGGLE, THANK YOU MESSAGE TOGGLE,
// RECEIPT DRAFT LIBRARY, FONT SIZE, LOGO FALLBACK MARK, WEBSITE +
// SOCIAL, PAPER FORMAT, THERMAL FIELDS, CURRENCY DISPLAY) — see prior
// header comments; unaffected by this update.

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

  String currencySymbol;
  String currencyDisplayMode;

  List<LineItem> lineItems;

  double        taxRate;
  double        discountRate;

  bool          taxEnabled;
  bool          discountEnabled;
  String        taxName;
  String        discountName;

  PaymentMethod paymentMethod;
  ReceiptStatus status;
  String        fontFamily;

  double        fontSize;

  ReceiptColor  colorScheme;

  int layoutTemplateId;
  String paperFormat;

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

  bool showCashierName;

  bool showThankYouMessage;
  String thankYouMessage;

  bool showBarcode;
  bool showQrCode;

  String qrData;
  String footerMessage;
  bool compactThermalLayout;

  bool showWebsite;
  String businessWebsite;

  bool showFacebook;
  String facebookHandle;
  bool showInstagram;
  String instagramHandle;
  bool showTwitter;
  String twitterHandle;

  bool excludeFromReports;

  // SIGNATURE PASS: three mutually exclusive modes, mirrors
  // InvoiceData's/QuoteData's identical fields exactly. showSignature
  // is Receipt's own show* boolean toggle (this model has no
  // enabledFields map), mirroring showThankYouMessage's identical
  // pattern.
  bool showSignature;
  String signatureMode; // 'typed' | 'image' | 'blank' | ''
  String signatureName;
  String? signatureImagePath;
  double signatureFontSize;
  String signatureFontFamily;

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
    this.taxEnabled        = true,
    this.discountEnabled   = true,
    this.taxName           = '',
    this.discountName      = '',
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
    this.showCashierName      = true,
    this.showThankYouMessage  = true,
    this.thankYouMessage      = 'Thank you for your purchase!',
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
    this.showSignature       = true,
    this.signatureMode       = 'blank',
    this.signatureName       = '',
    this.signatureImagePath,
    this.signatureFontSize   = 22.0,
    this.signatureFontFamily = '',
  }) : lineItems = lineItems ?? [];

  double get subtotal       => lineItems.fold(0.0, (sum, i) => sum + i.total);
  double get discountAmount => discountEnabled ? subtotal * (discountRate / 100) : 0.0;
  double get taxAmount      => taxEnabled ? (subtotal - discountAmount) * (taxRate / 100) : 0.0;

  double get itemTaxExtra => lineItems.fold(
      0.0,
      (sum, i) => sum +
          (i.taxEnabled
              ? (i.itemTaxIsAddition ? 1 : -1) * i.total * i.itemTaxRate / 100
              : 0.0));

  double get itemDiscountExtra => lineItems.fold(
      0.0,
      (sum, i) => sum + (i.discountEnabled ? i.total * i.itemDiscountRate / 100 : 0.0));

  Map<String, double> get itemTaxExtraByName {
    final map = <String, double>{};
    for (final i in lineItems) {
      if (!i.taxEnabled) continue;
      final key = i.itemTaxName.trim();
      final amt = (i.itemTaxIsAddition ? 1 : -1) * i.total * i.itemTaxRate / 100;
      map[key] = (map[key] ?? 0.0) + amt;
    }
    return map;
  }

  Map<String, double> get itemDiscountExtraByName {
    final map = <String, double>{};
    for (final i in lineItems) {
      if (!i.discountEnabled) continue;
      final key = i.itemDiscountName.trim();
      final amt = i.total * i.itemDiscountRate / 100;
      map[key] = (map[key] ?? 0.0) + amt;
    }
    return map;
  }

  double get amountPaid =>
      subtotal - discountAmount + taxAmount + itemTaxExtra - itemDiscountExtra;

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
        'taxEnabled':       taxEnabled,
        'discountEnabled':  discountEnabled,
        'taxName':          taxName,
        'discountName':     discountName,
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
        'showCashierName':      showCashierName,
        'showThankYouMessage':  showThankYouMessage,
        'thankYouMessage':      thankYouMessage,
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
        'showSignature':        showSignature,
        'signatureMode':        signatureMode,
        'signatureName':        signatureName,
        'signatureImagePath':   signatureImagePath,
        'signatureFontSize':    signatureFontSize,
        'signatureFontFamily':  signatureFontFamily,
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
        taxEnabled:      j['taxEnabled']      as bool?   ?? true,
        discountEnabled: j['discountEnabled'] as bool?   ?? true,
        taxName:         j['taxName']         as String? ?? '',
        discountName:    j['discountName']    as String? ?? '',
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
        showCashierName:      j['showCashierName']      as bool? ?? true,
        showThankYouMessage:  j['showThankYouMessage']  as bool? ?? true,
        thankYouMessage: j['thankYouMessage'] as String? ?? 'Thank you for your purchase!',
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
        showSignature:       j['showSignature']       as bool?   ?? true,
        signatureMode:       j['signatureMode']        as String? ?? 'blank',
        signatureName:       j['signatureName']        as String? ?? '',
        signatureImagePath:  j['signatureImagePath']   as String?,
        signatureFontSize:   (j['signatureFontSize']   as num?)?.toDouble() ?? 22.0,
        signatureFontFamily: j['signatureFontFamily']  as String? ?? '',
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
    bool?           taxEnabled,
    bool?           discountEnabled,
    String?         taxName,
    String?         discountName,
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
    bool?           showCashierName,
    bool?           showThankYouMessage,
    String?         thankYouMessage,
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
    bool?           showSignature,
    String?         signatureMode,
    String?         signatureName,
    String?         signatureImagePath,
    bool            clearSignatureImage = false,
    double?         signatureFontSize,
    String?         signatureFontFamily,
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
        taxEnabled:       taxEnabled       ?? this.taxEnabled,
        discountEnabled:  discountEnabled  ?? this.discountEnabled,
        taxName:          taxName          ?? this.taxName,
        discountName:     discountName     ?? this.discountName,
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
        showCashierName:      showCashierName      ?? this.showCashierName,
        showThankYouMessage:  showThankYouMessage  ?? this.showThankYouMessage,
        thankYouMessage:      thankYouMessage      ?? this.thankYouMessage,
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
        showSignature:       showSignature       ?? this.showSignature,
        signatureMode:       signatureMode       ?? this.signatureMode,
        signatureName:       signatureName       ?? this.signatureName,
        signatureImagePath: clearSignatureImage ? null : (signatureImagePath ?? this.signatureImagePath),
        signatureFontSize:   signatureFontSize   ?? this.signatureFontSize,
        signatureFontFamily: signatureFontFamily ?? this.signatureFontFamily,
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

// ─────────────────────────────────────────────────────────────────────────────
// SavedReceiptDraft
// ─────────────────────────────────────────────────────────────────────────────

class SavedReceiptDraft {
  String id;
  String name;
  ReceiptData data;
  DateTime createdAt;
  DateTime lastEditedAt;

  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;
  String logoShape;
  bool logoShowInitial;
  String logoInitialLetter;

  SavedReceiptDraft({
    required this.id,
    required this.name,
    required this.data,
    required this.createdAt,
    required this.lastEditedAt,
    this.logoPath,
    this.logoOffsetDx = 0.0,
    this.logoOffsetDy = 0.0,
    this.logoScale = 1.0,
    this.logoShape = 'roundedSquare',
    this.logoShowInitial = true,
    this.logoInitialLetter = '',
  });

  String get displayName {
    if (name.trim().isNotEmpty) return name.trim();
    if (data.clientName.trim().isNotEmpty) return data.clientName.trim();
    if (data.receiptNumber.trim().isNotEmpty) return data.receiptNumber.trim();
    return 'Untitled Draft';
  }

  int get itemCount => data.lineItems.length;
  double get total => data.amountPaid;

  String lastEditedDisplay() {
    final diff = DateTime.now().difference(lastEditedAt);
    if (diff.inMinutes < 1)  return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    if (diff.inDays    == 1) return 'Yesterday';
    if (diff.inDays    <  7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'data': data.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastEditedAt': lastEditedAt.toIso8601String(),
        'logoPath': logoPath,
        'logoOffsetDx': logoOffsetDx,
        'logoOffsetDy': logoOffsetDy,
        'logoScale': logoScale,
        'logoShape': logoShape,
        'logoShowInitial': logoShowInitial,
        'logoInitialLetter': logoInitialLetter,
      };

  factory SavedReceiptDraft.fromJson(Map<String, dynamic> j) => SavedReceiptDraft(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        data: ReceiptData.fromJson(j['data'] as Map<String, dynamic>? ?? {}),
        createdAt: DateTime.parse(j['createdAt'] as String),
        lastEditedAt: DateTime.parse(j['lastEditedAt'] as String),
        logoPath: j['logoPath'] as String?,
        logoOffsetDx: (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        logoOffsetDy: (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        logoScale: (j['logoScale'] as num?)?.toDouble() ?? 1.0,
        logoShape: j['logoShape'] as String? ?? 'roundedSquare',
        logoShowInitial: j['logoShowInitial'] as bool? ?? true,
        logoInitialLetter: j['logoInitialLetter'] as String? ?? '',
      );

  SavedReceiptDraft copyWith({
    String? name,
    ReceiptData? data,
    DateTime? lastEditedAt,
    String? logoPath,
    bool clearLogo = false,
    double? logoOffsetDx,
    double? logoOffsetDy,
    double? logoScale,
    String? logoShape,
    bool? logoShowInitial,
    String? logoInitialLetter,
  }) =>
      SavedReceiptDraft(
        id: id,
        name: name ?? this.name,
        data: data ?? this.data.deepCopy(),
        createdAt: createdAt,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
        logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
        logoOffsetDx: logoOffsetDx ?? this.logoOffsetDx,
        logoOffsetDy: logoOffsetDy ?? this.logoOffsetDy,
        logoScale: logoScale ?? this.logoScale,
        logoShape: logoShape ?? this.logoShape,
        logoShowInitial: logoShowInitial ?? this.logoShowInitial,
        logoInitialLetter: logoInitialLetter ?? this.logoInitialLetter,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SavedReceiptLineItem
// ─────────────────────────────────────────────────────────────────────────────

class SavedReceiptLineItem {
  String id;
  String? name;
  LineItem item;
  DateTime createdAt;
  DateTime lastEditedAt;

  SavedReceiptLineItem({
    required this.id,
    this.name,
    required this.item,
    required this.createdAt,
    required this.lastEditedAt,
  });

  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (item.description.trim().isNotEmpty) return item.description.trim();
    return 'Saved Item';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'item': item.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastEditedAt': lastEditedAt.toIso8601String(),
      };

  factory SavedReceiptLineItem.fromJson(Map<String, dynamic> j) => SavedReceiptLineItem(
        id: j['id'] as String,
        name: j['name'] as String?,
        item: LineItem.fromJson(j['item'] as Map<String, dynamic>? ?? {}),
        createdAt: DateTime.parse(j['createdAt'] as String),
        lastEditedAt: DateTime.parse(j['lastEditedAt'] as String),
      );

  SavedReceiptLineItem copyWith({
    String? name,
    bool clearName = false,
    LineItem? item,
    DateTime? lastEditedAt,
  }) =>
      SavedReceiptLineItem(
        id: id,
        name: clearName ? null : (name ?? this.name),
        item: item ?? this.item.copyWith(),
        createdAt: createdAt,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SavedReceiptLineItemSet
// ─────────────────────────────────────────────────────────────────────────────

class SavedReceiptLineItemSet {
  String id;
  String name;
  List<LineItem> items;

  SavedReceiptLineItemSet({
    required this.id,
    required this.name,
    required this.items,
  });

  int get itemCount => items.length;
  double get total => items.fold(0.0, (sum, i) => sum + i.total);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory SavedReceiptLineItemSet.fromJson(Map<String, dynamic> j) =>
      SavedReceiptLineItemSet(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  SavedReceiptLineItemSet copyWith({
    String? name,
    List<LineItem>? items,
  }) =>
      SavedReceiptLineItemSet(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items.map((i) => i.copyWith()).toList(),
      );
}
