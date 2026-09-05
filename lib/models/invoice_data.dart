// invoice_data.dart
// lib/models/invoice_data.dart
//
// LINE NET TOTAL FIX (this update): LineItem was missing lineNetTotal —
// create_invoice_item_widgets.dart (New Item draft card, Committed Item
// row) reads this getter to show a row's Total after ITS OWN tax/
// discount are applied, but the getter was never actually present on
// this file on disk (only in an earlier draft pass), which is why
// `flutter run` failed with "The getter 'lineNetTotal' isn't defined
// for the type 'LineItem'". Added below, plus SavedLineItemSet.total
// updated to sum lineNetTotal instead of the plain base total, for the
// same reason a bundle preview's total should reflect real per-item
// tax/discount too.
//
// TAX/DISCOUNT NAMING COPYWITH FIX (earlier): InvoiceData.copyWith()
// was missing taxName/discountName from its parameter list and
// constructor call — the fields existed (declared, defaulted, in
// toJson/fromJson) but copyWith silently dropped any value passed in,
// resetting both back to '' on every single copy. This is why
// InvoiceProvider.updateInvoiceDetails()'s taxName/discountName params
// had no effect. Fixed by adding both to copyWith's signature and
// passing them through with the standard `?? this.x` pattern, same as
// every other field.
//
// SIGNATURE SIZER PASS (earlier): InvoiceData gained
// signatureFontSize (double, default 22.0) — the typed-name signature's
// font size, adjustable via a slider on the Customise step's Signature
// toggle row (step_customise.dart). Read by
// executive_invoice_payment_terms_signature.dart's buildSignatureBlock
// in place of the previously-hardcoded 22. Default matches the old
// hardcoded size exactly, so existing invoices render identically until
// the slider is actually moved.
//
// AMOUNT DUE PASS (earlier): InvoiceData gained amountDueOverride
// (nullable double) — a manual override for the "Amount Due" figure
// shown next to Due Date under Grand Total on the document. Null means
// "auto": amountDue (the new getter) always tracks grandTotal live as
// line items/tax/discount change. Once the person manually edits the
// Amount Due field on the Create Invoice step
// (create_invoice_bottom_sheet.dart's new "Due Date & Amount Due"
// section), this holds that fixed value instead and stops tracking
// grandTotal. Two new enabledFields keys — dueDateSummary and amountDue
// — gate the new bar that renders this pair directly under Grand Total
// (executive_invoice_stationary_layout.dart's buildFooterSection).
// dueDateSummary is deliberately a DIFFERENT key from the pre-existing
// 'dueDate' toggle — 'dueDate' already controls the Due Date shown in
// the Billed-To meta row near the top of the document, a different
// rendering location from this new bar under the totals. Both new keys
// default true, same as every other field, so existing invoices render
// the new bar automatically once amountDue/dueDate actually have values
// — no migration needed since amountDue always resolves to something
// (grandTotal) even for invoices saved before this pass existed.
//
// PAYMENT INFO / TERMS & CONDITIONS / SIGNATURE PASS (earlier):
// InvoiceData gained bankName/accountName/accountNumber/
// otherPaymentDetails (Payment Info), paymentTerms (a due/terms note,
// template-authored the same way thankYouMessage is), poNumber (a
// PO/Reference Number — deliberately per-invoice, NOT copied from a
// template, since a PO number is different on every invoice),
// termsAndConditions, and a three-mode Signature block: signatureMode
// ('typed' | 'image' | 'blank'), signatureName (typed caption, used
// when signatureMode == 'typed'), signatureImagePath (used when
// signatureMode == 'image'; 'blank' renders neither — just an empty
// line for a physical wet-ink signature). All eight new fields default
// to '' / 'blank' / null so every persisted invoice loads exactly as
// before this pass. Matching keys (bankName, accountName, accountNumber,
// otherPaymentDetails, paymentTerms, poNumber, termsAndConditions,
// signature) were added to defaultInvoiceEnabledFields() so each has its
// own show/hide toggle on the Customise step, same as every other field
// — see step_customise.dart's _FieldsSection "Payment Info" and "Terms &
// Signature" groups. NOTE: bankName/accountName/accountNumber/
// otherPaymentDetails/paymentTerms/termsAndConditions/signature* are
// intended to eventually be authored once on BusinessInfo (in
// client_info.dart) and copied onto InvoiceData at template-select time,
// the same way businessName/businessLogoPath etc. already work — that
// BusinessInfo-side change and the sync step in
// StepCreateInvoice._syncToProvider() are NOT done yet (need
// client_info.dart / step_create_invoice.dart first). For now these
// fields are plain per-invoice InvoiceData fields with no template
// authoring UI wired up.
//
// CONTAINER LOGO + MANDATORY NAME PASS (earlier): SavedInvoiceDraft
// gained its own logoPath/logoOffsetDx/Dy/logoScale/logoShape/
// logoShowInitial/logoInitialLetter fields — a small identifying image
// for the SAVED DRAFT CONTAINER itself (shown on step_create_invoice.
// dart's _InvoiceDraftCard), separate from the invoice's own business
// logo. Mirrors BusinessInfo's identical field set exactly, edited via
// the same SharedLogoPicker UI used on the Template sheet — see
// create_invoice_bottom_sheet.dart's "Container Logo" section. The
// draft's `name` field (previously optional, labelled "Draft Label") is
// now mandatory on that same sheet — see that file's own pass note.
//
// PER-ITEM TAX/DISCOUNT + SAVED SINGLE LINE ITEMS PASS (earlier):
// LineItem gained four new fields — taxEnabled/itemTaxRate,
// discountEnabled/itemDiscountRate — so a single line item can carry its
// own tax/discount rate independent of InvoiceData's existing whole-
// invoice taxRate/discountRate (which is UNCHANGED and still applies to
// the full subtotal exactly as before). Both can be active at once
// (they stack — see create_invoice_bottom_sheet.dart's totals formula
// and its one-time "both are active" toast). Also added sourceSavedId
// (nullable String) — when a line item currently on an invoice was
// added by tapping a saved single-item container (see the new
// SavedInvoiceLineItem below / create_invoice_saved_line_items_widgets.
// dart), this holds that container's id, so the saved-items panel can
// show its radio button as "currently included" for THIS invoice. Items
// typed by hand, or added via the pre-existing SavedLineItemSet bundle
// quick-add, leave this null. All four new fields default to
// false/0.0/false/0.0/null, so every persisted LineItem/invoice loads
// and totals exactly as before this pass.
//
// New model: SavedInvoiceLineItem — a single saved line item (as
// opposed to SavedLineItemSet below, which is a bundle of several).
// Mirrors SavedLineItemSet/Customer/InvoiceTemplate's shape (id/name +
// toJson/fromJson/copyWith), persisted the same way via its own single
// JSON-encoded SharedPreferences list — see
// create_invoice_saved_line_items_widgets.dart for the UI this backs.
//
// INVOICE DRAFT LIBRARY PASS (earlier): added SavedInvoiceDraft — a
// named, editable invoice-in-progress, saved from the Create Invoice
// step's new library screen (step_create_invoice.dart) and reopened via
// CreateInvoiceBottomSheet (create_invoice_bottom_sheet.dart) to keep
// editing it. Mirrors Customer/InvoiceTemplate/SavedLineItemSet's shape
// (id/name + toJson/fromJson/copyWith) so it persists the same way, via
// a single JSON-encoded SharedPreferences list. Unlike SavedInvoice (the
// finished, fully-rendered invoice with completionPercent/folderName/etc),
// SavedInvoiceDraft only carries what's actually editable on the Create
// Invoice step — it stores a full InvoiceData snapshot for convenience
// (so nothing about the shape of an in-progress invoice needs to be
// duplicated here), but business info/logo and layoutTemplateId are
// deliberately re-resolved from the selected template + provider state
// at "Continue to Customise" time (see StepCreateInvoice.
// _syncSelectedToProvider), not read back out of the draft.
//
// LINE ITEM CONTAINERS PASS (earlier): added SavedLineItemSet — a
// named, reusable bundle of line items, saved from the Create Invoice
// step's Line Items section and quick-added back onto any future
// invoice with a tap. Mirrors Customer/InvoiceTemplate's shape (id/name
// + toJson/fromJson/copyWith) so it persists the same way, via a single
// JSON-encoded SharedPreferences list — see
// create_invoice_saved_items_widgets.dart (CreateInvoiceSavedItemSets)
// for the UI this backs.
//
// TEMPLATE FIELD VISIBILITY PASS (earlier): added enabledFields — a
// Map<String, bool> keyed by the same field-id strings used in
// step_templates.dart's toggle rows (see defaultInvoiceEnabledFields()
// below, which mirrors that file's _defaultFields() exactly). Previously
// InvoiceTemplate.enabledFields was saved on the template but never
// copied anywhere InvoiceData could read it, so the Invoice Fields /
// Customer Fields toggles in the template sheet had no effect on the
// actual rendered invoice or exported PDF. Populated from
// InvoiceTemplate.enabledFields in StepCreateInvoice._syncToProvider(),
// and read by executive_invoice_stationary_layout.dart (preview/edit
// canvas) and invoice_pdf_service.dart (exported PDF) to decide what
// actually renders. Missing keys default to true via `?? true` at each
// read site, so persisted invoices saved before this field existed still
// render exactly as before.
//
// LOGO FALLBACK MARK PASS (earlier): added businessLogoShowInitial
// (bool, default true) and businessLogoInitialLetter (String, default
// '') alongside the existing logo fields. When no real logo image is
// set, every template renders a small rotated-square initial-letter mark
// (the "blue diamond") instead of leaving blank space — these two fields
// let the user turn that mark off entirely (businessLogoShowInitial =
// false), or override which letter it shows instead of always
// auto-deriving the first letter of businessName
// (businessLogoInitialLetter). Both are read by buildSharedLogo() in
// shared_doc_widgets.dart via DocTemplateAdapter. Defaults preserve
// existing behaviour exactly (mark shown, auto letter) for every
// persisted invoice, no migration needed.
//
// STATUS HIDDEN PASS (earlier): statusHidden — a plain bool, default
// false — lets the status chip be hidden on the card faces without
// touching paymentStatus itself. Backs the new "None" radio option in the
// status menu (document_status_menu.dart / InvoiceProvider.
// updateSavedInvoiceStatusHidden): picking "None" sets this true and
// leaves paymentStatus exactly as it was; picking any real status sets it
// back to false. Kept separate from paymentStatus rather than adding a
// 5th enum value, since paymentStatus still needs to hold a real, valid
// status for aging/reports/overdue logic even while the chip is hidden.
//
// TEMPLATE + LOGO SIZER PASS: layoutTemplateId (which visual design —
// Executive/Nordic/Vibrant/etc, see preview_registry.dart — this invoice
// renders with) and businessLogoOffsetDx/Dy/Scale/Shape (driven by
// SharedLogoPicker) plus businessLogoDisplaySize (rendered logo box size
// in px, driven by the Logo Size slider on the Customise step). All new
// fields fall back to sensible defaults when missing from persisted JSON
// (layoutTemplateId 1 = Executive, zero offset, scale 1.0, 'roundedSquare'
// shape, size 40.0), so existing persisted invoices load correctly with
// no migration step.
//
// CURRENCY DISPLAY PASS (this update): added currencySymbol and
// currencyDisplayMode alongside currency (the code, e.g. "USD"). Both are
// free text / free choice — no hardcoded currency list gates what can be
// entered here, since a fixed dropdown would cap which currencies the app
// can invoice in. currencyDisplayMode is 'code' | 'symbol' | 'both' and
// controls how shared_doc_widgets.dart's fmtMoney() renders amounts.
// Defaults ('' symbol, 'code' mode) mean existing persisted invoices
// render exactly as before this field existed.

