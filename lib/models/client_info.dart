// lib/models/client_info.dart
//
// LOGO FALLBACK MARK PASS (this update): BusinessInfo gains
// logoShowInitial (bool, default true) and logoInitialLetter (String,
// default '') — mirrors ReceiptTemplate's and QuoteTemplate's own fields
// of the same name/purpose. Needed so step_templates.dart's
// SharedLogoPicker can wire up the "show letter mark when there's no
// logo" switch + optional letter override, matching what Quote's and
// (after this pass) Receipt's template sheets already do. Defaults
// preserve existing render behaviour for every persisted invoice
// template, no migration needed.

import 'invoice_data.dart'; // for InvoiceColor

// ─────────────────────────────────────────────────────────────────────────
// ClientInfo  (aliased as Customer via invoice_models.dart)
// ─────────────────────────────────────────────────────────────────────────
//
// UPDATED (this pass): added logoOffsetDx/Dy, logoScale, logoShape so the
// customer logo can be repositioned/zoomed/shaped via SharedLogoPicker
// (lib/widgets/shared_logo_picker.dart), matching BusinessInfo below and
// the receipt/quote business profiles. logoShape is stored as a plain
// String ('circle' | 'square' | 'roundedSquare') so this model file has no
// dependency on the widgets layer — UI code converts via
// logoShapeFromString()/.storageName.
//
// CURRENCY DISPLAY PASS (this update): added currencySymbol and
// currencyDisplayMode alongside the existing defaultCurrency (the ISO-ish
// code, e.g. "USD"). This is deliberately NOT a fixed dropdown of
// currencies — defaultCurrency and currencySymbol are both free text, so
// any currency in the world can be entered, not just ones on a hardcoded
// list. currencyDisplayMode controls how the two combine when money is
// rendered: 'code' (USD 200.00), 'symbol' ($200.00), or 'both'
// (USD $200.00). Defaults to 'code' so existing saved customers render
// exactly as they did before this field existed.

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
  String  currencySymbol;
  String  currencyDisplayMode; // 'code' | 'symbol' | 'both'

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
    this.currencySymbol      = '',
    this.currencyDisplayMode = 'code',
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
        'currencySymbol':      currencySymbol,
        'currencyDisplayMode': currencyDisplayMode,
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
        currencySymbol:      j['currencySymbol'] as String? ?? '',
        currencyDisplayMode: j['currencyDisplayMode'] as String? ?? 'code',
        defaultTaxRate:  (j['defaultTaxRate'] as num?)?.toDouble() ?? 0.0,
      );
}

// ─────────────────────────────────────────────────────────────────────────
// BusinessInfo
// ─────────────────────────────────────────────────────────────────────────
//
// UPDATED (this pass): same addition as ClientInfo above — logoOffsetDx/Dy,
// logoScale, logoShape — so the business logo in the Template step gets the
// same reposition/zoom/shape editor via SharedLogoPicker.
//
// LOGO FALLBACK MARK PASS (this update): added logoShowInitial/
// logoInitialLetter — see file header note above.

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
  bool    logoShowInitial;
  String  logoInitialLetter;

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
    this.logoShowInitial   = true,
    this.logoInitialLetter = '',
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
        'logoShowInitial':   logoShowInitial,
        'logoInitialLetter': logoInitialLetter,
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
        logoShowInitial:   j['logoShowInitial'] as bool? ?? true,
        logoInitialLetter: j['logoInitialLetter'] as String? ?? '',
        senderName:     j['senderName']     as String?,
        senderEmail:    j['senderEmail']    as String?,
        senderPhone:    j['senderPhone']    as String?,
        senderPosition: j['senderPosition'] as String?,
        senderAddress:  j['senderAddress']  as String?,
        senderWebsite:  j['senderWebsite']  as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────
// InvoiceTemplate
// ─────────────────────────────────────────────────────────────────────────

class InvoiceTemplate {
  final String      id;
  String            name;
  BusinessInfo      businessInfo;
  String            currency;
  Map<String, bool> enabledFields;

  // THANK YOU MESSAGE PASS: the message text itself now lives on the
  // template (previously only a "Thank You Message" toggle existed on
  // the Customise step's field-visibility list, with no field anywhere
  // to type what it says). Defaults to the same copy InvoiceData already
  // used implicitly. Not yet wired into InvoiceData.thankYouMessage on
  // template selection — UI/model plumbing only for now, application
  // logic to follow in a later pass.
  String thankYouMessage;

  InvoiceTemplate({
    required this.id,
    required this.name,
    required this.businessInfo,
    this.currency      = 'USD',
    Map<String, bool>? enabledFields,
    this.thankYouMessage = 'Thank you for your business!',
  }) : enabledFields = enabledFields ?? {};

