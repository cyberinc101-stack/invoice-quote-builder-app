// lib/screens/invoice_create_section/step_create_invoice/create_invoice_bottom_sheet.dart
//
// SAVED-ITEMS CAP ENFORCEMENT PASS (this update): _saveDraftItem() now
// checks the saved single-item library against
// kMaxSavedInvoiceLineItems (create_invoice_saved_line_items_widgets.dart,
// lowered to 100 in that file's own pass) before adding a new entry —
// previously the constant existed but nothing ever compared the
// library's length against it, so the saved-items library had no
// practical ceiling. When already at the cap, the item is NOT added to
// the saved library (and therefore not added to the invoice either,
// since it's only ever added as a saved-linked copy here), and a
// snackbar explains why. The typed draft is left exactly as entered so
// nothing is lost — same "block and explain, don't silently drop"
// pattern used for Container/Template/Customer caps elsewhere in this
// app, and the same fix applied to create_quote_bottom_sheet.dart's own
// _saveDraftItem(). Toggling inclusion of an ALREADY-saved item
// (_toggleSavedLineItem) is unaffected — that never creates a new saved
// entry, so the cap doesn't apply there.
//
// TAX-BASE FIX (earlier): _taxAmount was computing tax on the raw
// _subtotal (before the whole-invoice discount was subtracted) —
// `_subtotal * _taxRate / 100`. This mirrors the exact same bug found
// and fixed on Quote's and Receipt's equivalent bottom sheets, where
// QuoteData.taxAmount/ReceiptData.taxAmount had always computed tax on
// the DISCOUNTED subtotal instead: `(subtotal - discountAmount) *
// taxRate / 100`. Fixed here to match that same pattern:
// `(_subtotal - _discountAmount) * _taxRate / 100`.
//
// STRUCTURED ADDRESS PASS (earlier): the single flat "Customer
// Address" field (shown only when widget.selectedCustomer == null, i.e.
// a manual customer override) is now six fields — Address Line 1/2,
// City, State/Province, Country, ZIP/Postal Code — matching the same
// AddressInfo structure ClientInfo/BusinessInfo already use
// (lib/models/address_info.dart) and the same field set/lengths
// step_customers.dart's own Address section already collects (60/60/
// 40/40/40/16 char caps). Backed by six new controllers
// (_custAddrLine1Ctrl.../_custZipCtrl) instead of the old single
// _custAddressCtrl (removed). When widget.selectedCustomer != null, the
// whole customer-details block (including this) stays hidden exactly as
// before — the selected Customer's own addressInfo is used directly in
// _save(), no manual entry needed.
//
// _save() now builds an AddressInfo (from the selected Customer when
// one was passed in, or from the six manual controllers otherwise) and
// passes it as InvoiceData.clientAddressInfo, plus its .singleLine as
// the legacy clientAddress string (so anything still reading the flat
// field keeps working). Editing an existing draft seeds the six
// controllers from InvoiceData.clientAddressInfo (which itself falls
// back to the legacy flat string via AddressInfo.fromJson for any
// invoice saved before this pass).
//
// BANNER POSITION PASS (earlier): the Template/Customer context
// banner (CreateInvoiceContextBanner) now sits directly under the sheet
// title ("Create Invoice" / "Edit Invoice"), before the Container
// Details section — previously it sat further down, after Container
// Name/Container Logo. No state or logic changed, purely a reordering
// of two existing blocks in build().
//
// AMOUNT DUE FORMAL REDESIGN PASS (earlier): the Amount Due field
// previously sat side-by-side with Due Date in a plain two-column Row,
// using the same generic CreateInvoiceField as every other text input
// on this sheet — easy to miss as "the one number that can override the
// invoice total" rather than reading as a first-class amount field.
// Replaced with a bespoke _AmountDueField widget rendering Amount Due as
// its own formal card, with a "Defaults to Total — {currency} {total}"
// helper line, a "Custom" chip, and a "Reset to total" text-button once
// overridden. All existing state/logic is unchanged — _amountDueCtrl,
// _amountDueManuallySet, _syncAmountDueIfAuto(), _resetAmountDueToAuto()
// all behave exactly as before.
//
// SAVED ITEMS COLLAPSIBLE HEADER PASS (earlier): removed the plain
// `_sectionHeader('Saved Items', icon: Icons.bookmark_rounded)` call
// that used to sit directly above CreateInvoiceSavedLineItemsPanel —
// that panel now renders its own section header (title + live item
// count + a chevron that collapses the search field/sort dropdown/card
// list).
//
// WHOLE-INVOICE TAX/DISCOUNT TOGGLE PASS (earlier): added two
// switches — Tax and Discount — right above their Name/% fields under
// "whole-invoice" Tax/Discount, each independently defaulting from a
// persisted "last used" SharedPreferences value on a brand-new invoice.
//
// See prior header comments (preserved from the previous pass) for the
// full history of DUPLICATE-DECLARATION FIX, TAX NAME PASS, TAX SIGN
// PASS, PER-ITEM TAX/DISCOUNT ON DRAFT CARD PASS, UNIT OF MEASURE PASS,
// AMOUNT DUE PASS, CONTAINER LOGO + MANDATORY NAME PASS,
// LINE-ITEMS-ABOVE PASS, ONE-SCREEN LINE ITEMS PASS,
// NEW-TAB DECLUTTER PASS, SINGLE-DRAFT ITEM PASS,
// BUNDLE PANEL REMOVAL PASS, PER-ITEM TAX/DISCOUNT + SAVE-ITEM PASS,
// and the original INVOICE LIBRARY RESTRUCTURE PASS that created this
// file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/invoice_models.dart';
import '../../../models/address_info.dart';
import '../../../widgets/shared_logo_picker.dart';
import 'create_invoice_item_widgets.dart';
import 'create_invoice_form_widgets.dart';
import 'create_invoice_saved_line_items_widgets.dart';

// =============================================================================
// CreateInvoiceBottomSheet
// =============================================================================

class CreateInvoiceBottomSheet extends StatefulWidget {
  final Customer? selectedCustomer;
  final InvoiceTemplate? selectedTemplate;

  /// The draft being edited, or null when creating a brand new one.
  final SavedInvoiceDraft? existing;

  final void Function(SavedInvoiceDraft draft) onSaved;

  const CreateInvoiceBottomSheet({
    super.key,
    this.selectedCustomer,
    this.selectedTemplate,
    this.existing,
    required this.onSaved,
  });

  @override
  State<CreateInvoiceBottomSheet> createState() =>
      _CreateInvoiceBottomSheetState();
}

class _CreateInvoiceBottomSheetState extends State<CreateInvoiceBottomSheet> {
  static const _accent = Color(0xFF2196F3);

  // TAX/DISCOUNT DEFAULT-OFF + PERSISTED PASS: SharedPreferences keys
  // remembering the last on/off state the person left these two
  // switches in. Used only to seed a BRAND NEW invoice (no existing
  // draft) — editing an existing draft still restores that draft's own
  // saved taxEnabled/discountEnabled exactly as before. A first-ever
  // new invoice (no persisted value yet) starts with both OFF.
  static const _kPrefTaxEnabledLast = 'create_invoice_tax_enabled_last';
  static const _kPrefDiscountEnabledLast = 'create_invoice_discount_enabled_last';

