// lib/screens/quote_editor_screen.dart
//
// PAYMENT/TERMS/SIGNATURE RESTORE-SYNC FIX (this update): unlike
// logo/enabledFields — which have always been synced correctly on
// template selection, so whatever's already sitting in QuoteData on a
// later restore is trustworthy — termsAndConditions/signatureMode/
// signatureName/signatureImagePath/bankName/accountName/accountNumber/
// otherPaymentDetails only started being pushed onto QuoteData recently
// (via _applyTemplate()'s call to provider.applyPaymentAndTermsFromTemplate()).
// _restoreTemplate() — which is what actually fires every time
// QuoteStepTemplateSection remounts and re-finds an already-selected
// template (leaving the Template step and coming back, or reopening a
// saved quote whose Template step hasn't been (re)visited yet this
// session) — never called that sync at all. Effect of the bug: any
// quote whose Template step wasn't the very last thing touched before
// checking Live Preview/Customise stayed stuck with empty terms and a
// blank signature forever, even though the linked template had real
// values typed into it, because restoring a template only ever
// refreshed this screen's own _selectedTemplate/_initialTemplateId —
// never the live QuoteData other screens actually read from.
//
// Fix: _restoreTemplate() now also calls
// provider.applyPaymentAndTermsFromTemplate(...), but only the FIRST
// time a given template is (re-)established in this editing session —
// gated by the new _syncedTemplateId field. Without that guard,
// re-syncing on every single remount would silently overwrite any
// per-quote signature customisation made afterwards via Customise's own
// Signature section (quote_step_customise.dart calls
// updateSignatureMode()/updateSignatureName()/updateSignatureImagePath()
// directly on QuoteProvider, independent of the template) every time the
// user simply flips back to the Template step without changing
// anything. _applyTemplate() (fresh selection or template edit-save)
// always syncs and always updates _syncedTemplateId, since an explicit
// re-selection/edit is a deliberate signal to pull in the template's
// current values.
//
// SELECTED-TEMPLATE/CLIENT STALE-ID FIX (earlier): _initialTemplateId
// and _initialClientId were each captured exactly ONCE, in initState(),
// from whatever QuoteProvider.quoteData.sourceTemplateId/sourceClientId
// happened to be when this screen first opened — and never updated
// again anywhere else in this file. QuoteStepTemplateSection (and
// QuoteStepCustomerSection) use that id purely to restore _selectedIndex
// when THEY re-run initState() — which happens every single time the
// user navigates away from the Template/Customer step and back, since
// _buildStep()'s switch statement swaps in a completely different
// widget for other steps and rebuilds a fresh instance of these two the
// moment the user returns.
//
// Effect of the bug: select a template, move forward through the
// wizard, then come back to the Template step to edit that same
// template (pencil icon) — the freshly-remounted
// QuoteStepTemplateSection restores _selectedIndex using the STALE
// _initialTemplateId (still whatever it was at screen-open time, often
// null for a brand-new quote), so _selectedIndex comes back null even
// though the template being edited is clearly "the" one in use. Its own
// onSaved callback then gates the resync on
// `if (_selectedIndex == editIndex) widget.onTemplateSelected(template)`
// — with _selectedIndex null, that check always fails, so
// onTemplateSelected() (and therefore _applyTemplate(), and therefore
// provider.applyPaymentAndTermsFromTemplate()) never fires. The edited
// template saves fine to the on-disk template library; the edit simply
// never reaches the live QuoteData for this quote, so nothing on
// Customise/Live Preview reflects it — a signature or terms edit looks
// like it silently did nothing.
//
// Fix: _applyTemplate()/_restoreTemplate() now also write
// template?.id into _initialTemplateId (mirrored for
// _applyClient()/_restoreClient() -> _initialClientId, same bug class),
// so any later remount of that step restores the correct selection and
// the edit-sync gate passes as expected.
//
// SIGNATURE/PAYMENT/TERMS SYNC FIX (earlier): _applyTemplate() was
// pushing the selected QuoteTemplate's logo and enabledFields onto
// QuoteProvider, but never its bankName/accountName/accountNumber/
// otherPaymentDetails/termsAndConditions/signatureMode/signatureName/
// signatureImagePath — even though QuoteProvider already had a bundled
// applyPaymentAndTermsFromTemplate() method built for exactly this,
// sitting unused (see that method's own header comment in
// quote_provider.dart, which explicitly flagged this as "the
// still-missing template-select sync step"). Effect of the bug: typing
// a signature name and picking "Type" on the Template sheet
// (_QuoteSignatureSection in quote_step_template_signature.dart) wrote
// those values onto the QuoteTemplate object only — nothing ever read
// them back onto the live QuoteData, so the Live Preview and the saved
// PDF always fell back to QuoteData's own signatureMode default
// ('blank'), and any typed name/image never appeared anywhere.
//
// Fix: _applyTemplate() now also calls
// provider.applyPaymentAndTermsFromTemplate(...) with the template's
// values, in the same place and following the same "apply once, at
// template selection" pattern already used for logoPath/enabledFields
// just above it — not re-pushed on every _syncToProvider() step
// transition, so it can't clobber a signature the user later
// fine-tunes via Customise's own Size/Font controls (which only ever
// adjust signatureFontSize/signatureFontFamily, never mode/name/image).
// _restoreTemplate() (used when reopening an already-saved quote) is
// deliberately left untouched for logo/enabledFields — same reasoning as
// the pre-existing logo/enabledFields asymmetry between
// _applyTemplate/_restoreTemplate: on restore, the provider's QuoteData
// already holds whatever was last saved for this quote, and re-pushing
// the template's values there would wipe out any per-quote
// customisation made after the template was originally applied. (This
// is exactly the assumption the PAYMENT/TERMS/SIGNATURE RESTORE-SYNC FIX
// above had to special-case, since it doesn't hold for fields that were
// never correctly synced in the first place.)
//
// CUSTOMISE OWNERSHIP PASS (earlier): QuoteStepCustomise
// (create_quote_section/step_customise/quote_step_customise.dart) is now
// a self-contained StatefulWidget that reads/writes QuoteProvider
// directly — logo, accent colour, font family/size, field-visibility
// toggles, and the quote title now all live on QuoteProvider/QuoteData
// (or the widget's own TextEditingController for the title), not as
// parallel copies on this screen. This fixes a real bug the old design
// had: _syncToProvider() ran on every step transition AND on opening
// the full preview from Customise, and it unconditionally pushed this
// screen's own stale local _logoPath/_colorScheme/_fontFamily/_fontSize/
// _enabledFields onto the provider — so editing the logo, accent colour,
// font, or a field toggle on Customise, then tapping "Preview &
// Download" or navigating via a step tab, silently reverted the edit
// back to whatever the Template step had last set.
//
// Fix: _logoPath/_logoOffset/_logoScale/_logoShape/_logoSize/
// _colorScheme/_fontFamily/_fontSize/_titleCtrl/_enabledFields are all
// REMOVED from this screen's state entirely. Business logo and
// enabledFields are now applied to the provider ONCE, directly inside
// _applyTemplate() at the moment a template is selected — not
// re-pushed on every subsequent _syncToProvider() call — so nothing
// this screen does after that can clobber a Customise-step edit.
// _syncToProvider() itself no longer touches logo/enabledFields/colour/
// font at all; it only carries business name/email/phone/address
// (template-authored, never edited on Customise) and the per-quote
// client/details/line-item data the Create Quote step already owned.
//
// This also means the Customise step is no longer one page in a shared
// scroll+bottom-nav-bar container — it supplies its own internal
// scroll view AND its own Back/Save bottom bar (matching Invoice's
// StepCustomise exactly), so when _step is the last step, this screen
// hands it the full bounded Expanded space directly instead of also
// wrapping it in a SingleChildScrollView (which would both double-
// scroll and break the widget's own internal Expanded/bottom-bar
// layout) or showing the shared QuoteStepNavBar underneath it (which
// would leave two "Save" affordances on screen at once). _save()/
// _saving are removed from this screen for the same reason — saving a
// quote now only ever happens from inside QuoteStepCustomise's own
// bottom bar.
//
// STEP CUSTOMER FOLDER MOVE PASS (earlier): quote_step_customer.dart
// relocated from create_quote_section/ into its own
// create_quote_section/step_customer/ subfolder — the only change in
// that pass was the import path. No behavioural change; QuoteStepCustomerSection/QuoteClient/QuoteStepCustomerController
// are all still the same types this screen already used.
//
// QUOTE LIBRARY RESTRUCTURE PASS (earlier): mirrors Invoice's own
// library restructure. The entire _createQuoteStep() body (quote
// number, dates, currency, client override, Saved Item Sets panel, line
// items, tax/discount, notes) has moved out into a bottom sheet
// (create_quote_section/step_create_quote/create_quote_bottom_sheet.dart,
// CreateQuoteBottomSheet), opened from a library screen embedded at
// this step (create_quote_section/step_create_quote/step_create_quote.dart,
// StepCreateQuote). Unlike Invoice's per-step StepNavBar, Quote keeps
// its existing single shared bottomNavigationBar (QuoteStepNavBar) for
// steps 0-2 — StepCreateQuote is an embedded widget (like
// QuoteStepCustomerSection/QuoteStepTemplateSection), not a standalone
// screen with its own nav.
//
// New state: _selectedQuoteDraft (SavedQuoteDraft?) replaces every piece
// of per-quote-details/line-item local state this screen used to own
// directly. StepCreateQuote reports the selected draft via
// onDraftSelected(); _syncToProvider() pulls quote number/dates/
// currency/line items/tax/discount from _selectedQuoteDraft?.data
// (falling back to whatever's already on the provider before any draft
// is selected). _stepBlockReason(2) and _validateForm() just check that
// a draft is selected, since the bottom sheet does its own full field
// validation before it will hand back a draft at all.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quote_provider.dart';
import '../models/quote_data.dart';
import '../widgets/step_editor_header.dart';
import 'create_quote_section/quote_edit_widgets.dart';
import 'create_quote_section/step_customer/quote_step_customer.dart';
import 'create_quote_section/step_customise/quote_step_customise.dart';
import 'create_quote_section/step_templates/quote_step_template.dart';
import 'create_quote_section/step_create_quote/step_create_quote.dart';

