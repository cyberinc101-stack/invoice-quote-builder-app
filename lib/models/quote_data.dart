import 'invoice_data.dart' show LineItem;
import 'address_info.dart';
import 'footer_tagline.dart';

enum QuoteStatus { draft, sent, accepted, declined, expired }

enum QuoteColor { blue, green, purple, orange, red, teal, black, indigo }

Map<String, bool> defaultQuoteEnabledFields() => {
      'invoiceNumber': true, 'date': true, 'dueDate': true,
      'tax': true, 'discount': true,
      'notes': true, 'thankYouMessage': true,
      'customerName': true, 'customerEmail': true, 'customerPhone': true,
      'customerAddress': true,
      'businessName': true, 'businessEmail': true, 'businessPhone': true,
      'businessAddress': true,
      'businessLogo': true,
      'signature': true,
      'bankName': true, 'accountName': true, 'accountNumber': true,
      'otherPaymentDetails': true,
      'termsAndConditions': true,
    };

class QuoteData {
  String businessName;
  String businessTagline;
  bool businessTaglineEnabled;
  bool footerTaglinesEnabled;
  // TAGLINE SIZE PASS: font size (pt) for footer tagline text —
  // adjustable via the Customise step. Clamped in the UI to a
  // range that, combined with autoFitText's own shrink-to-fit,
  // cannot overflow the footer band even at max size with 6 items.
  double footerTaglinesFontSize;
  List<FooterTaglineItem> footerTaglines;
  String businessEmail;
  String businessPhone;
  String businessAddress;
  AddressInfo businessAddressInfo;
  String? businessLogoPath;

  double businessLogoOffsetDx;
  double businessLogoOffsetDy;
  double businessLogoScale;
  String businessLogoShape;
  double businessLogoDisplaySize;

  bool businessLogoShowInitial;
  String businessLogoInitialLetter;

  // BACKGROUND-IMAGE PASS: mirrors InvoiceData's identical new fields —
  // see that file's header comment for the full rationale. Both
  // null/false by default, so every existing persisted quote loads and
  // renders exactly as before this pass.
  String? headerBackgroundImagePath;
  bool headerBackgroundEnabled;
  double headerBackgroundOpacity;
  double headerBackgroundOffsetDx;
  double headerBackgroundOffsetDy;
  double headerBackgroundScale;
  String? footerBackgroundImagePath;
  bool footerBackgroundEnabled;
  double footerBackgroundOpacity;
  double footerBackgroundOffsetDx;
  double footerBackgroundOffsetDy;
  double footerBackgroundScale;

  // MID-PAGE BACKGROUND PASS: mirrors InvoiceData's identical new
  // fields — see that file's header comment for the full rationale.
  String? bodyBackgroundImagePath;
  bool bodyBackgroundEnabled;
  double bodyBackgroundOpacity;
  double bodyBackgroundOffsetDx;
  double bodyBackgroundOffsetDy;
  double bodyBackgroundScale;

  String clientName;
  String clientEmail;
  String clientPhone;
  String clientAddress;

  AddressInfo clientAddressInfo;

  String quoteNumber;
  String issueDate;
  String expiryDate;
  String notes;
  String currency;

  String currencySymbol;
  String currencyDisplayMode;

  List<LineItem> lineItems;

  double      taxRate;
  double      discountRate;

  String taxName;
  String discountName;

  bool taxEnabled;
  bool discountEnabled;

  QuoteStatus quoteStatus;
  String      fontFamily;

  double      fontSize;

  QuoteColor  colorScheme;

  int layoutTemplateId;

  Map<String, bool> enabledFields;

  String? sourceTemplateId;
  String? sourceClientId;

  bool excludeFromReports;

  bool statusHidden;

  String signatureMode;
  String signatureName;
  String? signatureImagePath;
  double signatureFontSize;
  String signatureFontFamily;

  String bankName;
  String accountName;
  String accountNumber;
  String otherPaymentDetails;

  String termsAndConditions;

