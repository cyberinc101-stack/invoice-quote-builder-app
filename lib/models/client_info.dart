// lib/models/client_info.dart

import 'invoice_data.dart'; // for InvoiceColor

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// ClientInfo  (aliased as Customer via invoice_models.dart)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//
// UPDATED (this pass): added logoOffsetDx/Dy, logoScale, logoShape so the
// customer logo can be repositioned/zoomed/shaped via SharedLogoPicker
// (lib/widgets/shared_logo_picker.dart), matching BusinessInfo below and
// the receipt/quote business profiles. logoShape is stored as a plain
// String ('circle' | 'square' | 'roundedSquare') so this model file has no
// dependency on the widgets layer â€” UI code converts via
// logoShapeFromString()/.storageName.

class ClientInfo {
  final String id;
  String name;
  String email;
  String phone;
  String address;
  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;
  String logoShape;

  double  defaultTaxRate;
  String  defaultCurrency;

  ClientInfo({
    String? id,
    this.name     = '',
    this.email    = '',
    this.phone    = '',
    this.address  = '',
    this.logoPath,
    this.logoOffsetDx = 0.0,
    this.logoOffsetDy = 0.0,
    this.logoScale    = 1.0,
    this.logoShape    = 'circle',
    this.defaultCurrency = 'USD',
    this.defaultTaxRate    = 0.0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id':           id,
        'name':         name,
        'email':        email,
        'phone':        phone,
        'address':      address,
        'logoPath':     logoPath,
        'logoOffsetDx': logoOffsetDx,
        'logoOffsetDy': logoOffsetDy,
        'logoScale':    logoScale,
        'logoShape':    logoShape,
        'defaultCurrency': defaultCurrency,
        'defaultTaxRate':  defaultTaxRate,
      };

  factory ClientInfo.fromJson(Map<String, dynamic> j) => ClientInfo(
        id:           j['id']       as String?,
        name:         j['name']     as String? ?? '',
        email:        j['email']    as String? ?? '',
        phone:        j['phone']    as String? ?? '',
        address:      j['address']  as String? ?? '',
        logoPath:     j['logoPath'] as String?,
        logoOffsetDx: (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        logoOffsetDy: (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        logoScale:    (j['logoScale'] as num?)?.toDouble() ?? 1.0,
        logoShape:    j['logoShape'] as String? ?? 'circle',
        defaultCurrency: j['defaultCurrency'] as String? ?? 'USD',
        defaultTaxRate:  (j['defaultTaxRate'] as num?)?.toDouble() ?? 0.0,
      );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// BusinessInfo
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
//
// UPDATED (this pass): same addition as ClientInfo above â€” logoOffsetDx/Dy,
// logoScale, logoShape â€” so the business logo in the Template step gets the
// same reposition/zoom/shape editor via SharedLogoPicker.

class BusinessInfo {
  String  name;
  String  email;
  String  phone;
  String  address;
  String  taxId;
  String? gstNumber;
  String? website;
  String? logoPath;
  double  logoOffsetDx;
  double  logoOffsetDy;
  double  logoScale;
  String  logoShape;

  // Sender / contact person fields
  String? senderName;
  String? senderEmail;
  String? senderPhone;
  String? senderPosition;
  String? senderAddress;
  String? senderWebsite;

  BusinessInfo({
    this.name           = '',
    this.email          = '',
    this.phone          = '',
    this.address        = '',
    this.taxId          = '',
    this.gstNumber,
    this.website,
    this.logoPath,
    this.logoOffsetDx   = 0.0,
    this.logoOffsetDy   = 0.0,
    this.logoScale      = 1.0,
    this.logoShape      = 'circle',
    this.senderName,
    this.senderEmail,
    this.senderPhone,
    this.senderPosition,
    this.senderAddress,
    this.senderWebsite,
  });

  Map<String, dynamic> toJson() => {
        'name':           name,
        'email':          email,
        'phone':          phone,
        'address':        address,
        'taxId':          taxId,
        'gstNumber':      gstNumber,
        'website':        website,
        'logoPath':       logoPath,
        'logoOffsetDx':   logoOffsetDx,
        'logoOffsetDy':   logoOffsetDy,
        'logoScale':      logoScale,
        'logoShape':      logoShape,
        'senderName':     senderName,
        'senderEmail':    senderEmail,
        'senderPhone':    senderPhone,
        'senderPosition': senderPosition,
        'senderAddress':  senderAddress,
        'senderWebsite':  senderWebsite,
      };

  factory BusinessInfo.fromJson(Map<String, dynamic> j) => BusinessInfo(
        name:           j['name']           as String? ?? '',
        email:          j['email']          as String? ?? '',
        phone:          j['phone']          as String? ?? '',
        address:        j['address']        as String? ?? '',
        taxId:          j['taxId']          as String? ?? '',
        gstNumber:      j['gstNumber']      as String?,
        website:        j['website']        as String?,
        logoPath:       j['logoPath']       as String?,
        logoOffsetDx:   (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        logoOffsetDy:   (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        logoScale:      (j['logoScale'] as num?)?.toDouble() ?? 1.0,
        logoShape:      j['logoShape'] as String? ?? 'circle',
        senderName:     j['senderName']     as String?,
        senderEmail:    j['senderEmail']    as String?,
        senderPhone:    j['senderPhone']    as String?,
        senderPosition: j['senderPosition'] as String?,
        senderAddress:  j['senderAddress']  as String?,
        senderWebsite:  j['senderWebsite']  as String?,
      );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// InvoiceTemplate
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class InvoiceTemplate {
  final String      id;
  String            name;
  BusinessInfo      businessInfo;
  String            currency;
  Map<String, bool> enabledFields;

  InvoiceTemplate({
    required this.id,
    required this.name,
    required this.businessInfo,
    this.currency      = 'USD',
    Map<String, bool>? enabledFields,
  }) : enabledFields = enabledFields ?? {};

  Map<String, dynamic> toJson() => {
        'id':            id,
        'name':          name,
        'businessInfo':  businessInfo.toJson(),
        'currency':      currency,
        'enabledFields': enabledFields,
      };

  factory InvoiceTemplate.fromJson(Map<String, dynamic> j) => InvoiceTemplate(
        id:   j['id']   as String? ?? '',
        name: j['name'] as String? ?? '',
        businessInfo: BusinessInfo.fromJson(
            j['businessInfo'] as Map<String, dynamic>? ?? {}),
        currency: j['currency'] as String? ?? 'USD',
        enabledFields: (j['enabledFields'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as bool? ?? true)),
      );
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Invoice  (the generated invoice document)
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class Invoice {
  final String      id;
  String            invoiceNumber;
  String?           barcodeNumber;
  DateTime          date;
  DateTime          dueDate;
  BusinessInfo      businessInfo;
  ClientInfo        customer;
  List<dynamic>     items; // List<LineItem> â€” avoid circular import by using dynamic
  double            taxRate;
  double            discountRate;
  String            notes;
  String            thankYouMessage;
  Map<String, bool> enabledFields;
  dynamic           colorScheme;   // InvoiceColor
  String?           businessLogoPath;
  String            currency;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    this.barcodeNumber,
    required this.date,
    required this.dueDate,
    required this.businessInfo,
    required this.customer,
    required this.items,
    this.taxRate          = 0,
    this.discountRate     = 0,
    this.notes            = '',
    this.thankYouMessage  = 'Thank you for your business!',
    required this.enabledFields,
    required this.colorScheme,
    this.businessLogoPath,
    this.currency         = 'USD',
  });

  Map<String, dynamic> toJson() => {
        'id':               id,
        'invoiceNumber':    invoiceNumber,
        'barcodeNumber':    barcodeNumber,
        'date':             date.toIso8601String(),
        'dueDate':          dueDate.toIso8601String(),
        'businessInfo':     businessInfo.toJson(),
        'customer':         customer.toJson(),
        'items':            (items as List).map((i) => i.toJson()).toList(),
        'taxRate':          taxRate,
        'discountRate':     discountRate,
        'notes':            notes,
        'thankYouMessage':  thankYouMessage,
        'enabledFields':    enabledFields,
        'colorScheme':      (colorScheme as InvoiceColor).name,
        'businessLogoPath': businessLogoPath,
        'currency':         currency,
      };
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// CurrencyHelper
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class CurrencyHelper {
  static const _currencies = <Map<String, String>>[
    {'code': 'USD', 'symbol': '\$',   'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': 'â‚¬',   'name': 'Euro'},
    {'code': 'GBP', 'symbol': 'Â£',   'name': 'British Pound'},
    {'code': 'AUD', 'symbol': 'A\$',  'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': 'C\$',  'name': 'Canadian Dollar'},
    {'code': 'CHF', 'symbol': 'Fr',   'name': 'Swiss Franc'},
    {'code': 'JPY', 'symbol': 'Â¥',   'name': 'Japanese Yen'},
    {'code': 'CNY', 'symbol': 'Â¥',   'name': 'Chinese Yuan'},
    {'code': 'NZD', 'symbol': 'NZ\$', 'name': 'New Zealand Dollar'},
    {'code': 'SGD', 'symbol': 'S\$',  'name': 'Singapore Dollar'},
    {'code': 'HKD', 'symbol': 'HK\$', 'name': 'Hong Kong Dollar'},
    {'code': 'MYR', 'symbol': 'RM',   'name': 'Malaysian Ringgit'},
    {'code': 'INR', 'symbol': 'â‚¹',   'name': 'Indian Rupee'},
    {'code': 'IDR', 'symbol': 'Rp',   'name': 'Indonesian Rupiah'},
    {'code': 'THB', 'symbol': 'à¸¿',   'name': 'Thai Baht'},
    {'code': 'BRL', 'symbol': 'R\$',  'name': 'Brazilian Real'},
    {'code': 'MXN', 'symbol': 'MX\$', 'name': 'Mexican Peso'},
    {'code': 'ZAR', 'symbol': 'R',    'name': 'South African Rand'},
    {'code': 'AED', 'symbol': 'Ø¯.Ø¥', 'name': 'UAE Dirham'},
    {'code': 'SAR', 'symbol': 'Ã¯Â·Â¼',   'name': 'Saudi Riyal'},
    {'code': 'SEK', 'symbol': 'kr',   'name': 'Swedish Krona'},
    {'code': 'NOK', 'symbol': 'kr',   'name': 'Norwegian Krone'},
    {'code': 'DKK', 'symbol': 'kr',   'name': 'Danish Krone'},
    {'code': 'PLN', 'symbol': 'zÅ‚',   'name': 'Polish Zloty'},
  ];

  static List<Map<String, String>> getAllCurrencies() => _currencies;

  static String getSymbol(String code) =>
      _currencies.firstWhere(
        (c) => c['code'] == code,
        orElse: () => {'symbol': code},
      )['symbol']!;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Extension kept for any code that calls InvoiceColor.allSchemes
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

extension InvoiceColorSchemeExtension on InvoiceColor {
  static List<InvoiceColor> get allSchemes => InvoiceColor.values;
}