  // INVOICE NUMBER LENGTH FIX (carried over): single source of truth for
  // the field's max character cap — see the original step file's note.
  static const int _invoiceNumberMax = 18;

  // Draft label — shown on the library card. Optional; falls back to
  // customer name / invoice number / "Untitled Draft" per
  // SavedInvoiceDraft.displayName.
  late TextEditingController _nameCtrl;

  // CONTAINER LOGO + MANDATORY NAME PASS: this container's own
  // identifying image — separate from the invoice's business logo —
  // edited via the exact same SharedLogoPicker UI the Template sheet
  // uses. Seeded from widget.existing on edit.
  String? _containerLogoPath;
  Offset _containerLogoOffset = Offset.zero;
  double _containerLogoScale = 1.0;
  LogoShape _containerLogoShape = LogoShape.roundedSquare;
  bool _containerLogoShowInitial = true;
  String _containerLogoInitialLetter = '';

  // Controllers
  late TextEditingController _invoiceNumberCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _discountCtrl;
  // TAX/DISCOUNT NAMING PASS: whole-invoice custom label, e.g. "GST" /
  // "Trade Discount" -- capped at 8 chars, same as every per-item custom
  // name field.
  late TextEditingController _taxNameCtrl;
  late TextEditingController _discountNameCtrl;

  // Customer override (if no customer passed from step 1)
  late TextEditingController _custNameCtrl;
  late TextEditingController _custEmailCtrl;
  late TextEditingController _custPhoneCtrl;

  // STRUCTURED ADDRESS PASS: the manual customer-override address is now
  // six fields instead of one flat one, matching AddressInfo
  // (lib/models/address_info.dart) and the same fields/lengths
  // step_customers.dart's own Address section already collects. Only
  // used/shown when widget.selectedCustomer == null — when a customer
  // IS selected, that Customer's own addressInfo is used directly in
  // _save() and none of these six controllers are rendered.
  late TextEditingController _custAddrLine1Ctrl;
  late TextEditingController _custAddrLine2Ctrl;
  late TextEditingController _custCityCtrl;
  late TextEditingController _custStateCtrl;
  late TextEditingController _custCountryCtrl;
  late TextEditingController _custZipCtrl;

  // Committed line items — every entry here is already final (added via
  // the draft card's Save Item button, or via toggling a Saved-tab
  // checkbox). Nothing here is edited in place any more; see
  // SINGLE-DRAFT ITEM PASS above.
  late List<InvoiceItem> _items;

  // SINGLE-DRAFT ITEM PASS: the one item currently being typed under
  // "New", not yet part of _items. A single set of controllers, not a
  // per-index list — there is only ever one draft on screen.
  late InvoiceItem _draftItem;
  late TextEditingController _draftDescCtrl;
  late TextEditingController _draftQtyCtrl;
  late TextEditingController _draftPriceCtrl;

  // UNIT OF MEASURE PASS: free-text label for the draft item's unit,
  // only meaningful while _draftItem.unit == 'custom' — the dropdown's
  // own value lives directly on _draftItem.unit (mutated in place by
  // CreateInvoiceItemCard, same as description/qty/price), so this is
  // the only extra controller the picker needs here.
  late TextEditingController _draftUnitCustomLabelCtrl;

  // PER-ITEM TAX/DISCOUNT ON DRAFT CARD PASS: %-input controllers for
  // the "Tax for this item"/"Discount for this item" switches, brought
  // back onto the draft card — same shape as the Saved Item edit
  // sheet's own _taxCtrl/_discountCtrl. The switches' on/off state lives
  // directly on _draftItem.taxEnabled/discountEnabled (mutated in place
  // by the card, same as everything else); only the % text needs a
  // real controller.
  late TextEditingController _draftTaxRateCtrl;
  late TextEditingController _draftDiscountRateCtrl;

  // TAX NAME PASS: "VAT, GST…" / "Trade Discount…" free-text names for
  // the draft card, same shape as _draftTaxRateCtrl/
  // _draftDiscountRateCtrl above.
  late TextEditingController _draftTaxNameCtrl;
  late TextEditingController _draftDiscountNameCtrl;

  // PER-ITEM TAX/DISCOUNT + SAVE-ITEM PASS: the saved single-item
  // library, always shown alongside the draft card (see ONE-SCREEN LINE
  // ITEMS PASS above).
  bool _savedLibraryLoading = true;
  List<SavedInvoiceLineItem> _savedLineItems = [];

  // Dates
  late DateTime _invoiceDate;
  late DateTime _dueDate;

  // Currency — free-text code + symbol + Code/Symbol/Both display mode.
  late TextEditingController _currencyCodeCtrl;
  late TextEditingController _currencySymbolCtrl;
  String _currencyDisplayMode = 'code'; // 'code' | 'symbol' | 'both'

  // Tax / discount rates -- source of truth for totals math (see
  // OVERFLOW FIX note in the original step file, carried over unchanged).
  // This remains the WHOLE-INVOICE rate — per-item rates live on each
  // LineItem itself and stack with this rather than replacing it (see
  // invoice_data.dart's InvoiceData.grandTotal).
  double _taxRate = 0.0;
  double _discountRate = 0.0;

  // WHOLE-INVOICE TAX/DISCOUNT TOGGLE PASS: on/off switches for the two
  // rates above. Seeded from the existing draft's InvoiceData in
  // initState(); default true for a brand-new draft.
  bool _taxEnabled = true;
  bool _discountEnabled = true;

  // AMOUNT DUE PASS: Amount Due input under Totals. Auto-tracks _total
  // (via _syncAmountDueIfAuto(), called every build) until the person
  // types their own value, at which point _amountDueManuallySet flips
  // true and it stops auto-updating. _syncingAmountDue guards the
  // controller's own listener while we write to it programmatically, so
  // the auto-sync itself never gets mistaken for a manual edit.
  late TextEditingController _amountDueCtrl;
  bool _amountDueManuallySet = false;
  bool _syncingAmountDue = false;

  static const _dateFmt = 'd MMM yyyy';

  bool get _isEditing => widget.existing != null;

