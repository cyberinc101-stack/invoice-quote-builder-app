// lib/models/client_info.dart
//
// PAYMENT TERMS REMOVAL PASS (this update): BusinessInfo.paymentTerms has
// been removed entirely — field, toJson/fromJson keys, and the
// constructor param are all gone. Matches the corresponding removal in
// invoice_data.dart (InvoiceData.paymentTerms + its enabledFields toggle),
// step_customise.dart (the "Payment Terms" toggle row), the template
// editor's "Payment Terms / Due Note" input field, and the two render
// sites (executive_invoice_payment_terms_signature.dart's
// buildPaymentInfoPanel, invoice_pdf_extra_sections.dart's
// buildPdfPaymentInfoPanel). Persisted templates that still have a
// 'paymentTerms' key in their saved JSON simply have it ignored on load
// now — no migration or crash.
//
// STRUCTURED ADDRESS PASS (earlier): ClientInfo.address and
// BusinessInfo.address/senderAddress were single free-text fields — that
// let a saved record hold a big unstructured blob that renders poorly on
// the invoice. Both now also carry an AddressInfo (see
// lib/models/address_info.dart): addressInfo on ClientInfo/BusinessInfo,
// plus senderAddressInfo on BusinessInfo for the Sender/Contact block.
// The original `address`/`senderAddress` String fields are NOT removed —
// they're kept in sync (set to addressInfo.singleLine) by the sheets that
// edit them (step_customers.dart / step_templates.dart), so anything else
// still reading them as plain strings (customer/template cards, PDF
// export, Quote/Receipt screens that share ClientInfo) is unaffected.
// fromJson() migrates existing data for free: if no 'addressInfo'/
// 'senderAddressInfo' key is present yet (every record saved before this
// pass), it builds the AddressInfo from the legacy string instead —
// AddressInfo.fromJson() puts a legacy string straight into `line1` rather
// than guessing at parsing it apart.
//
// CUSTOMER CURRENCY REMOVAL PASS (earlier): ClientInfo's
// defaultCurrency/currencySymbol/currencyDisplayMode fields have been
// removed entirely. Currency is set once per InvoiceTemplate (see
// InvoiceTemplate.currency below) / per invoice, not per customer — having
// it editable on the customer record too was redundant and confusing.
// toJson/fromJson simply no longer read/write those three keys; any old
// persisted customer JSON that still has them will just have those keys
// ignored on load (no migration needed, no crash).
//
// PAYMENT INFO / TERMS & SIGNATURE PASS (earlier pass): BusinessInfo gains
// the template-authored fields matching InvoiceData's own
// bankName/accountName/accountNumber/otherPaymentDetails/
// termsAndConditions/signatureMode/signatureName/signatureImagePath (see
// invoice_data.dart's PAYMENT INFO / TERMS & CONDITIONS / SIGNATURE PASS
// header for full field rationale). Deliberately does NOT include
// poNumber — that field is per-invoice only (a PO number differs on
// every invoice) and is never authored on a template. Edited via
// step_templates.dart's new Payment Info / Terms & Conditions / Signature
// sections. NOT yet copied onto InvoiceData at template-select time —
// that sync step still needs to be added to
// StepCreateInvoice._syncToProvider(). Defaults ('' / 'blank' / null)
// preserve existing behaviour for every persisted template, no migration
// needed.
//
// LOGO FALLBACK MARK PASS (earlier): BusinessInfo gains
// logoShowInitial (bool, default true) and logoInitialLetter (String,
// default '') — mirrors ReceiptTemplate's and QuoteTemplate's own fields
// of the same name/purpose. Needed so step_templates.dart's
// SharedLogoPicker can wire up the "show letter mark when there's no
// logo" switch + optional letter override, matching what Quote's and
// (after this pass) Receipt's template sheets already do. Defaults
// preserve existing render behaviour for every persisted invoice
// template, no migration needed.

import 'invoice_data.dart'; // for InvoiceColor
import 'address_info.dart';