// ─────────────────────────────────────────────────────────────────────────────
// LineItem
// ─────────────────────────────────────────────────────────────────────────────
//
// LINE NET TOTAL PASS: LineItem gained lineNetTotal — a row's own Total
// after ITS OWN tax/discount are applied (total minus this item's
// discount, plus this item's signed tax). `total` itself is UNCHANGED
// (still the plain qty × unitPrice base every other total depends on)
// — this is a second, display-oriented getter. Every UI site that
// renders a line item's Total (the New Item draft card, the Committed
// Item row, the Saved Item card, and the rendered document's TOTAL
// column) now reads this instead of `total`, so a row with its own
// tax/discount actually shows a total that reflects it instead of the
// pre-tax/discount base figure. SavedLineItemSet.total (the bundle
// preview total) now sums lineNetTotal too, for the same reason.
//
// TAX NAME PASS (earlier): LineItem gained itemTaxName/
// itemDiscountName (both default '') — a user-typed label like "GST" or
// "VAT" for tax, "Trade Discount" for discount. The TAX/DISCOUNT column
// headers on the document stay generic (a single column can't show
// multiple different names), but each row's own name shows inline next
// to that row's percentage. InvoiceData gained itemTaxExtraByName/
// itemDiscountExtraByName — the totals section's per-name breakdown,
// grouping every item by its name so differently-named items get
// separate "Item Tax (GST)"/"Item Tax (VAT)" rows instead of one
// combined figure, while a single shared name (or no name at all)
// still collapses to one row exactly as before this pass.
//
// TAX SIGN PASS (earlier): LineItem gained itemTaxIsAddition
// (default true) — whether this item's per-item tax adds to the total
// (ordinary sales tax) or subtracts from it (a withholding tax, common
// for contractors: the client deducts it before paying, reducing what's
// owed). InvoiceData.itemTaxExtra is now a signed net figure instead of
// always-positive — see that getter's own comment for exactly how this
// composes with grandTotal (no formula change needed there) and which
// render sites needed updating to handle a possibly-negative value.
//
// UNIT OF MEASURE PASS (earlier): added kLineItemUnits (the full picklist), plus
// unitDisplayLabel()/unitPriceSuffix() — shared vocabulary used by both
// the item-entry UI (create_invoice_item_widgets.dart's Unit dropdown,
// create_invoice_saved_line_items_widgets.dart's edit sheet) and the
// document render side (executive_invoice_stationary_layout.dart's new
// UNIT column). '' means "no unit set" — every existing persisted
// LineItem defaults to it, so old invoices render exactly as before
// (no UNIT column at all — see that file's showUnitCol gate). 'custom'
// is the one key whose display text comes from the item's own
// customUnitLabel instead of this fixed map, for a unit that doesn't
// fit any preset (e.g. "sqm", "page", "seat").