  String get _currencyPrefix {
    final symbol = _currencySymbolCtrl.text.trim();
    final code = _currencyCodeCtrl.text.trim().toUpperCase();
    if (symbol.isNotEmpty) return symbol;
    if (code.isNotEmpty) return '$code ';
    return '';
  }

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.total);
  // WHOLE-INVOICE TAX/DISCOUNT TOGGLE PASS: each now returns 0 while
  // its switch is off, mirroring InvoiceData.taxAmount/discountAmount's
  // matching change.
  double get _discountAmount => _discountEnabled ? _subtotal * _discountRate / 100 : 0.0;
  // TAX-BASE FIX: tax now applies to the DISCOUNTED subtotal — see this
  // file's header comment for the full rationale. Previously this read
  // `_subtotal * _taxRate / 100`, ignoring the whole-invoice discount
  // entirely. _discountAmount is referenced here even though it's
  // declared as the getter directly above; Dart getters resolve lazily
  // so the order between them doesn't matter.
  double get _taxAmount =>
      _taxEnabled ? (_subtotal - _discountAmount) * _taxRate / 100 : 0.0;
  // TAX SIGN PASS: signed net figure, same as InvoiceData.itemTaxExtra —
  // positive for an item whose tax adds to the total (default),
  // negative for a withholding item. `_total`'s `+ _itemTaxExtra` below
  // needed no formula change — a negative value already subtracts.
  double get _itemTaxExtra => _items.fold(
      0.0,
      (sum, i) => sum +
          (i.taxEnabled
              ? (i.itemTaxIsAddition ? 1 : -1) * i.total * i.itemTaxRate / 100
              : 0.0));
  double get _itemDiscountExtra => _items.fold(0.0,
      (sum, i) => sum + (i.discountEnabled ? i.total * i.itemDiscountRate / 100 : 0.0));
  double get _total =>
      _subtotal + _taxAmount - _discountAmount + _itemTaxExtra - _itemDiscountExtra;

  // TAX NAME PASS: grouped-by-name breakdown for CreateInvoiceTotalsCard
  // — same logic as InvoiceData.itemTaxExtraByName/itemDiscountExtraByName
  // (that getter's own comment explains the grouping/sign rules in
  // full). _itemTaxExtra/_itemDiscountExtra above are unaffected — they
  // still feed _total exactly as before; these two are purely for the
  // live totals card's per-name display.
  Map<String, double> get _itemTaxExtraByName {
    final map = <String, double>{};
    for (final i in _items) {
      if (!i.taxEnabled) continue;
      final key = i.itemTaxName.trim();
      final amt = (i.itemTaxIsAddition ? 1 : -1) * i.total * i.itemTaxRate / 100;
      map[key] = (map[key] ?? 0.0) + amt;
    }
    return map;
  }

  Map<String, double> get _itemDiscountExtraByName {
    final map = <String, double>{};
    for (final i in _items) {
      if (!i.discountEnabled) continue;
      final key = i.itemDiscountName.trim();
      final amt = i.total * i.itemDiscountRate / 100;
      map[key] = (map[key] ?? 0.0) + amt;
    }
    return map;
  }

  // Which saved-item ids are currently included on this invoice, derived
  // live from _items' sourceSavedId — drives the Saved panel's checkbox
  // state.
  Set<String> get _includedSavedIds => _items
      .map((i) => i.sourceSavedId)
      .whereType<String>()
      .toSet();

  @override
  void initState() {
    super.initState();

    final existingData = widget.existing?.data;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final tsShort = ts
        .toString()
        .substring((ts.toString().length - 6).clamp(0, ts.toString().length));

    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');

    _containerLogoPath = widget.existing?.logoPath;
    _containerLogoOffset = Offset(
      widget.existing?.logoOffsetDx ?? 0.0,
      widget.existing?.logoOffsetDy ?? 0.0,
    );
    _containerLogoScale = widget.existing?.logoScale ?? 1.0;
    _containerLogoShape = logoShapeFromString(widget.existing?.logoShape ?? 'roundedSquare');
    _containerLogoShowInitial = widget.existing?.logoShowInitial ?? true;
    _containerLogoInitialLetter = widget.existing?.logoInitialLetter ?? '';

    _invoiceNumberCtrl = TextEditingController(
      text: (existingData != null && existingData.invoiceNumber.isNotEmpty)
          ? existingData.invoiceNumber
          : 'INV-$tsShort',
    );
    _notesCtrl = TextEditingController(text: existingData?.notes ?? '');
    _taxCtrl = TextEditingController(
      text: (existingData == null || existingData.taxRate == 0)
          ? '0'
          : '${existingData.taxRate}',
    );
    _discountCtrl = TextEditingController(
      text: (existingData == null || existingData.discountRate == 0)
          ? '0'
          : '${existingData.discountRate}',
    );
    _taxRate = (existingData?.taxRate ?? 0.0).clamp(0.0, 100.0);
    _discountRate = (existingData?.discountRate ?? 0.0).clamp(0.0, 100.0);
    // TAX/DISCOUNT DEFAULT-OFF + PERSISTED PASS: editing an existing
    // draft still restores exactly what that draft had saved. A brand
    // new invoice starts OFF by default; _loadLastToggleDefaults() below
    // then asynchronously overrides that with whatever the person left
    // these switches at last time, once SharedPreferences resolves.
    _taxEnabled = existingData?.taxEnabled ?? false;
    _discountEnabled = existingData?.discountEnabled ?? false;
    _taxNameCtrl = TextEditingController(text: existingData?.taxName ?? '');
    _discountNameCtrl = TextEditingController(text: existingData?.discountName ?? '');

    // Customer override fields — the customer picked in step 1 wins;
    // otherwise fall back to whatever's stored on the draft being edited.
    _custNameCtrl = TextEditingController(
      text: widget.selectedCustomer?.name ?? existingData?.clientName ?? '',
    );
    _custEmailCtrl = TextEditingController(
      text: widget.selectedCustomer?.email ?? existingData?.clientEmail ?? '',
    );
    _custPhoneCtrl = TextEditingController(
      text: widget.selectedCustomer?.phone ?? existingData?.clientPhone ?? '',
    );

    // STRUCTURED ADDRESS PASS: seed the six manual fields from the
    // existing draft's structured clientAddressInfo (which itself
    // migrates a legacy flat clientAddress string via
    // AddressInfo.fromJson for any invoice saved before this pass).
    // These six controllers are only ever shown/used when
    // widget.selectedCustomer == null — when a customer IS selected,
    // _save() reads that Customer's own addressInfo directly instead.
    final seedAddress = existingData?.clientAddressInfo ?? AddressInfo();
    _custAddrLine1Ctrl = TextEditingController(text: seedAddress.line1);
    _custAddrLine2Ctrl = TextEditingController(text: seedAddress.line2);
    _custCityCtrl = TextEditingController(text: seedAddress.city);
    _custStateCtrl = TextEditingController(text: seedAddress.state);
    _custCountryCtrl = TextEditingController(text: seedAddress.country);
    _custZipCtrl = TextEditingController(text: seedAddress.postalCode);

    final initialCurrencyCode = widget.selectedTemplate?.currency ??
        ((existingData != null && existingData.currency.isNotEmpty)
            ? existingData.currency
            : 'USD');
    _currencyCodeCtrl = TextEditingController(text: initialCurrencyCode);
    _currencySymbolCtrl =
        TextEditingController(text: existingData?.currencySymbol ?? '');
    _currencyDisplayMode =
        (existingData != null && existingData.currencyDisplayMode.isNotEmpty)
            ? existingData.currencyDisplayMode
            : 'code';

    _invoiceDate = (existingData != null && existingData.issueDate.isNotEmpty)
        ? (DateFormat(_dateFmt).tryParse(existingData.issueDate) ??
            DateTime.now())
        : DateTime.now();
    _dueDate = (existingData != null && existingData.dueDate.isNotEmpty)
        ? (DateFormat(_dateFmt).tryParse(existingData.dueDate) ??
            DateTime.now().add(const Duration(days: 30)))
        : DateTime.now().add(const Duration(days: 30));

    // Committed items — restore from the draft if present, else start
    // with an empty invoice (the draft card below is how the first item
    // gets added).
    _items = (existingData != null && existingData.lineItems.isNotEmpty)
        ? existingData.lineItems.map((i) => i.copyWith()).toList()
        : [];

    // AMOUNT DUE PASS: seed from the existing draft's manual override if
    // it had one, else start in "auto" mode showing _total (which is
    // safe to read now — _items/_taxRate/_discountRate are all already
    // set above). The listener only flips _amountDueManuallySet when
    // the change didn't come from our own programmatic sync
    // (_syncAmountDueIfAuto(), called every build).
    final existingAmountDue = existingData?.amountDueOverride;
    _amountDueManuallySet = existingAmountDue != null;
    _amountDueCtrl = TextEditingController(
      text: (existingAmountDue ?? _total).toStringAsFixed(2),
    );
    _amountDueCtrl.addListener(() {
      if (!_syncingAmountDue && !_amountDueManuallySet) {
        setState(() => _amountDueManuallySet = true);
      }
    });

    // The draft card always starts blank.
    _draftItem = InvoiceItem();
    _draftDescCtrl = TextEditingController();
    _draftQtyCtrl = TextEditingController(text: '1');
    _draftPriceCtrl = TextEditingController(text: '0');
    _draftUnitCustomLabelCtrl = TextEditingController();
    _draftTaxRateCtrl = TextEditingController(text: '0');
    _draftDiscountRateCtrl = TextEditingController(text: '0');
    _draftTaxNameCtrl = TextEditingController();
    _draftDiscountNameCtrl = TextEditingController();

    // Rebuild on changes for totals / live currency preview / counters.
    for (final c in [
      _nameCtrl,
      _invoiceNumberCtrl,
      _taxCtrl,
      _discountCtrl,
      _taxNameCtrl,
      _discountNameCtrl,
      _currencyCodeCtrl,
      _currencySymbolCtrl,
      _draftDescCtrl,
      _draftQtyCtrl,
      _draftPriceCtrl,
      _draftUnitCustomLabelCtrl,
      _draftTaxRateCtrl,
      _draftDiscountRateCtrl,
      _draftTaxNameCtrl,
      _draftDiscountNameCtrl,
    ]) {
      c.addListener(() => setState(() {}));
    }

    _loadSavedLibrary();

    // TAX/DISCOUNT DEFAULT-OFF + PERSISTED PASS: only for a brand new
    // invoice — an existing draft already has its own real saved values
    // seeded above and must not be overridden by this "last used"
    // convenience default.
    if (existingData == null) {
      _loadLastToggleDefaults();
    }
  }

  // TAX/DISCOUNT DEFAULT-OFF + PERSISTED PASS: reads whatever on/off
  // state the person left Tax/Discount in last time (defaulting to OFF
  // if this is the very first time), and applies it to a brand-new
  // invoice's switches once SharedPreferences resolves.
  Future<void> _loadLastToggleDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    final tax = prefs.getBool(_kPrefTaxEnabledLast) ?? false;
    final discount = prefs.getBool(_kPrefDiscountEnabledLast) ?? false;
    if (!mounted) return;
    setState(() {
      _taxEnabled = tax;
      _discountEnabled = discount;
    });
  }

  Future<void> _persistTaxEnabledDefault(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefTaxEnabledLast, value);
  }

  Future<void> _persistDiscountEnabledDefault(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefDiscountEnabledLast, value);
  }

  Future<void> _loadSavedLibrary() async {
    final items = await loadSavedLineItems();
    if (!mounted) return;
    setState(() {
      _savedLineItems = items;
      _savedLibraryLoading = false;
    });
  }

  // AMOUNT DUE PASS: keeps _amountDueCtrl showing the live running total
  // whenever the person hasn't manually overridden it. Called at the top
  // of build() every rebuild (items/tax/discount edits already trigger a
  // rebuild via their own onChanged handlers, so this piggybacks on that
  // rather than needing its own separate listeners on every input).
  // Writes to the controller directly rather than via setState — a plain
  // TextEditingController.text assignment already notifies the bound
  // TextField on its own. _syncingAmountDue guards the controller's own
  // listener (above) so this programmatic write is never mistaken for
  // the person typing.
  void _syncAmountDueIfAuto() {
    if (_amountDueManuallySet) return;
    final autoText = _total.toStringAsFixed(2);
    if (_amountDueCtrl.text == autoText) return;
    _syncingAmountDue = true;
    _amountDueCtrl.text = autoText;
    _syncingAmountDue = false;
  }

  void _resetAmountDueToAuto() {
    setState(() {
      _amountDueManuallySet = false;
      _amountDueCtrl.text = _total.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _invoiceNumberCtrl, _notesCtrl, _taxCtrl,
      _discountCtrl, _taxNameCtrl, _discountNameCtrl, _custNameCtrl, _custEmailCtrl,
      _custPhoneCtrl,
      _custAddrLine1Ctrl, _custAddrLine2Ctrl, _custCityCtrl,
      _custStateCtrl, _custCountryCtrl, _custZipCtrl,
      _currencyCodeCtrl, _currencySymbolCtrl,
      _draftDescCtrl, _draftQtyCtrl, _draftPriceCtrl,
      _draftUnitCustomLabelCtrl,
      _draftTaxRateCtrl, _draftDiscountRateCtrl,
      _draftTaxNameCtrl, _draftDiscountNameCtrl,
      _amountDueCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // SINGLE-DRAFT ITEM PASS: commit the draft card — adds it to the
  // invoice's real line items AND saves it into the single-item library
  // in one action, then resets the draft card back to blank. This is
  // the fix for the reported bug where the only way to persist anything
  // was the one big Save Invoice button at the bottom.
  //
  // SAVED-ITEMS CAP ENFORCEMENT PASS: guards the saved-library side of
  // this action against kMaxSavedInvoiceLineItems — if the library is
  // already full, the new item is NOT saved to the library (and
  // therefore not added to _items either, since it's only ever added as
  // a saved-linked copy here), and a snackbar explains why. The typed
  // draft is left untouched so nothing the person entered is lost.
  // ---------------------------------------------------------------------------
  Future<void> _saveDraftItem() async {
    _draftItem
      ..description = _draftDescCtrl.text.trim()
      ..quantity = double.tryParse(_draftQtyCtrl.text) ?? 1
      ..unitPrice = double.tryParse(_draftPriceCtrl.text) ?? 0
      // UNIT OF MEASURE PASS: _draftItem.unit itself is already kept in
      // sync live by CreateInvoiceItemCard's dropdown callback (it
      // mutates item.unit directly, same as description/qty/price
      // above); customUnitLabel is the one field backed by a real
      // controller here, so it gets the same defensive re-sync the
      // other controller-backed fields get.
      ..customUnitLabel = _draftItem.unit == 'custom'
          ? _draftUnitCustomLabelCtrl.text.trim()
          : ''
      // PER-ITEM TAX/DISCOUNT ON DRAFT CARD PASS: same defensive
      // re-sync — taxEnabled/discountEnabled are already kept live by
      // the card's Switch callbacks; itemTaxRate/itemDiscountRate are
      // the two fields backed by real controllers here.
      ..itemTaxRate = (double.tryParse(_draftTaxRateCtrl.text) ?? 0.0).clamp(0.0, 100.0)
      ..itemDiscountRate = (double.tryParse(_draftDiscountRateCtrl.text) ?? 0.0).clamp(0.0, 100.0)
      // TAX NAME PASS: same defensive re-sync for the two name fields.
      ..itemTaxName = _draftTaxNameCtrl.text.trim()
      ..itemDiscountName = _draftDiscountNameCtrl.text.trim();

    if (_draftItem.description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a description before saving this item.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // SAVED-ITEMS CAP ENFORCEMENT PASS: block before creating the
    // library entry — kMaxSavedInvoiceLineItems is exported from
    // create_invoice_saved_line_items_widgets.dart (now 100).
    if (_savedLineItems.length >= kMaxSavedInvoiceLineItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Maximum of $kMaxSavedInvoiceLineItems saved items reached. Delete one before saving another.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final libraryEntry = SavedInvoiceLineItem(
      id: const Uuid().v4(),
      item: _draftItem.copyWith(clearSourceSavedId: true),
      createdAt: now,
      lastEditedAt: now,
    );

    setState(() {
      _savedLineItems.add(libraryEntry);
      _items.add(_draftItem.copyWith(sourceSavedId: libraryEntry.id));
      // Reset the draft card to blank for the next item.
      _draftItem = InvoiceItem();
      _draftDescCtrl.text = '';
      _draftQtyCtrl.text = '1';
      _draftPriceCtrl.text = '0';
      _draftUnitCustomLabelCtrl.text = '';
      _draftTaxRateCtrl.text = '0';
      _draftDiscountRateCtrl.text = '0';
      _draftTaxNameCtrl.text = '';
      _draftDiscountNameCtrl.text = '';
    });
    await persistSavedLineItems(_savedLineItems);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved "${libraryEntry.displayName}" and added it to this invoice.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeCommittedItem(int index) {
    // Kept for API symmetry with the saved-items panel's own removal
    // path — not currently wired to any visible button since the
    // ONE-SCREEN LINE ITEMS PASS folded the committed-item list into the
    // saved-items panel above, but harmless to leave here if a future
    // pass wants a direct remove action again.
    setState(() => _items.removeAt(index));
  }

  // ---------------------------------------------------------------------------
  // Toggle a saved item's inclusion on this invoice. Adding appends a
  // fresh LineItem copy tagged with sourceSavedId; removing drops every
  // current item tagged with that id.
  // ---------------------------------------------------------------------------
  void _toggleSavedLineItem(SavedInvoiceLineItem saved) {
    final alreadyIncluded = _items.any((i) => i.sourceSavedId == saved.id);
    setState(() {
      if (alreadyIncluded) {
        _items.removeWhere((i) => i.sourceSavedId == saved.id);
      } else {
        _items.add(saved.item.copyWith(sourceSavedId: saved.id));
      }
    });
  }

  Future<void> _editSavedLineItem(int index, SavedInvoiceLineItem updated) async {
    setState(() => _savedLineItems[index] = updated);
    await persistSavedLineItems(_savedLineItems);
  }

  Future<void> _deleteSavedLineItem(int index) async {
    setState(() => _savedLineItems.removeAt(index));
    await persistSavedLineItems(_savedLineItems);
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------
  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateForm() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a name for this container.');
      return false;
    }

    if (_invoiceNumberCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter an invoice number.');
      return false;
    }

    if (widget.selectedCustomer == null && _custNameCtrl.text.trim().isEmpty) {
      _showValidationError('Please enter a customer name.');
      return false;
    }

    if (_items.isEmpty) {
      _showValidationError('Add and save at least one item to continue.');
      return false;
    }

    if (_discountRate < 0 || _discountRate > 100) {
      _showValidationError('Discount must be between 0 and 100%.');
      return false;
    }

    if (_taxRate < 0 || _taxRate > 100) {
      _showValidationError('Tax rate must be between 0 and 100%.');
      return false;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Save — validates, builds an InvoiceData off the already-committed
  // _items list (nothing to flush any more — every entry is final the
  // moment it's added), wraps it in a SavedInvoiceDraft (preserving id/
  // createdAt when editing), hands it to the parent via onSaved(), and
  // closes the sheet.
  //
  // AMOUNT DUE PASS: amountDueOverride is only set when the person
  // actually typed their own Amount Due value (_amountDueManuallySet);
  // otherwise it stays null so InvoiceData.amountDue keeps auto-tracking
  // grandTotal on the document, not a stale snapshot of _total taken at
  // save time.
  //
  // STRUCTURED ADDRESS PASS: clientAddressInfo comes straight from the
  // selected Customer (widget.selectedCustomer!.addressInfo) when one
  // was picked in step 1 — that Customer's own structured address is
  // the source of truth, and none of the six manual controllers are
  // rendered in that case. Otherwise it's built from the six manual
  // fields. Either way, clientAddress (the legacy flat string) is kept
  // in sync via .singleLine, same pattern client_info.dart's own sheets
  // already use for ClientInfo/BusinessInfo.
  // ---------------------------------------------------------------------------
  void _save() {
    if (!_validateForm()) return;

    final clientAddressInfo = widget.selectedCustomer?.addressInfo ??
        AddressInfo(
          line1: _custAddrLine1Ctrl.text.trim(),
          line2: _custAddrLine2Ctrl.text.trim(),
          city: _custCityCtrl.text.trim(),
          state: _custStateCtrl.text.trim(),
          country: _custCountryCtrl.text.trim(),
          postalCode: _custZipCtrl.text.trim(),
        );

    final data = InvoiceData(
      clientName: _custNameCtrl.text.trim(),
      clientEmail: _custEmailCtrl.text.trim(),
      clientPhone: _custPhoneCtrl.text.trim(),
      clientAddress: clientAddressInfo.singleLine,
      clientAddressInfo: clientAddressInfo,
      invoiceNumber: _invoiceNumberCtrl.text.trim(),
      issueDate: DateFormat(_dateFmt).format(_invoiceDate),
      dueDate: DateFormat(_dateFmt).format(_dueDate),
      notes: _notesCtrl.text.trim(),
      currency: _currencyCodeCtrl.text.trim().isEmpty
          ? 'USD'
          : _currencyCodeCtrl.text.trim().toUpperCase(),
      currencySymbol: _currencySymbolCtrl.text.trim(),
      currencyDisplayMode: _currencyDisplayMode,
      lineItems: List<InvoiceItem>.from(_items),
      taxRate: _taxRate,
      discountRate: _discountRate,
      taxName: _taxNameCtrl.text.trim(),
      discountName: _discountNameCtrl.text.trim(),
      taxEnabled: _taxEnabled,
      discountEnabled: _discountEnabled,
      amountDueOverride: _amountDueManuallySet
          ? (double.tryParse(_amountDueCtrl.text) ?? _total)
          : null,
    );

    final now = DateTime.now();
    final draft = SavedInvoiceDraft(
      id: widget.existing?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      data: data,
      createdAt: widget.existing?.createdAt ?? now,
      lastEditedAt: now,
      logoPath: _containerLogoPath,
      logoOffsetDx: _containerLogoOffset.dx,
      logoOffsetDy: _containerLogoOffset.dy,
      logoScale: _containerLogoScale,
      logoShape: _containerLogoShape.storageName,
      logoShowInitial: _containerLogoShowInitial,
      logoInitialLetter: _containerLogoInitialLetter.trim(),
    );

    widget.onSaved(draft);
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // Date picker
  // ---------------------------------------------------------------------------
  Future<void> _pickDate(bool isDueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isDueDate ? _dueDate : _invoiceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDueDate) {
          _dueDate = picked;
        } else {
          _invoiceDate = picked;
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Section helpers (mirrors the original step file's helpers exactly)
  // ---------------------------------------------------------------------------
  Widget _sectionHeader(String label, {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          if (icon != null) ...[
            Icon(icon, size: 16, color: _accent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _counter(int current, int max) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          '$current / $max',
          style: TextStyle(
            fontSize: 11,
            color: current > max
                ? const Color(0xFFF44336)
                : colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }

  Widget _rangeWarning(double raw, double clamped) {
    if (raw == clamped) return const SizedBox.shrink();
    final clampedLabel = clamped % 1 == 0
        ? clamped.toInt().toString()
        : clamped.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 2),
      child: Text(
        'Using $clampedLabel% for totals (must be 0-100)',
        style: const TextStyle(fontSize: 10.5, color: Color(0xFFF44336)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // AMOUNT DUE PASS: keep the Amount Due field showing the live total
    // for as long as it's still in auto mode. Safe to call unconditionally
    // every build — it's a no-op once the text already matches, and it
    // never calls setState itself (see the method's own comment).
    _syncAmountDueIfAuto();

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat(_dateFmt);
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = kb + 32 + MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      minChildSize: 0.4,
      maxChildSize: 0.96,
      builder: (context, sc) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: sc,
                  padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Sheet title row ─────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _isEditing ? 'Edit Invoice' : 'Create Invoice',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (_isEditing)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D1B2E)
                                    : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: _accent.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Editing',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Context banner (template / customer selection) ─
                      // BANNER POSITION PASS: moved here, directly under
                      // the title, so it's the first thing seen after
                      // opening the sheet — previously this sat further
                      // down, after Container Details/Container Logo.
                      CreateInvoiceContextBanner(
                        template: widget.selectedTemplate,
                        customer: widget.selectedCustomer,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),

                      // ── Container name + logo ────────────────────────
                      // CONTAINER LOGO + MANDATORY NAME PASS: this name
                      // is now required — it's the label shown on this
                      // draft's library card back on step_create_invoice.
                      // dart, so it can't be left blank the way an
                      // optional label could.
                      _sectionHeader('Container Details', icon: Icons.folder_rounded),
                      CreateInvoiceField(
                        ctrl: _nameCtrl,
                        label: 'Container Name *',
                        hint: 'e.g. Acme Corp — March retainer',
                        icon: Icons.label_rounded,
                        max: 60,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_nameCtrl.text.length, 60),
                      const SizedBox(height: 20),

                      // Container logo — a small identifying image for
                      // THIS SAVED CONTAINER, separate from the
                      // invoice's own business logo below. Uses the
                      // exact same SharedLogoPicker widget and params as
                      // step_templates.dart's "Business Logo" section,
                      // so upload/reposition/zoom/shape and the
                      // "show letter mark when there's no logo" switch
                      // all behave identically.
                      _sectionHeader('Container Logo', icon: Icons.image_rounded),
                      SharedLogoPicker(
                        logoPath: _containerLogoPath,
                        logoOffset: _containerLogoOffset,
                        logoScale: _containerLogoScale,
                        logoShape: _containerLogoShape,
                        accent: _accent,
                        onChanged: (p, o, s, shape) => setState(() {
                          _containerLogoPath = p;
                          _containerLogoOffset = o;
                          _containerLogoScale = s;
                          _containerLogoShape = shape;
                        }),
                        showInitialFallback: _containerLogoShowInitial,
                        onShowInitialFallbackChanged: (v) =>
                            setState(() => _containerLogoShowInitial = v),
                        initialLetterOverride: _containerLogoInitialLetter,
                        onInitialLetterOverrideChanged: (v) =>
                            setState(() => _containerLogoInitialLetter = v),
                      ),
                      const SizedBox(height: 20),

                      // ── Invoice number ───────────────────────────────
                      _sectionHeader('Invoice Details',
                          icon: Icons.receipt_long_rounded),
                      CreateInvoiceField(
                        ctrl: _invoiceNumberCtrl,
                        label: 'Invoice Number',
                        hint: 'e.g. INV-001',
                        icon: Icons.tag_rounded,
                        max: _invoiceNumberMax,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_invoiceNumberCtrl.text.length, _invoiceNumberMax),
                      const SizedBox(height: 12),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: CreateInvoiceDateField(
                              label: 'Invoice Date',
                              value: dateFormat.format(_invoiceDate),
                              onTap: () => _pickDate(false),
                              accent: _accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CreateInvoiceDateField(
                              label: 'Due Date',
                              value: dateFormat.format(_dueDate),
                              onTap: () => _pickDate(true),
                              accent: _accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Currency ─────────────────────────────────────
                      // DISPLAY FORMAT REORDER PASS: the Code/Symbol/Both
                      // selector now sits above the Currency Code field
                      // instead of below it — purely a visual reorder,
                      // same function as before (it still reads live
                      // from _currencyCodeCtrl/_currencySymbolCtrl and
                      // still gates the Currency Symbol field's
                      // visibility further down).
                      _sectionHeader('Currency',
                          icon: Icons.attach_money_rounded),
                      CreateInvoiceCurrencyDisplayModeSelector(
                        value: _currencyDisplayMode,
                        accent: _accent,
                        onChanged: (mode) =>
                            setState(() => _currencyDisplayMode = mode),
                        previewCode: _currencyCodeCtrl.text.trim().isEmpty
                            ? 'USD'
                            : _currencyCodeCtrl.text.trim().toUpperCase(),
                        previewSymbol: _currencySymbolCtrl.text.trim(),
                      ),
                      const SizedBox(height: 12),

                      CreateInvoiceField(
                        ctrl: _currencyCodeCtrl,
                        label: 'Currency Code',
                        hint: 'e.g. USD',
                        icon: Icons.attach_money_rounded,
                        max: 6,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_currencyCodeCtrl.text.length, 6),
                      if (_currencyDisplayMode != 'code') ...[
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _currencySymbolCtrl,
                          label: 'Currency Symbol',
                          hint: 'e.g. \$, €, kr',
                          icon: Icons.currency_exchange_rounded,
                          max: 6,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_currencySymbolCtrl.text.length, 6),
                      ],
                      const SizedBox(height: 20),

                      // ── Customer (if none selected in step 1) ────────
                      if (widget.selectedCustomer == null) ...[
                        _sectionHeader('Customer Details',
                            icon: Icons.person_rounded),
                        // FIELD LENGTH TIGHTENING PASS: 100 -> 40, matching
                        // step_customers.dart's saved-customer library cap
                        // — this field feeds the exact same "Billed To"
                        // block on the document.
                        CreateInvoiceField(
                          ctrl: _custNameCtrl,
                          label: 'Customer Name',
                          hint: 'e.g. Acme Corp',
                          icon: Icons.person_rounded,
                          max: 40,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        // FIELD LENGTH TIGHTENING PASS: 100 -> 60.
                        CreateInvoiceField(
                          ctrl: _custEmailCtrl,
                          label: 'Customer Email',
                          hint: 'e.g. billing@acme.com',
                          icon: Icons.email_rounded,
                          max: 60,
                          keyboard: TextInputType.emailAddress,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _custPhoneCtrl,
                          label: 'Customer Phone',
                          hint: 'e.g. +1 555 000 1234',
                          icon: Icons.phone_rounded,
                          max: 20,
                          keyboard: TextInputType.phone,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 20),

                        // STRUCTURED ADDRESS PASS: six fields instead of
                        // one flat "Customer Address" field, matching
                        // AddressInfo (line1/line2/city/state/country/
                        // postalCode) and step_customers.dart's own
                        // Address section field set/lengths exactly.
                        _sectionHeader('Customer Address',
                            icon: Icons.location_on_rounded),
                        CreateInvoiceField(
                          ctrl: _custAddrLine1Ctrl,
                          label: 'Address Line 1 (Optional)',
                          hint: 'e.g. 123 Queen Street',
                          icon: Icons.location_on_rounded,
                          max: 60,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custAddrLine1Ctrl.text.length, 60),
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _custAddrLine2Ctrl,
                          label: 'Address Line 2 (Optional)',
                          hint: 'e.g. Apt 4B, Level 2',
                          icon: Icons.location_on_rounded,
                          max: 60,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custAddrLine2Ctrl.text.length, 60),
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _custCityCtrl,
                          label: 'City (Optional)',
                          hint: 'e.g. Auckland',
                          icon: Icons.location_city_rounded,
                          max: 40,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custCityCtrl.text.length, 40),
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _custStateCtrl,
                          label: 'State / Province (Optional)',
                          hint: 'e.g. Auckland',
                          icon: Icons.map_rounded,
                          max: 40,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custStateCtrl.text.length, 40),
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _custCountryCtrl,
                          label: 'Country (Optional)',
                          hint: 'e.g. New Zealand',
                          icon: Icons.public_rounded,
                          max: 40,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custCountryCtrl.text.length, 40),
                        const SizedBox(height: 12),
                        CreateInvoiceField(
                          ctrl: _custZipCtrl,
                          label: 'ZIP / Postal Code (Optional)',
                          hint: 'e.g. 1010',
                          icon: Icons.markunread_mailbox_rounded,
                          max: 16,
                          accent: _accent,
                          onChanged: (_) => setState(() {}),
                        ),
                        _counter(_custZipCtrl.text.length, 16),
                        const SizedBox(height: 20),
                      ],

                      // ── Line items ───────────────────────────────────
                      _sectionHeader('Line Items', icon: Icons.list_alt_rounded),

                      // The single draft entry card for typing a brand
                      // new item — saving it adds it to the invoice AND
                      // the Saved Items library below in one action.
                      CreateInvoiceItemCard(
                        item: _draftItem,
                        descCtrl: _draftDescCtrl,
                        qtyCtrl: _draftQtyCtrl,
                        priceCtrl: _draftPriceCtrl,
                        unitCustomLabelCtrl: _draftUnitCustomLabelCtrl,
                        taxRateCtrl: _draftTaxRateCtrl,
                        discountRateCtrl: _draftDiscountRateCtrl,
                        taxNameCtrl: _draftTaxNameCtrl,
                        discountNameCtrl: _draftDiscountNameCtrl,
                        currencySymbol: _currencyPrefix,
                        accent: _accent,
                        onChanged: () => setState(() {}),
                        onSaveItem: _saveDraftItem,
                      ),
                      const SizedBox(height: 20),

                      // ── Saved Items — the "container section". The
                      // panel below now supplies its own section header
                      // (title + count + collapse chevron) — see
                      // create_invoice_saved_line_items_widgets.dart's
                      // own pass note — so there is deliberately no
                      // _sectionHeader('Saved Items', ...) call here any
                      // more; it would just duplicate what the panel
                      // already renders.
                      _savedLibraryLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : CreateInvoiceSavedLineItemsPanel(
                              library: _savedLineItems,
                              includedIds: _includedSavedIds,
                              currencySymbol: _currencyPrefix,
                              accent: _accent,
                              onToggleInclude: _toggleSavedLineItem,
                              onEdit: _editSavedLineItem,
                              onDelete: _deleteSavedLineItem,
                            ),
                      const SizedBox(height: 12),

                      // ── Tax / Discount (whole-invoice / global) ──────
                      // WHOLE-INVOICE TAX/DISCOUNT TOGGLE PASS: each
                      // side now has its own on/off switch above the
                      // Name/% fields — turning one off hides those
                      // fields entirely and stops that rate applying to
                      // the totals below (see _taxAmount/_discountAmount
                      // getters above).
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('Tax',
                                          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.8))),
                                    ),
                                    Switch(
                                      value: _taxEnabled,
                                      onChanged: (v) {
                                        setState(() => _taxEnabled = v);
                                        _persistTaxEnabledDefault(v);
                                      },
                                      activeTrackColor: _accent,
                                    ),
                                  ],
                                ),
                                if (_taxEnabled) ...[
                                  CreateInvoiceField(
                                    ctrl: _taxNameCtrl,
                                    label: 'Tax Name (Optional)',
                                    hint: 'e.g. GST',
                                    icon: Icons.label_outline_rounded,
                                    max: 8,
                                    accent: _accent,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  _counter(_taxNameCtrl.text.length, 8),
                                  const SizedBox(height: 12),
                                  CreateInvoiceField(
                                    ctrl: _taxCtrl,
                                    label: 'Tax % (whole invoice)',
                                    hint: 'e.g. 10',
                                    icon: Icons.percent_rounded,
                                    max: 5,
                                    keyboard: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    extraFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    accent: _accent,
                                    onChanged: (v) => setState(() {
                                      final parsed = double.tryParse(v) ?? 0.0;
                                      _taxRate = parsed.clamp(0.0, 100.0);
                                    }),
                                  ),
                                  _rangeWarning(
                                      double.tryParse(_taxCtrl.text) ?? 0.0,
                                      _taxRate),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('Discount',
                                          style: TextStyle(fontSize: 12.5, color: colorScheme.onSurface.withValues(alpha: 0.8))),
                                    ),
                                    Switch(
                                      value: _discountEnabled,
                                      onChanged: (v) {
                                        setState(() => _discountEnabled = v);
                                        _persistDiscountEnabledDefault(v);
                                      },
                                      activeTrackColor: _accent,
                                    ),
                                  ],
                                ),
                                if (_discountEnabled) ...[
                                  CreateInvoiceField(
                                    ctrl: _discountNameCtrl,
                                    label: 'Discount Name (Optional)',
                                    hint: 'e.g. Trade',
                                    icon: Icons.label_outline_rounded,
                                    max: 8,
                                    accent: _accent,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  _counter(_discountNameCtrl.text.length, 8),
                                  const SizedBox(height: 12),
                                  CreateInvoiceField(
                                    ctrl: _discountCtrl,
                                    label: 'Discount % (whole invoice)',
                                    hint: 'e.g. 5',
                                    icon: Icons.local_offer_rounded,
                                    max: 5,
                                    keyboard: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    extraFormatters: [
                                      FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    accent: _accent,
                                    onChanged: (v) => setState(() {
                                      final parsed = double.tryParse(v) ?? 0.0;
                                      _discountRate = parsed.clamp(0.0, 100.0);
                                    }),
                                  ),
                                  _rangeWarning(
                                      double.tryParse(_discountCtrl.text) ?? 0.0,
                                      _discountRate),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Totals card ──────────────────────────────────
                      CreateInvoiceTotalsCard(
                        subtotal: _subtotal,
                        taxAmount: _taxAmount,
                        discountAmount: _discountAmount,
                        itemTaxByName: _itemTaxExtraByName,
                        itemDiscountByName: _itemDiscountExtraByName,
                        total: _total,
                        taxRate: _taxRate,
                        discountRate: _discountRate,
                        taxName: _taxNameCtrl.text.trim(),
                        discountName: _discountNameCtrl.text.trim(),
                        taxEnabled: _taxEnabled,
                        discountEnabled: _discountEnabled,
                        currencySymbol: _currencyPrefix,
                        isDark: isDark,
                        accent: _accent,
                      ),
                      const SizedBox(height: 20),

                      // ── Due Date & Amount Due ────────────────────────
                      // AMOUNT DUE FORMAL REDESIGN PASS: Due Date now
                      // sits on its own full-width row (previous
                      // behavior/state unchanged — still the exact same
                      // _dueDate/_pickDate collected under Invoice
                      // Details above). Amount Due is broken out into
                      // its own formal _AmountDueField card below it —
                      // see that widget's header comment for what
                      // changed and why.
                      _sectionHeader('Due Date & Amount Due',
                          icon: Icons.event_available_rounded),
                      CreateInvoiceDateField(
                        label: 'Due Date',
                        value: dateFormat.format(_dueDate),
                        onTap: () => _pickDate(true),
                        accent: _accent,
                      ),
                      const SizedBox(height: 16),
                      _AmountDueField(
                        ctrl: _amountDueCtrl,
                        currencyPrefix: _currencyPrefix,
                        total: _total,
                        isManual: _amountDueManuallySet,
                        accent: _accent,
                        isDark: isDark,
                        onReset: _resetAmountDueToAuto,
                      ),
                      const SizedBox(height: 20),

                      // ── Notes ────────────────────────────────────────
                      _sectionHeader('Additional Info',
                          icon: Icons.notes_rounded),
                      // FIELD LENGTH TIGHTENING PASS: 500 -> 250 — Notes
                      // renders in a fixed-width panel beside the totals
                      // column on the printed document with no scroll or
                      // truncation of its own; 500 characters could push
                      // that panel taller than a page, causing overflow.
                      CreateInvoiceField(
                        ctrl: _notesCtrl,
                        label: 'Notes / Payment Terms',
                        hint: 'e.g. Payment due within 30 days...',
                        icon: Icons.note_rounded,
                        max: 250,
                        maxLines: 3,
                        accent: _accent,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(_notesCtrl.text.length, 250),
                      const SizedBox(height: 28),

                      // ── Save button ──────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: Text(
                            _isEditing ? 'Save Changes' : 'Save Invoice',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// _AmountDueField — AMOUNT DUE FORMAL REDESIGN PASS
//
// A dedicated, full-width card for Amount Due, replacing its previous
// life as one half of a plain two-column Row next to Due Date. Styled to
// read as a formal financial-document field rather than a generic text
// input:
//   - A label row with "Amount Due" on the left and, once the value has
//     been manually overridden away from the computed total, a small
//     "Custom" chip on the right plus a "Reset to total" text button.
//   - A helper line under the label reading "Defaults to Total —
//     {currency}{total}" while still in auto mode, so it's clear this
//     field tracks the invoice total unless touched.
//   - The input itself: a bordered box with the currency prefix shown as
//     a fixed leading label (not part of the editable text), and the
//     typed amount right-aligned in a bold, larger font — echoing how
//     Total is styled in CreateInvoiceTotalsCard, so Amount Due reads as
//     an amount of the same weight as the figures above it, not a lesser
//     text field.
//
// Purely presentational — ctrl/onReset are the same _amountDueCtrl/
// _resetAmountDueToAuto() the sheet already had; this widget doesn't
// introduce any new state of its own.
// =============================================================================

class _AmountDueField extends StatefulWidget {
  final TextEditingController ctrl;
  final String currencyPrefix;
  final double total;
  final bool isManual;
  final Color accent;
  final bool isDark;
  final VoidCallback onReset;

  const _AmountDueField({
    required this.ctrl,
    required this.currencyPrefix,
    required this.total,
    required this.isManual,
    required this.accent,
    required this.isDark,
    required this.onReset,
  });

  @override
  State<_AmountDueField> createState() => _AmountDueFieldState();
}

// AUTO-SCROLL-ON-FOCUS PASS: this field's TextField isn't routed
// through CreateInvoiceField (it's a bespoke card, see the class header
// comment above), so it owns its own FocusNode with the same
// retry-based Scrollable.ensureVisible() behaviour applied everywhere
// else on this sheet.
class _AmountDueFieldState extends State<_AmountDueField> {
  final FocusNode _focusNode = FocusNode();
  static const _retryDelaysMs = [80, 200, 350, 500];

  // Field renamed to widget.* below; keep short local aliases for the
  // parts of build() that referenced the old constructor params
  // directly, to minimize the diff against the original widget body.
  TextEditingController get ctrl => widget.ctrl;
  String get currencyPrefix => widget.currencyPrefix;
  double get total => widget.total;
  bool get isManual => widget.isManual;
  Color get accent => widget.accent;
  bool get isDark => widget.isDark;
  VoidCallback get onReset => widget.onReset;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) return;
    for (final delayMs in _retryDelaysMs) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted || !_focusNode.hasFocus) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.2,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Label row: "Amount Due" + Custom chip + Reset action ────
          Row(
            children: [
              Icon(Icons.payments_rounded, size: 16, color: accent),
              const SizedBox(width: 6),
              Text(
                'Amount Due',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
              if (isManual) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Custom',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (isManual)
                GestureDetector(
                  onTap: onReset,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: accent),
                      const SizedBox(width: 3),
                      Text(
                        'Reset to total',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // ── Helper line — only shown while still auto-tracking ──────
          if (!isManual)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 22),
              child: Text(
                'Defaults to Total — $currencyPrefix${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            )
          else
            const SizedBox(height: 10),

          // ── The amount input itself ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16233A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                if (currencyPrefix.isNotEmpty) ...[
                  Text(
                    currencyPrefix.trim(),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    focusNode: _focusNode,
                    textAlign: TextAlign.right,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(15),
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: accent,
                      letterSpacing: -0.2,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
