// quote_data.dart
// lib/models/quote_data.dart
//
// PAYMENT INFO + TERMS PASS (this update): QuoteData gains
// bankName/accountName/accountNumber/otherPaymentDetails (Payment Info)
// and termsAndConditions — the two blocks Invoice's own
// buildPaymentInfoPanel()/buildTermsPanel()
// (executive_invoice_payment_terms_signature.dart) already know how to
// render, now ported into executive_quote_stationary_layout.dart's own
// buildPaymentInfoPanel()/buildTermsPanel() and wired into
// buildFooterSection() there. Matching 'bankName', 'accountName',
// 'accountNumber', 'otherPaymentDetails', 'termsAndConditions' keys were
// added to defaultQuoteEnabledFields() so each has its own show/hide
// toggle, same as every other field. All new fields default to '' so
// every persisted quote loads exactly as before this pass.
//
// NOT YET WIRED: these fields (like signatureMode/signatureName before
// them) still need a sync step wherever a QuoteTemplate is applied to
// QuoteProvider on template selection — that's the piece copying
// QuoteTemplate.bankName/termsAndConditions/etc onto live QuoteData.
// Until that sync exists, these fields can only be set by directly
// calling QuoteData.copyWith with real values (e.g. eventually via a
// provider method mirroring updateSignatureMode's shape).
//
// Deliberately NOT adding a Sender/Contact block (senderName/
// senderEmail/senderPhone/senderPosition/senderAddress/senderWebsite)
// in this pass — Invoice's own InvoiceData has no equivalent fields
// either (only its InvoiceTemplate/BusinessInfo model does), and there
// is no confirmed render site for sender fields in Invoice's own
// stationary layout to port from. Adding them here without a render
// target would be dead model weight. Revisit once Invoice's own
// sender-field render site (if one exists) is available for parity.
//
// SIGNATURE PASS (earlier): QuoteData gains a three-mode Signature
// block, mirroring InvoiceData's own signature fields exactly:
//   - signatureMode ('typed' | 'image' | 'blank' | '' deselected)
//   - signatureName (typed caption, used when signatureMode == 'typed')
//   - signatureImagePath (used when signatureMode == 'image')
//   - signatureFontSize (double, default 22.0)
//   - signatureFontFamily (String, default '' — one of the six
//     locally-bundled script families in
//     executive_invoice_payment_terms_signature.dart's kSignatureFonts,
//     or '' to render in the default italic body-font look)
// All new fields default to '' / 'blank' / null / 22.0 / '' so every
// persisted quote loads exactly as before this pass. A new 'signature'
// key was added to defaultQuoteEnabledFields() so the Signature row has
// its own show/hide toggle on the Customise step, same as every other
// field. Rendered by executive_quote_stationary_layout.dart's
// buildFooterSection via a new buildSignatureBlock() call (mirrors
// Invoice's identical call into
// executive_invoice_payment_terms_signature.dart) and exported by
// quote_pdf_service.dart's Executive PDF builder.
//
// PER-ITEM TOTALS PARITY FIX (earlier): QuoteData was missing
// itemTaxExtra / itemDiscountExtra / itemTaxExtraByName /
// itemDiscountExtraByName — the four getters InvoiceData uses to fold
// each LineItem's own discountEnabled/taxEnabled rate into the
// document's grand total and into the footer's grouped-by-name "Item
// Tax (GST)" / "Item Discounts (Trade)" rows.
//
// grandTotal now mirrors InvoiceData.grandTotal's formula exactly:
//   subtotal - discountAmount + taxAmount - itemDiscountExtra + itemTaxExtra
//
// CREATE-QUOTE PARITY PASS (earlier): brought QuoteData up to the
// same per-invoice field set InvoiceData already has, for exactly the
// fields that are generic (not invoice-specific).
//
// FONT SIZE PASS, TEMPLATE/CLIENT RESTORE-ON-EDIT PASS, TEMPLATE FIELD
// VISIBILITY PASS, LOGO FALLBACK MARK PASS, TEMPLATE + LOGO SIZER PASS,
// CURRENCY DISPLAY PASS (all earlier) — see prior header comments for
// each of these; unaffected by this update.

import 'invoice_data.dart' show LineItem;
import 'address_info.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum QuoteStatus { draft, sent, accepted, declined, expired }

enum QuoteColor { blue, green, purple, orange, red, teal, black, indigo }

// ─────────────────────────────────────────────────────────────────────────────
// Default field-visibility map
// ─────────────────────────────────────────────────────────────────────────────
//
// PAYMENT INFO + TERMS PASS: added 'bankName', 'accountName',
// 'accountNumber', 'otherPaymentDetails', 'termsAndConditions' — one
// toggle key per new field/block, same as every existing field. All
// default true so existing behaviour (nothing new to show since the
// fields are all still empty strings) is unaffected until they're
// actually filled in.
//
// SIGNATURE PASS: added 'signature' — gates the Signature block, same
// key name InvoiceData/DocTemplateAdapter already use.
Map<String, bool> defaultQuoteEnabledFields() => {
      'invoiceNumber': true, 'date': true, 'dueDate': true,
      'tax': true, 'discount': true,
      'notes': true, 'thankYouMessage': true,
      'customerName': true, 'customerEmail': true, 'customerPhone': true,
      'customerAddress': true,
      'businessLogo': true,
      'signature': true,
      'bankName': true, 'accountName': true, 'accountNumber': true,
      'otherPaymentDetails': true,
      'termsAndConditions': true,
    };

// ─────────────────────────────────────────────────────────────────────────────
// QuoteData
// ─────────────────────────────────────────────────────────────────────────────

class QuoteData {
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

  // SIGNATURE PASS: three mutually exclusive modes, mirrors
  // InvoiceData's identical fields exactly. 'typed' renders
  // signatureName in signatureFontFamily (or the default italic look
  // when signatureFontFamily is ''); 'image' renders signatureImagePath
  // as-is; 'blank' renders neither, just an empty signing line; ''
  // (deselected) renders nothing at all.
  String signatureMode; // 'typed' | 'image' | 'blank' | ''
  String signatureName;
  String? signatureImagePath;
  double signatureFontSize;
  String signatureFontFamily;

  // PAYMENT INFO PASS: bank details — bankName/accountName/
  // accountNumber are the three named fields; otherPaymentDetails is a
  // single freeform field for anything that doesn't fit those three
  // (IBAN, SWIFT/BIC, routing/sort code, PayPal handle, etc), exactly
  // mirroring InvoiceData's identical four fields.
  String bankName;
  String accountName;
  String accountNumber;
  String otherPaymentDetails;

  // TERMS PASS: freeform Terms & Conditions text, mirrors
  // InvoiceData.termsAndConditions exactly.
  String termsAndConditions;

  QuoteData({
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
       clientAddressInfo = clientAddressInfo ?? AddressInfo();

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

// ─────────────────────────────────────────────────────────────────────────────
// SavedQuoteDraft
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// SavedQuoteLineItem
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// SavedQuoteLineItemSet
// ─────────────────────────────────────────────────────────────────────────────

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