/// The full Unit-of-measure picklist, in the order shown in the
/// dropdown. '' (empty) is deliberately first — "no unit" is a valid,
/// common choice for a simple flat-price line item.
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

/// Display text for a unit key — for 'custom', prefers the item's own
/// customUnitLabel (falling back to 'Custom' if that's somehow still
/// blank); every other key reads from the fixed map above. Used both by
/// the dropdown's selected-value display and by the rendered UNIT
/// column on the document.
String unitDisplayLabel(String unit, {String customUnitLabel = ''}) {
  if (unit == 'custom') {
    final trimmed = customUnitLabel.trim();
    return trimmed.isEmpty ? 'Custom' : trimmed;
  }
  return _kUnitDisplayLabels[unit] ?? unit;
}

// Lowercase "per X" suffix for the Price field's label — only for units
// where "Price per <unit>" actually reads naturally. Deliberately
// excludes '', 'fixed_price' (already a whole-item price), 'expense'
// (reimbursement, not a per-unit rate), and 'percentage' (the price
// field there is an amount, not a per-unit rate) — 'custom' is handled
// by the caller using the item's own customUnitLabel text directly
// rather than this map.
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

/// The "per X" suffix to show next to the Price field's label (e.g.
/// "Price (per hour)"), or null when this unit doesn't have one — see
/// _kUnitPriceSuffix's doc comment for exactly which units qualify.
/// For 'custom', returns the item's own customUnitLabel (trimmed) when
/// non-empty, so a person who typed e.g. "sqm" sees "Price (per sqm)"
/// too, not just the preset units.
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

  // UNIT OF MEASURE PASS: which of kLineItemUnits this item is priced
  // in — '' (the default) means no unit was set, matching every
  // persisted LineItem from before this pass existed. customUnitLabel
  // is only meaningful when unit == 'custom' — the free-text label the
  // person typed (e.g. "sqm", "page", "seat").
  String unit;
  String customUnitLabel;

  // PER-ITEM TAX/DISCOUNT PASS: this item's own rate, independent of
  // InvoiceData's whole-invoice taxRate/discountRate. Only applied when
  // its matching *Enabled flag is true. See
  // create_invoice_bottom_sheet.dart's totals getters for exactly how
  // this combines with the global rate (they stack, not override).
  bool taxEnabled;
  double itemTaxRate;
  bool discountEnabled;
  double itemDiscountRate;

  // TAX SIGN PASS: whether this item's tax adds to the total (true —
  // ordinary sales tax, the default) or subtracts from it (false — a
  // withholding tax: the client deducts it before paying you, so it
  // reduces what's owed rather than adding on top). Defaults to true so
  // every existing item with taxEnabled already set keeps behaving
  // exactly as before this field existed. Purely a display/sign concern
  // for itemTaxRate — the rate and enabled flag themselves are
  // unchanged.
  bool itemTaxIsAddition;

  // TAX NAME PASS: user-typed label for this item's tax (e.g. "GST",
  // "VAT", "Sales Tax") — '' (default) means unnamed, matching every
  // existing item. The rendered TAX column header always stays the
  // generic word "TAX" regardless of what individual items are named
  // (a single column can't show multiple different headers); each row's
  // own name shows inline next to that row's percentage instead — see
  // executive_invoice_stationary_layout.dart's rateCell(). The totals
  // section groups by this name: items sharing a name (or all left
  // blank) collapse into one "Item Tax" row, differently-named items
  // each get their own row — see InvoiceData.itemTaxExtraByName below.
  String itemTaxName;

  // TAX NAME PASS: same treatment for Discount — a user-typed label
  // (e.g. "Trade Discount", "Early Payment") shown next to that row's
  // discount percentage and used to group the totals section's
  // "Item Discounts" row(s) the same way itemTaxName groups Item Tax.
  String itemDiscountName;

  // PER-ITEM TAX/DISCOUNT PASS: set when this item currently on an
  // invoice originated from tapping a SavedInvoiceLineItem container
  // (below) — lets the Saved-items panel show that container's radio as
  // "included in this invoice". Null for hand-typed items and for items
  // added via the (separate) SavedLineItemSet bundle quick-add.
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

  // LINE NET TOTAL PASS: the actual amount THIS row contributes once its
  // own tax/discount are applied — total minus this item's own discount
  // plus this item's own signed tax (negative when itemTaxIsAddition is
  // false, i.e. a withholding tax). Deliberately a SEPARATE getter from
  // `total`, which stays the plain qty × unitPrice base figure every
  // other calculation (subtotal, itemDiscountExtra, itemTaxExtra, and
  // this getter itself) already depends on — redefining `total` itself
  // would silently change all of those. Only this item's OWN
  // taxEnabled/discountEnabled apply here; InvoiceData's whole-invoice
  // taxRate/discountRate are a separate, invoice-level calculation
  // against the full subtotal (see InvoiceData.taxAmount/
  // discountAmount) and have no single-row equivalent, so they're
  // intentionally not folded in here. Anywhere a line item's own Total
  // column should reflect its own rate (New Item card, Committed Item
  // row, Saved Item card, the rendered document's TOTAL column) should
  // read this instead of `total`.
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

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum PaymentStatus { unpaid, partial, paid, overdue }

