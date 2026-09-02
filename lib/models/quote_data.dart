// quote_data.dart
// lib/models/quote_data.dart
//
// QUOTE DRAFT LIBRARY PASS (this update): added SavedQuoteDraft — a
// named, editable quote-in-progress, saved from the Create Quote step's
// new library screen (create_quote_section/step_create_quote.dart) and
// reopened via CreateQuoteBottomSheet
// (create_quote_section/create_quote_bottom_sheet.dart) to keep editing
// it. Mirrors SavedInvoiceDraft (invoice_data.dart) exactly — see that
// file's INVOICE DRAFT LIBRARY PASS note for the full rationale. Also
// added SavedQuoteLineItemSet — a Quote-only mirror of
// SavedLineItemSet (invoice_data.dart), kept as a separate class/library
// (own SharedPreferences key) so Quote's saved item-set bundles never
// mix with Invoice's, backing the new
// create_quote_section/quote_saved_items_widgets.dart panel.
//
// FONT SIZE PASS (earlier): added fontSize (double, default 12.0) —
// Quote had a fontFamily field but no numeric size field at all, unlike
// InvoiceData's own font size support (see step_customise.dart's
// _SizeSection / InvoiceProvider.fontSize). Added so Quote's Customise
// step can finally show a Text Size slider matching Invoice's, via the
// new quote_step_customise.dart. Default (12.0) preserves existing
// render behaviour for every persisted quote, no migration needed.
//
// TEMPLATE/CLIENT RESTORE-ON-EDIT PASS (earlier): added
// sourceTemplateId and sourceClientId — the id of whichever QuoteTemplate
// (quote_template_library.dart) / QuoteClient (quote_client_library.dart)
// was selected when this quote was last saved. Previously QuoteData only
// stored the raw business/client strings COPIED FROM a template/client at
// save time, with no record of which saved entry they came from — so
// re-opening a saved quote to edit it always showed "Select or add a
// template/client" even though one had already been chosen, forcing a
// reselect every time. quote_editor_screen.dart now reads these two ids
// in initState and passes them to QuoteTemplateLibrarySection /
// QuoteClientLibrarySection as initialSelectedId so the right card is
// highlighted and the status strip shows "Using X" on open, without
// re-cascading that template's CURRENT business info/logo/fields over
// the quote's own already-loaded (and possibly since-diverged) values —
// see _restoreTemplate()/_restoreClient() there, kept deliberately
// separate from _applyTemplate()/_applyClient()'s full cascade. Both
// fields are nullable and default to null, so every existing persisted
// quote loads exactly as before (falls back to the pre-existing "must
// reselect" behaviour — nothing regresses).
//
// TEMPLATE FIELD VISIBILITY PASS (earlier): added enabledFields — a
// Map<String, bool> mirroring InvoiceData's own field (see that file's
// TEMPLATE FIELD VISIBILITY PASS for the full rationale). Quote had no
// equivalent of InvoiceTemplate's Invoice Fields/Customer Fields toggle
// sheet at all — this adds the same capability via a new "Template" step
// in QuoteEditorScreen (quote_editor_screen.dart), synced through
// QuoteProvider.updateEnabledFields(), read by quoteToAdapter() in
// doc_template_adapter.dart, and gated in executive_template.dart (which
// already reads DocTemplateAdapter.enabledFields generically — no changes
// needed there). Defaults to defaultQuoteEnabledFields() (everything
// shown), so every existing persisted quote renders exactly as before.
//
// LOGO FALLBACK MARK PASS (earlier): added businessLogoShowInitial
// (bool, default true) and businessLogoInitialLetter (String, default
// '') — mirrors InvoiceData's own new fields. See invoice_data.dart's
// doc comment for the full rationale. Defaults preserve existing render
// behaviour for every persisted quote, no migration needed.
//
// TEMPLATE + LOGO SIZER PASS (earlier): added layoutTemplateId (which
// visual design — Executive/Nordic/Vibrant/etc, see the quote
// preview_registry.dart — this quote actually renders with) and
// businessLogoOffsetDx/Dy/Scale/Shape (mirrors InvoiceData's own new
// fields, driven by the same SharedLogoPicker widget). Previously the
// quote always rendered as Executive regardless of what was picked in
// QuoteTemplateChooserScreen, and had no logo reposition/zoom/shape data
// at all. All new fields fall back to sensible defaults when missing from
// persisted JSON (layoutTemplateId 1 = Executive, zero offset, scale 1.0,
// 'roundedSquare' shape), so existing persisted quotes load correctly
// with no migration step.
//
// CURRENCY DISPLAY PASS (earlier): added currencySymbol and
// currencyDisplayMode, mirroring InvoiceData's own fields — see that
// file's doc comment for the full rationale (free text, no hardcoded
// currency list, defaults preserve existing render behaviour).