  QuoteData({
    this.businessName     = '',
    this.businessTagline  = '',
    this.businessTaglineEnabled = true,
    this.footerTaglinesEnabled = false,
    this.footerTaglinesFontSize = 8.0,
    List<FooterTaglineItem>? footerTaglines,
    this.businessEmail    = '',
    this.businessPhone    = '',
    this.businessAddress  = '',
    AddressInfo? businessAddressInfo,
    this.businessLogoPath,
    this.businessLogoOffsetDx = 0.0,
    this.businessLogoOffsetDy = 0.0,
    this.businessLogoScale    = 1.0,
    this.businessLogoShape    = 'roundedSquare',
    this.businessLogoDisplaySize = 40.0,
    this.businessLogoShowInitial = true,
    this.businessLogoInitialLetter = '',
    this.headerBackgroundImagePath,
    this.headerBackgroundEnabled = false,
    this.headerBackgroundOpacity = 1.0,
    this.headerBackgroundOffsetDx = 0.0,
    this.headerBackgroundOffsetDy = 0.0,
    this.headerBackgroundScale = 1.0,
    this.footerBackgroundImagePath,
    this.footerBackgroundEnabled = false,
    this.footerBackgroundOpacity = 1.0,
    this.footerBackgroundOffsetDx = 0.0,
    this.footerBackgroundOffsetDy = 0.0,
    this.footerBackgroundScale = 1.0,
    this.bodyBackgroundImagePath,
    this.bodyBackgroundEnabled = false,
    this.bodyBackgroundOpacity = 1.0,
    this.bodyBackgroundOffsetDx = 0.0,
    this.bodyBackgroundOffsetDy = 0.0,
    this.bodyBackgroundScale = 1.0,
    this.clientName       = '',
    this.clientEmail      = '',
    this.clientPhone      = '',
    this.clientAddress    = '',
    AddressInfo? clientAddressInfo,
    this.quoteNumber      = '',
    this.issueDate        = '',
    this.expiryDate       = '',
    this.notes            = '',
    this.currency         = 'USD',
    this.currencySymbol      = '',
    this.currencyDisplayMode = 'code',
    List<LineItem>? lineItems,
    this.taxRate          = 0.0,
    this.discountRate     = 0.0,
    this.taxName          = '',
    this.discountName     = '',
    this.taxEnabled       = true,
    this.discountEnabled  = true,
    this.quoteStatus      = QuoteStatus.draft,
    this.fontFamily       = 'Roboto',
    this.fontSize         = 12.0,
    this.colorScheme      = QuoteColor.purple,
    this.layoutTemplateId = 1,
    Map<String, bool>? enabledFields,
    this.sourceTemplateId,
    this.sourceClientId,
    this.excludeFromReports = false,
    this.statusHidden        = false,
    this.signatureMode       = 'blank',
    this.signatureName       = '',
    this.signatureImagePath,
    this.signatureFontSize   = 22.0,
    this.signatureFontFamily = '',
    this.bankName            = '',
    this.accountName         = '',
    this.accountNumber       = '',
    this.otherPaymentDetails = '',
    this.termsAndConditions  = '',
  }) : lineItems = lineItems ?? [],
       enabledFields = enabledFields ?? defaultQuoteEnabledFields(),
       clientAddressInfo = clientAddressInfo ?? AddressInfo(),
       businessAddressInfo = businessAddressInfo ?? AddressInfo(),
       footerTaglines = footerTaglines ?? [];

  double get subtotal       => lineItems.fold(0.0, (sum, i) => sum + i.total);
  double get discountAmount => discountEnabled ? subtotal * (discountRate / 100) : 0.0;
  double get taxAmount      => taxEnabled ? (subtotal - discountAmount) * (taxRate / 100) : 0.0;

  double get itemTaxExtra => lineItems.fold(
      0.0,
      (sum, i) => sum +
          (i.taxEnabled
              ? (i.itemTaxIsAddition ? 1 : -1) * i.total * i.itemTaxRate / 100
              : 0.0));

  double get itemDiscountExtra => lineItems.fold(0.0,
      (sum, i) => sum + (i.discountEnabled ? i.total * i.itemDiscountRate / 100 : 0.0));

  double get grandTotal =>
      subtotal - discountAmount + taxAmount - itemDiscountExtra + itemTaxExtra;

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