enum InvoiceColor { blue, green, purple, orange, red, teal, black, indigo }

// ─────────────────────────────────────────────────────────────────────────────
// Default field-visibility map
// ─────────────────────────────────────────────────────────────────────────────
//
// TEMPLATE FIELD VISIBILITY PASS: mirrors step_templates.dart's
// _defaultFields() exactly (same key set, same defaults). Used whenever
// InvoiceData is constructed without an explicit enabledFields map — new
// invoices with no template selected, or persisted invoices saved before
// this field existed. Kept as a plain top-level function (not a const)
// so each caller gets its own fresh, independently-mutable Map instance.
//
// PAYMENT INFO / TERMS & CONDITIONS / SIGNATURE PASS: added bankName,
// accountName, accountNumber, otherPaymentDetails, paymentTerms,
// poNumber, termsAndConditions, signature — one toggle key per new
// field/block, same as every existing field. All default true so
// existing behaviour (nothing new to show since the fields are all still
// empty strings) is unaffected until the person actually fills them in.
//
// AMOUNT DUE PASS: added dueDateSummary and amountDue — gate the new
// Due Date/Amount Due bar rendered directly under Grand Total. Distinct
// from the pre-existing 'dueDate' key (which gates the Billed-To meta
// row's Due Date, a different spot on the document). Both default true.
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
      'notes': true, 'thankYouMessage': true,
      'bankName': true, 'accountName': true, 'accountNumber': true,
      'otherPaymentDetails': true, 'paymentTerms': true, 'poNumber': true,
      'termsAndConditions': true, 'signature': true,
      'dueDateSummary': true, 'amountDue': true,
    };