import 'invoice_data.dart' show LineItem;

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum QuoteStatus { draft, sent, accepted, declined, expired }

enum QuoteColor { blue, green, purple, orange, red, teal, black, indigo }

// ─────────────────────────────────────────────────────────────────────────────
// Default field-visibility map
// ─────────────────────────────────────────────────────────────────────────────
//
// TEMPLATE FIELD VISIBILITY PASS: same key set as
// defaultInvoiceEnabledFields() (invoice_data.dart) minus the
// invoice-only business/sender/barcode keys that have no quote toggle UI
// yet — invoiceNumber/date/dueDate/tax/discount/notes/thankYouMessage
// (document fields) and customerName/Email/Phone/Address (client
// fields). These are exactly the keys executive_template.dart's
// _executiveFullHeader / _ExecutiveMetaRow already gate on generically
// via docFieldOn(), so a quote's Template step toggles take effect with
// no further changes to the rendering path. Used whenever QuoteData is
// constructed without an explicit enabledFields map.
Map<String, bool> defaultQuoteEnabledFields() => {
      'invoiceNumber': true, 'date': true, 'dueDate': true,
      'tax': true, 'discount': true,
      'notes': true, 'thankYouMessage': true,
      'customerName': true, 'customerEmail': true, 'customerPhone': true,
      'customerAddress': true,
      'businessLogo': true,
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

  // Logo reposition/zoom/shape — mirrors InvoiceData's fields, driven by
  // the same SharedLogoPicker widget. Only meaningful when
  // businessLogoPath is set.
  double businessLogoOffsetDx;
  double businessLogoOffsetDy;
  double businessLogoScale;
  String businessLogoShape; // storage name from LogoShape.storageName
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

  String quoteNumber;
  String issueDate;
  String expiryDate;
  String notes;
  String currency;

  // Free-text currency symbol + display mode — see InvoiceData for the
  // full rationale. Not gated by any hardcoded currency list.
  String currencySymbol;
  String currencyDisplayMode; // 'code' | 'symbol' | 'both'

  List<LineItem> lineItems;

  double      taxRate;
  double      discountRate;
  QuoteStatus quoteStatus;
  String      fontFamily;

  // FONT SIZE PASS: numeric text size (points), mirrors
  // InvoiceProvider.fontSize / InvoiceData's equivalent. Drives the new
  // Text Size slider on quote_step_customise.dart via
  // QuoteProvider.updateFontSize().
  double      fontSize;

  QuoteColor  colorScheme;

  // Which visual design (see the quote preview_registry.dart's
  // kQuoteTemplates / buildQuotePreview) this quote renders with —
  // 1 = Executive, 2 = Nordic, etc.
  int layoutTemplateId;

  // TEMPLATE FIELD VISIBILITY PASS: which template-defined fields
  // actually render on this quote — see defaultQuoteEnabledFields()
  // above for the key set. Populated from the new Template step in
  // QuoteEditorScreen; read by quoteToAdapter() (doc_template_adapter.
  // dart) via `d.enabledFields`, then by executive_template.dart's
  // docFieldOn() helper, which defaults a missing key to true (shown) —
  // so a persisted quote saved before this field existed still renders
  // exactly as before.
  Map<String, bool> enabledFields;

  // TEMPLATE/CLIENT RESTORE-ON-EDIT PASS: which saved QuoteTemplate /
  // QuoteClient this quote's business/client info was last populated
  // from — see the file-level doc comment above. Null means "no saved
  // template/client is associated", whether that's because this quote
  // predates this pass, no selection was ever made, or a prior selection
  // was explicitly cleared.
  String? sourceTemplateId;
  String? sourceClientId;

  // Same escape hatch as InvoiceData.excludeFromReports. See that file's
  // doc comment for the gating rule.
  bool excludeFromReports;

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
    this.quoteStatus      = QuoteStatus.draft,
    this.fontFamily       = 'Roboto',
    this.fontSize         = 12.0,
    this.colorScheme      = QuoteColor.purple,
    this.layoutTemplateId = 1,
    Map<String, bool>? enabledFields,
    this.sourceTemplateId,
    this.sourceClientId,
    this.excludeFromReports = false,
  }) : lineItems = lineItems ?? [],
       enabledFields = enabledFields ?? defaultQuoteEnabledFields();

  // ── Computed totals ────────────────────────────────────────────────────────

  double get subtotal       => lineItems.fold(0.0, (sum, i) => sum + i.total);
  double get discountAmount => subtotal * (discountRate / 100);
  double get taxAmount      => (subtotal - discountAmount) * (taxRate / 100);
  double get grandTotal     => subtotal - discountAmount + taxAmount;

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
        'quoteStatus':      quoteStatus.name,
        'fontFamily':       fontFamily,
        'fontSize':         fontSize,
        'colorScheme':      colorScheme.name,
        'layoutTemplateId': layoutTemplateId,
        'enabledFields':    enabledFields,
        'sourceTemplateId': sourceTemplateId,
        'sourceClientId':   sourceClientId,
        'excludeFromReports': excludeFromReports,
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
      );

  // ── copyWith ───────────────────────────────────────────────────────────────
  //
  // clearBusinessLogo: explicit clear flag, same reasoning as
  // SavedInvoice's clearFolderName — a plain `x ?? this.x` copyWith can
  // never express "set this field to null" once it already has a value.
  // clearSourceTemplateId/clearSourceClientId follow the identical
  // pattern, for the identical reason: a plain null passed in for either
  // id must mean "clear it" when a template/client was deselected, not
  // "leave whatever was already there" — see quote_provider.dart's
  // updateBusinessInfo/updateClientInfo for how these flags get set.
  // enabledFields is copied into a fresh Map instance either way, so
  // callers never accidentally share a mutable Map reference between two
  // QuoteData instances.

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
        quoteStatus:      quoteStatus      ?? this.quoteStatus,
        fontFamily:       fontFamily       ?? this.fontFamily,
        fontSize:         fontSize         ?? this.fontSize,
        colorScheme:      colorScheme      ?? this.colorScheme,
        layoutTemplateId: layoutTemplateId ?? this.layoutTemplateId,
        enabledFields: Map<String, bool>.from(enabledFields ?? this.enabledFields),
        sourceTemplateId: clearSourceTemplateId ? null : (sourceTemplateId ?? this.sourceTemplateId),
        sourceClientId:   clearSourceClientId   ? null : (sourceClientId   ?? this.sourceClientId),
        excludeFromReports: excludeFromReports ?? this.excludeFromReports,
      );

  QuoteData deepCopy() => copyWith(
        lineItems: lineItems.map((i) => i.copyWith()).toList(),
        enabledFields: Map<String, bool>.from(enabledFields),
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

  // folderName/clearFolderName — same pattern as SavedInvoice.copyWith.
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
// SavedQuoteDraft — a named, editable quote-in-progress. Mirrors
// SavedInvoiceDraft (invoice_data.dart) exactly — see that file's
// INVOICE DRAFT LIBRARY PASS note for the full rationale. Stores a
// complete QuoteData snapshot of everything editable on the Create Quote
// step (customer override, dates, currency, line items, tax/discount,
// notes) plus a user-facing `name` for the library card, independent of
// any customer/quote-number text so a draft can be labelled before
// either is filled in.
// ─────────────────────────────────────────────────────────────────────────────

class SavedQuoteDraft {
  String id;
  String name;
  QuoteData data;
  DateTime createdAt;
  DateTime lastEditedAt;

  SavedQuoteDraft({
    required this.id,
    required this.name,
    required this.data,
    required this.createdAt,
    required this.lastEditedAt,
  });

  /// What the library card shows as its title — the explicit label if one
  /// was typed, else the client name, else the quote number, else a
  /// generic fallback. Never blank.
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
      };

  factory SavedQuoteDraft.fromJson(Map<String, dynamic> j) => SavedQuoteDraft(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        data: QuoteData.fromJson(j['data'] as Map<String, dynamic>? ?? {}),
        createdAt: DateTime.parse(j['createdAt'] as String),
        lastEditedAt: DateTime.parse(j['lastEditedAt'] as String),
      );

  SavedQuoteDraft copyWith({
    String? name,
    QuoteData? data,
    DateTime? lastEditedAt,
  }) =>
      SavedQuoteDraft(
        id: id,
        name: name ?? this.name,
        data: data ?? this.data.deepCopy(),
        createdAt: createdAt,
        lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SavedQuoteLineItemSet — a named, reusable bundle of line items for the
// Quote flow. Mirrors SavedLineItemSet (invoice_data.dart) exactly, but
// kept as a SEPARATE library (own SharedPreferences key, own class) so
// Quote's saved item sets never mix with Invoice's — see
// quote_saved_items_widgets.dart (QuoteSavedItemSets) for the UI this
// backs.
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
  double get total => items.fold(0.0, (sum, i) => sum + i.total);

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