  Map<String, dynamic> toJson() => {
        'businessName':     businessName,
        'businessTagline':  businessTagline,
        'businessTaglineEnabled': businessTaglineEnabled,
        'footerTaglinesEnabled':  footerTaglinesEnabled,
        'footerTaglinesFontSize': footerTaglinesFontSize,
        'footerTaglines':   footerTaglinesToJson(footerTaglines),
        'businessEmail':    businessEmail,
        'businessPhone':    businessPhone,
        'businessAddress':  businessAddress,
        'businessAddressInfo': businessAddressInfo.toJson(),
        'businessLogoPath': businessLogoPath,
        'businessLogoOffsetDx': businessLogoOffsetDx,
        'businessLogoOffsetDy': businessLogoOffsetDy,
        'businessLogoScale':    businessLogoScale,
        'businessLogoShape':    businessLogoShape,
        'businessLogoDisplaySize': businessLogoDisplaySize,
        'businessLogoShowInitial': businessLogoShowInitial,
        'businessLogoInitialLetter': businessLogoInitialLetter,
        'headerBackgroundImagePath': headerBackgroundImagePath,
        'headerBackgroundEnabled':   headerBackgroundEnabled,
        'headerBackgroundOpacity': headerBackgroundOpacity,
        'headerBackgroundOffsetDx': headerBackgroundOffsetDx,
        'headerBackgroundOffsetDy': headerBackgroundOffsetDy,
        'headerBackgroundScale': headerBackgroundScale,
        'footerBackgroundImagePath': footerBackgroundImagePath,
        'footerBackgroundEnabled':   footerBackgroundEnabled,
        'footerBackgroundOpacity': footerBackgroundOpacity,
        'footerBackgroundOffsetDx': footerBackgroundOffsetDx,
        'footerBackgroundOffsetDy': footerBackgroundOffsetDy,
        'footerBackgroundScale': footerBackgroundScale,
        'bodyBackgroundImagePath': bodyBackgroundImagePath,
        'bodyBackgroundEnabled':   bodyBackgroundEnabled,
        'bodyBackgroundOpacity': bodyBackgroundOpacity,
        'bodyBackgroundOffsetDx': bodyBackgroundOffsetDx,
        'bodyBackgroundOffsetDy': bodyBackgroundOffsetDy,
        'bodyBackgroundScale': bodyBackgroundScale,
        'clientName':       clientName,
        'clientEmail':      clientEmail,
        'clientPhone':      clientPhone,
        'clientAddress':    clientAddress,
        'clientAddressInfo': clientAddressInfo.toJson(),
        'quoteNumber':      quoteNumber,
        'issueDate':        issueDate,
        'expiryDate':       expiryDate,
        'notes':            notes,
        'currency':         currency,
        'currencySymbol':      currencySymbol,
        'currencyDisplayMode': currencyDisplayMode,
        'lineItems':        lineItems.map((i) => i.toJson()).toList(),
        'taxRate':          taxRate,
        'discountRate':     discountRate,
        'taxName':          taxName,
        'discountName':     discountName,
        'taxEnabled':       taxEnabled,
        'discountEnabled':  discountEnabled,
        'quoteStatus':      quoteStatus.name,
        'fontFamily':       fontFamily,
        'fontSize':         fontSize,
        'colorScheme':      colorScheme.name,
        'layoutTemplateId': layoutTemplateId,
        'enabledFields':    enabledFields,
        'sourceTemplateId': sourceTemplateId,
        'sourceClientId':   sourceClientId,
        'excludeFromReports': excludeFromReports,
        'statusHidden':        statusHidden,
        'signatureMode':       signatureMode,
        'signatureName':       signatureName,
        'signatureImagePath':  signatureImagePath,
        'signatureFontSize':   signatureFontSize,
        'signatureFontFamily': signatureFontFamily,
        'bankName':            bankName,
        'accountName':         accountName,
        'accountNumber':       accountNumber,
        'otherPaymentDetails': otherPaymentDetails,
        'termsAndConditions':  termsAndConditions,
      };