// ─────────────────────────────────────────────────────────────────────────────
// InvoiceData
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceData {
  String businessName;
  String businessEmail;
  String businessPhone;
  String businessAddress;
  String? businessLogoPath;

  // Logo reposition/zoom/shape — driven by SharedLogoPicker. Only
  // meaningful when businessLogoPath is set.
  double businessLogoOffsetDx;
  double businessLogoOffsetDy;
  double businessLogoScale;
  String businessLogoShape; // storage name from LogoShape.storageName

  // Rendered logo box size (width/height, px) — driven by the "Logo Size"
  // slider on the Customise step, independent of businessLogoScale (which
  // is the zoom/crop level *within* the box).
  double businessLogoDisplaySize;

  // No-logo fallback mark — see LOGO FALLBACK MARK PASS above. Only
  // meaningful when businessLogoPath is NOT set (once a real logo exists,
  // these two fields are simply ignored).
  bool businessLogoShowInitial;
  String businessLogoInitialLetter;

  String clientName;
  String clientEmail;
  String clientPhone;
  String clientAddress;

  String invoiceNumber;
  String issueDate;
  String dueDate;
  String notes;
  String currency;

  // Free-text currency symbol (e.g. "$", "€", "kr") and how it combines
  // with `currency` (the code) when rendered — see fmtMoney() in
  // shared_doc_widgets.dart. Not gated by any hardcoded currency list.
  String currencySymbol;
  String currencyDisplayMode; // 'code' | 'symbol' | 'both'

  List<LineItem> lineItems;

  double        taxRate;
  double        discountRate;

  // TAX/DISCOUNT NAMING PASS: whole-invoice custom label (e.g. "GST",
  // "VAT") for the document's own Tax %/Discount % — separate from
  // LineItem.itemTaxName/itemDiscountName, which name an individual
  // item's own rate. '' (default) means unnamed, rendering as the plain
  // "Tax (X%)"/"Discount (X%)" every existing invoice already shows.
  String        taxName;
  String        discountName;

  PaymentStatus paymentStatus;
  String        fontFamily;
  InvoiceColor  colorScheme;

  // Which visual design (see preview_registry.dart's kInvoiceTemplates /
  // buildInvoicePreview) this invoice renders with — 1 = Executive, 2 =
  // Nordic, etc. Set from InvoiceTemplateChooserScreen's selection and
  // carried through the wizard by StepCreateInvoice._syncToProvider().
  int layoutTemplateId;

  // TEMPLATE FIELD VISIBILITY PASS: which template-defined fields should
  // actually render on this invoice — keyed by the same field-id strings
  // used in step_templates.dart's toggle rows (invoiceNumber, date,
  // dueDate, barcode, tax, discount, notes, thankYouMessage,
  // customerName/Email/Phone/Address, businessName/Email/Phone/Address/
  // Logo, bankName/accountName/accountNumber/otherPaymentDetails,
  // paymentTerms, poNumber, termsAndConditions, signature,
  // dueDateSummary, amountDue, etc — see defaultInvoiceEnabledFields()
  // above for the full key set). Populated from
  // InvoiceTemplate.enabledFields when a template is selected (see
  // StepCreateInvoice._syncToProvider()); read by
  // executive_invoice_stationary_layout.dart and invoice_pdf_service.dart
  // via `d.enabledFields[key] ?? true`, so a missing key (older
  // persisted invoices) always defaults to shown.
  Map<String, bool> enabledFields;

  // System-stamped (not user-typed, unlike issueDate/dueDate) — set the
  // moment paymentStatus flips to PaymentStatus.paid, cleared if it's ever
  // changed away from paid. See InvoiceProvider.updateSavedInvoiceStatus.
  DateTime? paidDate;

  // User-set escape hatch for the Reports screen — e.g. test invoices,
  // duplicates, or anything that shouldn't count toward income/aging/Top
  // Clients even if it's 100% complete and paid. Reports gating is:
  // completionPercent == 100 AND !excludeFromReports. See
  // reports_screen.dart's _isReportable().
  bool excludeFromReports;

  // When true, every card layout hides the colored status chip/pill for
  // this invoice (see doc_cards.dart) even though paymentStatus still
  // holds a real value underneath — set via the "None" option in the
  // status menu. Purely a display toggle; never affects aging, overdue
  // pushes, or reports gating, which all still read paymentStatus as
  // normal.
  bool statusHidden;

  // PAYMENT INFO / TERMS & CONDITIONS / SIGNATURE PASS: see the file
  // header comment above for the full rationale and rendering rules.
  // Bank details — bankName/accountName/accountNumber are the three
  // named fields; otherPaymentDetails is a single freeform field for
  // anything that doesn't fit those three (IBAN, SWIFT/BIC, routing/sort
  // code, PayPal handle, etc) rather than guessing which of those a
  // given business needs.
  String bankName;
  String accountName;
  String accountNumber;
  String otherPaymentDetails;

  // Payment Terms / due note — e.g. "Payment due within 14 days" — kept
  // separate from the generic `notes` field above.
  String paymentTerms;

  // PO / Reference Number — deliberately per-invoice (not copied from a
  // template the way bankName/etc are intended to be), since a PO number
  // is different on every invoice.
  String poNumber;

  String termsAndConditions;

  // Signature — three mutually exclusive modes. 'typed' renders
  // signatureName as a script-style caption; 'image' renders
  // signatureImagePath as-is (no crop/shape mask — a scanned signature
  // usually shouldn't be forced into a circle/square the way a logo is);
  // 'blank' renders neither, just an empty line reserved for a physical
  // wet-ink signature.
  String signatureMode; // 'typed' | 'image' | 'blank'
  String signatureName;
  String? signatureImagePath;

  // SIGNATURE SIZER PASS: font size (px) for the typed-name signature —
  // adjustable via a slider on the Customise step's Signature toggle row
  // (step_customise.dart). Only meaningfully affects signatureMode ==
  // 'typed'; harmless/unused for 'image' and 'blank'. Default 22.0
  // matches the size every typed signature rendered at before this
  // field existed, so persisted invoices look identical until someone
  // actually moves the slider.
  double signatureFontSize;

  // AMOUNT DUE PASS: manual override for the Amount Due figure shown
  // next to Due Date under Grand Total. Null means "auto" — amountDue
  // (getter below) always tracks grandTotal live. Once the user
  // manually edits the Amount Due field on the Create Invoice step,
  // this holds that fixed value and amountDue stops tracking grandTotal.
  double? amountDueOverride;

  InvoiceData({
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
    this.paymentStatus    = PaymentStatus.unpaid,
    this.fontFamily       = 'Roboto',
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
    this.paymentTerms        = '',
    this.poNumber            = '',
    this.termsAndConditions  = '',
    this.signatureMode       = 'blank',
    this.signatureName       = '',
    this.signatureImagePath,
    this.signatureFontSize = 22.0,
    this.amountDueOverride,
  }) : lineItems = lineItems ?? [],
       enabledFields = enabledFields ?? defaultInvoiceEnabledFields();

  // ── Computed totals ────────────────────────────────────────────────────────
  //
  // PER-ITEM TAX/DISCOUNT PASS: itemTaxExtra/itemDiscountExtra are new —
  // the sum of every line item's OWN tax/discount contribution (only
  // items with taxEnabled/discountEnabled true contribute, computed
  // against that item's own total, not the whole subtotal). grandTotal
  // now folds those in alongside the pre-existing whole-invoice
  // taxAmount/discountAmount, which are UNCHANGED — global and per-item
  // rates stack rather than one overriding the other. subtotal itself
  // is unchanged (still the plain sum of item totals with no rates
  // applied at all).
  double get subtotal       => lineItems.fold(0.0, (sum, i) => sum + i.total);
  double get discountAmount => subtotal * (discountRate / 100);
  double get taxAmount      => (subtotal - discountAmount) * (taxRate / 100);
  // TAX SIGN PASS: itemTaxExtra is now a SIGNED net total — positive
  // when an item's tax adds to the total (the default), negative when
  // itemTaxIsAddition is false (a withholding tax that reduces what's
  // owed). grandTotal's existing `+ itemTaxExtra` needed no formula
  // change at all — adding a negative number already subtracts
  // correctly. Every display site that reads this value now has to
  // handle a possibly-negative number instead of assuming it's always
  // an addition — see executive_invoice_stationary_layout.dart's
  // buildFooterSection and create_invoice_item_widgets.dart's
  // CreateInvoiceTotalsCard for the render-side fix.
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

  // TAX NAME PASS: itemTaxExtra/itemDiscountExtra above (the plain
  // totals used in grandTotal) stay unchanged — these two are the
  // display-side breakdown for the footer/totals card, grouping every
  // taxed/discounted item by its itemTaxName/itemDiscountName ('' counts
  // as its own group — "unnamed"). When every item shares one name (or
  // none has one), the map naturally comes back with a single entry, so
  // the totals section renders one row exactly as before; genuinely
  // different names each get their own row. Values here are SIGNED for
  // tax (matching itemTaxExtra's sign convention — negative for a
  // withholding group) and plain positive magnitudes for discount
  // (matching itemDiscountExtra, which is always subtracted at the call
  // site via a fixed `negative: true`).
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

  // AMOUNT DUE PASS: the actual "Amount Due" figure rendered on the
  // document — grandTotal unless the user has manually overridden it
  // (amountDueOverride != null), e.g. to reflect a partial payment
  // already received outside the app.
  double get amountDue => amountDueOverride ?? grandTotal;

  // ── Serialisation ──────────────────────────────────────────────────────────

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
        'paymentStatus':    paymentStatus.name,
        'fontFamily':       fontFamily,
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
        'paymentTerms':        paymentTerms,
        'poNumber':            poNumber,
        'termsAndConditions':  termsAndConditions,
        'signatureMode':       signatureMode,
        'signatureName':       signatureName,
        'signatureImagePath':  signatureImagePath,
        'signatureFontSize':   signatureFontSize,
        'amountDueOverride':   amountDueOverride,
      };

  factory InvoiceData.fromJson(Map<String, dynamic> j) => InvoiceData(
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
        paymentStatus: PaymentStatus.values.firstWhere(
          (s) => s.name == (j['paymentStatus'] as String? ?? ''),
          orElse: () => PaymentStatus.unpaid,
        ),
        fontFamily:  j['fontFamily'] as String? ?? 'Roboto',
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
        paymentTerms:        j['paymentTerms']         as String? ?? '',
        poNumber:            j['poNumber']             as String? ?? '',
        termsAndConditions:  j['termsAndConditions']   as String? ?? '',
        signatureMode:       j['signatureMode']        as String? ?? 'blank',
        signatureName:       j['signatureName']        as String? ?? '',
        signatureImagePath:  j['signatureImagePath']   as String?,
        signatureFontSize:   (j['signatureFontSize']   as num?)?.toDouble() ?? 22.0,
        amountDueOverride:   (j['amountDueOverride']   as num?)?.toDouble(),
      );

  // ── copyWith ───────────────────────────────────────────────────────────────
  //
  // clearPaidDate / clearBusinessLogo: explicit clear flags, same reasoning
  // as SavedInvoice's clearFolderName — a plain `x ?? this.x` copyWith can
  // never express "set this field to null" once it already has a value.
  // excludeFromReports/statusHidden are plain bools, so they don't need a
  // clear flag — `false` passes straight through the `?? this.x` pattern.
  // enabledFields is copied into a fresh Map instance either way (whether
  // a new map is passed in or not) so callers never accidentally share a
  // mutable Map reference between two InvoiceData instances.
  //
  // PAYMENT INFO / TERMS & CONDITIONS / SIGNATURE PASS: clearSignatureImage
  // added for the same reason as clearBusinessLogo/clearPaidDate — needed
  // to explicitly null out signatureImagePath once it's been set (e.g.
  // switching signatureMode away from 'image').
  //
  // AMOUNT DUE PASS: clearAmountDueOverride added for the same reason —
  // needed to explicitly null amountDueOverride back to "auto" (e.g. the
  // Create Invoice step's "tap to auto-calculate" action).
  //
  // TAX/DISCOUNT NAMING COPYWITH FIX: taxName/discountName added here —
  // previously missing from both the parameter list and the constructor
  // call below, so any value passed in was silently dropped and every
  // copy reset both fields back to ''. See file header comment.

  InvoiceData copyWith({
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
    PaymentStatus?  paymentStatus,
    String?         fontFamily,
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
    String?         paymentTerms,
    String?         poNumber,
    String?         termsAndConditions,
    String?         signatureMode,
    String?         signatureName,
    String?         signatureImagePath,
    bool            clearSignatureImage = false,
    double?         signatureFontSize,
    double?         amountDueOverride,
    bool            clearAmountDueOverride = false,
  }) =>
      InvoiceData(
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
        paymentStatus:    paymentStatus    ?? this.paymentStatus,
        fontFamily:       fontFamily       ?? this.fontFamily,
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
        paymentTerms:        paymentTerms        ?? this.paymentTerms,
        poNumber:            poNumber            ?? this.poNumber,
        termsAndConditions:  termsAndConditions  ?? this.termsAndConditions,
        signatureMode:       signatureMode       ?? this.signatureMode,
        signatureName:       signatureName       ?? this.signatureName,
        signatureImagePath: clearSignatureImage ? null : (signatureImagePath ?? this.signatureImagePath),
        signatureFontSize: signatureFontSize ?? this.signatureFontSize,
        amountDueOverride: clearAmountDueOverride ? null : (amountDueOverride ?? this.amountDueOverride),
      );

  InvoiceData deepCopy() => copyWith(
        lineItems: lineItems.map((i) => i.copyWith()).toList(),
        enabledFields: Map<String, bool>.from(enabledFields),
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

  // folderName/clearFolderName — pass a folderName to set it, or pass
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

// ─────────────────────────────────────────────────────────────────────────────
// SavedLineItemSet — a named, reusable bundle of line items, saved from
// the Create Invoice step's Line Items section and quick-added back onto
// any future invoice with a tap. Mirrors Customer/InvoiceTemplate's shape
// (id/name + toJson/fromJson/copyWith) so it persists the same way, via
// a single JSON-encoded SharedPreferences list — see
// create_invoice_saved_items_widgets.dart (CreateInvoiceSavedItemSets)
// for the UI this backs.
// ─────────────────────────────────────────────────────────────────────────────

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
  // LINE NET TOTAL PASS: sums each item's lineNetTotal (own tax/discount
  // included) rather than the plain base total, so a bundle preview's
  // total matches what adding those same items to an invoice would
  // actually add up to.
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

// ─────────────────────────────────────────────────────────────────────────────
// SavedInvoiceLineItem — a single saved line item (as opposed to
// SavedLineItemSet above, which is a bundle of several). Saved via the
// bookmark action on any line-item card while building an invoice, and
// browsed/radio-selected back onto any future invoice from the "Saved"
// tab of the Line Items section — see
// create_invoice_saved_line_items_widgets.dart for the UI this backs.
// Mirrors SavedLineItemSet's shape exactly (id/name + toJson/fromJson/
// copyWith), persisted the same way via its own single JSON-encoded
// SharedPreferences list, kept as a fully separate list/type from
// SavedLineItemSet rather than folding into it, since "one saved item"
// and "one saved bundle of items" are browsed and edited as genuinely
// different things in the UI.
// ─────────────────────────────────────────────────────────────────────────────

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

  /// What the library card shows as its title — the explicit label if
  /// one was given, else the item's own description, else a generic
  /// fallback. Never blank.
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

// ─────────────────────────────────────────────────────────────────────────────
// SavedInvoiceDraft — a named, editable invoice-in-progress. See
// INVOICE DRAFT LIBRARY PASS note at the top of this file for the full
// rationale. Stores a complete InvoiceData snapshot of everything
// editable on the Create Invoice step (customer override, dates,
// currency, line items, tax/discount, notes) plus a user-facing `name`
// for the library card, independent of any customer/invoice-number
// text so a draft can be labelled before either is filled in.
// ─────────────────────────────────────────────────────────────────────────────

class SavedInvoiceDraft {
  String id;
  String name;
  InvoiceData data;
  DateTime createdAt;
  DateTime lastEditedAt;

  // CONTAINER LOGO PASS: a small identifying image for this saved draft
  // container itself — separate from the invoice's own business logo
  // (InvoiceData.businessLogoPath) — so the library card
  // (step_create_invoice.dart's _InvoiceDraftCard) can show a real
  // thumbnail instead of a generic receipt icon, same as
  // step_templates.dart's saved template cards already do via
  // BusinessInfo.logoPath. Mirrors that same field set exactly
  // (offset/scale/shape + show-initial-fallback + optional letter
  // override), edited via the identical SharedLogoPicker UI in
  // create_invoice_bottom_sheet.dart's "Container Logo" section.
  // Defaults (no logo, fallback mark on, auto letter) preserve existing
  // behaviour for every draft saved before this field existed.
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

  /// What the library card shows as its title — the explicit label if one
  /// was typed, else the customer name, else the invoice number, else a
  /// generic fallback. Never blank.
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
