import 'address_info.dart';
import 'footer_tagline.dart';

const List<String> kLineItemUnits = [
  '',
  'hour',
  'day',
  'week',
  'month',
  'service',
  'fixed_price',
  'kilometer',
  'expense',
  'percentage',
  'piece',
  'license',
  'session',
  'package',
  'custom',
];

const Map<String, String> _kUnitDisplayLabels = {
  '': 'No unit',
  'hour': 'Hour',
  'day': 'Day',
  'week': 'Week',
  'month': 'Month',
  'service': 'Service',
  'fixed_price': 'Fixed Price',
  'kilometer': 'Kilometer',
  'expense': 'Expense',
  'percentage': 'Percentage',
  'piece': 'Piece / Unit',
  'license': 'License',
  'session': 'Session',
  'package': 'Package / Bundle',
  'custom': 'Custom Unit…',
};

String unitDisplayLabel(String unit, {String customUnitLabel = ''}) {
  if (unit == 'custom') {
    final trimmed = customUnitLabel.trim();
    return trimmed.isEmpty ? 'Custom' : trimmed;
  }
  return _kUnitDisplayLabels[unit] ?? unit;
}

const Map<String, String> _kUnitPriceSuffix = {
  'hour': 'hour',
  'day': 'day',
  'week': 'week',
  'month': 'month',
  'kilometer': 'km',
  'piece': 'unit',
  'license': 'license',
  'session': 'session',
  'package': 'package',
  'service': 'service',
};

