// lib/screens/invoice_create_section/step_create_invoice/step_create_invoice.dart
//
// SCAFFOLD PARITY FIX (this update): the previous "TOAST PARITY FIX"
// pass (removing `behavior: SnackBarBehavior.floating` from _continue()'s
// validation SnackBar) did NOT fix the overlap — because the real cause
// was never the `behavior` value. It's a Scaffold structure problem:
//
// A fixed-behavior SnackBar docks directly above whatever Scaffold's
// `bottomNavigationBar` is — the nearest Scaffold ANCESTOR of the
// BuildContext used to call ScaffoldMessenger.of(context). This widget
// has never had its own Scaffold; its StepNavBar was just the last
// child of a plain Column, sitting inside EditorScreen's body
// (editor_screen.dart), and EditorScreen's own Scaffold has no
// `bottomNavigationBar` set at all. So `ScaffoldMessenger.of(context)`
// from _continue() found EditorScreen's Scaffold, which has nothing to
// dock above — the SnackBar just sat at the literal bottom of the
// screen, on top of wherever this widget's own StepNavBar happened to
// be rendered. Quote's equivalent toast doesn't have this problem
// because QuoteEditorScreen registers its nav bar as its Scaffold's
// actual `bottomNavigationBar` (see quote_editor_screen.dart) — so a
// SnackBar shown there automatically docks above it instead of over it.
//
// Fix: this widget now wraps itself in its own `ScaffoldMessenger` +
// `Scaffold`, with its StepNavBar registered as that Scaffold's real
// `bottomNavigationBar` instead of being a plain trailing Column child.
// SnackBars are shown via a local `GlobalKey<ScaffoldMessengerState>`
// (`_messengerKey`) rather than `ScaffoldMessenger.of(context)`, so they
// resolve to THIS widget's own ScaffoldMessenger — which now has a real
// bottomNavigationBar to dock above — regardless of what the parent
// screen (EditorScreen) does or doesn't provide. `backgroundColor:
// Colors.transparent` on the nested Scaffold keeps this purely a
// layout/messenger change with no visual difference otherwise.
//
// SAVED-ITEMS FILTERS PASS (earlier): adds a search field +
// Recent/A-Z/Z-A sort selector to the "Saved Invoices" list, matching
// the same treatment already applied to the Templates step
// (step_templates.dart) — new _DraftSearchField / _DraftSortSelector
// widgets at the bottom of this file, matching relevance against the
// draft's display name, invoice number, and client name. The library's
// previous hardcoded `_library.length - 1 - displayIdx` reversal is
// gone — the SliverList now iterates `_visibleIndices`, which
// reproduces that exact same newest-first order under the default
// "Recent" sort mode, so nothing changes visually until a person
// actually searches or picks a different sort.
//
// PAYMENT TERMS REMOVAL PASS (earlier): the sync of BusinessInfo's
// paymentTerms onto InvoiceData in _syncSelectedToProvider() has been
// removed entirely — the field no longer exists on either BusinessInfo
// (client_info.dart) or InvoiceData (invoice_data.dart), so this line
// would no longer compile. Matches the corresponding removal in
// step_templates.dart (the controller + form field),
// step_templates_terms.dart (the section), step_customise.dart (the
// toggle row), and the two render sites
// (executive_invoice_payment_terms_signature.dart,
// invoice_pdf_extra_sections.dart).
//
// STRUCTURED ADDRESS SYNC PASS (earlier): _syncSelectedToProvider()
// now carries businessAddressInfo through — same template-first-else-
// current pattern already used for businessName/Email/Phone/Address
// just above it. The resolved AddressInfo's singleLine also updates the
// legacy flat businessAddress string (falling back to
// businessInfo?.address / current.businessAddress when the structured
// value is still empty, e.g. a template saved before the structured
// address pass existed), so anything still reading the flat string
// keeps working. clientAddressInfo is per-invoice — like clientName,
// it's read straight off the selected draft's own data (`d`), which
// create_invoice_bottom_sheet.dart's _save() is now responsible for
// populating (from the selected Customer's addressInfo, or from the
// sheet's own six manual address fields — see that file's own pass
// note).
//
// SIGNATURE SIZER SYNC PASS (earlier): added
// `signatureFontSize: current.signatureFontSize` to
// _syncSelectedToProvider()'s InvoiceData constructor call — same
// preserve-from-current pattern already used for
// businessLogoDisplaySize just above it, since signatureFontSize is
// likewise a per-invoice Customise-step setting (a slider on the
// Signature toggle row), not something a template authors. Without
// this it would silently reset to 22.0 every time this sync runs.
//
// AMOUNT DUE SYNC FIX (earlier): _syncSelectedToProvider() was
// missing `amountDueOverride: d.amountDueOverride` from its InvoiceData
// constructor call — same bug class the ENABLED FIELDS + LOGO DISPLAY
// SYNC FIX and the poNumber BUG FIX below it already document: an
// optional constructor param silently omitted here means "reset to the
// constructor default" (null — auto), so a manually-set Amount Due
// typed on the Create Invoice step's new "Due Date & Amount Due"
// section (create_invoice_bottom_sheet.dart) would have survived onto
// the SavedInvoiceDraft just fine, then been silently dropped the
// moment "Continue to Customise" was tapped. Added alongside poNumber
// as a per-invoice field read from the draft's own data (`d`) — NOT
// template-sourced, since Amount Due is specific to this invoice, not
// something a template authors.
//
// ENABLED FIELDS + LOGO DISPLAY SYNC FIX (earlier):
// _syncSelectedToProvider() was rebuilding InvoiceData from scratch on
// every "Continue to Customise" tap but never passing `enabledFields`
// into that constructor call — since it's an optional parameter, leaving
// it out silently fell back to defaultInvoiceEnabledFields() (every key
// true), wiping out whatever template toggles or previously-set Customise
// toggles were already in effect, every single time this ran. Now reads
// `widget.selectedTemplate?.enabledFields ?? current.enabledFields`,
// mirroring the exact template-first-else-current pattern already used
// for businessName/Email/Phone/Address a few lines above it. Same bug,
// same fix, for businessLogoDisplaySize/businessLogoShowInitial/
// businessLogoInitialLetter — all three were also missing from that
// constructor call and were silently resetting to their constructor
// defaults (40.0 / true / '') on every sync.
//
// PAYMENT INFO / TERMS & SIGNATURE SYNC PASS (earlier): _syncSelectedToProvider()
// now copies BusinessInfo's template-authored bankName/accountName/
// accountNumber/otherPaymentDetails/termsAndConditions/
// signatureMode/signatureName/signatureImagePath (see client_info.dart's
// PAYMENT INFO / TERMS & SIGNATURE PASS) onto the InvoiceData built here —
// same "template value if a template is selected, else keep whatever's
// already on the provider" pattern already used for businessName/Email/
// Phone/Address above. This is the sync step step_templates.dart's own
// pass note has been flagging as pending — filling in Payment Info /
// Terms & Conditions / Signature on a template now actually reaches the
// invoice. poNumber is deliberately NOT included in this
// template-sourced block — it's per-invoice only (see client_info.dart's
// BusinessInfo header comment) and is instead picked up from the draft's
// own data below.
//
// BUG FIX (found while making the above change): poNumber was never
// being copied from the selected draft's InvoiceData (`d`) onto the
// synced InvoiceData at all — every other per-invoice field on `d`
// (clientName, invoiceNumber, notes, etc) was already being copied, but
// poNumber was simply missing from this constructor call, so any PO /
// Reference Number typed into an invoice draft was silently dropped the
// moment "Continue to Customise" was tapped. Added `poNumber: d.poNumber`
// alongside the other per-invoice fields.
//
// CONTAINER LOGO + MANDATORY NAME PASS (earlier): _InvoiceDraftCard's
// icon block now renders the draft's own container logo
// (SavedInvoiceDraft.logoPath, set via create_invoice_bottom_sheet.dart's
// new "Container Logo" section) exactly the way step_templates.dart's
// _TemplateCard renders BusinessInfo.logoPath — a real SharedLogoThumbnail
// when a logo is set, else the same rotated-square initial-letter
// fallback mark (respecting logoShowInitial/logoInitialLetter), else a
// plain icon as the last resort. New _DraftCardFallbackMark mirrors
// step_templates.dart's _CardFallbackMark exactly, adapted to
// SavedInvoiceDraft's flat logo fields instead of BusinessInfo's nesting.
//
// INVOICE LIBRARY RESTRUCTURE PASS (earlier): this step is now a
// library screen, mirroring step_customers.dart/step_templates.dart's
// pattern (header -> info banner -> "Create Invoice" button -> "Saved
// Invoices" section with Hide/Show -> cards -> "Continue to Customise"
// button in the StepNavBar) instead of being one long inline form.
//
// This screen owns a library of SavedInvoiceDraft (invoice_data.dart),
// persisted as a single JSON-encoded SharedPreferences list under
// 'invoice_saved_draft_list'. Tapping "Create Invoice" opens the sheet
// blank (seeded only from widget.selectedCustomer/widget.selectedTemplate);
// saving it appends a new draft to the library and selects it. Tapping
// a saved card selects it (single-select); tapping its pencil icon
// reopens the sheet pre-filled with that draft's data for further
// editing; tapping its trash icon deletes it.
//
// "Continue to Customise" requires a selected draft. When tapped,
// _syncSelectedToProvider() builds the same InvoiceData shape the old
// _syncToProvider() did, then calls widget.onNext().

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/invoice_models.dart';
import '../../../providers/invoice_provider.dart';
import '../../../widgets/shared_logo_picker.dart';
import '../invoice_edit_widgets.dart';
import 'create_invoice_form_widgets.dart';
import 'create_invoice_bottom_sheet.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _kMaxInvoiceDrafts = 100;
const _kPrefInvoiceDraftList = 'invoice_saved_draft_list';