  Map<String, dynamic> toJson() => {
        'id':            id,
        'name':          name,
        'businessInfo':  businessInfo.toJson(),
        'currency':      currency,
        'enabledFields': enabledFields,
        'thankYouMessage': thankYouMessage,
      };

  factory InvoiceTemplate.fromJson(Map<String, dynamic> j) => InvoiceTemplate(
        id:   j['id']   as String? ?? '',
        name: j['name'] as String? ?? '',
        businessInfo: BusinessInfo.fromJson(
            j['businessInfo'] as Map<String, dynamic>? ?? {}),
        currency: j['currency'] as String? ?? 'USD',
        enabledFields: (j['enabledFields'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v as bool? ?? true)),
        thankYouMessage: j['thankYouMessage'] as String? ?? 'Thank you for your business!',
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Invoice  (the generated invoice document)
// ─────────────────────────────────────────────────────────────────────────

class Invoice {
  final String      id;
  String            invoiceNumber;
  String?           barcodeNumber;
  DateTime          date;
  DateTime          dueDate;
  BusinessInfo      businessInfo;
  ClientInfo        customer;
  List<dynamic>     items; // List<LineItem> — avoid circular import by using dynamic
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

// ─────────────────────────────────────────────────────────────────────────
// CurrencyHelper
// ─────────────────────────────────────────────────────────────────────────
//
// Kept as a suggestions/quick-pick list only — NOT a hardcoded validation
// list. getSymbol() is used as a convenience default when a user picks a
// well-known code from getAllCurrencies(), but currencySymbol on
// ClientInfo/InvoiceData/QuoteData/ReceiptData is always free text, so any
// currency not in this list still works fully — the user just types the
// symbol themselves instead of getting it auto-filled.

class CurrencyHelper {
  static const _currencies = <Map<String, String>>[
    {'code': 'USD', 'symbol': '\$',   'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€',   'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£',   'name': 'British Pound'},
    {'code': 'AUD', 'symbol': 'A\$',  'name': 'Australian Dollar'},
    {'code': 'CAD', 'symbol': 'C\$',  'name': 'Canadian Dollar'},
    {'code': 'CHF', 'symbol': 'Fr',   'name': 'Swiss Franc'},
    {'code': 'JPY', 'symbol': '¥',   'name': 'Japanese Yen'},
    {'code': 'CNY', 'symbol': '¥',   'name': 'Chinese Yuan'},
    {'code': 'NZD', 'symbol': 'NZ\$', 'name': 'New Zealand Dollar'},
    {'code': 'SGD', 'symbol': 'S\$',  'name': 'Singapore Dollar'},
    {'code': 'HKD', 'symbol': 'HK\$', 'name': 'Hong Kong Dollar'},
    {'code': 'MYR', 'symbol': 'RM',   'name': 'Malaysian Ringgit'},
    {'code': 'INR', 'symbol': '₹',   'name': 'Indian Rupee'},
    {'code': 'IDR', 'symbol': 'Rp',   'name': 'Indonesian Rupiah'},
    {'code': 'THB', 'symbol': '฿',   'name': 'Thai Baht'},
    {'code': 'BRL', 'symbol': 'R\$',  'name': 'Brazilian Real'},
    {'code': 'MXN', 'symbol': 'MX\$', 'name': 'Mexican Peso'},
    {'code': 'ZAR', 'symbol': 'R',    'name': 'South African Rand'},
    {'code': 'AED', 'symbol': 'د.إ', 'name': 'UAE Dirham'},
    {'code': 'SAR', 'symbol': 'ر.س',   'name': 'Saudi Riyal'},
    {'code': 'SEK', 'symbol': 'kr',   'name': 'Swedish Krona'},
    {'code': 'NOK', 'symbol': 'kr',   'name': 'Norwegian Krone'},
    {'code': 'DKK', 'symbol': 'kr',   'name': 'Danish Krone'},
    {'code': 'PLN', 'symbol': 'zł',   'name': 'Polish Zloty'},
  ];

  static List<Map<String, String>> getAllCurrencies() => _currencies;

  /// Best-effort convenience lookup for auto-filling the symbol field when
  /// a user picks a well-known code — returns '' (not the code) when
  /// unknown, so callers can tell "not found" apart from "found, no
  /// symbol" and leave the field blank rather than defaulting to the code.
  static String getSymbol(String code) =>
      _currencies.firstWhere(
        (c) => c['code']?.toUpperCase() == code.toUpperCase(),
        orElse: () => const {'symbol': ''},
      )['symbol']!;
}

// ─────────────────────────────────────────────────────────────────────────
// Extension kept for any code that calls InvoiceColor.allSchemes
// ─────────────────────────────────────────────────────────────────────────

extension InvoiceColorSchemeExtension on InvoiceColor {
  static List<InvoiceColor> get allSchemes => InvoiceColor.values;
}