class QuoteEditorScreen extends StatefulWidget {
  final int layoutTemplateId;

  /// Which step to open on (0 = Customer ... 3 = Customise).
  final int initialStep;

  const QuoteEditorScreen({
    super.key,
    this.layoutTemplateId = 1,
    this.initialStep = 0,
  });

  @override
  State<QuoteEditorScreen> createState() => _QuoteEditorScreenState();
}

class _QuoteEditorScreenState extends State<QuoteEditorScreen> {
  static const Color _accent = Color(0xFF7B1FA2);

  static const List<StepMeta> _steps = [
    StepMeta(label: 'Customer', icon: Icons.person_rounded),
    StepMeta(label: 'Template', icon: Icons.tune_rounded),
    StepMeta(label: 'Create Quote', icon: Icons.request_quote_rounded),
    StepMeta(label: 'Customise', icon: Icons.rate_review_rounded),
  ];

  late int _step;
  late int _layoutTemplateId;

  QuoteTemplate? _selectedTemplate;
  QuoteClient? _selectedClient;

  String? _initialTemplateId;
  String? _initialClientId;

  // PAYMENT/TERMS/SIGNATURE RESTORE-SYNC FIX: tracks which template's
  // payment/terms/signature fields have already been pushed onto the
  // live QuoteData this session, so _restoreTemplate() only syncs once
  // per template selection instead of on every remount of the Template
  // step. See _restoreTemplate() below for why re-syncing on every
  // remount would be wrong (it would clobber Customise-level signature
  // overrides), and this file's header comment for the full bug this
  // fixes.
  String? _syncedTemplateId;