// ---------------------------------------------------------------------------
// Persistence helpers
// ---------------------------------------------------------------------------
Future<void> _persistDrafts(List<SavedInvoiceDraft> list) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kPrefInvoiceDraftList,
    jsonEncode(list.map((d) => d.toJson()).toList()),
  );
}

Future<List<SavedInvoiceDraft>> _loadDrafts() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefInvoiceDraftList);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => SavedInvoiceDraft.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

// =============================================================================
// StepCreateInvoice
// =============================================================================

class StepCreateInvoice extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Customer? selectedCustomer;
  final InvoiceTemplate? selectedTemplate;

  /// Visual PDF layout chosen in InvoiceTemplateChooserScreen (e.g. 1 =
  /// Executive). Null/unrecognized falls back to the only built layout.
  final int? layoutTemplateId;

  const StepCreateInvoice({
    super.key,
    required this.onBack,
    required this.onNext,
    this.selectedCustomer,
    this.selectedTemplate,
    this.layoutTemplateId,
  });

  @override
  State<StepCreateInvoice> createState() => _StepCreateInvoiceState();
}

// SAVED-ITEMS FILTERS PASS: sort modes for the saved-invoice list,
// matching Templates' own sort modes.
enum _DraftSortMode { recent, nameAsc, nameDesc }