// ─────────────────────────────────────────────────────────────────────────
// ClientInfo  (aliased as Customer via invoice_models.dart)
// ─────────────────────────────────────────────────────────────────────────
//
// UPDATED (earlier pass): added logoOffsetDx/Dy, logoScale, logoShape so the
// customer logo can be repositioned/zoomed/shaped via SharedLogoPicker
// (lib/widgets/shared_logo_picker.dart), matching BusinessInfo below and
// the receipt/quote business profiles. logoShape is stored as a plain
// String ('circle' | 'square' | 'roundedSquare') so this model file has no
// dependency on the widgets layer — UI code converts via
// logoShapeFromString()/.storageName.

class ClientInfo {
  final String id;
  String name;
  String email;
  String phone;
  String address; // legacy single-line address — kept in sync from
                   // addressInfo.singleLine by the sheet that edits it.
  AddressInfo addressInfo;
  String? logoPath;
  double logoOffsetDx;
  double logoOffsetDy;
  double logoScale;
  String logoShape;

  double defaultTaxRate;

  ClientInfo({
    String? id,
    this.name     = '',
    this.email    = '',
    this.phone    = '',
    this.address  = '',
    AddressInfo? addressInfo,
    this.logoPath,
    this.logoOffsetDx = 0.0,
    this.logoOffsetDy = 0.0,
    this.logoScale    = 1.0,
    this.logoShape    = 'circle',
    this.defaultTaxRate = 0.0,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        addressInfo = addressInfo ?? AddressInfo();

  Map<String, dynamic> toJson() => {
        'id':           id,
        'name':         name,
        'email':        email,
        'phone':        phone,
        'address':      address,
        'addressInfo':  addressInfo.toJson(),
        'logoPath':     logoPath,
        'logoOffsetDx': logoOffsetDx,
        'logoOffsetDy': logoOffsetDy,
        'logoScale':    logoScale,
        'logoShape':    logoShape,
        'defaultTaxRate':  defaultTaxRate,
      };

  factory ClientInfo.fromJson(Map<String, dynamic> j) => ClientInfo(
        id:           j['id']       as String?,
        name:         j['name']     as String? ?? '',
        email:        j['email']    as String? ?? '',
        phone:        j['phone']    as String? ?? '',
        address:      j['address']  as String? ?? '',
        // STRUCTURED ADDRESS PASS: falls back to the legacy `address`
        // string when no `addressInfo` key exists yet (every record
        // saved before this pass) — see AddressInfo.fromJson's own
        // String-input handling.
        addressInfo:  AddressInfo.fromJson(j['addressInfo'] ?? j['address']),
        logoPath:     j['logoPath'] as String?,
        logoOffsetDx: (j['logoOffsetDx'] as num?)?.toDouble() ?? 0.0,
        logoOffsetDy: (j['logoOffsetDy'] as num?)?.toDouble() ?? 0.0,
        logoScale:    (j['logoScale'] as num?)?.toDouble() ?? 1.0,
        logoShape:    j['logoShape'] as String? ?? 'circle',
        defaultTaxRate:  (j['defaultTaxRate'] as num?)?.toDouble() ?? 0.0,
      );
}

// ─────────────────────────────────────────────────────────────────────────
// BusinessInfo
// ─────────────────────────────────────────────────────────────────────────
//
// UPDATED (earlier pass): logoOffsetDx/Dy, logoScale, logoShape — so the
// business logo in the Template step gets the same reposition/zoom/shape
// editor via SharedLogoPicker.
//
// LOGO FALLBACK MARK PASS (earlier pass): logoShowInitial/
// logoInitialLetter — see file header note above.
//
// PAYMENT INFO / TERMS & SIGNATURE PASS (earlier pass): bankName/
// accountName/accountNumber/otherPaymentDetails (Payment Info),
// termsAndConditions (Terms & Conditions), and the
// three-mode signatureMode/signatureName/signatureImagePath (Signature)
// — see file header note above. Edited via step_templates.dart's
// _PaymentInfoSection / _TermsSection / _SignatureSection (in
// step_templates_payment.dart / step_templates_terms.dart /
// step_templates_signature.dart). paymentTerms was removed from this
// group entirely — see PAYMENT TERMS REMOVAL PASS above.

class BusinessInfo {
  String  name;
  String  email;
  String  phone;
  String  address; // legacy single-line business address — kept in sync
                    // from addressInfo.singleLine by step_templates.dart.
  AddressInfo addressInfo;
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
  String? senderAddress; // legacy single-line sender address — kept in
                          // sync from senderAddressInfo.singleLine.
  AddressInfo senderAddressInfo;
  String? senderWebsite;

  // PAYMENT INFO / TERMS & SIGNATURE PASS: bank details. bankName/
  // accountName/accountNumber are the three named fields;
  // otherPaymentDetails is a single freeform field for anything that
  // doesn't fit those three (IBAN, SWIFT/BIC, routing/sort code, PayPal
  // handle, etc) rather than guessing which of those a given business
  // needs. Mirrors InvoiceData's identical fields exactly.
  String bankName;
  String accountName;
  String accountNumber;
  String otherPaymentDetails;

  String termsAndConditions;

  // Signature — three mutually exclusive modes, mirrors
  // InvoiceData.signatureMode/signatureName/signatureImagePath exactly.
  // 'typed' renders signatureName as a script-style caption; 'image'
  // renders signatureImagePath as-is (no crop/shape mask); 'blank'
  // renders neither, just an empty line reserved for a physical
  // wet-ink signature.
  String signatureMode; // 'typed' | 'image' | 'blank'
  String signatureName;
  String? signatureImagePath;

  BusinessInfo({
    this.name           = '',
    this.email          = '',
    this.phone          = '',
    this.address        = '',
    AddressInfo? addressInfo,
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
    AddressInfo? senderAddressInfo,
    this.senderWebsite,
    this.bankName            = '',
    this.accountName         = '',
    this.accountNumber       = '',
    this.otherPaymentDetails = '',
    this.termsAndConditions  = '',
    this.signatureMode       = 'blank',
    this.signatureName       = '',
    this.signatureImagePath,
  })  : addressInfo = addressInfo ?? AddressInfo(),
        senderAddressInfo = senderAddressInfo ?? AddressInfo();

  Map<String, dynamic> toJson() => {
        'name':           name,
        'email':          email,
        'phone':          phone,
        'address':        address,
        'addressInfo':    addressInfo.toJson(),
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
        'senderAddressInfo': senderAddressInfo.toJson(),
        'senderWebsite':  senderWebsite,
        'bankName':            bankName,
        'accountName':         accountName,
        'accountNumber':       accountNumber,
        'otherPaymentDetails': otherPaymentDetails,
        'termsAndConditions':  termsAndConditions,
        'signatureMode':       signatureMode,
        'signatureName':       signatureName,
        'signatureImagePath':  signatureImagePath,
      };

  factory BusinessInfo.fromJson(Map<String, dynamic> j) => BusinessInfo(
        name:           j['name']           as String? ?? '',
        email:          j['email']          as String? ?? '',
        phone:          j['phone']          as String? ?? '',
        address:        j['address']        as String? ?? '',
        // STRUCTURED ADDRESS PASS: falls back to the legacy `address`/
        // `senderAddress` strings when no `addressInfo`/`senderAddressInfo`
        // key exists yet (every record saved before this pass).
        addressInfo:    AddressInfo.fromJson(j['addressInfo'] ?? j['address']),
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
        senderAddressInfo: AddressInfo.fromJson(
            j['senderAddressInfo'] ?? j['senderAddress']),
        senderWebsite:  j['senderWebsite']  as String?,
        bankName:            j['bankName']            as String? ?? '',
        accountName:         j['accountName']         as String? ?? '',
        accountNumber:       j['accountNumber']       as String? ?? '',
        otherPaymentDetails: j['otherPaymentDetails']  as String? ?? '',
        termsAndConditions:  j['termsAndConditions']   as String? ?? '',
        signatureMode:       j['signatureMode']        as String? ?? 'blank',
        signatureName:       j['signatureName']        as String? ?? '',
        signatureImagePath:  j['signatureImagePath']   as String?,
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
// InvoiceData/QuoteData/ReceiptData is always free text, so any
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