  factory QuoteData.fromJson(Map<String, dynamic> j) => QuoteData(
        businessName:     j['businessName']     as String? ?? '',
        businessTagline:  j['businessTagline']  as String? ?? '',
        businessTaglineEnabled: j['businessTaglineEnabled'] as bool? ?? true,
        footerTaglinesEnabled:  j['footerTaglinesEnabled']  as bool? ?? false,
        footerTaglinesFontSize: (j['footerTaglinesFontSize'] as num?)?.toDouble() ?? 8.0,
        footerTaglines:   footerTaglinesFromJson(j['footerTaglines']),
        businessEmail:    j['businessEmail']    as String? ?? '',
        businessPhone:    j['businessPhone']    as String? ?? '',
        businessAddress:  j['businessAddress']  as String? ?? '',
        businessAddressInfo: AddressInfo.fromJson(
            j['businessAddressInfo'] ?? j['businessAddress']),
        businessLogoPath: j['businessLogoPath'] as String?,
        businessLogoOffsetDx: (j['businessLogoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        businessLogoOffsetDy: (j['businessLogoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        businessLogoScale:    (j['businessLogoScale']    as num?)?.toDouble() ?? 1.0,
        businessLogoShape:    j['businessLogoShape']      as String? ?? 'roundedSquare',
        businessLogoDisplaySize: (j['businessLogoDisplaySize'] as num?)?.toDouble() ?? 40.0,
        businessLogoShowInitial: j['businessLogoShowInitial'] as bool? ?? true,
        businessLogoInitialLetter: j['businessLogoInitialLetter'] as String? ?? '',
        headerBackgroundImagePath: j['headerBackgroundImagePath'] as String?,
        headerBackgroundEnabled:   j['headerBackgroundEnabled']   as bool?   ?? false,
        headerBackgroundOpacity: (j['headerBackgroundOpacity'] as num?)?.toDouble() ?? 1.0,
        headerBackgroundOffsetDx: (j['headerBackgroundOffsetDx'] as num?)?.toDouble() ?? 0.0,
        headerBackgroundOffsetDy: (j['headerBackgroundOffsetDy'] as num?)?.toDouble() ?? 0.0,
        headerBackgroundScale: (j['headerBackgroundScale'] as num?)?.toDouble() ?? 1.0,
        footerBackgroundImagePath: j['footerBackgroundImagePath'] as String?,
        footerBackgroundEnabled:   j['footerBackgroundEnabled']   as bool?   ?? false,
        footerBackgroundOpacity: (j['footerBackgroundOpacity'] as num?)?.toDouble() ?? 1.0,
        footerBackgroundOffsetDx: (j['footerBackgroundOffsetDx'] as num?)?.toDouble() ?? 0.0,
        footerBackgroundOffsetDy: (j['footerBackgroundOffsetDy'] as num?)?.toDouble() ?? 0.0,
        footerBackgroundScale: (j['footerBackgroundScale'] as num?)?.toDouble() ?? 1.0,
        bodyBackgroundImagePath: j['bodyBackgroundImagePath'] as String?,
        bodyBackgroundEnabled:   j['bodyBackgroundEnabled']   as bool?   ?? false,
        bodyBackgroundOpacity: (j['bodyBackgroundOpacity'] as num?)?.toDouble() ?? 1.0,
        bodyBackgroundOffsetDx: (j['bodyBackgroundOffsetDx'] as num?)?.toDouble() ?? 0.0,
        bodyBackgroundOffsetDy: (j['bodyBackgroundOffsetDy'] as num?)?.toDouble() ?? 0.0,
        bodyBackgroundScale: (j['bodyBackgroundScale'] as num?)?.toDouble() ?? 1.0,
        clientName:       j['clientName']       as String? ?? '',
        clientEmail:      j['clientEmail']      as String? ?? '',
        clientPhone:      j['clientPhone']      as String? ?? '',
        clientAddress:    j['clientAddress']    as String? ?? '',
        clientAddressInfo: AddressInfo.fromJson(
            j['clientAddressInfo'] ?? j['clientAddress']),
        quoteNumber:      j['quoteNumber']      as String? ?? '',
        issueDate:        j['issueDate']        as String? ?? '',
        expiryDate:       j['expiryDate']       as String? ?? '',
        notes:            j['notes']            as String? ?? '',
        currency:         j['currency']         as String? ?? 'USD',
        currencySymbol:      j['currencySymbol'] as String? ?? '',
        currencyDisplayMode: j['currencyDisplayMode'] as String? ?? 'code',
        lineItems: (j['lineItems'] as List<dynamic>? ?? [])
            .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        taxRate:      (j['taxRate']      as num?)?.toDouble() ?? 0.0,
        discountRate: (j['discountRate'] as num?)?.toDouble() ?? 0.0,
        taxName:      j['taxName']      as String? ?? '',
        discountName: j['discountName'] as String? ?? '',
        taxEnabled:      j['taxEnabled']      as bool? ?? true,
        discountEnabled: j['discountEnabled'] as bool? ?? true,
        quoteStatus: QuoteStatus.values.firstWhere(
          (s) => s.name == (j['quoteStatus'] as String? ?? ''),
          orElse: () => QuoteStatus.draft,
        ),
        fontFamily:  j['fontFamily'] as String? ?? 'Roboto',
        fontSize:    (j['fontSize'] as num?)?.toDouble() ?? 12.0,
        colorScheme: QuoteColor.values.firstWhere(
          (c) => c.name == (j['colorScheme'] as String? ?? ''),
          orElse: () => QuoteColor.purple,
        ),
        layoutTemplateId: (j['layoutTemplateId'] as num?)?.toInt() ?? 1,
        enabledFields: (j['enabledFields'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as bool? ?? true),
            ) ??
            defaultQuoteEnabledFields(),
        sourceTemplateId: j['sourceTemplateId'] as String?,
        sourceClientId:   j['sourceClientId']   as String?,
        excludeFromReports: j['excludeFromReports'] as bool? ?? false,
        statusHidden:        j['statusHidden']        as bool?   ?? false,
        signatureMode:       j['signatureMode']       as String? ?? 'blank',
        signatureName:       j['signatureName']       as String? ?? '',
        signatureImagePath:  j['signatureImagePath']  as String?,
        signatureFontSize:   (j['signatureFontSize']  as num?)?.toDouble() ?? 22.0,
        signatureFontFamily: j['signatureFontFamily'] as String? ?? '',
        bankName:            j['bankName']            as String? ?? '',
        accountName:         j['accountName']         as String? ?? '',
        accountNumber:       j['accountNumber']       as String? ?? '',
        otherPaymentDetails: j['otherPaymentDetails']  as String? ?? '',
        termsAndConditions:  j['termsAndConditions']   as String? ?? '',
      );

  QuoteData copyWith({
    String?         businessName,
    String?         businessTagline,
    bool?           businessTaglineEnabled,
    bool?           footerTaglinesEnabled,
    double?         footerTaglinesFontSize,
    List<FooterTaglineItem>? footerTaglines,
    String?         businessEmail,
    String?         businessPhone,
    String?         businessAddress,
    AddressInfo?    businessAddressInfo,
    String?         businessLogoPath,
    bool            clearBusinessLogo = false,
    double?         businessLogoOffsetDx,
    double?         businessLogoOffsetDy,
    double?         businessLogoScale,
    String?         businessLogoShape,
    double?         businessLogoDisplaySize,
    bool?           businessLogoShowInitial,
    String?         businessLogoInitialLetter,
    String?         headerBackgroundImagePath,
    bool            clearHeaderBackgroundImage = false,
    bool?           headerBackgroundEnabled,
    double?         headerBackgroundOpacity,
    double?         headerBackgroundOffsetDx,
    double?         headerBackgroundOffsetDy,
    double?         headerBackgroundScale,
    String?         footerBackgroundImagePath,
    bool            clearFooterBackgroundImage = false,
    bool?           footerBackgroundEnabled,
    double?         footerBackgroundOpacity,
    double?         footerBackgroundOffsetDx,
    double?         footerBackgroundOffsetDy,
    double?         footerBackgroundScale,
    String?         bodyBackgroundImagePath,
    bool            clearBodyBackgroundImage = false,
    bool?           bodyBackgroundEnabled,
    double?         bodyBackgroundOpacity,
    double?         bodyBackgroundOffsetDx,
    double?         bodyBackgroundOffsetDy,
    double?         bodyBackgroundScale,
    String?         clientName,
    String?         clientEmail,
    String?         clientPhone,
    String?         clientAddress,
    AddressInfo?    clientAddressInfo,
    String?         quoteNumber,
    String?         issueDate,
    String?         expiryDate,
    String?         notes,
    String?         currency,
    String?         currencySymbol,
    String?         currencyDisplayMode,
    List<LineItem>? lineItems,
    double?         taxRate,
    double?         discountRate,
    String?         taxName,
    String?         discountName,
    bool?           taxEnabled,
    bool?           discountEnabled,
    QuoteStatus?    quoteStatus,
    String?         fontFamily,
    double?         fontSize,
    QuoteColor?     colorScheme,
    int?            layoutTemplateId,
    Map<String, bool>? enabledFields,
    String?         sourceTemplateId,
    bool            clearSourceTemplateId = false,
    String?         sourceClientId,
    bool            clearSourceClientId = false,
    bool?           excludeFromReports,
    bool?           statusHidden,
    String?         signatureMode,
    String?         signatureName,
    String?         signatureImagePath,
    bool            clearSignatureImage = false,
    double?         signatureFontSize,
    String?         signatureFontFamily,
    String?         bankName,
    String?         accountName,
    String?         accountNumber,
    String?         otherPaymentDetails,
    String?         termsAndConditions,
  }) =>
      QuoteData(
        businessName:     businessName     ?? this.businessName,
        businessTagline:  businessTagline  ?? this.businessTagline,
        businessTaglineEnabled: businessTaglineEnabled ?? this.businessTaglineEnabled,
        footerTaglinesEnabled:  footerTaglinesEnabled  ?? this.footerTaglinesEnabled,
        footerTaglinesFontSize: footerTaglinesFontSize ?? this.footerTaglinesFontSize,
        footerTaglines: footerTaglines ?? List<FooterTaglineItem>.from(this.footerTaglines),
        businessEmail:    businessEmail    ?? this.businessEmail,
        businessPhone:    businessPhone    ?? this.businessPhone,
        businessAddress:  businessAddress  ?? this.businessAddress,
        businessAddressInfo: businessAddressInfo ?? this.businessAddressInfo,
        businessLogoPath: clearBusinessLogo ? null : (businessLogoPath ?? this.businessLogoPath),
        businessLogoOffsetDx: businessLogoOffsetDx ?? this.businessLogoOffsetDx,
        businessLogoOffsetDy: businessLogoOffsetDy ?? this.businessLogoOffsetDy,
        businessLogoScale:    businessLogoScale    ?? this.businessLogoScale,
        businessLogoShape:    businessLogoShape    ?? this.businessLogoShape,
        businessLogoDisplaySize: businessLogoDisplaySize ?? this.businessLogoDisplaySize,
        businessLogoShowInitial: businessLogoShowInitial ?? this.businessLogoShowInitial,
        businessLogoInitialLetter: businessLogoInitialLetter ?? this.businessLogoInitialLetter,
        headerBackgroundImagePath: clearHeaderBackgroundImage
            ? null
            : (headerBackgroundImagePath ?? this.headerBackgroundImagePath),
        headerBackgroundEnabled: headerBackgroundEnabled ?? this.headerBackgroundEnabled,
        headerBackgroundOpacity: headerBackgroundOpacity ?? this.headerBackgroundOpacity,
        headerBackgroundOffsetDx: headerBackgroundOffsetDx ?? this.headerBackgroundOffsetDx,
        headerBackgroundOffsetDy: headerBackgroundOffsetDy ?? this.headerBackgroundOffsetDy,
        headerBackgroundScale: headerBackgroundScale ?? this.headerBackgroundScale,
        footerBackgroundImagePath: clearFooterBackgroundImage
            ? null
            : (footerBackgroundImagePath ?? this.footerBackgroundImagePath),
        footerBackgroundEnabled: footerBackgroundEnabled ?? this.footerBackgroundEnabled,
        footerBackgroundOpacity: footerBackgroundOpacity ?? this.footerBackgroundOpacity,
        footerBackgroundOffsetDx: footerBackgroundOffsetDx ?? this.footerBackgroundOffsetDx,
        footerBackgroundOffsetDy: footerBackgroundOffsetDy ?? this.footerBackgroundOffsetDy,
        footerBackgroundScale: footerBackgroundScale ?? this.footerBackgroundScale,
        bodyBackgroundImagePath: clearBodyBackgroundImage
            ? null
            : (bodyBackgroundImagePath ?? this.bodyBackgroundImagePath),
        bodyBackgroundEnabled: bodyBackgroundEnabled ?? this.bodyBackgroundEnabled,
        bodyBackgroundOpacity: bodyBackgroundOpacity ?? this.bodyBackgroundOpacity,
        bodyBackgroundOffsetDx: bodyBackgroundOffsetDx ?? this.bodyBackgroundOffsetDx,
        bodyBackgroundOffsetDy: bodyBackgroundOffsetDy ?? this.bodyBackgroundOffsetDy,
        bodyBackgroundScale: bodyBackgroundScale ?? this.bodyBackgroundScale,
        clientName:       clientName       ?? this.clientName,
        clientEmail:      clientEmail      ?? this.clientEmail,
        clientPhone:      clientPhone      ?? this.clientPhone,
        clientAddress:    clientAddress    ?? this.clientAddress,
        clientAddressInfo: clientAddressInfo ?? this.clientAddressInfo,
        quoteNumber:      quoteNumber      ?? this.quoteNumber,
        issueDate:        issueDate        ?? this.issueDate,
        expiryDate:       expiryDate       ?? this.expiryDate,
        notes:            notes            ?? this.notes,
        currency:         currency         ?? this.currency,
        currencySymbol:      currencySymbol      ?? this.currencySymbol,
        currencyDisplayMode: currencyDisplayMode ?? this.currencyDisplayMode,
        lineItems:        lineItems        ?? List<LineItem>.from(this.lineItems),
        taxRate:          taxRate          ?? this.taxRate,
        discountRate:     discountRate     ?? this.discountRate,
        taxName:          taxName          ?? this.taxName,
        discountName:     discountName     ?? this.discountName,
        taxEnabled:       taxEnabled       ?? this.taxEnabled,
        discountEnabled:  discountEnabled  ?? this.discountEnabled,
        quoteStatus:      quoteStatus      ?? this.quoteStatus,
        fontFamily:       fontFamily       ?? this.fontFamily,
        fontSize:         fontSize         ?? this.fontSize,
        colorScheme:      colorScheme      ?? this.colorScheme,
        layoutTemplateId: layoutTemplateId ?? this.layoutTemplateId,
        enabledFields: Map<String, bool>.from(enabledFields ?? this.enabledFields),
        sourceTemplateId: clearSourceTemplateId ? null : (sourceTemplateId ?? this.sourceTemplateId),
        sourceClientId:   clearSourceClientId   ? null : (sourceClientId   ?? this.sourceClientId),
        excludeFromReports: excludeFromReports ?? this.excludeFromReports,
        statusHidden:        statusHidden        ?? this.statusHidden,
        signatureMode:       signatureMode       ?? this.signatureMode,
        signatureName:       signatureName       ?? this.signatureName,
        signatureImagePath: clearSignatureImage ? null : (signatureImagePath ?? this.signatureImagePath),
        signatureFontSize:   signatureFontSize   ?? this.signatureFontSize,
        signatureFontFamily: signatureFontFamily ?? this.signatureFontFamily,
        bankName:            bankName            ?? this.bankName,
        accountName:         accountName         ?? this.accountName,
        accountNumber:       accountNumber       ?? this.accountNumber,
        otherPaymentDetails: otherPaymentDetails ?? this.otherPaymentDetails,
        termsAndConditions:  termsAndConditions  ?? this.termsAndConditions,
      );

  QuoteData deepCopy() => copyWith(
        lineItems: lineItems.map((i) => i.copyWith()).toList(),
        enabledFields: Map<String, bool>.from(enabledFields),
        clientAddressInfo: clientAddressInfo.copyWith(),
        businessAddressInfo: businessAddressInfo.copyWith(),
        footerTaglines: footerTaglines.map((t) => t.copyWith()).toList(),
      );
}

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

class SavedQuoteDraft {
  String id;
  String name;
  QuoteData data;
  DateTime createdAt;
  DateTime lastEditedAt;

  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;
  String logoShape;
  bool logoShowInitial;
  String logoInitialLetter;

  SavedQuoteDraft({
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
    if (data.quoteNumber.trim().isNotEmpty) return data.quoteNumber.trim();
    return 'Untitled Draft';
  }

  int get itemCount => data.lineItems.length;
  double get total => data.grandTotal;

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

  factory SavedQuoteDraft.fromJson(Map<String, dynamic> j) => SavedQuoteDraft(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        data: QuoteData.fromJson(j['data'] as Map<String, dynamic>? ?? {}),
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

  SavedQuoteDraft copyWith({
    String? name,
    QuoteData? data,
    DateTime? lastEditedAt,
    String? logoPath,
    bool clearLogoPath = false,
    double? logoOffsetDx,
    double? logoOffsetDy,
    double? logoScale,
    String? logoShape,
    bool? logoShowInitial,
    String? logoInitialLetter,
  }) =>
      SavedQuoteDraft(
        id: id,
        name: name ?? this.name,
        data: data ?? this.data.deepCopy(),
        createdAt: createdAt,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
        logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
        logoOffsetDx: logoOffsetDx ?? this.logoOffsetDx,
        logoOffsetDy: logoOffsetDy ?? this.logoOffsetDy,
        logoScale: logoScale ?? this.logoScale,
        logoShape: logoShape ?? this.logoShape,
        logoShowInitial: logoShowInitial ?? this.logoShowInitial,
        logoInitialLetter: logoInitialLetter ?? this.logoInitialLetter,
      );
}

class SavedQuoteLineItem {
  String id;
  String? name;
  LineItem item;
  DateTime createdAt;
  DateTime lastEditedAt;

  SavedQuoteLineItem({
    required this.id,
    this.name,
    required this.item,
    required this.createdAt,
    required this.lastEditedAt,
  });

  String get displayName {
    if ((name ?? '').trim().isNotEmpty) return name!.trim();
    if (item.description.trim().isNotEmpty) return item.description.trim();
    return 'Untitled Item';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'item': item.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'lastEditedAt': lastEditedAt.toIso8601String(),
      };

  factory SavedQuoteLineItem.fromJson(Map<String, dynamic> j) =>
      SavedQuoteLineItem(
        id: j['id'] as String,
        name: j['name'] as String?,
        item: LineItem.fromJson(j['item'] as Map<String, dynamic>? ?? {}),
        createdAt: DateTime.parse(j['createdAt'] as String),
        lastEditedAt: DateTime.parse(j['lastEditedAt'] as String),
      );

  SavedQuoteLineItem copyWith({
    String? name,
    bool clearName = false,
    LineItem? item,
    DateTime? lastEditedAt,
  }) =>
      SavedQuoteLineItem(
        id: id,
        name: clearName ? null : (name ?? this.name),
        item: item ?? this.item.copyWith(),
        createdAt: createdAt,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      );
}

class SavedQuoteLineItemSet {
  String id;
  String name;
  List<LineItem> items;

  SavedQuoteLineItemSet({
    required this.id,
    required this.name,
    required this.items,
  });

  int get itemCount => items.length;
  double get total => items.fold(0.0, (sum, i) => sum + i.lineNetTotal);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((i) => i.toJson()).toList(),
      };

  factory SavedQuoteLineItemSet.fromJson(Map<String, dynamic> j) =>
      SavedQuoteLineItemSet(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  SavedQuoteLineItemSet copyWith({
    String? name,
    List<LineItem>? items,
  }) =>
      SavedQuoteLineItemSet(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items.map((i) => i.copyWith()).toList(),
      );
}