class _StepCreateInvoiceState extends State<StepCreateInvoice> {
  static const _accent = Color(0xFF2196F3); // blue accent for invoices

  bool _loading = true;
  List<SavedInvoiceDraft> _library = [];
  int? _selectedIndex;
  bool _showLibraryPanel = true;

  // SAVED-ITEMS FILTERS PASS: search + sort state.
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  _DraftSortMode _sortMode = _DraftSortMode.recent;

  // SCAFFOLD PARITY FIX: this widget's own ScaffoldMessenger, so
  // SnackBars shown from here (_continue(), the "Maximum invoices
  // reached" tap) dock above THIS widget's own StepNavBar — now
  // registered as this widget's own nested Scaffold's
  // `bottomNavigationBar` in build() below — instead of resolving to
  // EditorScreen's ambient Scaffold, which has no `bottomNavigationBar`
  // to dock above at all.
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text);
    });
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final drafts = await _loadDrafts();
    if (!mounted) return;
    setState(() {
      _library = drafts;
      _loading = false;
    });
  }

  // SAVED-ITEMS FILTERS PASS: relevance tier against display name,
  // invoice number, and client name. 3 means "doesn't match" and gets
  // filtered out.
  int _relevance(int i, String q) {
    final draft = _library[i];
    final d = draft.data;
    final name = draft.displayName.toLowerCase();
    final invoiceNumber = d.invoiceNumber.toLowerCase();
    final client = d.clientName.toLowerCase();
    if (name.startsWith(q)) return 0;
    if (name.contains(q)) return 1;
    if (invoiceNumber.contains(q) || client.contains(q)) return 2;
    return 3;
  }

  // Real _library indices for what's currently displayed — same
  // relevance-vs-sort behaviour as the Templates step's own
  // _visibleIndices. "Recent" reproduces the exact same newest-first
  // order the SliverList previously got via the hardcoded
  // `_library.length - 1 - displayIdx` reversal, so the default view is
  // unchanged.
  List<int> get _visibleIndices {
    final q = _searchQuery.trim().toLowerCase();
    var indices = List<int>.generate(_library.length, (i) => i);

    if (q.isEmpty) {
      switch (_sortMode) {
        case _DraftSortMode.nameAsc:
          indices.sort((a, b) => _library[a]
              .displayName
              .toLowerCase()
              .compareTo(_library[b].displayName.toLowerCase()));
          break;
        case _DraftSortMode.nameDesc:
          indices.sort((a, b) => _library[b]
              .displayName
              .toLowerCase()
              .compareTo(_library[a].displayName.toLowerCase()));
          break;
        case _DraftSortMode.recent:
          indices = indices.reversed.toList();
          break;
      }
      return indices;
    }

    indices = indices.where((i) => _relevance(i, q) < 3).toList();
    indices.sort((a, b) {
      final ra = _relevance(a, q);
      final rb = _relevance(b, q);
      if (ra != rb) return ra.compareTo(rb);
      return _library[a]
          .displayName
          .toLowerCase()
          .compareTo(_library[b].displayName.toLowerCase());
    });
    return indices;
  }

  void _toggleDraft(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }

  void _showCreateSheet({SavedInvoiceDraft? existing, int? editIndex}) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CreateInvoiceBottomSheet(
        selectedCustomer: widget.selectedCustomer,
        selectedTemplate: widget.selectedTemplate,
        existing: existing,
        onSaved: (draft) {
          if (editIndex != null) {
            setState(() => _library[editIndex] = draft);
          } else {
            final newIdx = _library.length;
            setState(() {
              _library.add(draft);
              _selectedIndex = newIdx;
              _showLibraryPanel = true;
            });
          }
          _persistDrafts(_library);
        },
      ),
    );
  }

  void _deleteDraft(int index) {
    setState(() {
      _library.removeAt(index);
      if (_selectedIndex == index) {
        _selectedIndex = null;
      } else if (_selectedIndex != null && _selectedIndex! > index) {
        _selectedIndex = _selectedIndex! - 1;
      }
    });
    _persistDrafts(_library);
  }

  // ---------------------------------------------------------------------------
  // Continue — requires a selected draft. Syncs it into InvoiceProvider
  // (business info/logo resolution unchanged from the pre-restructure
  // _syncToProvider()) then hands off to the parent flow via
  // widget.onNext(), exactly as before.
  //
  // SCAFFOLD PARITY FIX: shows the SnackBar via `_messengerKey` (this
  // widget's own ScaffoldMessenger) instead of `ScaffoldMessenger.of
  // (context)`. The latter resolved to EditorScreen's ambient Scaffold,
  // which has no `bottomNavigationBar` — so the SnackBar had nothing to
  // dock above and just sat at the literal bottom of the screen, on top
  // of this widget's own StepNavBar. `_messengerKey` now resolves to
  // THIS widget's own nested Scaffold (see build() below), whose
  // `bottomNavigationBar` IS the StepNavBar — so the SnackBar docks
  // above it correctly, matching Quote's/Receipt's look.
  // ---------------------------------------------------------------------------
  void _continue() {
    if (_selectedIndex == null) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Select or create an invoice to continue.'),
        ),
      );
      return;
    }
    _syncSelectedToProvider();
    widget.onNext();
  }

  void _syncSelectedToProvider() {
    final draft = _library[_selectedIndex!];
    final d = draft.data;
    final provider = context.read<InvoiceProvider>();
    final current = provider.invoiceData;
    final businessInfo = widget.selectedTemplate?.businessInfo;

    // LOGO OVERWRITE FIX (unchanged from the original step file): keep
    // whatever's already on the provider if it already has a logo set;
    // only pull from the template when the provider has none at all yet.
    final providerHasLogo = current.businessLogoPath != null &&
        current.businessLogoPath!.isNotEmpty;
    final useTemplateLogo = !providerHasLogo && businessInfo?.logoPath != null;

    final resolvedLogoPath =
        useTemplateLogo ? businessInfo!.logoPath : current.businessLogoPath;
    final resolvedLogoOffsetDx = useTemplateLogo
        ? businessInfo!.logoOffsetDx
        : current.businessLogoOffsetDx;
    final resolvedLogoOffsetDy = useTemplateLogo
        ? businessInfo!.logoOffsetDy
        : current.businessLogoOffsetDy;
    final resolvedLogoScale =
        useTemplateLogo ? businessInfo!.logoScale : current.businessLogoScale;
    final resolvedLogoShape =
        useTemplateLogo ? businessInfo!.logoShape : current.businessLogoShape;

    // STRUCTURED ADDRESS SYNC PASS: template value if a template is
    // selected, else keep whatever's already on the provider — same
    // pattern as businessName/Email/Phone/Address above. The legacy flat
    // businessAddress string is derived from whichever AddressInfo wins
    // here (its singleLine), falling back to the template's/provider's
    // own flat string when the structured value is still empty (a
    // template saved before AddressInfo existed on BusinessInfo).
    final resolvedBusinessAddressInfo =
        businessInfo?.addressInfo ?? current.businessAddressInfo;
    final resolvedBusinessAddress = resolvedBusinessAddressInfo.isNotEmpty
        ? resolvedBusinessAddressInfo.singleLine
        : (businessInfo?.address ?? current.businessAddress);

    final data = InvoiceData(
      businessName: businessInfo?.name ?? current.businessName,
      businessEmail: businessInfo?.email ?? current.businessEmail,
      businessPhone: businessInfo?.phone ?? current.businessPhone,
      businessAddress: resolvedBusinessAddress,
      businessAddressInfo: resolvedBusinessAddressInfo,
      businessLogoPath: resolvedLogoPath,
      businessLogoOffsetDx: resolvedLogoOffsetDx,
      businessLogoOffsetDy: resolvedLogoOffsetDy,
      businessLogoScale: resolvedLogoScale,
      businessLogoShape: resolvedLogoShape,

      // ENABLED FIELDS + LOGO DISPLAY SYNC FIX: these three (display
      // size, show-initial-fallback, initial-letter override) and
      // enabledFields below were all missing from this constructor call
      // entirely — since every one of them is an optional parameter,
      // omitting them silently reset each to its constructor default
      // (40.0 / true / '' / "everything shown") on every single
      // "Continue to Customise" tap, discarding whatever was actually
      // set on the template or already in effect on the provider. Same
      // template-first-else-current pattern as businessName/etc above.
      businessLogoDisplaySize: current.businessLogoDisplaySize,
      businessLogoShowInitial:
          businessInfo?.logoShowInitial ?? current.businessLogoShowInitial,
      businessLogoInitialLetter:
          businessInfo?.logoInitialLetter ?? current.businessLogoInitialLetter,

      clientName: d.clientName,
      clientEmail: d.clientEmail,
      clientPhone: d.clientPhone,
      clientAddress: d.clientAddress,
      // STRUCTURED ADDRESS SYNC PASS: clientAddressInfo is per-invoice —
      // like clientName/clientAddress above, it's read straight off the
      // selected draft's own data. create_invoice_bottom_sheet.dart's
      // _save() is what actually populates this (from the selected
      // Customer's addressInfo when one is picked in step 1, or from the
      // sheet's own six manual address fields otherwise).
      clientAddressInfo: d.clientAddressInfo,
      invoiceNumber: d.invoiceNumber,
      issueDate: d.issueDate,
      dueDate: d.dueDate,
      notes: d.notes,
      currency: d.currency,
      currencySymbol: d.currencySymbol,
      currencyDisplayMode: d.currencyDisplayMode,
      lineItems: d.lineItems.map((i) => i.copyWith()).toList(),
      taxRate: d.taxRate,
      discountRate: d.discountRate,
      paymentStatus: current.paymentStatus,
      fontFamily: current.fontFamily,
      colorScheme: current.colorScheme,
      layoutTemplateId: widget.layoutTemplateId ?? current.layoutTemplateId,

      // ENABLED FIELDS + LOGO DISPLAY SYNC FIX: the fix this whole pass
      // was actually about — every field-visibility toggle in the app
      // (Payment Info/Terms/Signature and every pre-existing toggle
      // alike) is gated on this map, and it was never being carried
      // into the reconstructed InvoiceData here at all.
      enabledFields: widget.selectedTemplate?.enabledFields ?? current.enabledFields,

      // BUG FIX: poNumber is per-invoice (see client_info.dart's
      // BusinessInfo header comment) and lives on the draft's own data —
      // was previously missing from this constructor entirely, so it
      // never survived past this sync step.
      poNumber: d.poNumber,

      // AMOUNT DUE SYNC FIX: same bug class as poNumber above —
      // amountDueOverride is per-invoice (set on the Create Invoice
      // step's Due Date & Amount Due section) and lives on the draft's
      // own data, not on the template. Was missing from this
      // constructor call entirely, so a manually-set Amount Due never
      // survived past "Continue to Customise".
      amountDueOverride: d.amountDueOverride,

      // PAYMENT INFO / TERMS & SIGNATURE SYNC PASS: template value when
      // a template is selected, else keep whatever's already on the
      // provider — same pattern as businessName/Email/Phone/Address
      // above. Deliberately does NOT read these off `d` (the draft) —
      // these are template-authored, not per-invoice.
      //
      // PAYMENT TERMS REMOVAL PASS: the `paymentTerms:` line that used
      // to sit here has been removed — the field no longer exists on
      // either BusinessInfo or InvoiceData.
      bankName: businessInfo?.bankName ?? current.bankName,
      accountName: businessInfo?.accountName ?? current.accountName,
      accountNumber: businessInfo?.accountNumber ?? current.accountNumber,
      otherPaymentDetails:
          businessInfo?.otherPaymentDetails ?? current.otherPaymentDetails,
      termsAndConditions:
          businessInfo?.termsAndConditions ?? current.termsAndConditions,
      signatureMode: businessInfo?.signatureMode ?? current.signatureMode,
      signatureName: businessInfo?.signatureName ?? current.signatureName,
      signatureImagePath:
          businessInfo?.signatureImagePath ?? current.signatureImagePath,

      // SIGNATURE SIZER PASS: signatureFontSize is a per-invoice
      // Customise-step setting (the "Size" slider under the Signature
      // toggle), not template-authored — same class of field as
      // businessLogoDisplaySize above, which this constructor already
      // preserves from `current` for exactly this reason. Without this,
      // adjusting the slider on Customise, then going back and tapping
      // "Continue to Customise" again, would silently reset it to the
      // 22.0 constructor default.
      signatureFontSize: current.signatureFontSize,
    );

    provider.updateInvoiceData(data);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atMax = _library.length >= _kMaxInvoiceDrafts;
    // SAVED-ITEMS FILTERS PASS
    final visible = _visibleIndices;
    final isSearching = _searchQuery.trim().isNotEmpty;

    // SCAFFOLD PARITY FIX: this widget now returns its OWN
    // ScaffoldMessenger + Scaffold, with the StepNavBar registered as
    // that Scaffold's real `bottomNavigationBar` — instead of being a
    // plain trailing Column child inside EditorScreen's body. This is
    // what actually gives SnackBars shown via `_messengerKey` something
    // correct to dock above. `backgroundColor: Colors.transparent` keeps
    // this a pure layout/messenger change with no visual difference —
    // EditorScreen's own background still shows through underneath.
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Invoice',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Save one or more invoices, then continue with the one you want',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_loading)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${_library.length}/$_kMaxInvoiceDrafts',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: atMax
                                    ? const Color(0xFFEF5350)
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Context banner (template / customer selection) ─
                    CreateInvoiceContextBanner(
                      template: widget.selectedTemplate,
                      customer: widget.selectedCustomer,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // ── Create Invoice button ──────────────────────
                    // SCAFFOLD PARITY FIX: routed through _messengerKey
                    // instead of ScaffoldMessenger.of(context), and the
                    // stray `behavior: SnackBarBehavior.floating` here
                    // is dropped for consistency — the SnackBar default
                    // (fixed) now docks above this widget's own
                    // StepNavBar exactly like the other toasts in this
                    // file.
                    GestureDetector(
                      onTap: atMax
                          ? () => _messengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Maximum of $_kMaxInvoiceDrafts invoices reached.',
                                  ),
                                ),
                              )
                          : () => _showCreateSheet(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: atMax
                              ? (isDark
                                  ? colorScheme.surfaceContainerHighest
                                  : const Color(0xFFF5F5F5))
                              : (isDark
                                  ? const Color(0xFF0D1B2E)
                                  : const Color(0xFFE3F2FD)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: atMax
                                ? colorScheme.outline.withValues(alpha: 0.3)
                                : (isDark
                                    ? _accent.withValues(alpha: 0.5)
                                    : const Color(0xFF90CAF9)),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: atMax
                                  ? colorScheme.onSurface.withValues(alpha: 0.3)
                                  : _accent,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                atMax
                                    ? 'Maximum Invoices Reached'
                                    : 'Create Invoice',
                                style: TextStyle(
                                  color: atMax
                                      ? colorScheme.onSurface
                                          .withValues(alpha: 0.3)
                                      : _accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Library header ────────────────────────────────────────
            if (!_loading && _library.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmark_rounded,
                              size: 16, color: _accent),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Saved Invoices',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _selectedIndex != null ? '1 ✓' : 'none',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _selectedIndex != null
                                    ? _accent
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(
                                () => _showLibraryPanel = !_showLibraryPanel),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF0D1B2E)
                                    : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _showLibraryPanel ? 'Hide' : 'Show',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    _showLibraryPanel
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: _accent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap a card to select it for this invoice.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Search + sort (SAVED-ITEMS FILTERS PASS) ─────────────
            if (!_loading && _showLibraryPanel && _library.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DraftSearchField(
                        controller: _searchCtrl,
                        accent: _accent,
                        hintText: 'Search saved invoices…',
                        onClear: () => _searchCtrl.clear(),
                      ),
                      const SizedBox(height: 10),
                      IgnorePointer(
                        ignoring: isSearching,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isSearching ? 0.35 : 1.0,
                          child: _DraftSortSelector(
                            value: _sortMode,
                            accent: _accent,
                            onChanged: (mode) =>
                                setState(() => _sortMode = mode),
                          ),
                        ),
                      ),
                      if (isSearching) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Sorted by relevance to "${_searchCtrl.text.trim()}"',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // ── Draft cards ────────────────────────────────────────────
            if (!_loading && _showLibraryPanel && _library.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, displayIdx) {
                      final i = visible[displayIdx];
                      return _InvoiceDraftCard(
                        draft: _library[i],
                        isSelected: _selectedIndex == i,
                        onTap: () => _toggleDraft(i),
                        onEdit: () => _showCreateSheet(
                            existing: _library[i], editIndex: i),
                        onDelete: () => _deleteDraft(i),
                      );
                    },
                    childCount: visible.length,
                  ),
                ),
              ),

            // ── No search results ────────────────────────────────────
            if (!_loading &&
                _showLibraryPanel &&
                _library.isNotEmpty &&
                isSearching &&
                visible.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    'No invoices match your search',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),

            // ── Empty state ─────────────────────────────────────────
            if (!_loading && _library.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'No invoices created yet',
                  sub: 'Tap above to create your first invoice',
                ),
              ),

            if (_loading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
              ),
          ],
        ),

        // ── Bottom nav bar (Back / Continue to Customise) ───────────────
        // SCAFFOLD PARITY FIX: this is now the nested Scaffold's real
        // `bottomNavigationBar` — the piece that actually makes SnackBars
        // shown via `_messengerKey` dock correctly above it, instead of
        // being just another trailing Column child with nothing for a
        // fixed-behavior SnackBar to dock above.
        bottomNavigationBar: SafeArea(
          top: false,
          bottom: true,
          child: StepNavBar(
            onBack: widget.onBack,
            onNext: _continue,
            nextLabel: 'Continue to Customise',
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SAVED-ITEMS FILTERS PASS: search field for the saved-invoice list.
// Functionally identical to the Templates step's own search field,
// duplicated here since that widget is file-private to that file.
// =============================================================================

class _DraftSearchField extends StatelessWidget {
  final TextEditingController controller;
  final Color accent;
  final String hintText;
  final VoidCallback onClear;

  const _DraftSearchField({
    required this.controller,
    required this.accent,
    required this.hintText,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final hasText = controller.text.isNotEmpty;
        return TextField(
          controller: controller,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
                fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.35)),
            prefixIcon: Icon(Icons.search_rounded,
                size: 20, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            suffixIcon: hasText
                ? GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close_rounded,
                        size: 18, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                  )
                : null,
            filled: true,
            fillColor: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : const Color(0xFFF9F9F9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: accent, width: 1.5)),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SAVED-ITEMS FILTERS PASS: sort selector (segmented chips) for the
// saved-invoice list. Same shape as the Templates step's own sort
// selector.
// =============================================================================

class _DraftSortSelector extends StatelessWidget {
  final _DraftSortMode value;
  final Color accent;
  final ValueChanged<_DraftSortMode> onChanged;

  const _DraftSortSelector({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  static const _options = [
    (_DraftSortMode.recent, 'Recent', Icons.schedule_rounded),
    (_DraftSortMode.nameAsc, 'A–Z', Icons.arrow_downward_rounded),
    (_DraftSortMode.nameDesc, 'Z–A', Icons.arrow_upward_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _options.map((opt) {
          final (mode, label, icon) = opt;
          final selected = value == mode;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? accent
                      : (isDark
                          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                          : const Color(0xFFF9F9F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? accent : colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon,
                        size: 13,
                        color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Invoice Draft Card
// =============================================================================

class _InvoiceDraftCard extends StatelessWidget {
  final SavedInvoiceDraft draft;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _accent = Color(0xFF2196F3);

  const _InvoiceDraftCard({
    required this.draft,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = draft.data;
    final currencyPrefix = d.currencySymbol.trim().isNotEmpty
        ? d.currencySymbol.trim()
        : (d.currency.trim().isNotEmpty ? '${d.currency.trim()} ' : '');

    // CONTAINER LOGO + MANDATORY NAME PASS: real thumbnail when the
    // container has a logo set, else the same rotated-square fallback
    // mark step_templates.dart's _TemplateCard uses (or a plain icon as
    // the last resort when logoShowInitial is off) — mirrors that
    // card's icon-block logic exactly, adapted to SavedInvoiceDraft's
    // flat logo fields.
    final hasLogo = draft.logoPath != null &&
        draft.logoPath!.isNotEmpty &&
        File(draft.logoPath!).existsSync();
    final shape = logoShapeFromString(draft.logoShape);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF0D1B2E) : Colors.white)
            : (isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : const Color(0xFFF9F9F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? _accent.withValues(alpha: isDark ? 0.6 : 0.5)
              : colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: isDark ? 0.12 : 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? _accent
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 13)
                    : null,
              ),
              const SizedBox(width: 12),

              // Logo / fallback mark — see CONTAINER LOGO + MANDATORY
              // NAME PASS above.
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: shape.radiusFor(46),
                  color: isSelected
                      ? (isDark
                          ? _accent.withValues(alpha: 0.15)
                          : const Color(0xFFE3F2FD))
                      : colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  border: Border.all(
                    color: isSelected
                        ? _accent.withValues(alpha: 0.4)
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? SharedLogoThumbnail(
                        logoPath: draft.logoPath!,
                        logoOffset: Offset(draft.logoOffsetDx, draft.logoOffsetDy),
                        logoScale: draft.logoScale,
                        logoShape: shape,
                        boxSize: 46,
                      )
                    : (draft.logoShowInitial
                        ? _DraftCardFallbackMark(draft: draft, accent: _accent)
                        : Icon(
                            Icons.receipt_long_rounded,
                            color: isSelected
                                ? _accent
                                : colorScheme.onSurface.withValues(alpha: 0.3),
                            size: 22,
                          )),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (d.invoiceNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        d.invoiceNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? _accent
                              : colorScheme.onSurface.withValues(alpha: 0.3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                _accent.withValues(alpha: isDark ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${draft.itemCount} item${draft.itemCount == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '$currencyPrefix${draft.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Edited ${draft.lastEditedDisplay()}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: isDark ? 0.18 : 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Selected to continue',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? _accent.withValues(alpha: 0.12)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.edit_rounded, color: _accent, size: 16),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFEF5350).withValues(alpha: 0.12)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Color(0xFFEF5350), size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _DraftCardFallbackMark — rotated-square initial mark shown when a draft
// has no container logo set and logoShowInitial is on. Mirrors
// step_templates.dart's _CardFallbackMark exactly, adapted to
// SavedInvoiceDraft's flat logo fields (and draft.name / the invoice's
// client name as the letter source) instead of BusinessInfo's nesting.
// =============================================================================

class _DraftCardFallbackMark extends StatelessWidget {
  final SavedInvoiceDraft draft;
  final Color accent;
  const _DraftCardFallbackMark({required this.draft, required this.accent});

  @override
  Widget build(BuildContext context) {
    final letter = draft.logoInitialLetter.trim();
    final source = draft.name.trim().isNotEmpty
        ? draft.name.trim()
        : draft.data.clientName.trim();
    final initial = letter.isNotEmpty
        ? letter[0].toUpperCase()
        : (source.isNotEmpty ? source[0].toUpperCase() : 'I');
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(4)),
          ),
        ),
        Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}