// lib/screens/invoice_create_section/step_create_invoice/step_create_invoice.dart
//
// ENABLED-FIELDS RE-SYNC FIX (this update): _syncSelectedToProvider()'s
// `enabledFields` resolution was the one field in this whole function
// that never got the SAME-SESSION RE-SYNC FIX treatment (see that pass's
// comment below) — it unconditionally overwrote the ENTIRE enabledFields
// map from the template's copy (when the template had one) on every
// single call, including a same-session re-sync (Customise -> Back ->
// Continue again without saving). That silently reverted ANY field
// toggle made in Customise — Business Name included — the moment the
// person navigated back and forward between these two steps, which is
// exactly what "the switch won't stay off" turned out to be. Fixed with
// the same `sameSession ? current.enabledFields : ...` guard every other
// Customise-only field here already has.
//
// DRAFT-SYNC PASS (earlier): two related fixes so Customise-only
// fields (Footer Taglines, and the invoice's own business logo — as
// opposed to this screen's separate "Container Logo") stop reverting
// when a draft is reused.
//
//   1. _syncSelectedToProvider()'s business-logo resolution previously
//      only ever considered `current` (the live provider — which may
//      have just been reset to defaults by Home's "Create Invoice"
//      button) or the template's own logo — never `d` (the actual
//      selected draft's own saved data). That's the exact same bug
//      class the FOOTER TAGLINES PERSISTENCE FIX v2 below already fixed
//      for the taglines fields — just not caught for the business logo
//      at the time. Now the draft's own logo (path/offset/scale/shape/
//      display size/show-initial/initial-letter) wins first when it has
//      one, ahead of the template, ahead of `current`.
//
//   2. Neither Footer Taglines nor the business logo are ever touched
//      by CreateInvoiceBottomSheet itself (they're Customise-only
//      controls) — so even reading them correctly from `d` here only
//      gets you the value the draft had the LAST time it was synced to
//      Customise and saved. Nothing previously wrote a Customise
//      session's changes back onto the originating draft, so picking
//      the same draft again after customising and saving an invoice
//      from it would still show the stale, pre-customisation value.
//      Fixed with a new public helper, syncCustomiseFieldsToDraft(),
//      called from step_customise.dart's _handleSave() right after a
//      successful save — see that file's own comment. This screen also
//      now calls provider.setSourceDraftId(draft.id) in
//      _syncSelectedToProvider() so the provider knows which draft (if
//      any) the current session came from, letting Customise's save
//      step know which draft entry to write back to.
//
// SAME-SESSION RE-SYNC FIX (earlier): the fix above only solved half
// the problem. _syncSelectedToProvider() re-runs on EVERY press of
// "Continue to Customise" — including when the user has already been in
// Customise this session, made an unsaved change (e.g. toggled Footer
// Taglines on), then tapped Back (returning to this step, same draft
// still selected) and Continue again. syncCustomiseFieldsToDraft() only
// writes Customise-only fields back onto the draft ON SAVE — so at that
// point the draft (`d`) still has whatever value it had BEFORE this
// session started, and re-reading `d` here silently overwrote the
// in-progress, not-yet-saved change with that stale value. This is what
// "Footer Taglines keeps turning off every time I enter Customise"
// actually was, whenever the flow involved any back-and-forth before
// saving — not just the "reset by Home" case the v2 fix below handled.
//
// Fixed by detecting whether this is a fresh sync from the draft (first
// time this session touches it) versus a RE-sync of the same
// already-in-progress session (provider.sourceDraftId already equals
// this draft's id). For every
// Customise-only field — footer taglines (enabled/font size/items), the
// entire business-logo group, and (as of this update) enabledFields — a
// same-session re-sync now keeps whatever's currently on the provider
// instead of re-pulling from the draft, so an unsaved in-session change
// can no longer be clobbered by navigating back and forward again.
// businessTagline (the actual TEXT) is unaffected — that's still
// authored on the template, not editable in Customise, so it keeps its
// original template-first-else-current resolution regardless of session
// state.
//
// (All header comments below from previous passes describe work already
// done and unaffected by this update — see project history.)
//
// FOOTER TAGLINES PERSISTENCE FIX v2 (earlier): _syncSelectedToProvider()
// previously carried businessTaglineEnabled/footerTaglinesEnabled/
// footerTaglinesFontSize forward from `current` (provider.invoiceData)
// instead of a template default — correct in isolation, but this sync also
// runs right after Home's "Create Invoice" button calls
// InvoiceProvider.resetInvoiceData() (see home_screen.dart), which wipes
// `current` back to a brand-new InvoiceData() BEFORE the user ever picks a
// saved draft on this screen. So "carry forward from current" was actually
// carrying forward an already-reset value, not the draft's real saved
// value — invisible for footerTaglinesEnabled specifically because its
// default is false, the same failure mode as the original bug, just one
// step earlier in the flow (Home -> Create Invoice -> pick an existing
// draft -> Continue to Customise).
//
// Fixed by sourcing these three fields from `d` (draft.data — the actual
// selected saved draft) instead of `current`, matching every other
// per-document field in this constructor (clientName, invoiceNumber,
// lineItems, taxRate, poNumber, amountDueOverride, etc. all already read
// from `d`). footerTaglines itself now also prefers the draft's own items
// when non-empty, ahead of the template's, ahead of current — same
// three-tier fallback shape as before, just with the right priority order:
// a real per-document value (d) outranks a template default, which
// outranks provider state that may have just been reset to nothing.
//
// (All header comments below from previous passes describe work already
// done and unaffected by this pass — see project history.)
//
// FOOTER TAGLINES PERSISTENCE FIX (earlier): _syncSelectedToProvider()
// used to resolve businessTaglineEnabled/footerTaglinesEnabled as
// `businessInfo?.field ?? current.field` — but both fields are
// non-nullable bools on BusinessInfo, so a template that simply hasn't
// touched them (still sitting at BusinessInfo's own defaults) silently
// overrode whatever the user had already set on THIS document in
// Customise, every single time this sync re-ran (i.e. every time the
// flow moved from Create Invoice into Customise). Most visible on
// footerTaglinesEnabled specifically because its default is false —
// unlike nearly every other toggle here, which defaults true, so an
// unnoticed reset there just looks like nothing changed. Same fix
// shape as footerTaglinesFontSize already below: always carry the
// current session's value forward instead of letting a template
// default silently stomp it. Trade-off: a template that explicitly
// sets footerTaglinesEnabled/businessTaglineEnabled true no longer
// auto-applies to a brand-new invoice from that template — the user
// toggles it on once in Customise as before.
//
// SENDER-AS-FROM-CONTACT SYNC PASS (earlier): _syncSelectedToProvider()
// also carries BusinessInfo.senderEmail/senderPhone/senderAddressInfo
// through onto InvoiceData.senderEmail/senderPhone/senderAddressInfo —
// same template-first-else-current pattern as every other field here.
// Previously these sender fields existed on BusinessInfo (collected on
// the template sheet) but were never copied onto InvoiceData at all, so
// they never reached the actual document. Now that
// doc_template_adapter.dart's invoiceToAdapter() sources the FROM
// block's email/phone/address from these sender fields instead of the
// business* ones (see that file, and step_templates.dart's trimmed
// Business Information section), this sync step is what actually gets
// sender data from the template onto a real invoice.
//
// FOOTER TAGLINES SYNC PASS (earlier): _syncSelectedToProvider()
// now carries businessTagline/businessTaglineEnabled/
// footerTaglinesEnabled/footerTaglines through — same template-first-
// else-current pattern already used for businessName/Email/Phone/
// Address just above it. Without this, a tagline or footer-tagline
// items authored on a template never reached a brand-new invoice built
// from that template — they only ever showed up if set directly on an
// in-progress document via Customise. footerTaglines specifically uses
// "template has any items -> use them, else keep current" rather than
// a plain `??`, since an empty list is not the same as "no template
// value" the way null is for every other field here.
//
// (All other header comments from the previous version describe work
// already done and unaffected by this pass — see project history.)

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