  // QUOTE LIBRARY RESTRUCTURE PASS: the selected draft from the Create
  // Quote step's library — carries quote number/dates/currency/client
  // override/line items/tax/discount/notes. Null until one is created or
  // selected on that step.
  SavedQuoteDraft? _selectedQuoteDraft;

  bool get _isLastStep => _step == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, _steps.length - 1);
    _layoutTemplateId = widget.layoutTemplateId;
    final q = context.read<QuoteProvider>().quoteData;

    _initialTemplateId = q.sourceTemplateId;
    _initialClientId = q.sourceClientId;
  }

  // SELECTED-TEMPLATE/CLIENT STALE-ID FIX: also updates _initialClientId
  // so a later remount of QuoteStepCustomerSection (navigating away from
  // Customer and back) restores the same client that's actually in use,
  // instead of falling back to whatever sourceClientId existed when this
  // screen first opened.
  void _applyClient(QuoteClient? client) {
    setState(() {
      _selectedClient = client;
      _initialClientId = client?.id;
    });
  }

  // CUSTOMISE OWNERSHIP PASS: template logo and field-visibility are now
  // applied straight to the provider ONCE, right here, instead of being
  // copied into this screen's own local state and re-pushed on every
  // subsequent _syncToProvider() call — see this file's header comment
  // for exactly why that re-push was the source of the overwrite bug.
  // businessName/Email/Phone/Address are NOT pushed here — those are
  // still synced in _syncToProvider() (template-first-else-current),
  // since nothing on Customise edits them and repeatedly re-applying
  // them on every step transition is harmless.
  //
  // SIGNATURE/PAYMENT/TERMS SYNC FIX: also applies the template's
  // Payment Info / Terms & Conditions / Signature fields onto the live
  // QuoteData, via QuoteProvider's own applyPaymentAndTermsFromTemplate()
  // — previously nothing ever called this, so a signature typed/picked
  // on the Template sheet (quote_step_template_signature.dart) stayed
  // on the QuoteTemplate object and never reached QuoteData, meaning it
  // never showed on the Live Preview or the exported PDF. Same "apply
  // once, at template selection" placement as the logo/enabledFields
  // calls above, for the same reason: it must not be re-pushed on every
  // _syncToProvider() step transition, or it would clobber whatever the
  // Customise step's Signature Size/Font controls set afterward.
  //
  // SELECTED-TEMPLATE/CLIENT STALE-ID FIX: also updates
  // _initialTemplateId to template?.id. Without this, re-editing the
  // currently-selected template after navigating away and back to the
  // Template step silently fails to resync — see this file's header
  // comment for the full mechanism.
  //
  // PAYMENT/TERMS/SIGNATURE RESTORE-SYNC FIX: also records
  // _syncedTemplateId = template?.id, since an explicit (re-)selection
  // or template edit-save here is always a deliberate signal to pull in
  // that template's current payment/terms/signature values — unlike a
  // passive remount-triggered restore (see _restoreTemplate() below).
  void _applyTemplate(QuoteTemplate? template) {
    setState(() {
      _selectedTemplate = template;
      _initialTemplateId = template?.id;
      _syncedTemplateId = template?.id;
    });
    if (template == null) return;
    final provider = context.read<QuoteProvider>();
    provider.updateBusinessInfo(
      businessLogoPath: template.logoPath,
      clearBusinessLogo: template.logoPath == null,
      businessLogoOffsetDx: template.logoOffsetDx,
      businessLogoOffsetDy: template.logoOffsetDy,
      businessLogoScale: template.logoScale,
      businessLogoShape: template.logoShape,
    );
    provider.updateEnabledFields(template.enabledFields);
    // SIGNATURE/PAYMENT/TERMS SYNC FIX: the missing sync step every
    // prior pass note in quote_provider.dart/quote_step_template.dart
    // flagged as pending. Without this call, template.signatureMode/
    // signatureName/signatureImagePath (and bankName/accountName/
    // accountNumber/otherPaymentDetails/termsAndConditions) never leave
    // the QuoteTemplate object.
    provider.applyPaymentAndTermsFromTemplate(
      bankName: template.bankName,
      accountName: template.accountName,
      accountNumber: template.accountNumber,
      otherPaymentDetails: template.otherPaymentDetails,
      termsAndConditions: template.termsAndConditions,
      signatureMode: template.signatureMode,
      signatureName: template.signatureName,
      signatureImagePath: template.signatureImagePath,
    );
    // Currency code lives on the selected draft (see
    // CreateQuoteBottomSheet's own template-currency prefill for new
    // drafts) rather than being pushed from here.
  }

  // SELECTED-TEMPLATE/CLIENT STALE-ID FIX: also updates
  // _initialTemplateId, same reasoning as _applyTemplate() above —
  // _restoreTemplate() runs when QuoteStepTemplateSection reports back
  // the template it found via the (possibly stale) initialSelectedId it
  // was constructed with; recording that id here keeps this screen's
  // own copy fresh for the NEXT time that step remounts.
  //
  // PAYMENT/TERMS/SIGNATURE RESTORE-SYNC FIX (this update): also syncs
  // the template's payment/terms/signature fields onto the live
  // QuoteData — but ONLY the first time this particular template is
  // (re-)established in this editing session, guarded by
  // _syncedTemplateId. Unlike logo/enabledFields (which have always
  // been synced correctly, so whatever's already in QuoteData on
  // restore is trustworthy), these fields only started being synced
  // recently via _applyTemplate()'s call to
  // applyPaymentAndTermsFromTemplate() — so a quote whose Template step
  // was never (re)visited after that sync was added (a previously-saved
  // quote reopened straight to Customise, or one whose Template step
  // simply hasn't remounted yet this session) was stuck with empty
  // terms and a blank signature forever, even though the linked
  // template had real values. Without the _syncedTemplateId guard,
  // re-syncing on every subsequent remount would silently overwrite any
  // per-quote signature customisation made afterwards via Customise's
  // own Signature section (quote_step_customise.dart calls
  // updateSignatureMode()/updateSignatureName()/
  // updateSignatureImagePath() directly on QuoteProvider, independent
  // of the template) every time the user simply flips back to the
  // Template step without changing anything.
  void _restoreTemplate(QuoteTemplate? template) {
    setState(() {
      _selectedTemplate = template;
      _initialTemplateId = template?.id;
    });
    if (template == null) return;
    if (_syncedTemplateId == template.id) return;
    context.read<QuoteProvider>().applyPaymentAndTermsFromTemplate(
      bankName: template.bankName,
      accountName: template.accountName,
      accountNumber: template.accountNumber,
      otherPaymentDetails: template.otherPaymentDetails,
      termsAndConditions: template.termsAndConditions,
      signatureMode: template.signatureMode,
      signatureName: template.signatureName,
      signatureImagePath: template.signatureImagePath,
    );
    _syncedTemplateId = template.id;
  }

  // SELECTED-TEMPLATE/CLIENT STALE-ID FIX: mirrors _restoreTemplate()
  // above for the Customer step/_initialClientId.
  void _restoreClient(QuoteClient? client) {
    setState(() {
      _selectedClient = client;
      _initialClientId = client?.id;
    });
  }

  // CUSTOMISE OWNERSHIP PASS: no longer touches business logo,
  // enabledFields, colour, font family, or font size — those are either
  // applied once in _applyTemplate() (logo/enabledFields/payment/terms/
  // signature) or owned entirely by QuoteStepCustomise writing straight
  // to the provider (colour/font). Business name/email/phone/address
  // and every per-quote field (client/details/line items) are unchanged
  // from before.
  void _syncToProvider() {
    final provider = context.read<QuoteProvider>();
    final current = provider.quoteData;
    final d = _selectedQuoteDraft?.data;

    provider.updateBusinessInfo(
      businessName: _selectedTemplate?.businessName ?? current.businessName,
      businessEmail: _selectedTemplate?.businessEmail ?? current.businessEmail,
      businessPhone: _selectedTemplate?.businessPhone ?? current.businessPhone,
      businessAddress: _selectedTemplate?.businessAddress ?? current.businessAddress,
      sourceTemplateId: _selectedTemplate?.id,
      clearSourceTemplateId: _selectedTemplate == null,
    );
    provider.updateClientInfo(
      clientName: _selectedClient?.name ?? d?.clientName ?? current.clientName,
      clientEmail: _selectedClient?.email ?? d?.clientEmail ?? current.clientEmail,
      clientPhone: _selectedClient?.phone ?? d?.clientPhone ?? current.clientPhone,
      clientAddress: _selectedClient?.address ?? d?.clientAddress ?? current.clientAddress,
      sourceClientId: _selectedClient?.id,
      clearSourceClientId: _selectedClient == null,
    );
    provider.updateQuoteDetails(
      quoteNumber: d?.quoteNumber ?? current.quoteNumber,
      issueDate: d?.issueDate ?? current.issueDate,
      expiryDate: d?.expiryDate ?? current.expiryDate,
      notes: d?.notes ?? current.notes,
      currency: d?.currency ?? current.currency,
      currencySymbol: d?.currencySymbol ?? current.currencySymbol,
      currencyDisplayMode: d?.currencyDisplayMode ?? current.currencyDisplayMode,
      taxRate: d?.taxRate ?? current.taxRate,
      discountRate: d?.discountRate ?? current.discountRate,
    );
    if (d != null) {
      provider.updateQuoteData(provider.quoteData.copyWith(
        lineItems: d.lineItems.map((i) => i.copyWith()).toList(),
      ));
    }
    provider.updateLayoutTemplateId(_layoutTemplateId);
  }

  // STEP-TAP BYPASS FIX (unchanged): tapping a step tab re-runs the same
  // per-step validation _nextStep() enforces when pressing Next.
  void _goToStep(int index) {
    if (index > _step) {
      for (int i = _step; i < index; i++) {
        final blocked = _stepBlockReason(i);
        if (blocked != null) {
          _showSnack(blocked);
          return;
        }
      }
    }
    _syncToProvider();
    setState(() => _step = index);
  }

  /// Returns the validation message to show if step [i] isn't complete
  /// enough to move past, or null if it's fine to continue.
  String? _stepBlockReason(int i) {
    if (i == 1 && _selectedTemplate == null) {
      return 'Select or add a template to continue';
    }
    if (i == 2 && _selectedQuoteDraft == null) {
      return 'Select or create a quote to continue';
    }
    return null;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _nextStep() {
    final blocked = _stepBlockReason(_step);
    if (blocked != null) {
      _showSnack(blocked);
      return;
    }
    if (_step < _steps.length - 1) {
      _syncToProvider();
      setState(() => _step++);
    }
    // CUSTOMISE OWNERSHIP PASS: there is no "else" branch here anymore —
    // reaching the last step no longer calls a save action from this
    // button at all, since the shared bottom nav bar isn't shown once
    // _isLastStep is true (see build() below). Saving happens entirely
    // inside QuoteStepCustomise's own bottom bar.
  }

  void _prevStep() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          StepEditorHeader(
            title: 'Create Quote',
            currentStep: _step,
            steps: _steps,
            accent: _accent,
            onBack: _prevStep,
            onStepTap: _goToStep,
          ),
          Expanded(
            // CUSTOMISE OWNERSHIP PASS: the Customise step supplies its
            // own internal SingleChildScrollView + bottom bar (matching
            // Invoice's StepCustomise) and needs the full bounded height
            // this Expanded provides directly — wrapping it in another
            // SingleChildScrollView here would both double-scroll and
            // break its own internal Expanded/bottom-bar layout (an
            // Expanded inside an unbounded-height ancestor throws).
            // Every other step keeps the plain scrolling container it
            // always had.
            child: _isLastStep
                ? _buildStep()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildStep(),
                  ),
          ),
        ],
      ),
      // CUSTOMISE OWNERSHIP PASS: the shared Back/Next bar only makes
      // sense for steps 0-2, which have no bottom bar of their own.
      // Once on Customise, QuoteStepCustomise's own _BottomBar (Back +
      // Save Quote) takes over entirely — showing this one underneath
      // it would leave two competing "continue" affordances on screen.
      bottomNavigationBar: _isLastStep
          ? null
          : QuoteStepNavBar(
              onBack: null,
              onNext: _nextStep,
              nextLabel: 'Next',
              nextIcon: Icons.arrow_forward_rounded,
              accent: _accent,
            ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _customerStep();
      case 1:
        return _templateStep();
      case 2:
        return _createQuoteStep();
      default:
        return _customiseStep();
    }
  }

  Widget _selectionStatus({required bool selected, required String label}) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? const Color(0xFF2E7D32) : _accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(selected ? Icons.check_circle_rounded : Icons.info_outline_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerStep() {
    final label = _selectedClient == null
        ? 'Select a saved customer, or enter one manually on the next Create Quote step.'
        : 'Using "${_selectedClient!.name}" for this quote.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuoteStepCustomerSection(
          accent: _accent,
          onClientSelected: _applyClient,
          initialSelectedId: _initialClientId,
          onInitialSelectionRestored: _restoreClient,
        ),
        const SizedBox(height: 12),
        _selectionStatus(selected: _selectedClient != null, label: label),
      ],
    );
  }

  Widget _templateStep() {
    final label = _selectedTemplate == null
        ? 'Select or add a template above to continue.'
        : 'Using "${_selectedTemplate!.name.isNotEmpty ? _selectedTemplate!.name : _selectedTemplate!.businessName}" for this quote.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuoteStepTemplateSection(
          accent: _accent,
          onTemplateSelected: _applyTemplate,
          initialSelectedId: _initialTemplateId,
          onInitialSelectionRestored: _restoreTemplate,
        ),
        const SizedBox(height: 12),
        _selectionStatus(selected: _selectedTemplate != null, label: label),
      ],
    );
  }

  // QUOTE LIBRARY RESTRUCTURE PASS: now just embeds StepCreateQuote
  // (create_quote_section/step_create_quote/step_create_quote.dart) —
  // the entire form has moved into CreateQuoteBottomSheet, opened from
  // that library screen.
  Widget _createQuoteStep() {
    return StepCreateQuote(
      accent: _accent,
      selectedClient: _selectedClient,
      selectedTemplate: _selectedTemplate,
      onDraftSelected: (draft) {
        setState(() => _selectedQuoteDraft = draft);
        _syncToProvider();
      },
    );
  }

  // CUSTOMISE OWNERSHIP PASS: QuoteStepCustomise now owns every piece of
  // its own state (title, logo, colour, font, field toggles) directly
  // against QuoteProvider — this screen hands it nothing but the one
  // callback it can't own itself (going back a step).
  Widget _customiseStep() {
    return QuoteStepCustomise(onBack: _prevStep);
  }
}