String? unitPriceSuffix(String unit, {String customUnitLabel = ''}) {
  if (unit == 'custom') {
    final trimmed = customUnitLabel.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return _kUnitPriceSuffix[unit];
}

class LineItem {
  String description;
  double quantity;
  double unitPrice;

  String unit;
  String customUnitLabel;

  bool taxEnabled;
  double itemTaxRate;
  bool discountEnabled;
  double itemDiscountRate;

  bool itemTaxIsAddition;

  String itemTaxName;

  String itemDiscountName;

  String? sourceSavedId;

  LineItem({
    this.description = '',
    this.quantity    = 1.0,
    this.unitPrice   = 0.0,
    this.unit             = '',
    this.customUnitLabel  = '',
    this.taxEnabled       = false,
    this.itemTaxRate      = 0.0,
    this.itemTaxIsAddition = true,
    this.itemTaxName      = '',
    this.discountEnabled  = false,
    this.itemDiscountRate = 0.0,
    this.itemDiscountName = '',
    this.sourceSavedId,
  });

  double get total => quantity * unitPrice;

  double get lineNetTotal {
    final discountAmt = discountEnabled ? total * itemDiscountRate / 100 : 0.0;
    final signedTaxAmt =
        taxEnabled ? (itemTaxIsAddition ? 1 : -1) * total * itemTaxRate / 100 : 0.0;
    return total - discountAmt + signedTaxAmt;
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'quantity':    quantity,
        'unitPrice':   unitPrice,
        'unit':             unit,
        'customUnitLabel':  customUnitLabel,
        'taxEnabled':       taxEnabled,
        'itemTaxRate':      itemTaxRate,
        'itemTaxIsAddition': itemTaxIsAddition,
        'itemTaxName':      itemTaxName,
        'discountEnabled':  discountEnabled,
        'itemDiscountRate': itemDiscountRate,
        'itemDiscountName': itemDiscountName,
        'sourceSavedId':    sourceSavedId,
      };

  factory LineItem.fromJson(Map<String, dynamic> j) => LineItem(
        description: j['description'] as String? ?? '',
        quantity:    (j['quantity']   as num?)?.toDouble() ?? 1.0,
        unitPrice:   (j['unitPrice']  as num?)?.toDouble() ?? 0.0,
        unit:             j['unit'] as String? ?? '',
        customUnitLabel:  j['customUnitLabel'] as String? ?? '',
        taxEnabled:       j['taxEnabled'] as bool? ?? false,
        itemTaxRate:      (j['itemTaxRate'] as num?)?.toDouble() ?? 0.0,
        itemTaxIsAddition: j['itemTaxIsAddition'] as bool? ?? true,
        itemTaxName:      j['itemTaxName'] as String? ?? '',
        discountEnabled:  j['discountEnabled'] as bool? ?? false,
        itemDiscountRate: (j['itemDiscountRate'] as num?)?.toDouble() ?? 0.0,
        itemDiscountName: j['itemDiscountName'] as String? ?? '',
        sourceSavedId:    j['sourceSavedId'] as String?,
      );

  LineItem copyWith({
    String? description,
    double? quantity,
    double? unitPrice,
    String? unit,
    String? customUnitLabel,
    bool? taxEnabled,
    double? itemTaxRate,
    bool? itemTaxIsAddition,
    String? itemTaxName,
    bool? discountEnabled,
    double? itemDiscountRate,
    String? itemDiscountName,
    String? sourceSavedId,
    bool clearSourceSavedId = false,
  }) =>
      LineItem(
        description: description ?? this.description,
        quantity:    quantity    ?? this.quantity,
        unitPrice:   unitPrice   ?? this.unitPrice,
        unit:             unit            ?? this.unit,
        customUnitLabel:  customUnitLabel ?? this.customUnitLabel,
        taxEnabled:       taxEnabled       ?? this.taxEnabled,
        itemTaxRate:      itemTaxRate      ?? this.itemTaxRate,
        itemTaxIsAddition: itemTaxIsAddition ?? this.itemTaxIsAddition,
        itemTaxName:      itemTaxName      ?? this.itemTaxName,
        discountEnabled:  discountEnabled  ?? this.discountEnabled,
        itemDiscountRate: itemDiscountRate ?? this.itemDiscountRate,
        itemDiscountName: itemDiscountName ?? this.itemDiscountName,
        sourceSavedId: clearSourceSavedId ? null : (sourceSavedId ?? this.sourceSavedId),
      );
}

enum PaymentStatus { unpaid, partial, paid, overdue }

enum InvoiceColor { blue, green, purple, orange, red, teal, black, indigo }

Map<String, bool> defaultInvoiceEnabledFields() => {
      'businessName': true, 'businessEmail': true, 'businessPhone': true,
      'businessAddress': true, 'businessWebsite': true, 'businessTaxId': true,
      'businessGst': true, 'businessLogo': true,
      'senderName': true, 'senderPosition': true, 'senderEmail': true,
      'senderPhone': true, 'senderAddress': true, 'senderWebsite': true,
      'customerName': true, 'customerEmail': true, 'customerPhone': true,
      'customerAddress': true,
      'invoiceNumber': true, 'date': true, 'dueDate': true,
      'barcode': true, 'tax': true, 'discount': true,
      // SHOW-STATUS-TOGGLE PASS: gates the status badge (UNPAID/PAID/
      // etc, now rendered under the invoice number in the header — see
      // doc_header.dart's buildSharedHeaderIdentity) — defaults true
      // so every existing document keeps showing it exactly as before
      // this pass.
      'status': true,
      'notes': true, 'thankYouMessage': true,
      'bankName': true, 'accountName': true, 'accountNumber': true,
      'otherPaymentDetails': true, 'poNumber': true,
      'termsAndConditions': true, 'signature': true,
      'dueDateSummary': true, 'amountDue': true,
    };

class InvoiceData {
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

  // SENDER-AS-FROM-CONTACT PASS: sender contact details, synced down
  // from the selected template's BusinessInfo.senderEmail/senderPhone/
  // senderAddressInfo (see step_create_invoice.dart's
  // _syncSelectedToProvider). doc_template_adapter.dart's
  // invoiceToAdapter() now feeds THESE fields into the FROM block's
  // email/phone/address slots instead of the business* fields above —
  // businessEmail/businessPhone/businessAddressInfo/businessAddress
  // are kept on the model (still written by anything that sets them,
  // still exported in toJson) but are no longer what renders in the
  // FROM block on an actual invoice; the sender fields are. This
  // mirrors the template sheet no longer collecting a separate
  // business address/email/phone — see step_templates.dart's Business
  // Information section, now just Name/Tagline/Tax ID/GST.
  String senderEmail;
  String senderPhone;
  AddressInfo senderAddressInfo;

  // TAX-ID-GST-IN-DETAILS PASS: Tax ID / EIN and GST Number, synced down
  // from the template's BusinessInfo.taxId/gstNumber (see
  // step_create_invoice.dart's _syncSelectedToProvider). Rendered in the
  // DETAILS column of the header meta row, below the Issue/Due dates —
  // see doc_header.dart's buildSharedMetaRow — only when non-empty.
  String businessTaxId;
  String businessGst;

  double businessLogoOffsetDx;
  double businessLogoOffsetDy;
  double businessLogoScale;
  String businessLogoShape;

  double businessLogoDisplaySize;

  bool businessLogoShowInitial;
  String businessLogoInitialLetter;

  // FREEFORM HEADER LOGO PASS: when Business Name and Tagline are both
  // switched off, the logo can be freely dragged/enlarged across the
  // whole header area instead of sitting in the small fixed logo box.
  // offsetDx/offsetDy are normalised -1..1 (matching Alignment's own
  // coordinate space, same convention as the background-image offsets
  // below), scale is a free multiplier applied on top of the image's
  // natural contain-fit size within the header area — not clamped to
  // 1..3 like the background images, since enlarging past that IS the
  // point of this feature. Defaults (0, 0, 1.0) place the logo
  // centered at its natural size, so every existing persisted invoice
  // loads and renders unchanged by this pass alone.
  double headerLogoFreeformOffsetDx;
  double headerLogoFreeformOffsetDy;
  double headerLogoFreeformScale;

  // BACKGROUND-IMAGE PASS: header/footer background image path + on/off
  // toggle for this invoice's document — mirrors the equivalent new
  // fields on QuoteData/ReceiptData. Both null/false by default, so
  // every existing persisted invoice loads and renders exactly as
  // before this pass; opting in is a separate action (an upload +
  // toggle on the Customise step) that isn't wired up by this model
  // change alone. See doc_header.dart's withOptionalBackgroundImage for
  // the render-side treatment (image + translucent scrim, so the
  // document's existing dark text always stays readable).
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

  // MID-PAGE BACKGROUND PASS: same treatment as header/footer above,
  // but for the page's body content area (line items + totals). Both
  // null/false by default, so every existing persisted invoice loads
  // and renders exactly as before this pass.
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

  String invoiceNumber;
  String issueDate;
  String dueDate;
  String notes;
  String currency;

  String currencySymbol;
  String currencyDisplayMode;

  List<LineItem> lineItems;

  double        taxRate;
  double        discountRate;

  String        taxName;
  String        discountName;

  bool taxEnabled;
  bool discountEnabled;

  PaymentStatus paymentStatus;
  String        fontFamily;

  double fontSize;

  InvoiceColor  colorScheme;

  int layoutTemplateId;

  Map<String, bool> enabledFields;

  DateTime? paidDate;

  bool excludeFromReports;

  bool statusHidden;

  String bankName;
  String accountName;
  String accountNumber;
  String otherPaymentDetails;

  String poNumber;

  String termsAndConditions;

  String signatureMode;
  String signatureName;
  String? signatureImagePath;

  double signatureFontSize;

  String signatureFontFamily;

  double? amountDueOverride;

  InvoiceData({
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
    this.senderEmail = '',
    this.senderPhone = '',
    AddressInfo? senderAddressInfo,
    this.businessTaxId = '',
    this.businessGst = '',
    this.businessLogoOffsetDx = 0.0,
    this.businessLogoOffsetDy = 0.0,
    this.businessLogoScale    = 1.0,
    this.businessLogoShape    = 'roundedSquare',
    this.businessLogoDisplaySize = 40.0,
    this.businessLogoShowInitial = true,
    this.businessLogoInitialLetter = '',
    this.headerLogoFreeformOffsetDx = 0.0,
    this.headerLogoFreeformOffsetDy = 0.0,
    this.headerLogoFreeformScale = 1.0,
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
    this.invoiceNumber    = '',
    this.issueDate        = '',
    this.dueDate           = '',
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
    this.paymentStatus    = PaymentStatus.unpaid,
    this.fontFamily       = 'Roboto',
    this.fontSize         = 14.0,
    this.colorScheme      = InvoiceColor.blue,
    this.layoutTemplateId = 1,
    Map<String, bool>? enabledFields,
    this.paidDate,
    this.excludeFromReports = false,
    this.statusHidden       = false,
    this.bankName            = '',
    this.accountName         = '',
    this.accountNumber       = '',
    this.otherPaymentDetails = '',
    this.poNumber            = '',
    this.termsAndConditions  = '',
    this.signatureMode       = 'blank',
    this.signatureName       = '',
    this.signatureImagePath,
    this.signatureFontSize = 22.0,
    this.signatureFontFamily = '',
    this.amountDueOverride,
  }) : lineItems = lineItems ?? [],
       enabledFields = enabledFields ?? defaultInvoiceEnabledFields(),
       businessAddressInfo = businessAddressInfo ?? AddressInfo(),
       senderAddressInfo = senderAddressInfo ?? AddressInfo(),
       clientAddressInfo = clientAddressInfo ?? AddressInfo(),
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

  double get amountDue => amountDueOverride ?? grandTotal;

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
        'senderEmail': senderEmail,
        'senderPhone': senderPhone,
        'senderAddressInfo': senderAddressInfo.toJson(),
        'businessTaxId': businessTaxId,
        'businessGst': businessGst,
        'businessLogoOffsetDx': businessLogoOffsetDx,
        'businessLogoOffsetDy': businessLogoOffsetDy,
        'businessLogoScale':    businessLogoScale,
        'businessLogoShape':    businessLogoShape,
        'businessLogoDisplaySize': businessLogoDisplaySize,
        'businessLogoShowInitial': businessLogoShowInitial,
        'businessLogoInitialLetter': businessLogoInitialLetter,
        'headerLogoFreeformOffsetDx': headerLogoFreeformOffsetDx,
        'headerLogoFreeformOffsetDy': headerLogoFreeformOffsetDy,
        'headerLogoFreeformScale': headerLogoFreeformScale,
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
        'invoiceNumber':    invoiceNumber,
        'issueDate':        issueDate,
        'dueDate':          dueDate,
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
        'paymentStatus':    paymentStatus.name,
        'fontFamily':       fontFamily,
        'fontSize':         fontSize,
        'colorScheme':      colorScheme.name,
        'layoutTemplateId': layoutTemplateId,
        'enabledFields':    enabledFields,
        'paidDate':         paidDate?.toIso8601String(),
        'excludeFromReports': excludeFromReports,
        'statusHidden':     statusHidden,
        'bankName':            bankName,
        'accountName':         accountName,
        'accountNumber':       accountNumber,
        'otherPaymentDetails': otherPaymentDetails,
        'poNumber':            poNumber,
        'termsAndConditions':  termsAndConditions,
        'signatureMode':       signatureMode,
        'signatureName':       signatureName,
        'signatureImagePath':  signatureImagePath,
        'signatureFontSize':   signatureFontSize,
        'signatureFontFamily': signatureFontFamily,
        'amountDueOverride':   amountDueOverride,
      };

  factory InvoiceData.fromJson(Map<String, dynamic> j) => InvoiceData(
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
        senderEmail: j['senderEmail'] as String? ?? '',
        senderPhone: j['senderPhone'] as String? ?? '',
        senderAddressInfo: AddressInfo.fromJson(j['senderAddressInfo']),
        businessTaxId: j['businessTaxId'] as String? ?? '',
        businessGst: j['businessGst'] as String? ?? '',
        businessLogoOffsetDx: (j['businessLogoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        businessLogoOffsetDy: (j['businessLogoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        businessLogoScale:    (j['businessLogoScale']    as num?)?.toDouble() ?? 1.0,
        businessLogoShape:    j['businessLogoShape']      as String? ?? 'roundedSquare',
        businessLogoDisplaySize: (j['businessLogoDisplaySize'] as num?)?.toDouble() ?? 40.0,
        businessLogoShowInitial: j['businessLogoShowInitial'] as bool? ?? true,
        businessLogoInitialLetter: j['businessLogoInitialLetter'] as String? ?? '',
        headerLogoFreeformOffsetDx: (j['headerLogoFreeformOffsetDx'] as num?)?.toDouble() ?? 0.0,
        headerLogoFreeformOffsetDy: (j['headerLogoFreeformOffsetDy'] as num?)?.toDouble() ?? 0.0,
        headerLogoFreeformScale: (j['headerLogoFreeformScale'] as num?)?.toDouble() ?? 1.0,
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
        invoiceNumber:    j['invoiceNumber']    as String? ?? '',
        issueDate:        j['issueDate']        as String? ?? '',
        dueDate:          j['dueDate']          as String? ?? '',
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
        paymentStatus: PaymentStatus.values.firstWhere(
          (s) => s.name == (j['paymentStatus'] as String? ?? ''),
          orElse: () => PaymentStatus.unpaid,
        ),
        fontFamily:  j['fontFamily'] as String? ?? 'Roboto',
        fontSize:    (j['fontSize'] as num?)?.toDouble() ?? 14.0,
        colorScheme: InvoiceColor.values.firstWhere(
          (c) => c.name == (j['colorScheme'] as String? ?? ''),
          orElse: () => InvoiceColor.blue,
        ),
        layoutTemplateId: (j['layoutTemplateId'] as num?)?.toInt() ?? 1,
        enabledFields: (j['enabledFields'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as bool? ?? true),
            ) ??
            defaultInvoiceEnabledFields(),
        paidDate: j['paidDate'] != null
            ? DateTime.tryParse(j['paidDate'] as String)
            : null,
        excludeFromReports: j['excludeFromReports'] as bool? ?? false,
        statusHidden: j['statusHidden'] as bool? ?? false,
        bankName:            j['bankName']            as String? ?? '',
        accountName:         j['accountName']         as String? ?? '',
        accountNumber:       j['accountNumber']       as String? ?? '',
        otherPaymentDetails: j['otherPaymentDetails']  as String? ?? '',
        poNumber:            j['poNumber']             as String? ?? '',
        termsAndConditions:  j['termsAndConditions']   as String? ?? '',
        signatureMode:       j['signatureMode']        as String? ?? 'blank',
        signatureName:       j['signatureName']        as String? ?? '',
        signatureImagePath:  j['signatureImagePath']   as String?,
        signatureFontSize:   (j['signatureFontSize']   as num?)?.toDouble() ?? 22.0,
        signatureFontFamily: j['signatureFontFamily']  as String? ?? '',
        amountDueOverride:   (j['amountDueOverride']   as num?)?.toDouble(),
      );

  InvoiceData copyWith({
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
    String?         senderEmail,
    String?         senderPhone,
    AddressInfo?    senderAddressInfo,
    String?         businessTaxId,
    String?         businessGst,
    double?         businessLogoOffsetDx,
    double?         businessLogoOffsetDy,
    double?         businessLogoScale,
    String?         businessLogoShape,
    double?         businessLogoDisplaySize,
    bool?           businessLogoShowInitial,
    String?         businessLogoInitialLetter,
    double?         headerLogoFreeformOffsetDx,
    double?         headerLogoFreeformOffsetDy,
    double?         headerLogoFreeformScale,
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
    String?         invoiceNumber,
    String?         issueDate,
    String?         dueDate,
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
    PaymentStatus?  paymentStatus,
    String?         fontFamily,
    double?         fontSize,
    InvoiceColor?   colorScheme,
    int?            layoutTemplateId,
    Map<String, bool>? enabledFields,
    DateTime?       paidDate,
    bool            clearPaidDate = false,
    bool?           excludeFromReports,
    bool?           statusHidden,
    String?         bankName,
    String?         accountName,
    String?         accountNumber,
    String?         otherPaymentDetails,
    String?         poNumber,
    String?         termsAndConditions,
    String?         signatureMode,
    String?         signatureName,
    String?         signatureImagePath,
    bool            clearSignatureImage = false,
    double?         signatureFontSize,
    String?         signatureFontFamily,
    double?         amountDueOverride,
    bool            clearAmountDueOverride = false,
  }) =>
      InvoiceData(
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
        senderEmail: senderEmail ?? this.senderEmail,
        senderPhone: senderPhone ?? this.senderPhone,
        senderAddressInfo: senderAddressInfo ?? this.senderAddressInfo,
        businessTaxId: businessTaxId ?? this.businessTaxId,
        businessGst: businessGst ?? this.businessGst,
        businessLogoOffsetDx: businessLogoOffsetDx ?? this.businessLogoOffsetDx,
        businessLogoOffsetDy: businessLogoOffsetDy ?? this.businessLogoOffsetDy,
        businessLogoScale:    businessLogoScale    ?? this.businessLogoScale,
        businessLogoShape:    businessLogoShape    ?? this.businessLogoShape,
        businessLogoDisplaySize: businessLogoDisplaySize ?? this.businessLogoDisplaySize,
        businessLogoShowInitial: businessLogoShowInitial ?? this.businessLogoShowInitial,
        businessLogoInitialLetter: businessLogoInitialLetter ?? this.businessLogoInitialLetter,
        headerLogoFreeformOffsetDx: headerLogoFreeformOffsetDx ?? this.headerLogoFreeformOffsetDx,
        headerLogoFreeformOffsetDy: headerLogoFreeformOffsetDy ?? this.headerLogoFreeformOffsetDy,
        headerLogoFreeformScale: headerLogoFreeformScale ?? this.headerLogoFreeformScale,
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
        invoiceNumber:    invoiceNumber    ?? this.invoiceNumber,
        issueDate:        issueDate        ?? this.issueDate,
        dueDate:          dueDate          ?? this.dueDate,
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
        paymentStatus:    paymentStatus    ?? this.paymentStatus,
        fontFamily:       fontFamily       ?? this.fontFamily,
        fontSize:         fontSize         ?? this.fontSize,
        colorScheme:      colorScheme      ?? this.colorScheme,
        layoutTemplateId: layoutTemplateId ?? this.layoutTemplateId,
        enabledFields: Map<String, bool>.from(enabledFields ?? this.enabledFields),
        paidDate: clearPaidDate ? null : (paidDate ?? this.paidDate),
        excludeFromReports: excludeFromReports ?? this.excludeFromReports,
        statusHidden: statusHidden ?? this.statusHidden,
        bankName:            bankName            ?? this.bankName,
        accountName:         accountName         ?? this.accountName,
        accountNumber:       accountNumber       ?? this.accountNumber,
        otherPaymentDetails: otherPaymentDetails ?? this.otherPaymentDetails,
        poNumber:            poNumber            ?? this.poNumber,
        termsAndConditions:  termsAndConditions  ?? this.termsAndConditions,
        signatureMode:       signatureMode       ?? this.signatureMode,
        signatureName:       signatureName       ?? this.signatureName,
        signatureImagePath: clearSignatureImage ? null : (signatureImagePath ?? this.signatureImagePath),
        signatureFontSize: signatureFontSize ?? this.signatureFontSize,
        signatureFontFamily: signatureFontFamily ?? this.signatureFontFamily,
        amountDueOverride: clearAmountDueOverride ? null : (amountDueOverride ?? this.amountDueOverride),
      );

  InvoiceData deepCopy() => copyWith(
        lineItems: lineItems.map((i) => i.copyWith()).toList(),
        enabledFields: Map<String, bool>.from(enabledFields),
        businessAddressInfo: businessAddressInfo.copyWith(),
        senderAddressInfo: senderAddressInfo.copyWith(),
        clientAddressInfo: clientAddressInfo.copyWith(),
        footerTaglines: footerTaglines.map((t) => t.copyWith()).toList(),
      );
}

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

class SavedLineItemSet {
  String id;
  String name;
  List<LineItem> items;

  SavedLineItemSet({
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

  factory SavedLineItemSet.fromJson(Map<String, dynamic> j) => SavedLineItemSet(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        items: (j['items'] as List<dynamic>? ?? [])
            .map((e) => LineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  SavedLineItemSet copyWith({
    String? name,
    List<LineItem>? items,
  }) =>
      SavedLineItemSet(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items.map((i) => i.copyWith()).toList(),
      );
}

class SavedInvoiceLineItem {
  String id;
  String? name;
  LineItem item;
  DateTime createdAt;
  DateTime lastEditedAt;

  SavedInvoiceLineItem({
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

  factory SavedInvoiceLineItem.fromJson(Map<String, dynamic> j) =>
      SavedInvoiceLineItem(
        id: j['id'] as String,
        name: j['name'] as String?,
        item: LineItem.fromJson(j['item'] as Map<String, dynamic>? ?? {}),
        createdAt: DateTime.parse(j['createdAt'] as String),
        lastEditedAt: DateTime.parse(j['lastEditedAt'] as String),
      );

  SavedInvoiceLineItem copyWith({
    String? name,
    bool clearName = false,
    LineItem? item,
    DateTime? lastEditedAt,
  }) =>
      SavedInvoiceLineItem(
        id: id,
        name: clearName ? null : (name ?? this.name),
        item: item ?? this.item.copyWith(),
        createdAt: createdAt,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      );
}

class SavedInvoiceDraft {
  String id;
  String name;
  InvoiceData data;
  DateTime createdAt;
  DateTime lastEditedAt;

  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;
  String logoShape;
  bool logoShowInitial;
  String logoInitialLetter;

  SavedInvoiceDraft({
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
    if (data.invoiceNumber.trim().isNotEmpty) return data.invoiceNumber.trim();
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

  factory SavedInvoiceDraft.fromJson(Map<String, dynamic> j) => SavedInvoiceDraft(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        data: InvoiceData.fromJson(j['data'] as Map<String, dynamic>? ?? {}),
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

  SavedInvoiceDraft copyWith({
    String? name,
    InvoiceData? data,
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
      SavedInvoiceDraft(
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