// DRAFT-SYNC PASS: writes the just-saved invoice's Customise-only
// fields back onto the draft that originated it (identified by
// InvoiceProvider.sourceDraftId, set by _syncSelectedToProvider()
// below). Without this, Footer Taglines and the business logo only
// ever live on the finished SavedInvoice — the separate draft library
// never learns the change, since CreateInvoiceBottomSheet never touches
// either of these fields itself. So re-selecting that draft next time
// would keep reverting to whatever it was when the draft was last saved
// via the bottom sheet (its class defaults, most of the time).
//
// Called from step_customise.dart's _handleSave() right after a
// successful saveCurrentInvoice() call, passing the freshly-saved
// SavedInvoice's own `.data`. No-ops quietly if the draft no longer
// exists (e.g. it was deleted from the library in the meantime) — this
// is a best-effort convenience sync, not something that should ever
// block or fail the actual invoice save it runs after.
Future<void> syncCustomiseFieldsToDraft(
  String draftId,
  InvoiceData finalData,
) async {
  final drafts = await _loadDrafts();
  final index = drafts.indexWhere((d) => d.id == draftId);
  if (index == -1) return;

  final updated = drafts[index].copyWith(
    data: drafts[index].data.copyWith(
          businessTagline: finalData.businessTagline,
          businessTaglineEnabled: finalData.businessTaglineEnabled,
          footerTaglinesEnabled: finalData.footerTaglinesEnabled,
          footerTaglinesFontSize: finalData.footerTaglinesFontSize,
          footerTaglines:
              finalData.footerTaglines.map((t) => t.copyWith()).toList(),
          businessLogoPath: finalData.businessLogoPath,
          clearBusinessLogo: finalData.businessLogoPath == null,
          businessLogoOffsetDx: finalData.businessLogoOffsetDx,
          businessLogoOffsetDy: finalData.businessLogoOffsetDy,
          businessLogoScale: finalData.businessLogoScale,
          businessLogoShape: finalData.businessLogoShape,
          businessLogoDisplaySize: finalData.businessLogoDisplaySize,
          businessLogoShowInitial: finalData.businessLogoShowInitial,
          businessLogoInitialLetter: finalData.businessLogoInitialLetter,
        ),
    lastEditedAt: DateTime.now(),
  );
  drafts[index] = updated;
  await _persistDrafts(drafts);
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

  // DRAFT-SYNC PASS: see this file's header comment for the full
  // rationale. Short version — businessLogo* fields now prefer the
  // selected draft's own saved logo (d) over `current`/the template,
  // matching footerTaglinesEnabled's own fix below, and
  // provider.setSourceDraftId(draft.id) records which draft this
  // session came from so step_customise.dart's _handleSave() can write
  // Customise-only changes back onto it later.
  //
  // SAME-SESSION RE-SYNC FIX: `sameSession` is true when this screen's
  // "Continue" is being pressed again for a session that was ALREADY
  // synced from this exact draft (i.e. provider.sourceDraftId already
  // equals draft.id) — meaning the user went Customise -> Back ->
  // Continue without saving in between. In that case every
  // Customise-only field (footer taglines, the whole business-logo
  // group, and — per the ENABLED-FIELDS RE-SYNC FIX above —
  // enabledFields) is left exactly as `current` already has it, instead
  // of being re-pulled from the draft/template — otherwise any unsaved
  // change made in that Customise session gets silently stomped by the
  // draft's/template's stale, last-saved value. A fresh sync (new
  // draft, or first time this draft is picked) still resolves
  // draft-first exactly as before.
  //
  // FOOTER TAGLINES PERSISTENCE FIX v2: businessTaglineEnabled,
  // footerTaglinesEnabled, and footerTaglinesFontSize read from `d`
  // (draft.data, the actual selected saved draft) instead of `current`
  // (provider.invoiceData, which may have just been reset to defaults
  // by Home's "Create Invoice" button before this screen ever ran) —
  // UNLESS sameSession, per the fix above.
  void _syncSelectedToProvider() {
    final draft = _library[_selectedIndex!];
    final d = draft.data;
    final provider = context.read<InvoiceProvider>();
    final current = provider.invoiceData;
    final businessInfo = widget.selectedTemplate?.businessInfo;

    // SAME-SESSION RE-SYNC FIX: sourceDraftId lives on the PROVIDER
    // (set via provider.setSourceDraftId() at the bottom of this
    // function), not on InvoiceData itself — read it from `provider`,
    // not from `current`.
    final bool sameSession = provider.sourceDraftId == draft.id;

    // DRAFT-SYNC PASS: the invoice's own business logo (set via
    // Customise's LogoSection) previously only ever read from `current`
    // (the live provider, which may have just been reset to defaults)
    // or the template — never from `d`, the same bug class
    // footerTaglinesEnabled had before its own fix below. The draft's
    // own logo wins first when it has one, ahead of the template, ahead
    // of whatever's currently on the provider — but only on a FRESH
    // sync (see SAME-SESSION RE-SYNC FIX above); a same-session re-sync
    // keeps `current`'s logo untouched instead, since the user may have
    // just changed it in Customise without saving yet.
    final draftHasLogo =
        d.businessLogoPath != null && d.businessLogoPath!.isNotEmpty;
    final providerHasLogo = current.businessLogoPath != null &&
        current.businessLogoPath!.isNotEmpty;
    final useDraftLogo = draftHasLogo && !sameSession;
    final useTemplateLogo = !sameSession &&
        !draftHasLogo &&
        !providerHasLogo &&
        businessInfo?.logoPath != null;

    final resolvedLogoPath = sameSession
        ? current.businessLogoPath
        : (useDraftLogo
            ? d.businessLogoPath
            : (useTemplateLogo ? businessInfo!.logoPath : current.businessLogoPath));
    final resolvedLogoOffsetDx = sameSession
        ? current.businessLogoOffsetDx
        : (useDraftLogo
            ? d.businessLogoOffsetDx
            : (useTemplateLogo
                ? businessInfo!.logoOffsetDx
                : current.businessLogoOffsetDx));
    final resolvedLogoOffsetDy = sameSession
        ? current.businessLogoOffsetDy
        : (useDraftLogo
            ? d.businessLogoOffsetDy
            : (useTemplateLogo
                ? businessInfo!.logoOffsetDy
                : current.businessLogoOffsetDy));
    final resolvedLogoScale = sameSession
        ? current.businessLogoScale
        : (useDraftLogo
            ? d.businessLogoScale
            : (useTemplateLogo ? businessInfo!.logoScale : current.businessLogoScale));
    final resolvedLogoShape = sameSession
        ? current.businessLogoShape
        : (useDraftLogo
            ? d.businessLogoShape
            : (useTemplateLogo ? businessInfo!.logoShape : current.businessLogoShape));
    final resolvedLogoDisplaySize = sameSession
        ? current.businessLogoDisplaySize
        : (draftHasLogo ? d.businessLogoDisplaySize : current.businessLogoDisplaySize);
    final resolvedLogoShowInitial = sameSession
        ? current.businessLogoShowInitial
        : (draftHasLogo
            ? d.businessLogoShowInitial
            : (businessInfo?.logoShowInitial ?? current.businessLogoShowInitial));
    final resolvedLogoInitialLetter = sameSession
        ? current.businessLogoInitialLetter
        : (draftHasLogo
            ? d.businessLogoInitialLetter
            : (businessInfo?.logoInitialLetter ?? current.businessLogoInitialLetter));

    final resolvedBusinessAddressInfo =
        businessInfo?.addressInfo ?? current.businessAddressInfo;
    final resolvedBusinessAddress = resolvedBusinessAddressInfo.isNotEmpty
        ? resolvedBusinessAddressInfo.singleLine
        : (businessInfo?.address ?? current.businessAddress);

    // SENDER-AS-FROM-CONTACT SYNC PASS: same template-first-else-current
    // resolution as resolvedBusinessAddressInfo above, but for the
    // sender's own address — this is what the FROM block on the actual
    // document now renders (see doc_template_adapter.dart).
    final resolvedSenderAddressInfo =
        businessInfo?.senderAddressInfo ?? current.senderAddressInfo;

    // SAME-SESSION RE-SYNC FIX / FOOTER TAGLINES PERSISTENCE FIX v2:
    // prefer the draft's own saved items first, then the template's,
    // then whatever's currently on the provider — but only on a FRESH
    // sync. A same-session re-sync keeps `current`'s items untouched,
    // for the same reason as the logo group above.
    final resolvedFooterTaglines = sameSession
        ? current.footerTaglines.map((t) => t.copyWith()).toList()
        : (d.footerTaglines.isNotEmpty
            ? d.footerTaglines.map((t) => t.copyWith()).toList()
            : (businessInfo != null && businessInfo.footerTaglines.isNotEmpty)
                ? businessInfo.footerTaglines.map((t) => t.copyWith()).toList()
                : current.footerTaglines.map((t) => t.copyWith()).toList());

    final data = InvoiceData(
      businessName: businessInfo?.name ?? current.businessName,
      // FOOTER TAGLINES SYNC PASS: template value if a template is
      // selected, else keep whatever's already on the provider — same
      // pattern as businessName/Email/Phone/Address. businessTagline
      // itself is authored on the template (not editable in Customise),
      // so it's unaffected by the SAME-SESSION RE-SYNC FIX.
      businessTagline: businessInfo?.tagline ?? current.businessTagline,
      // SAME-SESSION RE-SYNC FIX: keep `current`'s value when re-syncing
      // the same in-progress session — see this function's header
      // comment. Otherwise (fresh sync), read from the actual selected
      // draft (d), not the live provider (current) — current may have
      // just been reset to defaults by Home's "Create Invoice" button
      // before this screen ever ran.
      businessTaglineEnabled:
          sameSession ? current.businessTaglineEnabled : d.businessTaglineEnabled,
      footerTaglinesEnabled:
          sameSession ? current.footerTaglinesEnabled : d.footerTaglinesEnabled,
      // MISSING-FONT-SIZE FIX (revised): same reasoning as
      // footerTaglinesEnabled above.
      footerTaglinesFontSize:
          sameSession ? current.footerTaglinesFontSize : d.footerTaglinesFontSize,
      footerTaglines: resolvedFooterTaglines,
      businessEmail: businessInfo?.email ?? current.businessEmail,
      businessPhone: businessInfo?.phone ?? current.businessPhone,
      businessAddress: resolvedBusinessAddress,
      businessAddressInfo: resolvedBusinessAddressInfo,
      // SENDER-AS-FROM-CONTACT SYNC PASS: the fields that actually
      // render in the FROM block now (see doc_template_adapter.dart's
      // invoiceToAdapter). Sourced from the template's Sender / Contact
      // Person section, not Business Information.
      senderEmail: businessInfo?.senderEmail ?? current.senderEmail,
      senderPhone: businessInfo?.senderPhone ?? current.senderPhone,
      senderAddressInfo: resolvedSenderAddressInfo,
      businessTaxId: businessInfo?.taxId ?? current.businessTaxId,
      businessGst: businessInfo?.gstNumber ?? current.businessGst,
      businessLogoPath: resolvedLogoPath,
      businessLogoOffsetDx: resolvedLogoOffsetDx,
      businessLogoOffsetDy: resolvedLogoOffsetDy,
      businessLogoScale: resolvedLogoScale,
      businessLogoShape: resolvedLogoShape,

      // DRAFT-SYNC PASS / SAME-SESSION RE-SYNC FIX: now sourced from
      // the same draft-first-unless-sameSession resolution as the rest
      // of the logo fields above, instead of reading `current`/the
      // template directly.
      businessLogoDisplaySize: resolvedLogoDisplaySize,
      businessLogoShowInitial: resolvedLogoShowInitial,
      businessLogoInitialLetter: resolvedLogoInitialLetter,

      clientName: d.clientName,
      clientEmail: d.clientEmail,
      clientPhone: d.clientPhone,
      clientAddress: d.clientAddress,
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

      // ENABLED-FIELDS RE-SYNC FIX: this was the one Customise-only
      // value in the whole function still missing the sameSession
      // guard — see this file's header comment. A same-session re-sync
      // now keeps whatever's currently on the provider (i.e. whatever
      // the person just toggled in Customise) instead of being
      // unconditionally overwritten by the template's own copy every
      // time this screen's "Continue" runs.
      enabledFields: sameSession
          ? current.enabledFields
          : (widget.selectedTemplate?.enabledFields ?? current.enabledFields),

      poNumber: d.poNumber,

      amountDueOverride: d.amountDueOverride,

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

      signatureFontSize: current.signatureFontSize,
    );

    provider.updateInvoiceData(data);
    // DRAFT-SYNC PASS: record which draft this session came from, so
    // step_customise.dart's _handleSave() knows which draft entry to
    // write Customise-only fields back onto once the invoice is saved.
    // This is what the NEXT call to _syncSelectedToProvider() reads (as
    // `provider.sourceDraftId`) to compute `sameSession` above.
    provider.setSourceDraftId(draft.id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final atMax = _library.length >= _kMaxInvoiceDrafts;
    final visible = _visibleIndices;
    final isSearching = _searchQuery.trim().isNotEmpty;

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
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

                    CreateInvoiceContextBanner(
                      template: widget.selectedTemplate,
                      customer: widget.selectedCustomer,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

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
// Search field / sort selector — unchanged from earlier passes.
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